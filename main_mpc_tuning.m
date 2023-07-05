%% MPC tuning

clc
clear variables
close all

%% ========== Data ==========

data = get_data();

%% ========== PSO - Settings ==========

pso_ub = data.pso_mpc_w_ub;
pso_lb = data.pso_mpc_w_lb;

num_w = length(pso_ub);

pso_options.pop_size = data.pso_pop_size;
pso_options.max_iter = data.pso_max_iter;
pso_options.inertia = data.pso_w;
pso_options.individual_attraction = data.pso_c_i;
pso_options.social_attraction = data.pso_c_s;
pso_options.borders_type = data.pso_borders_type;

%% ========== PSO - Execution ==========

if isempty(gcp('nocreate'))
	parpool('local');
end

tim1 = tic;

[mpc_weights_opt, swarm_data, cost_data] = ...
	pso_parallel(@(w)pso_obj_fun(w,data), num_w, pso_lb, pso_ub, pso_options);

exec_time = toc(tim1);

fprintf('Elapsed time: %.2f min\n',exec_time/60);

save('pso_mpc_track.mat',...
	'swarm_data','cost_data','mpc_weights_opt','pso_options','num_w','pso_lb','pso_ub')

%% ========== PSO - Plots ==========

close all

load('pso_mpc_track.mat',...
	'swarm_data','cost_data','mpc_weights_opt','pso_options','num_w','pso_lb','pso_ub')

% ===== (1) Costs =====

f1 = figure(1); set(f1,'color','w');
f1.Position = [100   100   560   210];

% tl = tiledlayout(2,1,'tilespacing','compact','padding','compact');
tl = tiledlayout(1,1,'tilespacing','none','padding','compact');

% Particles costs
% tl_ax1 = nexttile(1);
% 
% for i=0:1:pso_options.max_iter
% 	xline(i, 'color', [0.7 0.7 0.7])
% 	x_plot = linspace(i,i+1,pso_options.pop_size+1);
% 	p1 = plot(x_plot(2:end), [swarm_data{i+1}.cost], ...
% 		'.', 'color', [0.7 0 0], 'markersize', 10); hold on
% end
% hold off
% 
% set(gca,'fontsize',13)
% set(gca,'yminorgrid','on'), set(gca,'ygrid','on')
% 
% xlim([0, pso_options.max_iter+1]), xticks(0.5:1:pso_options.max_iter+1), xticklabels(0:1:pso_options.max_iter)
% %ylim([0, 1000])

% Global best cost
%tl_ax2 = nexttile(2);
tl_ax2 = nexttile(1);

p2 = plot(0:1:pso_options.max_iter, cost_data, ...
	'b.-', 'markersize', 20);

set(gca,'fontsize',13)
grid(gca,'minor'), grid on

xlim([0, pso_options.max_iter]), xticks(0:1:pso_options.max_iter)

% xlabel(tl,'Iteration','fontsize',14,'interpreter','latex')
% ylabel(tl,'Cost','fontsize',14,'interpreter','latex')

xlabel('Iteration','fontsize',14,'interpreter','latex')

% title(tl,'Particles costs','fontsize',14,'interpreter','latex')
title(tl,'Global best cost','fontsize',14,'interpreter','latex')

% leg = legend([p1,p2],{'Particles','Global best'},...
% 	'location','southoutside','numcolumns',2,...
% 	'fontsize',12,'interpreter','latex');
% leg.Layout.Tile = 'south';

% zoom_plot(tl, tl_ax1, [0,16,0,750], [4,15.5,3000,9500], ...
% 	{'NW','SW'; 'NE','SE'})
% set(gca,'yminorgrid','on'), set(gca,'ygrid','on')
% xlim([0, pso_options.max_iter+1]), xticks(0.5:1:pso_options.max_iter+1), xticklabels(0:1:pso_options.max_iter)
% ylim([0,500])

% zoom_plot(tl, tl_ax2, [2,10,0,1], [2.5,9.5,15,55], ...
% 	{'NW','SW'; 'NE','SE'})
% grid(gca,'minor'), grid on
% xlim([3,10]), ylim([0.209,0.2125])

% ===== (2) Positions =====

f2 = figure(2); set(f2,'color','w');
f2.Position = [200   100   560   420*0.75];

n_plots = sum(pso_lb ~= pso_ub);

