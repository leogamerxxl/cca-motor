function R = sim_dcdc_comutatie(D, sc)
%SIM_DCDC_COMUTATIE Convertorul DC-DC bidirecțional cu N faze intercalate, simulat cu comutație.
%   Fiecare fază: semipunte (tranzistor inferior s_k = 1 -> bobina la masă; superior -> bobina la U_dc),
%   comandă complementară, deci conducție continuă în ambele sensuri (tracțiune și recuperare):
%     L di_k/dt = U_bat - (1 - s_k) * u_dc,      C du_dc/dt = sum((1 - s_k) * i_k) - i_sarcina
%     U_bat = U_0 - R_bat * sum(i_k)
%   Sarcina (cele 3 invertoare): putere P(t) = 0 -> P_dc_max (tracțiune) -> -P_franare (recuperare), cu
%   pante de durată t_rampa (cuplul motoarelor nu se schimbă instantaneu), i_sarcina = P(t) / u_dc.
%   Reglare în cascadă (ca în exemplul de curs Boost_Model): PI de tensiune -> curentul total de referință
%   (cu compensarea puterii sarcinii) -> PI de curent pe fiecare fază -> factorul de umplere
%     d_k = 1 - (U_bat - v_k) / u_dc,   v_k = PI_i(i_ref/N - i_k)   (tensiunea dorită pe bobină)
%   PWM: purtătoare triunghiulară pe fiecare fază, defazată cu T_s/N; s_k = (d_k > purtătoare_k).
%   Purtătoarea se calculează din numărul pasului (aritmetică întreagă), identic în MATLAB și Python.

N = D.N_faze;  L = D.L;  Cdc = D.C;  Udc_ref = D.U_dc;  Rb = D.R_bat;  U0 = sc.U_bat_V;
dt = sc.dt;  n = round(sc.t_end / dt);
np = round(1 / (D.f_s * dt));                      % pași pe perioada de comutație
wci = 2 * pi * sc.fc_I_Hz;  Kpi = L * wci;  Kii = Kpi * wci / 10;
wcu = 2 * pi * sc.fc_U_Hz;  Kpu = Cdc * wcu;  Kiu = Kpu * wcu / 5;
Imax = 1.2 * D.I_bat_max;
i = zeros(N, 1);  zi = zeros(N, 1);  u = Udc_ref;  zu = 0;
ns = floor(n / sc.salvare) + 1;
t_ = zeros(ns, 1);  IL = zeros(ns, N);  UDC = t_;  IB = t_;  UB = t_;  DD = t_;  P_ = t_;
j = 1;  UDC(1) = u;  UB(1) = U0;
% indicatori calculați la rezoluție completă în două ferestre de 1 ms (regim stabilizat):
% 1 – tracțiune (chiar înainte de t_franare), 2 – recuperare (ultima ms)
fer = [sc.t_franare - 1e-3, sc.t_franare; sc.t_end - 1e-3, sc.t_end];
A = zeros(2, 4);  mn = inf(2, 3);  mx = -inf(2, 3);  cnt = zeros(2, 1);
for k = 1:n
    tk = (k - 1) * dt;
    if tk < sc.t_tractiune
        P = 0;
    elseif tk < sc.t_tractiune + sc.t_rampa
        P = D.P_dc_max * (tk - sc.t_tractiune) / sc.t_rampa;
    elseif tk < sc.t_franare
        P = D.P_dc_max;
    elseif tk < sc.t_franare + sc.t_rampa
        P = D.P_dc_max - (1 + sc.P_franare_rel) * D.P_dc_max * (tk - sc.t_franare) / sc.t_rampa;
    else
        P = -sc.P_franare_rel * D.P_dc_max;
    end
    isarc = P / u;
    ib = sum(i);
    Ub = U0 - Rb * ib;
    % regulatorul de tensiune (curentul condensatorului dorit) + compensarea puterii sarcinii
    eu = Udc_ref - u;
    ic = Kpu * eu + Kiu * zu;
    iref = (P + u * ic) / Ub;
    iref_s = min(max(iref, -Imax), Imax);
    if iref == iref_s || (iref > Imax && eu < 0) || (iref < -Imax && eu > 0)
        zu = zu + eu * dt;
    end
    s = zeros(N, 1);  d = zeros(N, 1);
    for q = 1:N
        ei = iref_s / N - i(q);
        v = Kpi * ei + Kii * zi(q);
        dq = 1 - (Ub - v) / u;
        d(q) = min(max(dq, 0), 1);
        if dq == d(q) || (dq > 1 && ei < 0) || (dq < 0 && ei > 0)
            zi(q) = zi(q) + ei * dt;
        end
        faza = mod(k - 1 + round((q - 1) * np / N), np);   % poziția în perioada purtătoarei
        purt = 1 - abs(2 * faza / np - 1);                % triunghi 0 -> 1 -> 0
        s(q) = d(q) > purt;
    end
    di = (Ub - (1 - s) * u) / L;
    du = (sum((1 - s) .* i) - isarc) / Cdc;
    i = i + di * dt;
    u = u + du * dt;
    for w = 1:2
        if k * dt > fer(w, 1) && k * dt <= fer(w, 2) + dt / 2
            v3 = [i(1), sum(i), u];
            A(w, :) = A(w, :) + [i(1), sum(i), u, d(1)];
            mn(w, :) = min(mn(w, :), v3);  mx(w, :) = max(mx(w, :), v3);
            cnt(w) = cnt(w) + 1;
        end
    end
    if mod(k, sc.salvare) == 0
        j = j + 1;
        t_(j) = k * dt;  IL(j, :) = i.';  UDC(j) = u;  IB(j) = sum(i);  UB(j) = U0 - Rb * sum(i);
        DD(j) = d(1);  P_(j) = P;
    end
end
R.t = t_(1:j);  R.IL = IL(1:j, :);  R.UDC = UDC(1:j);  R.IB = IB(1:j);  R.UB = UB(1:j);  R.D = DD(1:j);
R.P = P_(1:j);
R.Kpi = Kpi;  R.Kii = Kii;  R.Kpu = Kpu;  R.Kiu = Kiu;  R.np = np;
R.tr = indicatori(A(1, :) / cnt(1), mn(1, :), mx(1, :), D, U0, Rb);
R.rec = indicatori(A(2, :) / cnt(2), mn(2, :), mx(2, :), D, U0, Rb);
m = R.t >= sc.t_tractiune;                       % de la prima schimbare de sarcină până la sfârșit
R.U_dc_min = min(R.UDC(m));
R.U_dc_max = max(R.UDC(m));
end

function X = indicatori(med, mn, mx, D, U0, Rb)
X.I_faza_med = med(1);
X.dI_faza = mx(1) - mn(1);
X.dI_bat = mx(2) - mn(2);
X.dU_dc = mx(3) - mn(3);
X.U_dc_med = med(3);
X.I_bat_med = med(2);
X.U_bat_med = U0 - Rb * X.I_bat_med;
X.D_med = med(4);
X.D_teoretic = 1 - X.U_bat_med / D.U_dc;
X.dI_faza_teoretic = X.U_bat_med * X.D_teoretic / (D.L * D.f_s);
end
