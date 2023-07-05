%% ========== [ Get NN data ] ==========
function net_data = get_net_data(net)

% ========== Net data ==========

in_size = net.inputs{end}.size;
out_size = net.outputs{end}.size;

n_layers = net.numLayers;

W_i = cell2mat(net.IW(1));
for i=1:1:n_layers-1
	W_h{i} = cell2mat(net.LW(i+1,i));
	b_h{i} = cell2mat(net.b(i));
end
b_o = cell2mat(net.b(n_layers));

in_range = net.inputs{1}.range;
in_proc_range = net.inputs{1}.processedRange;
out_range = net.outputs{1,n_layers}.range;
out_proc_range = net.outputs{1,n_layers}.processedRange;

map = @(x, ir, or) or(1) + ((or(2) - or(1)) / (ir(2) - ir(1))) * (x - ir(1));

% ========== Data struct ==========

net_data.in_size = in_size;
net_data.out_size = out_size;
net_data.n_layers = n_layers;

net_data.W_i = W_i;
net_data.W_h = W_h;
net_data.b_h = b_h;
net_data.b_o = b_o;

net_data.in_range = in_range;
net_data.in_proc_range = in_proc_range;
net_data.out_range = out_range;
net_data.out_proc_range = out_proc_range;

net_data.map = map;

end













