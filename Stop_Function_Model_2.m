%% Stop Funktion
% Hydro2Motion
% Prototyp: Homer
% Stand: 23.01.2020
% edited: Robin Nedella, Timo Freilinger
% disp('Stop Fuction start...')

%% Zeitstempel zur übersichtlichen Benennung der Simulationsergebnisse
clock1 = clock;
yyyy = clock1(1,1);
mm = clock1(1,2);
dd = clock1(1,3);
hh = clock1(1,4);
min = clock1(1,5);
sec = floor(clock1(1,6));

%% Matrix aus Simout Ergebnissen erstellen
%% Reported average of dv_min and dv_max
average_dv_min = mean(strategie_parameter.dv_min);
average_dv_max = mean(strategie_parameter.dv_max);
%% Fahrwiderstände
simout_col_num_DR = length(Driving_Resistances.Data(1,:));      % Zahl der Spalten in Simout
for wuobuocv = 1:simout_col_num_DR
    DR(:,wuobuocv) = Driving_Resistances.Data(:,wuobuocv);
end
%Steigungswiderstand energy loss
DR(:,simout_col_num_DR+1) = ts*DR(:,3).*DR(:,6);
%Rollwiderstand energy loss
DR(:,simout_col_num_DR+2) = ts*DR(:,3).*DR(:,7);
%Luftwiderstand energy loss
DR(:,simout_col_num_DR+3) = ts*DR(:,3).*DR(:,8);
%Kurvenwiderstand energy loss
DR(:,simout_col_num_DR+4) = ts*DR(:,3).*DR(:,9);

colNames_DR = {
        'Zeit',                             % [s]
        'Position',                         % [m]
        'Geschwindigkeit',                  % [m/s]
        'Beschleunigung',                   % [m/s^2]
        'fps',
        'Steigungswiderstand',
        'Rollwiderstand',
        'Luftwiderstand',
        'Kurvenwiderstand',
        'Steigung_loss',
        'Roll_loss',
        'Luft_loss',
        'Kurven_loss'
        };
Driving_Resistances_Table = array2table(DR,'VariableNames',colNames_DR);

