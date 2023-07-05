%% NN training (MPC data-driven pred. model)

clc
clear variables
close all

%% ========== Data ==========

load('training_data_err.mat',...
	'data_in','data_out_f','data_out_g');

%% ========== State equation NN ==========

% ===== Definition =====

% Shuffle training data
data_perm = randperm(size(data_in,2));
data_in_f = data_in(:,data_perm);
data_out_f = data_out_f(:,data_perm);

hidden_layers = [15];

net_f = feedforwardnet(hidden_layers);

net_f.trainFcn = 'trainlm';
net_f.trainParam.epochs = 1000;
net_f.trainParam.max_fail = 100;

net_f.divideFcn = 'dividerand';
net_f.divideParam.trainRatio = 0.8;
net_f.divideParam.valRatio = 0.1;
net_f.divideParam.testRatio = 0.1;

net_f.performParam.normalization = 'standard';

net_f = configure(net_f,data_in_f,data_out_f);

% ===== Training =====

n_data_part = 10000; % Train data partition size

n_train_iter = floor(size(data_in_f,2)/n_data_part); % Number of partitions
train_iter = 1;

tr_f_v = [];

for i=0 : n_data_part : size(data_in_f,2)-n_data_part
	
	fprintf('Training state equation NN: step %d / %d\n', train_iter, n_train_iter);
	train_iter = train_iter+1;
	
	data_in_f_part = data_in_f(:, i+1 : i+n_data_part);
	data_out_f_part = data_out_f(:, i+1 : i+n_data_part);
	
	[net_f, tr_f] = train(net_f,data_in_f_part,data_out_f_part,...
		'useParallel','yes');
	
	tr_f_v = [tr_f_v, tr_f];
	
end

% ===== Save trained NN =====

save('trained_net_f_err.mat',...
	'net_f','tr_f_v');

%% ========== Output equation NN ==========

% ===== Definition =====

% Shuffle training data
data_perm = randperm(size(data_in,2));
data_in_g = data_in(:,data_perm);
data_out_g = data_out_g(:,data_perm);

hidden_layers = [10];

net_g = feedforwardnet(hidden_layers);

net_g.trainFcn = 'trainlm';
net_g.trainParam.epochs = 1000;
net_g.trainParam.max_fail = 100;

net_g.divideFcn = 'dividerand';
net_g.divideParam.trainRatio = 0.8;
net_g.divideParam.valRatio = 0.1;
net_g.divideParam.testRatio = 0.1;

net_g.performParam.normalization = 'standard';

net_g = configure(net_g,data_in_g,data_out_g);

% ===== Training =====

n_data_part = 10000; % Train data partition size

n_train_iter = floor(size(data_in_g,2)/n_data_part); % Number of partitions
train_iter = 1;

tr_g_v = [];

for i=0 : n_data_part : size(data_in_g,2)-n_data_part
	
	fprintf('Training output equation NN: step %d / %d\n', train_iter, n_train_iter);
	train_iter = train_iter+1;
	
	data_in_g_part = data_in_g(:, i+1 : i+n_data_part);
	data_out_g_part = data_out_g(:, i+1 : i+n_data_part);
	
	[net_g, tr_g] = train(net_g,data_in_g_part,data_out_g_part,...
		'useParallel','yes');
	
	tr_g_v = [tr_g_v, tr_g];
	
end

% ===== Save trained NN =====

save('trained_net_g_err.mat',...
	'net_g','tr_g_v');

%% ========== Plots ==========

close all

load('trained_net_f_err.mat',...
	'tr_f_v');
load('trained_net_g_err.mat',...
	'tr_g_v');

% ===== State equation NN =====

train_perf = [tr_f_v(:).perf];
test_perf = [tr_f_v(:).tperf];
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

title('Training performances ($\mathcal{N}_f$)','fontsize',14,'interpreter','latex')

legend([p2,p1],{'Training','Validation'},'interpreter','latex',...
	'Location','northeast','numcolumns',1,'fontsize',12)

% ===== Output equation NN =====

train_perf = [tr_g_v(:).perf];
test_perf = [tr_g_v(:).tperf];
epochs = 1:1:length(train_perf);

f2 = figure(2); set(f2,'color','w');
f2.Position = [200   100   560   420*0.65];
tiledlayout(1,1,'tilespacing','none','padding','compact');

nexttile

p1 = semilogy(epochs,test_perf,'r-'); hold on
p2 = semilogy(epochs,train_perf,'b-'); hold off

set(gca,'fontsize',13)
set(gca,'xminorgrid','on','yminorgrid','on'), grid on

xlim([0, epochs(end)])

xlabel('Epoch','fontsize',14,'interpreter','latex')
ylabel('MSE (normalized)','fontsize',14,'interpreter','latex')

title('Training performances ($\mathcal{N}_g$)','fontsize',14,'interpreter','latex')

legend([p2,p1],{'Training','Validation'},'interpreter','latex',...
	'Location','northeast','numcolumns',1,'fontsize',12)

%% ========== Export images ==========

% exportgraphics(f1,'nn_pred_model_perf_f.pdf','BackgroundColor','w');
% exportgraphics(f2,'nn_pred_model_perf_g.pdf','BackgroundColor','w');

%% ========== Error mean and variance ==========

clc

load('training_data_err.mat',...
	'data_in','data_out_f','data_out_g');
load('trained_net_f_err.mat',...
	'net_f','tr_f_v');
load('trained_net_g_err.mat',...
	'net_g','tr_g_v');

% Compute net pred. outputs
data_out_f_nn = net_f(data_in);
data_out_g_nn = net_g(data_in);

% Compute norm. error
norm_err_f = (data_out_f_nn - data_out_f)./max(abs(data_out_f),[],2);
norm_err_g = (data_out_g_nn - data_out_g)./max(abs(data_out_g),[],2);

% Mean of norm. error
mean(norm_err_f,2)
mean(norm_err_g,2)

% Variance of norm. error
var(norm_err_f,[],2)
var(norm_err_g,[],2)



















