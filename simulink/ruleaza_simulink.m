%% Construiește, simulează și verifică toate modelele Simulink ale proiectului (MATLAB R2023b sau mai nou,
%  Simulink + Simscape Electrical cu biblioteca Specialized Power Systems).
%  Rulare: în MATLAB, din folderul simulink/ al depozitului:   ruleaza_simulink
%  Selecție (opțional, înainte de rulare):   MODELE = {'c3_A', 'masina'};  ruleaza_simulink
%  Modele: c3_A, c3_D – modelul MCC din C3 cu blocuri Simulink de bază (scenariile A și D)
%          masina     – DC Machine (SPS) cu parametrii YM720 echivalenți
%          dcdc       – convertorul DC-DC bidirecțional cu 4 faze (SPS)
%          incarcator – încărcătorul CC-CV cu histerezis (SPS)
%          ansamblu   – sistemul complet pe ciclul P3 (SPS; durează câteva minute)
%  Rezultate: modele/*.slx (se pot deschide și modifica în Simulink), rezultate/*.png,
%  rezultate/rezultate_simulink.json și jurnalul complet rezultate/jurnal_simulink.txt.

aici = fileparts(mfilename('fullpath'));
addpath(aici);
if ~exist(fullfile(aici, 'modele'), 'dir'), mkdir(fullfile(aici, 'modele')); end
if ~exist(fullfile(aici, 'rezultate'), 'dir'), mkdir(fullfile(aici, 'rezultate')); end
jurnal = fullfile(aici, 'rezultate', 'jurnal_simulink.txt');
if exist(jurnal, 'file'), delete(jurnal); end
diary(jurnal);
fprintf('=== CCA – modelele Simulink (%s) ===\n', datestr(now, 'yyyy-mm-dd HH:MM'));
fprintf('MATLAB %s\n', version);
v = ver;  nume_tb = {v.Name};
for tb = {'Simulink', 'Simscape', 'Simscape Electrical'}
    k = find(strcmp(nume_tb, tb{1}), 1);
    if isempty(k), fprintf('  %-20s: LIPSEȘTE\n', tb{1}); else, fprintf('  %-20s: %s\n', tb{1}, v(k).Version); end
end
fprintf('  biblioteca Specialized Power Systems (sps_lib): %s\n', mat2str(exist('sps_lib', 'file') == 4));

if ~exist('MODELE', 'var')
    MODELE = {'c3_A', 'c3_D', 'masina', 'dcdc', 'incarcator', 'ansamblu'};
end
if ~(exist('REFERINTE_CALCULATE', 'var') && REFERINTE_CALCULATE)
    fprintf('\nParametrii și simulările de referință (din scripturile etapelor 2-4)...\n');
    P = parametri_simulink();
    Z = simulari(P.S, P.M, P.T);                                     % referința MATLAB pentru C3
    Rd = sim_dcdc_comutatie(P.D, P.S.cv.simulare.dcdc);              % referința MATLAB pentru DC-DC
    Ri = sim_incarcare_comutatie(P.C, P.S.cv.simulare.incarcare);    % referința MATLAB pentru încărcător
end

rezultate = struct();
stare = cell(numel(MODELE), 3);
for q = 1:numel(MODELE)
    m = MODELE{q};
    fprintf('\n--- %s ---\n', m);
    tic;
    try
        switch m
            case 'c3_A',       r = model_c3_mcc('A', P, Z);
            case 'c3_D',       r = model_c3_mcc('D', P, Z);
            case 'masina',     r = model_sps_masina(P, Z);
            case 'dcdc',       r = model_sps_dcdc(P, Rd);
            case 'incarcator', r = model_sps_incarcator(P, Ri);
            case 'ansamblu',   r = model_sps_ansamblu(P);
            otherwise,         error('Model necunoscut: %s', m);
        end
        for f = {'t', 'I', 'W', 'T_ax'}
            if isfield(r, f{1}), r = rmfield(r, f{1}); end
        end
        rezultate.(m) = r;
        stare(q, :) = {m, 'OK', sprintf('%.1f s', toc)};
    catch e
        fprintf(2, 'EROARE în %s: %s\n', m, e.message);
        for s = e.stack(1:min(3, end)).'
            fprintf(2, '   la %s (linia %d)\n', s.name, s.line);
        end
        rezultate.(m) = struct('eroare', e.message);
        stare(q, :) = {m, 'EROARE', sprintf('%.1f s', toc)};
    end
end
fprintf('\n=== Rezumat ===\n');
for q = 1:size(stare, 1)
    fprintf('  %-12s %-7s %s\n', stare{q, :});
end
f = fopen(fullfile(aici, 'rezultate', 'rezultate_simulink.json'), 'w');
fprintf(f, '%s', jsonencode(rezultate));
fclose(f);
fprintf('\nModelele sunt în simulink/modele, figurile și rezultatele în simulink/rezultate.\n');
fprintf('Dacă apare o eroare, trimiteți fișierul simulink/rezultate/jurnal_simulink.txt.\n');
diary off;
