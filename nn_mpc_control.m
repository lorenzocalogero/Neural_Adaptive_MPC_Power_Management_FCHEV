%% NN-MPC control

function [y, u, x, max_exec_time] = nn_mpc_control(net, data)

% ===== Meas. error =====

err = @(e,size) 1 + (-e + 2*e*rand(size)); % Random mult. error in [-e,+e]

% ===== Init. =====

net_data = get_net_data(net); % Net data

net_c = @(x) net_fun(net_data,x); % NN-MPC controller

x = data.x_in;
u = [];
y = [];

exec_time = [];

% ===== NN-MPC control =====

x1 = x(:,1);

% Measured values (affected by error)
x1_m = x1 .* err(data.err_meas,[data.nx,1]);

for k = 1:1:length(data.time_sys)

	if mod((k-1)*data.Ts_sys, data.Ts_mpc) == 0
		
		% NN-MPC control (1 step)
		[u1, curr_exec_time] = nn_mpc_control_1_step(net_c, k, x1_m, data);
		exec_time = [exec_time, curr_exec_time];
		
	end

	[x2,y1] = plant_dt(x1,u1,data); % Apply control input to system

	% Save closed-loop trajectories
	x = [x, x2];
	u = [u, u1];
	y = [y, y1];

	x1 = x2; % Update current state
	
	x1_m = x1 .* err(data.err_meas,[data.nx,1]);

end

max_exec_time = mean(exec_time);

end





%% ========== Auxiliary functions ==========

%% ===== NN MPC control (1 step) =====
function [u1, curr_exec_time] = nn_mpc_control_1_step(net_c, k, x1, data)

	P_tot_r = data.y_r(3,k);
	x_net = [x1(1), x1(2), P_tot_r]';
	
	tim_1 = tic;
	
	% Compute optimal control input (via NN)
	u1 = net_c(x_net);
	
	% Apply control input bounds
	u1(1) = max(min(u1(1), get_bat_power_max(x1(1),data)), data.P_b_min);
	u1(2) = max(min(u1(2), data.P_fc_max), data.P_fc_min);
	
	curr_exec_time = toc(tim_1);

end

%% ===== Get current max battery power =====
function P_b_max = get_bat_power_max(SOC, data)

Voc_bat = @(z) data.bat_stack_num*data.Voc_bat_cell(z);
Ro_bat = @(z) data.bat_stack_num*data.Ro_bat_cell(z);

P_b_max_model = 0.99*Voc_bat(SOC)^2/(4*Ro_bat(SOC));

P_b_max = min(P_b_max_model,data.P_b_max_data);

end















