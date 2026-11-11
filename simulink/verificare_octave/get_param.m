function v = get_param(cale, nume)
R = mock_reg();
k = find(strcmp({R.blocuri.cale}, cale));
if isempty(k), error('mock: get_param pe un bloc inexistent %s', cale); end
b = R.blocuri(k);
switch nume
    case 'PortHandles'
        n = mock_porturi(b);
        tipuri = {'Inport', 'Outport', 'LConn', 'RConn'};
        v = struct();
        for t = 1:4
            h = zeros(1, n(t));
            for i = 1:n(t)
                j = find(R.porturi(:, 1) == k & R.porturi(:, 2) == t & R.porturi(:, 3) == i, 1);
                if isempty(j)
                    R.porturi(end + 1, :) = [k t i];
                    j = size(R.porturi, 1);
                end
                h(i) = j;
            end
            v.(tipuri{t}) = h;
        end
        mock_reg(R);
    otherwise
        if isfield(b.param, nume), v = b.param.(nume); else, v = ''; end
end
end
