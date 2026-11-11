function S = incarca_date()
%INCARCA_DATE Datele de intrare pentru P4 / C3.
%   S.C2, S.D, S.R2, S.R3, S.B – rezultatele etapei 2 (P2/P3), recalculate cu funcțiile din ../../etapa2-calcule/matlab
%   S.mot – motorul ales din catalog (../date/motor_ales.json)
%   S.ip  – ipotezele pentru modelul mașinii și al reductorului (../date/ipoteze_masina.json)

aici = fileparts(mfilename('fullpath'));
addpath(fullfile(aici, '..', '..', 'etapa2-calcule', 'matlab'));

S.C2  = constante();
S.D   = date_intrare();
S.V   = S.D.medie;                               % tema se face pentru vehiculul mediu
S.R2  = calcul_p2(S.V, S.C2);
S.R3  = calcul_p3(S.V, S.C2, S.R2);
S.cel = celula_aleasa();
S.B   = dimensionare_baterie(S.R3.Wbat, S.cel, S.V, S.C2, S.R2.P_max);

S.mot = jsondecode(fileread(fullfile(aici, '..', 'date', 'motor_ales.json')));
S.ip  = jsondecode(fileread(fullfile(aici, '..', 'date', 'ipoteze_masina.json')));
end
