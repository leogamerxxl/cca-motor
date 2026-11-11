function delete_block(cale)
R = mock_reg();
k = find(strcmp({R.blocuri.cale}, cale));
if isempty(k), error('mock: delete_block pe un bloc inexistent'); end
R.blocuri(k) = [];
mock_reg(R);
end
