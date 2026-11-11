function rez = model_sps_ansamblu(P, t_palier, Ts, inversat)
%MODEL_SPS_ANSAMBLU P4/P5-P6: simularea pe ansamblu a sistemului de acționare (schema bloc, slide 4) în
%   Specialized Power Systems, pe ciclul de viteză din P3 (0 -> 50 km/h -> 0, palier t_palier):
%     baterie (U_nom + R_bat) -> DC-DC bidirecțional cu 4 faze (U_conv = 800 V, ca în MODEL_SPS_DCDC)
%     -> chopper în punte H (echivalentul MCC al invertorului, PWM unipolar) -> DC Machine cu magneți
%     permanenți (parametrii YM720 din C3; J = J_rotor + inerția vehiculului raportată, 1/3 din vehicul)
%     -> cuplul de sarcină al vehiculului T_s = a0*sign(w) + a2*w^2 (rezistențele la înaintare, P2).
%   Celelalte două motoare (identice, aceeași sarcină) sunt reprezentate de o sursă de curent comandată
%   care absoarbe din circuitul intermediar de 2 ori curentul punții H.
%   Reglarea (ca în simulare_ansamblu.m): PI de viteză cu anti-windup (integrare condiționată) -> T_ref
%   limitat (M_max, P_lim/w, aderență; fără frânare la w = 0) -> la frânare mașina dă cel mult T_rec
%   (T_el = max(T_ref, -T_rec)), restul T_fm = T_ref - T_el îl dă frâna mecanică (adăugată cuplului de
%   sarcină) -> I_ref = (T_el + Tf0*sign(w) + Fv*w)/k -> PI de curent -> tensiunea -> PWM.
%   Rezultatele se compară cu modelul MATLAB (simulare_ansamblu.m) rulat cu același palier.
%   Durata de calcul crește cu t_palier (implicit 2 s) și scade cu Ts (implicit 2 µs).
if nargin < 1 || isempty(P), P = parametri_simulink(); end
if nargin < 2 || isempty(t_palier), t_palier = 2; end
if nargin < 3 || isempty(Ts), Ts = 2e-6; end
if nargin < 4, inversat = false; end
L = biblioteci();  M = P.M;  T = P.T;  Q = P.veh;  S = P.S;  R3 = S.R3;  r = S.C2.r;  k_rd = T.k_rd;
sp = S.ip.simulare;  H = P.H;
t1 = R3.t1;  t2 = t1 + t_palier;  t3 = t2 + t1;  t_end = t3 + sp.C_t_oprire;
W1 = R3.V1 * k_rd / r;
T_ad = S.R2.Fa * r / (T.N * k_rd * T.eta_rd);
wc = 2 * pi * sp.B_fc_Hz;  Kp_i = Q.L * wc;  Ki_i = Q.R * wc;
Kp_w = 2 * sp.C_zeta_viteza * sp.C_wn_viteza * Q.J;  Ki_w = sp.C_wn_viteza^2 * Q.J;
mos = {'Ron', nr(P.S.cv.dcdc.modul.R_DS_on_cald_mOhm * 1e-3), 'Lon', '0', 'Rd', '1e-3', 'Vfd', '0', 'IC', '0', ...
       'Rs', '1e5', 'Cs', 'inf', 'Measurements', 'off'};
dec = round(1e-4 / Ts);                                   % un punct salvat la 0,1 ms
mdl = model_nou('cca_sps_ansamblu');
c = @(a, b) leaga(mdl, a, b);
bloc(mdl, 'powergui', L.powergui, [40 20 120 60], 'SimulationMode', 'Discrete', 'SampleTime', nr(Ts));
adauga_dcdc(mdl, P, S.B.U_nom, Ts);

