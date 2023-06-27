%% Feste Umwelt Parameter
% Hydro2Motion
% Prototyp: Homer
% Stand: 23.01.2020
% edited: Robin Nedella, Timo Freilinger

%% Luft
umwelt_parameter.p_0 = 101325;               % [Pa] Umgebungsdruck
umwelt_parameter.T_0 = 288;                  % [K] Umgebungstemperatur
umwelt_parameter.R = 287.058;                % [J/(kg*K)] spezifische Gaskonstante Luft
umwelt_parameter.kappa = 1.4;                % [-] Isentropenexponent Luft
umwelt_parameter.rho_0 = umwelt_parameter.p_0 / (umwelt_parameter.T_0 * umwelt_parameter.R);    % [kg/m^3]  Umgebungsdichte (ideales Gasgesetz)

%% Ortsabhängig
umwelt_parameter.g = 9.81;   % [m/s^2] Erdbeschleunigung