function L = punct_functionare(M, W, T_ax)
%PUNCT_FUNCTIONARE Puterile și pierderile (diagrama de puteri, C3) în punctele (W, T_ax), regim de motor.
%   W [rad/s] > 0 și T_ax [Nm] >= 0 pot fi vectori/matrici de aceeași dimensiune.
%   Sub viteza de bază tensiunea se reglează (U < U_n, convertorul / invertorul), fluxul este maxim (phi = 1).
%   Când tensiunea necesară depășește U_n, fluxul se slăbește: se alege cel mai mare flux k*phi = x care
%   respectă  W*x^2 - (U_n - dUp)*x + Ra*T_E = 0  (curent minim, deci pierderi în cupru minime).

T_E  = T_ax + M.T_f0 + M.F_v .* W;                      % cuplul electromagnetic
U_pf = M.k .* W + M.R_a .* T_E ./ M.k + M.dU_p;          % tensiunea necesară cu flux plin
disc = (M.U_n - M.dU_p).^2 - 4 .* W .* M.R_a .* T_E;
x    = M.k .* ones(size(W));
slab = U_pf > M.U_n;                                    % puncte cu slăbire de câmp
x(slab) = ((M.U_n - M.dU_p) + sqrt(max(disc(slab), 0))) ./ (2 .* W(slab));
L.phi = x ./ M.k;
L.I   = T_E ./ x;
L.E   = x .* W;
L.U   = L.E + M.R_a .* L.I + M.dU_p;
L.T_E = T_E;
L.P1  = L.U .* L.I;                                     % puterea electrică absorbită
L.P_a = M.R_a .* L.I.^2;                                % pierderi în înfășurări (indus)
L.P_p = M.dU_p .* L.I;                                  % pierderi „la perii”
L.P_em = L.E .* L.I;                                    % puterea electromagnetică = T_E*W
L.P_Fe = M.K_H .* W + M.K_F .* W.^2;                    % pierderi în fier
L.P_fv = M.T_m0 .* W + M.F_m .* W.^2;                   % pierderi mecanice și de ventilație
L.P2  = T_ax .* W;                                      % puterea mecanică la ax
L.SP  = L.P1 - L.P2;                                    % pierderi totale
L.eta = L.P2 ./ L.P1;                                   % randament (P_ex = 0: magneți permanenți)
% domeniul admis: anvelopa din catalog și existența soluției de tensiune
L.in_anvelopa = (T_ax <= min(M.M_max, M.P_max ./ W) + 1e-9) & (W <= M.W_max + 1e-9) & (disc >= 0 | ~slab);
L.eta(~L.in_anvelopa) = NaN;
end
