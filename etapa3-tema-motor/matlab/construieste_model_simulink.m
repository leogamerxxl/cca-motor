function rez = construieste_model_simulink(scenariu)
%CONSTRUIESTE_MODEL_SIMULINK Construiește și simulează în Simulink modelul mașinii (curs C3, exercițiul 2).
%   rez = construieste_model_simulink('A')  – pornire în gol la tensiunea U_p (fără vehicul)
%   rez = construieste_model_simulink('D')  – rampă de tensiune cu sarcina vehiculului (implicit)
%   Modelul (model_mcc_ym720.slx, salvat în ../rezultate) conține ecuațiile din C3:
%     L*dI/dt = U - Ra*I - dUp*sign(I) - k*phi*W,   T_E = k*phi*I,   T_ax = T_E - Tf0*sign(W) - Fv*W,
%     J*dW/dt = T_ax - (a0*sign(W) + a2*W^2),        phi = min(1, W_b/W)  (slăbire de câmp)
%   Se folosește rezolvitorul cu pas fix ode4 (Runge-Kutta 4), același algoritm ca în rk4.m, iar la final
%   rezultatul Simulink este comparat cu simularea din simulari.m.
%   Necesită MATLAB R2020a sau mai nou cu Simulink (fără Simscape). Nu a putut fi rulat aici (nu există
%   Simulink în GNU Octave); ecuațiile și parametrii sunt aceiași cu cei verificați în Octave.

if nargin < 1, scenariu = 'D'; end
S = incarca_date();  M = identificare_mcc(S.mot, S.ip);  T = tema_proiect(S, M);
sim_p = S.ip.simulare;
switch upper(scenariu)
    case 'A'
        P = parametri_model(S, M, T, 'gol');
        U0 = M.U_p;  panta = 0;  t_end = sim_p.A_t_end;  dt = sim_p.A_dt;  dec = sim_p.A_salvare;
    case 'D'
        P = parametri_model(S, M, T, 'vehicul');
        U0 = sim_p.D_U0;  panta = sim_p.D_panta;  t_end = sim_p.D_t_end;  dt = sim_p.D_dt;  dec = sim_p.D_salvare;
    otherwise
        error('Scenariul trebuie să fie ''A'' sau ''D''.');
end
nr = @(x) num2str(x, 16);                     % valorile se scriu direct în blocuri (funcția nu folosește base workspace)

mdl = 'model_mcc_ym720';
if bdIsLoaded(mdl), close_system(mdl, 0); end
new_system(mdl);
if usejava('desktop'), open_system(mdl); end

% --- sursa de tensiune: U = sat(U0 + panta*t, 0, U_n) ---
add_block('simulink/Sources/Clock',               [mdl '/Ceas'],   'Position', [20 40 50 70]);
add_block('simulink/Math Operations/Gain',        [mdl '/Panta'],  'Gain', nr(panta), 'Position', [80 40 120 70]);
add_block('simulink/Sources/Constant',            [mdl '/U0'],     'Value', nr(U0), 'Position', [80 90 120 120]);
add_block('simulink/Math Operations/Sum',         [mdl '/SumU'],   'Inputs', '++', 'Position', [150 55 170 105]);
add_block('simulink/Discontinuities/Saturation',  [mdl '/SatU'],   'UpperLimit', nr(M.U_n), 'LowerLimit', '0', ...
          'Position', [200 65 240 95]);

% --- circuitul indusului: dI/dt = (U - Ra*I - dUp*sign(I) - E)/L ---
add_block('simulink/Math Operations/Sum',         [mdl '/SumArm'], 'Inputs', '+---', 'Position', [280 50 300 150]);
add_block('simulink/Math Operations/Gain',        [mdl '/InvL'],   'Gain', nr(1 / P.L), 'Position', [330 85 370 115]);
add_block('simulink/Continuous/Integrator',       [mdl '/Int_I'],  'InitialCondition', '0', 'Position', [400 85 430 115]);
add_block('simulink/Math Operations/Gain',        [mdl '/Ra'],     'Gain', nr(P.R), 'Position', [400 160 440 190], ...
          'Orientation', 'left');
add_block('simulink/Math Operations/Sign',        [mdl '/SgnI'],   'ZeroCross', 'off', 'Position', [470 210 500 240], ...
          'Orientation', 'left');
add_block('simulink/Math Operations/Gain',        [mdl '/dUp'],    'Gain', nr(P.dUp), 'Position', [400 210 440 240], ...
          'Orientation', 'left');

