%% CCA – Curs C3, exercițiul 1: calculul pierderilor după modelul MCC și hărțile de randament
% Rulare: din folderul matlab/, comanda  main_pierderi
% Mașina sincronă cu magneți permanenți YM720 este descrisă cu ecuațiile MCC (echivalentul de curent
% continuu al comenzii vectoriale): U = E + Ra*I + dUp, E = k*phi*W, T_E = k*phi*I.

if exist('GRAFICE', 'var'), grafice = GRAFICE; else, grafice = true; end
S = incarca_date();
M = identificare_mcc(S.mot, S.ip);
T = tema_proiect(S, M);
rpm = 60 / (2*pi);

%% 1. Parametrii modelului (din catalog + ipotezele din date/ipoteze_masina.json)
fprintf('\n=== C3 – Parametrii modelului MCC echivalent (un motor %s) ===\n', S.mot.nume);
fprintf('Punctul nominal: P_n = %.0f kW, M_n = %.0f Nm -> W_n = %.2f rad/s (%.0f rot/min)\n', ...
        M.P_n/1e3, M.M_n, M.W_n, M.n_n);
fprintf('  eta_n = %.3f -> P1_n = %.2f kW, pierderi totale = %.2f kW, I_n = P1_n/U_n = %.2f A\n', ...
        M.eta_n, M.P1_n/1e3, M.SP_n/1e3, M.I_n);
fprintf('  împărțirea pierderilor: Cu %.0f %%, Fe %.0f %%, mecanice %.0f %%\n', ...
        100*M.P_a_n/M.SP_n, 100*M.P_Fe_n/M.SP_n, 100*M.P_fv_n/M.SP_n);
fprintf('R_a  = %.5f Ohm      dU_p = %.2f V (fără perii)\n', M.R_a, M.dU_p);
fprintf('k    = kE = kM = %.5f V*s/rad = Nm/A   (E_n = %.2f V)\n', M.k, M.E_n);
fprintf('K_H  = %.5f Nm,  K_F = %.4e Nm*s/rad   (P_Fe = K_H*W + K_F*W^2; P_Fe(n_max)/P_Fe(n_n) = %.2f)\n', ...
        M.K_H, M.K_F, S.ip.raport_Fe_max);
fprintf('T_m0 = %.5f Nm,  F_m = %.4e Nm*s/rad   (P_fv = T_m0*W + F_m*W^2; P_fv(n_max)/P_fv(n_n) = %.2f)\n', ...
        M.T_m0, M.F_m, S.ip.raport_mec_max);
fprintf('T_f0 = K_H + T_m0 = %.4f Nm,  F_v = K_F + F_m = %.4e Nm*s/rad\n', M.T_f0, M.F_v);
fprintf('Verificare: T_ax(n_n) = k*I_n - T_f0 - F_v*W_n = %.3f Nm (M_n = %.0f Nm)\n', M.T_ax_n_verif, M.M_n);
fprintf('Viteza de bază la M_max: n_b = %.0f rot/min, I_max = %.1f A, P(M_max, n_b) = %.1f kW\n', ...
        M.n_b, M.I_max, M.P_b/1e3);
fprintf('L_a = %.3g H, tau_a = L_a/R_a = %.3g s, J_rotor = %.4g kg*m2\n', M.L_a, M.tau_a, M.J_rotor);

%% 2. Pornirea (C3, IV)
fprintf('\n=== C3 – Pornirea ===\n');
fprintf('Pornire directă la U_n: I_p = (U_n - dU_p)/R_a = %.0f A (%.1f × I_n), M_p = %.0f Nm – inadmisibil\n', ...
        M.I_p_Un, M.I_p_Un/M.I_n, M.M_p_Un);
fprintf('Pornire la tensiune redusă (convertor): U_p = R_a*I_max + dU_p = %.2f V limitează I_p la I_max = %.1f A\n', ...
        M.U_p, M.I_max);

%% 3. Diagrama de puteri în punctele caracteristice (C3, V–VII)
W_varf = min(M.W_b, M.P_max / M.M_max);
pct = {
  'nominal (n_n, M_n)',              M.W_n,                    M.M_n
  'cuplu maxim (P_max/M_max)',       W_varf,                   M.M_max
  'putere maximă la n_max',          M.W_max,                  M.P_max / M.W_max
  'v_max (P_n necesar / N)',         T.n_m_vmax / rpm,         T.M_nec_n / T.N
  '100 km/h, viteză constantă',      T.n_m_Va / rpm,           NaN
  '50 km/h, viteză constantă (P3)',  S.R3.V1 / S.C2.r * T.k_rd, S.R3.Ft1p * S.C2.r / (T.N * T.k_rd * T.eta_rd)
};
% 100 km/h constant: forțele din P2 la Va fără accelerație
F100 = forte_rezistente(S.R2.Va, 0, S.V, S.C2);
pct{5, 3} = F100.Ft * S.C2.r / (T.N * T.k_rd * T.eta_rd);
fprintf('\n=== C3 – Diagrama de puteri (un motor) ===\n');
fprintf('%-32s %7s %7s %6s %7s %7s %8s %7s %7s %7s %8s %7s\n', 'Punct', 'n', 'T_ax', 'phi', 'U', 'I', ...
        'P1', 'P_a', 'P_Fe', 'P_fv', 'P2', 'eta');