%fileDR = strcat('DRsim_',num2str(yyyy),'_',num2str(mm),'_',num2str(dd),'_',num2str(hh),'_',num2str(min),'_',num2str(sec),'_I_',num2str(strategie_parameter.I_max),'__i_getr_',num2str(strategie_parameter.i_getriebe_vec),'__U_low_',num2str(fahrzeug_parameter.U_SC_min),'__U_up_',num2str(fahrzeug_parameter.U_SC_initial),'__dv_min_',num2str(average_dv_min),'__dv_max_',num2str(average_dv_max));
%fileDR = strrep(fileDR,'.','k');                         % "k" steht für Komma
%save(strcat('Simulation_Ergebnisse\',fileDR,'.mat'),'Driving_Resistances_Table');


%%
% Was in welcher Spalte steht, findet man im Simulink-Modell, oberste
% Ebene > Datenablage, Speicher-MUX
simout_col_num = length(simout.Data(1,:));      % Zahl der Spalten in Simout
for bnj = 1:simout_col_num
    ablage(:,bnj) = simout.Data(:,bnj);
end

%if akt_konfig_ungeeignet == 0 && ablage(end,1) <= (strecke.max_Dauer * 60)   % dann hat Berechnung geklappt
    %% Energiebedarf Motor gesamt berechnen
    Energiebedarf_Motor = sum(ablage(:,12)*ts);           % Multiplizieren von Leistungsbedarf in Zeitschritt mit Zeitinkrement und Addieren auf gesamt
    ablage(1,simout_col_num+1) = Energiebedarf_Motor;

    %% Reichweite Motor pro 10 kWh (ungefähr 1L Benzin) berechnen
    energie_1_L_benzin = 10;                                        % [kWh] Energie pro Liter Benzin
    reichweite_Motor_10_kWh = max(strecke.distanz_3d) * strategie_parameter.runde_sim / 1000 * (energie_1_L_benzin * 3600 * 1000/ Energiebedarf_Motor);
    ablage(1,simout_col_num+3) = reichweite_Motor_10_kWh;

    %% Energiebedarf BZ gesamt berechnen
    Energiebedarf_BZ = sum(ablage(:,23)*ts);           % Multiplizieren von Leistungsbedarf in Zeitschritt mit Zeitinkrement und Addieren auf gesamt
    ablage(1,simout_col_num+2) = Energiebedarf_BZ;

    %% Reichweite BZ pro 10 kWh (ungefähr 1L Benzin) berechnen
    reichweite_BZ_10_kWh = max(strecke.distanz_3d) * strategie_parameter.runde_sim / 1000 * (energie_1_L_benzin * 3600 * 1000/ Energiebedarf_BZ);
    ablage(1,simout_col_num+4) = reichweite_BZ_10_kWh;
% else    % dann hat Berechnung nicht geklappt
%     ablage(1,simout_col_num+3) = 0;         % keine Reichweite
%     ablage(1,simout_col_num+4) = 0;         % keine Reichweite
% end    

%% Spalten in Matrix benennen
colNames = {
        'Zeit',                             % [s]
        'Position',                         % [m]
        'Position_in_Runde',                % [m]
        'Zeilennr_in_strecke',              % [-]
        'fertige_Runden',                   % [-]
        'Geschwindigkeit',                  % [m/s]
        'Beschleunigung',                   % [m/s^2]
        'fps',                              % [-] 0: kein Gas (Ausrollen), 1: Gas
        'aktuelle_Motordrehzahl',           % [1/min]
        'maximale_akt_Motordrehzahl',       % [1/min]
        'Widerstand_gesamt',                % [N]
        'Leistungsbedarf_Motorcontroller',  % [W]
        'Leistungsabgabe_Hinterrad',        % [W]
        'Motor_Moment',                     % [-]
        'Motor_Wirkungsgrad',               % [Nm]
        'Spannung',                         % [V]
        'Strom',                            % [A]
        'Kurvenwiderstand',                 % [N]
        'Radius',                           % [m]
        'Hoehe',                            % [m]
        'Steigungswiderstand',              % [N]
        'Spannung_SC',                      % [V]
        'Leistungsbedarf_BZ',               % [W]
        'eta_BZ_aktuell',                   % [-]
        'Zwangsgas',                        % [-]
        'Hoehenradius',                     % [m]
        'Energiebedarf_Motor_gesamt',       % [J]
        'Energiebedarf_BZ_gesamt',          % [J]
        'Reichweite_Motor_1_L_Benzin_km'    % [km] Reichweite Motor pro Liter Benzin äquivalent
        'Reichweite_BZ_1_L_Benzin_km'       % [km] Reichweite BZ pro Liter Benzin äquivalent
        };
ablage_table = array2table(ablage,'VariableNames',colNames);    % Tabelle mit Spaltenbeschriftung
% Umbenennen der Tabelle im Workspace
ablage_table_name = strcat('I_',num2str(strategie_parameter.I_max),'__i_getr_',num2str(strategie_parameter.i_getriebe_vec),'__U_low_',num2str(fahrzeug_parameter.U_SC_min),'__U_up_');
ablage_table_name = strrep(ablage_table_name,'.','k');      % "k" steht für Komma
ablage_table_name = strrep(ablage_table_name,'-','n');      % "n" steht für negativ

%cmdstr = [ablage_table_name,' = ','ablage_table',';'];
%evalin('base',cmdstr);

%% Daten speichern (Zeitstempel im Namen)
% nur speichern, wenn kein stehen bleiben
% wenn stehengeblieben trotz zwangsgas-versuch: auch speichern
if akt_konfig_ungeeignet == 0 && ablage_table.Geschwindigkeit(end) >= 0 && ablage_table.Zeit(end) <= (strecke.max_Dauer * 60)           % dann war Simulation erfolgreich ohne Stehenbleiben
    ordner_existiert = exist('Simulation_Ergebnisse');
    if ordner_existiert ~= 7
        mkdir('Simulation_Ergebnisse');
    end
    filename = strcat('sim_',num2str(yyyy),'_',num2str(mm),'_',num2str(dd),'_',num2str(hh),'_',num2str(min),'_',num2str(sec),'_I_',num2str(strategie_parameter.I_max),'__i_getr_',num2str(strategie_parameter.i_getriebe_vec),'__U_low_',num2str(fahrzeug_parameter.U_SC_min),'__U_up_',num2str(fahrzeug_parameter.U_SC_initial),'__dv_min_',num2str(average_dv_min),'__dv_max_',num2str(average_dv_max));
    filename = strrep(filename,'.','k');                         % "k" steht für Komma
    save(strcat('Simulation_Ergebnisse\',filename,'.mat'),'ablage_table');
    disp('Rechnung erfolgreich.')
elseif akt_konfig_ungeeignet == 1                                                   % dann ist aktuelle Konfiguration ungeeignet
    ordner_existiert = exist('Simulation_Ergebnisse');
    if ordner_existiert ~= 7
        mkdir('Simulation_Ergebnisse');
    end
    filename = strcat('sim_not_finished_',num2str(yyyy),'_',num2str(mm),'_',num2str(dd),'_',num2str(hh),'_',num2str(min),'_',num2str(sec),'_I_',num2str(strategie_parameter.I_max),'__i_getr_',num2str(strategie_parameter.i_getriebe_vec),'__U_low_',num2str(fahrzeug_parameter.U_SC_min),'__U_up_',num2str(fahrzeug_parameter.U_SC_initial),'__dv_min_',num2str(average_dv_min),'__dv_max_',num2str(average_dv_max));
    filename = strrep(filename,'.','k');                         % "k" steht für Komma
    save(strcat('Simulation_Ergebnisse\',filename,'.mat'),'ablage_table');
    disp('Andere Konfiguration (Strom und Übersetzung) wählen!')
elseif ablage_table.Zeit(end) > (strecke.max_Dauer * 60)
    ordner_existiert = exist('Simulation_Ergebnisse');
    if ordner_existiert ~= 7
        mkdir('Simulation_Ergebnisse');
    end
    filename = strcat('sim_delay_',num2str(yyyy),'_',num2str(mm),'_',num2str(dd),'_',num2str(hh),'_',num2str(min),'_',num2str(sec),'_I_',num2str(strategie_parameter.I_max),'__i_getr_',num2str(strategie_parameter.i_getriebe_vec),'__U_low_',num2str(fahrzeug_parameter.U_SC_min),'__U_up_',num2str(fahrzeug_parameter.U_SC_initial),'__dv_min_',num2str(average_dv_min),'__dv_max_',num2str(average_dv_max));
    filename = strrep(filename,'.','k');                         % "k" steht für Komma
    filename = strrep(filename,'-','n');                         % "n" steht für negativ
    save(strcat('Simulation_Ergebnisse\',filename,'.mat'),'ablage_table');
    disp('Gesamtzeit überschritten!')
    
end

clear bnj clock1 colNames colNames_DR Driving_Resistances dd hh min mm ordner_existiert sec simout_col_num simout_col_num_DR DR  yyyy tout ablage energie_1_L_benzin;
%clear cmdstr filename;