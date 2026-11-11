function [t, y] = citeste(out, variabila)
%CITESTE Timpul și valorile unui semnal salvat cu To Workspace (Timeseries) în rezultatul OUT = sim(...).
ts = out.get(variabila);
t = ts.Time(:);
y = squeeze(ts.Data);
if size(y, 1) ~= numel(t), y = y.'; end
end
