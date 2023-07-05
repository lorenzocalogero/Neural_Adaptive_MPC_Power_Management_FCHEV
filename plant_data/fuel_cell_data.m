%% Get fuel cell data

clc
clear variables
close all

%% ========== External data ==========

load('fc_char_curve_data.mat')

%% ========== Fuel cell data ==========

fc_stack_num = 500;
A_fc = 400; % [cm^2]

I_fc_s = fc_char_curve_data(:,1)*A_fc; % [A]
V_fc_s = fc_char_curve_data(:,2); % [V]

% ===== Power =====

P_fc_s = V_fc_s.*I_fc_s; % [W]

P_fc_min = 0;
P_fc_max_data = max(P_fc_s)*fc_stack_num;
P_fc_delta_min = -(P_fc_max_data-P_fc_min)*0.1;
P_fc_delta_max = (P_fc_max_data-P_fc_min)*0.1;

p_pol_curve_s = polyfit(I_fc_s(6:end),V_fc_s(6:end),1);

Voc_fc_s = p_pol_curve_s(2); % [V]
Ro_fc_s = abs(p_pol_curve_s(1)); % [Ohm]

P_aux_0_fc = 100; % [W]
V_aux_fc_s = 0.05; % [V]

save('fc_power_data.mat',...
	'fc_stack_num','P_fc_min','P_fc_max_data','P_fc_delta_min','P_fc_delta_max',...
	'Voc_fc_s','Ro_fc_s','P_aux_0_fc','V_aux_fc_s');

%% ========== Plots ==========

% ===== Characteristic curve =====

I_fc_plot = linspace(min(I_fc_s),max(I_fc_s));

f1 = figure(1); set(f1,'color','w')
tiledlayout(1,1,'tilespacing','none','padding','compact')

nexttile

p1 = plot(I_fc_plot, polyval(p_pol_curve_s,I_fc_plot), 'r-','linewidth',1.25); hold on
p2 = plot(I_fc_s, V_fc_s, 'b.-','markersize',10); hold off

set(gca,'fontsize',14)
grid(gca,'minor'), grid on

xlim([0, max(I_fc_s)]), xticks(0:20:max(I_fc_s))
ylim([min(V_fc_s), max(V_fc_s)])

xlabel('$I_{fc,s}$ [A]','fontsize',14,'interpreter','latex')
ylabel('$V_{fc,s}$ [V]','fontsize',14,'interpreter','latex')

legend([p2 p1],{'Measurements','Linear fitting'},...
	'fontsize',12,'interpreter','latex','location','northeast')














