function add_line(mdl, h1, h2, varargin)
R = mock_reg();
if ~isnumeric(h1) || ~isnumeric(h2), error('mock: add_line folosește aici doar handle-uri'); end
t1 = R.porturi(h1, 2);  t2 = R.porturi(h2, 2);
fiz1 = t1 >= 3;  fiz2 = t2 >= 3;
if fiz1 ~= fiz2, error('mock: legătură între port fizic și port de semnal'); end
if ~fiz1
    if t1 ~= 2 || t2 ~= 1, error('mock: legătura de semnal trebuie să fie ieșire -> intrare'); end
    if any(R.linii(:, 2) == h2), error('mock: intrarea %s este deja legată', mock_nume_port(R, h2)); end
end
R.linii(end + 1, :) = [h1 h2];
mock_reg(R);
end