% --- puntea H și mașina ---
bloc(mdl, 'Ihb_m', L.masura_I, [800 150 830 180]);
bloc(mdl, 'SA_sus', L.mosfet, [880 100 910 130], mos{:});
bloc(mdl, 'SA_jos', L.mosfet, [880 220 910 250], mos{:});
bloc(mdl, 'SB_sus', L.mosfet, [1040 100 1070 130], mos{:});
bloc(mdl, 'SB_jos', L.mosfet, [1040 220 1070 250], mos{:});
bloc(mdl, 'Masina', L.masina_cc, [930 150 1020 210], ...
     'PresetModel', 'No', 'FieldType', 'Permanent magnet', 'MechanicalLoad', 'Torque TL', ...
     'MachineConstant', 'Torque constant (N.m/A)', ...
     'RLa', nr([M.R_a M.L_a]), 'Kt', nr(M.k), 'J', nr(Q.J), 'Bm', nr(M.F_v), 'Tf', nr(M.T_f0), ...
     'w0', '0', 'MeasurementBus', 'on');
c('Cdc/l1', 'Ihb_m/l1');
c('Ihb_m/r1', 'SA_sus/l1');  c('Ihb_m/r1', 'SB_sus/l1');
c('SA_sus/r1', 'SA_jos/l1');  c('SB_sus/r1', 'SB_jos/l1');
c('SA_jos/r1', 'Masa/l1');  c('SB_jos/r1', 'Masa/l1');
c('SA_sus/r1', 'Masina/l1');  c('SB_sus/r1', 'Masina/r1');
% --- celelalte două motoare: sursă de curent = 2 × curentul punții H ---
bloc(mdl, 'I2mot_m', L.masura_I, [800 380 830 410]);
bloc(mdl, 'I2mot', L.sursa_I, [860 420 890 460], 'Initialize', 'off', 'Measurements', 'None');
bloc(mdl, 'Ihb_z', L.intarziere, [1100 300 1130 330], 'SampleTime', nr(Ts), 'InitialCondition', '0');
bloc(mdl, 'Doi', L.castig, [1160 300 1200 330], 'Gain', '2');
c('Cdc/l1', 'I2mot_m/l1');
if ~inversat
    c('I2mot_m/r1', 'I2mot/l1');  c('I2mot/r1', 'Masa/l1');
else
    c('I2mot_m/r1', 'I2mot/r1');  c('I2mot/l1', 'Masa/l1');
end
c('Ihb_m/o1', 'Ihb_z/i1');  c('Ihb_z/o1', 'Doi/i1');  c('Doi/o1', 'I2mot/i1');
% compensarea puterii sarcinii în DC-DC: P_ff = u_dc * 3 * i_punte (filtrat)
bloc(mdl, 'Trei', L.castig, [1160 350 1200 380], 'Gain', '3');
bloc(mdl, 'ProdPff', L.produs, [1230 340 1260 380], 'Inputs', '**');
bloc(mdl, 'FiltruPff', L.filtru, [1290 345 1350 375], 'Numerator', '1', 'Denominator', '[2e-4 1]');
c('Ihb_z/o1', 'Trei/i1');  c('Trei/o1', 'ProdPff/i1');  c('Udc_z/o1', 'ProdPff/i2');
c('ProdPff/o1', 'FiltruPff/i1');  c('FiltruPff/o1', 'Pff/i1');

% --- măsuri de la mașină ---
bloc(mdl, 'Selector', L.selector, [1060 150 1065 210], 'OutputSignals', 'iA,w,Te');
bloc(mdl, 'w_z', L.intarziere, [1100 170 1130 200], 'SampleTime', nr(Ts), 'InitialCondition', '0');
bloc(mdl, 'iA_z', L.intarziere, [1100 130 1130 160], 'SampleTime', nr(Ts), 'InitialCondition', '0');
c('Masina/o1', 'Selector/i1');  c('Selector/o1', 'iA_z/i1');  c('Selector/o2', 'w_z/i1');
% --- cuplul de sarcină al vehiculului: a0*sign(w) + a2*w^2 ---
bloc(mdl, 'SgnW', L.semn, [1160 420 1190 450], 'ZeroCross', 'off');
bloc(mdl, 'a0', L.castig, [1210 420 1250 450], 'Gain', nr(Q.a0));
bloc(mdl, 'W2', L.produs, [1160 470 1190 500], 'Inputs', '**');
bloc(mdl, 'a2', L.castig, [1210 470 1250 500], 'Gain', nr(Q.a2));
bloc(mdl, 'SumTL', L.suma, [1280 430 1300 490], 'Inputs', '++-');
c('w_z/o1', 'SgnW/i1');  c('SgnW/o1', 'a0/i1');  c('w_z/o1', 'W2/i1');  c('w_z/o1', 'W2/i2');  c('W2/o1', 'a2/i1');
c('a0/o1', 'SumTL/i1');  c('a2/o1', 'SumTL/i2');  c('SumTL/o1', 'Masina/i1');   % i3 (frâna mecanică): mai jos

