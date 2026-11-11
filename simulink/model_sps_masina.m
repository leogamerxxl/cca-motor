function rez = model_sps_masina(P, Z)
%MODEL_SPS_MASINA Mașina YM720 ca mașină de curent continuu cu magneți permanenți (blocul DC Machine din
%   Specialized Power Systems, ca în exemplul de curs MCC_CCA.slx) cu parametrii identificați în C3:
%     RLa = [R_a L_a],  Kt = k,  J = J_rotor,  Bm = F_v (frecări vâscoase),  Tf = T_f0 (cuplul static).
%   Scenariul A din simulari.m: pornire în gol la tensiunea U_p (curent de pornire <= I_max), apoi treaptă
%   de cuplu de sarcină M_n.  Cuplul la ax se calculează ca în curs: T_ax = Te - Tf0*sign(w) - Fv*w.
%   Regimul staționar final se compară cu valorile teoretice și cu rk4.m (simulari.m).
if nargin < 1 || isempty(P), P = parametri_simulink(); end
if nargin < 2 || isempty(Z), Z = simulari(P.S, P.M, P.T); end
M = P.M;  sp = P.S.ip.simulare;  L = biblioteci();
mdl = model_nou('cca_sps_masina_ym720');

bloc(mdl, 'powergui', L.powergui, [40 20 120 60], 'SimulationMode', 'Continuous');
% SPS pornește implicit circuitele în regim staționar (aici i_A(0) = U_p/R_a); referința rk4.m pornește de la
% I = 0, deci stările electrice inițiale se pun la zero
try
    set_param([mdl '/powergui'], 'x0status', 'zero');
catch e
    warning('cca:x0', 'powergui: x0status = zero nu a putut fi setat (%s)', e.message);
end
bloc(mdl, 'Ua', L.sursa_dc, [60 140 90 180], 'Amplitude', nr(M.U_p));
bloc(mdl, 'Masa', L.masa, [60 230 90 260]);
bloc(mdl, 'Masina', L.masina_cc, [200 130 290 210], ...
     'PresetModel', 'No', 'FieldType', 'Permanent magnet', 'MechanicalLoad', 'Torque TL', ...
     'MachineConstant', 'Torque constant (N.m/A)', ...
     'RLa', nr([M.R_a M.L_a]), 'Kt', nr(M.k), 'J', nr(M.J_rotor), 'Bm', nr(M.F_v), 'Tf', nr(M.T_f0), ...
     'w0', '0', 'MeasurementBus', 'on');
bloc(mdl, 'TL', L.treapta, [120 60 150 90], 'Time', nr(sp.A_t_treapta), 'Before', '0', ...
     'After', nr(sp.A_M_treapta));
bloc(mdl, 'Selector', L.selector, [340 140 345 220], 'OutputSignals', 'iA,w,Te');
% T_ax = Te - Tf0*sign(w) - Fv*w
bloc(mdl, 'SgnW', L.semn, [400 250 430 280], 'ZeroCross', 'off');
bloc(mdl, 'Tf0', L.castig, [450 250 490 280], 'Gain', nr(M.T_f0));
bloc(mdl, 'Fv', L.castig, [450 300 490 330], 'Gain', nr(M.F_v));
bloc(mdl, 'SumTax', L.suma, [540 200 560 300], 'Inputs', '+--');
spre_workspace(mdl, 'Out_I', 'sps_I', [420 120 490 140], 1);
spre_workspace(mdl, 'Out_W', 'sps_W', [420 160 490 180], 1);
spre_workspace(mdl, 'Out_Te', 'sps_Te', [420 200 490 220], 1);
spre_workspace(mdl, 'Out_Tax', 'sps_Tax', [600 240 670 260], 1);
bloc(mdl, 'Scope', L.scope, [600 120 630 200], 'NumInputPorts', '3');

c = @(a, b) leaga(mdl, a, b);
c('Ua/r1', 'Masina/l1');            % + -> A+
c('Ua/l1', 'Masina/r1');            % - -> A-
c('Ua/l1', 'Masa/l1');
c('TL/o1', 'Masina/i1');
c('Masina/o1', 'Selector/i1');
c('Selector/o1', 'Out_I/i1');   c('Selector/o2', 'Out_W/i1');   c('Selector/o3', 'Out_Te/i1');
c('Selector/o2', 'SgnW/i1');    c('SgnW/o1', 'Tf0/i1');         c('Selector/o2', 'Fv/i1');
c('Selector/o3', 'SumTax/i1');  c('Tf0/o1', 'SumTax/i2');       c('Fv/o1', 'SumTax/i3');
c('SumTax/o1', 'Out_Tax/i1');
c('Selector/o1', 'Scope/i1');   c('Selector/o2', 'Scope/i2');   c('SumTax/o1', 'Scope/i3');

set_param(mdl, 'SolverType', 'Variable-step', 'Solver', 'ode23tb', 'RelTol', '1e-6', 'MaxStep', '1e-4', ...
          'StopTime', nr(sp.A_t_end), 'ReturnWorkspaceOutputs', 'on');
fisier = fullfile(P.dir_modele, [mdl '.slx']);
save_system(mdl, fisier);
out = simuleaza(mdl);
[t, I] = citeste(out, 'sps_I');  [~, W] = citeste(out, 'sps_W');  [~, Tax] = citeste(out, 'sps_Tax');
if abs(I(1)) > 1
    warning('cca:x0', 'i_A(0) = %.1f A: curentul inițial nu este 0 (inițializare SPS în regim staționar)', I(1));
end
A = Z.A;
rez.model = mdl;  rez.fisier = fisier;
k0 = find(t < sp.A_t_treapta, 1, 'last');
rez.I_varf = max(I);            rez.I_varf_ref = A.I_varf;
rez.W_gol = W(k0);              rez.W_gol_ref = A.W_gol;           rez.W_gol_teoretic = A.W_gol_teoretic;
rez.W_final = W(end);           rez.W_final_ref = A.W_final;       rez.W_final_teoretic = A.W_sarcina_teoretic;
rez.I_final = I(end);           rez.I_final_ref = A.I_final;       rez.I_final_teoretic = A.I_sarcina_teoretic;
fprintf('DC Machine (SPS): I vârf %.1f A (rk4 %.1f); W gol %.3f (rk4 %.3f, teoretic %.3f) rad/s;\n', ...
        rez.I_varf, rez.I_varf_ref, rez.W_gol, rez.W_gol_ref, rez.W_gol_teoretic);
fprintf('                  cu sarcină W %.3f rad/s, I %.1f A (teoretic %.3f rad/s, %.1f A)\n', ...
        rez.W_final, rez.I_final, rez.W_final_teoretic, rez.I_final_teoretic);
fig = figure('Name', 'DC Machine SPS – YM720 echivalent', 'Visible', 'off');
subplot(3, 1, 1); plot(t, I, A.t, A.I, '--'); grid on; ylabel('i_A [A]'); legend('SPS DC Machine', 'rk4.m');
subplot(3, 1, 2); plot(t, W, A.t, A.W, '--'); grid on; ylabel('\omega [rad/s]');
subplot(3, 1, 3); plot(t, Tax, A.t, A.T_ax, '--'); grid on; ylabel('T_{ax} [Nm]'); xlabel('t [s]');
rez.figura = fullfile(P.dir_rezultate, [mdl '.png']);
salveaza_figura(fig, rez.figura);
end
