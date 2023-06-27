%% Darstellung Auswertung
% Hydro2Motion
% Prototyp: Homer
% Stand: 23.01.2020
% edited: Robin Nedella

%% ________________
% Dieses Skript dient zur Auswertung der Simulationsergebnisse zur Schulung
% der Fahrer
%  ________________
clear all
close all
tic
%% Laden der Streckendaten
addpath('../4 Simulationsmodell/Streckendaten');       % Ordner mit Streckendaten
load('strecke_sem19_steigung.mat');
% strecke = sem_18_hungary;

%% Laden der Ergebnisse
%load('Simulation_Ergebnisse/sim_delay_2018_7_8_13_43_3_I_5k5__i_getr_15k6__U_low_27__U_up_32__dv_min_2k5__dv_max_4k5.mat');
load('../4 Simulationsmodell/Simulation_Ergebnisse/sim_2020_1_23_11_49_32_I_7k5__i_getr_18k1__U_low_28__U_up_32__dv_min_0k061111__dv_max_0k53333.mat');
daten_simulation = ablage_table;
% Anzahl der Runden
runden_gesamt = daten_simulation.fertige_Runden(end);
% Löschen der gesamten Energimenge etc (da lediglich in 1. Zeile, sonst Null)
daten_simulation(:,27:end) = [];

%% Initialisierung
zeilen_Runde = zeros(runden_gesamt,2);
zeilen_Runde(1,1) = 1;  % erste Runde beginnt in erster Zeile
aktuelle_Runde = 2;     % Initialisierung

%% Zeilen finden, in denen einzelne Runden stehen
for oiev = 1:1:height(daten_simulation)
    if daten_simulation.fertige_Runden(oiev + 1) > daten_simulation.fertige_Runden(oiev)
        zeilen_Runde(aktuelle_Runde , 1) = oiev + 1;
        zeilen_Runde(aktuelle_Runde - 1 , 2) = oiev;
        aktuelle_Runde = aktuelle_Runde + 1;
    end
    if aktuelle_Runde > runden_gesamt + 1
        zeilen_Runde(end,:) = [];
        break
    end
end

%% Daten auf Runden aufteilen
for cqj = 1:1:runden_gesamt
    einzelne_runden.(strcat('Runde_',num2str(cqj))) = daten_simulation(zeilen_Runde(cqj,1):zeilen_Runde(cqj,2),:);
end
toc

clear cqj oiev ablage_table aktuelle_Runde runden_gesamt sem_18_hungary

%% Plot der Runden
clear daten_runde_plot
runde_plot =  4;  % welche Runde soll geplottet werden
% Matrix erstellen, für jede Zeilenr erster Wert
% erste Zeile anders
daten_runde_plot(1,:) = einzelne_runden.(strcat('Runde_',num2str(runde_plot)))(1,:);
daten_runde_plot.Position_in_Runde(1) = 0;
daten_runde_plot.Zeilennr_in_strecke(1) = 1;
daten_runde_plot(2,:) = einzelne_runden.(strcat('Runde_',num2str(runde_plot)))(1,:);

% gewollte Runde raussuchen
for ossq = 4:1: height(einzelne_runden . (strcat('Runde_',num2str(runde_plot))))    % alle Zeilen durchgehen
    zeilennr = einzelne_runden.(strcat('Runde_',num2str(runde_plot))).Zeilennr_in_strecke(ossq);
    zeilennr_m_1 = einzelne_runden.(strcat('Runde_',num2str(runde_plot))).Zeilennr_in_strecke(ossq - 1);
    if zeilennr > zeilennr_m_1
        zeile = einzelne_runden.(strcat('Runde_',num2str(runde_plot))).Zeilennr_in_strecke(ossq);
        daten_runde_plot(zeile,:) = einzelne_runden.(strcat('Runde_',num2str(runde_plot)))(ossq,:);
    end
end

tic
stem3(strecke.x(1:1:end) , strecke.y(1:1:end) , daten_runde_plot.Geschwindigkeit(1:1:end).*3.6 );
zlim([min(daten_runde_plot.Geschwindigkeit * 3.6) max(daten_runde_plot.Geschwindigkeit * 3.6)]);
zlabel('Geschwindigkeit km/h');
view(10,55);
title(strcat('Runde',num2str(runde_plot),' | Geschwindigkeitsverlauf'));
hold on

%% Min und Max v Markieren
indexmin = find(min(daten_runde_plot.Geschwindigkeit(1:end).*3.6) == daten_runde_plot.Geschwindigkeit(1:end).*3.6); 
xmin = strecke.x(indexmin); 
ymin = strecke.y(indexmin);
vmin = daten_runde_plot.Geschwindigkeit(indexmin).*3.6;

indexmax = find(max(daten_runde_plot.Geschwindigkeit(1:end).*3.6) == daten_runde_plot.Geschwindigkeit(1:end).*3.6); 
xmax = strecke.x(indexmax);
ymax = strecke.y(indexmax);
vmax = daten_runde_plot.Geschwindigkeit(indexmax).*3.6;

% Find Radius for max. Speed point:
offset_v = 10; % vorwärts Punkte suchen
offset_b = 10; % rückwärts Punkte suchen
rmin = min(strecke.radius((indexmax - offset_b):(indexmax + offset_v)));
stem3(strecke.x((indexmax - offset_b):(indexmax + offset_v)) , strecke.y((indexmax - offset_b):(indexmax + offset_v)) , daten_runde_plot.Geschwindigkeit((indexmax - offset_b):(indexmax + offset_v)).*3.6, 'r+' );


strvmin = ['v min = ',num2str(vmin)];
text(xmax,ymax,vmin,strvmin,'HorizontalAlignment','right','Color','r')

strvmax = ['v max = ', num2str(vmax), ' km/h; min R = ', num2str(rmin), ' m'];
text(xmax,ymax,vmax,strvmax,'HorizontalAlignment','right','Color','r')


%% Ende Min Max



toc

tic
figure
hold on
for ois = 1:1:height(daten_runde_plot)
    if daten_runde_plot.fps(ois) == 0
        scatter(strecke.x(ois) , strecke.y(ois) , 'MarkerEdgeColor' , [0 0 1])
    else
        scatter(strecke.x(ois) , strecke.y(ois) , 'MarkerEdgeColor' , [1 0 0])
    end
end
plot(strecke.x(1),strecke.y(1), 'X', 'Color', 'g' , 'MarkerSize', 20);
title(strcat('Runde',num2str(runde_plot),' | Rot: Gas | Blau: kein Gas'));


hold off

% zlim([min(daten_runde_plot.Geschwindigkeit) max(daten_runde_plot.Geschwindigkeit)]);
toc
