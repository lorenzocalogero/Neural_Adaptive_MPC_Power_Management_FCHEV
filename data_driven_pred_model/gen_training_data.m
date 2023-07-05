%% Gen. training data (MPC data-driven pred. model)

clc
clear variables
close all

%% ========== Data ==========

data = get_data();

%% ========== Gen. training data ==========

% ===== Mult. meas. error =====
err_meas = 0.1;
err = @(e,size) 1 + (-e + 2*e*rand(size)); % Random mult. error in [-e,+e]

% ===== Generate data =====
P_b_1 = linspace(data.P_b_min, data.P_b_max_data, 30);
P_fc_1 = linspace(data.P_fc_min, data.P_fc_max, 30);

SOC_1 = linspace(data.SOC_min, data.SOC_max, 15);
mh_1 = linspace(data.mh_min, data.mh_max, 15);

data_in = setprod(SOC_1, mh_1, P_b_1, P_fc_1)';

data_out_f = zeros(data.nx,size(data_in,2));
data_out_g = zeros(data.ny,size(data_in,2));

if isempty(gcp('nocreate'))
	parpool('local');
end

parfor i=1:size(data_in,2)
	
	fprintf('Generating training data: step %d / %d\n', i, size(data_in,2));
	
	x1 = data_in([1,2],i);
	u1 = data_in([3,4],i);
	
	[x1d,y1] = plant_ct(x1,u1,data);
	
	data_out_f(:,i) = x1d .* err(err_meas,[data.nx,1]);
	data_out_g(:,i) = y1 .* err(err_meas,[data.ny,1]);
	
end

%% ========== Save training data ==========

save('training_data_err.mat',...
	'data_in','data_out_f','data_out_g');












