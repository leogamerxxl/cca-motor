function H = incalzire(S, M, T, Z)
%INCALZIRE Căldura produsă de pierderi și creșterea de temperatură (curs C3, VIII): Q = m*c*dT.
%   Calcul adiabatic (fără răcire) pentru UN motor, în patru regimuri, și puterea de răcire necesară
%   în regim permanent (egală cu pierderile).
r = S.C2.r;  k_rd = T.k_rd;  N = T.N;  mc = M.masa * M.c;   % [J/K] capacitatea termică

% 1) accelerarea din simularea B, până la 100 km/h
B = Z.B;  m100 = B.v <= 100 / 3.6;
W = B.W(m100);  I = B.I(m100);  t = B.t(m100);
P = M.R_a * I.^2 + M.dU_p * abs(I) + M.K_H * W + M.K_F * W.^2 + M.T_m0 * W + M.F_m * W.^2;
H.acc.Q  = trapz(t, P);
H.acc.dT = H.acc.Q / mc;
H.acc.durata = t(end);
H.acc.P_med = H.acc.Q / t(end);

% 2) 30 s (durata de vârf din catalog) la cuplul maxim și la cea mai mare viteză la care catalogul
%    mai permite cuplul maxim (W = P_max/M_max, dacă aceasta este sub viteza de bază)
W = min(M.W_b, M.P_max / M.M_max);
L = punct_functionare(M, W, M.M_max);
H.varf.n = W * 60 / (2*pi);
H.varf.SP = L.SP;  H.varf.durata = S.mot.durata_varf_s;
H.varf.Q = L.SP * H.varf.durata;  H.varf.dT = H.varf.Q / mc;  H.varf.eta = L.eta;

% 3) rulare continuă cu v_max (cuplul împărțit egal pe motoare)
W = T.n_m_vmax * 2*pi / 60;
L = punct_functionare(M, W, T.M_nec_n / N);
H.vmax.SP = L.SP;  H.vmax.eta = L.eta;  H.vmax.T = T.M_nec_n / N;  H.vmax.n = T.n_m_vmax;
H.vmax.dT_min = L.SP * 60 / mc;                   % creșterea de temperatură într-un minut fără răcire

% 4) ciclul P3: rulare cu 50 km/h
W = S.R3.V1 / r * k_rd;
Tm = S.R3.Ft1p * r / (N * k_rd * T.eta_rd);
L = punct_functionare(M, W, Tm);
H.p3.SP = L.SP;  H.p3.eta = L.eta;  H.p3.T = Tm;  H.p3.n = W * 60 / (2*pi);
H.p3.Q  = L.SP * S.R3.t12;  H.p3.dT = H.p3.Q / mc;
H.mc = mc;
end
