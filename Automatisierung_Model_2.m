%% Automatisierung der Berechnung zur Optimierung
% Hydro2Motion
% Prototyp: Homer
% Stand: 23.01.2020
% edited: Robin Nedella

clear all;

%% zu berechnendes Modell:
Model_Name = 'Model2_V032_R_T4';
%Model_Name = 'Model2_V032_R_T2';

%% Search Pathes for Subdirectories
addpath('Kennfelder');
addpath('Parameter');
addpath('Streckendaten');
addpath('Zwangsgas');

%% InitFcn
Initialisierung_Model_2;
Fahrzeug_Parameter_Model_2;
Umwelt_Parameter_Model_2;
Strategie_Parameter_Model_2;

%% Eingabe Bereich Strom
I_mini = 7.5;
I_maxi = 7.5;
delta_I = 1;

%% Eingabe Bereich Übersetzung
i_get_min = 18.1;
i_get_max = 18.1;
delta_i_get = 1;

%% Eingabe Bereich untere SC-Spannung
% ab dieser Spannung wird in der Simulation geladen
U_low_low = 28;
U_low_up  = 28;
delta_U_low = 1;

%% Eingabe Bereich obere SC-Spannung
% bis zu dieser Spannung wird in der Simulation geladen
% dies entspricht auch der initialen Ladung bei Start der Simulation
U_up_low  = 32;
U_up_up   = 32;
delta_U_up = 1;

%% Eingabe Bereich untere Geschwindigkeit
% ab dieser Geschwindigkeitsdifferenz von der Durchschnittsgeschwindigkeit wird Gas gegeben
dv_min_low = 0;
dv_min_up  = 0.5;
delta_dv_min = 0.02;
dv_min_values = dv_min_low:delta_dv_min:dv_min_up;

%% Eingabe Bereich obere Geschwindigkeit
% ab dieser Geschwindigkeitsdifferenz von der Durchschnittsgeschwindigkeit wird kein Gas mehr gegeben
dv_max_low   = 0.5;
dv_max_up    = 1;
delta_dv_max = 0.02;
dv_max_values = dv_max_low:delta_dv_max:dv_max_up;

%% Eingabe minimale Geschwindigkeit
% Abfangen, dass Fahrzeug zu langsam wird, da an manchen Stellen seitens der Strategie kein Gas gegeben werden darf
v_low_low   = 10 / 3.6;
v_low_up    = 10 / 3.6;
delta_v_low = 1 / 3.6;

%% Eingabe Bereich untere Abweichung von minimaler Geschwindigkeit
dv_low_down_down  = 0;
dv_low_down_up    = 0;
delta_dv_low_down = 1;

%% Eingabe Bereich obere Abweichung von minimaler Geschwindigkeit
dv_low_up_down    = 5 / 3.6;
dv_low_up_up      = 5 / 3.6;
delta_dv_low_up   = 1;

%% New code
data = zeros(1,3);
%%
v_average = 6.58;

%% Automatische Berechnung:
% alle oben genannten Fälle werden kombiniert

