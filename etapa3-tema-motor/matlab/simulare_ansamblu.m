function C = simulare_ansamblu(S, M, T)
%SIMULARE_ANSAMBLU Simularea pe ansamblu a sistemului de acționare (suport P4, slide 4) pe ciclul din P3.
%   Lanțul: baterie 190s31p -> convertor DC-DC bidirecțional (U_conv reglată) -> N invertoare
%           -> N mașini (modelul MCC din C3) -> reductoare -> roți -> vehicul.
%   Ciclul de viteză (P3, scurtat): accelerare 0 -> V1 cu accelerația din P3 în t1, palier V1 timp de
%   C_t_palier, frânare recuperativă simetrică V1 -> 0 în t1, apoi oprire C_t_oprire.
%   Reglarea în cascadă (ca în schema bloc): regulator de viteză PI -> cuplul de referință (limitat de
%   M_max, de puterea sistemului P_lim/W și de aderență) -> curentul de referință -> regulator de curent PI
%   -> tensiunea aplicată de invertor, U în [-U_n, U_n] (invertorul permite tensiune și curent de ambele
%   semne).  La frânare mașinile dau cel mult T_rec (limitele motoarelor și ale aderenței pe punți, din
%   TEMA_PROIECT); restul este dat de frâna mecanică (energie pierdută).
%   Fazele ciclului se separă după viteza reală: accelerarea până când v atinge V1, palierul, frânarea.
%   Randamentul în regim staționar la V1 se calculează pe a doua jumătate a palierului și se folosește,
%   împreună cu randamentele simulate la accelerare și frânare, pentru refacerea calculului P3 pe tot ciclul.
%   Partea electrică din amonte (modele medii, fără dinamică, deoarece U_conv este reglată):
%     P_dc   = N*U*I / eta_inv  (tracțiune)        P_dc   = N*U*I * eta_inv  (recuperare)
%     P_bat  = P_dc / eta_dcdc  (tracțiune)        P_bat  = P_dc * eta_dcdc  (recuperare)
%     U_bat  = U_0 - R_bat*I_bat,  P_bat = U_bat*I_bat  ->  I_bat = (U_0 - sqrt(U_0^2 - 4*R_bat*P_bat)) / (2*R_bat)
%     R_bat  = Ns*R_celula/Np,     U_0 = Ns*U_nom celulă (tensiunea de mers în gol, considerată constantă)
%   Energiile pe faze se compară cu estimarea din P3 (W01/eta + W12/eta - eta*W2f).

ip = S.ip;  c = ip.simulare;  r = S.C2.r;  N = T.N;  k_rd = T.k_rd;  R3 = S.R3;  B = S.B;  cel = S.cel;

% --- ciclul de viteză ---
a  = R3.a;   V1 = R3.V1;   t1 = R3.t1;
t2 = t1 + c.C_t_palier;   t3 = t2 + t1;   t_end = t3 + c.C_t_oprire;
v_ref = @(t) a * min(t, t1) - a * min(max(t - t2, 0), t1);
C.t1 = t1;  C.t2 = t2;  C.t3 = t3;  C.a = a;  C.V1 = V1;

% --- modelul unui motor (fiecare motor antrenează 1/N din vehicul) ---
P = parametri_model(S, M, T, 'vehicul');
P.mod = 'viteza';
P.U_min = -M.U_n;
wc = 2 * pi * c.B_fc_Hz;                         % regulatorul de curent (ca în scenariul B)
P.Kp = P.L * wc;  P.Ki = P.R * wc;
wn = c.C_wn_viteza;  zeta = c.C_zeta_viteza;     % regulatorul de viteză: poli dubli în -wn (zeta = 1)
P.Kp_w = 2 * zeta * wn * P.J;  P.Ki_w = wn^2 * P.J;
T_ad = S.R2.Fa * r / (N * k_rd * T.eta_rd);      % cuplul pe motor la limita de aderență
P.Tlim_fun = @(W) min([T_ad, M.M_max, T.P_lim_motor / max(W, 1e-6)]);
P.T_rec = T.T_rec_max;
P.Wref_fun = @(t) v_ref(t) * k_rd / r;
C.Kp_w = P.Kp_w;  C.Ki_w = P.Ki_w;  C.J = P.J;  C.T_ad = T_ad;

[t, X, Y] = rk4(P, t_end, c.C_dt, [0; 0; 0; 0], c.C_salvare);
C.t = t;  C.I = X(:, 1);  C.W = X(:, 2);  C.v = C.W * r / k_rd;  C.v_ref = v_ref(t);
C.U = Y(:, 1);  C.phi = Y(:, 2);  C.T_ax = Y(:, 4);  C.I_ref = Y(:, 6);  C.T_fm = Y(:, 7);
C.eroare_v_max = max(abs(C.v - C.v_ref));        % [m/s]

