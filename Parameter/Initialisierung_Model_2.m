%% Initialisierung
% Hydro2Motion
% Prototyp: Homer
% Stand: 23.01.2020
% edited: Robin Nedella, Timo Freilinger

%% Löschen Workspace
% clc;
tic
%% Laden der nötigen Kennfelder und Streckendaten

% Motorkennfeld
load('coeffs_motor');               % Struct wo Koeffizienten der Polynome des Drehmoments und des Wirkungsgrades hinterlegt sind

% Strecke
%load('educeco_2019');  % Nr. 1: drivee Strecke
load('strecke_sem19_steigung');
load('bremspunkte');           % Bremspunkte

% Ausrollkurven
load('ausrollen_a_v');

% Kennfeld Brennstoffzelle (I über U)
load('brennstoffzellen_ui_kennfeld');

% Wirkungsgrad Brennstoffzelle
load('brennstoffzellen_eta_kennfeld');


%% Radius minimum suchen
strecke.min_Radius = min(strecke.radius);

%% Eingabe Timestep Simulation
ts = 0.01;

%% Zwangsgas-Matrix erstellen (Spaltennummer steht für jeweilige Runde)
% load('zwangsgas_timo');
zwangsgas = zeros(length(strecke.x),strecke.Rundenzahl);

%% Speichern der im Motorkennfeld hinterlegten Informationen in einer extra Tabelle, um es in Simulink verarbeiten zu können

    %% Moment
    % Aufbau Tabelle: Spannung | Strom | min | max | coeffs
string_fieldnames_U_moment = fieldnames( coeffs_motor.moment ); % alle Pfade, wo Spannungen hinterlegt
for i = 1:1:length(string_fieldnames_U_moment)
    string_with_k_U_moment(i,1) = extractAfter( string_fieldnames_U_moment(i,1) , "spannung_V_"); % hinterlegte Spannungswerte herausfinden
    string_U_moment(i,1) = strrep( string_with_k_U_moment(i,1) , 'k' , '.');                             % ersetze "k" mit "." im String
end
string_U_moment = string( string_U_moment );  % cell-array zu array und string zu zahlen
for i = 1:1:length(string_U_moment)
    U_moment(i,1) = str2num( string_U_moment(i,1) ); % string zu zahlen
    U_moment(i,2) = length( fields( eval( strcat( 'coeffs_motor.moment.' , string(string_fieldnames_U_moment(i,1) )))));   % wieviel Ströme je Spannung hinterlegt
end
U_moment = sortrows(U_moment,1);                  % sortieren von klein nach groß

for i = 1:1:size(U_moment,1)        % gehe alle Zeilen durch
    
    string_with_k_U_moment      = strrep( sprintf('%2.1f' , U_moment(i,1)) , '.' , 'k');                                                     % ersetze "k" mit "."
    string_fieldnames_I_moment  = fieldnames( eval( strcat('coeffs_motor.moment.spannung_V_' , string(string_with_k_U_moment))));  % alle Pfade, wo für aktuell betrachtete Spannungen die Ströme hinterlegt sind

    for k = 1:1:length(string_fieldnames_I_moment)
        string_with_k_I_moment(k,1) = extractAfter( string_fieldnames_I_moment(k,1) , "strom_A_"); % hinterlegte Stromswerte herausfinden
        string_I_moment(k,1) = strrep( string_with_k_I_moment(k,1) , 'k' , '.');                             % ersetze "k" mit "." im String
    end
    string_I_moment = string( string_I_moment );
    for m = 1:1:length(string_I_moment)
        I_moment(m,1) = str2num( string_I_moment(m,1) ); % string zu zahlen
    end
    I_moment = sort(I_moment);        % sortieren von klein nach groß

    
    for j = 1:1:length(I_moment) % geh alle Ströme durch
        string_with_k_I_moment  = strrep( sprintf('%2.1f' , I_moment(j,1)) , '.' , 'k');                                      % hinterlegte Stromwerte herausfinden
        
        % speichern in Matrix:
        coeffs_motor_moment(i + j - 1 , 1) = str2num( sprintf('%2.1f' , U_moment(i,1)) );
        coeffs_motor_moment(i + j - 1 , 2) = str2num( sprintf('%2.1f' , I_moment(j,1)) );
        coeffs_motor_moment(i + j - 1 , 3) = coeffs_motor.moment.(strcat('spannung_V_' , string_with_k_U_moment)).(strcat('strom_A_' , string_with_k_I_moment)).min;
        coeffs_motor_moment(i + j - 1 , 4) = coeffs_motor.moment.(strcat('spannung_V_' , string_with_k_U_moment)).(strcat('strom_A_' , string_with_k_I_moment)).max;
            % Anzahl der Koeffizienten herausfinden
            anzahl_coeffs = length( coeffs_motor.moment.(strcat('spannung_V_' , string_with_k_U_moment)).(strcat('strom_A_' , string_with_k_I_moment)).coeffs );
        coeffs_motor_moment(i + j - 1 , 5:4+anzahl_coeffs) = fliplr( coeffs_motor.moment.(strcat('spannung_V_' , string_with_k_U_moment)).(strcat('strom_A_' , string_with_k_I_moment)).coeffs );
    end
    
    
