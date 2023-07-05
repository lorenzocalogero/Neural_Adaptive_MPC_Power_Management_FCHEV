%% Get battery cell data

clc
clear variables
close all

%% ========== External data ==========

load('bat_Voc_vs_SOC_data.mat',...
	'SOC_Voc_data');
load('bat_Ro_vs_SOC_data.mat',...
	'SOC_Ro_data');

SOC_Voc = SOC_Voc_data;
SOC_Ro = SOC_Ro_data;

%% ========== Battery data ==========

bat_stack_num = 200;
I_b_max = 350; % [A]

% ===== Plots =====

% Input data
f1 = figure(1); set(f1,'color','w')
tiledlayout(2,1,'tilespacing','compact','padding','compact')

nexttile

plot(SOC_Voc(:,1),SOC_Voc(:,2),'b.'), hold on

nexttile

plot(SOC_Ro(:,1),SOC_Ro(:,2),'b.'), hold on

% ===== Power =====

P_b_min = -bat_stack_num*max(SOC_Voc(:,2))*I_b_max; % [W]
P_b_max_data = bat_stack_num*max(SOC_Voc(:,2))*I_b_max; % [W]
P_b_delta_min = -(P_b_max_data-P_b_min)*0.1; % [W/s]
P_b_delta_max = (P_b_max_data-P_b_min)*0.1; % [W/s]

% ===== Save data =====

save('bat_power_data.mat',...
	'bat_stack_num','P_b_min','P_b_max_data','P_b_delta_min','P_b_delta_max');

% ===== Piecewise constr. poly fit =====

% Voc fit
deg = [3, 3, 3, 3]; % Degree of each piece
xc = [0, 0.25, 0.5, 0.75, 1]; % Constraint points (bounds of each piece interval)
yc = [3.41, 3.69, 3.87, 4, 4.13];

p_Voc = piecewise_polyfit_constrained(SOC_Voc(:,1), SOC_Voc(:,2), xc, yc, deg);

Voc_bat_cell = @(z) polyval(p_Voc{1},z)*(z >= xc(1) & z <= xc(2)) + ...
	polyval(p_Voc{2},z)*(z >= xc(2) & z <= xc(3)) + ...
	polyval(p_Voc{3},z)*(z >= xc(3) & z <= xc(4)) + ...
	polyval(p_Voc{4},z)*(z >= xc(4) & z <= xc(5));

% Ro fit
deg = [3, 3, 3, 3];
xc = [0, 0.25, 0.5, 0.75, 1];
yc = [2.3e-03, 2.15e-03, 2.046e-03, 1.995e-03, 2e-03];

p_Ro = piecewise_polyfit_constrained(SOC_Ro(:,1), SOC_Ro(:,2), xc, yc, deg);

Ro_bat_cell = @(z) polyval(p_Ro{1},z)*(z >= xc(1) & z <= xc(2)) + ...
	polyval(p_Ro{2},z)*(z >= xc(2) & z <= xc(3)) + ...
	polyval(p_Ro{3},z)*(z >= xc(3) & z <= xc(4)) + ...
	polyval(p_Ro{4},z)*(z >= xc(4) & z <= xc(5));

% ===== Save data =====
save('bat_Voc_Ro_fun.mat',...
	'Voc_bat_cell','Ro_bat_cell');

%% ========== Plots ==========

% ===== Fitted data =====

SOC_plot = linspace(0,1);

for i=1:1:length(SOC_plot)
	Voc_plot(i) = Voc_bat_cell(SOC_plot(i));
	Ro_plot(i) = Ro_bat_cell(SOC_plot(i));
end

figure(1)

nexttile(1)

plot(SOC_plot,Voc_plot,'r-'), hold off

set(gca,'fontsize',12)
grid(gca,'minor'), grid on

xlim([0, 1]), xticks(0:0.1:1)
ylim([min(Voc_plot), max(Voc_plot)])

xlabel('$SOC$','fontsize',14,'interpreter','latex')
ylabel('$V_{oc,s}$ [V]','fontsize',14,'interpreter','latex')

nexttile(2)

plot(SOC_plot,Ro_plot,'r-'), hold off

set(gca,'fontsize',12)
grid(gca,'minor'), grid on

xlim([0, 1]), xticks(0:0.1:1)
ylim([min(Ro_plot), max(Ro_plot)])

xlabel('$SOC$','fontsize',14,'interpreter','latex')
ylabel('$R_{o,s}$ [$\Omega$]','fontsize',14,'interpreter','latex')












