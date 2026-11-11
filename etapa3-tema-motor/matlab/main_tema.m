%% CCA – Proiect P4: tema de proiect (slide 3) cu verificările „confirmare MCC / reductor / baterie”
% Rulare: din folderul matlab/, comanda  main_tema
% Datele vehiculului mediu și bateria vin din etapa 2 (../../etapa2-calcule/matlab).

S = incarca_date();
M = identificare_mcc(S.mot, S.ip);
T = tema_proiect(S, M);
da = {'NU', 'DA'};
rpm = 60 / (2*pi);

fprintf('\n=== P4 – Tema de proiect (vehiculul mediu, %d vehicule de serie) ===\n', S.D.n);
fprintf('Să se proiecteze un sistem de propulsie cu acționare electrică care să aibă:\n');
fprintf('\n1. ME: %d × %s (%s), dispunere %s\n', T.N, S.mot.nume, S.mot.tip, S.mot.dispunere);
fprintf('   %-8s %12s %12s   %s\n', 'Mărime', 'pe motor', 'total', 'Observații');
fprintf('   %-8s %9.1f kW %9.1f kW   catalog\n', 'P_n', M.P_n/1e3, T.N*M.P_n/1e3);
fprintf('   %-8s %10.0f V %12s   tensiunea circuitului intermediar (DC-DC)\n', 'U_n', M.U_n, '');
fprintf('   %-8s %10.1f A %10.1f A   echivalent MCC: P_n/(eta_n*U_n), eta_n = %.3f\n', 'I_n', M.I_n, T.N*M.I_n, M.eta_n);
fprintf('   %-8s %6.0f rot/min %10s   n_n = P_n/M_n; n_max = %d rot/min\n', 'n', M.n_n, '', M.n_max);
fprintf('   %-8s %9.1f Nm %9.1f Nm   catalog\n', 'M_n', M.M_n, T.N*M.M_n);
fprintf('   %-8s %9.1f kW %9.1f kW   catalog (vârf %d s)\n', 'P_max', M.P_max/1e3, T.N*M.P_max/1e3, S.mot.durata_varf_s);
fprintf('   %-8s %10.1f A %10.1f A   echivalent MCC la M_max și viteza de bază\n', 'I_max', M.I_max, T.N*M.I_max);
fprintf('   %-8s %9.1f Nm %9.1f Nm   catalog; viteza de bază n_b = %.0f rot/min\n', 'M_max', M.M_max, T.N*M.M_max, M.n_b);

fprintf('   Cerut pe motor: P_max %.1f kW la %.0f rot/min (%.1f Nm, %.1f A); P_n %.1f kW la %.0f rot/min (%.1f Nm, %.1f A)\n', ...
        T.Pm_max_nec/1e3, T.nm_max_nec, T.Mm_max_nec, T.Im_max_nec, T.Pm_n_nec/1e3, T.n_m_vmax, T.Mm_n_nec, T.Im_n_nec);
fprintf('   Limita de putere a sistemului (baterie, DC-DC): %.1f kW pe motor (P_max din P2 / %d)\n', T.P_lim_motor/1e3, T.N);

fprintf('\n2. Reductor: i_rd = Omega_r/Omega_ax = %.4f (1:%.2f), eta_rd = %.2f (ales liber)\n', T.i_rd, T.k_rd, T.eta_rd);
fprintf('   n motor la v_max = %.0f rot/min, la 100 km/h = %.0f rot/min\n', T.n_m_vmax, T.n_m_Va);

fprintf('\n3. Baterie: W_bat necesar = %.2f kWh (P3), instalat = %.2f kWh (%ds%dp, %s)\n', ...
        T.W_bat_nec/3.6e6, T.W_bat_inst/3.6e6, S.B.Ns, S.B.Np, S.cel.nume);
fprintf('   U_bat = %.0f…%.0f V (nominal %.0f V); convertor DC-DC ridicător bidirecțional, U_conv = %.0f V\n', ...
        T.U_bat_min, T.U_bat_max, T.U_bat_nom, T.U_conv);
fprintf('   factor de umplere D = %.3f…%.3f; I_bat la P_max și U_min = %.0f A\n', T.D_min, T.D_max, T.I_bat_max);

fprintf('\nVehiculul propulsat (la roți):\n');
fprintf('   P_rn  = %8.1f kW   n_rn  = %6.0f rot/min   M_rn  = %7.1f Nm   (rulare continuă cu v_max = %.1f km/h)\n', ...
        T.P_rn/1e3, T.n_rn, T.M_rn, S.R2.vmax*3.6);
fprintf('   P_rmax = %7.1f kW   n_rmax = %5.0f rot/min   M_rmax = %6.1f Nm   (accelerare la limita de aderență)\n', ...
        T.P_rmax/1e3, T.n_rmax, T.M_rmax);

fprintf('\n=== Confirmări ===\n');
fprintf('MCC:      N*P_max = %.0f kW >= P_max necesar %.1f kW: %s\n', T.N*M.P_max/1e3, T.P_nec_max/1e3, da{T.ok_P_max+1});
fprintf('          N*P_n   = %.0f kW >= P_n necesar   %.1f kW: %s\n', T.N*M.P_n/1e3, T.P_nec_n/1e3, da{T.ok_P_n+1});
fprintf('          M_max = %.0f Nm >= M față %.1f Nm (f_față = %.3f): %s; >= M spate %.1f Nm/motor: %s\n', ...
        M.M_max, T.M_nec_fata, T.f_fata, da{T.ok_M_fata+1}, T.M_nec_spate, da{T.ok_M_spate+1});
fprintf('          tensiunea U_conv = %.0f V în domeniul motorului %d…%d V: %s\n', T.U_conv, S.mot.U_dc_min_V, S.mot.U_dc_max_V, da{T.ok_U+1});
fprintf('Reductor: n_max motor %d >= n la v_max %.0f rot/min: %s\n', M.n_max, T.n_m_vmax, da{T.ok_n_max+1});
fprintf('          N*M_max*k_rd*eta_rd = %.0f Nm >= M_rmax = %.0f Nm: %s\n', T.M_roti_disp, T.M_rmax, da{T.ok_M_roti+1});
fprintf('Frânare:  decelerare %.2f m/s2 (P3), f_față = %.3f: recuperabil %.1f kN (față %.1f, spate %.1f) din %.1f kN necesari: %s\n', ...
        T.a_fr, T.f_fata_fr, T.F_rec_max/1e3, T.F_fata_fr/1e3, T.F_spate_fr/1e3, T.F_fr_nec/1e3, da{T.ok_frana+1});
fprintf('          -> %.1f %% electric (T_rec = %.1f Nm/motor), restul cu frâna mecanică\n', 100 * T.cota_rec, T.T_rec_max);
fprintf('Baterie:  W instalat %.2f >= W necesar %.2f kWh: %s\n', T.W_bat_inst/3.6e6, T.W_bat_nec/3.6e6, da{T.ok_W_bat+1});
fprintf('          I celulă la P_max și U_min = %.1f A <= %d A: %s\n', S.B.I_celula, S.cel.I_max_cont, da{T.ok_I_cel+1});
fprintf('          P mecanică disponibilă %.0f kW >= P_max %.1f kW: %s\n', T.P_mec_disp/1e3, T.P_nec_max/1e3, da{T.ok_P_bat+1});
fprintf('(Puterea maximă a vehiculului este limitată de aderență – P2; motoarele au rezervă de putere.)\n');
