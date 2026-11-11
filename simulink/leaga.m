function leaga(mdl, sursa, destinatie)
%LEAGA Conectează două porturi din modelul MDL.  Porturile se dau ca 'Bloc/tipN':
%   o = ieșire de semnal (Outport), i = intrare de semnal (Inport),
%   l = conexiune fizică din stânga (LConn), r = conexiune fizică din dreapta (RConn).
%   Exemple: leaga(mdl, 'Ceas/o1', 'Suma/i2');  leaga(mdl, 'Ubat/r1', 'Rbat/l1').
%   Pentru conexiunile fizice (Specialized Power Systems), legarea unui port deja conectat creează
%   o ramificație a aceluiași nod.
hs = port_bloc(mdl, sursa);
hd = port_bloc(mdl, destinatie);
try
    add_line(mdl, hs, hd, 'autorouting', 'on');
catch e
    error('cca:legatura', 'Legătura %s -> %s nu a putut fi creată: %s', sursa, destinatie, e.message);
end
end

function h = port_bloc(mdl, s)
k = find(s == '/', 1, 'last');
b = s(1:k - 1);
p = s(k + 1:end);
ph = get_param([mdl '/' b], 'PortHandles');
n = str2double(p(2:end));
switch p(1)
    case 'o', v = ph.Outport;
    case 'i', v = ph.Inport;
    case 'l', v = ph.LConn;
    case 'r', v = ph.RConn;
    otherwise, error('cca:port', 'Tip de port necunoscut în "%s" (o/i/l/r).', s);
end
if n > numel(v)
    error('cca:port', 'Blocul "%s" are doar %d porturi de tipul "%s" (cerut %d).', b, numel(v), p(1), n);
end
h = v(n);
end
