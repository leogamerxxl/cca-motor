%% CCA – Curs C3, exercițiul 2 și P4: simularea mașinii (model MCC) și simularea pe ansamblu
% Rulare: din folderul matlab/, comanda  main_simulare
% Toate scenariile folosesc același integrator Runge-Kutta 4 cu pas fix (rk4.m); modelul Simulink
% echivalent se construiește cu  construieste_model_simulink('D')  (sau 'A').

if exist('GRAFICE', 'var'), grafice = GRAFICE; else, grafice = true; end
S = incarca_date();
M = identificare_mcc(S.mot, S.ip);
T = tema_proiect(S, M);
rpm = 60 / (2*pi);
P = parametri_model(S, M, T, 'vehicul');

fprintf('\n=== Modelul dinamic al unui motor (1/%d din vehicul) ===\n', T.N);
fprintf('J = J_rotor + M*r^2/(N*k_rd^2) = %.4g + %.4g = %.4g kg*m2\n', M.J_rotor, P.J - M.J_rotor, P.J);
fprintf('T_sarcina = a0 + a2*W^2: a0 = %.3f Nm, a2 = %.4e Nm*s2/rad2\n', P.a0, P.a2);
fprintf('Constanta de timp electrică tau_a = %.3g s, electromecanică tau_m = J*R_a/k^2 = %.3g s\n', ...
        M.tau_a, P.J * M.R_a / M.k^2);

sim_p = S.ip.simulare;
tic;
Z = simulari(S, M, T);
C = simulare_ansamblu(S, M, T);
durata = toc;

fprintf('\n=== A: pornire în gol la U_p = %.2f V, treaptă de sarcină %.0f Nm la %.0f ms ===\n', M.U_p, ...
        sim_p.A_M_treapta, sim_p.A_t_treapta * 1e3);
fprintf('I de vârf = %.1f A (I_max = %.1f A); în gol W = %.3f rad/s (teoretic %.3f rad/s)\n', ...
        Z.A.I_varf, M.I_max, Z.A.W_gol, Z.A.W_gol_teoretic);
fprintf('cu sarcină: W = %.3f rad/s, I = %.1f A (teoretic %.3f rad/s, %.1f A)\n', Z.A.W_final, Z.A.I_final, ...
        Z.A.W_sarcina_teoretic, Z.A.I_sarcina_teoretic);

fprintf('\n=== B: accelerare cu regulator de curent (f_c = %d Hz) și slăbire de câmp ===\n', S.ip.simulare.B_fc_Hz);
fprintf('cuplul cerut pe motor = min(aderență %.1f Nm, M_max %.0f Nm, P_max/W)\n', Z.B.T_ad, M.M_max);
fprintf('0–100 km/h: %.2f s (P2: %.2f s), 0–200 km/h: %.2f s, v_max %.1f km/h atinsă: %s în %.1f s; I de vârf %.1f A\n', ...
        Z.B.t_100, S.R2.ta, Z.B.t_200, S.R2.vmax*3.6, mat2str(Z.B.atins_vmax), Z.B.t_vmax, Z.B.I_varf);

fprintf('\n=== D: rampă de tensiune %g V/s până la U_n, sarcina vehiculului (scenariul Simulink) ===\n', sim_p.D_panta);
fprintf('I de vârf = %.1f A, turația finală = %.0f rot/min (n_max = %d) după %g s\n', ...
        Z.D.I_varf, Z.D.W_final * rpm, M.n_max, sim_p.D_t_end);

fprintf('\n=== C: simulare pe ansamblu – ciclul P3 scurtat (0 -> %.0f km/h în %.2f s, palier %g s, frânare %.2f s) ===\n', ...
        C.V1*3.6, C.t1, sim_p.C_t_palier, C.t1);
fprintf('Regulator de viteză PI: Kp = %.1f Nm*s/rad, Ki = %.1f Nm/rad (poli dubli la -%g rad/s)\n', ...
        C.Kp_w, C.Ki_w, sim_p.C_wn_viteza);
fprintf('Eroarea maximă de urmărire a vitezei: %.3f km/h\n', C.eroare_v_max * 3.6);
fprintf('Baterie: R_bat = %.4f Ohm, U_0 = %.0f V; I_bat = %.0f … %.0f A; U_bat min = %.0f V; I celulă max = %.1f A\n', ...
        C.R_bat, C.U_0, C.I_bat_min, C.I_bat_max, C.U_bat_min, C.I_celula_max);
fprintf('DC-DC: D max = %.3f; eta_invertor = %.2f, eta_DC-DC = %.2f (ipoteze)\n', C.D_max, S.ip.eta_invertor, S.ip.eta_dcdc);
fprintf('%-10s %12s %12s %12s %12s %10s\n', 'Faza', 'E_ax [kJ]', 'E_el [kJ]', 'E_dc [kJ]', 'E_bat [kJ]', 'eta lanț');
ff = {'acc', 'palier', 'franare'};  eta_f = [C.eta_acc, C.eta_pal, C.eta_rec];
for q = 1:3
    E = C.E.(ff{q});
    fprintf('%-10s %12.1f %12.1f %12.1f %12.1f %10.3f\n', ff{q}, E.ax/1e3, E.el/1e3, E.dc/1e3, E.bat/1e3, eta_f(q));
end
fprintf('Energia din baterie pe ciclu: %.1f kJ (P3 cu eta = %.1f: %.1f kJ); dSOC = %.4f %%\n', ...
        C.E.total_bat/1e3, S.C2.eta, C.P3.W_stocata/1e3, C.dSOC_pct);
fprintf('(durata simulărilor: %.1f s)\n', durata);

if grafice
    figure('Name', 'Simulare A – pornire în gol');
    subplot(2, 1, 1); plot(Z.A.t, Z.A.I); grid on; ylabel('I [A]');
    subplot(2, 1, 2); plot(Z.A.t, Z.A.W * rpm); grid on; ylabel('n [rot/min]'); xlabel('t [s]');
    figure('Name', 'Simulare B – accelerare');
    subplot(3, 1, 1); plot(Z.B.t, Z.B.v * 3.6); grid on; ylabel('v [km/h]');
    subplot(3, 1, 2); plot(Z.B.t, Z.B.I, Z.B.t, Z.B.U); grid on; legend('I [A]', 'U [V]');
    subplot(3, 1, 3); plot(Z.B.t, Z.B.T_ax, Z.B.t, 100 * Z.B.phi); grid on; legend('T_{ax} [Nm]', '\phi [%]'); xlabel('t [s]');
    figure('Name', 'Simulare D – rampă de tensiune');
    subplot(2, 1, 1); plot(Z.D.t, Z.D.U, Z.D.t, Z.D.I); grid on; legend('U [V]', 'I [A]');
    subplot(2, 1, 2); plot(Z.D.t, Z.D.W * rpm); grid on; ylabel('n [rot/min]'); xlabel('t [s]');
    figure('Name', 'Simulare C – ansamblu');
    subplot(3, 1, 1); plot(C.t, C.v_ref * 3.6, '--', C.t, C.v * 3.6); grid on; ylabel('v [km/h]'); legend('referință', 'vehicul');
    subplot(3, 1, 2); plot(C.t, C.P_ax / 1e3, C.t, C.P_bat / 1e3); grid on; legend('P_{ax} [kW]', 'P_{bat} [kW]');
    subplot(3, 1, 3); plot(C.t, C.I_bat, C.t, C.U_bat); grid on; legend('I_{bat} [A]', 'U_{bat} [V]'); xlabel('t [s]');
end