% --- puteri (pe tot vehiculul) ---
C.P_ax  = N * C.T_ax .* C.W;                     % puterea la axul motoarelor
C.P_el  = N * C.U .* C.I;                        % puterea la bornele motoarelor
C.P_dc  = C.P_el ./ ip.eta_invertor .^ sign(C.P_el);
C.P_bat = C.P_dc ./ ip.eta_dcdc .^ sign(C.P_dc);
C.R_bat = B.Ns * cel.R_dc_mOhm * 1e-3 / B.Np;
C.U_0   = B.U_nom;
C.I_bat = (C.U_0 - sqrt(C.U_0^2 - 4 * C.R_bat * C.P_bat)) / (2 * C.R_bat);
C.U_bat = C.U_0 - C.R_bat * C.I_bat;
C.P_chim = C.U_0 * C.I_bat;                      % puterea cedată de celule (inclusiv pierderile R_bat*I^2)
C.I_bat_max = max(C.I_bat);   C.I_bat_min = min(C.I_bat);
C.I_celula_max = C.I_bat_max / B.Np;
C.U_bat_min = min(C.U_bat);
C.D_max = 1 - C.U_bat_min / T.U_conv;            % factorul de umplere al convertorului ridicător
C.P_bat_max = max(C.P_bat);

% --- puterea la roți (tot vehiculul) din viteza simulată: P_roată = M*v*dv/dt + (Ff + Fra)*v ---
V = S.V;  C2 = S.C2;
Ff = C2.mu_f * V.M * C2.g;
C.P_fm = T.N * C.T_fm .* C.W;                     % puterea disipată în frânele mecanice (<= 0)
C.P_rez = (Ff * sign(C.v) + 0.5 * C2.rho * V.S * V.Cx * C.v.^2) .* C.v;
% --- fazele, după viteza reală ---
k1 = find(C.v >= (1 - 1e-3) * V1, 1);
if isempty(k1), C.t_acc = t1; else, C.t_acc = t(k1); end
faze = {'acc', 0, C.t_acc; 'palier', C.t_acc, t2; 'franare', t2, t_end};
for q = 1:size(faze, 1)
    m = t >= faze{q, 2} - 1e-12 & t <= faze{q, 3} + 1e-12;
    ti = t(m);  vi = C.v(m);
    E.ax   = trapz(ti, C.P_ax(m));
    E.el   = trapz(ti, C.P_el(m));
    E.dc   = trapz(ti, C.P_dc(m));
    E.bat  = trapz(ti, C.P_chim(m));
    E.fm   = trapz(ti, C.P_fm(m));
    E.roata = 0.5 * V.M * (vi(end)^2 - vi(1)^2) + trapz(ti, C.P_rez(m));   % energia la roți
    C.E.(faze{q, 1}) = E;
end
C.E.total_bat = C.E.acc.bat + C.E.palier.bat + C.E.franare.bat;
C.E.total_ax  = C.E.acc.ax + C.E.palier.ax + C.E.franare.ax;
C.Q_bat = trapz(t, C.I_bat);                     % sarcina electrică extrasă [As]
C.dSOC_pct = C.Q_bat / (B.Cap_Ah * 3600) * 100;

% --- comparația cu P3 pe același ciclu scurtat ---
eta = S.C2.eta;
C.P3.W01 = R3.W01_exact;                         % energia mecanică la roți, accelerare
C.P3.W12 = R3.P1p * c.C_t_palier;                % palier cu V1
C.P3.W2f = R3.W01_exact;                         % frânare (W2f = W01)
C.P3.W_stocata = C.P3.W01 / eta + C.P3.W12 / eta - eta * C.P3.W2f;
% randamentele lanțului baterie <-> roți pe faze (la frânare: energia recuperată / energia de frânare
% de la roți, inclusiv partea preluată de frâna mecanică)
C.eta_acc  = C.E.acc.roata / C.E.acc.bat;
C.eta_pal  = C.E.palier.roata / C.E.palier.bat;
C.eta_rec  = C.E.franare.bat / C.E.franare.roata;
C.cota_fm  = C.E.franare.fm / (C.E.franare.fm + C.E.franare.ax);   % partea frânei mecanice (la ax)
% regimul staționar la V1 (a doua jumătate a palierului): P la roți = P1' din P3
m = t >= t1 + 0.5 * c.C_t_palier & t <= t2;
C.P_bat_palier = mean(C.P_chim(m));
C.eta_pal_stabil = R3.P1p / C.P_bat_palier;
% refacerea calculului P3 pe tot ciclul (palierul de t12) cu randamentele simulate
C.P3.W_stocata_sim = R3.W01 / C.eta_acc + R3.W12 / C.eta_pal_stabil - C.eta_rec * R3.W2f;
C.P3.W_bat_sim = C.P3.W_stocata_sim / (1 - S.C2.rezerva);
C.P3.rezerva_sim = 1 - C.P3.W_stocata_sim / B.W_real;
% palierul cu 3, 2 (puntea față decuplată) sau 1 motor activ (celelalte decuplate mecanic) – calcul static
C.palier = eficienta_palier(S, M, T, [3 2 1], C.eta_acc, C.eta_rec);
end
