%% Normale Berechnung des Simulink Modells
% Hydro2Motion
% Prototyp: Homer
% Stand: 23.01.2020
% edited: Robin Nedella, Timo Freilinger

clear all;
clf;

%% Vorbereitung

% Füge Pfade hinzu, wo Unterprogramme hinterlegt
addpath('Kennfelder');          % Ordner mit Kennfelddaten
addpath('Parameter');           % Ordner mit Parametern und Initialisierungsskript
addpath('Streckendaten');       % Ordner mit Streckendaten
addpath('Zwangsgas');           % Ordner mit Zwangsgas-Informationen

% Ausführen der Skripte zur Initialisierung
Initialisierung_Model_2;        % rufe Funktion auf, in welcher die Initialisierung durchgeführt wird
Fahrzeug_Parameter_Model_2;     % rufe Funktion auf, in welcher Fahrzeugparameter geladen werden
Umwelt_Parameter_Model_2;       % rufe Funktion auf, in welcher Umweltparameter geladen werden
Strategie_Parameter_Model_2;    % rufe Funktion auf, in welcher Strategieparameter geladen werden

%% Strategie: veränderliche Strategieparameter setzen

% Antriebsstrangparameter
    % [A] gefahrener Strom
strategie_parameter.I_max = 7.5;
    % [-] mögliche Übersetzungen
strategie_parameter.i_getriebe_vec = [18.1];

% Super Caps
    % [V] Anfangsspannung der Kondensatoren
fahrzeug_parameter.U_SC_initial = 32;
    % [V] minimale Spannung der SC (unterschreiten --> Aufladen)
fahrzeug_parameter.U_SC_min = 28;
speeds = [-0.042	0.0012;
        -0.042	0.0012;
        -0.042	0.0012;
        -0.042	0.0012;
        -0.0418	0.0012;
        -0.0437	0.0012;
        -0.0419	0.0012;
        -0.0421	0.0012];
% "Pendeln" um Durchschnittsgeschwindigkeit
    % [m/s] Abstand untere Grenze der Bandbreite zur Durchschnittsgeschwindigkeit (v_min = v_durch + dv_min)
strategie_parameter.dv_min = speeds(:,1);
    % [m/s] Abstand obere Grenze der Bandbreite zur Durchschnittsgeschwindigkeit (v_max = v_durch + dv_max)
strategie_parameter.dv_max = speeds(:,2);
cuts = [28; 34; 56; 58; 118; 162; 208];
strategie_parameter.cuts = cuts;
% Untere Geschwindigkeitsgrenze
    % [m/s] untere Geschwindigkeitsgrenze, bei der trotz Kurve/... Gas gegeben wird
strategie_parameter.v_low = 10 / 3.6;
    % [m/s] Abstand untere Grenze der Bandbreite zur minimalen Geschwindigkeit
strategie_parameter.dv_low_down = 0;
    % [m/s] Abstand obere Grenze der Bandbreite zur minimalen Geschwindigkeit
strategie_parameter.dv_low_up = 5 / 3.6;


%% Simulation durchführen
% Erste Simulation
akt_konfig_ungeeignet = 0;          % Initialisierung

tic;                                % Simulationszeit messen (Anfang)
clear simout;                       % Vorherige Lösung aus Workspace löschen

Model_Name = 'Model2_V032_R_T4';    % Name Simulink-Modell
sim(Model_Name);                    % Simulation durchführen

Stop_Function_Model_2;              % Stop Function nach Simulation ausführen
%% Ergebnis prüfen


    %% Prüfung, ob das Auto stehen geblieben ist
