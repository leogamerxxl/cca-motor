function R = mock_reg(R_nou)
%MOCK_REG Registrul global al simulatorului de API Simulink folosit la verificarea în Octave.
persistent REG
if nargin > 0, REG = R_nou; end
if isempty(REG)
    REG = struct('blocuri', struct('cale', {}, 'tip', {}, 'sursa', {}, 'param', {}), ...
                 'linii', zeros(0, 2), 'porturi', zeros(0, 3), 'model', struct(), 'urmatorul', 1, ...
                 'erori', {{}}, 'avertismente', {{}});
end
R = REG;
end
