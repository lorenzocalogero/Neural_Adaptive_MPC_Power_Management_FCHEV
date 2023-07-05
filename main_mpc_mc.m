%% MPC/NN-MPC control (closed-loop simulation) - Monte Carlo analysis

clc
clear variables
close all

%% ========== Data ==========

data = get_data();

%% ========== Run parallel pool ==========
if isempty(gcp('nocreate'))
	parpool('local');
end

%% ========== MC analysis ==========

% ===== Settings =====
N_mc = 100; % Number of Monte Carlo simulations
use_nn_mpc = false;

% ===== Start MC simulations =====
data.mpc_verb = false;

if use_nn_mpc == false
	
	data.err_meas = 0;
	fprintf('MC simulation (MPC): 0 / %d (noise free)\n', N_mc)
	[y_0, u_0, ~, ~] = mpc_control(data);

	data.err_meas = 0.1;
	parfor i = 1:N_mc
		fprintf('MC simulation (MPC): %d / %d\n', i, N_mc)
		[y{i}, u{i}, ~, ~] = mpc_control(data);
	end
	
else
	
	load('trained_net_nn_mpc_bal.mat',...
		'net');
	
	data.err_meas = 0;
	fprintf('MC simulation (NN-MPC): 0 / %d (noise free)\n', N_mc)
	[y_0, u_0, ~, ~] = nn_mpc_control(net, data);

	data.err_meas = 0.1;
	parfor i = 1:N_mc
		fprintf('MC simulation (NN-MPC): %d / %d\n', i, N_mc)
		[y{i}, u{i}, ~, ~] = nn_mpc_control(net, data);
	end
	
end

%% ========== Save MPC data ==========

save('mc_mpc_bal.mat',...
	'y_0','u_0','y','u','N_mc');

%% ========== Plots ==========

close all

data = get_data();

load('mc_mpc_bal.mat',...
	'y_0','u_0','y','u','N_mc');

P_req = data.y_r(3,:)';

% ===== Set up figures =====

% ===== 1) Requested power =====

f1 = figure(1); set(f1,'color','w');
f1.Position = [100   100   560   420];

tl1 = tiledlayout(2,1,'tilespacing','compact','padding','compact');

% ===== 2) Battery / FC power =====

f2 = figure(2); set(f2,'color','w');
f2.Position = [200   100   560   420];

tl2 = tiledlayout(2,1,'tilespacing','compact','padding','compact');

% ===== 3) Supplies =====

f3 = figure(3); set(f3,'color','w');
f3.Position = [300   100   560   420];

tl3 = tiledlayout(2,1,'tilespacing','compact','padding','compact');

% ===== Plot MC traj. (noise-corrupted) =====

for i=1:1:N_mc
	
	P_b = u{i}(1,:)';
	P_fc = u{i}(2,:)';

	SOC = y{i}(1,:)';
	mh = y{i}(2,:)';
	P_tot = data.bat_conv_eff*P_b + data.fc_conv_eff*P_fc;

	P_req_mpc = P_req(1:data.Ts_mpc/data.Ts_sys:end);
	P_tot_mpc = P_tot(1:data.Ts_mpc/data.Ts_sys:end);
	
	% ===== 1) Requested power =====

	figure(1)

	% Requested/delivered power
	nexttile(1), hold on

	f1_p1a = plot(data.time_sys, P_tot, 'b-');

	% Requested power tracking error
	nexttile(2), hold on

	e_lim = data.pso_P_req_track_err_lim;

	f1_p2a = plot(data.time_mpc, 100*(P_tot_mpc-P_req_mpc)/max(abs(P_req_mpc)),'b-');

	% ===== 2) Battery / FC power =====

	figure(2)

	nexttile(1), hold on

	f2_p1a = plot(data.time_sys, P_b, 'b-');
	
	nexttile(2), hold on
	
	f2_p2a = plot(data.time_sys, P_fc, 'b-');

	% ===== (3) Supplies =====

	SOC_p = 100*(SOC-0)/(1-0);
	mh_p = 100*(mh-0)/(data.mh_max-0);

	figure(3)

	nexttile(1), hold on

	f3_p1a = plot(data.time_sys, SOC_p, 'b-');
	
	nexttile(2), hold on
	
	f3_p2a = plot(data.time_sys, mh_p, 'b-');
	
