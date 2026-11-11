function T = tema_proiect(S, M)
%TEMA_PROIECT Tema de proiect (suport P4, slide 3): cerințele vehiculului, mașina electrică, reductorul,
%   bateria și verificările („confirmare”) ale alegerilor față de cerințe.
%   S – datele (INCARCA_DATE), M – parametrii unui motor (IDENTIFICARE_MCC).

R2 = S.R2;  ip = S.ip;  mot = S.mot;  B = S.B;
N  = mot.numar_motoare;
rpm = 60 / (2*pi);

% --- cerințele vehiculului, la roți (tot vehiculul) ---
T.P_rn  = R2.Pr_vmax;               % regim nominal: rulare continuă cu v_max
T.M_rn  = R2.Mr_vmax;
T.n_rn  = R2.Omega_r_max * rpm;
T.P_rmax = R2.Pr;                   % regim maxim: accelerare 0–100 km/h la limita de aderență
T.M_rmax = R2.Mr;
T.n_rmax = R2.Omega_r_max * rpm;    % turația maximă a roților (la v_max)
T.n_r_Va = R2.Omega_r_Va * rpm;

% --- reductorul (ales liber): n_max al motorului corespunde (cu rezervă mică) lui v_max ---
T.k_rd   = ip.k_rd;                 % n_motor / n_roată
T.i_rd   = 1 / T.k_rd;              % notația din curs: i_rd = Omega_r / Omega_ax
T.eta_rd = ip.eta_rd;
T.n_m_vmax = T.n_rmax * T.k_rd;     % turația motoarelor la v_max
T.n_m_Va   = T.n_r_Va * T.k_rd;

% --- cerințele la axul motoarelor (total) ---
T.P_nec_max = R2.P_max;             % puterea maximă la ax (P2, pasul 5)
T.P_nec_n   = R2.P_nom;             % puterea nominală la ax (P2, pasul 8)
T.M_nec_max = T.M_rmax / (T.k_rd * T.eta_rd);
T.M_nec_n   = T.P_nec_n / (T.n_m_vmax / rpm);
% repartiția pe punți la accelerare (repartiție statică și transfer de sarcină h/L)
f_fata = ip.repartitie_statica_fata - R2.a / S.C2.g * ip.h_L;
T.f_fata = f_fata;
T.M_nec_fata  = f_fata * T.M_nec_max;               % 1 motor pe puntea față
T.M_nec_spate = (1 - f_fata) * T.M_nec_max / 2;     % 2 motoare pe puntea spate (fiecare)
% limita de putere a sistemului: bateria și DC-DC-ul sunt dimensionate pentru P_max din P2 (nu pentru
% 3 x P_max al motoarelor), deci cuplul cerut motoarelor este limitat și la P_nec_max / (N * Omega)
T.P_lim_motor = min(M.P_max, T.P_nec_max / N);
% cerințele pe motor în cele două regimuri (pentru comparația cu datele de catalog)
W_Va = T.n_m_Va / rpm;  W_vm = T.n_m_vmax / rpm;
T.Mm_max_nec = T.P_nec_max / (N * W_Va);            % cuplul pe motor la P_max (100 km/h, cuplu egal)
L = punct_functionare(M, [W_Va, W_vm], [T.Mm_max_nec, T.M_nec_n / N]);
T.Pm_max_nec = T.P_nec_max / N;   T.Im_max_nec = L.I(1);   T.nm_max_nec = T.n_m_Va;
T.Pm_n_nec   = T.P_nec_n / N;     T.Im_n_nec   = L.I(2);   T.Mm_n_nec = T.M_nec_n / N;
% frânarea recuperativă cu decelerația din P3 (simetrică accelerării): repartiția sarcinii pe punți
% la frânare (transfer spre față) și limitele motoarelor și ale aderenței pe fiecare punte
a_fr = S.R3.a;  FzMg = S.V.M * S.C2.g;
T.a_fr = a_fr;
T.f_fata_fr = ip.repartitie_statica_fata + a_fr / S.C2.g * ip.h_L;
F_motor = M.M_max * T.k_rd / S.C2.r;                % forța la roată dată de un motor la M_max
T.F_fata_fr  = min(S.C2.mu_a * T.f_fata_fr * FzMg, 1 * F_motor);
T.F_spate_fr = min(S.C2.mu_a * (1 - T.f_fata_fr) * FzMg, 2 * F_motor);
T.F_rec_max = T.F_fata_fr + T.F_spate_fr;           % forța de frânare recuperabilă electric
T.F_fr_nec  = S.V.M * a_fr - S.R3.Ff - S.R3.Fra_V1; % forța de frânare cerută la V1 (rezistențele ajută)
T.cota_rec  = min(1, T.F_rec_max / T.F_fr_nec);
T.ok_frana  = T.F_rec_max + 1e-9 >= T.F_fr_nec;       % NU -> restul cu frâna mecanică
T.T_rec_max = T.F_rec_max * S.C2.r * T.eta_rd / (N * T.k_rd);   % cuplul recuperativ mediu pe motor

