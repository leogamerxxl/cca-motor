function [dx, y] = derivata_mcc(t, x, P)
%DERIVATA_MCC Modelul dinamic al mașinii (ecuațiile MCC din C3) cu sarcina vehiculului.
%   Stări: x = [I; W; z; zw]  (curentul, viteza unghiulară, integralele erorilor de curent și de viteză
%   pentru regulatoarele PI)
%     L*dI/dt = U - R*I - dUp*sign(I) - k*phi*W
%     T_E     = k*phi*I
%     T_ax    = T_E - Tf0*sign(W) - Fv*W                 (pierderile de cuplu, C3 VII)
%     J*dW/dt = T_ax - T_sarcina,   T_sarcina = a0*sign(W) + a2*W^2 + M_treapta*(t >= t_treapta)
%   Tensiunea U: P.mod = 'tensiune' -> U = P.U_fun(t);
%                P.mod = 'curent'   -> regulator PI de curent, I_ref = P.Iref_fun(W, phi);
%                P.mod = 'viteza'   -> regulator PI de viteză (W_ref = P.Wref_fun(t)) care dă cuplul de referință
%                                      (limitat la ±P.Tlim_fun(W); fără cuplu de frânare la W = 0),
%                                      urmat de regulatorul PI de curent.
%   Tensiunea dată de regulatorul de curent este limitată la [P.U_min, P.U_n].
%   La frânare (modul 'viteza') mașina dă cel mult P.T_rec (limitele motoarelor și ale aderenței pe punți);
%   restul cuplului de frânare cerut, T_fm <= 0, este dat de frâna mecanică:  J*dW/dt = T_ax + T_fm - T_sarcina.
%   y – mărimi de ieșire: [U, phi, T_E, T_ax, T_sarcina, I_ref, T_fm].

I = x(1);  W = x(2);  z = x(3);  zw = x(4);
if P.slabire && W > P.W_b
    phi = P.W_b / W;
else
    phi = 1;
end
dz = 0;  dzw = 0;  Iref = NaN;  T_fm = 0;
switch P.mod
    case 'tensiune'
        U = P.U_fun(t);
    case {'curent', 'viteza'}
        if strcmp(P.mod, 'curent')
            Iref = P.Iref_fun(W, phi);
        else
            ew = P.Wref_fun(t) - W;
            Tu = P.Kp_w * ew + P.Ki_w * zw;
            Tl = P.Tlim_fun(W);
            Tl_fr = Tl * (W > 0);        % vehiculul oprit nu mai este frânat electric (nu merge înapoi)
            Tref = min(max(Tu, -Tl_fr), Tl);
            if Tu == Tref || (Tu > Tl && ew < 0) || (Tu < -Tl_fr && ew > 0)
                dzw = ew;                % anti-windup pentru regulatorul de viteză
            end
            T_el = max(Tref, -P.T_rec);             % partea electrică (recuperativă) a cuplului de frânare
            T_fm = Tref - T_el;                     % restul: frâna mecanică
            Iref = (T_el + P.Tf0 * sign(W) + P.Fv * W) / (P.k * phi);   % compensarea pierderilor de cuplu
        end
        e = Iref - I;
        u = P.Kp * e + P.Ki * z;
        U = min(max(u, P.U_min), P.U_n);
        if u == U || (u > P.U_n && e < 0) || (u < P.U_min && e > 0)
            dz = e;                      % anti-windup: se integrează doar dacă ieșirea nu e saturată
        end
    otherwise
        error('mod necunoscut');
end
T_E  = P.k * phi * I;
T_ax = T_E - P.Tf0 * sign(W) - P.Fv * W;
T_s  = P.a0 * sign(W) + P.a2 * W^2 + P.M_treapta * (t >= P.t_treapta);
dI = (U - P.R * I - P.dUp * sign(I) - P.k * phi * W) / P.L;
dW = (T_ax + T_fm - T_s) / P.J;
if W <= 0 && dW < 0
    dW = 0;                          % vehiculul nu se deplasează înapoi
end
dx = [dI; dW; dz; dzw];
y  = [U, phi, T_E, T_ax, T_s, Iref, T_fm];
end
