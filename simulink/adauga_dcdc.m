function adauga_dcdc(mdl, P, U_bat0, Ts)
%ADAUGA_DCDC Adaugă în modelul MDL bateria și convertorul DC-DC bidirecțional cu N faze intercalate
%   (Specialized Power Systems), cu reglarea în cascadă din sim_dcdc_comutatie.m:
%     baterie: sursă U_bat0 + R_bat;  fiecare fază: bobină L -> semipunte cu 2 MOSFET (jos: la masă,
%     sus: la U_dc), comandă complementară;  condensatorul circuitului intermediar C (U inițială = U_dc).
%     PI de tensiune -> i_c;  i_ref = (P_ff + u_dc*i_c)/U_bat, limitat la ±1,2*I_bat_max;
%     PI de curent pe fază -> v;  d = 1 - (U_bat - v)/u_dc, limitat la [0, 1];
%     PWM: purtătoare triunghiulară 0..1 defazată cu (q-1)/N perioade, s_q = d > purtătoare.
%   Nodurile pentru sarcină: + = 'Cdc/l1', masa = 'Masa/l1'.  Intrarea de semnal 'Pff/i1' primește
%   puterea absorbită de sarcină (compensare), ieșirile de măsură: 'Udc_m/o1', 'Ibat_m/o1', 'Ubat_m/o1'.
L = biblioteci();  D = P.D;  N = D.N_faze;  sc = P.S.cv.simulare.dcdc;  md = P.S.cv.dcdc.modul;
c = @(a, b) leaga(mdl, a, b);
wci = 2 * pi * sc.fc_I_Hz;  Kpi = D.L * wci;  Kii = Kpi * wci / 10;
wcu = 2 * pi * sc.fc_U_Hz;  Kpu = D.C * wcu;  Kiu = Kpu * wcu / 5;
Imax = 1.2 * D.I_bat_max;
mos = {'Ron', nr(md.R_DS_on_cald_mOhm * 1e-3), 'Lon', '0', 'Rd', '1e-3', 'Vfd', '0', 'IC', '0', ...
       'Rs', '1e5', 'Cs', 'inf', 'Measurements', 'off'};

% --- partea de putere ---
bloc(mdl, 'Ubat', L.sursa_dc, [40 300 70 340], 'Amplitude', nr(U_bat0));
bloc(mdl, 'Rbat', L.rlc, [100 250 140 270], 'BranchType', 'R', 'Resistance', nr(D.R_bat));
bloc(mdl, 'Ibat_m', L.masura_I, [170 245 200 275]);
bloc(mdl, 'Ubat_m', L.masura_U, [230 330 260 360]);
bloc(mdl, 'Masa', L.masa, [40 560 70 590]);
c('Ubat/r1', 'Rbat/l1');  c('Rbat/r1', 'Ibat_m/l1');  c('Ubat/l1', 'Masa/l1');
c('Ibat_m/r1', 'Ubat_m/l1');  c('Ubat_m/l2', 'Masa/l1');
bloc(mdl, 'Cdc', L.rlc, [700 300 740 320], 'BranchType', 'C', 'Capacitance', nr(D.C), 'Setx0', 'on', ...
     'InitialVoltage', nr(D.U_dc), 'Orientation', 'down');
bloc(mdl, 'Udc_m', L.masura_U, [760 330 790 360]);
c('Cdc/r1', 'Masa/l1');  c('Cdc/l1', 'Udc_m/l1');  c('Udc_m/l2', 'Masa/l1');
for q = 1:N
    y = 220 + 90 * (q - 1);
    f = sprintf('%d', q);
    bloc(mdl, ['L' f], L.rlc, [300 y 340 y + 20], 'BranchType', 'RL', 'Resistance', '1e-4', ...
         'Inductance', nr(D.L));
    bloc(mdl, ['IL' f '_m'], L.masura_I, [370 y - 5 400 y + 25]);
    bloc(mdl, ['Sjos' f], L.mosfet, [450 y + 30 480 y + 60], mos{:});
    bloc(mdl, ['Ssus' f], L.mosfet, [450 y - 40 480 y - 10], mos{:});
    c('Ibat_m/r1', ['L' f '/l1']);  c(['L' f '/r1'], ['IL' f '_m/l1']);
    c(['IL' f '_m/r1'], ['Sjos' f '/l1']);  c(['Sjos' f '/r1'], 'Masa/l1');          % drena jos = mijloc
    c(['IL' f '_m/r1'], ['Ssus' f '/r1']);  c(['Ssus' f '/l1'], 'Cdc/l1');           % sursa sus = mijloc
end

% --- măsuri întârziate cu un pas (evită buclele algebrice în modul discret) ---
bloc(mdl, 'Udc_z', L.intarziere, [820 440 850 470], 'SampleTime', nr(Ts), 'InitialCondition', nr(D.U_dc));
bloc(mdl, 'Ubat_z', L.intarziere, [820 480 850 510], 'SampleTime', nr(Ts), 'InitialCondition', nr(U_bat0));
c('Udc_m/o1', 'Udc_z/i1');  c('Ubat_m/o1', 'Ubat_z/i1');