% dann: mehr Gas geben nach abnehmender Zeit
while ablage_table.Geschwindigkeit(end) < 0
    % suche Punkt, an dem zuletzt Gas gegeben wurde
    ende_zuletzt_Gas = length(ablage_table.Geschwindigkeit);
    while ablage_table.fps(ende_zuletzt_Gas) < 1
        % solange keine 1 gefunden wird, geht er weiter zurück in der Strecke
        ende_zuletzt_Gas = ende_zuletzt_Gas - 1;                  % Spalte, in welcher letztes mal Gas gegeben wurde
    end
    % wenn ein 1er gefunden wurde, wird wieder zurückgegangen, bis wieder ein 0er gefunden wird
    start_zuletzt_Gas = ende_zuletzt_Gas;
    while ablage_table.fps(start_zuletzt_Gas) > 0
        % suche Punkt, wo das Gasgeben begonnen hat
        if start_zuletzt_Gas ~= 0                           % verhindert, dass Zähler über den Start (negativ) am Beginn der Simulation hinausgeht
            start_zuletzt_Gas = start_zuletzt_Gas - 1;
            if start_zuletzt_Gas == 0                       % Abbruch, da while-Schleife sonst Error
                akt_konfig_ungeeignet = 1;
                disp('geht nicht');
                break
            end
        else
            % Begin des Gasgeben wurde gefunden
            break
        end
    end
    % Abbruch, falls nicht funktioniert
    if akt_konfig_ungeeignet == 1
        Stop_Function_Model_2;
        break
    end
    
    % Position zu den gefundenen Indizes in der ablage_table für Beginn und Ende vom letzten Gasgeben
    position_ende_zuletzt_Gas = ablage_table.Position_in_Runde (ende_zuletzt_Gas);    % Position Runde, an der letztes Gasintervall endet
    position_start_zuletzt_Gas = ablage_table.Position_in_Runde (start_zuletzt_Gas);  % Position Runde, an der letztes Gasintervall startet
    % zugehörige Zeilennummern in Streckenmatrix
    Zeilennr_strecke_ende_zuletzt_gas = ablage_table.Zeilennr_in_strecke(ende_zuletzt_Gas);
    Zeilennr_strecke_start_zuletzt_gas = ablage_table.Zeilennr_in_strecke(start_zuletzt_Gas);

    % Abfrage, ob Intervall über Startlinie geht
    if position_ende_zuletzt_Gas > position_start_zuletzt_Gas
        % Füllen der Zwangsgase mit fps der vergangenen Simulation
        % Matrix in "Initialisierung" automatisch erstellt!
        zwangsgas(Zeilennr_strecke_start_zuletzt_gas:Zeilennr_strecke_ende_zuletzt_gas , ablage_table.fertige_Runden(ende_zuletzt_Gas)+1) = 1;
    else    % dann aufteilen auf 2 Runden && Füllen mit 1ern (Zwangsgas)
        zwangsgas(1:Zeilennr_strecke_ende_zuletzt_gas , ablage_table.fertige_Runden( ende_zuletzt_Gas ) + 1) = 1;
        zwangsgas(Zeilennr_strecke_start_zuletzt_gas:end , num2str(ablage_table.fertige_Runden( ende_zuletzt_Gas ) ) ) = 1;
    end
    % verlängert aktiv das Intervall des Gas gebens --> Zwangsgas in struct gespeichert
    % Rückwärts testen, wie viel Verlängerung der FPS=1-Zeit zur nächsten Kurve möglich ist
    
    % laenger_gas_meter = 1;                     % um ... Meter länger Gas geben
    ascp = Zeilennr_strecke_start_zuletzt_gas;   % Zähler initialisieren mit letztem Start des Gasgeben
    if ascp == 1 && ablage_table.fertige_Runden(start_zuletzt_Gas) ~= 0              % Vorheriger Punkt liegt in vorheriger Runde, aber nicht ganz am Start des Rennens
        zwangsgas( length(strecke.x) , ablage_table.fertige_Runden(start_zuletzt_Gas) ) = 1;
    else
        % Zwangsgas für die aktuelle Runde befüllen, einen Wegpunkt früher mit Zwangsgas starten
        zwangsgas(ascp - 1 , ablage_table.fertige_Runden( start_zuletzt_Gas ) + 1 ) = 1;
    end
    disp('Neue Berechnung erfolgt wegen Stillstand...');
    tic
    % Index des Punktes in der Streckenmatrix, an dem das letzte Gasgeben begonnen hat
    ascp
    clear simout ablage_table;
    sim(Model_Name); 
    toc
    disp('Neue Berechnung wegen Stillstand fertig...');

    Stop_Function_Model_2;
end

    %% Prüfung, ob die Gesamtzeit überschritten wurde
% falls ja: setzte unteres Geschwindigkeitslimit nach oben
% dass er stehenbleibt ist abgefangen, da er hier weiter mit der Zwangsgas-Matrix rechnet!
while ablage_table.Zeit(end) > (strecke.max_Dauer * 60)
    strategie_parameter.dv_min = strategie_parameter.dv_min + 0.2;
    strategie_parameter.dv_max = strategie_parameter.dv_max + 0.2;
    disp('Gesamtzeit ueberschritten um [sec]:');
    betrag = ablage_table.Zeit(end) - (strecke.max_Dauer * 60)
    disp('Neue Berechnung erfolgt wegen Gesamtzeitueberschreitung...');
    tic
    % Index des Punktes in der Streckenmatrix, an dem das letzte Gas geben begonnen hat
    clear simout ablage_table;
    sim(Model_Name);
    Stop_Function_Model_2;
    toc
    disp('Neue Berechnung wegen Gesamtzeitueberschreitung fertig...');
    if ablage_table.Zeit(end) <= (strecke.max_Dauer * 60)
        disp('Erfolgreich!');
        puffer = ablage_table.Zeit(end) - (strecke.max_Dauer * 60)
    end
end

    %% Prüfung, ob zum Ende des Rennens mehr Rollen gelassen werden kann
