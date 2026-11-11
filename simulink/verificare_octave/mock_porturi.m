function n = mock_porturi(b)
%MOCK_PORTURI Numărul de porturi [Inport Outport LConn RConn] al blocului, după tip și parametri.
p = b.param;
g = @(nume, implicit) obtine(p, nume, implicit);
switch b.tip
    case 'powergui',   n = [0 0 0 0];
    case 'sursa_dc',   n = [0 0 1 1];
    case 'sursa_I',    n = [1 0 1 1];
    case 'masa',       n = [0 0 1 0];
    case 'rlc',        n = [0 0 1 1];
    case 'mosfet',     n = [1 strcmp(g('Measurements', 'on'), 'on') 1 1];
    case 'dioda',      n = [0 strcmp(g('Measurements', 'on'), 'on') 1 1];
    case 'masura_I',   n = [0 1 1 1];
    case 'masura_U',   n = [0 1 2 0];
    case 'masina_cc'
        if strcmp(g('FieldType', 'Wound'), 'Wound'), n = [1 1 2 2]; else, n = [1 1 1 1]; end
    case {'pid', 'castig', 'semn', 'abs', 'integrator', 'fcn', 'saturatie', 'releu', 'tabel', 'intarziere', ...
          'filtru', 'conversie'}
        n = [1 1 0 0];
    case {'triunghi', 'ceas', 'constanta', 'treapta'}, n = [0 1 0 0];
    case {'suma', 'produs'}
        s = g('Inputs', '2');
        if all(ismember(s, '0123456789')), k = str2double(s); else, k = sum(ismember(s, '+-*/')); end
        n = [k 1 0 0];
    case 'minmax',     n = [str2double(g('Inputs', '1')) 1 0 0];
    case 'relational', n = [2 1 0 0];
    case 'logic'
        if strcmp(g('Operator', 'AND'), 'NOT'), n = [1 1 0 0]; else, n = [str2double(g('Inputs', '2')) 1 0 0]; end
    case 'workspace',  n = [1 0 0 0];
    case 'scope',      n = [str2double(g('NumInputPorts', '1')) 0 0 0];
    case 'stop',       n = [1 0 0 0];
    case 'selector',   n = [1 numel(strsplit(g('OutputSignals', 'a'), ',')) 0 0];
    case 'mux',        n = [str2double(g('Inputs', '2')) 1 0 0];
    otherwise,         error('mock: tip necunoscut %s', b.tip);
end
end
function v = obtine(p, nume, implicit)
if isfield(p, nume), v = p.(nume); else, v = implicit; end
end