% --- regulatorul de tensiune și curentul de referință ---
bloc(mdl, 'Udc_ref', L.constanta, [880 520 920 540], 'Value', nr(D.U_dc));
bloc(mdl, 'SumEu', L.suma, [950 520 970 560], 'Inputs', '+-');
bloc(mdl, 'PI_U', L.pid, [1000 520 1060 560], 'Controller', 'PI', 'P', nr(Kpu), 'I', nr(Kiu));
bloc(mdl, 'Pff', L.castig, [1000 600 1040 630], 'Gain', '1');
bloc(mdl, 'ProdUic', L.produs, [1090 520 1120 560], 'Inputs', '**');
bloc(mdl, 'SumP', L.suma, [1150 540 1170 600], 'Inputs', '++');
bloc(mdl, 'DivUb', L.produs, [1200 550 1230 590], 'Inputs', '*/');
bloc(mdl, 'SatIref', L.saturatie, [1260 555 1300 585], 'UpperLimit', nr(Imax), 'LowerLimit', nr(-Imax));
bloc(mdl, 'Iref_faza', L.castig, [1330 555 1370 585], 'Gain', nr(1 / N));
c('Udc_ref/o1', 'SumEu/i1');  c('Udc_z/o1', 'SumEu/i2');  c('SumEu/o1', 'PI_U/i1');
c('PI_U/o1', 'ProdUic/i1');  c('Udc_z/o1', 'ProdUic/i2');
c('ProdUic/o1', 'SumP/i1');  c('Pff/o1', 'SumP/i2');
c('SumP/o1', 'DivUb/i1');  c('Ubat_z/o1', 'DivUb/i2');  c('DivUb/o1', 'SatIref/i1');  c('SatIref/o1', 'Iref_faza/i1');
bloc(mdl, 'Ceas_PWM', L.ceas, [880 660 910 690]);
% --- pe fiecare fază: PI de curent, factorul de umplere, PWM ---
for q = 1:N
    y = 720 + 70 * (q - 1);
    f = sprintf('%d', q);
    bloc(mdl, ['IL' f '_z'], L.intarziere, [880 y 910 y + 30], 'SampleTime', nr(Ts), 'InitialCondition', '0');
    bloc(mdl, ['SumEi' f], L.suma, [940 y 960 y + 30], 'Inputs', '+-');
    bloc(mdl, ['PI_I' f], L.pid, [990 y 1050 y + 30], 'Controller', 'PI', 'P', nr(Kpi), 'I', nr(Kii));
    bloc(mdl, ['SumV' f], L.suma, [1080 y 1100 y + 30], 'Inputs', '+-');       % U_bat - v
    bloc(mdl, ['DivD' f], L.produs, [1130 y 1160 y + 30], 'Inputs', '*/');      % (U_bat - v)/u_dc
    bloc(mdl, ['Unu' f], L.constanta, [1130 y + 35 1160 y + 50], 'Value', '1');
    bloc(mdl, ['SumD' f], L.suma, [1190 y 1210 y + 40], 'Inputs', '+-');       % d = 1 - (...)
    bloc(mdl, ['SatD' f], L.saturatie, [1240 y 1280 y + 30], 'UpperLimit', '1', 'LowerLimit', '0');
    bloc(mdl, ['Purt' f], L.functie, [940 y + 40 1060 y + 60], 'Expr', ...
         sprintf('1-abs(2*(u*%s+%s-floor(u*%s+%s))-1)', nr(D.f_s), nr((q - 1) / N), nr(D.f_s), nr((q - 1) / N)));
    bloc(mdl, ['Comp' f], L.relational, [1310 y 1340 y + 40], 'Operator', '>');
    bloc(mdl, ['Not' f], L.logic, [1370 y + 25 1400 y + 45], 'Operator', 'NOT');
    c(['IL' f '_m/o1'], ['IL' f '_z/i1']);
    c('Iref_faza/o1', ['SumEi' f '/i1']);  c(['IL' f '_z/o1'], ['SumEi' f '/i2']);  c(['SumEi' f '/o1'], ['PI_I' f '/i1']);
    c('Ubat_z/o1', ['SumV' f '/i1']);  c(['PI_I' f '/o1'], ['SumV' f '/i2']);
    c(['SumV' f '/o1'], ['DivD' f '/i1']);  c('Udc_z/o1', ['DivD' f '/i2']);
    c(['Unu' f '/o1'], ['SumD' f '/i1']);  c(['DivD' f '/o1'], ['SumD' f '/i2']);  c(['SumD' f '/o1'], ['SatD' f '/i1']);
    c('Ceas_PWM/o1', ['Purt' f '/i1']);
    c(['SatD' f '/o1'], ['Comp' f '/i1']);  c(['Purt' f '/o1'], ['Comp' f '/i2']);
    c(['Comp' f '/o1'], ['Sjos' f '/i1']);  c(['Comp' f '/o1'], ['Not' f '/i1']);  c(['Not' f '/o1'], ['Ssus' f '/i1']);
end
end
