%% CCA – Proiect P5-P6: convertoarele DC-DC (ridicător, coborâtor, bidirecțional) și încărcarea bateriei
% Rulare: din folderul matlab/, comanda  main_p5p6
% Calcul și simulare pentru fiecare bloc din schema bloc (suport P4/P5-P6, slide 2):
%   - convertorul DC-DC bidirecțional baterie <-> circuitul intermediar U_conv (tracțiune / frânare recuperativă)
%   - chopperul în 4 cadrane (echivalentul MCC al invertorului) care alimentează fiecare motor
%   - încărcătorul AC-DC (PFC + coborâtor cu reglare de curent prin histerezis, CC-CV)

if exist('GRAFICE', 'var'), grafice = GRAFICE; else, grafice = true; end
S  = incarca_date4();
D  = dimensionare_dcdc(S);
H  = dimensionare_chopper(S);
Ci = dimensionare_incarcator(S);
cv = S.cv;  da = {'NU', 'DA'};

%% 1. Convertorul DC-DC bidirecțional
fprintf('\n=== P5-P6 – Convertorul DC-DC bidirecțional (%d faze intercalate, f_s = %.0f kHz) ===\n', D.N_faze, D.f_s/1e3);
fprintf('Punctul de putere maximă: 3 motoare × %.1f Nm la %.0f rot/min, eta motor = %.2f %%\n', ...
        D.T_motor_Pmax, S.T.n_m_Va, 100 * D.eta_motor_Pmax);
fprintf('P în circuitul intermediar = %.1f kW (eta invertor %.3f), P baterie = %.1f kW (eta DC-DC %.3f)\n', ...
        D.P_dc_max/1e3, cv.dcdc.eta_invertor, D.P_bat_max/1e3, cv.dcdc.eta_dcdc_ipoteza);
fprintf('Ridicător: U_dc = %.0f V, U_bat = %.0f…%.0f V -> D = %.4f…%.4f (nominal %.3f)\n', D.U_dc, ...
        D.U_bat_min, D.U_bat_max, D.D_min, D.D_max, D.D_nom);
fprintf('  peste %.0f %% din U_dc (U_bat > %.0f V) se trece în regim „trecere directă” (tranzistorul superior închis)\n', ...
        100 * cv.dcdc.U_trecere_rel, cv.dcdc.U_trecere_rel * D.U_dc);
fprintf('Coborâtor (recuperare): D_c = U_bat/U_dc = %.3f…%.4f\n', D.Dc_min, D.Dc_max);
fprintf('Curenți: I_bat max = %.0f A (U_bat = %.0f V), pe fază %.1f A, vârf %.1f A; I circuit intermediar %.0f A\n', ...
        D.I_bat_max, D.U_bat_min, D.I_faza_max, D.I_varf_faza, D.I_dc_max);
fprintf('Bobina pe fază: dI = %.0f %% × I_faza = %.1f A -> L = %.1f µH (W_L = %.2f J)\n', ...
        100 * cv.dcdc.ondulatie_I_rel, D.dI, D.L * 1e6, D.W_L);
fprintf('Condensator: dU = %.0f V -> C >= %.0f µF = %d × %s\n', D.dU, D.C * 1e6, ...
        ceil(D.C * 1e6 / cv.dcdc.condensator.C_uF), cv.dcdc.condensator.nume);
fprintf('Modul: %s; U: %s, I_vârf <= %.0f %% × I_D (%d A): %s\n', D.modul, da{D.ok_U_modul + 1}, ...
        100 * cv.dcdc.rezerva_curent, cv.dcdc.modul.I_D_A, da{D.ok_I_modul + 1});
fprintf('Pierderi la P_max: conducție %.0f W + comutație %.0f W pe fază -> total %.2f kW, eta = %.2f %%\n', ...
        D.P_cond_faza, D.P_com_faza, D.P_pierderi/1e3, 100 * D.eta_calc);

%% 2. Chopperul (invertorul) pe motor
fprintf('\n=== Chopper în 4 cadrane (invertorul echivalent), f_pwm = %.0f kHz, modulație unipolară ===\n', H.f_pwm/1e3);
fprintf('L_a = %.0f µH: ondulația maximă a curentului dI = U_dc/(8 L_a f) = %.1f A (%.1f %% din I_max), dT = %.1f Nm\n', ...
        H.L_a * 1e6, H.dI_max, 100 * H.dI_max_rel, H.dT_max);
fprintf('În punctele nominal / cuplu maxim / P_max la 100 km/h: m = %.3f / %.3f / %.3f, dI = %.1f / %.1f / %.1f A\n', H.m, H.dI);

%% 3. Încărcătorul
fprintf('\n=== Încărcătorul (%.0f kW AC, 3 × %.0f V) ===\n', Ci.P_AC/1e3, Ci.U_AC);
fprintf('PFC: U_dc = %.0f V (> %.0f V vârf de linie și > U_CV = %.0f V: %s); P baterie = %.2f kW\n', Ci.U_dc, ...
        Ci.U_dc_min_PFC, Ci.U_CV, da{Ci.ok_U_PFC + 1}, Ci.P_bat/1e3);
fprintf('CC: I = %.2f A (%.3fC, %.3f A/celulă); CV: %.0f V; tăiere la %.2f A\n', Ci.I_CC, Ci.C_rate, Ci.I_cel_CC, ...
        Ci.U_CV, Ci.I_taiere);
