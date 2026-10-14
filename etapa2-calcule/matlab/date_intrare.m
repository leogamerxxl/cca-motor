function D = date_intrare(fisier_csv)
%DATE_INTRARE Citește datele din documentare (etapa 1) și le transformă în S.I.
%   D = DATE_INTRARE() citește ../date/date_documentare.csv și întoarce:
%     D.vehicule – structură cu datele brute și în S.I. pentru fiecare vehicul de serie
%     D.medie    – „vehiculul mediu” (media datelor din documentare, cerința P2/P3)
%     D.gt63     – vehiculul de referință Mercedes-AMG GT 63 4-Door Coupé (pentru comparație)
%   Valorile lipsă din CSV sunt NaN și sunt excluse din medii.

if nargin < 1
    aici = fileparts(mfilename('fullpath'));
    fisier_csv = fullfile(aici, '..', 'date', 'date_documentare.csv');
end

fid = fopen(fisier_csv, 'r', 'n', 'UTF-8');
if fid < 0
    error('Nu pot deschide %s', fisier_csv);
end
antet = strsplit(strtrim(fgetl(fid)), ',');
linii = {};
while true
    l = fgetl(fid);
    if ~ischar(l), break; end
    l = strtrim(l);
    if isempty(l), continue; end
    linii{end+1} = strsplit(l, ','); %#ok<AGROW>
end
fclose(fid);

col = @(nume) find(strcmp(antet, nume));
n = numel(linii);
num = @(nume) cellfun(@(c) str2double(c{col(nume)}), linii);

T.vehicul     = cellfun(@(c) c{col('vehicul')}, linii, 'UniformOutput', false);
T.P_kW        = num('P_max_kW');
T.vmax_kmh    = num('v_max_kmh');
T.t_acc_s     = num('t_acc_s');
T.v_acc_kmh   = num('v_acc_kmh');
T.M_kg        = num('masa_kg');
T.cuplu_Nm    = num('cuplu_Nm');
T.bat_kWh     = num('baterie_kWh');
T.aut_min_km  = num('autonomie_min_km');
T.aut_max_km  = num('autonomie_max_km');
T.ciclu       = cellfun(@(c) c{col('ciclu')}, linii, 'UniformOutput', false);
T.cons_min    = num('consum_min_kWh100');
T.cons_max    = num('consum_max_kWh100');
T.Cx          = num('Cx');
T.A_m2        = num('A_m2');
T.anv_lat_mm  = num('anv_spate_latime_mm');
T.anv_prof    = num('anv_spate_profil_pct');
T.janta_in    = num('janta_spate_inch');

% --- mărimi derivate (S.I.) pentru fiecare vehicul ---
T.P_W        = T.P_kW * 1e3;                       % [W]
T.vmax_ms    = T.vmax_kmh / 3.6;                    % [m/s]
T.a_ms2      = (T.v_acc_kmh / 3.6) ./ T.t_acc_s;    % [m/s^2] accelerație medie 0–v_acc
T.bat_Ws     = T.bat_kWh * 3.6e6;                   % [Ws]
T.aut_km     = (T.aut_min_km + T.aut_max_km) / 2;   % [km] mijlocul intervalului declarat
T.cons_kWh100 = (T.cons_min + T.cons_max) / 2;      % [kWh/100 km]
T.cons_Wsm   = T.cons_kWh100 / 100 * 3600;          % [Ws/m]  (1 kWh/km = 3600 Ws/m)
T.r_static_m = (T.janta_in * 25.4 / 2 + T.anv_lat_mm .* T.anv_prof / 100) / 1000; % [m]

D.vehicule = T;
D.n = n;

% --- vehiculul mediu ---
% Autonomia și consumul se mediază doar pe valorile WLTP (ciclurile CLTC / EPA
% nu sunt comparabile cu WLTP); celelalte mărimi pe toate vehiculele de serie.
med = @(x) mean(x(~isnan(x)));
wltp = strcmp(T.ciclu, 'WLTP');
V.nume       = 'Vehicul mediu (documentare)';
V.P_doc      = med(T.P_W);
V.vmax       = med(T.vmax_ms);
V.a_doc      = med(T.a_ms2);
V.M          = med(T.M_kg);
V.cuplu_doc  = med(T.cuplu_Nm);
V.W_bat_doc  = med(T.bat_Ws);
V.autonomie  = med(T.aut_km(wltp)) * 1e3;           % [m]   (doar WLTP)
V.consum_doc = med(T.cons_Wsm(wltp));               % [Ws/m] (doar WLTP)
V.Cx         = med(T.Cx);
V.S          = med(T.A_m2);
V.r_static   = med(T.r_static_m);
V.n_valori   = struct('Cx', sum(~isnan(T.Cx)), 'S', sum(~isnan(T.A_m2)), ...
                      'autonomie', sum(~isnan(T.aut_km(wltp))), ...
                      'consum', sum(~isnan(T.cons_Wsm(wltp))), 'r', sum(~isnan(T.r_static_m)));
D.medie = V;

% --- vehiculul de referință (rândul GT 63) ---
k = find(strncmp(T.vehicul, 'Mercedes-AMG GT 63', 18), 1);
G.nume       = T.vehicul{k};
G.P_doc      = T.P_W(k);
G.vmax       = T.vmax_ms(k);
G.a_doc      = T.a_ms2(k);
G.M          = T.M_kg(k);
G.cuplu_doc  = T.cuplu_Nm(k);
G.W_bat_doc  = T.bat_Ws(k);
G.autonomie  = T.aut_km(k) * 1e3;
G.consum_doc = T.cons_Wsm(k);
G.Cx         = T.Cx(k);
G.S          = T.A_m2(k);
G.r_static   = V.r_static;   % dimensiunea anvelopelor GT 63 EV nu este publicată
D.gt63 = G;
end
