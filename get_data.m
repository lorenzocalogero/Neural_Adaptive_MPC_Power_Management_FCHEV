%% Get data struct

function data = get_data()

%% ========== Plant ==========

% Size
nx = 2;
nu = 2;
ny = 3;

% Plant discrete time step [s]
Ts_sys = 0.2; % Same as time step of P_req

%% ========== Plant model ==========

% ===== Battery =====

load('bat_power_data.mat',...
	'bat_stack_num','P_b_min','P_b_max_data','P_b_delta_min','P_b_delta_max');

load('bat_Voc_Ro_fun.mat',...
	'Voc_bat_cell','Ro_bat_cell');

SOC_min = 0.2;
SOC_max = 0.8;

nom_capacity = 60; % [Ah]
Q_nom = nom_capacity*3600; % [As=C]

bat_coul_eff = 0.95;
bat_conv_eff = 0.97;

% ===== Fuel cell =====

load('fc_power_data.mat',...
	'fc_stack_num','P_fc_min','P_fc_max_data','P_fc_delta_min','P_fc_delta_max',...
	'Voc_fc_s','Ro_fc_s','P_aux_0_fc','V_aux_fc_s');

mh_min = 200; % [g]
mh_max = 2000; % [g]

fc_conv_eff = 0.97;

P_fc_max_model = 0.99*(fc_stack_num*(Voc_fc_s-V_aux_fc_s)^2/(4*Ro_fc_s)-P_aux_0_fc); % [W]
P_fc_max = min(P_fc_max_data, P_fc_max_model); % [W]

%% ========== Simulation ==========

% ===== Initial condition =====

SOC_1 = 0.5;
mh_1 = 900; % [g]
x_in = [SOC_1, mh_1]';

%% ========== MPC ==========

% ===== General =====

% MPC discrete time step [s]
Ts_mpc = 1; % Must be a multiple of Ts_sys

% Data-driven prediction model
data_driven_mpc = true; % Enable data-driven pred. model

if data_driven_mpc == true
	load('trained_net_f_err.mat',...
		'net_f');
	net_f_data = get_net_data(net_f);
	
	load('trained_net_g_err.mat',...
		'net_g');
	net_g_data = get_net_data(net_g);
else
	net_f_data = [];
	net_g_data = [];
end

err_meas = 0; % Multiplicative meas. error

ignore_u0 = false;
mpc_verb = true; % MPC verbosity

% ===== Horizons =====

Np = 10; % Prediction horizon
Nc = 3; % Control horizon

% ===== Output reference =====

load('P_req_data.mat',...
	'P_req_data','time_data');

T_sim = time_data(end);

time_mpc = 0:Ts_mpc:T_sim;
time_sys = 0:Ts_sys:T_sim;

P_tot_r = P_req_data';
SOC_r = repmat(x_in(1), 1, length(P_tot_r));
mh_r = repmat(x_in(2), 1, length(P_tot_r));

y_r = [SOC_r; mh_r; P_tot_r];

% ===== Output bounds =====

y_m = [SOC_min; mh_min; -inf];
y_M = [SOC_max; mh_max; +inf];

% ===== Input bounds =====

u_m = [P_b_min; P_fc_min];
u_M = [P_b_max_data; P_fc_max];

% ===== Input rate bounds =====

ud_m = [P_b_delta_min; P_fc_delta_min];
ud_M = [P_b_delta_max; P_fc_delta_max];

% ===== Scale factors =====

y_scale = 0.5*[SOC_max - SOC_min;
	mh_max - mh_min;
	(P_b_max_data + P_fc_max) - (P_b_min + P_fc_min)];

u_scale = 0.5*[P_b_max_data - P_b_min;
	P_fc_max - P_fc_min];

% ===== Weights =====

% mpc_w = [SOC, mh, P_tot, ...
%	P_b, P_fc, ...
%	SOC (rate), mh (rate), P_tot (rate), ...
%	P_b (rate), P_fc (rate), ...
%	alpha];

% Manual
% mpc_w = [0, 0, 100, 0, 0, 0, 0, 0, 0, 0, 10]; % Track
% mpc_w = [50, 50, 100, 0, 0, 50, 50, 0, 50, 50, 10]; % Bal
% mpc_w = [75, 0, 100, 0, 0, 75, 0, 0, 75, 0, 10]; % Bat
% mpc_w = [0, 75, 100, 0, 0, 0, 75, 0, 0, 75, 10]; % H2

