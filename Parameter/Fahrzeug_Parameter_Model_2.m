%% Feste Fahrzeug Parameter
% Hydro2Motion
% Prototyp: Homer
% Stand: 23.01.2020
% edited: Robin Nedella, Timo Freilinger

%% Allgemeine Fahrzeugdaten
fahrzeug_parameter.cw_A = 0.1222;           % [m^2] Strömungswiderstandsfläche (0.06 theorie, 0.1222 praxis)
fahrzeug_parameter.f_roll = 0.0022;        % [-] Rollwiderstandsbeiwert aus lin. Ausrollversuch (0.0008 theorie, 0.0022 praxis)
fahrzeug_parameter.c_alpha = 50000;        % [N/rad] Schraeglaufsteifgkeiten der Raeder (aus H2M Handbuch)
fahrzeug_parameter.raeder = 3;             % [-] Anzahl der Räder
% Schwerpunkt: x-Richtung vom vorderen zum hinteren Ende des Fahrzeugs,
%              y-Richtung entlang der Vorderachse vom linken zum rechten Rad
%              z-Richtung senkrecht vom Boden nach oben
fahrzeug_parameter.x_sp = 1;            % [m] Lage Schwerpunkt in x-Richtung
fahrzeug_parameter.y_sp = 1;            % [m] Lage Schwerpunkt in y-Richtung
fahrzeug_parameter.z_sp = 1;            % [m] Lage Schwerpunkt in z-Richtung

%% Massen
fahrzeug_parameter.m_lv = 0;                                        % [kg] Masse Fahrzeug links vorne
fahrzeug_parameter.m_rv = 0;                                        % [kg] Masse Fahrzeug rechts vorne
fahrzeug_parameter.m_lh = 0;                                        % [kg] Masse Fahrzeug links hinten
fahrzeug_parameter.m_rh = 41;                                        % [kg] Masse Fahrzeug rechts hinten
fahrzeug_parameter.m_fahrer = 58;                                    % [kg] Masse Fahrer
fahrzeug_parameter.m_ges = fahrzeug_parameter.m_lv + fahrzeug_parameter.m_rv + fahrzeug_parameter.m_lh + fahrzeug_parameter.m_rh + fahrzeug_parameter.m_fahrer;   % [kg] Gesamtmasse

%% Brennstoffzelle
fahrzeug_parameter.hig_h2 = 119.972 * 10^6;     % [J/kg] gravimetrischer Heizwert Wasserstoff
fahrzeug_parameter.hiv_h2 = 2990 * 3600;        % [J/m^3] volumetrischer Heizwert Wasserstoff

%% Sekundärverbräuche
fahrzeug_parameter.P_sekundaer = 5;         % [J/sec] Sekundärverbräuche: 3 Watt Morotcontroller, 6 Watt Elektronik
fahrzeug_parameter.P_BZLuefter = 18;        % [J/sec] Sekundärverbräuche: 12W BZ Lüfter und Ventile, wenn die BZ an ist

%% Motor
% Daten aus Kennfeld von maxon_RE50 Art.Nr. 370354 (Nenn-Kennzahlen beziehen sich auf die Nenn-Spannung!)
fahrzeug_parameter.speed_torque_gradient = - 0.668 * 1000 / 60;    % [rps/Nm] Kennliniensteigung (Drehzahl über Drehmoment)
fahrzeug_parameter.nominal_U = 24;                                 % [V] Nennspannung
fahrzeug_parameter.nominal_speed = 5680 / 60;                      % [rps] Nenndrehzahl
fahrzeug_parameter.nominal_torque = 0.405;                         % [Nm] Nennmoment
fahrzeug_parameter.idle_speed = 5950 / 60;                         % [rps] Leerlaufdrehzahl
fahrzeug_parameter.stall_torque = 8.920;                           % [Nm] Anhaltemoment
fahrzeug_parameter.k_M = 38.5 / 1000;                              % [Nm/A] Drehmomentenkonstante
fahrzeug_parameter.k_n = 245.4 / 60;                               % [rps/V] Drehzahlkonstante
fahrzeug_parameter.R_i = 0.103;                                    % [Ohm] Innenwiderstand Motor
fahrzeug_parameter.J_rotor = 536 *10^-7;                           % [kg*m^2] Trägheitsmoment Rotor

%% Motorcontroller
fahrzeug_parameter.MC_max_voltage_gain = 0.95;                     % [-] Quotient aus Aus- und Eingangsspannung Motorcontroller, was maximal möglich ist

%% Getriebe
fahrzeug_parameter.J_ritzel = 0;                                   % [kg*m^2] Trägheitsmoment Ritzel
fahrzeug_parameter.J_kronenrad = 0.1;                              % [kg*m^2] Trägheitsmoment Kronenrad
fahrzeug_parameter.eta_getriebe = 0.75;                            % [-] Getriebewirkungsgrad                                                                    

%% Supercaps
U_single_cap = 2.7;          % V
C_single_cap = 310;          % F
fahrzeug_parameter.number_cap_pack = 13;        % Anzahl Caps pro Pack
fahrzeug_parameter.number_pack = 2;             % Anzahl der Packs
fahrzeug_parameter.U_SC_nominal = U_single_cap * fahrzeug_parameter.number_cap_pack;                                  % [V] Nominalspannung SC
faktor_kapazitaet = 1;
fahrzeug_parameter.C_SC = fahrzeug_parameter.number_pack * C_single_cap / fahrzeug_parameter.number_cap_pack * faktor_kapazitaet

clear U_single_cap C_single_cap faktor_kapazitaet;

%% Bremse
fahrzeug_parameter.bremskraft_max = 2; % [N] Maximale Bremskraft




%% Reifen (v.a. Hinterrad, also Antriebsreifen)
fahrzeug_parameter.r_dyn = 0.239687344;    % [m] Radius des Antriebsrades, gemessen am 10.05.2018
fahrzeug_parameter.J_r_dyn = 0.149;        % [kg*m^2] Massenträgheitsmoment Hinterrad
fahrzeug_parameter.m_r_dyn = 1;            % [kg] Masse des Hinterrades
fahrzeug_parameter.t_nu = 0;               % [-] Haftreibungskoeffizient (Reifen-Boden)
