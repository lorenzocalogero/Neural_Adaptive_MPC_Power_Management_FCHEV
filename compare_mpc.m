%% Compare MPC and NN-MPC results

clc
clear variables
close all

%% ========== Data ==========

data = get_data();

load('nn_mpc_bal.mat',...
	'P_req','P_tot','P_b','P_fc','SOC','mh','max_exec_time');

P_tot_nn = P_tot;
P_b_nn = P_b;
P_fc_nn = P_fc;
SOC_nn = SOC;
mh_nn = mh;
max_exec_time_nn = max_exec_time;

load('mpc_bal.mat',...
	'P_tot','P_b','P_fc','SOC','mh','max_exec_time');

%% ========== Plots ==========

close all

% ===== (1) Requested power =====

f1 = figure(1); set(f1,'color','w');
f1.Position = [100   100   560   420*0.65];

tl = tiledlayout(1,1,'tilespacing','none','padding','compact');

% Requested/delivered power
nexttile

plot(data.time_sys, 100*(P_tot_nn-P_tot)/max(abs(P_tot)), 'r-')

e_lim = max( max(abs(100*(P_tot_nn-P_tot)/max(abs(P_tot)))),10 );

set(gca,'fontsize',13)
grid(gca,'minor'), grid on

xlim([0, data.time_sys(end)])
ylim([-e_lim*1.1,e_lim*1.1])

xlabel('Time [s]','fontsize',14,'interpreter','latex')
ylabel('Error [\%]','fontsize',14,'interpreter','latex')

title('Deliv. power error (normalized)','fontsize',14,'interpreter','latex')

% ===== (2) Battery / FC power =====

f2 = figure(2); set(f2,'color','w');
f2.Position = [200   100   560   420*0.9];

tl = tiledlayout(2,1,'tilespacing','compact','padding','compact');

nexttile

plot(data.time_sys, 100*(P_b_nn-P_b)/max(abs(P_b)), 'b-')

e_lim = max( max(abs(100*(P_b_nn-P_b)/max(abs(P_b)))),10 );

set(gca,'fontsize',13)
grid(gca,'minor'), grid on

xlim([0, data.time_sys(end)]), xticklabels([])
ylim([-e_lim*1.1,e_lim*1.1])

title('Battery power error (normalized)','fontsize',14,'interpreter','latex')

nexttile

plot(data.time_sys, 100*(P_fc_nn-P_fc)/max(abs(P_b)), 'r-')

e_lim = max( max(abs(100*(P_fc_nn-P_fc)/max(abs(P_b)))),10 );

set(gca,'fontsize',13)
grid(gca,'minor'), grid on

xlim([0, data.time_sys(end)])
ylim([-e_lim*1.1,e_lim*1.1])

title('Fuel cell power error (normalized)','fontsize',14,'interpreter','latex')

ylabel(tl,'Error [\%]','fontsize',14,'interpreter','latex')
xlabel(tl,'Time [s]','fontsize',14,'interpreter','latex')

% ===== (3) Supplies =====

SOC_p = 100*(SOC-0)/(1-0);
mh_p = 100*(mh-0)/(data.mh_max-0);

SOC_p_nn = 100*(SOC_nn-0)/(1-0);
mh_p_nn = 100*(mh_nn-0)/(data.mh_max-0);

f3 = figure(3); set(f3,'color','w');
f3.Position = [300   100   560   420*0.9];

tl = tiledlayout(2,1,'tilespacing','compact','padding','compact');

nexttile

plot(data.time_sys, SOC_p_nn-SOC_p, 'b-')

e_lim = max(abs(SOC_p_nn-SOC_p));

set(gca,'fontsize',13)
grid(gca,'minor'), grid on

xlim([0, data.time_sys(end)]), xticklabels([])
ylim([-e_lim*1.1,e_lim*1.1])

title('$SOC$ error','fontsize',14,'interpreter','latex')

nexttile

plot(data.time_sys, mh_p_nn-mh_p, 'r-')

e_lim = max(abs(mh_p_nn-mh_p));

set(gca,'fontsize',13)
grid(gca,'minor'), grid on

xlim([0, data.time_sys(end)])
ylim([-e_lim*1.1,e_lim*1.1])

title('$\mathrm{H}_2$ mass error','fontsize',14,'interpreter','latex')

ylabel(tl,'Error [\%]','fontsize',14,'interpreter','latex')
xlabel(tl,'Time [s]','fontsize',14,'interpreter','latex')

%% ========== Export images ==========

% exportgraphics(f1,'comp_mpc_bal_power_req.pdf','BackgroundColor','w');
% exportgraphics(f2,'comp_mpc_bal_power_split.pdf','BackgroundColor','w');
% exportgraphics(f3,'comp_mpc_bal_supplies.pdf','BackgroundColor','w');


















