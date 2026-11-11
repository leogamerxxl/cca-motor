function set_param(cale, varargin)
R = mock_reg();
if ~any(cale == '/')                      % parametrii modelului
    for q = 1:2:numel(varargin)
        if ~ischar(varargin{q + 1}), error('mock: %s trebuie dat ca șir', varargin{q}); end
        R.model.(varargin{q}) = varargin{q + 1};
    end
    mock_reg(R);
    return;
end
k = find(strcmp({R.blocuri.cale}, cale));
if isempty(k), error('mock: set_param pe un bloc inexistent %s', cale); end
b = R.blocuri(k);
enum = struct('FieldType', {{'Wound', 'Permanent magnet'}}, 'PresetModel', {{'No'}}, ...
    'MechanicalLoad', {{'Torque TL', 'Speed w', 'Mechanical rotational port'}}, ...
    'MachineConstant', {{'Torque constant (N.m/A)'}}, 'SimulationMode', {{'Continuous', 'Discrete', 'Phasor', 'Discrete phasor'}}, ...
    'Operator', {{'==', '~=', '<', '<=', '>=', '>', 'AND', 'OR', 'NAND', 'NOR', 'XOR', 'NOT'}}, ...
    'Controller', {{'PI', 'PID', 'P', 'I', 'PD'}}, 'AntiWindupMode', {{'none', 'back-calculation', 'clamping'}}, ...
    'BranchType', {{'RLC', 'R', 'L', 'C', 'RL', 'RC', 'LC', 'Open circuit'}}, 'Function', {{'min', 'max'}}, ...
    'Orientation', {{'right', 'left', 'up', 'down'}}, 'SaveFormat', {{'Timeseries', 'Array', 'Structure', 'Structure With Time'}}, ...
    'Measurements', {{'on', 'off', 'None', 'Branch current', 'Current', 'Voltage'}}, ...
    'LimitOutput', {{'on', 'off'}}, 'ZeroCross', {{'on', 'off'}}, 'Setx0', {{'on', 'off'}}, 'MeasurementBus', {{'on', 'off'}}, ...
    'Initialize', {{'on', 'off'}}, 'OutDataTypeStr', {{'double', 'boolean', 'single'}});
for q = 1:2:numel(varargin)
    nume = varargin{q};  val = varargin{q + 1};
    if ~ischar(val), error('mock: %s / %s trebuie dat ca șir', cale, nume); end
    if isfield(enum, nume) && ~any(strcmp(enum.(nume), val))
        error('mock: %s: valoare nepermisă %s = "%s"', cale, nume, val);
    end
    if strcmp(b.tip, 'masina_cc') && ~any(strcmp(nume, {'PresetModel', 'Position', 'Orientation'})) && ...
       ~(isfield(b.param, 'PresetModel') && strcmp(b.param.PresetModel, 'No'))
        error('mock: DC Machine – PresetModel trebuie setat la ''No'' înainte de %s', nume);
    end
    b.param.(nume) = val;
end
R.blocuri(k) = b;
mock_reg(R);
end
