%% Discrete-time plant model

function [x2,y1] = plant_dt(x1,u1,data)

[x1d,y1] = plant_ct(x1,u1,data);
x2 = x1 + x1d*data.Ts_sys;
	
end