% "Ausrollen" lassen bzw. an letzter Stelle weniger Gas
ausrollen_ende = 10;    % wieviel vor Ende ausrollen (10 Punkte entsprechen ca. 5 Meter)
% for ias = 1:1:3
while ablage_table.Zeit(end) < (strecke.max_Dauer * 60) - 70    % mehr als 1 Minute Puffer am Ende...
    % suche Stelle, wo zuletzt Gas gegeben wurde
    ende_zuletzt_Gas = length(ablage_table.Geschwindigkeit);
    while ablage_table.fps(ende_zuletzt_Gas) ~= 1
        % solange keine 1 gefunden wird, geht er weiter zurück in der Strecke
        ende_zuletzt_Gas = ende_zuletzt_Gas - 1;                  % Spalte, in welcher letztes mal Gas gegeben wurde
    end % Ende zuletzt Gas geben wurde gefunden!
    % nun: "Zwangsgas"-Matrix an dieser Stelle mit "2" füllen (ausrollen)
    
    % Zwangsgasmatrix genau an dieser Stelle und die letzten [...] Sekunden mit einer "2" füllen
    % letzte Sekunden entsprechen genau dem Puffer, den er noch hat!
    
    % Position zu den gefundenen Indizes in der ablage_table für Beginn und Ende vom letzten Gasgeben
    position_ende_zuletzt_Gas_ausrollen = ablage_table.Position_in_Runde (ende_zuletzt_Gas);    % Position Runde, an der letztes Gasintervall endet
    % zugehörige Zeilennummern in Streckenmatrix
    Zeilennr_strecke_ende_zuletzt_gas_ausrollen = ablage_table.Zeilennr_in_strecke(ende_zuletzt_Gas);
    Zeilennr_strecke_start_zuletzt_gas_ausrollen = Zeilennr_strecke_ende_zuletzt_gas_ausrollen - ausrollen_ende;

    % Abfrage, ob Intervall über Startlinie geht
    if position_ende_zuletzt_Gas_ausrollen - ausrollen_ende > 1
        % Füllen der Zwangsgase mit fps der vergangenen Simulation
        % Matrix in "Initialisierung" automatisch erstellt!
        zwangsgas(Zeilennr_strecke_start_zuletzt_gas_ausrollen:Zeilennr_strecke_ende_zuletzt_gas_ausrollen , ablage_table.fertige_Runden(ende_zuletzt_Gas)+1) = 2;
    else    % dann aufteilen auf 2 Runden && Füllen mit 2ern (Zwangsausrollen)
        zwangsgas(1:Zeilennr_strecke_ende_zuletzt_gas_ausrollen , ablage_table.fertige_Runden( ende_zuletzt_Gas ) + 1) = 2;
        zwangsgas(Zeilennr_strecke_start_zuletzt_gas_ausrollen:end , num2str(ablage_table.fertige_Runden( ende_zuletzt_Gas ) ) ) = 2;
    end
    
    disp('Neue Berechnung erfolgt wegen Puffer am Ende...');
    puffer = abs(ablage_table.Zeit(end) - strecke.max_Dauer * 60)

    tic
    clear simout ablage_table;
    sim(Model_Name); 
    toc
    disp('Neue Berechnung wegen Puffer am Ende fertig...');

    Stop_Function_Model_2;
  
end
aktueller_puffer = abs(ablage_table.Zeit(end) - strecke.max_Dauer * 60)

%%
% Ablage Table löschen
eval(cell2mat(strcat('clear',{' '}, ablage_table_name)));
clear ablage_table_name Energiebedarf_BZ Energiebedarf_Motor;

%% Auswertung: Reichweiten ausgeben
if akt_konfig_ungeeignet == 1 || ablage_table.Zeit(end) > (strecke.max_Dauer * 60)
    reichweite_Motor_10_kWh = 0
    reichweite_BZ_10_kWh = 0
elseif ablage_table.Zeit(end) > (strecke.max_Dauer * 60)
    reichweite_Motor_10_kWh = 0
    reichweite_BZ_10_kWh = 0
else
    fprintf('Reichweite pro Liter Benzin (10kWh): %5.2f km\n',reichweite_BZ_10_kWh);
    reichweite_BZ_m3 = max(strecke.distanz_3d) * strategie_parameter.runde_sim / 1000 / (ablage_table.Energiebedarf_BZ_gesamt(1) / fahrzeug_parameter.hiv_h2);
    fprintf('Reichweite pro m^3 Wasserstoff: %5.2f km\n',reichweite_BZ_m3);
end

toc         % beendet Timer zur Simulationszeitberechnung

clear akt_konfig_ungeeignet ausrollen_a_v I_moment I_wirkungsgrad kennfeld_motor simout vorgabe_switch;
