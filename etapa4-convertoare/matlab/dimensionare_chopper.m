function H = dimensionare_chopper(S)
%DIMENSIONARE_CHOPPER Chopperul în 4 cadrane (punte H) – echivalentul de curent continuu al invertorului
%   care alimentează un motor (P5-P6).  Modulație unipolară: tensiunea la bornele motorului comută între
%   0 și ±U_dc cu frecvența 2*f_pwm, factorul de umplere m = U/U_dc:
%     dI = U_dc * m * (1 - m) / (2 * L_a * f_pwm),   maxim pentru m = 0,5:  dI_max = U_dc / (8 * L_a * f_pwm)
%   ondulația cuplului: dT = k * dI

M = S.M;  cv = S.cv.chopper;
H.U_dc = S.T.U_conv;
H.f_pwm = cv.f_pwm_Hz;
H.L_a = M.L_a;
H.dI_max = H.U_dc / (8 * H.L_a * H.f_pwm);
H.dT_max = M.k * H.dI_max;
H.I_max = M.I_max;
H.I_varf = M.I_max + H.dI_max / 2;
H.dI_max_rel = H.dI_max / M.I_max;
% în punctele caracteristice (U și I din diagrama de puteri)
W = [M.W_n, min(M.W_b, M.P_max / M.M_max), S.T.n_m_Va * 2*pi / 60];
Tq = [M.M_n, M.M_max, S.T.P_nec_max / (S.T.N * W(3))];
L = punct_functionare(M, W, Tq);
H.m = L.U / H.U_dc;
H.dI = H.U_dc .* H.m .* (1 - H.m) / (2 * H.L_a * H.f_pwm);
H.I = L.I;
end
