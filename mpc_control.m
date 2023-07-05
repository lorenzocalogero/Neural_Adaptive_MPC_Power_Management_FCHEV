%% MPC control

function [y, u, x, max_exec_time] = mpc_control(data, mpc_w)

% ===== Meas. error =====

err = @(e,size) 1 + (-e + 2*e*rand(size)); % Random mult. error in [-e,+e]

% ===== Init. =====

mpc_c = mpc_controller(data); % MPC controller

x = data.x_in;
u = [];
y = [];

exec_time = [];

% ===== MPC control =====

x1 = x(:,1);
u1 = zeros(data.nu,1);

% Measured values (affected by error)
x1_m = x1 .* err(data.err_meas,[data.nx,1]);
u1_m = u1 .* err(data.err_meas,[data.nu,1]);

x_op = x1_m;
u_op = u1_m;

u0 = u1;

for k = 1:1:length(data.time_sys)

	if mod((k-1)*data.Ts_sys, data.Ts_mpc) == 0

		% NN-MPC control (1 step)
		if nargin < 2
			[u1, curr_exec_time] = ...
				mpc_control_1_step(mpc_c, k, x1_m, x_op, u_op, u0, data);
		else
			[u1, curr_exec_time] = ...
				mpc_control_1_step(mpc_c, k, x1_m, x_op, u_op, u0, data, mpc_w);
		end
		exec_time = [exec_time, curr_exec_time];

	end

	% Apply control input to system
	if nargin < 2
		[x2,y1] = plant_dt(x1,u1,data);
	else
		x1d = net_fun(data.net_f_data, [x1; u1]);
		x2 = x1 + x1d*data.Ts_sys;
		y1 = net_fun(data.net_g_data, [x1; u1]);
	end

	% Save closed-loop trajectories
	x = [x, x2];
	u = [u, u1];
	y = [y, y1];

	x1 = x2; % Update current state
	
	x1_m = x1 .* err(data.err_meas,[data.nx,1]);
	u1_m = u1 .* err(data.err_meas,[data.nu,1]);

	x_op = x1_m;
	u_op = u1_m;

	u0 = u1;

end

max_exec_time = mean(exec_time);

end





%% ========== Auxiliary functions ==========

%% ===== MPC control (1 step) =====
function [u1, curr_exec_time] = ...
	mpc_control_1_step(mpc_c, k, x1, x_op, u_op, u0, data, mpc_w)

u_M = data.u_M;

y_r_curr = repmat(data.y_r(:,k),1,data.Np+1);

if nargin == 8
	Q = diag(mpc_w(1:3));
	R = diag(mpc_w(4:5));
	Qd = diag(mpc_w(6:8));
	Rd = diag(mpc_w(9:10));
	P = mpc_w(11)*Q;
else
	Q = data.Q;
	R = data.R;
	Qd = data.Qd;
	Rd = data.Rd;
	P = data.P;
end

[A, B, b, C, D, d] = lin_pred_model(x_op,u_op,data);

u_M(1) = get_bat_power_max(x1(1), data); % Only P_b_max changes at each time step

tim_1 = tic;

% Compute optimal control input
u1 = mpc_c({x1, u0, A, B, b, C, D, d, ...
	y_r_curr, Q, R, Qd, Rd, P, ...
	data.y_m, data.y_M, data.u_m, u_M, data.ud_m*data.Ts_mpc, data.ud_M*data.Ts_mpc});

curr_exec_time = toc(tim_1);

if (nargin < 8) && (data.mpc_verb == true)
	clc
	fprintf('MPC simulation: time %.2f s / %.2f s\n',(k-1)*data.Ts_sys,data.T_sim);
end

end

%% ===== Get current max battery power =====
function P_b_max = get_bat_power_max(SOC, data)

Voc_bat = @(z) data.bat_stack_num*data.Voc_bat_cell(z);
Ro_bat = @(z) data.bat_stack_num*data.Ro_bat_cell(z);

P_b_max_model = 0.99*Voc_bat(SOC)^2/(4*Ro_bat(SOC));

P_b_max = min(P_b_max_model,data.P_b_max_data);

end















