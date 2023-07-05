%% Pred. model numerical affine linearization

function [A, B, b, C, D, d] = lin_pred_model(x_op,u_op,data)

J_f_x = num_jacobian(@(x)plant_f(x,u_op,data), x_op);
J_f_u = num_jacobian(@(u)plant_f(x_op,u,data), u_op);

% J_g_x = num_jacobian(@(x)plant_g(x,u_op,data), x_op);
% J_g_u = num_jacobian(@(u)plant_g(x_op,u,data), u_op);

A = J_f_x;
B = J_f_u;
b = plant_f(x_op,u_op,data) - A*x_op - B*u_op;

% C = J_g_x;
% D = J_g_u;
C = [1 0; 0 1; 0 0];
D = [0 0; 0 0; data.bat_conv_eff data.fc_conv_eff];
d = plant_g(x_op,u_op,data) - C*x_op - D*u_op;

end





%% Auxiliary functions

%% ===== Plant model state fun. =====
function x2 = plant_f(x1,u1,data)

if data.data_driven_mpc == true
	x1d = net_fun(data.net_f_data, [x1; u1]);
	x2 = x1 + x1d*data.Ts_mpc;
else
	[x1d,~] = plant_ct(x1,u1,data);
	x2 = x1 + x1d*data.Ts_mpc;
end

end

%% ===== Plant model output fun. =====
function y1 = plant_g(x1,u1,data)

if data.data_driven_mpc == true
	y1 = net_fun(data.net_g_data, [x1; u1]);
else
	[~,y1] = plant_ct(x1,u1,data);
end

end


