end

% ===== Plot noise-free traj. =====

P_b = u_0(1,:)';
P_fc = u_0(2,:)';

SOC = y_0(1,:)';
mh = y_0(2,:)';
P_tot = data.bat_conv_eff*P_b + data.fc_conv_eff*P_fc;

P_req_mpc = P_req(1:data.Ts_mpc/data.Ts_sys:end);
P_tot_mpc = P_tot(1:data.Ts_mpc/data.Ts_sys:end);

% ===== 1) Requested power =====

figure(1)

% Requested/delivered power
nexttile(1), hold on

f1_p1b = plot(data.time_sys, P_tot, 'r-');

set(gca,'fontsize',13)
grid(gca,'minor'), grid on

xlim([0, data.time_sys(end)]), xticklabels([])

ylabel('Power [W]','fontsize',14,'interpreter','latex')

title('Delivered power','fontsize',14,'interpreter','latex')

% legend([f1_p1b, f1_p1a], {'Noise-free','Monte Carlo'},'interpreter','latex',...
% 	'Location','northwest','numcolumns',1,'fontsize',12)

% Requested power tracking error
nexttile(2), hold on

e_lim = data.pso_P_req_track_err_lim;

f1_p2b = plot(data.time_mpc, 100*(P_tot_mpc-P_req_mpc)/max(abs(P_req_mpc)),'r-');
yline(-e_lim(2), 'r--')
yline(e_lim(2), 'r--')

set(gca,'fontsize',13)
grid(gca,'minor'), grid on

xlim([0, data.time_mpc(end)])

ylabel('Error [\%]','fontsize',14,'interpreter','latex')

title('Req. power tracking error (normalized)','fontsize',14,'interpreter','latex')

legend([f1_p2b, f1_p2a], {'Noise-free','Monte Carlo'},'interpreter','latex',...
	'Location','southoutside','numcolumns',2,'fontsize',12)

xlabel(tl1, 'Time [s]','fontsize',14,'interpreter','latex')

% ===== 2) Battery / FC power =====

figure(2)

% Battery power
nexttile(1), hold on

f2_p1b = plot(data.time_sys, P_b, 'r-');

set(gca,'fontsize',13)
set(gca,'xminorgrid','on'), grid on

xlim([0, data.time_sys(end)])
ylim([-2e05, 2.5e05]), yticks(-2e05:1e05:2.5e05)

title('Battery power','fontsize',14,'interpreter','latex')

% legend([f2_p1b, f2_p1a], {'Noise-free','Monte Carlo'},'interpreter','latex',...
% 	'Location','northwest','numcolumns',1,'fontsize',12)

% FC power
nexttile(2), hold on

f2_p2b = plot(data.time_sys, P_fc, 'r-');

set(gca,'fontsize',13)
set(gca,'xminorgrid','on'), grid on

set(gca,'fontsize',13)
set(gca,'xminorgrid','on'), grid on

xlim([0, data.time_sys(end)])
ylim([-2e05, 2.5e05]), yticks(-2e05:1e05:2.5e05)

title('Fuel cell power','fontsize',14,'interpreter','latex')

legend([f2_p2b, f2_p2a], {'Noise-free','Monte Carlo'},'interpreter','latex',...
	'Location','southoutside','numcolumns',2,'fontsize',12)

xlabel(tl2,'Time [s]','fontsize',14,'interpreter','latex')
ylabel(tl2,'Power [W]','fontsize',14,'interpreter','latex')

% ===== 3) Supplies =====

SOC_p = 100*(SOC-0)/(1-0);
mh_p = 100*(mh-0)/(data.mh_max-0);

figure(3)

% SOC
nexttile(1), hold on

