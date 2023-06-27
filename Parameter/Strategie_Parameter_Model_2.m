%% Strategie Parameter
% Hydro2Motion
% Prototyp: Homer
% Stand: 23.01.2020
% edited: Robin Nedella, Timo Freilinger

%% Muss nach "Initialisierung" ausgeführt werden!

%% ________________________________________________________________________________________________
% !!!!!!!!!!!!!!
% Auskommentierte Sachen sind in "Normale Berechnung" bzw. "Automatisierung" extra wiederzufinden
% !!!!!!!!!!!!!!
%% ________________________________________________________________________________________________

%% Wettbewerbsabhängige Vorgaben
strategie_parameter.t_gesamt_zul = strecke.max_Dauer * 60;                               % [s] mögliche Gesamtzeit vorgegeben
strategie_parameter.runde_gesamt_zul = strecke.Rundenzahl;                          % [-] Rundenzahl
strategie_parameter.laenge_gesamt = strategie_parameter.runde_gesamt_zul * max(strecke.distanz_3d);   % aus bereits geladener Streckenmatrix wird letzter Punkt genommen
strategie_parameter.runde_sim = strecke.Rundenzahl;                                 % [-] zu simulierende Runden

%% Durchschnittsgeschwindigkeit (nötig, um vorgegebene Strecke in vorgegebener Zeit zu schaffen)
strategie_parameter.v_durch = round( (strategie_parameter.laenge_gesamt / strategie_parameter.t_gesamt_zul) * 100) / 100;     % [m/s] aus gegebener Strecke und Zeit berechnete Durchschnittsgeschwindigkeit, gerundet auf 2 Nachkommastellen

%% Zeit-Puffer Beladung SC am Ende des Rennens
strategie_parameter.end_charge_Zeitpuffer = 30; %[s]

%% Strategie Gas geben
% % anhand v_durch und Bandbreite mit max. Abweichung zur v_durch (+/-) wird bei Überschreiten durch fps_neu nachgeregelt
% strategie_parameter.dv_min = 1;         % Abstand untere Grenze der Bandbreite zur Durchschnittsgeschwindigkeit
% strategie_parameter.dv_max = 2;         % Abstand obere Grenze der Bandbreite zur Durchschnittsgeschwindigkeit
strategie_parameter.min_gas_zeit_kurve = 3; % [s] Zeit, die mindestens vor einer Kurve Gas gegeben werden können muss, bevor der Radius zu klein wird
% !! Kritischer Radius muss größer als kleinster in strecke.radius hinterlegter sein !!
% oder gleich Null, falls es ignoriert werden soll (dieser Fall ist abgesichert)
strategie_parameter.crit_radius_gas = 2;   % [m] kein Gas bei Kurvenradius kleiner als dieser

%% Untere Geschwindigkeitsgrenze
% strategie_parameter.v_low = 10 / 3.6;      % [m/s] untere Geschwindigkeitsgrenze, bei der trotz Kurve/... Gas gegeben wird
% strategie_parameter.dv_low_down = 1;       % Abstand untere Grenze der Bandbreite zur minimalen Geschwindigkeit
% strategie_parameter.dv_low_up = 2;         % Abstand obere Grenze der Bandbreite zur minimalen Geschwindigkeit

%% Übersetzung
% strategie_parameter.i_getriebe_vec = [11];              % mögliche Übersetzungen

%% gefahrener Strom
% strategie_parameter.I_max = 8;     % [A]