%% MPC controller object (Yalmip)

function mpc_c = mpc_controller(data)

yalmip('clear');

% ========== Data ==========

nx = data.nx;
nu = data.nu;
ny = data.ny;

Np = data.Np;
Nc = data.Nc;

% ========== Yalmip declarations ==========

% ===== Yalmip variables =====
% Prediction model matrices
A = sdpvar(nx,nx,'full');
B = sdpvar(nx,nu,'full');
b = sdpvar(nx,1,'full');

C = sdpvar(ny,nx,'full');
D = sdpvar(ny,nu,'full');
d = sdpvar(ny,1,'full');

% States
x = sdpvar(nx*ones(1,Np+2),ones(1,Np+2));
x_in = sdpvar(nx,1);

% Inputs
u = sdpvar(nu*ones(1,Nc),ones(1,Nc));

% Outputs
y = sdpvar(ny*ones(1,Np+1),ones(1,Np+1));

% Output reference
y_r = sdpvar(ny*ones(1,Np+1),ones(1,Np+1));

% Weights
Q = sdpvar(ny,ny,'full');
R = sdpvar(nu,nu,'full');
Qd = sdpvar(ny,ny,'full');
Rd = sdpvar(nu,nu,'full');
P = sdpvar(ny,ny,'full');
rho = 1e04;

% Bounds
y_m = sdpvar(ny,1); y_M = sdpvar(ny,1);
u_m = sdpvar(nu,1); u_M = sdpvar(nu,1);
ud_m = sdpvar(nu,1); ud_M = sdpvar(nu,1);

% Slack variables
e_y = sdpvar(ny,1);

% Scale factors
y_scale = data.y_scale;
u_scale = data.u_scale;

% Auxiliary variables
u0 = sdpvar(nu,1);

% ===== Cost function =====

cost = 0;

% Output
for k = 1:1:Np
	cost = cost + ((y{k}-y_r{k})./y_scale)'*Q*((y{k}-y_r{k})./y_scale);
end

% Input
for k = 1:1:Np
	if k <= Nc
		cost = cost + (u{k}./u_scale)'*R*(u{k}./u_scale);
	else
		cost = cost + (u{Nc}./u_scale)'*R*(u{Nc}./u_scale);
	end
end

% Output rate
for k = 2:1:Np
	cost = cost + ((y{k}-y{k-1})./y_scale)'*Qd*((y{k}-y{k-1})./y_scale);
end

% Input rate
for k = 2:1:Np
	if k <= Nc
		cost = cost + ((u{k}-u{k-1})./u_scale)'*Rd*((u{k}-u{k-1})./u_scale);
	else
		cost = cost + ((u{Nc}-u{Nc-1})./u_scale)'*Rd*((u{Nc}-u{Nc-1})./u_scale);
	end
end

% Slack variables
cost = cost + rho*(e_y./y_scale)'*(e_y./y_scale);

% Terminal cost
cost = cost + ((y{Np+1}-y_r{Np+1})./y_scale)'*P*((y{Np+1}-y_r{Np+1})./y_scale);

% ===== Constraints =====
constr = [];

% Initial condition
constr = [constr; x{1} == x_in];

% Prediction model
for k = 1:1:Np+1
	if k <= Nc
		constr = [constr;
			x{k+1} == A*x{k} + B*u{k} + b;
			y{k} == C*x{k} + D*u{k} + d];
	else
		constr = [constr;
			x{k+1} == A*x{k} + B*u{Nc} + b;
			y{k} == C*x{k} + D*u{Nc} + d];
	end
end

% Output bounds
for k = 1:1:Np+1
	constr = [constr; y_m - 1e-03*e_y <= y{k} <= y_M + 1e-03*e_y];
end

% Input bounds
for k = 1:1:Nc
	constr = [constr; u_m <= u{k} <= u_M];
end

% Input rate bounds
if data.ignore_u0 == false
	constr = [constr; ud_m <= u{1}-u0 <= ud_M];
end
for k = 2:1:Nc
	constr = [constr; ud_m <= u{k}-u{k-1} <= ud_M];
end

% Slack variables
constr = [constr; e_y >= 0];

% ===== Optimizer object (MPC controller) =====
params_in = {x_in, u0, A, B, b, C, D, d, ...
	[y_r{:}], Q, R, Qd, Rd, P, ...
	y_m, y_M, u_m, u_M, ud_m, ud_M};

sol_out = u{1};

options = sdpsettings('verbose',0,'solver','quadprog');
options.quadprog.TolCon = 1e-04;
options.quadprog.TolFun = 1e-03;
options.quadprog.TolFunValue = 1e-03;

mpc_c = optimizer(constr,cost,options,params_in,sol_out);

end













