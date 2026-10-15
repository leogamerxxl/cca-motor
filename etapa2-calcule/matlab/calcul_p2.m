function R = calcul_p2(V, C)
%CALCUL_P2 Puterea mașinii electrice (suport P2, slide 6–8, pașii 1–9).
%   R = CALCUL_P2(V, C) pornește de la forțele rezistente și calculează succesiv
%   Ft -> Mr -> Pr -> Pax, pentru punctul (Va, ta) – puterea maximă – și pentru
%   rularea cu v_max constantă – puterea nominală.

R.nume = V.nume;

% Pasul 1–2: ciclu accelerare / v constantă / decelerare; accelerația medie 0–Va
R.Va = C.Va_kmh / 3.6;                       % [m/s]
R.a_doc  = V.a_doc;                          % [m/s^2] din documentare
R.ta_doc = R.Va / R.a_doc;                   % [s]

% Pasul 3: forța de tracțiune în punctul (Va, ta)
F3 = forte_rezistente(R.Va, R.a_doc, V, C);
R.Fra_Va = F3.Fra;  R.Ff = F3.Ff;  R.Gt = F3.Gt;
R.Ft_doc = F3.Ft;   R.Fa = F3.Fa;

% Pasul 4: verificarea aderenței Ft <= Fa; altfel Ft = Fa și se recalculează a
R.mu_necesar = R.Ft_doc / (V.M * C.g * cos(C.alpha));   % aderența cerută de a_doc
R.aderenta_ok = R.Ft_doc <= R.Fa;
if R.aderenta_ok
    R.a  = R.a_doc;
    R.Ft = R.Ft_doc;
else
    R.a  = (R.Fa - R.Fra_Va - R.Ff - R.Gt) / V.M;
    R.Ft = R.Fa;
end
R.ta = R.Va / R.a;                           % [s] timpul 0–Va realizabil

% Pasul 5: cuplul și puterea la roată, puterea la axul mașinii electrice
R.Omega_r_Va = R.Va / C.r;                   % [rad/s]
R.Mr  = C.r * R.Ft;                          % [Nm]
R.Pr  = R.Mr * R.Omega_r_Va;                 % [W] (= Ft * Va)
R.Pax = R.Pr / (1 - C.pp);                   % [W] Pax = Pr + Pp, Pp = Pax/100
R.Pp  = R.Pax - R.Pr;                        % [W]

% Pasul 6: reductorul (i_rd = Omega_r / Omega_ax) și cuplul la axul mașinii
R.Omega_r_max  = V.vmax / C.r;               % [rad/s] la v_max
R.Omega_ax_max = C.n_max * 2 * pi / 60;      % [rad/s] turația maximă aleasă
R.i_rd = R.Omega_r_max / R.Omega_ax_max;     % [-] (< 1)
R.k_rd = 1 / R.i_rd;                         % [-] raport de reducere „clasic” n_motor / n_roată
R.Omega_ax_Va = R.Omega_r_Va / R.i_rd;       % [rad/s] turația de bază
R.n_ax_Va = R.Omega_ax_Va * 60 / (2 * pi);   % [rot/min]
R.Max = R.Pax / R.Omega_ax_Va;               % [Nm] cuplul maxim la axul mașinii

% Pasul 7: forța de tracțiune la v_max (a = 0)
F7 = forte_rezistente(V.vmax, 0, V, C);
R.vmax = V.vmax;
R.Fra_vmax = F7.Fra;
R.Ft_vmax  = F7.Ft;

% Pasul 8: aderența la v_max și puterea pentru rulare cu v_max constantă
R.aderenta_vmax_ok = R.Ft_vmax <= R.Fa;
if ~R.aderenta_vmax_ok
    % se reduce v_max până când Ft = Fa
    R.vmax = sqrt((R.Fa - R.Ff - R.Gt) / (0.5 * C.rho * V.S * V.Cx)) + C.Vv;
    R.Ft_vmax = R.Fa;
end
R.Mr_vmax  = C.r * R.Ft_vmax;
R.Pr_vmax  = R.Ft_vmax * R.vmax;
R.Pax_nom  = R.Pr_vmax / (1 - C.pp);
R.Max_vmax = R.Pax_nom / R.Omega_ax_max;

% Pasul 9: puterea maximă (pas 5) și nominală (pas 8)
R.P_max = R.Pax;
R.P_nom = R.Pax_nom;

% Verificare de coerență cu documentarea: aceeași formulă cu accelerația documentată
R.Pax_fara_aderenta = R.Ft_doc * R.Va / (1 - C.pp);
R.Max_fara_aderenta = R.Pax_fara_aderenta / R.Omega_ax_Va;
R.P_doc = V.P_doc;
R.cuplu_doc = V.cuplu_doc;
R.raport_vmax = R.vmax / R.Va;               % domeniul de slăbire de câmp necesar
end
