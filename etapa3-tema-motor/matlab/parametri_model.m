function P = parametri_model(S, M, T, scenariu)
%PARAMETRI_MODEL Parametrii modelului dinamic al unui motor pentru un scenariu de simulare.
%   Fiecare dintre cele N motoare antrenează 1/N din vehicul (inerție și rezistențe la înaintare
%   raportate la ax prin reductor):
%     J = J_rotor + M_veh*r^2 / (N*k_rd^2)
%     T_sarcina = a0 + a2*W^2,  a0 = Ff*r/(N*k_rd*eta_rd),  a2 = 1/2*rho*S*Cx*(r/k_rd)^2*r/(N*k_rd*eta_rd)
%   scenariu: 'gol' (fără vehicul) sau 'vehicul'.

C2 = S.C2;  V = S.V;  N = T.N;  k_rd = T.k_rd;  r = C2.r;
P.R = M.R_a;  P.L = M.L_a;  P.k = M.k;  P.dUp = M.dU_p;
P.Tf0 = M.T_f0;  P.Fv = M.F_v;  P.W_b = M.W_b;  P.U_n = M.U_n;
P.U_min = 0;                 % tensiunea minimă dată de regulatorul de curent (0: un singur sens)
switch scenariu
    case 'gol'
        P.J = M.J_rotor;  P.a0 = 0;  P.a2 = 0;
    case 'vehicul'
        P.J  = M.J_rotor + V.M * r^2 / (N * k_rd^2);
        Ff   = C2.mu_f * V.M * C2.g * cos(C2.alpha);
        P.a0 = Ff * r / (N * k_rd * T.eta_rd);
        P.a2 = 0.5 * C2.rho * V.S * V.Cx * (r / k_rd)^2 * r / (N * k_rd * T.eta_rd);
    otherwise
        error('scenariu necunoscut: %s', scenariu);
end
P.slabire = true;            % slăbire de câmp ideală peste W_b: phi = min(1, W_b/W)
end
