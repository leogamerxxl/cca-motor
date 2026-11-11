function R = sim_incarcare_comutatie(C, sc)
%SIM_INCARCARE_COMUTATIE Încărcătorul cu comutație: coborâtor cu reglare de curent prin histerezis
%   (ca în exemplul din suportul P5-P6) și regulator PI de tensiune pentru faza CV.
%   Ca simularea să dureze puțin, bateria are capacitatea echivalentă redusă de k_timp ori
%   (C_s = C_eq / k_timp): fenomenele lente se desfășoară de k_timp ori mai repede, comutația rămâne reală.
%   Tensiunea inițială este aleasă astfel încât faza CC să dureze t_CC_s.
%   Încărcarea se oprește când curentul mediu (filtrat, tau_filtru_I) scade sub I_taiere în faza CV
%   (la curent mic, banda fixă de histerezis lucrează în impulsuri – conducție întreruptă).
%     L di/dt = s*U_dc - U_bat  (s = 0 și i = 0: dioda blochează – conducție întreruptă)
%     U_bat = OCV + R_bat*i,  dOCV/dt = i / C_s
%     histerezis: s = 0 dacă i >= I_ref + h/2;  s = 1 dacă i <= I_ref - h/2
%     I_ref = sat(PI(U_CV - U_f), 0, I_CC),  U_f = U_bat filtrată (filtru de ordinul 1, tau_filtru)
%   Regulatorul de tensiune: câștigul la frecvențe mari K_p*R_bat = Kp_R < 1 (ondulația și întârzierea
%   buclei de curent nu destabilizează bucla); frecvența de tăiere fc_U este dată de componenta integrală:
%     K_i = 2*pi*fc_U / |R_bat + 1/(j*2*pi*fc_U*C_s)|

dt = sc.dt;  n = round(sc.t_end / dt);
Cs = C.C_eq / sc.k_timp;
R.C_s = Cs;  R.tau_s = C.R_bat * Cs;
OCV = C.U_CV - C.R_bat * C.I_CC - C.I_CC * sc.t_CC_s / Cs;
R.OCV0 = OCV;
wc = 2 * pi * sc.fc_U_Hz;
Kp = sc.Kp_R / C.R_bat;
Ki = wc / abs(C.R_bat + 1 / (1i * wc * Cs));
R.Kp = Kp;  R.Ki = Ki;
i = 0;  s = 1;  z = C.I_CC / Ki;  h = C.h;  Uf = OCV;  If = 0;  oprit = false;  t_stop = NaN;
ns = floor(n / sc.salvare) + 1;
t_ = zeros(ns, 1);  I_ = t_;  U_ = t_;  Iref_ = t_;  S_ = t_;
j = 1;  t_(1) = 0;  I_(1) = i;  U_(1) = OCV;  Iref_(1) = C.I_CC;  S_(1) = s;
nr_comutatii = 0;  t_CC = NaN;
for k = 1:n
    U = OCV + C.R_bat * i;
    Uf = Uf + (U - Uf) * dt / sc.tau_filtru_s;
    e = C.U_CV - Uf;
    iu = Kp * e + Ki * z;
    Iref = min(max(iu, 0), C.I_CC);
    if iu == Iref || (iu > C.I_CC && e < 0) || (iu < 0 && e > 0)
        z = z + e * dt;
    end
    if isnan(t_CC) && Iref < 0.99 * C.I_CC, t_CC = (k - 1) * dt; end
    If = If + (i - If) * dt / sc.tau_filtru_I_s;
    if ~oprit && ~isnan(t_CC) && If < C.I_taiere
        oprit = true;  t_stop = (k - 1) * dt;          % sfârșitul încărcării
    end
    s_vechi = s;
    if oprit
        s = 0;  Iref = 0;
    elseif i >= Iref + h / 2
        s = 0;
    elseif i <= Iref - h / 2
        s = 1;
    end
    if s == 1 && s_vechi == 0, nr_comutatii = nr_comutatii + 1; end
    di = (s * C.U_dc - U) / C.L;
    i = i + di * dt;
    if i < 0, i = 0; end
    OCV = OCV + i * dt / Cs;
    if mod(k, sc.salvare) == 0
        j = j + 1;
        t_(j) = k * dt;  I_(j) = i;  U_(j) = OCV + C.R_bat * i;  Iref_(j) = Iref;  S_(j) = s;
    end
    if k == round(sc.t_CC_s * 0.9 / dt), nr_cc = nr_comutatii; end
end
R.t = t_(1:j);  R.I = I_(1:j);  R.U = U_(1:j);  R.Iref = Iref_(1:j);  R.s = S_(1:j);
R.t_CC = t_CC;
R.t_stop = t_stop;
R.t_stop_teoretic = sc.t_CC_s + R.tau_s * log(C.I_CC / C.I_taiere);
R.f_CC = nr_cc / (sc.t_CC_s * 0.9);              % frecvența medie de comutație în faza CC
R.f_CC_teoretic = C.U_dc * (C.U_CV / C.U_dc) * (1 - C.U_CV / C.U_dc) / (h * C.L);
% curentul mediu în faza CV comparat cu modelul mediu: I = I_CC * exp(-(t - t_CC) / tau_s)
tt = sc.t_CC_s + R.tau_s;
m = abs(R.t - tt) <= 1 / R.f_CC;                   % o fereastră de ~2 perioade în jurul lui t_CC + tau_s
R.I_med_tau = mean(R.I(m));
R.I_med_tau_teoretic = C.I_CC * exp(-1);
R.U_final = R.U(end);
end
