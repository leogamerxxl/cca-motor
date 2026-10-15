function R = calcul_p3(V, C, R2)
%CALCUL_P3 Necesarul de energie electrică (suport P3, slide 4–8, pașii 1–14).
%   R = CALCUL_P3(V, C, R2) folosește accelerația R2.a calculată în P2 și
%   cerința de autonomie V.autonomie. Lanțul de calcul:
%   P1 -> P1' -> t1 -> Pmed -> P01_med -> Wmed -> W01_med -> W01 -> d1 -> d2
%      -> W12 -> Wmec -> Wstocata -> Wbat

R.nume = V.nume;
R.V1 = C.V1_kmh / 3.6;                       % [m/s]

% Pasul 2–4: accelerația din sesiunea precedentă (a = Va/ta, P2 pasul 2) și
% verificarea aderenței în punctul (V1, t1); dacă Ft > Fa se recalculează a.
R.a_P2 = R2.a_doc;
R.a = R.a_P2;
F1 = forte_rezistente(R.V1, R.a, V, C);
R.aderenta_ok = F1.Ft <= F1.Fa;
if ~R.aderenta_ok
    R.a = (F1.Fa - F1.Fra - F1.Ff - F1.Gt) / V.M;
    F1 = forte_rezistente(R.V1, R.a, V, C);
end
R.Fra_V1 = F1.Fra;  R.Ff = F1.Ff;  R.Gt = F1.Gt;  R.Fa = F1.Fa;
R.Ft1 = F1.Ft;
R.P1  = R.Ft1 * R.V1;                        % [W] puterea la V1 cu accelerația a

% Pasul 5: puterea la viteză constantă V1 (fără accelerație)
F1p = forte_rezistente(R.V1, 0, V, C);
R.Ft1p = F1p.Ft;
R.P1p  = R.Ft1p * R.V1;                      % [W]

% Pasul 6: timpul de accelerare
R.t1 = R.V1 / R.a;                           % [s]

% Pasul 7: puterea medie pe [0, t1] (aproximare liniară, P0 = 0)
R.P0   = 0;
R.Pmed = (R.P0 + R.P1) / 2;                  % [W]

% Pasul 7–8 (exercițiu Matlab): discretizare în n intervale egale.
% Grila are n+1 puncte, t(1) = 0 ... t(n+1) = t1 (indicii Matlab = indicii din curs).
% Pe fiecare interval forța F_ti și viteza V_ti sunt constante:
%   P01_med = (1/n) * sum_{i=1..n}   F_ti*V_ti   -> valorile de la începutul intervalelor
%   W01     = sum_{i=1..n+1} P_ti*dt             -> cum P(t(1)) = 0, valorile de la sfârșitul intervalelor
% Cele două sume încadrează integrala exactă (prima o subestimează, a doua o supraestimează).
A = R.Ff + R.Gt + V.M * R.a;                 % termenul constant al Ft
B = 0.5 * C.rho * V.S * V.Cx;                % Fra = B * v^2 (Vv = 0)
R.W01_exact = A * R.a * R.t1^2 / 2 + B * R.a^3 * R.t1^4 / 4;   % integrala analitică
R.P01_exact = R.W01_exact / R.t1;

nr = numel(C.n_pasi);
R.disc = struct('n', cell(1, nr));
for k = 1:nr
    n  = C.n_pasi(k);
    dt = R.t1 / n;
    t  = linspace(0, R.t1, n + 1);           % t(1) = 0 ... t(n+1) = t1
    v  = R.a * t;                            % V_ti
    F  = forte_rezistente(v, R.a, V, C);     % F_ti
    P  = F.Ft .* v;                          % P_ti = F_ti * V_ti  (P(t(1)) = 0)
    P01_med = sum(P(1:n)) / n;               % (1/n) * sum_{i=1..n} F_ti V_ti
    W01 = sum(P(1:n+1)) * dt;                % sum_{i=1..n+1} P_ti * dt_i

    % efortul de calcul: același calcul (grilă, forțe, sume) repetat de nrep ori
    nrep = 2000;
    tic;
    for q = 1:nrep
        tt = linspace(0, R.t1, n + 1);
        vv = R.a * tt;
        FF = forte_rezistente(vv, R.a, V, C);
        PP = FF.Ft .* vv;
        pm = sum(PP(1:n)) / n; %#ok<NASGU>
        ww = sum(PP) * dt;     %#ok<NASGU>
    end
    durata = toc / nrep;

    R.disc(k).n        = n;
    R.disc(k).dt       = dt;
    R.disc(k).t        = t;
    R.disc(k).P        = P;
    R.disc(k).P01_med  = P01_med;
    R.disc(k).W01      = W01;
    R.disc(k).W01_med  = P01_med * R.t1;
    R.disc(k).eroare_W01_pct = (W01 - R.W01_exact) / R.W01_exact * 100;
    R.disc(k).eroare_W01_med_pct = (P01_med * R.t1 - R.W01_exact) / R.W01_exact * 100;
    R.disc(k).timp_s   = durata;
end

% Pasul 8: energia mecanică pe [0, t1]
R.Wmed    = R.Pmed * R.t1;                   % [Ws]
R.P01_med = R.disc(end).P01_med;             % valorile cu cel mai fin pas
R.W01_med = R.disc(end).W01_med;
R.W01     = R.disc(end).W01;

% Pasul 9–10: distanțe (aria de sub curba vitezei), df = d1
R.d1 = R.V1 * R.t1 / 2;                      % [m]
R.df = R.d1;
R.autonomie = V.autonomie;                   % [m] cerința de autonomie
R.d2 = R.autonomie - R.d1 - R.df;            % [m]
R.t12 = R.d2 / R.V1;                         % [s] t2 - t1 = d2 / V1
R.t2 = R.t1 + R.t12;
R.tf = R.t2 + R.t1;                          % decelerare simetrică (df = d1)

% Pasul 11–12: energia la viteză constantă și energia mecanică pe ciclu
R.W12  = R.P1p * R.t12;                      % [Ws]
R.W2f  = R.W01;                              % W01 = W2f (curs)
R.Wmec = R.W01 + R.W12 - R.W2f;              % [Ws]

% Pasul 13: energia electrică stocată, cu eta_el-mec = eta_mec-el
R.Wstocata = R.W01 / C.eta + R.W12 / C.eta - C.eta * R.W2f;

% Pasul 14: rezervă de 30 %: Wbat = Wstocata + 0,3 * Wbat
R.Wbat = R.Wstocata / (1 - C.rezerva);

% mărimi derivate pentru comparația cu documentarea
R.Wbat_kWh      = R.Wbat / 3.6e6;
R.Wstocata_kWh  = R.Wstocata / 3.6e6;
R.consum_stoc_kWh100 = R.Wstocata / R.autonomie * 100 / 3600;   % [kWh/100 km]
R.W_bat_doc_kWh = V.W_bat_doc / 3.6e6;
R.consum_doc_kWh100 = V.consum_doc * 100 / 3600;
end