% --- ciclul de viteză și regulatorul de viteză ---
bloc(mdl, 'Ceas', L.ceas, [1380 40 1410 70]);
bloc(mdl, 'W_ref', L.tabel, [1440 40 1500 70], 'Table', nr([0 W1 W1 0 0]), ...
     'BreakpointsForDimension1', nr([0 t1 t2 t3 t_end]));
bloc(mdl, 'SumEw', L.suma, [1530 40 1550 90], 'Inputs', '+-');
% PI de viteză: T_u = Kp_w*e + Ki_w*∫e, cu integrare condiționată (ca în derivata_mcc.m): se integrează
% când T_ref = T_u sau când eroarea scoate regulatorul din limitare
bloc(mdl, 'KpW', L.castig, [1580 20 1620 40], 'Gain', nr(Kp_w));
bloc(mdl, 'PoartaAW', L.functie, [1580 300 1700 320], 'Expr', ...
     '(u(1)==u(2)) + (u(1)>u(2))*(u(3)<0) + (u(1)<u(2))*(u(3)>0)');
bloc(mdl, 'MuxAW', L.mux, [1540 290 1545 330], 'Inputs', '3');
bloc(mdl, 'ProdAW', L.produs, [1720 300 1750 330], 'Inputs', '**');
bloc(mdl, 'IntW', L.integrator, [1580 60 1610 90], 'InitialCondition', '0');
bloc(mdl, 'KiW', L.castig, [1620 60 1650 90], 'Gain', nr(Ki_w));
bloc(mdl, 'PI_W', L.suma, [1660 40 1670 90], 'Inputs', '++');
bloc(mdl, 'Eps', L.constanta, [1380 120 1410 140], 'Value', '1e-6');
bloc(mdl, 'MaxW', L.minmax, [1440 110 1470 150], 'Function', 'max', 'Inputs', '2');
bloc(mdl, 'Pmax', L.constanta, [1440 160 1480 180], 'Value', nr(T.P_lim_motor));
bloc(mdl, 'PperW', L.produs, [1500 130 1530 180], 'Inputs', '*/');
bloc(mdl, 'Tlim0', L.constanta, [1500 200 1540 220], 'Value', nr(min(T_ad, M.M_max)));
bloc(mdl, 'Tl', L.minmax, [1570 140 1600 210], 'Function', 'min', 'Inputs', '2');
bloc(mdl, 'Zero', L.constanta, [1500 240 1530 260], 'Value', '0');
bloc(mdl, 'Wpoz', L.relational, [1570 230 1600 260], 'Operator', '>');
bloc(mdl, 'Wpoz_d', L.conversie, [1620 230 1660 260], 'OutDataTypeStr', 'double');
bloc(mdl, 'Tlfr', L.produs, [1690 210 1720 250], 'Inputs', '**');
bloc(mdl, 'MinusTlfr', L.castig, [1740 215 1780 245], 'Gain', '-1');
bloc(mdl, 'MinT', L.minmax, [1680 60 1710 110], 'Function', 'min', 'Inputs', '2');
bloc(mdl, 'Tref', L.minmax, [1740 70 1770 130], 'Function', 'max', 'Inputs', '2');
c('Ceas/o1', 'W_ref/i1');  c('W_ref/o1', 'SumEw/i1');  c('w_z/o1', 'SumEw/i2');
c('SumEw/o1', 'KpW/i1');  c('KpW/o1', 'PI_W/i1');  c('IntW/o1', 'KiW/i1');  c('KiW/o1', 'PI_W/i2');
c('PI_W/o1', 'MuxAW/i1');  c('Tref/o1', 'MuxAW/i2');  c('SumEw/o1', 'MuxAW/i3');  c('MuxAW/o1', 'PoartaAW/i1');
c('PoartaAW/o1', 'ProdAW/i1');  c('SumEw/o1', 'ProdAW/i2');  c('ProdAW/o1', 'IntW/i1');
c('w_z/o1', 'MaxW/i1');  c('Eps/o1', 'MaxW/i2');  c('Pmax/o1', 'PperW/i1');  c('MaxW/o1', 'PperW/i2');
c('PperW/o1', 'Tl/i1');  c('Tlim0/o1', 'Tl/i2');
c('w_z/o1', 'Wpoz/i1');  c('Zero/o1', 'Wpoz/i2');  c('Wpoz/o1', 'Wpoz_d/i1');
c('Tl/o1', 'Tlfr/i1');  c('Wpoz_d/o1', 'Tlfr/i2');  c('Tlfr/o1', 'MinusTlfr/i1');
c('PI_W/o1', 'MinT/i1');  c('Tl/o1', 'MinT/i2');  c('MinT/o1', 'Tref/i1');  c('MinusTlfr/o1', 'Tref/i2');
% --- limita cuplului de recuperare și frâna mecanică ---
bloc(mdl, 'mTrec', L.constanta, [1740 160 1790 180], 'Value', nr(-T.T_rec_max));
bloc(mdl, 'Tel', L.minmax, [1800 150 1830 190], 'Function', 'max', 'Inputs', '2');
bloc(mdl, 'Tfm', L.suma, [1800 200 1820 240], 'Inputs', '+-');
c('Tref/o1', 'Tel/i1');  c('mTrec/o1', 'Tel/i2');  c('Tref/o1', 'Tfm/i1');  c('Tel/o1', 'Tfm/i2');
c('Tfm/o1', 'SumTL/i3');                         % cuplul frânei mecanice se adaugă la sarcina mașinii
% --- curentul de referință și regulatorul de curent ---
bloc(mdl, 'Tf0', L.castig, [1210 520 1250 550], 'Gain', nr(M.T_f0));
bloc(mdl, 'Fv', L.castig, [1210 560 1250 590], 'Gain', nr(M.F_v));
bloc(mdl, 'SumTE', L.suma, [1800 80 1820 160], 'Inputs', '+++');
bloc(mdl, 'Div_k', L.castig, [1850 105 1890 135], 'Gain', nr(1 / M.k));
bloc(mdl, 'SumEi', L.suma, [1920 100 1940 150], 'Inputs', '+-');
bloc(mdl, 'PI_I', L.pid, [1970 105 2030 145], 'Controller', 'PI', 'P', nr(Kp_i), 'I', nr(Ki_i), ...
     'LimitOutput', 'on', 'UpperSaturationLimit', nr(M.U_n), 'LowerSaturationLimit', nr(-M.U_n), ...
     'AntiWindupMode', 'clamping');
