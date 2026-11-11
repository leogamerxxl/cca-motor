function s = mock_nume_port(R, h)
b = R.blocuri(R.porturi(h, 1));
t = {'i', 'o', 'l', 'r'};
s = sprintf('%s/%s%d', b.cale(find(b.cale == '/', 1) + 1:end), t{R.porturi(h, 2)}, R.porturi(h, 3));
end
