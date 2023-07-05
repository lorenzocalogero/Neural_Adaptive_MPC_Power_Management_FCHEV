function [x_best, swarm_data, cost_data] = pso_parallel(fun,n_vars,lb,ub,options)

var_size = [n_vars, 1];

cost_data = [];

if nargin == 4
	options.pop_size = 50;
	options.max_iter = 50;
	options.inertia = [0.9 0.2];
	options.individual_attraction = 2;
	options.social_attraction = 2;
	options.borders_type = 'absorb';
end

pop_size = options.pop_size;
max_iter = options.max_iter;

if length(options.inertia) == 1
	w = linspace(options.inertia,options.inertia,max_iter);
elseif length(options.inertia) == 2
	w = linspace(options.inertia(1),options.inertia(2),max_iter);
end

c_i = options.individual_attraction;
c_s = options.social_attraction;

particle.x=[];
particle.v=[];
particle.cost=[];
particle.best.x=[];
particle.best.cost=[];
swarm=repmat(particle,pop_size,1);

global_best.x = [];
global_best.cost = inf;

v_norm_coef = 0.75;
v_norm_max = v_norm_coef*norm((ub-lb)/2);

parfor i=1:pop_size % Parfor
	
	fprintf('Initializing particles: %d / %d\n', i, pop_size)

	swarm(i).x = unifrnd(lb,ub,var_size);

	swarm(i).v = unifrnd(lb,ub,var_size);
	
	if norm(swarm(i).v) > v_norm_max
		swarm(i).v = swarm(i).v/norm(swarm(i).v) * v_norm_max;
	end

	swarm(i).cost = fun(swarm(i).x);

	swarm(i).best.x = swarm(i).x;
	swarm(i).best.cost = swarm(i).cost;

end

for i=1:1:pop_size
	if swarm(i).best.cost < global_best.cost
		global_best = swarm(i).best;
	end
end

clc

swarm_data{1} = swarm;
cost_data = [cost_data; global_best.cost];

x_best = global_best.x;
	
fprintf('Best: [')
fprintf('%g, ', x_best(1:end-1))
fprintf('%g]\n', x_best(end))

fprintf('Best cost: %.6f\n\n', global_best.cost)

for iter = 1:1:max_iter

	parfor i=1:pop_size % Parfor

		swarm(i).v = w(iter)*swarm(i).v + ...
			c_i*rand(var_size).*(swarm(i).best.x - swarm(i).x) + ...
			c_s*rand(var_size).*(global_best.x - swarm(i).x);
		
		if norm(swarm(i).v) > v_norm_max
			swarm(i).v = swarm(i).v/norm(swarm(i).v) * v_norm_max;
		end
		
		swarm(i).x = swarm(i).x + swarm(i).v;

		if isequal(options.borders_type, 'reflect')
			is_outside = (swarm(i).x < lb | swarm(i).x > ub);
			swarm(i).v(is_outside) = -swarm(i).v(is_outside);
		elseif isequal(options.borders_type, 'absorb')
			is_outside = (swarm(i).x < lb | swarm(i).x > ub);
			swarm(i).v(is_outside) = 0;
		end

		swarm(i).x = max(swarm(i).x,lb);
		swarm(i).x = min(swarm(i).x,ub);

		swarm(i).cost = fun(swarm(i).x);

		if swarm(i).cost < swarm(i).best.cost

			swarm(i).best.x = swarm(i).x;
			swarm(i).best.cost = swarm(i).cost;

		end
		
		fprintf('PSO: iteration %d, particle %d - Cost: %.6f\n', iter, i, swarm(i).cost)

	end
	
	for i=1:1:pop_size
		if swarm(i).best.cost < global_best.cost
			global_best = swarm(i).best;
		end
	end
	
	swarm_data{iter+1} = swarm;
	cost_data = [cost_data; global_best.cost];
	
	x_best = global_best.x;
	
	fprintf('Best: [')
	fprintf('%g, ', x_best(1:end-1))
	fprintf('%g]\n', x_best(end))
	
	fprintf('Best cost: %.6f\n\n', global_best.cost)

end

end


