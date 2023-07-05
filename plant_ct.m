%% Continuous-time plant model

function [x1d,y1] = plant_ct(x1,u1,data)

% ===== Current state and input =====
SOC_1 = x1(1);
P_b1 = u1(1);

% ===== Battery =====
Voc_bat = @(SOC) data.bat_stack_num*data.Voc_bat_cell(SOC);

Ro_bat = @(SOC) data.bat_stack_num*data.Ro_bat_cell(SOC);

I_b = @(SOC, P_b) Voc_bat(SOC)/(2*Ro_bat(SOC)) - sqrt( (Voc_bat(SOC)/(2*Ro_bat(SOC)))^2 - ...
	P_b/Ro_bat(SOC) );

if I_b(SOC_1, P_b1) > 0
	K = 1/data.bat_coul_eff;
else
	K = data.bat_coul_eff;
end

SOC_d = @(SOC, P_b) -K/data.Q_nom * I_b(SOC, P_b);

% ===== Fuel cell =====
I_fc = @(P_fc) (1/(2*data.fc_stack_num*data.Ro_fc_s))*...
	(data.fc_stack_num*(data.Voc_fc_s-data.V_aux_fc_s) - ...
	sqrt( data.fc_stack_num^2*(data.Voc_fc_s-data.V_aux_fc_s)^2 - ...
	4*data.fc_stack_num*data.Ro_fc_s*(P_fc + data.P_aux_0_fc) ));

n_e = 2;
q = 1.602176634e-19; % Elemental charge [C]
M_h = 2.106; % H2 molar mass [g/mol]
N_A = 6.02214076e23; % Avogadro's number [1/mol]

mh_d = @(P_fc) -data.fc_stack_num * (I_fc(P_fc)*M_h)/(n_e*q*N_A);

% ===== Total delivered power =====
P_tot = @(P_b,P_fc) data.bat_conv_eff*P_b + data.fc_conv_eff*P_fc;

% ===== CT model =====
fc = @(x,u) [SOC_d(x(1),u(1)); mh_d(u(2))];
gc = @(x,u) [x(1); x(2); P_tot(u(1),u(2))];

% ===== CT model eval. =====
x1d = fc(x1,u1);
y1 = gc(x1,u1);

end
