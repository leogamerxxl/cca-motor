function rez = model_sps_dcdc(P, Rm, inversat)
%MODEL_SPS_DCDC P5-P6: convertorul DC-DC bidirecțional (4 faze intercalate) în Specialized Power Systems,
%   cu sarcina celor 3 invertoare modelată ca sursă de curent comandată i = P(t)/u_dc:
%   P = 0 -> P_dc_max (tracțiune, ridicător) -> -P_franare (frânare recuperativă, coborâtor).
%   powergui discret (Ts = pasul din sim_dcdc_comutatie.m), rezolvitor cu pas fix ode4.
%   Rezultatele se compară cu simularea MATLAB cu comutație (sim_dcdc_comutatie.m) – Rm, opțional.
%   inversat – folosit intern: dacă sursa de curent a fost legată cu polaritatea inversă, modelul se
%   reconstruiește automat cu bornele schimbate.
if nargin < 1 || isempty(P), P = parametri_simulink(); end
if nargin < 2 || isempty(Rm), Rm = sim_dcdc_comutatie(P.D, P.S.cv.simulare.dcdc); end
if nargin < 3, inversat = false; end
L = biblioteci();  D = P.D;  sc = P.S.cv.simulare.dcdc;  N = D.N_faze;  Ts = sc.dt;
mdl = model_nou('cca_sps_dcdc_bidirectional');
c = @(a, b) leaga(mdl, a, b);
bloc(mdl, 'powergui', L.powergui, [40 20 120 60], 'SimulationMode', 'Discrete', 'SampleTime', nr(Ts));
adauga_dcdc(mdl, P, sc.U_bat_V, Ts);

% --- sarcina: P(t) = treaptă de tracțiune + treaptă spre recuperare; i = P/u_dc ---
bloc(mdl, 'P_tr', L.treapta, [600 520 630 550], 'Time', nr(sc.t_tractiune), 'Before', '0', 'After', nr(D.P_dc_max));
bloc(mdl, 'P_fr', L.treapta, [600 580 630 610], 'Time', nr(sc.t_franare), 'Before', '0', ...
     'After', nr(-(1 + sc.P_franare_rel) * D.P_dc_max));
bloc(mdl, 'SumPs', L.suma, [660 540 680 600], 'Inputs', '++');
bloc(mdl, 'DivIs', L.produs, [710 550 740 590], 'Inputs', '*/');
bloc(mdl, 'Isarc', L.sursa_I, [820 230 850 270], 'Initialize', 'off', ...
     'Measurements', 'None');
bloc(mdl, 'Isarc_m', L.masura_I, [780 180 810 210]);
c('P_tr/o1', 'SumPs/i1');  c('P_fr/o1', 'SumPs/i2');  c('SumPs/o1', 'DivIs/i1');  c('Udc_z/o1', 'DivIs/i2');
c('DivIs/o1', 'Isarc/i1');  c('SumPs/o1', 'Pff/i1');
c('Cdc/l1', 'Isarc_m/l1');
if ~inversat
    c('Isarc_m/r1', 'Isarc/l1');  c('Isarc/r1', 'Masa/l1');
else
    c('Isarc_m/r1', 'Isarc/r1');  c('Isarc/l1', 'Masa/l1');
end
% --- ieșiri ---
spre_workspace(mdl, 'W_Udc', 'sps_Udc', [900 100 970 120], 1);
spre_workspace(mdl, 'W_Ibat', 'sps_Ibat', [900 140 970 160], 1);
spre_workspace(mdl, 'W_Isarc', 'sps_Isarc', [900 180 970 200], 1);
spre_workspace(mdl, 'W_D', 'sps_D1', [1420 720 1490 740], 1);
c('Udc_m/o1', 'W_Udc/i1');  c('Ibat_m/o1', 'W_Ibat/i1');  c('Isarc_m/o1', 'W_Isarc/i1');  c('SatD1/o1', 'W_D/i1');
for q = 1:N
    f = sprintf('%d', q);
    spre_workspace(mdl, ['W_IL' f], ['sps_IL' f], [480 40 * q 550 40 * q + 20], 1);
    c(['IL' f '_m/o1'], ['W_IL' f '/i1']);
