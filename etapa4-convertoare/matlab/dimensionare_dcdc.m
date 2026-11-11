function D = dimensionare_dcdc(S)
%DIMENSIONARE_DCDC Convertorul DC-DC bidirecțional baterie <-> circuitul intermediar (P5-P6).
%   La tracțiune funcționează ca ridicător de tensiune (boost), la frânarea recuperativă ca
%   coborâtor (buck); aceeași semipunte (2 tranzistoare SiC pe fază), N faze intercalate.
%     ridicător:  U_dc = U_bat / (1 - D)         coborâtor:  U_bat = D_c * U_dc,  D_c = 1 - D
%     bobina:     dI_L = U_bat * D / (L * f_s)    (maximă pentru U_bat = U_dc/2 sau la marginea domeniului)
%     condensator: dU_dc = I_dc * D / (C * f_s)   (o fază echivalentă – estimare acoperitoare)

M = S.M;  T = S.T;  B = S.B;  cv = S.cv.dcdc;  cel = S.cel;
D.U_dc = T.U_conv;
D.U_bat_min = B.U_min;  D.U_bat_max = B.U_max;  D.U_bat_nom = B.U_nom;
D.R_bat = B.Ns * cel.R_dc_mOhm * 1e-3 / B.Np;
D.f_s = cv.f_s_Hz;  D.N_faze = cv.N_faze;

% puterea cerută în circuitul intermediar în punctul de putere maximă (100 km/h, limita de aderență)
W = T.n_m_Va * 2*pi / 60;
D.T_motor_Pmax = T.P_nec_max / (T.N * W);
L = punct_functionare(M, W, D.T_motor_Pmax);
D.eta_motor_Pmax = L.eta;
D.P1_motor_Pmax = L.P1;
D.P_dc_max = T.N * L.P1 / cv.eta_invertor;          % puterea absorbită din circuitul intermediar
D.P_bat_max = D.P_dc_max / cv.eta_dcdc_ipoteza;      % puterea cerută bateriei

% factorul de umplere
D.D_max = 1 - D.U_bat_min / D.U_dc;
D.D_min = 1 - D.U_bat_max / D.U_dc;
D.D_nom = 1 - D.U_bat_nom / D.U_dc;
D.U_trecere = cv.U_trecere_rel * D.U_dc;            % peste această tensiune: trecere directă (fără reglare)
D.D_min_regl = 1 - cv.U_trecere_rel;                % factorul de umplere minim în regim de reglare

% curenți (caz defavorabil: baterie descărcată, U_bat = U_min)
D.I_bat_max = D.P_bat_max / D.U_bat_min;
D.I_faza_max = D.I_bat_max / D.N_faze;
D.I_dc_max = D.P_dc_max / D.U_dc;

% bobina pe fază
U_crit = min(max(D.U_dc / 2, D.U_bat_min), D.U_bat_max);
D.U_bat_ondulatie_max = U_crit;
D.D_ondulatie_max = 1 - U_crit / D.U_dc;
D.dI = cv.ondulatie_I_rel * D.I_faza_max;
D.L = U_crit * D.D_ondulatie_max / (D.dI * D.f_s);
D.I_varf_faza = D.I_faza_max + D.dI / 2;
D.W_L = 0.5 * D.L * D.I_varf_faza^2;                % energia maximă în bobină

% condensatorul circuitului intermediar
D.dU = cv.ondulatie_U_rel * D.U_dc;
D.C = D.I_dc_max * D.D_max / (D.dU * D.f_s);

% verificarea modulului ales
md = cv.modul;
D.modul = md.nume;
D.ok_U_modul = md.U_DS_V >= D.U_dc / 0.8;           % tensiunea de lucru <= 80 % din U_DS
D.ok_I_modul = D.I_varf_faza <= cv.rezerva_curent * md.I_D_A;
% pierderi la puterea maximă (pe fază: conducție în tranzistorul care conduce + comutație dură)
I = D.I_faza_max;
D.I_rms_faza = sqrt(I^2 + D.dI^2 / 12);
D.P_cond_faza = md.R_DS_on_cald_mOhm * 1e-3 * D.I_rms_faza^2;
if md.E_ref_U_V > 0 && md.E_ref_I_A > 0
    D.P_com_faza = D.f_s * (md.E_on_mJ + md.E_off_mJ) * 1e-3 * (D.U_dc / md.E_ref_U_V) * (I / md.E_ref_I_A);
else
    D.P_com_faza = NaN;
end
D.P_pierderi = D.N_faze * (D.P_cond_faza + D.P_com_faza);
D.eta_calc = D.P_dc_max / (D.P_dc_max + D.P_pierderi);

% regimul coborâtor (frânare recuperativă)
D.Dc_min = D.U_bat_min / D.U_dc;
D.Dc_max = D.U_bat_max / D.U_dc;
end
