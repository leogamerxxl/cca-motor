function R = sim_incarcare_medie(C, dt)
%SIM_INCARCARE_MEDIE Încărcarea completă CC-CV cu modelul mediu (fără comutație), pas dt [s].
%   CC: I = I_CC până când U_bat = OCV + R_bat*I atinge U_CV;  CV: U_bat = U_CV, I = (U_CV - OCV)/R_bat.
%   Se oprește când I < I_taiere.  OCV crește cu dOCV/dt = I / C_eq (în faza CV soluția exactă pe pas).
ic_P = C.P_bat / C.P_AC;                      % randamentul încărcătorului (PFC x coborâtor)
OCV = C.U_0 + (C.U_CV - C.U_0) * C.SOC0;
nmax = ceil(20 * 3600 / dt);
t = zeros(nmax, 1);  I = t;  U = t;  SOC = t;
k = 0;  tk = 0;  t_CC = NaN;
while k < nmax
    Ik = min(C.I_CC, (C.U_CV - OCV) / C.R_bat);
    if Ik < C.I_taiere, break; end
    k = k + 1;
    t(k) = tk;  I(k) = Ik;  U(k) = OCV + C.R_bat * Ik;  SOC(k) = (OCV - C.U_0) / (C.U_CV - C.U_0);
    if Ik < C.I_CC && isnan(t_CC), t_CC = tk; end
    if Ik >= C.I_CC
        OCV = OCV + C.I_CC * dt / C.C_eq;                         % faza CC (liniară)
    else
        OCV = C.U_CV - (C.U_CV - OCV) * exp(-dt / C.tau_CV);     % faza CV (exponențială, exactă)
    end
    tk = tk + dt;
end
t = t(1:k);  I = I(1:k);  U = U(1:k);  SOC = SOC(1:k);
R.t = t;  R.I = I;  R.U = U;  R.SOC = SOC;
R.P_bat = U .* I;
R.P_AC = R.P_bat / ic_P;
R.t_CC = t_CC;
R.t_total = t(end) + dt;
R.SOC_final = (OCV - C.U_0) / (C.U_CV - C.U_0);
R.E_bat = sum(R.P_bat) * dt;                     % energia intrată în baterie [Ws]
R.E_AC = sum(R.P_AC) * dt;                       % energia luată din rețea [Ws]
OCV0 = C.U_0 + (C.U_CV - C.U_0) * C.SOC0;
R.E_stocata = C.C_eq * (OCV^2 - OCV0^2) / 2;     % energia stocată: integrala OCV dQ, cu dQ = C_eq dOCV
R.E_pierderi_bat = R.E_bat - R.E_stocata;        % pierderile în R_bat [Ws]
end