% --- fluxul: phi = min(1, W_b / max(W, eps)) și k*phi ---
add_block('simulink/Sources/Constant',            [mdl '/Eps'],    'Value', '1e-6', 'Position', [520 330 550 350]);
add_block('simulink/Math Operations/MinMax',      [mdl '/MaxW'],   'Function', 'max', 'Inputs', '2', ...
          'Position', [580 300 610 340]);
add_block('simulink/Sources/Constant',            [mdl '/Wb'],     'Value', nr(P.W_b), 'Position', [580 250 620 270]);
add_block('simulink/Math Operations/Product',     [mdl '/Div'],    'Inputs', '*/', 'Position', [650 260 680 330]);
add_block('simulink/Sources/Constant',            [mdl '/Unu'],    'Value', '1', 'Position', [650 220 680 240]);
add_block('simulink/Math Operations/MinMax',      [mdl '/MinPhi'], 'Function', 'min', 'Inputs', '2', ...
          'Position', [710 230 740 300]);
add_block('simulink/Math Operations/Gain',        [mdl '/k'],      'Gain', nr(P.k), 'Position', [770 250 810 280]);
add_block('simulink/Math Operations/Product',     [mdl '/ProdE'],  'Inputs', '**', 'Position', [850 330 880 380]);
add_block('simulink/Math Operations/Product',     [mdl '/ProdTE'], 'Inputs', '**', 'Position', [850 80 880 130]);

% --- partea mecanică: T_ax = T_E - Tf0*sign(W) - Fv*W;  dW/dt = (T_ax - T_sarcina)/J ---
add_block('simulink/Math Operations/Sum',         [mdl '/SumTax'], 'Inputs', '+--', 'Position', [920 70 940 150]);
add_block('simulink/Math Operations/Sum',         [mdl '/SumMec'], 'Inputs', '+-', 'Position', [980 80 1000 130]);
add_block('simulink/Math Operations/Gain',        [mdl '/InvJ'],   'Gain', nr(1 / P.J), 'Position', [1030 90 1070 120]);
add_block('simulink/Continuous/Integrator',       [mdl '/Int_W'],  'InitialCondition', '0', 'LimitOutput', 'on', ...
          'LowerSaturationLimit', '0', 'Position', [1100 90 1130 120]);
add_block('simulink/Math Operations/Sign',        [mdl '/SgnW'],   'ZeroCross', 'off', 'Position', [1100 180 1130 210], ...
          'Orientation', 'left');
add_block('simulink/Math Operations/Gain',        [mdl '/Tf0'],    'Gain', nr(P.Tf0), 'Position', [1040 180 1080 210], ...
          'Orientation', 'left');
add_block('simulink/Math Operations/Gain',        [mdl '/Fv'],     'Gain', nr(P.Fv), 'Position', [1040 230 1080 260], ...
          'Orientation', 'left');
add_block('simulink/Math Operations/Gain',        [mdl '/a0'],     'Gain', nr(P.a0), 'Position', [1040 280 1080 310], ...
          'Orientation', 'left');
add_block('simulink/Math Operations/Product',     [mdl '/W2'],     'Inputs', '**', 'Position', [1100 330 1130 370], ...
          'Orientation', 'left');
add_block('simulink/Math Operations/Gain',        [mdl '/a2'],     'Gain', nr(P.a2), 'Position', [1040 335 1080 365], ...
          'Orientation', 'left');
add_block('simulink/Math Operations/Sum',         [mdl '/SumSarc'], 'Inputs', '++', 'Position', [990 280 1010 370], ...
          'Orientation', 'left');

% --- ieșiri ---
add_block('simulink/Sinks/To Workspace', [mdl '/Out_I'],   'VariableName', 'sim_I',   'SaveFormat', 'Timeseries', ...
          'Decimation', nr(dec), 'Position', [470 20 540 40]);
add_block('simulink/Sinks/To Workspace', [mdl '/Out_W'],   'VariableName', 'sim_W',   'SaveFormat', 'Timeseries', ...
          'Decimation', nr(dec), 'Position', [1170 20 1240 40]);
add_block('simulink/Sinks/To Workspace', [mdl '/Out_U'],   'VariableName', 'sim_U',   'SaveFormat', 'Timeseries', ...
          'Decimation', nr(dec), 'Position', [250 10 320 30]);
