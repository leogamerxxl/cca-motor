function tip = mock_tip(sursa)
%MOCK_TIP Tipul blocului după calea din bibliotecă.
s = strrep(sursa, newline, ' ');
tabel = {'powergui', 'powergui'; 'DC Voltage Source', 'sursa_dc'; 'Controlled Current Source', 'sursa_I';
         'Ground', 'masa'; 'Series RLC Branch', 'rlc'; 'Mosfet', 'mosfet'; 'Diode', 'dioda';
         'Current Measurement', 'masura_I'; 'Voltage Measurement', 'masura_U'; 'DC Machine', 'masina_cc';
         'PID Controller', 'pid'; 'Triangle Generator', 'triunghi'; 'Clock', 'ceas'; 'Constant', 'constanta';
         'Sources/Step', 'treapta'; 'Gain', 'castig'; 'Math Operations/Sum', 'suma'; 'Product', 'produs';
         'Math Operations/Sign', 'semn'; 'MinMax', 'minmax'; 'Math Operations/Abs', 'abs';
         'Continuous/Integrator', 'integrator'; 'User-Defined Functions/Fcn', 'fcn'; 'Saturation', 'saturatie';
         'Relay', 'releu'; 'Relational Operator', 'relational'; 'Logical Operator', 'logic';
         '1-D Lookup Table', 'tabel'; 'Unit Delay', 'intarziere'; 'Transfer Fcn', 'filtru';
         'To Workspace', 'workspace'; 'Sinks/Scope', 'scope'; 'Stop Simulation', 'stop';
         'Bus Selector', 'selector'; 'Signal Routing/Mux', 'mux'; 'Data Type Conversion', 'conversie'};
tip = '';
for q = 1:size(tabel, 1)
    if ~isempty(strfind(s, tabel{q, 1})), tip = tabel{q, 2}; return; end
end
end
