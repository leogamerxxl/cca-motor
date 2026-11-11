function Z = simulari(S, M, T)
%SIMULARI Scenariile de simulare a mașinii (curs C3, exercițiul 2), pentru UN motor YM720.
%   A – pornire în gol la tensiunea U_p care limitează curentul de pornire la I_max (C3, IV), apoi
%       treaptă de cuplu de sarcină (ca în exemplul de curs MCC_CCA.slx)
%   B – accelerarea vehiculului cu regulator PI de curent și slăbire de câmp; cuplul cerut este
%       limitat de aderență (ca în P2) și de puterea maximă a motorului; se oprește la v_max
%   D – tensiune în rampă (fără regulator) cu sarcina vehiculului – scenariul refăcut în Simulink;
%       durata se alege astfel încât turația să rămână sub n_max
%   (C – ciclul de viteză al întregului sistem – este în SIMULARE_ANSAMBLU)
%   Toate folosesc același integrator RK4 cu pas fix (rk4.m).

ip = S.ip;  sim = ip.simulare;  r = S.C2.r;  N = T.N;  k_rd = T.k_rd;

% --- A: pornire în gol la U_p ---
P = parametri_model(S, M, T, 'gol');
P.mod = 'tensiune';  P.U_fun = @(t) M.U_p;
P.M_treapta = sim.A_M_treapta;  P.t_treapta = sim.A_t_treapta;     % treaptă de sarcină, ca în exemplul de curs
[t, X, Y] = rk4(P, sim.A_t_end, sim.A_dt, [0; 0; 0; 0], sim.A_salvare);
k0 = find(t < sim.A_t_treapta, 1, 'last');                        % ultimul punct înainte de treaptă
Z.A = struct('t', t, 'I', X(:, 1), 'W', X(:, 2), 'U', Y(:, 1), 'T_ax', Y(:, 4), ...
             'I_varf', max(X(:, 1)), 'W_gol', X(k0, 2), 'W_final', X(end, 2), 'I_final', X(end, 1), ...
             'W_gol_teoretic', (M.U_p - M.dU_p - M.R_a * M.T_f0 / M.k) / (M.k + M.R_a * M.F_v / M.k), ...
             'W_sarcina_teoretic', (M.U_p - M.dU_p - M.R_a * (sim.A_M_treapta + M.T_f0) / M.k) / ...
                                   (M.k + M.R_a * M.F_v / M.k), ...
             'I_sarcina_teoretic', 0);
Z.A.I_sarcina_teoretic = (sim.A_M_treapta + M.T_f0 + M.F_v * Z.A.W_sarcina_teoretic) / M.k;

% --- B: accelerare cu regulator de curent ---
P = parametri_model(S, M, T, 'vehicul');
P.mod = 'curent';
wc = 2 * pi * sim.B_fc_Hz;                  % banda regulatorului de curent
P.Kp = P.L * wc;  P.Ki = P.R * wc;          % compensarea polului electric (L/R)
T_ad = S.R2.Fa * r / (N * k_rd * T.eta_rd); % cuplul pe motor care folosește toată aderența
P.T_ad = T_ad;
P.Iref_fun = @(W, phi) (min([T_ad, M.M_max, M.P_max / max(W, 1e-6)]) + M.T_f0 + M.F_v * W) / (M.k * phi);
W_vmax = S.V.vmax * k_rd / r;
[t, X, Y] = rk4(P, sim.B_t_end, sim.B_dt, [0; 0; 0; 0], sim.B_salvare, @(x) x(2) >= W_vmax);
v = X(:, 2) * r / k_rd;                      % viteza vehiculului [m/s]
Z.B = struct('t', t, 'I', X(:, 1), 'W', X(:, 2), 'v', v, 'U', Y(:, 1), 'phi', Y(:, 2), ...
             'T_ax', Y(:, 4), 'T_ad', T_ad);
Z.B.t_100  = interp_timp(t, v, 100 / 3.6);
Z.B.t_200  = interp_timp(t, v, 200 / 3.6);
Z.B.t_vmax = t(end);
Z.B.atins_vmax = X(end, 2) >= W_vmax;
Z.B.I_varf = max(X(:, 1));

% --- D: rampă de tensiune (model Simulink) ---
P = parametri_model(S, M, T, 'vehicul');
P.mod = 'tensiune';
P.U_fun = @(t) min(max(sim.D_U0 + sim.D_panta * t, 0), M.U_n);
[t, X, Y] = rk4(P, sim.D_t_end, sim.D_dt, [0; 0; 0; 0], sim.D_salvare);
Z.D = struct('t', t, 'I', X(:, 1), 'W', X(:, 2), 'v', X(:, 2) * r / k_rd, 'U', Y(:, 1), ...
             'phi', Y(:, 2), 'T_ax', Y(:, 4), 'I_varf', max(X(:, 1)), 'W_final', X(end, 2));
end

function tx = interp_timp(t, v, vx)
k = find(v >= vx, 1);
if isempty(k) || k == 1
    tx = NaN;
else
    tx = t(k-1) + (vx - v(k-1)) * (t(k) - t(k-1)) / (v(k) - v(k-1));
end
end
