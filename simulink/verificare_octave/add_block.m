function add_block(sursa, cale, varargin)
R = mock_reg();
tip = mock_tip(sursa);
if isempty(tip), error('mock: biblioteca nu conține "%s"', strrep(sursa, newline, ' ')); end
if any(strcmp({R.blocuri.cale}, cale)), error('mock: blocul %s există deja', cale); end
k = strfind(cale, '/');
if numel(k) ~= 1, error('mock: numele blocului conține "/": %s', cale); end
b = struct('cale', cale, 'tip', tip, 'sursa', sursa, 'param', struct());
R.blocuri(end + 1) = b;
mock_reg(R);
for q = 1:2:numel(varargin)
    if strcmp(varargin{q}, 'Position')
        if ~isnumeric(varargin{q + 1}) || numel(varargin{q + 1}) ~= 4, error('mock: Position trebuie [x1 y1 x2 y2]'); end
        continue;
    end
    set_param(cale, varargin{q}, varargin{q + 1});
end
end
