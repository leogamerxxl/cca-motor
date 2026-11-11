function [t, X, Y] = rk4(P, t_end, dt, x0, pas_salvare, conditie_stop)
%RK4 Integrare cu pas fix Runge-Kutta de ordinul 4 a modelului DERIVATA_MCC.
%   Același algoritm este folosit și în implementarea Python, ca rezultatele să poată fi comparate exact.
%   pas_salvare – se salvează un punct la fiecare pas_salvare pași; conditie_stop(x) – oprire anticipată.
if nargin < 6, conditie_stop = []; end
n  = round(t_end / dt);
ns = floor(n / pas_salvare) + 1;
t  = zeros(ns, 1);  X = zeros(ns, numel(x0));  Y = zeros(ns, 6);
x  = x0(:);
[~, y] = derivata_mcc(0, x, P);
t(1) = 0;  X(1, :) = x.';  Y(1, :) = y;
j = 1;
for i = 1:n
    ti = (i - 1) * dt;
    k1 = derivata_mcc(ti,          x,              P);
    k2 = derivata_mcc(ti + dt/2,   x + dt/2 * k1,  P);
    k3 = derivata_mcc(ti + dt/2,   x + dt/2 * k2,  P);
    k4 = derivata_mcc(ti + dt,     x + dt * k3,    P);
    x  = x + dt/6 * (k1 + 2*k2 + 2*k3 + k4);
    if x(2) < 0, x(2) = 0; end
    oprire = ~isempty(conditie_stop) && conditie_stop(x);
    if mod(i, pas_salvare) == 0 || oprire
        j = j + 1;
        [~, y] = derivata_mcc(i * dt, x, P);
        t(j) = i * dt;  X(j, :) = x.';  Y(j, :) = y;
    end
    if oprire, break; end
end
t = t(1:j);  X = X(1:j, :);  Y = Y(1:j, :);
end
