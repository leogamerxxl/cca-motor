function M = identificare_mcc(mot, ip)
%IDENTIFICARE_MCC Parametrii modelului de tip MCC (curs C3) pentru UN motor YM720.
%   Mașina sincronă cu magneți permanenți comandată vectorial se descrie cu ecuațiile MCC:
%     U = E + Ra*I + dUp,  E = k*phi*Omega,  T_E = k*phi*I  (k = kE = kM în unități S.I.)
%   phi = 1 până la viteza de bază; peste ea fluxul se slăbește (la PMSM prin curentul de axă d).
%   Pierderile urmează diagrama de puteri din C3:
%     P1 = U*I,  Pa = Ra*I^2,  Pp = dUp*I,  Pem = E*I = T_E*Omega,
%     PFe = KH*Omega + KF*Omega^2,  Pfv = Tm0*Omega + Fm*Omega^2,  P2 = Pem - PFe - Pfv = T_ax*Omega
%   iar ca pierderi de cuplu:  T_ax = T_E - Tf0 - Fv*Omega,  Tf0 = KH + Tm0,  Fv = KF + Fm.
%   Coeficienții se determină din punctul nominal (date de catalog + randamentul ales) și din
%   punctul de turație maximă (rapoartele PFe(n_max)/PFe(n_n) și Pfv(n_max)/Pfv(n_n)).

M.U_n   = ip.U_n_V;
M.dU_p  = ip.dU_p_V;
M.P_n   = mot.P_n_kW * 1e3;
M.M_n   = mot.M_n_Nm;
M.P_max = mot.P_max_kW * 1e3;
M.M_max = mot.M_max_Nm;
M.W_n   = M.P_n / M.M_n;                      % [rad/s] viteza nominală (P_n = M_n*W_n)
M.n_n   = M.W_n * 60 / (2*pi);                % [rot/min]
M.n_max = mot.n_max_rpm;
M.W_max = M.n_max * 2*pi / 60;

% --- punctul nominal: puteri și curent ---
M.eta_n = ip.eta_n;
M.P1_n  = M.P_n / M.eta_n;                    % puterea electrică absorbită
M.SP_n  = M.P1_n - M.P_n;                     % pierderi totale
M.I_n   = M.P1_n / M.U_n;                     % curentul nominal (echivalent de curent continuu)
M.P_a_n = ip.cota_Cu * M.SP_n;                % pierderi în înfășurări
M.R_a   = M.P_a_n / M.I_n^2;
M.P_p_n = M.dU_p * M.I_n;                     % „pierderi la perii” (0 la PMSM)
M.P_Fe_n = ip.cota_Fe * M.SP_n;               % pierderi în fier la W_n
M.P_fv_n = M.SP_n - M.P_a_n - M.P_p_n - M.P_Fe_n;   % pierderi mecanice și de ventilație la W_n

% --- pierderile în fier: două puncte (nominal și turație maximă) ---
M.P_Fe_max = ip.raport_Fe_max * M.P_Fe_n;
A = [M.W_n M.W_n^2; M.W_max M.W_max^2];
x = A \ [M.P_Fe_n; M.P_Fe_max];
M.K_H = x(1);  M.K_F = x(2);
% --- pierderile mecanice: aceleași două puncte ---
M.P_fv_max = ip.raport_mec_max * M.P_fv_n;
x = A \ [M.P_fv_n; M.P_fv_max];
M.T_m0 = x(1);  M.F_m = x(2);
% --- pierderile de cuplu (C3, VII) ---
M.T_f0 = M.K_H + M.T_m0;
M.F_v  = M.K_F + M.F_m;

% --- constanta mașinii din punctul nominal ---
M.E_n = M.U_n - M.R_a * M.I_n - M.dU_p;
M.k   = M.E_n / M.W_n;                        % [V*s/rad] = [Nm/A]
M.T_ax_n_verif = M.k * M.I_n - M.T_f0 - M.F_v * M.W_n;   % trebuie să fie egal cu M_n

% --- viteza de bază la cuplul maxim (începutul slăbirii de câmp) ---
M.W_b = M.W_n;
for it = 1:100
    I = (M.M_max + M.T_f0 + M.F_v * M.W_b) / M.k;
    M.W_b = (M.U_n - M.R_a * I - M.dU_p) / M.k;
end
M.I_max = (M.M_max + M.T_f0 + M.F_v * M.W_b) / M.k;
M.n_b   = M.W_b * 60 / (2*pi);
M.P_b   = M.M_max * M.W_b;                    % puterea la cuplul maxim și viteza de bază

% --- pornirea (C3, IV): la tensiunea nominală și la tensiunea care limitează curentul la I_max ---
M.I_p_Un = (M.U_n - M.dU_p) / M.R_a;          % curentul de pornire la U_n
M.M_p_Un = M.k * M.I_p_Un;                    % cuplul de pornire la U_n
M.U_p    = M.R_a * M.I_max + M.dU_p;          % tensiunea de pornire pentru I_ap = I_max

% --- parametri dinamici ---
M.tau_a   = ip.tau_a_s;                       % constanta de timp electrică L/R a mașinii reale (YASA)
M.L_a     = M.tau_a * M.R_a;                  % se păstrează tau la trecerea PMSM -> MCC echivalent
M.J_rotor = ip.J_rotor_kgm2;
M.masa    = mot.masa_kg;
M.c       = ip.c_J_kgK;
end