bloc(mdl, 'DivM', L.produs, [2060 110 2090 150], 'Inputs', '*/');
bloc(mdl, 'SatM', L.saturatie, [2110 115 2150 145], 'UpperLimit', '1', 'LowerLimit', '-1');
bloc(mdl, 'MinusM', L.castig, [2180 160 2220 190], 'Gain', '-1');
bloc(mdl, 'Purt_HB', L.functie, [2060 200 2180 220], 'Expr', ...
     sprintf('2*(1-abs(2*(u*%s-floor(u*%s))-1))-1', nr(H.f_pwm), nr(H.f_pwm)));
bloc(mdl, 'CompA', L.relational, [2250 110 2280 150], 'Operator', '>');
bloc(mdl, 'CompB', L.relational, [2250 170 2280 210], 'Operator', '>');
bloc(mdl, 'NotA', L.logic, [2310 130 2340 150], 'Operator', 'NOT');
bloc(mdl, 'NotB', L.logic, [2310 190 2340 210], 'Operator', 'NOT');
c('SgnW/o1', 'Tf0/i1');  c('w_z/o1', 'Fv/i1');
c('Tel/o1', 'SumTE/i1');  c('Tf0/o1', 'SumTE/i2');  c('Fv/o1', 'SumTE/i3');  c('SumTE/o1', 'Div_k/i1');
c('Div_k/o1', 'SumEi/i1');  c('iA_z/o1', 'SumEi/i2');  c('SumEi/o1', 'PI_I/i1');
c('PI_I/o1', 'DivM/i1');  c('Udc_z/o1', 'DivM/i2');  c('DivM/o1', 'SatM/i1');  c('SatM/o1', 'MinusM/i1');
c('Ceas_PWM/o1', 'Purt_HB/i1');
c('SatM/o1', 'CompA/i1');  c('Purt_HB/o1', 'CompA/i2');  c('MinusM/o1', 'CompB/i1');  c('Purt_HB/o1', 'CompB/i2');
c('CompA/o1', 'SA_sus/i1');  c('CompA/o1', 'NotA/i1');  c('NotA/o1', 'SA_jos/i1');
c('CompB/o1', 'SB_sus/i1');  c('CompB/o1', 'NotB/i1');  c('NotB/o1', 'SB_jos/i1');
% --- ieșiri ---
nume = {'Selector/o2', 'sps_w'; 'Selector/o1', 'sps_iA'; 'Selector/o3', 'sps_Te'; 'Udc_m/o1', 'sps_Udc';
        'Ibat_m/o1', 'sps_Ibat'; 'Ubat_m/o1', 'sps_Ubat'; 'W_ref/o1', 'sps_Wref'; 'Tref/o1', 'sps_Tref';
        'I2mot_m/o1', 'sps_I2mot'; 'Tfm/o1', 'sps_Tfm'};
