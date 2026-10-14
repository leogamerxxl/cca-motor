%% CCA – Proiect P2: prelucrarea datelor din documentare și puterea mașinii electrice
% Rulare: din folderul matlab/, comanda  main_p2
% Rezultate: tabel în Command Window + figurile P2 (dacă GRAFICE = true).

if ~exist('GRAFICE', 'var'), GRAFICE = true; end
C = constante();
D = date_intrare();

%% 1. Datele medii din documentare transformate în S.I. (slide 2)
V = D.medie;
fprintf('\n=== P2.1 Date medii din documentare (%d vehicule de serie) ===\n', D.n);
fprintf('%-34s %14s   %s\n', 'Mărime', 'Valoare S.I.', 'Echivalent');
fprintf('%-34s %14.4g W    %8.1f kW\n',      'Putere maximă',           V.P_doc, V.P_doc/1e3);
fprintf('%-34s %14.4g m/s  %8.1f km/h\n',    'Viteză maximă',           V.vmax, V.vmax*3.6);
fprintf('%-34s %14.4g m/s2 %8.2f s (0–100)\n','Accelerație medie 0–100', V.a_doc, (100/3.6)/V.a_doc);
fprintf('%-34s %14.4g m    %8.1f km (WLTP, %d valori)\n', 'Autonomie', V.autonomie, V.autonomie/1e3, V.n_valori.autonomie);
fprintf('%-34s %14.4g kg\n',                  'Masă',                    V.M);
fprintf('%-34s %14.4g Ws   %8.1f kWh\n',     'Capacitate baterie',      V.W_bat_doc, V.W_bat_doc/3.6e6);
fprintf('%-34s %14.4g Nm\n',                  'Cuplu',                   V.cuplu_doc);
fprintf('%-34s %14.4g Ws/m %8.2f kWh/100 km (WLTP, %d valori)\n', 'Consum mediu', V.consum_doc, ...
        V.consum_doc*100/3600, V.n_valori.consum);
fprintf('%-34s %14.4g -    (%d valori)\n',    'Cx',                      V.Cx, V.n_valori.Cx);
fprintf('%-34s %14.4g m2   (%d valori)\n',    'Suprafață frontală S',    V.S, V.n_valori.S);
fprintf('%-34s %14.4g m    (r static, %d valori)\n', 'Raza roții', V.r_static, V.n_valori.r);

%% 2. Pașii 1–9 pentru vehiculul mediu și pentru GT 63
R2 = [calcul_p2(D.medie, C), calcul_p2(D.gt63, C)];
for R = R2
    fprintf('\n=== P2 – %s ===\n', R.nume);
    fprintf('Pas 2  a_doc = Va/ta = %.2f m/s2 (ta = %.2f s)\n', R.a_doc, R.ta_doc);
    fprintf('Pas 3  Fra = %.1f N, Ff = %.1f N, Gt = %.1f N, M*a = %.1f N  ->  Ft = %.1f N\n', ...
            R.Fra_Va, R.Ff, R.Gt, R.Ft_doc - R.Fra_Va - R.Ff - R.Gt, R.Ft_doc);
    if R.aderenta_ok, s = 'DA'; else, s = 'NU'; end
    fprintf('Pas 4  Fa = %.1f N; Ft <= Fa: %s', R.Fa, s);
    if ~R.aderenta_ok
        fprintf('  ->  Ft = Fa, a = %.2f m/s2, ta = %.2f s', R.a, R.ta);
    end
    fprintf('\n');
    fprintf('Pas 5  Mr = %.1f Nm, Omega_r = %.2f rad/s, Pr = %.1f kW, Pp = %.2f kW, Pax = %.1f kW\n', ...
            R.Mr, R.Omega_r_Va, R.Pr/1e3, R.Pp/1e3, R.Pax/1e3);
    fprintf('Pas 6  n_max = %d rot/min la v_max -> i_rd = %.4f (1:%.2f); n_ax(Va) = %.0f rot/min; Max = %.1f Nm\n', ...
            C.n_max, R.i_rd, R.k_rd, R.n_ax_Va, R.Max);
    fprintf('Pas 7  v_max = %.2f m/s: Fra = %.1f N, Ft = %.1f N\n', R.vmax, R.Fra_vmax, R.Ft_vmax);
    if R.aderenta_vmax_ok, s = 'DA'; else, s = 'NU'; end
    fprintf('Pas 8  Ft <= Fa la v_max: %s; Pr = %.1f kW, Pax = %.1f kW, Max(v_max) = %.1f Nm\n', ...
            s, R.Pr_vmax/1e3, R.Pax_nom/1e3, R.Max_vmax);
    fprintf('Pas 9  P_max = %.1f kW (pas 5),  P_nom = %.1f kW (pas 8)\n', R.P_max/1e3, R.P_nom/1e3);
    fprintf('Coerență: cu a_doc fără limita de aderență Pax = %.1f kW; documentare: %.1f kW\n', ...
            R.Pax_fara_aderenta/1e3, R.P_doc/1e3);
end

%% 3. Sensibilitate la coeficientul de aderență și la densitatea aerului (vehicul mediu)
fprintf('\n=== P2 – sensibilitate (vehicul mediu) ===\n');
fprintf('%6s %8s %10s %10s %10s %10s\n', 'mu_a', 'rho', 'a [m/s2]', 'ta [s]', 'Pmax [kW]', 'Pnom [kW]');
for mu = [0.8 1.0 1.2]
    for rho = [1.293 1.225]
        Cs = C; Cs.mu_a = mu; Cs.rho = rho;
        Rs = calcul_p2(D.medie, Cs);
        fprintf('%6.2f %8.3f %10.2f %10.2f %10.1f %10.1f\n', mu, rho, Rs.a, Rs.ta, Rs.P_max/1e3, Rs.P_nom/1e3);
    end
end

%% 4. Figuri
if GRAFICE
    v = linspace(0, D.medie.vmax, 300);
    Rm = R2(1);
    F_acc = forte_rezistente(v, Rm.a, D.medie, C);
    F_cst = forte_rezistente(v, 0, D.medie, C);
    figure('Name', 'P2 – forțe');
    plot(v*3.6, F_acc.Ft/1e3, v*3.6, F_cst.Ft/1e3, [0 v(end)*3.6], [1 1]*F_acc.Fa/1e3, '--');
    grid on; xlabel('v [km/h]'); ylabel('F [kN]');
    legend('F_t cu accelerația a', 'F_t la viteză constantă', 'F_a (aderență)', 'Location', 'best');
    title('P2 – forța de tracțiune necesară, vehicul mediu');
    figure('Name', 'P2 – putere');
    plot(v*3.6, F_acc.Ft.*v/(1-C.pp)/1e3, v*3.6, F_cst.Ft.*v/(1-C.pp)/1e3);
    grid on; xlabel('v [km/h]'); ylabel('P_{ax} [kW]');
    legend('cu accelerația a', 'la viteză constantă', 'Location', 'best');
    title('P2 – puterea la axul mașinii electrice, vehicul mediu');
end
