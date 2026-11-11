"""CCA – P5-P6: convertoarele DC-DC și încărcarea bateriei – implementarea Python.

Aceleași formule și aceleași simulări (pas fix, aceeași ordine a operațiilor) ca ../matlab/*.m.
"""
import json
import math
import sys
from pathlib import Path

import numpy as np

AICI = Path(__file__).resolve().parent
RADACINA = AICI.parent
sys.path.insert(0, str(RADACINA.parent / "etapa3-tema-motor" / "python"))
import model_p4 as mp  # noqa: E402


def incarca_date4():
    S = mp.incarca_date()
    S["M"] = mp.identificare_mcc(S["mot"], S["ip"])
    S["T"] = mp.tema_proiect(S, S["M"])
    S["cv"] = json.loads((RADACINA / "date" / "convertoare.json").read_text(encoding="utf-8"))
    return S


# ---------------------------------------------------------------- dimensionare_dcdc.m
def dimensionare_dcdc(S):
    M, T, B, cv, cel = S["M"], S["T"], S["B"], S["cv"]["dcdc"], S["cel"]
    D = dict(U_dc=T["U_conv"], U_bat_min=B["U_min"], U_bat_max=B["U_max"], U_bat_nom=B["U_nom"])
    D["R_bat"] = B["Ns"] * cel["R_dc_mOhm"] * 1e-3 / B["Np"]
    D["f_s"] = cv["f_s_Hz"]
    D["N_faze"] = cv["N_faze"]
    W = T["n_m_Va"] * 2 * math.pi / 60
    D["T_motor_Pmax"] = T["P_nec_max"] / (T["N"] * W)
    L = mp.scalar(mp.punct_functionare(M, W, D["T_motor_Pmax"]))
    D["eta_motor_Pmax"] = L["eta"]
    D["P1_motor_Pmax"] = L["P1"]
    D["P_dc_max"] = T["N"] * L["P1"] / cv["eta_invertor"]
    D["P_bat_max"] = D["P_dc_max"] / cv["eta_dcdc_ipoteza"]
    D["D_max"] = 1 - D["U_bat_min"] / D["U_dc"]
    D["D_min"] = 1 - D["U_bat_max"] / D["U_dc"]
    D["D_nom"] = 1 - D["U_bat_nom"] / D["U_dc"]
    D["I_bat_max"] = D["P_bat_max"] / D["U_bat_min"]
    D["I_faza_max"] = D["I_bat_max"] / D["N_faze"]
    D["I_dc_max"] = D["P_dc_max"] / D["U_dc"]
    U_crit = min(max(D["U_dc"] / 2, D["U_bat_min"]), D["U_bat_max"])
    D["U_bat_ondulatie_max"] = U_crit
    D["D_ondulatie_max"] = 1 - U_crit / D["U_dc"]
    D["dI"] = cv["ondulatie_I_rel"] * D["I_faza_max"]
    D["L"] = U_crit * D["D_ondulatie_max"] / (D["dI"] * D["f_s"])
    D["I_varf_faza"] = D["I_faza_max"] + D["dI"] / 2
    D["W_L"] = 0.5 * D["L"] * D["I_varf_faza"] ** 2
    D["dU"] = cv["ondulatie_U_rel"] * D["U_dc"]
    D["C"] = D["I_dc_max"] * D["D_max"] / (D["dU"] * D["f_s"])
    md = cv["modul"]
    D["modul"] = md["nume"]
    D["ok_U_modul"] = md["U_DS_V"] >= D["U_dc"] / 0.8
    D["ok_I_modul"] = D["I_varf_faza"] <= cv["rezerva_curent"] * md["I_D_A"]
    I = D["I_faza_max"]
    D["I_rms_faza"] = math.sqrt(I ** 2 + D["dI"] ** 2 / 12)
    D["P_cond_faza"] = md["R_DS_on_cald_mOhm"] * 1e-3 * D["I_rms_faza"] ** 2
    if md["E_ref_U_V"] > 0 and md["E_ref_I_A"] > 0:
        D["P_com_faza"] = D["f_s"] * (md["E_on_mJ"] + md["E_off_mJ"]) * 1e-3 * (D["U_dc"] / md["E_ref_U_V"]) \
            * (I / md["E_ref_I_A"])
    else:
        D["P_com_faza"] = math.nan
    D["P_pierderi"] = D["N_faze"] * (D["P_cond_faza"] + D["P_com_faza"])
    D["eta_calc"] = D["P_dc_max"] / (D["P_dc_max"] + D["P_pierderi"])
    D["Dc_min"] = D["U_bat_min"] / D["U_dc"]
    D["Dc_max"] = D["U_bat_max"] / D["U_dc"]
    return D


