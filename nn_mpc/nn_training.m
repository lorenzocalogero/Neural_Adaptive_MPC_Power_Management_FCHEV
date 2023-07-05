%% NN training (NN-MPC)

clc
clear variables
close all

%% ========== Data ==========

load('training_data_nn_mpc_bal.mat',...
	'data_in','data_out');

data = get_data();

%% ========== Neural network ==========

% ===== Definition =====

% Shuffle training data
data_perm = randperm(size(data_in,2));
data_in = data_in(:,data_perm);
data_out = data_out(:,data_perm);

hidden_layers = [15 15];

net = feedforwardnet(hidden_layers);

net.trainFcn = 'trainlm';
net.trainParam.epochs = 1000;
net.trainParam.max_fail = 100;

net.divideFcn = 'dividerand';
net.divideParam.trainRatio = 0.8;
net.divideParam.valRatio = 0.1;
net.divideParam.testRatio = 0.1;

net.performParam.normalization = 'standard';

net = configure(net,data_in,data_out);

% ===== Training =====

n_data_part = size(data_in,2); % Train data partition size

n_train_iter = floor(size(data_in,2)/n_data_part); % Number of partitions
train_iter = 1;

tr_v = [];

for i=0 : n_data_part : size(data_in,2)-n_data_part
	
	fprintf('Training NN: step %d / %d\n', train_iter, n_train_iter);
	train_iter = train_iter+1;
	
	data_in_part = data_in(:, i+1 : i+n_data_part);
	data_out_part = data_out(:, i+1 : i+n_data_part);
	
	[net, tr] = train(net,data_in_part,data_out_part,...
		'useParallel','yes');
	
	tr_v = [tr_v, tr];
	
end

% ===== Save trained NN =====

save('trained_net_nn_mpc_bal.mat',...
	'net','tr_v');

%% ========== Plots ==========

close all

load('trained_net_nn_mpc_bal.mat',...
	'tr_v');

train_perf = [tr_v(:).perf];
%val_perf = [tr_v(:).vperf];
test_perf = [tr_v(:).tperf];
epochs = 1:1:length(train_perf);

f1 = figure(1); set(f1,'color','w');
f1.Position = [100   100   560   420*0.65];
tl = tiledlayout(1,1,'tilespacing','none','padding','compact');

nexttile

p1 = semilogy(epochs,test_perf,'r-'); hold on
p2 = semilogy(epochs,train_perf,'b-'); hold off

set(gca,'fontsize',13)
set(gca,'xminorgrid','on','yminorgrid','on'), grid on

xlim([0, epochs(end)])

xlabel('Epoch','fontsize',14,'interpreter','latex')
ylabel('MSE (normalized)','fontsize',14,'interpreter','latex')

title('Training performances','fontsize',14,'interpreter','latex')

legend([p2,p1],{'Training','Validation'},'interpreter','latex',...
	'Location','northeast','numcolumns',1,'fontsize',12)

%% ========== Export images ==========

exportgraphics(f1,'nn_mpc_bal_net_perf.pdf','BackgroundColor','w');

%% ========== Error mean and variance ==========

clc

load('training_data_nn_mpc_bal.mat',...
	'data_in','data_out');
load('trained_net_nn_mpc_bal.mat',...
	'net','tr_v');

data_out_nn = net(data_in); % Compute net pred. outputs

norm_err = (data_out_nn - data_out)./max(abs(data_out),[],2); % Compute norm. error

err_max = max(abs(data_out_nn - data_out),[],2) % Max abs. error

norm_err_max = max(abs(norm_err),[],2)*100 % Max norm. error

norm_err_mean = mean(norm_err,2) % Mean of norm. error

norm_err_var = var(norm_err,[],2) % Variance of norm. error










