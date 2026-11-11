%% Rulează tema (P4), pierderile (C3 ex. 1) și simulările (C3 ex. 2, P4) și salvează rezultatele
% numerice în ../rezultate/rezultate_matlab.json, pentru comparația cu implementarea Python
% (python/calcule_p4.py).

% Implicit fără figuri; pentru figuri: GRAFICE = true; ruleaza_tot
grafice_implicit = ~exist('GRAFICE', 'var');
if grafice_implicit, GRAFICE = false; end
main_tema;
main_pierderi;
main_simulare;
if grafice_implicit, clear GRAFICE; end

% puncte de comparație din simulări (valorile salvate la momente fixe)
esant = @(Q, tt) interp1(Q.t, [Q.I, Q.W], tt);
iesire = struct();
iesire.motor = M;
iesire.tema = T;
iesire.puncte = arrayfun(@(p) struct('nume', p.nume, 'n', p.n, 'T', p.T, 'phi', p.L.phi, 'U', p.L.U, ...
    'I', p.L.I, 'P1', p.L.P1, 'P_a', p.L.P_a, 'P_Fe', p.L.P_Fe, 'P_fv', p.L.P_fv, 'P2', p.L.P2, ...
    'eta', p.L.eta), puncte);
iesire.harta = struct('eta_max', H.eta_max, 'n_eta_max', H.n_eta_max, 'T_eta_max', H.T_eta_max, ...
    'cota_95', sum(H.eta(:) >= 0.95) / sum(~isnan(H.eta(:))));
iesire.caracteristici = struct('n0_Un', K.n_U(1, 1), 'n_Mmax_Un', K.n_U(1, end));
iesire.incalzire = Hc;
iesire.sim.A = struct('I_varf', Z.A.I_varf, 'W_gol', Z.A.W_gol, 'W_final', Z.A.W_final, 'I_final', Z.A.I_final, ...
    'W_gol_teoretic', Z.A.W_gol_teoretic, 'W_sarcina_teoretic', Z.A.W_sarcina_teoretic, ...
    'I_sarcina_teoretic', Z.A.I_sarcina_teoretic, ...
    'esantioane', esant(Z.A, [0.002 0.01 0.03]));
iesire.sim.B = struct('t_100', Z.B.t_100, 't_200', Z.B.t_200, 't_vmax', Z.B.t_vmax, ...
    'atins_vmax', Z.B.atins_vmax, 'I_varf', Z.B.I_varf, 'T_ad', Z.B.T_ad, 'esantioane', esant(Z.B, [1 3 10]));
iesire.sim.D = struct('I_varf', Z.D.I_varf, 'W_final', Z.D.W_final, 'esantioane', esant(Z.D, [2 5 8]));
iesire.sim.C = rmfield(C, {'t', 'I', 'W', 'v', 'v_ref', 'U', 'phi', 'T_ax', 'I_ref', 'T_fm', 'P_ax', 'P_el', ...
    'P_dc', 'P_bat', 'I_bat', 'U_bat', 'P_chim', 'P_fm', 'P_rez'});
iesire.sim.C.esantioane = esant(C, [1 4 8]);

aici = fileparts(mfilename('fullpath'));
f = fopen(fullfile(aici, '..', 'rezultate', 'rezultate_matlab.json'), 'w');
fprintf(f, '%s', jsonencode(iesire));
fclose(f);
fprintf('\nRezultate salvate în rezultate/rezultate_matlab.json\n');
