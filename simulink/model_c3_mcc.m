function rez = model_c3_mcc(scenariu, P, Z)
%MODEL_C3_MCC Curs C3, exercițiul 2: modelul mașinii electrice (ecuațiile MCC) în Simulink, cu calculul
%   cuplului la ax, construit din blocuri Simulink de bază (fără Simscape):
%     L*dI/dt = U - Ra*I - dUp*sign(I) - k*phi*W,   T_E = k*phi*I,   T_ax = T_E - Tf0*sign(W) - Fv*W,
%     J*dW/dt = T_ax - (a0*sign(W) + a2*W^2 + treaptă de sarcină),   phi = min(1, W_b/W)  (slăbire de câmp)
%   scenariu 'A' – pornire în gol la U_p (curentul de pornire limitat la I_max), apoi treaptă de sarcină M_n
%   scenariu 'D' – rampă de tensiune 0 -> U_n cu sarcina vehiculului (1/3 din vehicul pe motor)
%   Rezolvitor cu pas fix ode4 (Runge-Kutta 4), același algoritm ca rk4.m; rezultatul se compară cu
%   simularea MATLAB (simulari.m).  P = PARAMETRI_SIMULINK(), Z = SIMULARI(...) – opționale.
if nargin < 1, scenariu = 'D'; end
if nargin < 2 || isempty(P), P = parametri_simulink(); end
if nargin < 3 || isempty(Z), Z = simulari(P.S, P.M, P.T); end
M = P.M;  sp = P.S.ip.simulare;  L = biblioteci();
switch upper(scenariu)
    case 'A'
        Q = P.gol;  U0 = M.U_p;  panta = 0;  t_end = sp.A_t_end;  dt = sp.A_dt;  dec = sp.A_salvare;
        t_tr = sp.A_t_treapta;  M_tr = sp.A_M_treapta;
    case 'D'
        Q = P.veh;  U0 = sp.D_U0;  panta = sp.D_panta;  t_end = sp.D_t_end;  dt = sp.D_dt;  dec = sp.D_salvare;
        t_tr = 0;  M_tr = 0;
    otherwise
        error('Scenariul trebuie să fie ''A'' sau ''D''.');
end
mdl = model_nou(['cca_c3_mcc_' upper(scenariu)]);

% --- tensiunea: U = sat(U0 + panta*t, 0, U_n) ---
bloc(mdl, 'Ceas',  L.ceas,      [20 40 50 70]);
bloc(mdl, 'Panta', L.castig,    [80 40 120 70],  'Gain', nr(panta));
bloc(mdl, 'U0',    L.constanta, [80 90 120 120], 'Value', nr(U0));
bloc(mdl, 'SumU',  L.suma,      [150 55 170 105], 'Inputs', '++');
bloc(mdl, 'SatU',  L.saturatie, [200 65 240 95], 'UpperLimit', nr(M.U_n), 'LowerLimit', '0');
% --- indusul: dI/dt = (U - Ra*I - dUp*sign(I) - E)/L ---
bloc(mdl, 'SumArm', L.suma,       [280 50 300 150], 'Inputs', '+---');
bloc(mdl, 'InvL',   L.castig,     [330 85 370 115], 'Gain', nr(1 / Q.L));
bloc(mdl, 'Int_I',  L.integrator, [400 85 430 115], 'InitialCondition', '0');
bloc(mdl, 'Ra',     L.castig,     [400 160 440 190], 'Gain', nr(Q.R), 'Orientation', 'left');
bloc(mdl, 'SgnI',   L.semn,       [470 210 500 240], 'ZeroCross', 'off', 'Orientation', 'left');
bloc(mdl, 'dUp',    L.castig,     [400 210 440 240], 'Gain', nr(Q.dUp), 'Orientation', 'left');
% --- fluxul: phi = min(1, W_b / max(W, eps)) ---
bloc(mdl, 'Eps',    L.constanta,  [520 330 550 350], 'Value', '1e-6');
bloc(mdl, 'MaxW',   L.minmax,     [580 300 610 340], 'Function', 'max', 'Inputs', '2');
bloc(mdl, 'Wb',     L.constanta,  [580 250 620 270], 'Value', nr(Q.W_b));
bloc(mdl, 'Div',    L.produs,     [650 260 680 330], 'Inputs', '*/');
bloc(mdl, 'Unu',    L.constanta,  [650 220 680 240], 'Value', '1');
bloc(mdl, 'MinPhi', L.minmax,     [710 230 740 300], 'Function', 'min', 'Inputs', '2');
bloc(mdl, 'k',      L.castig,     [770 250 810 280], 'Gain', nr(Q.k));
bloc(mdl, 'ProdE',  L.produs,     [850 330 880 380], 'Inputs', '**');
bloc(mdl, 'ProdTE', L.produs,     [850 80 880 130],  'Inputs', '**');
% --- partea mecanică: T_ax = T_E - Tf0*sign(W) - Fv*W;  dW/dt = (T_ax - T_sarcina)/J ---
bloc(mdl, 'SumTax',  L.suma,       [920 70 940 150],  'Inputs', '+--');
bloc(mdl, 'SumMec',  L.suma,       [980 80 1000 130], 'Inputs', '+-');
bloc(mdl, 'InvJ',    L.castig,     [1030 90 1070 120], 'Gain', nr(1 / Q.J));
bloc(mdl, 'Int_W',   L.integrator, [1100 90 1130 120], 'InitialCondition', '0', 'LimitOutput', 'on', ...
     'LowerSaturationLimit', '0');
