%% Rulează P2 și P3 și salvează rezultatele numerice în ../rezultate/rezultate_matlab.json
% Rezultatele sunt comparate cu implementarea Python / Excel (python/calcule_p2_p3.py).

if ~exist('GRAFICE', 'var'), GRAFICE = false; end
main_p2;
main_p3;

C   = constante();
D   = date_intrare();
cel = celula_aleasa();
nume = {'medie', 'gt63'};
iesire = struct();
for k = 1:2
    V  = D.(nume{k});
    R2 = calcul_p2(V, C);
    R3 = calcul_p3(V, C, R2);
    B  = dimensionare_baterie(R3.Wbat, cel, V, C, R2.P_max);
    bloc = struct();
    bloc.date = V;
    bloc.p2 = R2;
    bloc.p3_discretizare = struct('n', C.n_pasi, ...
        'P01_med', [R3.disc.P01_med], 'W01', [R3.disc.W01], ...
        'eroare_W01_pct', [R3.disc.eroare_W01_pct], 'timp_s', [R3.disc.timp_s]);
    bloc.p3 = rmfield(R3, 'disc');
    bloc.baterie = rmfield(B, 'celula');
    iesire.(nume{k}) = bloc;
end
iesire.constante = C;
iesire.celula = cel;

aici = fileparts(mfilename('fullpath'));
f = fopen(fullfile(aici, '..', 'rezultate', 'rezultate_matlab.json'), 'w');
fprintf(f, '%s', jsonencode(iesire));
fclose(f);
fprintf('\nRezultate salvate în rezultate/rezultate_matlab.json\n');
