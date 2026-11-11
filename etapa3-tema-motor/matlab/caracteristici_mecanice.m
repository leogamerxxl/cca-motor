function K = caracteristici_mecanice(M, U_rel, phi_rel, n_puncte)
%CARACTERISTICI_MECANICE Caracteristicile mecanice statice n = f(T_ax) (curs C3, III):
%     n = (U - dUp)/(kE*Phi) - Ra/(kE*Phi) * I,   cu  I = (T_ax + Tf0 + Fv*W)/(k*phi)
%   rezolvat explicit în W:  W = (U - dUp - Ra*(T_ax + Tf0)/(k*phi)) / (k*phi + Ra*Fv/(k*phi))
%   U_rel   – tensiuni relative (U/U_n) cu flux plin (reglarea prin tensiune, sub viteza de bază)
%   phi_rel – fluxuri relative la U = U_n (slăbire de câmp, peste viteza de bază)
if nargin < 4, n_puncte = 50; end
T = linspace(0, M.M_max, n_puncte);
K.T = T;
K.U_rel = U_rel;  K.phi_rel = phi_rel;
K.n_U   = zeros(numel(U_rel), n_puncte);
K.n_phi = zeros(numel(phi_rel), n_puncte);
for q = 1:numel(U_rel)
    K.n_U(q, :) = viteza(M, U_rel(q) * M.U_n, 1, T) * 60 / (2*pi);
end
for q = 1:numel(phi_rel)
    K.n_phi(q, :) = viteza(M, M.U_n, phi_rel(q), T) * 60 / (2*pi);
end
% limita de funcționare din catalog (cuplul maxim / puterea maximă) și turația maximă
K.anv_n = linspace(1, M.n_max, n_puncte);
K.anv_T = min(M.M_max, M.P_max ./ (K.anv_n * 2*pi / 60));
end

function W = viteza(M, U, phi, T)
kp = M.k * phi;
W = (U - M.dU_p - M.R_a * (T + M.T_f0) / kp) / (kp + M.R_a * M.F_v / kp);
W = max(W, 0);
end