fprintf('Coborâtor: D = %.3f…%.3f; histerezis h = %.2f A -> L = %.0f µH (f <= %.0f kHz)\n', Ci.D_min, Ci.D_max, Ci.h, ...
        Ci.L * 1e6, cv.incarcator.f_s_max_Hz/1e3);
fprintf('Baterie: R = %.4f Ohm, OCV liniar %.0f…%.0f V (medie %.0f V = U_nom), C_eq = %.0f F, tau_CV = %.0f s\n', ...
        Ci.R_bat, Ci.U_0, Ci.U_CV, (Ci.U_0 + Ci.U_CV)/2, Ci.C_eq, Ci.tau_CV);
fprintf('Timpi (analitic) de la SOC = %.0f %%: CC %.2f h (până la SOC = %.1f %%), CV %.1f min, total %.2f h\n', ...
        100 * Ci.SOC0, Ci.t_CC/3600, 100 * Ci.SOC_CC, Ci.t_CV/60, Ci.t_total/3600);

%% 4. Simulări
sim = cv.simulare;
tic;
Im = sim_incarcare_medie(Ci, cv.incarcator.dt_medie_s);
Ic = sim_incarcare_comutatie(Ci, sim.incarcare);
Dc = sim_dcdc_comutatie(D, sim.dcdc);
durata = toc;
fprintf('\n=== Simulare: încărcarea completă (model mediu, pas %g s) ===\n', cv.incarcator.dt_medie_s);
fprintf('t_CC = %.2f h (analitic %.2f h), total %.2f h (analitic %.2f h), SOC final %.2f %%\n', Im.t_CC/3600, ...
        Ci.t_CC/3600, Im.t_total/3600, Ci.t_total/3600, 100 * Im.SOC_final);
fprintf('Energie: din rețea %.2f kWh, în baterie %.2f kWh, stocată %.2f kWh, pierderi în R_bat %.3f kWh\n', ...
        Im.E_AC/3.6e6, Im.E_bat/3.6e6, Im.E_stocata/3.6e6, Im.E_pierderi_bat/3.6e6);
fprintf('\n=== Simulare: încărcătorul cu comutație (histerezis + PI tensiune), timp scalat × 1/%d ===\n', sim.incarcare.k_timp);
fprintf('trecerea CC -> CV la %.2f ms (model mediu scalat: %.2f ms); I la t_CC + tau = %.2f A (model mediu %.2f A)\n', ...
        Ic.t_CC * 1e3, sim.incarcare.t_CC_s * 1e3, Ic.I_med_tau, Ic.I_med_tau_teoretic);
fprintf('frecvența de comutație în CC: %.1f kHz (teoretic %.1f kHz); U final %.2f V\n', Ic.f_CC/1e3, ...
        Ic.f_CC_teoretic/1e3, Ic.U_final);
fprintf('\n=== Simulare: DC-DC bidirecțional cu comutație (%d faze, U_bat0 = %.0f V) ===\n', D.N_faze, sim.dcdc.U_bat_V);
for nume = {'tr', 'rec'}
    X = Dc.(nume{1});
    fprintf('%-4s I_bat = %7.1f A, U_bat = %.1f V, D = %.4f (teoretic %.4f), U_dc = %.2f V\n', nume{1}, X.I_bat_med, ...
            X.U_bat_med, X.D_med, X.D_teoretic, X.U_dc_med);
    fprintf('     ondulații: faza %.1f A (formula %.1f A), baterie %.1f A, U_dc %.2f V\n', X.dI_faza, ...
            X.dI_faza_teoretic, X.dI_bat, X.dU_dc);
end
fprintf('schimbările de sarcină (pante): U_dc min = %.1f V, U_dc max = %.1f V\n', Dc.U_dc_min, Dc.U_dc_max);
fprintf('(durata simulărilor: %.1f s)\n', durata);

if grafice
    figure('Name', 'Încărcare CC-CV (model mediu)');
    subplot(3, 1, 1); plot(Im.t / 3600, Im.I); grid on; ylabel('I [A]');
    subplot(3, 1, 2); plot(Im.t / 3600, Im.U); grid on; ylabel('U_{bat} [V]');
    subplot(3, 1, 3); plot(Im.t / 3600, 100 * Im.SOC); grid on; ylabel('SOC [%]'); xlabel('t [h]');
    figure('Name', 'Încărcător cu comutație');
    subplot(2, 1, 1); plot(Ic.t * 1e3, Ic.I, Ic.t * 1e3, Ic.Iref); grid on; ylabel('I [A]'); legend('I', 'I_{ref}');
    subplot(2, 1, 2); plot(Ic.t * 1e3, Ic.U); grid on; ylabel('U_{bat} [V]'); xlabel('t [ms]');
    figure('Name', 'DC-DC bidirecțional');
    subplot(3, 1, 1); plot(Dc.t * 1e3, Dc.UDC); grid on; ylabel('U_{dc} [V]');
    subplot(3, 1, 2); plot(Dc.t * 1e3, Dc.IL); grid on; ylabel('i_L [A]');
    subplot(3, 1, 3); plot(Dc.t * 1e3, Dc.IB); grid on; ylabel('I_{bat} [A]'); xlabel('t [ms]');
end