fprintf('%-32s %7s %7s %6s %7s %7s %8s %7s %7s %7s %8s %7s\n', '', 'rot/min', 'Nm', '-', 'V', 'A', ...
        'kW', 'kW', 'kW', 'kW', 'kW', '%');
puncte = struct('nume', {}, 'n', {}, 'T', {}, 'L', {});
for q = 1:size(pct, 1)
    L = punct_functionare(M, pct{q, 2}, pct{q, 3});
    puncte(q).nume = pct{q, 1};  puncte(q).n = pct{q, 2} * rpm;  puncte(q).T = pct{q, 3};  puncte(q).L = L;
    fprintf('%-32s %7.0f %7.1f %6.3f %7.1f %7.1f %8.2f %7.3f %7.3f %7.3f %8.2f %7.2f\n', pct{q, 1}, ...
            pct{q, 2} * rpm, pct{q, 3}, L.phi, L.U, L.I, L.P1/1e3, L.P_a/1e3, L.P_Fe/1e3, L.P_fv/1e3, ...
            L.P2/1e3, 100 * L.eta);
end

%% 4. Harta de randament
H = harta_randament(M, 120);
fprintf('\nHarta de randament: eta_max = %.2f %% la n = %.0f rot/min, T_ax = %.0f Nm\n', ...
        100 * H.eta_max, H.n_eta_max, H.T_eta_max);
fprintf('Zona cu eta >= 95 %%: %.1f %% din domeniul de funcționare\n', ...
        100 * sum(H.eta(:) >= 0.95) / sum(~isnan(H.eta(:))));

%% 5. Caracteristicile mecanice n = f(T_ax)
K = caracteristici_mecanice(M, [1 0.75 0.5 0.25], [0.8 0.6 M.W_b / M.W_max]);
fprintf('\nCaracteristici mecanice: mers în gol la U_n: n_0 = %.0f rot/min; la M_max cu U_n: %.0f rot/min\n', ...
        K.n_U(1, 1), K.n_U(1, end));

%% 6. Încălzirea (C3, VIII): Q = m*c*dT (fără răcire)
Z = simulari(S, M, T);
Hc = incalzire(S, M, T, Z);
fprintf('\n=== C3 – Căldura produsă de pierderi (un motor, m = %.0f kg, c = %.0f J/(kg*K), m*c = %.0f J/K) ===\n', ...
        M.masa, M.c, Hc.mc);
fprintf('Accelerare 0–100 km/h (simularea B, %.2f s): Q = %.1f kJ, P_med = %.1f kW, dT = %.2f K\n', ...
        Hc.acc.durata, Hc.acc.Q/1e3, Hc.acc.P_med/1e3, Hc.acc.dT);
fprintf('Cuplu maxim %d s la %.0f rot/min: pierderi %.1f kW (eta = %.1f %%), Q = %.0f kJ, dT = %.1f K\n', ...
        Hc.varf.durata, Hc.varf.n, Hc.varf.SP/1e3, 100*Hc.varf.eta, Hc.varf.Q/1e3, Hc.varf.dT);
fprintf('Rulare cu v_max: pierderi %.2f kW/motor (eta = %.1f %%) -> dT = %.1f K în fiecare minut fără răcire;\n', ...
        Hc.vmax.SP/1e3, 100*Hc.vmax.eta, Hc.vmax.dT_min);
fprintf('  puterea de răcire necesară în regim permanent = %.2f kW/motor\n', Hc.vmax.SP/1e3);
fprintf('Ciclul P3, palier 50 km/h (%.0f s): pierderi %.0f W/motor (eta = %.1f %%), Q = %.1f MJ – fără răcire dT = %.0f K\n', ...
        S.R3.t12, Hc.p3.SP, 100*Hc.p3.eta, Hc.p3.Q/1e6, Hc.p3.dT);
fprintf('  -> răcirea cu ulei trebuie să evacueze continuu %.0f W/motor\n', Hc.p3.SP);

%% 7. Figuri
if grafice
    figure('Name', 'C3 – harta de randament');
    contourf(H.n, H.T, 100 * H.eta, [80 85 88 90 92 93 94 95 96 97]); colorbar; hold on;
    plot(H.anv_n, H.anv_T, 'k', 'LineWidth', 1.5);
    for q = 1:numel(puncte), plot(puncte(q).n, puncte(q).T, 'rx', 'MarkerSize', 9, 'LineWidth', 1.5); end
    xlabel('n [rot/min]'); ylabel('T_{ax} [Nm]'); title(sprintf('Randamentul [%%] – %s (model MCC)', S.mot.nume));
    figure('Name', 'C3 – caracteristici mecanice');
    plot(K.T, K.n_U, '-', K.T, K.n_phi, '--', K.anv_T, K.anv_n, 'k', 'LineWidth', 1.2); grid on;
    xlabel('T_{ax} [Nm]'); ylabel('n [rot/min]'); title('Caracteristici mecanice n = f(T_{ax})');
    legend([arrayfun(@(u) sprintf('U = %.2f U_n', u), K.U_rel, 'UniformOutput', false), ...
            arrayfun(@(p) sprintf('U_n, \\phi = %.2f', p), K.phi_rel, 'UniformOutput', false), {'limita catalog'}]);
end