for q = 1:size(nume, 1)
    spre_workspace(mdl, ['W_' nume{q, 2}], nume{q, 2}, [2400 40 * q 2470 40 * q + 20], dec);
    c(nume{q, 1}, ['W_' nume{q, 2} '/i1']);
end
bloc(mdl, 'Scope', L.scope, [2400 420 2430 500], 'NumInputPorts', '3');
c('Selector/o2', 'Scope/i1');  c('Selector/o1', 'Scope/i2');  c('Udc_m/o1', 'Scope/i3');

set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', nr(Ts), 'StopTime', nr(t_end), ...
          'ReturnWorkspaceOutputs', 'on');
fisier = fullfile(P.dir_modele, [mdl '.slx']);
save_system(mdl, fisier);
out = simuleaza(mdl);
[t, w] = citeste(out, 'sps_w');  [~, iA] = citeste(out, 'sps_iA');  [~, Te] = citeste(out, 'sps_Te');
[~, Udc] = citeste(out, 'sps_Udc');  [~, Ib] = citeste(out, 'sps_Ibat');  [~, Ub] = citeste(out, 'sps_Ubat');
[~, Wr] = citeste(out, 'sps_Wref');  [~, I2] = citeste(out, 'sps_I2mot');  [~, Tfm] = citeste(out, 'sps_Tfm');
% polaritatea sursei care reprezintă celelalte două motoare (trebuie să absoarbă curent la accelerare)
macc = t > 0.5 * t1 & t < t1;
if mean(I2(macc)) < 0 && ~inversat
    fprintf(2, 'Sursa de curent a celorlalte motoare a fost legată invers – modelul se reconstruiește.\n');
    close_system(mdl, 0);
    rez = model_sps_ansamblu(P, t_palier, Ts, true);
    return;
