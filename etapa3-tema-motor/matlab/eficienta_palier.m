function E = eficienta_palier(S, M, T, N_activ, eta_acc, eta_rec)
%EFICIENTA_PALIER Randamentul lanțului baterie -> roți la viteza constantă V1 (palierul ciclului P3), în
%   regim staționar, cu N_activ motoare în funcțiune (celelalte decuplate mecanic, fără pierderi), și
%   energia ciclului P3 refăcută cu acest randament (accelerarea și frânarea cu eta_acc, eta_rec simulate).
%     cuplul pe motor: T = Ft1' * r / (N_activ * k_rd * eta_rd),  Omega = V1 * k_rd / r
%     P_baterie: P1 (harta C3) -> / eta_invertor -> / eta_DC-DC -> I_bat din P = (U_0 - R_bat*I)*I
R3 = S.R3;  r = S.C2.r;  ip = S.ip;  B = S.B;  cel = S.cel;
R_bat = B.Ns * cel.R_dc_mOhm * 1e-3 / B.Np;  U0 = B.U_nom;
W = R3.V1 / r * T.k_rd;
for q = 1:numel(N_activ)
    n = N_activ(q);
    Tm = R3.Ft1p * r / (n * T.k_rd * T.eta_rd);
    L = punct_functionare(M, W, Tm);
    P_bat = n * L.P1 / ip.eta_invertor / ip.eta_dcdc;
    I = (U0 - sqrt(U0^2 - 4 * R_bat * P_bat)) / (2 * R_bat);
    E(q).N_activ = n;
    E(q).T_motor = Tm;
    E(q).eta_motor = L.eta;
    E(q).P_bat = U0 * I;
    E(q).eta = R3.P1p / (U0 * I);
    E(q).W_stocata = R3.W01 / eta_acc + R3.W12 / E(q).eta - eta_rec * R3.W2f;
    E(q).rezerva = 1 - E(q).W_stocata / B.W_real;
end
end
