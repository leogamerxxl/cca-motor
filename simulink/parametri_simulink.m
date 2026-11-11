function P = parametri_simulink()
%PARAMETRI_SIMULINK Toate mărimile folosite de modelele Simulink, calculate cu scripturile MATLAB ale
%   proiectului (etapele 2, 3 și 4), ca valorile din Simulink să fie aceleași cu cele din calcule.
%   P.S – datele (vehicul mediu, baterie, ipoteze), P.M – parametrii unui motor (model MCC echivalent),
%   P.T – tema P4, P.D – DC-DC bidirecțional, P.H – chopperul, P.C – încărcătorul,
%   P.gol / P.veh – parametrii modelului dinamic al unui motor (fără / cu vehiculul).
aici = fileparts(mfilename('fullpath'));
addpath(fullfile(aici, '..', 'etapa4-convertoare', 'matlab'));   % adaugă și etapele 3 și 2
S = incarca_date4();
P.S = S;  P.M = S.M;  P.T = S.T;
P.D = dimensionare_dcdc(S);
P.H = dimensionare_chopper(S);
P.C = dimensionare_incarcator(S);
P.gol = parametri_model(S, S.M, S.T, 'gol');
P.veh = parametri_model(S, S.M, S.T, 'vehicul');
P.dir_modele = fullfile(aici, 'modele');
P.dir_rezultate = fullfile(aici, 'rezultate');
end
