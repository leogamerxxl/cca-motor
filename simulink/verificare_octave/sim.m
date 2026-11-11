function out = sim(mdl, varargin)
%SIM (simulator de verificare) Verifică structura modelului construit și întoarce semnale fictive.
%   Erori: intrări de semnal nelegate, borne fizice nelegate, parametri de rezolvitor lipsă.
%   Afișează lista nodurilor electrice (netlist) pentru verificarea topologiei.
R = mock_reg();
nb = numel(R.blocuri);
probleme = {};  avert = {};
tipuri = {'i', 'o', 'l', 'r'};
handles_fizice = [];
for k = 1:nb
    b = R.blocuri(k);
    n = mock_porturi(b);
    for t = 1:4
        for i = 1:n(t)
            j = find(R.porturi(:, 1) == k & R.porturi(:, 2) == t & R.porturi(:, 3) == i, 1);
            nume = sprintf('%s/%s%d', b.cale(find(b.cale == '/', 1) + 1:end), tipuri{t}, i);
            legat = ~isempty(j) && (any(R.linii(:, 1) == j) || any(R.linii(:, 2) == j));
            if ~legat
                if t == 2, avert{end + 1} = ['ieșire nefolosită ' nume]; else, probleme{end + 1} = ['nelegat ' nume]; end
            end
            if t >= 3 && ~isempty(j), handles_fizice(end + 1) = j; end
        end
    end
end
for c = {'SolverType', 'StopTime'}
    if ~isfield(R.model, c{1}), probleme{end + 1} = ['parametrul modelului lipsește: ' c{1}]; end
end
% noduri electrice (union-find pe legăturile fizice)
par = 1:size(R.porturi, 1);
    function r = rad(x)
        while par(x) ~= x, x = par(x); end
        r = x;
    end
for q = 1:size(R.linii, 1)
    a = R.linii(q, 1);  b2 = R.linii(q, 2);
    if R.porturi(a, 2) >= 3
        ra = rad(a);  rb = rad(b2);
        if ra ~= rb, par(ra) = rb; end
    end
end
noduri = containers.Map('KeyType', 'double', 'ValueType', 'any');
for h = unique(handles_fizice)
    r = rad(h);
    if ~isKey(noduri, r), noduri(r) = {}; end
    v = noduri(r);  v{end + 1} = mock_nume_port(R, h);  noduri(r) = v;
end
fprintf('   [mock] %s: %d blocuri, %d legături, %d noduri electrice\n', mdl, nb, size(R.linii, 1), noduri.Count);
chei = keys(noduri);
for q = 1:numel(chei)
    v = noduri(chei{q});
    fprintf('      nod %2d: %s\n', q, strjoin(sort(v), ', '));
    if numel(v) < 2, probleme{end + 1} = sprintf('nod cu o singură bornă: %s', v{1}); end
end
for q = 1:numel(avert), fprintf('   [mock] avertisment: %s\n', avert{q}); end
if ~isempty(probleme)
    error('mock: modelul %s are probleme:\n  %s', mdl, strjoin(probleme, sprintf('\n  ')));
end
% semnale fictive pentru blocurile To Workspace
T = str2double(R.model.StopTime);
d = struct();
for k = 1:nb
    b = R.blocuri(k);
    if strcmp(b.tip, 'workspace')
        t = linspace(0, T, 2001).';
        d.(b.param.VariableName) = struct('Time', t, 'Data', 1 + 0.01 * t / T);
    end
end
out = FakeOut(d);
end
