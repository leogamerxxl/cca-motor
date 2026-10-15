function C = constante()
%CONSTANTE Ipotezele de calcul pentru P2 și P3 (unități S.I.).
%   Valorile marcate „curs” sunt exemplele din suportul de proiect P2 / P3;
%   celelalte sunt alegeri de proiectare justificate în README.md.

% --- mediu și drum (P2, slide 5–6) ---
C.g      = 9.81;      % [m/s^2] accelerația gravitațională
C.rho    = 1.293;     % [kg/m^3] densitatea aerului în condiții normale (0 °C, 101 325 Pa)
C.mu_f   = 0.013;     % [-] coeficient de frecare la rulare (curs)
C.mu_a   = 0.8;       % [-] coeficient de aderență (curs)
C.alpha  = 0;         % [rad] drum drept, fără pantă (simplificare curs)
C.Vv     = 0;         % [m/s] fără vânt (simplificare curs)

% --- lanț de transmisie (P2, slide 7) ---
C.r      = 0.35;      % [m] raza dinamică a roții (anvelope de 20–21", vezi README)
C.pp     = 0.01;      % [-] pierderi în reductor: Pp = 1/100 * Pax (curs)
C.Va_kmh = 100;       % [km/h] viteza Va atinsă în timpul ta (0–100 km/h)
C.n_max  = 15000;     % [rot/min] turația maximă aleasă a mașinii electrice la v_max

% --- ciclul de rulare P3 ---
C.V1_kmh = 50;        % [km/h] viteza constantă a ciclului (curs)
C.eta    = 0.80;      % [-] eta_el-mec = eta_mec-el (curs)
C.rezerva = 0.30;     % [-] rezervă de energie în baterie (curs)
C.n_pasi = [100 1000];% numărul de pași pentru discretizarea intervalului [0, t1] (curs)

% --- baterie (P3, slide 9) ---
C.U_bat_max_admis = 850; % [V] tensiunea maximă admisă a bateriei (invertoare / motoare din clasa „800 V”)
C.k_masa_bat   = 0.30;% [-] masa bateriei <= 30 % din masa vehiculului (curs)
end