# ---------------------------------------------------------------- dimensionare_chopper.m
def dimensionare_chopper(S):
    M, cv, T = S["M"], S["cv"]["chopper"], S["T"]
    H = dict(U_dc=T["U_conv"], f_pwm=cv["f_pwm_Hz"], L_a=M["L_a"])
    H["dI_max"] = H["U_dc"] / (8 * H["L_a"] * H["f_pwm"])
    H["dT_max"] = M["k"] * H["dI_max"]
    H["I_max"] = M["I_max"]
    H["I_varf"] = M["I_max"] + H["dI_max"] / 2
    H["dI_max_rel"] = H["dI_max"] / M["I_max"]
    W = np.array([M["W_n"], min(M["W_b"], M["P_max"] / M["M_max"]), T["n_m_Va"] * 2 * math.pi / 60])
    Tq = np.array([M["M_n"], M["M_max"], T["P_nec_max"] / (T["N"] * W[2])])
    L = mp.punct_functionare(M, W, Tq)
    H["m"] = L["U"] / H["U_dc"]
    H["dI"] = H["U_dc"] * H["m"] * (1 - H["m"]) / (2 * H["L_a"] * H["f_pwm"])
    H["I"] = L["I"]
    return H


# ---------------------------------------------------------------- dimensionare_incarcator.m
def dimensionare_incarcator(S):
    B, cel, ic = S["B"], S["cel"], S["cv"]["incarcator"]
    C = dict(P_AC=ic["P_AC_W"], U_AC=ic["U_AC_V"], U_dc=ic["U_dc_PFC_V"])
    C["U_dc_min_PFC"] = math.sqrt(2) * C["U_AC"]
    C["ok_U_PFC"] = C["U_dc"] > C["U_dc_min_PFC"] and C["U_dc"] > B["U_max"]
    C["P_bat"] = C["P_AC"] * ic["eta_PFC"] * ic["eta_buck"]
    C["U_CV"] = B["Ns"] * cel["U_max"]
    C["I_CC"] = C["P_bat"] / C["U_CV"]
    C["C_rate"] = C["I_CC"] / B["Cap_Ah"]
    C["I_cel_CC"] = C["I_CC"] / B["Np"]
    C["I_taiere"] = ic["I_taiere_celula_A"] * B["Np"]
    C["D_min"] = B["U_min"] / C["U_dc"]
    C["D_max"] = C["U_CV"] / C["U_dc"]
    Dc = min(max(0.5, C["D_min"]), C["D_max"])
    C["h"] = ic["ondulatie_I_rel"] * C["I_CC"]
    C["L"] = C["U_dc"] * Dc * (1 - Dc) / (C["h"] * ic["f_s_max_Hz"])
    C["f_la_U_nom"] = C["U_dc"] * (B["U_nom"] / C["U_dc"]) * (1 - B["U_nom"] / C["U_dc"]) / (C["h"] * C["L"])
    C["R_bat"] = B["Ns"] * cel["R_dc_mOhm"] * 1e-3 / B["Np"]
    C["Q"] = B["Cap_Ah"] * 3600
    C["U_0"] = B["Ns"] * ic["OCV_celula_SOC0_V"]
    C["C_eq"] = C["Q"] / (C["U_CV"] - C["U_0"])
    C["tau_CV"] = C["R_bat"] * C["C_eq"]
    C["SOC0"] = ic["SOC_initial"]
    C["SOC_CC"] = (C["U_CV"] - C["R_bat"] * C["I_CC"] - C["U_0"]) / (C["U_CV"] - C["U_0"])
    C["t_CC"] = (C["SOC_CC"] - C["SOC0"]) * C["Q"] / C["I_CC"]
    C["t_CV"] = C["tau_CV"] * math.log(C["I_CC"] / C["I_taiere"])
    C["t_total"] = C["t_CC"] + C["t_CV"]
    return C


