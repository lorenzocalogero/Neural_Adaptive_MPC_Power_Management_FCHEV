%% ========== [ NN function ] ==========
function y = net_fun(net_data, x)

x_p = zeros(net_data.in_size,1);
y = zeros(net_data.out_size,1);

% NN input rescaling
for i = 1:1:length(x)
	x_p(i) = net_data.map(x(i), net_data.in_range(i,:), net_data.in_proc_range(i,:));
end

% NN computation
W_i = net_data.W_i;
W_h = net_data.W_h;
b_h = net_data.b_h;
b_o = net_data.b_o;

y_p = tanh(W_i*x_p + b_h{1});
for i=2:1:net_data.n_layers-1
	y_p = tanh(W_h{i-1}*y_p + b_h{i});
end
y_p = W_h{net_data.n_layers-1}*y_p + b_o;

% NN output rescaling
for i = 1:1:length(y_p)
	y(i) = net_data.map(y_p(i), net_data.out_proc_range(i,:), net_data.out_range(i,:));
end

end