tl = tiledlayout(ceil(n_plots/2),2,'tilespacing','compact','padding','compact');

curr_tile = 1;

for i=1:1:num_w
	
	if pso_lb(i) ~= pso_ub(i)
		
		nexttile(curr_tile), hold on
		
		swarm_data_x_1 = swarm_data{1};
		swarm_data_x = [swarm_data_x_1.x];
		
		p1 = plot(swarm_data_x(i,:), zeros(pso_options.pop_size,1), ...
			'.', 'color', [0.7 0 0], 'markersize', 20);
		
		curr_tile = curr_tile+1;
		
	end
	
end

curr_tile = 1;

for i=1:1:num_w
	
	if pso_lb(i) ~= pso_ub(i)
		
		nexttile(curr_tile)
		
		swarm_data_x_1 = swarm_data{end};
		swarm_data_x = [swarm_data_x_1.x];
		
% 		if i==num_w
% 			p2 = plot(swarm_data_x(i,:)-10, zeros(pso_options.pop_size,1), ...
% 			'.', 'color', [0 0 0.8], 'markersize', 20);
% 		else
			p2 = plot(swarm_data_x(i,:), zeros(pso_options.pop_size,1), ...
			'.', 'color', [0 0 0.8], 'markersize', 20);
% 		end
		
		p3 = plot([mpc_weights_opt(i), mpc_weights_opt(i)],[-0.1, 0.1], ...
			'g-','linewidth', 1.5);
		hold off
		
		set(gca,'fontsize',11)
		set(gca,'xminorgrid','on'), grid on
		
		h_curr = gca;
		if h_curr.XAxis.Exponent > 0
			h_curr.XAxis.Exponent = 0;
			h_curr.XAxis.TickLabelFormat = '%.0e';
		end
		
		xlim([0, pso_ub(i)])
		ylim([-0.1, 0.1]), yticks([])
		
		ylabel(sprintf('$w_{%d}$',i),'interpreter','latex','fontsize',14)
		
		curr_tile = curr_tile+1;
		
	end
	
end

title(tl,'Particles positions','fontsize',14,'interpreter','latex')

leg = legend([p1,p2,p3],...
	{'Positions at first iter.','Positions at last iter.','Best weights'},...
	'NumColumns',3,'fontsize',10,'interpreter','latex');
leg.Layout.Tile = 'south';

%% ========== PSO - Export images ==========

exportgraphics(f1,'pso_cost.pdf','BackgroundColor','w');
exportgraphics(f2,'pso_part_pos.pdf','BackgroundColor','w');





%% ========== Auxiliary functions ==========

%% ===== PSO objective function =====
function f_val = pso_obj_fun(mpc_weights, data)

P_req = data.y_r(3,:)';

% MPC simulation

[y, u, ~, ~] = mpc_control(data, mpc_weights);

P_b = u(1,:)';
P_fc = u(2,:)';
P_tot = data.bat_conv_eff*P_b + data.fc_conv_eff*P_fc;

P_req_mpc = P_req(1:data.Ts_mpc/data.Ts_sys:end);
P_tot_mpc = P_tot(1:data.Ts_mpc/data.Ts_sys:end);

SOC = y(1,:)';
mh = y(2,:)';

SOC_1 = data.x_in(1);
mh_1 = data.x_in(2);

SOC_end = SOC(end);
mh_end = mh(end);

% Objective function eval

P_req_track_err = max( abs( 100*(P_tot_mpc-P_req_mpc)/max(abs(P_req_mpc)) ) );

e_lim = data.pso_P_req_track_err_lim;

if (P_req_track_err >= min(e_lim)) && (P_req_track_err <= max(e_lim))
	cost_P_req_track = 1e-04*( min(e_lim) - P_req_track_err )^2;
else
	cost_P_req_track = ( min(e_lim) - P_req_track_err )^2;
end

cost_bat_cons = ( 1 - (SOC_end-data.SOC_min)/(SOC_1-data.SOC_min) )^2;

cost_H2_cons = ( 1 - (mh_end-data.mh_min)/(mh_1-data.mh_min) )^2;

f_val = (data.pso_coef(1)*cost_P_req_track + ...
	data.pso_coef(2)*cost_bat_cons + ...
	data.pso_coef(3)*cost_H2_cons)/sum(data.pso_coef);

end










