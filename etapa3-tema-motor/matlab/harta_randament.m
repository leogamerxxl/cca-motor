function H = harta_randament(M, n_puncte)
%HARTA_RANDAMENT Harta de randament a unui motor (curs C3, exercițiul 1) pe grila n x T_ax.
if nargin < 2, n_puncte = 120; end
n = linspace(M.n_max / n_puncte, M.n_max, n_puncte);
Tq = linspace(0, M.M_max, n_puncte);
[NN, TT] = meshgrid(n, Tq);
L = punct_functionare(M, NN * 2*pi / 60, TT);
H.n = n;  H.T = Tq;  H.eta = L.eta;  H.SP = L.SP;  H.SP(~L.in_anvelopa) = NaN;
H.phi = L.phi;  H.phi(~L.in_anvelopa) = NaN;
H.anv_n = n;  H.anv_T = min(M.M_max, M.P_max ./ (n * 2*pi / 60));
[H.eta_max, kmax] = max(L.eta(:));
H.n_eta_max = NN(kmax);  H.T_eta_max = TT(kmax);
end
