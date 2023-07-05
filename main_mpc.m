%% MPC control (closed-loop simulation)

clc
clear variables
close all

%% ========== Data ==========

data = get_data();

%% ========== MPC control ==========

[y, u, ~, max_exec_time] = mpc_control(data);

fprintf('\nMax exec. time (MPC, 1 step) = %.4f ms\n',max_exec_time*1e03)

%% ========== Performances ==========

P_req = data.y_r(3,:)';

P_b = u(1,:)';
P_fc = u(2,:)';

SOC = y(1,:)'; SOC_end = SOC(end);
mh = y(2,:)'; mh_end = mh(end);
P_tot = data.bat_conv_eff*P_b + data.fc_conv_eff*P_fc;

P_req_mpc = P_req(1:data.Ts_mpc/data.Ts_sys:end);
P_tot_mpc = P_tot(1:data.Ts_mpc/data.Ts_sys:end);

e_th = data.P_req_track_err_th;

P_req_track_err = -100*(P_tot_mpc-P_req_mpc)/max(abs(P_req_mpc));

P_req_track_err_fun = @(x) 1*(x <= min(e_th)) + ...
	(0-1)/(max(e_th)-min(e_th))*(x-max(e_th)).*(and(x > min(e_th), x <= max(e_th))) + ...
	0*(x > max(e_th));

P_req_track = sum(P_req_track_err_fun(P_req_track_err))/length(P_req_mpc);

bat_cons = 100*(1-(SOC(end)-data.SOC_min)/(SOC(1)-data.SOC_min));

H2_cons = 100*(1-(mh(end)-data.mh_min)/(mh(1)-data.mh_min));

tot_cons = (bat_cons + H2_cons)/2;

fprintf('SoC: %.3f / %.3f    Battery cons.: %.2f%%\n',SOC_end,data.x_in(1),bat_cons)
fprintf('H2 mass: %.3f / %.3f g    H2 cons.: %.2f%%\n',mh_end,data.x_in(2),H2_cons)
fprintf('Total cons.: %.2f%%\n\n',tot_cons)

fprintf('Power request satisfaction: %.2f%%\n\n',P_req_track*100)
fprintf('Max tracking error: %.2f%%\n\n',max(abs(P_req_track_err)))

%% ========== Save MPC data ==========

% save('mpc_track.mat',...
% 	'P_req','P_tot','P_b','P_fc','SOC','mh','max_exec_time');

%% ========== Plots ==========

close all

data = get_data();

% load('mpc_track.mat',...
% 	'P_req','P_tot','P_b','P_fc','SOC','mh','max_exec_time');

P_req_mpc = P_req(1:data.Ts_mpc/data.Ts_sys:end);
P_tot_mpc = P_tot(1:data.Ts_mpc/data.Ts_sys:end);

% ===== 1) Requested power =====

f1 = figure(1); set(f1,'color','w');
f1.Position = [100   100   560   420*0.9];

tl = tiledlayout(2,1,'tilespacing','compact','padding','compact');

% Requested/delivered power
nexttile

plot(data.time_sys, P_req, 'r-'), hold on
plot(data.time_sys, P_tot, 'b-'), hold off

set(gca,'fontsize',13)
grid(gca,'minor'), grid on

xlim([0, data.time_sys(end)]), xticklabels([])

ylabel('Power [W]','fontsize',14,'interpreter','latex')

title('Requested / delivered power','fontsize',14,'interpreter','latex')

legend({'$P_{tot,r}$','$P_{tot}$'},'interpreter','latex',...
	'Location','northwest','numcolumns',2,'fontsize',12)

% Requested power tracking error
nexttile

e_lim = data.pso_P_req_track_err_lim;

plot(data.time_mpc, 100*(P_tot_mpc-P_req_mpc)/max(abs(P_req_mpc)),'r-'), hold on
yline(-e_lim(2), 'r--')
yline(e_lim(2), 'r--'), hold off

set(gca,'fontsize',13)
grid(gca,'minor'), grid on

xlim([0, data.time_mpc(end)])
ylim([-e_lim(2), e_lim(2)]*1.1)

ylabel('Error [\%]','fontsize',14,'interpreter','latex')

title('Req. power tracking error (normalized)','fontsize',14,'interpreter','latex')

xlabel(tl, 'Time [s]','fontsize',14,'interpreter','latex')

% ===== 2) Battery / FC power =====

f2 = figure(2); set(f2,'color','w');
f2.Position = [200   100   560   420*0.9];

tiledlayout(1,1,'tilespacing','none','padding','compact')

nexttile

plot(data.time_sys, P_b, 'b-'), hold on
plot(data.time_sys, P_fc, 'r-'), hold off

set(gca,'fontsize',13)
set(gca,'xminorgrid','on'), grid on

xlim([0, data.time_sys(end)])
ylim([-2e05, 2.5e05]), yticks(-2e05:0.5e05:2.5e05)

xlabel('Time [s]','fontsize',14,'interpreter','latex')
ylabel('Power [W]','fontsize',14,'interpreter','latex')

title('Battery / fuel cell power','fontsize',14,'interpreter','latex')

legend({'$P_{b}$','$P_{fc}$'},'interpreter','latex',...
	'Location','southoutside','numcolumns',2,'fontsize',12)

% ===== 3) Supplies =====

SOC_p = 100*(SOC-0)/(1-0);
mh_p = 100*(mh-0)/(data.mh_max-0);

f3 = figure(3); set(f3,'color','w');
f3.Position = [300   100   560   420*0.9];

tiledlayout(1,1,'tilespacing','none','padding','compact')

nexttile

p1 = plot(data.time_sys, SOC_p, 'b-'); hold on
p2 = plot(data.time_sys, mh_p, 'r-');

p3 = yline(100*(data.SOC_max-0)/(1-0),'b--');
p4 = yline(100*(data.mh_max-0)/(data.mh_max-0),'r--');

yline(100*(data.SOC_min-0)/(1-0),'b--')
yline(100*(data.mh_min-0)/(data.mh_max-0),'r--'), hold off

set(gca,'fontsize',13)
set(gca,'xminorgrid','on'), grid on

xlim([0, data.time_sys(end)])
ylim([0, 100]), yticks(0:10:100)

xlabel('Time [s]','fontsize',14,'interpreter','latex')
ylabel('Fill percentage [\%]','fontsize',14,'interpreter','latex')

title('Supplies','fontsize',14,'interpreter','latex')

legend([p1,p2,p3,p4], {'$SOC$','$\mathrm{H}_2$ mass',...
	'$SOC$ bounds','$\mathrm{H}_2$ mass bounds'},'interpreter','latex',...
	'Location','southoutside','numcolumns',2,'fontsize',12)

%% ========== Export images ==========

% exportgraphics(f1,'mpc_track_power_req.pdf','BackgroundColor','w');
% exportgraphics(f2,'mpc_track_power_split.pdf','BackgroundColor','w');
% exportgraphics(f3,'mpc_track_supplies.pdf','BackgroundColor','w');



