f3_p1b = plot(data.time_sys, SOC_p, 'r-');

set(gca,'fontsize',13)
set(gca,'xminorgrid','on','yminorgrid','on'), grid on

xlim([0, data.time_sys(end)])
%ylim([0, 100]), yticks(0:20:100)

title('$SOC$','fontsize',14,'interpreter','latex')

% legend([f3_p1b, f3_p1a], {'Noise-free','Monte Carlo'},'interpreter','latex',...
% 	'Location','northwest','numcolumns',1,'fontsize',12)

% H2 mass
nexttile(2), hold on

f3_p2b = plot(data.time_sys, mh_p, 'r-');

set(gca,'fontsize',13)
set(gca,'xminorgrid','on','yminorgrid','on'), grid on

xlim([0, data.time_sys(end)])
%ylim([0, 100]), yticks(0:20:100)

title('$\mathrm{H}_2$ mass','fontsize',14,'interpreter','latex')

legend([f3_p2b, f3_p2a], {'Noise-free','Monte Carlo'},'interpreter','latex',...
	'Location','southoutside','numcolumns',2,'fontsize',12)

xlabel(tl3,'Time [s]','fontsize',14,'interpreter','latex')
ylabel(tl3,'Fill percentage [\%]','fontsize',14,'interpreter','latex')

%% ========== Performances ==========

data = get_data();

load('mc_nn_mpc_bal.mat',...
	'y_0','u_0','y','u','N_mc');

P_req = data.y_r(3,:)';

for i=1:1:N_mc
	
	P_b = u{i}(1,:)';
	P_fc = u{i}(2,:)';

	SOC = y{i}(1,:)'; SOC_end = SOC(end);
	mh = y{i}(2,:)'; mh_end = mh(end);
	P_tot = data.bat_conv_eff*P_b + data.fc_conv_eff*P_fc;

	P_req_mpc = P_req(1:data.Ts_mpc/data.Ts_sys:end);
	P_tot_mpc = P_tot(1:data.Ts_mpc/data.Ts_sys:end);

	e_th = data.P_req_track_err_th;

	P_req_track_err(:,i) = -100*(P_tot_mpc-P_req_mpc)/max(abs(P_req_mpc));

	P_req_track_err_fun = @(x) 1*(x <= min(e_th)) + ...
		(0-1)/(max(e_th)-min(e_th))*(x-max(e_th)).*(and(x > min(e_th), x <= max(e_th))) + ...
		0*(x > max(e_th));

	P_req_track(i) = sum(P_req_track_err_fun(P_req_track_err(:,i)))/length(P_req_mpc);

	bat_cons(i) = 100*(1-(SOC(end)-data.SOC_min)/(SOC(1)-data.SOC_min));

	H2_cons(i) = 100*(1-(mh(end)-data.mh_min)/(mh(1)-data.mh_min));

	tot_cons(i) = (bat_cons(i) + H2_cons(i))/2;

end

fprintf('Battery cons.: [%.2f%%, %.2f%%]\n',min(bat_cons),max(bat_cons))
fprintf('H2 cons.: [%.2f%%, %.2f%%]\n',min(H2_cons), max(H2_cons))
fprintf('Total cons.: [%.2f%%, %.2f%%]\n\n',min(tot_cons), max(tot_cons))

fprintf('Power request satisfaction: [%.2f%%, %.2f%%]\n\n',...
	min(P_req_track)*100, max(P_req_track)*100)

fprintf('Max tracking error: [%.2f%%, %.2f%%]\n\n',...
	min(max(P_req_track_err,[],1),[],2),max(max(abs(P_req_track_err),[],1),[],2))

%% ========== Export images ==========

exportgraphics(f1,'mc_mpc_bal_power_req.pdf','BackgroundColor','w','Resolution',300);
exportgraphics(f2,'mc_mpc_bal_power_split.pdf','BackgroundColor','w','Resolution',300);
exportgraphics(f3,'mc_mpc_bal_supplies.pdf','BackgroundColor','w','Resolution',300);