add_block('simulink/Sinks/To Workspace', [mdl '/Out_Tax'], 'VariableName', 'sim_Tax', 'SaveFormat', 'Timeseries', ...
          'Decimation', nr(dec), 'Position', [960 10 1030 30]);
add_block('simulink/Sinks/Scope',        [mdl '/Scope'],   'NumInputPorts', '3', 'Position', [1180 140 1210 220]);

% --- conexiuni ---
L = @(a, b) add_line(mdl, a, b, 'autorouting', 'on');
L('Ceas/1', 'Panta/1');   L('Panta/1', 'SumU/1');   L('U0/1', 'SumU/2');   L('SumU/1', 'SatU/1');
L('SatU/1', 'SumArm/1');  L('SatU/1', 'Out_U/1');
L('SumArm/1', 'InvL/1');  L('InvL/1', 'Int_I/1');
L('Int_I/1', 'Ra/1');     L('Ra/1', 'SumArm/2');
L('Int_I/1', 'SgnI/1');   L('SgnI/1', 'dUp/1');    L('dUp/1', 'SumArm/3');
L('ProdE/1', 'SumArm/4');
L('Int_W/1', 'MaxW/1');   L('Eps/1', 'MaxW/2');
L('Wb/1', 'Div/1');       L('MaxW/1', 'Div/2');
L('Unu/1', 'MinPhi/1');   L('Div/1', 'MinPhi/2');  L('MinPhi/1', 'k/1');
L('k/1', 'ProdE/1');      L('Int_W/1', 'ProdE/2');
L('k/1', 'ProdTE/1');     L('Int_I/1', 'ProdTE/2');
L('ProdTE/1', 'SumTax/1');
L('Int_W/1', 'SgnW/1');   L('SgnW/1', 'Tf0/1');    L('Tf0/1', 'SumTax/2');
L('Int_W/1', 'Fv/1');     L('Fv/1', 'SumTax/3');
L('SumTax/1', 'SumMec/1');
L('SgnW/1', 'a0/1');      L('a0/1', 'SumSarc/1');
L('Int_W/1', 'W2/1');     L('Int_W/1', 'W2/2');    L('W2/1', 'a2/1');     L('a2/1', 'SumSarc/2');
L('SumSarc/1', 'SumMec/2');
L('SumMec/1', 'InvJ/1');  L('InvJ/1', 'Int_W/1');
L('Int_I/1', 'Out_I/1');  L('Int_W/1', 'Out_W/1');  L('SumTax/1', 'Out_Tax/1');
L('Int_I/1', 'Scope/1');  L('Int_W/1', 'Scope/2');  L('SumTax/1', 'Scope/3');

% --- configurație: pas fix, Runge-Kutta 4 (ode4) ---
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', nr(dt), ...
          'StopTime', nr(t_end), 'ReturnWorkspaceOutputs', 'on');
aici = fileparts(mfilename('fullpath'));
save_system(mdl, fullfile(aici, '..', 'rezultate', [mdl '.slx']));

% --- simulare și comparație cu simulari.m ---
out = sim(mdl);
sI = out.get('sim_I');  sW = out.get('sim_W');  sT = out.get('sim_Tax');
rez.t = sW.Time;  rez.I = sI.Data(:);  rez.W = sW.Data(:);  rez.T_ax = sT.Data(:);
Z = simulari(S, M, T);
ref = Z.(upper(scenariu));
rez.dif_W = max(abs(interp1(ref.t, ref.W, rez.t, 'linear', 'extrap') - rez.W));
rez.dif_I = max(abs(interp1(ref.t, ref.I, rez.t, 'linear', 'extrap') - rez.I));
fprintf('Scenariul %s: diferența maximă Simulink - rk4.m: |dW| = %.3g rad/s, |dI| = %.3g A\n', ...
        upper(scenariu), rez.dif_W, rez.dif_I);

figure('Name', ['Simulink – scenariul ' upper(scenariu)]);
subplot(3, 1, 1); plot(rez.t, rez.I, ref.t, ref.I, '--'); grid on; ylabel('I [A]');
legend('Simulink', 'rk4.m', 'Location', 'best');
subplot(3, 1, 2); plot(rez.t, rez.W * 60 / (2*pi), ref.t, ref.W * 60 / (2*pi), '--'); grid on; ylabel('n [rot/min]');
subplot(3, 1, 3); plot(rez.t, rez.T_ax, ref.t, ref.T_ax, '--'); grid on; ylabel('T_{ax} [Nm]'); xlabel('t [s]');
end
