function C = dimensionare_incarcator(S)
%DIMENSIONARE_INCARCATOR Încărcătorul: redresor trifazat cu PFC (U_dc_PFC) + convertor coborâtor cu reglare
%   de curent prin histerezis (ca în exemplul din suportul P5-P6) și încărcare CC-CV.
%     coborâtor: U_bat = D * U_dc_PFC;  cu banda de histerezis h:  f = U_dc_PFC * D * (1 - D) / (h * L)
%     => L = U_dc_PFC * max(D(1-D)) / (h * f_s_max),   h = ondulatie_I_rel * I_CC
%   Bateria (model liniar, ca în exemplul de curs): OCV(SOC) = U_0 + (U_CV - U_0) * SOC, cu
%   U_0 = Ns * OCV_celulă(SOC = 0) ales astfel încât tensiunea medie = tensiunea nominală;
%   capacitatea echivalentă C_eq = Q / (U_CV - U_0), rezistența internă R_bat = Ns * R_celulă / Np.

B = S.B;  cel = S.cel;  ic = S.cv.incarcator;
C.P_AC = ic.P_AC_W;  C.U_AC = ic.U_AC_V;  C.U_dc = ic.U_dc_PFC_V;
C.U_dc_min_PFC = sqrt(2) * C.U_AC;                % tensiunea de vârf între faze (PFC ridicător)
C.ok_U_PFC = C.U_dc > C.U_dc_min_PFC && C.U_dc > B.U_max;
C.P_bat = C.P_AC * ic.eta_PFC * ic.eta_buck;      % puterea care ajunge în baterie
C.U_CV = B.Ns * cel.U_max;                        % tensiunea de încărcare (4,2 V/celulă)
C.I_CC = C.P_bat / C.U_CV;                        % curentul constant: puterea nu depășește P_bat
C.C_rate = C.I_CC / B.Cap_Ah;
C.I_cel_CC = C.I_CC / B.Np;
C.I_taiere = ic.I_taiere_celula_A * B.Np;
% coborâtorul
C.D_min = B.U_min / C.U_dc;  C.D_max = C.U_CV / C.U_dc;
Dc = min(max(0.5, C.D_min), C.D_max);
C.h = ic.ondulatie_I_rel * C.I_CC;               % banda de histerezis = ondulația curentului
C.L = C.U_dc * Dc * (1 - Dc) / (C.h * ic.f_s_max_Hz);
C.f_la_U_nom = C.U_dc * (B.U_nom / C.U_dc) * (1 - B.U_nom / C.U_dc) / (C.h * C.L);
% bateria
C.R_bat = B.Ns * cel.R_dc_mOhm * 1e-3 / B.Np;
C.Q = B.Cap_Ah * 3600;                            % [As]
C.U_0 = B.Ns * ic.OCV_celula_SOC0_V;
C.C_eq = C.Q / (C.U_CV - C.U_0);                  % [F]
C.tau_CV = C.R_bat * C.C_eq;                      % constanta de timp a fazei CV
% timpi (analitic)
C.SOC0 = ic.SOC_initial;
C.SOC_CC = (C.U_CV - C.R_bat * C.I_CC - C.U_0) / (C.U_CV - C.U_0);
C.t_CC = (C.SOC_CC - C.SOC0) * C.Q / C.I_CC;
C.t_CV = C.tau_CV * log(C.I_CC / C.I_taiere);
C.t_total = C.t_CC + C.t_CV;
end