end
bloc(mdl, 'Scope', L.scope, [980 20 1010 100], 'NumInputPorts', '3');
c('Udc_m/o1', 'Scope/i1');  c('Ibat_m/o1', 'Scope/i2');  c('IL1_m/o1', 'Scope/i3');

set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'ode4', 'FixedStep', nr(Ts), 'StopTime', nr(sc.t_end), ...
          'ReturnWorkspaceOutputs', 'on');
fisier = fullfile(P.dir_modele, [mdl '.slx']);
save_system(mdl, fisier);
out = simuleaza(mdl);
[t, Udc] = citeste(out, 'sps_Udc');  [~, Ib] = citeste(out, 'sps_Ibat');  [~, Is] = citeste(out, 'sps_Isarc');
[~, D1] = citeste(out, 'sps_D1');
IL = zeros(numel(t), N);
for q = 1:N
    [~, IL(:, q)] = citeste(out, sprintf('sps_IL%d', q));
end
% verificarea polarității sursei de curent (trebuie să absoarbă putere la tracțiune)
m1 = t > sc.t_franare - 1e-3 & t <= sc.t_franare;
if mean(Is(m1)) < 0 && ~inversat
    fprintf(2, 'Sursa de curent a sarcinii a fost legată invers – modelul se reconstruiește.\n');
    close_system(mdl, 0);
    rez = model_sps_dcdc(P, Rm, true);
    return;
end
m2 = t > sc.t_end - 1e-3;
rez.model = mdl;  rez.fisier = fisier;  rez.sursa_inversata = inversat;
ind = @(m) struct('I_bat_med', mean(Ib(m)), 'U_dc_med', mean(Udc(m)), 'D_med', mean(D1(m)), ...
                  'dI_faza', max(IL(m, 1)) - min(IL(m, 1)), 'dI_bat', max(Ib(m)) - min(Ib(m)), ...
                  'dU_dc', max(Udc(m)) - min(Udc(m)));
rez.tr = ind(m1);  rez.rec = ind(m2);
rez.U_dc_min = min(Udc(t >= sc.t_tractiune & t < sc.t_franare));
rez.U_dc_max = max(Udc(t >= sc.t_franare));
rez.ref.tr = Rm.tr;  rez.ref.rec = Rm.rec;  rez.ref.U_dc_min = Rm.U_dc_min;  rez.ref.U_dc_max = Rm.U_dc_max;
fprintf('DC-DC (SPS): tracțiune I_bat %.0f A (MATLAB %.0f), D %.4f (%.4f), ΔI faza %.1f A (%.1f), ΔU_dc %.2f V (%.2f)\n', ...
        rez.tr.I_bat_med, Rm.tr.I_bat_med, rez.tr.D_med, Rm.tr.D_med, rez.tr.dI_faza, Rm.tr.dI_faza, ...
        rez.tr.dU_dc, Rm.tr.dU_dc);
fprintf('             recuperare I_bat %.0f A (MATLAB %.0f); U_dc min %.1f V (%.1f), max %.1f V (%.1f)\n', ...
        rez.rec.I_bat_med, Rm.rec.I_bat_med, rez.U_dc_min, Rm.U_dc_min, rez.U_dc_max, Rm.U_dc_max);
fig = figure('Name', 'DC-DC bidirecțional (SPS)', 'Visible', 'off');
subplot(3, 1, 1); plot(t * 1e3, Udc, Rm.t * 1e3, Rm.UDC, '--'); grid on; ylabel('U_{dc} [V]');
legend('Simulink SPS', 'MATLAB');
subplot(3, 1, 2); plot(t * 1e3, IL); grid on; ylabel('i_L [A]');
subplot(3, 1, 3); plot(t * 1e3, Ib, Rm.t * 1e3, Rm.IB, '--'); grid on; ylabel('I_{bat} [A]'); xlabel('t [ms]');
rez.figura = fullfile(P.dir_rezultate, [mdl '.png']);
salveaza_figura(fig, rez.figura);
end