% Auto
mpc_w = [2.131, 1.245, 100, 0, 0, 100, 75.5009, 0, 100, 71.4305, 12.5138]; % Track
% mpc_w = [50.8763, 93.1232, 63.8188, 0, 0, 0, 9.63706, 0, 29.2137, 91.6158, 5]; % Bal
% mpc_w = [58.992, 0, 100, 0, 0, 55.2587, 5.91388, 0, 99.8219, 34.5301, 20.6265]; % Bat
% mpc_w = [15.6242, 100, 100, 0, 0, 100, 52.2036, 0, 17.0152, 64.2239, 23.8652]; % H2

Q = diag(mpc_w(1:3));
R = diag(mpc_w(4:5));
Qd = diag(mpc_w(6:8));
Rd = diag(mpc_w(9:10));
P = mpc_w(11)*Q;

%% ========== MPC tuning ==========

% ===== PSO bounds =====

pso_mpc_w_lb = [0, 0, 0, ...
	0, 0, ...
	0, 0, 0, ...
	0, 0, ...
	5]';
pso_mpc_w_ub = [100, 100, 100, ...
	0, 0, ...
	100, 100, 0, ...
	100, 100, ...
	30]';

% ===== PSO parameters =====

pso_pop_size = 10;
pso_max_iter = 10;
pso_w = [0.9 0.2];
pso_c_i = 1;
pso_c_s = 2;
pso_borders_type = 'absorb';

% ===== PSO obj. function =====

pso_P_req_track_err_lim = [0, 10];

pso_coef_P_req_track = 3;
pso_coef_bat_cons = 0;
pso_coef_H2_cons = 0;

pso_coef = [pso_coef_P_req_track, pso_coef_bat_cons, pso_coef_H2_cons];

P_req_track_err_th = [10, 10.5];

%% ========== Data struct ==========

% ===== System =====
data.nx = nx;
data.nu = nu;
data.ny = ny;

data.Ts_sys = Ts_sys;

% ===== System model - Battery =====
data.bat_stack_num = bat_stack_num;
data.SOC_min = SOC_min;
data.SOC_max = SOC_max;
data.Q_nom = Q_nom;
data.bat_coul_eff = bat_coul_eff;
data.bat_conv_eff = bat_conv_eff;

data.P_b_min = P_b_min;
data.P_b_max_data = P_b_max_data;
data.P_b_delta_min = P_b_delta_min;
data.P_b_delta_max = P_b_delta_max;

data.Voc_bat_cell = Voc_bat_cell;
data.Ro_bat_cell = Ro_bat_cell;

% ===== System model - Fuel cell =====
data.fc_stack_num = fc_stack_num;
data.mh_min = mh_min;
data.mh_max = mh_max;
data.fc_conv_eff = fc_conv_eff;

data.P_fc_min = P_fc_min;
data.P_fc_max = P_fc_max;
data.P_fc_delta_min = P_fc_delta_min;
data.P_fc_delta_max = P_fc_delta_max;

data.Voc_fc_s = Voc_fc_s;
data.Ro_fc_s = Ro_fc_s;

data.P_aux_0_fc = P_aux_0_fc;
data.V_aux_fc_s = V_aux_fc_s;

% ===== Simulation =====
data.x_in = x_in;

% ===== MPC =====
data.Ts_mpc = Ts_mpc;

data.err_meas = err_meas;

data.ignore_u0 = ignore_u0;
data.mpc_verb = mpc_verb;

data.data_driven_mpc = data_driven_mpc;
data.net_f_data = net_f_data;
data.net_g_data = net_g_data;

data.Np = Np;
data.Nc = Nc;

data.T_sim = T_sim;
data.time_mpc = time_mpc;
data.time_sys = time_sys;

data.y_r = y_r;

data.y_m = y_m;
data.y_M = y_M;
data.u_m = u_m;
data.u_M = u_M;
data.ud_m = ud_m;
data.ud_M = ud_M;

data.y_scale = y_scale;
data.u_scale = u_scale;

data.Q = Q;
data.R = R;
data.Qd = Qd;
data.Rd = Rd;
data.P = P;

% ===== MPC tuning =====
data.pso_mpc_w_lb = pso_mpc_w_lb;
data.pso_mpc_w_ub = pso_mpc_w_ub;

data.pso_pop_size = pso_pop_size;
data.pso_max_iter = pso_max_iter;
data.pso_w = pso_w;
data.pso_c_i = pso_c_i;
data.pso_c_s = pso_c_s;
data.pso_borders_type = pso_borders_type;

data.pso_P_req_track_err_lim = pso_P_req_track_err_lim;

data.pso_coef = pso_coef;

data.P_req_track_err_th = P_req_track_err_th;

end