end
% referința MATLAB (model mediu) pe același ciclu
S2 = S;  S2.ip.simulare.C_t_palier = t_palier;
Cm = simulare_ansamblu(S2, M, T);
v = w * r / k_rd;  v_ref = Wr * r / k_rd;
Tax = Te - M.T_f0 * sign(w) - M.F_v * w;
P_ax = T.N * Tax .* w;
P_chim = S.B.U_nom * Ib;                         % puterea cedată de celule (U_0 * I_bat)
P_fm = T.N * Tfm .* w;                           % puterea disipată în frânele mecanice (<= 0)
k1 = find(v >= (1 - 1e-3) * R3.V1, 1);           % fazele după viteza reală, ca în simulare_ansamblu.m
if isempty(k1), t_acc = t1; else, t_acc = t(k1); end
faze = {'acc', 0, t_acc; 'palier', t_acc, t2; 'franare', t2, t_end};
rez.t_acc = t_acc;  rez.t_acc_ref = Cm.t_acc;
rez.model = mdl;  rez.fisier = fisier;  rez.t_palier = t_palier;  rez.sursa_inversata = inversat;
rez.eroare_v_max = max(abs(v - v_ref));          rez.eroare_v_max_ref = Cm.eroare_v_max;
for q = 1:3
    m = t >= faze{q, 2} & t <= faze{q, 3};
    rez.E.(faze{q, 1}) = struct('ax', trapz(t(m), P_ax(m)), 'bat', trapz(t(m), P_chim(m)), ...
                                'fm', trapz(t(m), P_fm(m)));
    rez.E_ref.(faze{q, 1}) = struct('ax', Cm.E.(faze{q, 1}).ax, 'bat', Cm.E.(faze{q, 1}).bat, ...
                                    'fm', Cm.E.(faze{q, 1}).fm);
end
rez.E_bat_total = trapz(t, P_chim);              rez.E_bat_total_ref = Cm.E.total_bat;
rez.I_bat_max = max(Ib);   rez.I_bat_min = min(Ib);   rez.I_bat_max_ref = Cm.I_bat_max;  rez.I_bat_min_ref = Cm.I_bat_min;
rez.U_dc_min = min(Udc);   rez.U_dc_max = max(Udc);
fprintf('Ansamblu (SPS): eroarea maximă de viteză %.2f km/h (MATLAB %.2f); I_bat %.0f…%.0f A (MATLAB %.0f…%.0f)\n', ...
        3.6 * rez.eroare_v_max, 3.6 * Cm.eroare_v_max, rez.I_bat_min, rez.I_bat_max, Cm.I_bat_min, Cm.I_bat_max);
fprintf('                energia din baterie %.1f kJ (MATLAB, model mediu %.1f kJ); U_dc %.0f…%.0f V\n', ...
        rez.E_bat_total / 1e3, Cm.E.total_bat / 1e3, rez.U_dc_min, rez.U_dc_max);
fprintf('                t_acc %.3f s (MATLAB %.3f s); frâna mecanică %.1f kJ (MATLAB %.1f kJ)\n', ...
        rez.t_acc, Cm.t_acc, -rez.E.franare.fm / 1e3, -Cm.E.franare.fm / 1e3);
fig = figure('Name', 'Ansamblu (SPS)', 'Visible', 'off');
subplot(4, 1, 1); plot(t, v * 3.6, t, v_ref * 3.6, '--', Cm.t, Cm.v * 3.6, ':'); grid on; ylabel('v [km/h]');
legend('SPS', 'referință', 'MATLAB (mediu)');
subplot(4, 1, 2); plot(t, iA, Cm.t, Cm.I, ':'); grid on; ylabel('i_A [A]');
subplot(4, 1, 3); plot(t, Ib, Cm.t, Cm.I_bat, ':'); grid on; ylabel('I_{bat} [A]');
subplot(4, 1, 4); plot(t, Udc); grid on; ylabel('U_{dc} [V]'); xlabel('t [s]');
rez.figura = fullfile(P.dir_rezultate, [mdl '.png']);
salveaza_figura(fig, rez.figura);
end