end

    %% Wirkungsgrad
    % Aufbau Tabelle: Spannung | Strom | min | max | coeffs
string_fieldnames_U_wirkungsgrad = fieldnames( coeffs_motor.wirkungsgrad ); % alle Pfade, wo Spannungen hinterlegt
for i = 1:1:length(string_fieldnames_U_wirkungsgrad)
    string_with_k_U_wirkungsgrad(i,1) = extractAfter( string_fieldnames_U_wirkungsgrad(i,1) , "spannung_V_"); % hinterlegte Spannungswerte herausfinden
    string_U_wirkungsgrad(i,1) = strrep( string_with_k_U_wirkungsgrad(i,1) , 'k' , '.');                             % ersetze "k" mit "." im String
end
string_U_wirkungsgrad = string( string_U_wirkungsgrad );  % cell-array zu array und string zu zahlen
for i = 1:1:length(string_U_wirkungsgrad)
    U_wirkungsgrad(i,1) = str2num( string_U_wirkungsgrad(i,1) ); % string zu zahlen
    U_wirkungsgrad(i,2) = length( fields( eval( strcat( 'coeffs_motor.wirkungsgrad.' , string(string_fieldnames_U_wirkungsgrad(i,1) )))));   % wieviel Ströme je Spannung hinterlegt
end
U_wirkungsgrad = sortrows(U_wirkungsgrad,1);                  % sortieren von klein nach groß

for i = 1:1:size(U_wirkungsgrad,1)
    
    string_with_k_U_wirkungsgrad      = strrep( sprintf('%2.1f' , U_wirkungsgrad(i,1)) , '.' , 'k');                                                     % ersetze "k" mit "."
    string_fieldnames_I_wirkungsgrad  = fieldnames( eval( strcat('coeffs_motor.wirkungsgrad.spannung_V_' , string(string_with_k_U_wirkungsgrad))));  % alle Pfade, wo für aktuell betrachtete Spannungen die Ströme hinterlegt sind

    for k = 1:1:length(string_fieldnames_I_wirkungsgrad)
        string_with_k_I_wirkungsgrad(k,1) = extractAfter( string_fieldnames_I_wirkungsgrad(k,1) , "strom_A_"); % hinterlegte Stromswerte herausfinden
        string_I_wirkungsgrad(k,1) = strrep( string_with_k_I_wirkungsgrad(k,1) , 'k' , '.');                             % ersetze "k" mit "." im String
    end
    string_I_wirkungsgrad = string( string_I_wirkungsgrad );
    for m = 1:1:length(string_I_wirkungsgrad)
        I_wirkungsgrad(m,1) = str2num( string_I_wirkungsgrad(m,1) ); % string zu zahlen
    end
    I_wirkungsgrad = sort(I_wirkungsgrad);        % sortieren von klein nach groß

    
    for j = 1:1:length(I_wirkungsgrad) % geh alle Ströme durch
        string_with_k_I_wirkungsgrad  = strrep( sprintf('%2.1f' , I_wirkungsgrad(j,1)) , '.' , 'k');                                      % hinterlegte Stromwerte herausfinden
        
        % speichern in Matrix:
        coeffs_motor_wirkungsgrad(i + j - 1 , 1) = str2num( sprintf('%2.1f' , U_wirkungsgrad(i,1)) );
        coeffs_motor_wirkungsgrad(i + j - 1 , 2) = str2num( sprintf('%2.1f' , I_wirkungsgrad(j,1)) );
        coeffs_motor_wirkungsgrad(i + j - 1 , 3) = coeffs_motor.wirkungsgrad.(strcat('spannung_V_' , string_with_k_U_wirkungsgrad)).(strcat('strom_A_' , string_with_k_I_moment)).min;
        coeffs_motor_wirkungsgrad(i + j - 1 , 4) = coeffs_motor.wirkungsgrad.(strcat('spannung_V_' , string_with_k_U_wirkungsgrad)).(strcat('strom_A_' , string_with_k_I_moment)).max;
            % Anzahl der Koeffizienten herausfinden
            anzahl_coeffs = length( coeffs_motor.wirkungsgrad.(strcat('spannung_V_' , string_with_k_U_wirkungsgrad)).(strcat('strom_A_' , string_with_k_I_wirkungsgrad)).coeffs );
        coeffs_motor_wirkungsgrad(i + j - 1 , 5 : 4+anzahl_coeffs) = fliplr( coeffs_motor.wirkungsgrad.(strcat('spannung_V_' , string_with_k_U_wirkungsgrad)).(strcat('strom_A_' , string_with_k_I_wirkungsgrad)).coeffs );
    end
clear I_moment I_wirkungsgrad anzahl_coeffs i j k m string_fieldnames_I_moment string_fieldnames_I_wirkungsgrad string_fieldnames_U_moment string_fieldnames_U_wirkungsgrad string_I_moment string_I_wirkungsgrad string_U_moment string_U_wirkungsgrad string_with_k_I_moment string_with_k_I_wirkungsgrad string_with_k_U_moment string_with_k_U_wirkungsgrad     
    
end

toc