function new_system(mdl)
R = mock_reg();
R.blocuri = R.blocuri([]);  R.linii = zeros(0, 2);  R.porturi = zeros(0, 3);  R.model = struct('nume', mdl);
R.erori = {};  R.avertismente = {};
mock_reg(R);
end
