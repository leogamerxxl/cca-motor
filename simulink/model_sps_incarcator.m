function rez = model_sps_incarcator(P, Rm)
%MODEL_SPS_INCARCATOR P5-P6: încărcarea bateriei (ca în exemplul din suportul P5-P6, slide 3):
%   sursa U_dc după PFC -> MOSFET + diodă de regim liber -> bobină L -> baterie (R_bat în serie cu
%   capacitatea echivalentă C_s); curentul reglat prin histerezis (blocul Relay, banda h), referința de
%   curent dată de un regulator PI de tensiune (faza CV), limitată la I_CC (faza CC).
%   Ca simularea să fie scurtă, capacitatea bateriei este redusă de k_timp ori (timp scalat), iar
%   tensiunea inițială este aleasă astfel încât faza CC să dureze t_CC_s (aceleași valori ca în
%   sim_incarcare_comutatie.m).  Simularea se oprește la sfârșitul încărcării (I mediu < I_taiere).
if nargin < 1 || isempty(P), P = parametri_simulink(); end
if nargin < 2 || isempty(Rm), Rm = sim_incarcare_comutatie(P.C, P.S.cv.simulare.incarcare); end
L = biblioteci();  C = P.C;  sc = P.S.cv.simulare.incarcare;
Ts = sc.dt;                                        % același pas ca în sim_incarcare_comutatie.m
Cs = C.C_eq / sc.k_timp;
OCV0 = C.U_CV - C.R_bat * C.I_CC - C.I_CC * sc.t_CC_s / Cs;
wc = 2 * pi * sc.fc_U_Hz;  Kp = sc.Kp_R / C.R_bat;  Ki = wc / abs(C.R_bat + 1 / (1i * wc * Cs));
mdl = model_nou('cca_sps_incarcator_cccv');
c = @(a, b) leaga(mdl, a, b);
bloc(mdl, 'powergui', L.powergui, [40 20 120 60], 'SimulationMode', 'Discrete', 'SampleTime', nr(Ts));
bloc(mdl, 'Udc_PFC', L.sursa_dc, [40 140 70 180], 'Amplitude', nr(C.U_dc));
bloc(mdl, 'Masa', L.masa, [40 300 70 330]);
bloc(mdl, 'S', L.mosfet, [120 80 150 110], 'Ron', '0.01', 'Lon', '0', 'Rd', '1e-3', 'Vfd', '0', 'IC', '0', ...
     'Rs', '1e5', 'Cs', 'inf', 'Measurements', 'off');
bloc(mdl, 'Dioda', L.dioda, [200 160 230 190], 'Ron', '1e-3', 'Lon', '0', 'Vf', '0.8', 'IC', '0', ...
     'Rs', '1e5', 'Cs', 'inf', 'Measurements', 'off', 'Orientation', 'up');
bloc(mdl, 'Lc', L.rlc, [260 85 300 105], 'BranchType', 'RL', 'Resistance', '1e-4', 'Inductance', nr(C.L));
bloc(mdl, 'I_m', L.masura_I, [330 80 360 110]);
bloc(mdl, 'Baterie', L.rlc, [420 160 460 180], 'BranchType', 'RC', 'Resistance', nr(C.R_bat), ...
     'Capacitance', nr(Cs), 'Setx0', 'on', 'InitialVoltage', nr(OCV0), 'Orientation', 'down');
bloc(mdl, 'U_m', L.masura_U, [500 160 530 190]);
c('Udc_PFC/r1', 'S/l1');  c('Udc_PFC/l1', 'Masa/l1');
c('S/r1', 'Dioda/r1');  c('Dioda/l1', 'Masa/l1');           % catodul la nodul de comutație
c('S/r1', 'Lc/l1');  c('Lc/r1', 'I_m/l1');  c('I_m/r1', 'Baterie/l1');  c('Baterie/r1', 'Masa/l1');
c('I_m/r1', 'U_m/l1');  c('U_m/l2', 'Masa/l1');
% --- reglare: PI de tensiune (pe tensiunea filtrată) -> I_ref; histerezis pe curent ---
bloc(mdl, 'Filtru_U', L.filtru, [580 160 640 190], 'Numerator', '1', 'Denominator', mat2str([sc.tau_filtru_s 1], 16));
bloc(mdl, 'U_CV', L.constanta, [580 220 620 240], 'Value', nr(C.U_CV));
bloc(mdl, 'SumEu', L.suma, [660 180 680 230], 'Inputs', '+-');
bloc(mdl, 'PI_U', L.pid, [710 185 770 225], 'Controller', 'PI', 'P', nr(Kp), 'I', nr(Ki), ...
     'LimitOutput', 'on', 'UpperSaturationLimit', nr(C.I_CC), 'LowerSaturationLimit', '0', ...
     'AntiWindupMode', 'clamping', 'InitialConditionForIntegrator', nr(C.I_CC));