bloc(mdl, 'SgnW',    L.semn,       [1100 180 1130 210], 'ZeroCross', 'off', 'Orientation', 'left');
bloc(mdl, 'Tf0',     L.castig,     [1040 180 1080 210], 'Gain', nr(Q.Tf0), 'Orientation', 'left');
bloc(mdl, 'Fv',      L.castig,     [1040 230 1080 260], 'Gain', nr(Q.Fv), 'Orientation', 'left');
bloc(mdl, 'a0',      L.castig,     [1040 280 1080 310], 'Gain', nr(Q.a0), 'Orientation', 'left');
bloc(mdl, 'W2',      L.produs,     [1100 330 1130 370], 'Inputs', '**', 'Orientation', 'left');
bloc(mdl, 'a2',      L.castig,     [1040 335 1080 365], 'Gain', nr(Q.a2), 'Orientation', 'left');
bloc(mdl, 'Treapta', L.treapta,    [1100 400 1130 430], 'Time', nr(t_tr), 'Before', '0', 'After', nr(M_tr), ...
     'Orientation', 'left');
bloc(mdl, 'SumSarc', L.suma,       [990 280 1010 430], 'Inputs', '+++', 'Orientation', 'left');
% --- ieșiri ---
spre_workspace(mdl, 'Out_I',   'sim_I',   [470 20 540 40],    dec);
spre_workspace(mdl, 'Out_W',   'sim_W',   [1170 20 1240 40],  dec);
spre_workspace(mdl, 'Out_U',   'sim_U',   [250 10 320 30],    dec);
spre_workspace(mdl, 'Out_Tax', 'sim_Tax', [960 10 1030 30],   dec);
bloc(mdl, 'Scope', L.scope, [1180 140 1210 220], 'NumInputPorts', '3');
% --- conexiuni ---
c = @(a, b) leaga(mdl, a, b);
c('Ceas/o1', 'Panta/i1');   c('Panta/o1', 'SumU/i1');   c('U0/o1', 'SumU/i2');   c('SumU/o1', 'SatU/i1');
c('SatU/o1', 'SumArm/i1');  c('SatU/o1', 'Out_U/i1');
c('SumArm/o1', 'InvL/i1');  c('InvL/o1', 'Int_I/i1');
c('Int_I/o1', 'Ra/i1');     c('Ra/o1', 'SumArm/i2');
c('Int_I/o1', 'SgnI/i1');   c('SgnI/o1', 'dUp/i1');    c('dUp/o1', 'SumArm/i3');
c('ProdE/o1', 'SumArm/i4');
c('Int_W/o1', 'MaxW/i1');   c('Eps/o1', 'MaxW/i2');
c('Wb/o1', 'Div/i1');       c('MaxW/o1', 'Div/i2');
c('Unu/o1', 'MinPhi/i1');   c('Div/o1', 'MinPhi/i2');  c('MinPhi/o1', 'k/i1');
c('k/o1', 'ProdE/i1');      c('Int_W/o1', 'ProdE/i2');
c('k/o1', 'ProdTE/i1');     c('Int_I/o1', 'ProdTE/i2');
c('ProdTE/o1', 'SumTax/i1');
c('Int_W/o1', 'SgnW/i1');   c('SgnW/o1', 'Tf0/i1');    c('Tf0/o1', 'SumTax/i2');
c('Int_W/o1', 'Fv/i1');     c('Fv/o1', 'SumTax/i3');
c('SumTax/o1', 'SumMec/i1');
c('SgnW/o1', 'a0/i1');      c('a0/o1', 'SumSarc/i1');
c('Int_W/o1', 'W2/i1');     c('Int_W/o1', 'W2/i2');    c('W2/o1', 'a2/i1');     c('a2/o1', 'SumSarc/i2');
c('Treapta/o1', 'SumSarc/i3');
c('SumSarc/o1', 'SumMec/i2');
c('SumMec/o1', 'InvJ/i1');  c('InvJ/o1', 'Int_W/i1');
c('Int_I/o1', 'Out_I/i1');  c('Int_W/o1', 'Out_W/i1');  c('SumTax/o1', 'Out_Tax/i1');
c('Int_I/o1', 'Scope/i1');  c('Int_W/o1', 'Scope/i2');  c('SumTax/o1', 'Scope/i3');