# ---------------------------------------------------------------- sim_incarcare_medie.m
def sim_incarcare_medie(C, dt):
    ic_P = C["P_bat"] / C["P_AC"]
    OCV = C["U_0"] + (C["U_CV"] - C["U_0"]) * C["SOC0"]
    OCV0 = OCV
    nmax = math.ceil(20 * 3600 / dt)
    t, I, U, SOC = [], [], [], []
    tk = 0.0
    t_CC = math.nan
    k = 0
    E_bat = 0.0
    while k < nmax:
        Ik = min(C["I_CC"], (C["U_CV"] - OCV) / C["R_bat"])
        if Ik < C["I_taiere"]:
            break
        k += 1
        t.append(tk)
        I.append(Ik)
        U.append(OCV + C["R_bat"] * Ik)
        SOC.append((OCV - C["U_0"]) / (C["U_CV"] - C["U_0"]))
        if Ik < C["I_CC"] and math.isnan(t_CC):
            t_CC = tk
        if Ik >= C["I_CC"]:
            OCV_nou = OCV + C["I_CC"] * dt / C["C_eq"]
            E_bat = E_bat + C["I_CC"] * ((OCV + OCV_nou) / 2 + C["R_bat"] * C["I_CC"]) * dt
        else:
            OCV_nou = C["U_CV"] - (C["U_CV"] - OCV) * math.exp(-dt / C["tau_CV"])
            E_bat = E_bat + C["U_CV"] * C["C_eq"] * (OCV_nou - OCV)
        OCV = OCV_nou
        tk = tk + dt
    R = dict(t=np.array(t), I=np.array(I), U=np.array(U), SOC=np.array(SOC))
    R["P_bat"] = R["U"] * R["I"]
    R["P_AC"] = R["P_bat"] / ic_P
    R["t_CC"] = t_CC
    R["t_total"] = t[-1] + dt
    R["SOC_final"] = (OCV - C["U_0"]) / (C["U_CV"] - C["U_0"])
    R["E_bat"] = E_bat
    R["E_AC"] = E_bat / ic_P
    R["E_stocata"] = C["C_eq"] * (OCV ** 2 - OCV0 ** 2) / 2
    R["E_pierderi_bat"] = R["E_bat"] - R["E_stocata"]
    return R


