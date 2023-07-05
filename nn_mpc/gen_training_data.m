%% Gen. training data (NN-MPC)

clc
clear variables
close all

%% ========== Data ==========

data = get_data();

P_req_min = data.P_b_min + data.P_fc_min;
P_req_max = data.P_b_max_data + data.P_fc_max;
P_b_min = data.P_b_min;

%% ========== Generate training data ==========

SOC = linspace(data.SOC_min,data.SOC_max,40);
mh = linspace(data.mh_min,data.mh_max,40);
P_req = linspace(0.99*P_req_min,0.99*P_req_max,50);

data_in = setprod(SOC, mh, P_req)';
data_out = zeros(2,size(data_in,2));

data.ignore_u0 = true;
mpc_c = mpc_controller(data);

if isempty(gcp('nocreate'))
	parpool('local');
end

SOC_r = data.y_r(1,1);
mh_r = data.y_r(2,1);

parfor i=1:size(data_in,2)
	
	fprintf('Generating training data: %d / %d\n',i,size(data_in,2));
	
	x1 = data_in([1,2],i);

	x_op = x1;
	u_op = [(P_b_min + get_bat_power_max(x1(1),data))/2, ...
		(data.P_fc_min + data.P_fc_max)/2]';
	
	y_r = [SOC_r; mh_r; data_in(3,i)];
	
	u1 = mpc_control_1_step(mpc_c, x1, y_r, x_op, u_op, data);
	
	data_out(:,i) = u1;
	
end

%% ========== Save training data ==========

save('training_data_nn_mpc_bal.mat',...
	'data_in','data_out');





%% ========== Auxiliary functions ==========

%% ===== MPC control (1 step) =====
function u1 = mpc_control_1_step(mpc_c, x1, y_r, x_op, u_op, data)

u_M = data.u_M;

y_r_curr = repmat(y_r,1,data.Np+1);

[A, B, c, C, D, d] = lin_pred_model(x_op,u_op,data);
	
u_M(1) = get_bat_power_max(x1(1), data);

u1 = mpc_c({x1, zeros(data.nu,1), A, B, c, C, D, d, ...
	y_r_curr, data.Q, data.R, data.Qd, data.Rd, data.P, ...
	data.y_m, data.y_M, data.u_m, u_M, data.ud_m*data.Ts_mpc, data.ud_M*data.Ts_mpc});

end

%% ===== MPC control (1 step) =====
function P_b_max = get_bat_power_max(SOC, data)

Voc_bat = @(z) data.bat_stack_num*data.Voc_bat_cell(z);
Ro_bat = @(z) data.bat_stack_num*data.Ro_bat_cell(z);

P_b_max_model = 0.99*Voc_bat(SOC)^2/(4*Ro_bat(SOC));

P_b_max = min(P_b_max_model, data.P_b_max_data);

end