% --- configurație: pas fix, Runge-Kutta 4 (ode4), ca în rk4.m ---
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', nr(dt), 'StopTime', nr(t_end), ...
          'ReturnWorkspaceOutputs', 'on');
fisier = fullfile(P.dir_modele, [mdl '.slx']);
save_system(mdl, fisier);

% --- simulare și comparație cu simulari.m ---
out = simuleaza(mdl);
[t, I] = citeste(out, 'sim_I');  [~, W] = citeste(out, 'sim_W');  [~, Tax] = citeste(out, 'sim_Tax');
ref = Z.(upper(scenariu));
rez.model = mdl;  rez.fisier = fisier;  rez.t = t;  rez.I = I;  rez.W = W;  rez.T_ax = Tax;
rez.dif_W_rel = max(abs(interp1(ref.t, ref.W, t, 'linear', 'extrap') - W)) / max(abs(ref.W));
rez.dif_I_rel = max(abs(interp1(ref.t, ref.I, t, 'linear', 'extrap') - I)) / max(abs(ref.I));
rez.W_final = W(end);  rez.W_final_ref = ref.W(end);
rez.I_varf = max(I);   rez.I_varf_ref = max(ref.I);
fprintf('C3 / scenariul %s: abaterea maximă Simulink - rk4.m: W %.2e, I %.2e (relativ)\n', upper(scenariu), ...
        rez.dif_W_rel, rez.dif_I_rel);
fig = figure('Name', ['C3 – modelul MCC, scenariul ' upper(scenariu)], 'Visible', 'off');
subplot(3, 1, 1); plot(t, I, ref.t, ref.I, '--'); grid on; ylabel('I [A]'); legend('Simulink', 'rk4.m');
subplot(3, 1, 2); plot(t, W * 60 / (2*pi), ref.t, ref.W * 60 / (2*pi), '--'); grid on; ylabel('n [rot/min]');
subplot(3, 1, 3); plot(t, Tax, ref.t, ref.T_ax, '--'); grid on; ylabel('T_{ax} [Nm]'); xlabel('t [s]');
rez.figura = fullfile(P.dir_rezultate, [mdl '.png']);
salveaza_figura(fig, rez.figura);
end