# ---------------------------------------------------------------- sim_incarcare_comutatie.m
def sim_incarcare_comutatie(C, sc):
    dt = sc["dt"]
    n = int(math.floor(sc["t_end"] / dt + 0.5))
    Cs = C["C_eq"] / sc["k_timp"]
    R = dict(C_s=Cs, tau_s=C["R_bat"] * Cs)
    OCV = C["U_CV"] - C["R_bat"] * C["I_CC"] - C["I_CC"] * sc["t_CC_s"] / Cs
    R["OCV0"] = OCV
    wc = 2 * math.pi * sc["fc_U_Hz"]
    Kp = sc["Kp_R"] / C["R_bat"]
    Ki = wc / abs(C["R_bat"] + 1 / (1j * wc * Cs))
    R["Kp"], R["Ki"] = Kp, Ki
    i, s, z, h = 0.0, 1, C["I_CC"] / Ki, C["h"]
    Uf = OCV
    tf = sc["tau_filtru_s"]
    tfi = sc["tau_filtru_I_s"]
    If = 0.0
    oprit = False
    t_stop = math.nan
    Rb, UCV, ICC, Udc, L = C["R_bat"], C["U_CV"], C["I_CC"], C["U_dc"], C["L"]
    t_, I_, U_, Iref_, S_ = [0.0], [i], [OCV], [ICC], [s]
    nr = 0
    nr_cc = 0
    t_CC = math.nan
    k_cc = int(math.floor(sc["t_CC_s"] * 0.9 / dt + 0.5))
    sal = sc["salvare"]
    for k in range(1, n + 1):
        U = OCV + Rb * i
        Uf = Uf + (U - Uf) * dt / tf
        e = UCV - Uf
        iu = Kp * e + Ki * z
        Iref = min(max(iu, 0.0), ICC)
        if iu == Iref or (iu > ICC and e < 0) or (iu < 0 and e > 0):
            z = z + e * dt
        if math.isnan(t_CC) and Iref < 0.99 * ICC:
            t_CC = (k - 1) * dt
        If = If + (i - If) * dt / tfi
        if not oprit and not math.isnan(t_CC) and If < C["I_taiere"]:
            oprit = True
            t_stop = (k - 1) * dt
        s_vechi = s
        if oprit:
            s = 0
            Iref = 0.0
        elif i >= Iref + h / 2:
            s = 0
        elif i <= Iref - h / 2:
            s = 1
        if s == 1 and s_vechi == 0:
            nr += 1
        di = (s * Udc - U) / L
        i = i + di * dt
        if i < 0:
            i = 0.0
        OCV = OCV + i * dt / Cs
        if k % sal == 0:
            t_.append(k * dt)
            I_.append(i)
            U_.append(OCV + Rb * i)
            Iref_.append(Iref)
            S_.append(s)
        if k == k_cc:
            nr_cc = nr
    R.update(t=np.array(t_), I=np.array(I_), U=np.array(U_), Iref=np.array(Iref_), s=np.array(S_))
    R["t_CC"] = t_CC
    R["t_stop"] = t_stop
    R["t_stop_teoretic"] = sc["t_CC_s"] + R["tau_s"] * math.log(ICC / C["I_taiere"])
    R["f_CC"] = nr_cc / (sc["t_CC_s"] * 0.9)
    R["f_CC_teoretic"] = Udc * (UCV / Udc) * (1 - UCV / Udc) / (h * L)
    tt = sc["t_CC_s"] + R["tau_s"]
    m = np.abs(R["t"] - tt) <= 1 / R["f_CC"]
    R["I_med_tau"] = float(np.mean(R["I"][m]))
    R["I_med_tau_teoretic"] = ICC * math.exp(-1)
    R["U_final"] = float(R["U"][-1])
    return R