bloc(mdl, 'SumEi', L.suma, [800 120 820 170], 'Inputs', '+-');
bloc(mdl, 'Histerezis', L.releu, [850 130 890 160], 'OnSwitchValue', nr(C.h / 2), 'OffSwitchValue', nr(-C.h / 2), ...
     'OnOutputValue', '1', 'OffOutputValue', '0');
c('U_m/o1', 'Filtru_U/i1');  c('U_CV/o1', 'SumEu/i1');  c('Filtru_U/o1', 'SumEu/i2');  c('SumEu/o1', 'PI_U/i1');
c('PI_U/o1', 'SumEi/i1');  c('I_m/o1', 'SumEi/i2');  c('SumEi/o1', 'Histerezis/i1');  c('Histerezis/o1', 'S/i1');
% --- sfârșitul încărcării: faza CV (I_ref < 0,99 I_CC) și curentul mediu < I_taiere ---
bloc(mdl, 'Filtru_I', L.filtru, [580 300 640 330], 'Numerator', '1', 'Denominator', mat2str([sc.tau_filtru_I_s 1], 16));
bloc(mdl, 'I_mic', L.relational, [680 300 710 330], 'Operator', '<');
bloc(mdl, 'I_taiere', L.constanta, [620 350 660 370], 'Value', nr(C.I_taiere));
bloc(mdl, 'CV', L.relational, [680 380 710 410], 'Operator', '<');
bloc(mdl, 'Prag_CV', L.constanta, [620 420 660 440], 'Value', nr(0.99 * C.I_CC));
bloc(mdl, 'Si', L.logic, [740 330 770 380], 'Operator', 'AND', 'Inputs', '2');
bloc(mdl, 'Stop', L.stop, [800 340 830 370]);
c('I_m/o1', 'Filtru_I/i1');  c('Filtru_I/o1', 'I_mic/i1');  c('I_taiere/o1', 'I_mic/i2');
c('PI_U/o1', 'CV/i1');  c('Prag_CV/o1', 'CV/i2');
c('I_mic/o1', 'Si/i1');  c('CV/o1', 'Si/i2');  c('Si/o1', 'Stop/i1');
% --- ieșiri ---
spre_workspace(mdl, 'W_I', 'sps_I', [900 60 970 80], 40);
spre_workspace(mdl, 'W_U', 'sps_U', [900 100 970 120], 40);
spre_workspace(mdl, 'W_Iref', 'sps_Iref', [900 220 970 240], 40);
c('I_m/o1', 'W_I/i1');  c('U_m/o1', 'W_U/i1');  c('PI_U/o1', 'W_Iref/i1');
bloc(mdl, 'Scope', L.scope, [1000 60 1030 140], 'NumInputPorts', '2');
c('I_m/o1', 'Scope/i1');  c('U_m/o1', 'Scope/i2');

set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', nr(Ts), 'StopTime', nr(sc.t_end), ...
          'ReturnWorkspaceOutputs', 'on');
fisier = fullfile(P.dir_modele, [mdl '.slx']);
save_system(mdl, fisier);
out = simuleaza(mdl);
[t, I] = citeste(out, 'sps_I');  [~, U] = citeste(out, 'sps_U');  [~, Iref] = citeste(out, 'sps_Iref');
rez.model = mdl;  rez.fisier = fisier;
k = find(Iref < 0.99 * C.I_CC, 1);
rez.t_CC = t(k);                  rez.t_CC_ref = Rm.t_CC;
rez.t_stop = t(end);              rez.t_stop_ref = Rm.t_stop;   rez.t_stop_mediu = Rm.t_stop_teoretic;
m = t > 0.2 * sc.t_CC_s & t < 0.9 * sc.t_CC_s;
rez.I_med_CC = mean(I(m));        rez.I_CC = C.I_CC;
rez.dI_CC = max(I(m)) - min(I(m));  rez.h = C.h;
fprintf('Încărcător (SPS): CC -> CV la %.2f ms (MATLAB %.2f ms); oprire la %.1f ms (MATLAB %.1f, model mediu %.1f ms)\n', ...
        rez.t_CC * 1e3, rez.t_CC_ref * 1e3, rez.t_stop * 1e3, rez.t_stop_ref * 1e3, rez.t_stop_mediu * 1e3);
fprintf('                  în CC: I mediu %.2f A (I_CC = %.2f A), ondulație %.2f A (h = %.2f A)\n', ...
        rez.I_med_CC, C.I_CC, rez.dI_CC, C.h);
fig = figure('Name', 'Încărcător CC-CV (SPS)', 'Visible', 'off');
subplot(2, 1, 1); plot(t * 1e3, I, t * 1e3, Iref, Rm.t * 1e3, Rm.Iref, '--'); grid on; ylabel('I [A]');
legend('i (SPS)', 'I_{ref} (SPS)', 'I_{ref} (MATLAB)');
subplot(2, 1, 2); plot(t * 1e3, U, Rm.t * 1e3, Rm.U, '--'); grid on; ylabel('U_{bat} [V]'); xlabel('t [ms]');
rez.figura = fullfile(P.dir_rezultate, [mdl '.png']);
salveaza_figura(fig, rez.figura);
end
