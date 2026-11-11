function L = biblioteci()
%BIBLIOTECI Căile blocurilor din bibliotecă (MATLAB R2023b, Simulink + Simscape Electrical /
%   Specialized Power Systems).  Pentru fiecare bloc se dau mai multe variante; prima care există
%   este folosită (vezi BLOC).  Căile au fost verificate în modelele de exemplu ale cursului
%   (MCC_CCA.slx, Buck_Model 1.slx, Boost_Model 1.slx) și în documentația R2023b.
nl = newline;
L.powergui   = {'sps_lib/powergui', 'powerlib/powergui', 'spspowerguiLib/powergui'};
L.sursa_dc   = {'sps_lib/Sources/DC Voltage Source', 'spsDCVoltageSourceLib/DC Voltage Source', ...
                'powerlib/Electrical Sources/DC Voltage Source'};
L.sursa_I    = {'sps_lib/Sources/Controlled Current Source', ...
                'spsControlledCurrentSourceLib/Controlled Current Source', ...
                'powerlib/Electrical Sources/Controlled Current Source'};
L.masa       = {'sps_lib/Utilities/Ground', 'spsGroundLib/Ground', 'powerlib/Elements/Ground'};
L.rlc        = {'sps_lib/Passives/Series RLC Branch', 'spsSeriesRLCBranchLib/Series RLC Branch', ...
                'powerlib/Elements/Series RLC Branch'};
L.mosfet     = {'sps_lib/Power Electronics/Mosfet', 'spsMosfetLib/Mosfet', 'powerlib/Power Electronics/Mosfet'};
L.dioda      = {'sps_lib/Power Electronics/Diode', 'spsDiodeLib/Diode', 'powerlib/Power Electronics/Diode'};
L.masura_I   = {'sps_lib/Sensors and Measurements/Current Measurement', ...
                'spsCurrentMeasurementLib/Current Measurement', 'powerlib/Measurements/Current Measurement'};
L.masura_U   = {'sps_lib/Sensors and Measurements/Voltage Measurement', ...
                'spsVoltageMeasurementLib/Voltage Measurement', 'powerlib/Measurements/Voltage Measurement'};
L.masina_cc  = {'sps_lib/Electrical Machines/DC Machine', 'spsDCMachineLib/DC Machine', ...
                'powerlib/Machines/DC Machine'};
L.pid        = {'simulink/Continuous/PID Controller', 'slpidlib/PID Controller'};
L.triunghi   = {['sps_lib/Sources/Signal Generator Sources/Triangle' nl 'Generator'], ...
                ['spsTriangleGeneratorLib/Triangle' nl 'Generator']};
% blocuri Simulink de bază
L.ceas       = 'simulink/Sources/Clock';
L.constanta  = 'simulink/Sources/Constant';
L.treapta    = 'simulink/Sources/Step';
L.castig     = 'simulink/Math Operations/Gain';
L.suma       = 'simulink/Math Operations/Sum';
L.produs     = 'simulink/Math Operations/Product';
L.semn       = 'simulink/Math Operations/Sign';
L.minmax     = 'simulink/Math Operations/MinMax';
L.abs        = 'simulink/Math Operations/Abs';
L.integrator = 'simulink/Continuous/Integrator';
L.functie    = 'simulink/User-Defined Functions/Fcn';
L.saturatie  = 'simulink/Discontinuities/Saturation';
L.releu      = 'simulink/Discontinuities/Relay';
L.relational = 'simulink/Logic and Bit Operations/Relational Operator';
L.logic      = 'simulink/Logic and Bit Operations/Logical Operator';
L.tabel      = 'simulink/Lookup Tables/1-D Lookup Table';
L.intarziere = 'simulink/Discrete/Unit Delay';
L.filtru     = 'simulink/Continuous/Transfer Fcn';
L.workspace  = 'simulink/Sinks/To Workspace';
L.scope      = 'simulink/Sinks/Scope';
L.stop       = 'simulink/Sinks/Stop Simulation';
L.selector   = 'simulink/Signal Routing/Bus Selector';
L.mux        = 'simulink/Signal Routing/Mux';
L.conversie  = 'simulink/Signal Attributes/Data Type Conversion';
end