% --- mașina electrică aleasă: N × YM720 (valori pe motor și total) ---
T.N = N;
T.ME_P_n = M.P_n;       T.ME_P_max = M.P_max;
T.ME_M_n = M.M_n;       T.ME_M_max = M.M_max;
T.ME_n_n = M.n_n;       T.ME_n_max = M.n_max;   T.ME_n_b = M.n_b;
T.ME_U_n = M.U_n;       T.ME_I_n = M.I_n;       T.ME_I_max = M.I_max;

% --- verificări (confirmare MCC / reductor / baterie) ---
T.ok_P_max   = N * M.P_max >= T.P_nec_max;
T.ok_P_n     = N * M.P_n   >= T.P_nec_n;
T.ok_M_fata  = M.M_max >= T.M_nec_fata;
T.ok_M_spate = M.M_max >= T.M_nec_spate;
T.ok_n_max   = M.n_max >= T.n_m_vmax;
T.M_roti_disp = N * M.M_max * T.k_rd * T.eta_rd;   % cuplul maxim disponibil la roți
T.ok_M_roti  = T.M_roti_disp >= T.M_rmax;
T.ok_U       = ip.U_conv_V <= mot.U_dc_max_V && ip.U_conv_V >= mot.U_dc_min_V;

% --- convertorul DC-DC bidirecțional (ridicător de tensiune la tracțiune) ---
T.U_conv = ip.U_conv_V;                      % tensiunea reglată a circuitului intermediar
T.U_bat_min = B.U_min;  T.U_bat_max = B.U_max;  T.U_bat_nom = B.U_nom;
T.D_max = 1 - B.U_min / T.U_conv;            % factorul de umplere (boost): U_conv = U_bat / (1 - D)
T.D_min = 1 - B.U_max / T.U_conv;
T.P_el_max = T.P_nec_max / S.C2.eta;         % puterea electrică la P_max (randamentul global din P3)
T.I_conv   = T.P_el_max / T.U_conv;          % curentul în circuitul intermediar
T.I_bat_max = T.P_el_max / B.U_min;          % curentul bateriei la U_min

% --- bateria ---
T.W_bat_nec  = S.R3.Wbat;
T.W_bat_inst = B.W_real;
T.ok_W_bat   = T.W_bat_inst >= T.W_bat_nec;
T.ok_I_cel   = B.I_celula <= S.cel.I_max_cont;
T.P_bat_disp = S.cel.I_max_cont * B.Np * B.U_min;            % puterea maximă a bateriei la U_min
T.P_mec_disp = T.P_bat_disp * S.C2.eta;                     % puterea mecanică disponibilă
T.ok_P_bat   = T.P_mec_disp >= T.P_nec_max;
end
