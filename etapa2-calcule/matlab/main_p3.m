%% CCA – Proiect P3: necesarul de energie electrică și bateria
% Rulare: din folderul matlab/, comanda  main_p3
% Folosește accelerația calculată în P2 (calcul_p2) și autonomia medie din documentare.

if ~exist('GRAFICE', 'var'), GRAFICE = true; end
C = constante();
D = date_intrare();
cel = celula_aleasa();

seturi = {D.medie, D.gt63};
for k = 1:numel(seturi)
    V  = seturi{k};
    R2 = calcul_p2(V, C);
    R3 = calcul_p3(V, C, R2);
    B  = dimensionare_baterie(R3.Wbat, cel, V, C, R2.P_max);
    P3(k) = R3; %#ok<SAGROW>
    BAT(k) = B; %#ok<SAGROW>

    fprintf('\n=== P3 – %s ===\n', R3.nume);
    fprintf('Pas 1–4  V1 = %.3f m/s, a = %.3f m/s2; Fra = %.2f N, Ff = %.2f N, M*a = %.1f N -> Ft1 = %.1f N (Fa = %.1f N)\n', ...
            R3.V1, R3.a, R3.Fra_V1, R3.Ff, V.M*R3.a, R3.Ft1, R3.Fa);
    fprintf('         P1 = Ft1*V1 = %.2f kW\n', R3.P1/1e3);
    fprintf('Pas 5    Ft1'' = %.2f N, P1'' = %.3f kW\n', R3.Ft1p, R3.P1p/1e3);
    fprintf('Pas 6    t1 = V1/a = %.4f s\n', R3.t1);
    fprintf('Pas 7    Pmed = P1/2 = %.3f kW\n', R3.Pmed/1e3);
    fprintf('         %6s %12s %14s %14s %12s %12s\n', 'n', 'dt [s]', 'P01_med [kW]', 'W01 [kJ]', 'eroare [%]', 'timp [us]');
    for q = 1:numel(R3.disc)
        d = R3.disc(q);
        fprintf('         %6d %12.3e %14.4f %14.4f %12.4f %12.2f\n', d.n, d.dt, d.P01_med/1e3, d.W01/1e3, ...
                d.eroare_W01_pct, d.timp_s*1e6);
    end
    fprintf('         valoarea exactă (integrală analitică): P01 = %.4f kW, W01 = %.4f kJ\n', ...
            R3.P01_exact/1e3, R3.W01_exact/1e3);
    fprintf('Pas 8    Wmed = %.4f kJ, W01_med = %.4f kJ, W01 = %.4f kJ\n', R3.Wmed/1e3, R3.W01_med/1e3, R3.W01/1e3);
    fprintf('Pas 9–10 d1 = df = %.3f m; autonomie = %.1f km; d2 = %.3f km; t2 - t1 = %.1f s (%.2f h)\n', ...
            R3.d1, R3.autonomie/1e3, R3.d2/1e3, R3.t12, R3.t12/3600);
    fprintf('Pas 11   W12 = P1''*(t2 - t1) = %.4g Ws = %.3f kWh\n', R3.W12, R3.W12/3.6e6);
    fprintf('Pas 12   Wmec = W01 + W12 - W2f = %.4g Ws = %.3f kWh\n', R3.Wmec, R3.Wmec/3.6e6);
    fprintf('Pas 13   Wstocata = %.4g Ws = %.3f kWh  (%.2f kWh/100 km)\n', R3.Wstocata, R3.Wstocata_kWh, R3.consum_stoc_kWh100);
    fprintf('Pas 14   Wbat = Wstocata/(1 - 0,30) = %.4g Ws = %.2f kWh  (documentare: %.1f kWh)\n', ...
            R3.Wbat, R3.Wbat_kWh, R3.W_bat_doc_kWh);

    fprintf('Baterie  celula %s: %.2f V, %.2f Ah, W_celula = %.0f Ws (%.2f Wh)\n', cel.nume, cel.U_nom, cel.Cap_Ah, ...
            B.W_celula, B.W_celula/3600);
    fprintf('         N_min = %d celule; %ds%dp = %d celule; U = %.1f V (%.1f–%.1f V); %.1f Ah; %.2f kWh instalați\n', ...
            B.N_min, B.Ns, B.Np, B.N, B.U_nom, B.U_min, B.U_max, B.Cap_Ah, B.W_real_kWh);
    fprintf('         I_bat la P_max = %.0f A -> %.1f A/celulă (max. %.0f A); Np din energie = %d, din curent = %d\n', ...
            B.I_bat_max, B.I_celula, cel.I_max_cont, B.Np_energie, B.Np_curent);
    fprintf('         masă celule = %.1f kg (%.1f %% din M), pachet estimat = %.1f kg (%.1f %%); limita 30 %% = %.1f kg\n', ...
            B.m_celule, B.procent_celule, B.m_pachet, B.procent_pachet, B.m_limita);
end

%% Figuri: P(t) pe [0, t1] pentru n = 100 și n = 1000, profilul de viteză
if GRAFICE
    R3 = P3(1);
    figure('Name', 'P3 – P(t)');
    for q = 1:numel(R3.disc)
        d = R3.disc(q);
        subplot(1, numel(R3.disc), q);
        stairs(d.t(1:end-1), d.P(2:end)/1e3); hold on;
        tt = linspace(0, R3.t1, 400);
        Fx = forte_rezistente(R3.a*tt, R3.a, D.medie, C);
        plot(tt, Fx.Ft.*R3.a.*tt/1e3, '--');
        plot([0 R3.t1], [1 1]*R3.Pmed/1e3, ':');
        grid on; xlabel('t [s]'); ylabel('P [kW]');
        title(sprintf('n = %d', d.n));
        legend('P_{ti} (constant pe interval)', 'P(t) continuu', 'P_{med} = P_1/2', 'Location', 'northwest');
    end
    figure('Name', 'P3 – ciclu');
    plot([0 R3.t1 R3.t2 R3.tf]/3600, [0 R3.V1 R3.V1 0]*3.6);
    grid on; xlabel('t [h]'); ylabel('V [km/h]');
    title(sprintf('Ciclul P3: %.0f km la %.0f km/h', R3.autonomie/1e3, R3.V1*3.6));
end
