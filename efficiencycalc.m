%Efficiency function based on the Automatisierung_Model_2 script
function eff = efficiencycalc(speeds)
    %Loading of track data and race parameters
    %This is the data from running the Initialisierung_Model_2,
    %Fahrzeug_Parameter_Model_2,Umwelt_Parameter_Model_2 and
    %Strategie_Parameter_Model_2 files
    parameters = load("parameters_initials.mat");

    %Checks before simulation
    strecke = parameters.strecke;
    assignin('base','strecke',strecke);

    cuts = [28; 34; 56; 58; 118; 162; 208];
    %Check for right order of cuts
    badcuts = 0;
    for k = 1:(length(cuts)-1)
        if cuts(k+1) - cuts(k) < 0
            badcuts = 1;
            break
        end
    end
	
    %dv_max must be positive and the segment cuts must be between 0 and
    %the track length for valid simulation
    if any(speeds(:,2) <= 0) || any(cuts <= 0) || badcuts || any(cuts > length(strecke.distanz_3d))
        eff = 0;
    else
        %Assign loaded parameters to base enviroment
        ausrollen_a_v = parameters.ausrollen_a_v;
        assignin('base','ausrollen_a_v',ausrollen_a_v);
        bremspunkte = parameters.bremspunkte;
        assignin('base','bremspunkte',bremspunkte);
        brennstoffzellen_eta_kennfeld = parameters.brennstoffzellen_eta_kennfeld;
        assignin('base','brennstoffzellen_eta_kennfeld',brennstoffzellen_eta_kennfeld);
        brennstoffzellen_ui_kennfeld = parameters.brennstoffzellen_ui_kennfeld;
        assignin('base','brennstoffzellen_ui_kennfeld',brennstoffzellen_ui_kennfeld);
        coeffs_motor = parameters.coeffs_motor;
        assignin('base','coeffs_motor',coeffs_motor);
        coeffs_motor_moment = parameters.coeffs_motor_moment;
        assignin('base','coeffs_motor_moment',coeffs_motor_moment);
        coeffs_motor_wirkungsgrad = parameters.coeffs_motor_wirkungsgrad;
        assignin('base','coeffs_motor_wirkungsgrad',coeffs_motor_wirkungsgrad);
        fahrzeug_parameter = parameters.fahrzeug_parameter;
        strategie_parameter = parameters.strategie_parameter;
        ts = parameters.ts;
        assignin('base','ts',ts);
        U_moment = parameters.U_moment;
        assignin('base','U_moment',U_moment);
        U_wirkungsgrad = parameters.U_wirkungsgrad;
        assignin('base','U_wirkungsgrad',U_wirkungsgrad);
        umwelt_parameter = parameters.umwelt_parameter;
        assignin('base','umwelt_parameter',umwelt_parameter);
        zwangsgas = parameters.zwangsgas;

        Model_Name = 'Model2_V032_R_T4';
    
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
        
        % "Pendeln" um Durchschnittsgeschwindigkeit
            % [m/s] Abstand untere Grenze der Bandbreite zur Durchschnittsgeschwindigkeit (v_min = v_durch + dv_min)
        %dv_min as vector with different speeds per segment of the track
        strategie_parameter.dv_min = speeds(:,1);
            % [m/s] Abstand obere Grenze der Bandbreite zur Durchschnittsgeschwindigkeit (v_max = v_durch + dv_max)
        %dv_max as vector with different speeds per segment of the track
        strategie_parameter.dv_max = speeds(:,2);
        %parameter for cuts of segments in the track
        strategie_parameter.cuts = cuts;
        
        % Untere Geschwindigkeitsgrenze
            % [m/s] untere Geschwindigkeitsgrenze, bei der trotz Kurve/... Gas gegeben wird
        strategie_parameter.v_low = 10 / 3.6;
            % [m/s] Abstand untere Grenze der Bandbreite zur minimalen Geschwindigkeit
        strategie_parameter.dv_low_down = 0;
            % [m/s] Abstand obere Grenze der Bandbreite zur minimalen Geschwindigkeit
        strategie_parameter.dv_low_up = 5 / 3.6;

        zwangsgas = zeros(length(strecke.x),strecke.Rundenzahl);
        clear ablage_table simout;
        tic;
        assignin('base','fahrzeug_parameter',fahrzeug_parameter);
        assignin('base','strategie_parameter',strategie_parameter);
        assignin('base','zwangsgas',zwangsgas);
        sim(Model_Name);
        akt_konfig_ungeeignet = 0;
        Stop_Function_Model_2;
        % erneut rechnen wenn Stillstand während Rennen
        while ablage_table.Geschwindigkeit(end) < 0
            % suche Punkt, an dem zuletzt Gas gegeben wurde
            ende_zuletzt_Gas = length(ablage_table.Geschwindigkeit);
            while ablage_table.fps(ende_zuletzt_Gas) < 1
                % solange keine 1 gefunden wird, geht er weiter zurück in der Strecke
                ende_zuletzt_Gas = ende_zuletzt_Gas - 1;                  % Spalte, in welcher letztes mal Gas gegeben wurde
            end
            % wenn ein 1er gefunden wurde, wird wieder zurückgegangen, bis wieder
            % ein 0er gefunden wird
            start_zuletzt_Gas = ende_zuletzt_Gas;
            while ablage_table.fps(start_zuletzt_Gas) > 0
                % suche Punkt, wo das Gasgeben begonnen hat
                if start_zuletzt_Gas ~= 0                           % verhindert, dass Zähler über den Start (negativ) am Beginn der Simulation hinausgeht
                    start_zuletzt_Gas = start_zuletzt_Gas - 1;
                    if start_zuletzt_Gas == 0                       % Abbruch, da while-Schleife sonst Error
                        akt_konfig_ungeeignet = 1;
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
                zwangsgas(Zeilennr_strecke_start_zuletzt_gas:Zeilennr_strecke_ende_zuletzt_gas , ablage_table.fertige_Runden(ende_zuletzt_Gas)+1) = 1;
            else    % dann aufteilen auf 2 Runden && Füllen mit 1ern (Zwangsgas)
                zwangsgas(1:Zeilennr_strecke_ende_zuletzt_gas , ablage_table.fertige_Runden( ende_zuletzt_Gas ) + 1) = 1;
                zwangsgas(Zeilennr_strecke_start_zuletzt_gas:end , num2str(ablage_table.fertige_Runden( ende_zuletzt_Gas ) ) ) = 1;
            end
            % verlängert aktiv das Intervall des Gas gebens --> Zwangsgas in struct
            % gespeichert
            % Rückwärts testen, wie viel Verlängerung der FPS=1-Zeit zur nächsten Kurve möglich ist
    
            % laenger_gas_meter = 1;                     % um ... Meter länger Gas geben
            ascp = Zeilennr_strecke_start_zuletzt_gas;   % Zähler initialisieren mit letztem Start des Gasgeben
            if ascp == 1 &&  ablage_table.fertige_Runden(start_zuletzt_Gas) ~= 0              % Vorheriger Punkt liegt in vorheriger Runde, aber nicht ganz am Start des Rennens
                zwangsgas( length(strecke.x) , ablage_table.fertige_Runden(start_zuletzt_Gas) ) = 1;
            else
                % Zwangsgas für die aktuelle Runde befüllen, einen Wegpunkt früher mit Zwangsgas starten
                zwangsgas(ascp - 1 , ablage_table.fertige_Runden( start_zuletzt_Gas ) + 1 ) = 1;
            end
            % erneute Simulation unter Berücksichtigung von Zwangsgas
            clear simout;
            assignin('base','zwangsgas',zwangsgas);
            sim(Model_Name); 
            Stop_Function_Model_2;
        end
        toc
        % prüfe ob Gesamtzeit überschritten
        while ablage_table.Zeit(end) > (strecke.max_Dauer * 60)
            strategie_parameter.dv_min = strategie_parameter.dv_min + 0.01;
            disp('Neue Berechnung erfolgt wegen Gesamtzeitueberschreitung...');
            tic
            % Index des Punktes in der Streckenmatrix, an dem das letzte Gasgeben
            % begonnen hat
            clear simout ablage_table;
            assignin('base','strategie_parameter',strategie_parameter);
            sim(Model_Name); 
            toc
            disp('Neue Berechnung wegen Gesamtzeitueberschreitung fertig...');
    
            Stop_Function_Model_2;
        end
    
        %name_ablage = strcat('I_',num2str(strom),'__i_getr_',num2str(uebersetzung),'__U_low_',num2str(SC_U_low),'__U_up_',num2str(SC_U_up),'__dv_min_',num2str(speed_min),'__dv_max_',num2str(speed_max));
        %name_ablage = strrep(name_ablage,'.','k');
        % Speichern der Reichweite in Struct
        if akt_konfig_ungeeignet == 0 && ablage_table.Zeit(end) <= (strecke.max_Dauer * 60)       % dann bleibt Fahrzeug nicht stehen
            eff = -reichweite_BZ_10_kWh;
        else                     % dann bleibt das Fahrzeug mit der aktuellen Konfiguration stehen 
            eff = 0;
        end
    end
end