for strom = I_mini : delta_I : I_maxi
    
    strategie_parameter.I_max = strom;
    
    for uebersetzung = i_get_min : delta_i_get : i_get_max
        
        strategie_parameter.i_getriebe_vec = [uebersetzung];
        
        for SC_U_low = U_low_low : delta_U_low : U_low_up
            
            fahrzeug_parameter.U_SC_min = SC_U_low;
            
            for SC_U_up = U_up_low : delta_U_up : U_up_up
                
                fahrzeug_parameter.U_SC_initial = SC_U_up;
                
                for speed_min = dv_min_low : delta_dv_min : dv_min_up
                    
                    strategie_parameter.dv_min = speed_min;
                    
                    for speed_max = dv_max_low : delta_dv_max : dv_max_up
                        
                        strategie_parameter.dv_max = speed_max;
                   
                        strategie_parameter.v_low = v_low_low;
                        strategie_parameter.dv_low_down = dv_low_down_down;
                        strategie_parameter.dv_low_up = dv_low_up_down;
                        
                        
                        %% Zwangsgas-Matrix erstellen (Spaltennummer steht für jeweilige Runde)
                        % zwar in Initialisierung erstellt, jedoch soll diese bei anderen Kombinationen wieder initialisiert werden
                        zwangsgas = zeros(length(strecke.x),strecke.Rundenzahl);
                        clear ablage_table simout;
                        tic;
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
                            sim(Model_Name); 
                            toc
                            disp('Neue Berechnung wegen Gesamtzeitueberschreitung fertig...');

                            Stop_Function_Model_2;
                        end

                        name_ablage = strcat('I_',num2str(strom),'__i_getr_',num2str(uebersetzung),'__U_low_',num2str(SC_U_low),'__U_up_',num2str(SC_U_up),'__dv_min_',num2str(speed_min),'__dv_max_',num2str(speed_max));
                        name_ablage = strrep(name_ablage,'.','k');
                        % Speichern der Reichweite in Struct
                        if akt_konfig_ungeeignet == 0 && ablage_table.Zeit(end) <= (strecke.max_Dauer * 60)       % dann bleibt Fahrzeug nicht stehen
                            Reichweite.(name_ablage) = reichweite_BZ_10_kWh;
                            data = cat(1, data, [speed_min speed_max reichweite_BZ_10_kWh]);
                        else                                % dann bleibt das Fahrzeug mit der aktuellen Konfiguration stehen 
                            Reichweite.(name_ablage) = 0;
                            data = cat(1, data, [speed_min speed_max reichweite_BZ_10_kWh]);
                        end
                        clear reichweite_BZ_10_kWh
                        eval(cell2mat(strcat('clear',{' '}, ablage_table_name)));
                        eval(cell2mat(strcat('clear',{' '}, name_ablage)));

                    end
                end
            end
        end
    end
end

clear Energiebedarf_BZ Energiebedarf_Motor ablage_table_name name_ablage ausrollen_a_v delta_dv_max delta_dv_min delta_I delta_i_get delta_U_low delta_U_up dv_max_low dv_max_up dv_min_low dv_min_up i_get_max i_get_min I_maxi I_mini SC_U_low SC_U_up speed_max speed_min strom U_low_low U_low_up U_up_low U_up_up uebersetzung;
data(1,:) = [];
%% Correction
% data(:,1) = -data(:,1) + v_average;
% data(:,2) = data(:,2) - v_average;
%%
%Simple data point graph for scattered data
figure(1)
scatter3(data(:,1),data(:,2),data(:,3),'o')
title('Efficiency vs speed')
xlabel('dv min m/s') 
ylabel('dv max Speed m/s')
zlabel('km/10kWh')
%%
%Mesh graph for data without standstills or errors
tdata = array2table(data,"VariableNames",{'dv_min','dv_max','Efficiency'});
tmat = array2table(reshape(tdata.Efficiency,length(unique(tdata.dv_min)),length(unique(tdata.dv_max))),...
    'RowNames',string(unique(tdata.dv_max)),'VariableNames',string(unique(tdata.dv_min)));
%%
rangeX = dv_min_values;
rangeY = dv_max_values;

%%
[X,Y] = meshgrid(0:0.02:0.5,0.5:0.02:1);
figure(2)
s = mesh(X,Y,table2array(tmat),'FaceAlpha','0.5');
s.FaceColor = 'flat';
title('Efficiency vs speed','FontSize',15)
xlabel('dv min (m/s)','FontSize',13) 
ylabel('dv max (m/s)','FontSize',13)
zlabel('Efficiency (km/10kWh)','FontSize',13)
%%
%Gradient
%Only works if mesh is successful
rangeYalter = rangeY';
[px,py] = gradient(table2array(tmat));
figure(3)
contour(rangeX,rangeYalter,table2array(tmat))
hold on
quiver(rangeX,rangeYalter,px,py)
hold off
title("Gradient graph")
xlabel('Minimum Speed m/s') 
ylabel('Maximum Speed m/s')