# ---------------------------------------------------------------- sim_dcdc_comutatie.m
def sim_dcdc_comutatie(D, sc):
    N, L, Cdc, Udc_ref, Rb, U0 = D["N_faze"], D["L"], D["C"], D["U_dc"], D["R_bat"], sc["U_bat_V"]
    dt = sc["dt"]
    n = int(math.floor(sc["t_end"] / dt + 0.5))
    npp = int(math.floor(1 / (D["f_s"] * dt) + 0.5))
    wci = 2 * math.pi * sc["fc_I_Hz"]
    Kpi = L * wci
    Kii = Kpi * wci / 10
    wcu = 2 * math.pi * sc["fc_U_Hz"]
    Kpu = Cdc * wcu
    Kiu = Kpu * wcu / 5
    Imax = 1.2 * D["I_bat_max"]
    i = [0.0] * N
    zi = [0.0] * N
    u = Udc_ref
    zu = 0.0
    dec = [int(math.floor((q * npp) / N + 0.5)) for q in range(N)]
    fer = [(sc["t_franare"] - 1e-3, sc["t_franare"]), (sc["t_end"] - 1e-3, sc["t_end"])]
    A = [[0.0] * 4 for _ in range(2)]
    mn = [[math.inf] * 3 for _ in range(2)]
    mx = [[-math.inf] * 3 for _ in range(2)]
    cnt = [0, 0]
    t_, IL, UDC, IB, UB, DD, P_ = [0.0], [[0.0] * N], [u], [0.0], [U0], [0.0], [0.0]
    sal = sc["salvare"]
    d = [0.0] * N
    for k in range(1, n + 1):
        tk = (k - 1) * dt
        if tk < sc["t_tractiune"]:
            P = 0.0
        elif tk < sc["t_franare"]:
            P = D["P_dc_max"]
        else:
            P = -sc["P_franare_rel"] * D["P_dc_max"]
        isarc = P / u
        ib = sum(i)
        Ub = U0 - Rb * ib
        eu = Udc_ref - u
        ic = Kpu * eu + Kiu * zu
        iref = (P + u * ic) / Ub
        iref_s = min(max(iref, -Imax), Imax)
        if iref == iref_s or (iref > Imax and eu < 0) or (iref < -Imax and eu > 0):
            zu = zu + eu * dt
        s = [0] * N
        for q in range(N):
            ei = iref_s / N - i[q]
            v = Kpi * ei + Kii * zi[q]
            dq = 1 - (Ub - v) / u
            d[q] = min(max(dq, 0.0), 1.0)
            if dq == d[q] or (dq > 1 and ei < 0) or (dq < 0 and ei > 0):
                zi[q] = zi[q] + ei * dt
            faza = (k - 1 + dec[q]) % npp
            purt = 1 - abs(2 * faza / npp - 1)
            s[q] = 1 if d[q] > purt else 0
        di = [(Ub - (1 - s[q]) * u) / L for q in range(N)]
        du = (sum((1 - s[q]) * i[q] for q in range(N)) - isarc) / Cdc
        i = [i[q] + di[q] * dt for q in range(N)]
        u = u + du * dt
        for w in range(2):
            if fer[w][0] < k * dt <= fer[w][1] + dt / 2:
                v3 = (i[0], sum(i), u)
                for c, val in enumerate((i[0], sum(i), u, d[0])):
                    A[w][c] += val
                for c in range(3):
                    mn[w][c] = min(mn[w][c], v3[c])
                    mx[w][c] = max(mx[w][c], v3[c])
                cnt[w] += 1
        if k % sal == 0:
            t_.append(k * dt)
            IL.append(list(i))
            UDC.append(u)
            IB.append(sum(i))
            UB.append(U0 - Rb * sum(i))
            DD.append(d[0])
            P_.append(P)
    R = dict(t=np.array(t_), IL=np.array(IL), UDC=np.array(UDC), IB=np.array(IB), UB=np.array(UB), D=np.array(DD),
             P=np.array(P_), Kpi=Kpi, Kii=Kii, Kpu=Kpu, Kiu=Kiu, np=npp)

    def indicatori(w):
        med = [a / cnt[w] for a in A[w]]
        X = dict(I_faza_med=med[0], dI_faza=mx[w][0] - mn[w][0], dI_bat=mx[w][1] - mn[w][1],
                 dU_dc=mx[w][2] - mn[w][2], U_dc_med=med[2], I_bat_med=med[1])
        X["U_bat_med"] = U0 - Rb * X["I_bat_med"]
        X["D_med"] = med[3]
        X["D_teoretic"] = 1 - X["U_bat_med"] / D["U_dc"]
        X["dI_faza_teoretic"] = X["U_bat_med"] * X["D_teoretic"] / (D["L"] * D["f_s"])
        return X

    R["tr"] = indicatori(0)
    R["rec"] = indicatori(1)
    m1 = (R["t"] >= sc["t_tractiune"]) & (R["t"] < sc["t_franare"])
    R["U_dc_min"] = float(R["UDC"][m1].min())
    R["U_dc_max"] = float(R["UDC"][R["t"] >= sc["t_franare"]].max())
    return R


def calculeaza_tot(cu_simulari=True):
    S = incarca_date4()
    R = dict(S=S, D=dimensionare_dcdc(S), H=dimensionare_chopper(S), C=dimensionare_incarcator(S))
    if cu_simulari:
        sim = S["cv"]["simulare"]
        R["Im"] = sim_incarcare_medie(R["C"], S["cv"]["incarcator"]["dt_medie_s"])
        R["Ic"] = sim_incarcare_comutatie(R["C"], sim["incarcare"])
        R["Dc"] = sim_dcdc_comutatie(R["D"], sim["dcdc"])
    return R
