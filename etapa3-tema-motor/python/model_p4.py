"""CCA – P4 / C3: modelul mașinii (echivalentul MCC al motorului YM720) – implementarea Python.

Aceleași formule și același integrator RK4 cu pas fix ca fișierele din ../matlab/*.m, ca rezultatele
să poată fi comparate exact (vezi calcule_p4.py).
"""
import json
import math
import sys
from pathlib import Path

import numpy as np

AICI = Path(__file__).resolve().parent
RADACINA = AICI.parent
ETAPA2 = RADACINA.parent / "etapa2-calcule"
sys.path.insert(0, str(ETAPA2 / "python"))
import calcule_p2_p3 as e2  # noqa: E402

RPM = 60 / (2 * math.pi)


def sgn(x):
    return (x > 0) - (x < 0)


def trapz(t, y):
    t = np.asarray(t, float)
    y = np.asarray(y, float)
    if t.size < 2:
        return 0.0
    return float(np.dot(np.diff(t), y[:-1] + y[1:]) / 2)


# ---------------------------------------------------------------- date (incarca_date.m)
def incarca_date():
    cel = json.loads((ETAPA2 / "date" / "celula_aleasa.json").read_text(encoding="utf-8"))
    e2.CELULA = cel
    tab, rez = e2.ruleaza(ETAPA2 / "date" / "date_documentare.csv", cel)
    m = rez["medie"]
    S = dict(C2=e2.C, V=m["date"], R2=m["p2"], R3=m["p3"], B=m["baterie"], cel=cel, n_vehicule=len(tab))
    S["mot"] = json.loads((RADACINA / "date" / "motor_ales.json").read_text(encoding="utf-8"))
    S["ip"] = json.loads((RADACINA / "date" / "ipoteze_masina.json").read_text(encoding="utf-8"))
    return S


# ---------------------------------------------------------------- identificare_mcc.m
def identificare_mcc(mot, ip):
    M = {}
    M["U_n"] = ip["U_n_V"]
    M["dU_p"] = ip["dU_p_V"]
    M["P_n"] = mot["P_n_kW"] * 1e3
    M["M_n"] = mot["M_n_Nm"]
    M["P_max"] = mot["P_max_kW"] * 1e3
    M["M_max"] = mot["M_max_Nm"]
    M["W_n"] = M["P_n"] / M["M_n"]
    M["n_n"] = M["W_n"] * 60 / (2 * math.pi)
    M["n_max"] = mot["n_max_rpm"]
    M["W_max"] = M["n_max"] * 2 * math.pi / 60
    M["eta_n"] = ip["eta_n"]
    M["P1_n"] = M["P_n"] / M["eta_n"]
    M["SP_n"] = M["P1_n"] - M["P_n"]
    M["I_n"] = M["P1_n"] / M["U_n"]
    M["P_a_n"] = ip["cota_Cu"] * M["SP_n"]
    M["R_a"] = M["P_a_n"] / M["I_n"] ** 2
    M["P_p_n"] = M["dU_p"] * M["I_n"]
    M["P_Fe_n"] = ip["cota_Fe"] * M["SP_n"]
    M["P_fv_n"] = M["SP_n"] - M["P_a_n"] - M["P_p_n"] - M["P_Fe_n"]
    M["P_Fe_max"] = ip["raport_Fe_max"] * M["P_Fe_n"]
    A = np.array([[M["W_n"], M["W_n"] ** 2], [M["W_max"], M["W_max"] ** 2]])
    x = np.linalg.solve(A, [M["P_Fe_n"], M["P_Fe_max"]])
    M["K_H"], M["K_F"] = float(x[0]), float(x[1])
    M["P_fv_max"] = ip["raport_mec_max"] * M["P_fv_n"]
    x = np.linalg.solve(A, [M["P_fv_n"], M["P_fv_max"]])
    M["T_m0"], M["F_m"] = float(x[0]), float(x[1])
    M["T_f0"] = M["K_H"] + M["T_m0"]
    M["F_v"] = M["K_F"] + M["F_m"]
    M["E_n"] = M["U_n"] - M["R_a"] * M["I_n"] - M["dU_p"]
    M["k"] = M["E_n"] / M["W_n"]
    M["T_ax_n_verif"] = M["k"] * M["I_n"] - M["T_f0"] - M["F_v"] * M["W_n"]
    W_b = M["W_n"]
    for _ in range(100):
        I = (M["M_max"] + M["T_f0"] + M["F_v"] * W_b) / M["k"]
        W_b = (M["U_n"] - M["R_a"] * I - M["dU_p"]) / M["k"]
    M["W_b"] = W_b
    M["I_max"] = (M["M_max"] + M["T_f0"] + M["F_v"] * M["W_b"]) / M["k"]
    M["n_b"] = M["W_b"] * 60 / (2 * math.pi)
    M["P_b"] = M["M_max"] * M["W_b"]
    M["I_p_Un"] = (M["U_n"] - M["dU_p"]) / M["R_a"]
    M["M_p_Un"] = M["k"] * M["I_p_Un"]
    M["U_p"] = M["R_a"] * M["I_max"] + M["dU_p"]
    M["L_a"] = ip["L_a_H"]
    M["J_rotor"] = ip["J_rotor_kgm2"]
    M["tau_a"] = M["L_a"] / M["R_a"]
    M["masa"] = mot["masa_kg"]
    M["c"] = ip["c_J_kgK"]
    return M


# ---------------------------------------------------------------- punct_functionare.m
def punct_functionare(M, W, T_ax):
    W, T_ax = np.broadcast_arrays(np.atleast_1d(np.asarray(W, float)), np.atleast_1d(np.asarray(T_ax, float)))
    T_E = T_ax + M["T_f0"] + M["F_v"] * W
    U_pf = M["k"] * W + M["R_a"] * T_E / M["k"] + M["dU_p"]
    disc = (M["U_n"] - M["dU_p"]) ** 2 - 4 * W * M["R_a"] * T_E
    x = np.full(W.shape, M["k"])
    slab = U_pf > M["U_n"]
    x[slab] = ((M["U_n"] - M["dU_p"]) + np.sqrt(np.maximum(disc[slab], 0))) / (2 * W[slab])
    L = {}
    L["phi"] = x / M["k"]
    L["I"] = T_E / x
    L["E"] = x * W
    L["U"] = L["E"] + M["R_a"] * L["I"] + M["dU_p"]
    L["T_E"] = T_E
    L["P1"] = L["U"] * L["I"]
    L["P_a"] = M["R_a"] * L["I"] ** 2
    L["P_p"] = M["dU_p"] * L["I"]
    L["P_em"] = L["E"] * L["I"]
    L["P_Fe"] = M["K_H"] * W + M["K_F"] * W ** 2
    L["P_fv"] = M["T_m0"] * W + M["F_m"] * W ** 2
    L["P2"] = T_ax * W
    L["SP"] = L["P1"] - L["P2"]
    with np.errstate(invalid="ignore", divide="ignore"):
        L["eta"] = L["P2"] / L["P1"]
    with np.errstate(divide="ignore"):
        lim = np.minimum(M["M_max"], M["P_max"] / W)
    L["in_anvelopa"] = (T_ax <= lim + 1e-9) & (W <= M["W_max"] + 1e-9) & ((disc >= 0) | ~slab)
    L["eta"] = np.where(L["in_anvelopa"], L["eta"], np.nan)
    return L


def scalar(L):
    return {k: (v.item() if np.size(v) == 1 else v) for k, v in L.items()}


# ---------------------------------------------------------------- tema_proiect.m
def tema_proiect(S, M):
    R2, ip, mot, B = S["R2"], S["ip"], S["mot"], S["B"]
    N = mot["numar_motoare"]
    T = {}
    T["P_rn"] = R2["Pr_vmax"]
    T["M_rn"] = R2["Mr_vmax"]
    T["n_rn"] = R2["Omega_r_max"] * RPM
    T["P_rmax"] = R2["Pr"]
    T["M_rmax"] = R2["Mr"]
    T["n_rmax"] = R2["Omega_r_max"] * RPM
    T["n_r_Va"] = R2["Omega_r_Va"] * RPM
    T["k_rd"] = ip["k_rd"]
    T["i_rd"] = 1 / T["k_rd"]
    T["eta_rd"] = ip["eta_rd"]
    T["n_m_vmax"] = T["n_rmax"] * T["k_rd"]
    T["n_m_Va"] = T["n_r_Va"] * T["k_rd"]
    T["P_nec_max"] = R2["P_max"]
    T["P_nec_n"] = R2["P_nom"]
    T["M_nec_max"] = T["M_rmax"] / (T["k_rd"] * T["eta_rd"])
    T["M_nec_n"] = T["P_nec_n"] / (T["n_m_vmax"] / RPM)
    f_fata = ip["repartitie_statica_fata"] - R2["a"] / S["C2"]["g"] * ip["h_L"]
    T["f_fata"] = f_fata
    T["M_nec_fata"] = f_fata * T["M_nec_max"]
    T["M_nec_spate"] = (1 - f_fata) * T["M_nec_max"] / 2
    T["N"] = N
    T["ME_P_n"], T["ME_P_max"] = M["P_n"], M["P_max"]
    T["ME_M_n"], T["ME_M_max"] = M["M_n"], M["M_max"]
    T["ME_n_n"], T["ME_n_max"], T["ME_n_b"] = M["n_n"], M["n_max"], M["n_b"]
    T["ME_U_n"], T["ME_I_n"], T["ME_I_max"] = M["U_n"], M["I_n"], M["I_max"]
    T["ok_P_max"] = N * M["P_max"] >= T["P_nec_max"]
    T["ok_P_n"] = N * M["P_n"] >= T["P_nec_n"]
    T["ok_M_fata"] = M["M_max"] >= T["M_nec_fata"]
    T["ok_M_spate"] = M["M_max"] >= T["M_nec_spate"]
    T["ok_n_max"] = M["n_max"] >= T["n_m_vmax"]
    T["M_roti_disp"] = N * M["M_max"] * T["k_rd"] * T["eta_rd"]
    T["ok_M_roti"] = T["M_roti_disp"] >= T["M_rmax"]
    T["ok_U"] = mot["U_dc_min_V"] <= ip["U_conv_V"] <= mot["U_dc_max_V"]
    T["U_conv"] = ip["U_conv_V"]
    T["U_bat_min"], T["U_bat_max"], T["U_bat_nom"] = B["U_min"], B["U_max"], B["U_nom"]
    T["D_max"] = 1 - B["U_min"] / T["U_conv"]
    T["D_min"] = 1 - B["U_max"] / T["U_conv"]
    T["P_el_max"] = T["P_nec_max"] / S["C2"]["eta"]
    T["I_conv"] = T["P_el_max"] / T["U_conv"]
    T["I_bat_max"] = T["P_el_max"] / B["U_min"]
    T["W_bat_nec"] = S["R3"]["Wbat"]
    T["W_bat_inst"] = B["W_real"]
    T["ok_W_bat"] = T["W_bat_inst"] >= T["W_bat_nec"]
    T["ok_I_cel"] = B["I_celula"] <= S["cel"]["I_max_cont"]
    T["P_bat_disp"] = S["cel"]["I_max_cont"] * B["Np"] * B["U_min"]
    T["P_mec_disp"] = T["P_bat_disp"] * S["C2"]["eta"]
    T["ok_P_bat"] = T["P_mec_disp"] >= T["P_nec_max"]
    return T


# ---------------------------------------------------------------- parametri_model.m
def parametri_model(S, M, T, scenariu):
    C2, V = S["C2"], S["V"]
    N, k_rd, r = T["N"], T["k_rd"], C2["r"]
    P = dict(R=M["R_a"], L=M["L_a"], k=M["k"], dUp=M["dU_p"], Tf0=M["T_f0"], Fv=M["F_v"], W_b=M["W_b"],
             U_n=M["U_n"], U_min=0.0)
    if scenariu == "gol":
        P.update(J=M["J_rotor"], a0=0.0, a2=0.0)
    elif scenariu == "vehicul":
        P["J"] = M["J_rotor"] + V["M"] * r ** 2 / (N * k_rd ** 2)
        Ff = C2["mu_f"] * V["M"] * C2["g"] * math.cos(C2["alpha"])
        P["a0"] = Ff * r / (N * k_rd * T["eta_rd"])
        P["a2"] = 0.5 * C2["rho"] * V["S"] * V["Cx"] * (r / k_rd) ** 2 * r / (N * k_rd * T["eta_rd"])
    else:
        raise ValueError(scenariu)
    P["slabire"] = True
    return P


# ---------------------------------------------------------------- derivata_mcc.m
def derivata_mcc(t, x, P):
    I, W, z, zw = x
    phi = P["W_b"] / W if (P["slabire"] and W > P["W_b"]) else 1.0
    dz = 0.0
    dzw = 0.0
    Iref = math.nan
    mod = P["mod"]
    if mod == "tensiune":
        U = P["U_fun"](t)
    elif mod in ("curent", "viteza"):
        if mod == "curent":
            Iref = P["Iref_fun"](W, phi)
        else:
            ew = P["Wref_fun"](t) - W
            Tu = P["Kp_w"] * ew + P["Ki_w"] * zw
            Tl = P["Tlim_fun"](W)
            Tref = min(max(Tu, -Tl), Tl)
            if Tu == Tref or (Tu > Tl and ew < 0) or (Tu < -Tl and ew > 0):
                dzw = ew
            Iref = (Tref + P["Tf0"] * sgn(W) + P["Fv"] * W) / (P["k"] * phi)
        e = Iref - I
        u = P["Kp"] * e + P["Ki"] * z
        U = min(max(u, P["U_min"]), P["U_n"])
        if u == U or (u > P["U_n"] and e < 0) or (u < P["U_min"] and e > 0):
            dz = e
    else:
        raise ValueError(mod)
    T_E = P["k"] * phi * I
    T_ax = T_E - P["Tf0"] * sgn(W) - P["Fv"] * W
    T_s = P["a0"] * sgn(W) + P["a2"] * W ** 2
    dI = (U - P["R"] * I - P["dUp"] * sgn(I) - P["k"] * phi * W) / P["L"]
    dW = (T_ax - T_s) / P["J"]
    if W <= 0 and dW < 0:
        dW = 0.0
    return [dI, dW, dz, dzw], [U, phi, T_E, T_ax, T_s, Iref]


# ---------------------------------------------------------------- rk4.m
def rk4(P, t_end, dt, x0, pas_salvare, conditie_stop=None):
    n = int(math.floor(t_end / dt + 0.5))
    x = [float(v) for v in x0]
    _, y = derivata_mcc(0.0, x, P)
    ts, Xs, Ys = [0.0], [list(x)], [y]
    h2 = dt / 2
    h6 = dt / 6
    for i in range(1, n + 1):
        ti = (i - 1) * dt
        k1, _ = derivata_mcc(ti, x, P)
        k2, _ = derivata_mcc(ti + dt / 2, [x[j] + h2 * k1[j] for j in range(4)], P)
        k3, _ = derivata_mcc(ti + dt / 2, [x[j] + h2 * k2[j] for j in range(4)], P)
        k4, _ = derivata_mcc(ti + dt, [x[j] + dt * k3[j] for j in range(4)], P)
        x = [x[j] + h6 * (k1[j] + 2 * k2[j] + 2 * k3[j] + k4[j]) for j in range(4)]
        if x[1] < 0:
            x[1] = 0.0
        oprire = conditie_stop is not None and conditie_stop(x)
        if i % pas_salvare == 0 or oprire:
            _, y = derivata_mcc(i * dt, x, P)
            ts.append(i * dt)
            Xs.append(list(x))
            Ys.append(y)
        if oprire:
            break
    return np.array(ts), np.array(Xs), np.array(Ys)


def interp_timp(t, v, vx):
    k = np.nonzero(v >= vx)[0]
    if k.size == 0 or k[0] == 0:
        return math.nan
    k = k[0]
    return float(t[k - 1] + (vx - v[k - 1]) * (t[k] - t[k - 1]) / (v[k] - v[k - 1]))


# ---------------------------------------------------------------- simulari.m
def simulari(S, M, T):
    ip, r, N, k_rd = S["ip"], S["C2"]["r"], T["N"], T["k_rd"]
    sim = ip["simulare"]
    Z = {}
    P = parametri_model(S, M, T, "gol")
    P["mod"] = "tensiune"
    P["U_fun"] = lambda t: M["U_p"]
    t, X, Y = rk4(P, sim["A_t_end"], sim["A_dt"], [0, 0, 0, 0], sim["A_salvare"])
    Z["A"] = dict(t=t, I=X[:, 0], W=X[:, 1], U=Y[:, 0], T_ax=Y[:, 3], I_varf=float(X[:, 0].max()),
                  W_final=float(X[-1, 1]),
                  W_gol_teoretic=(M["U_p"] - M["dU_p"] - M["R_a"] * M["T_f0"] / M["k"])
                  / (M["k"] + M["R_a"] * M["F_v"] / M["k"]))
    P = parametri_model(S, M, T, "vehicul")
    P["mod"] = "curent"
    wc = 2 * math.pi * sim["B_fc_Hz"]
    P["Kp"] = P["L"] * wc
    P["Ki"] = P["R"] * wc
    T_ad = S["R2"]["Fa"] * r / (N * k_rd * T["eta_rd"])
    P["Iref_fun"] = lambda W, phi: (min([T_ad, M["M_max"], M["P_max"] / max(W, 1e-6)]) + M["T_f0"]
                                    + M["F_v"] * W) / (M["k"] * phi)
    W_vmax = S["V"]["vmax"] * k_rd / r
    t, X, Y = rk4(P, sim["B_t_end"], sim["B_dt"], [0, 0, 0, 0], sim["B_salvare"], lambda x: x[1] >= W_vmax)
    v = X[:, 1] * r / k_rd
    B = dict(t=t, I=X[:, 0], W=X[:, 1], v=v, U=Y[:, 0], phi=Y[:, 1], T_ax=Y[:, 3], T_ad=T_ad)
    B["t_100"] = interp_timp(t, v, 100 / 3.6)
    B["t_200"] = interp_timp(t, v, 200 / 3.6)
    B["t_vmax"] = float(t[-1])
    B["atins_vmax"] = bool(X[-1, 1] >= W_vmax)
    B["I_varf"] = float(X[:, 0].max())
    Z["B"] = B
    P = parametri_model(S, M, T, "vehicul")
    P["mod"] = "tensiune"
    P["U_fun"] = lambda t: min(max(sim["D_U0"] + sim["D_panta"] * t, 0), M["U_n"])
    t, X, Y = rk4(P, sim["D_t_end"], sim["D_dt"], [0, 0, 0, 0], sim["D_salvare"])
    Z["D"] = dict(t=t, I=X[:, 0], W=X[:, 1], v=X[:, 1] * r / k_rd, U=Y[:, 0], phi=Y[:, 1], T_ax=Y[:, 3],
                  I_varf=float(X[:, 0].max()), W_final=float(X[-1, 1]))
    return Z


# ---------------------------------------------------------------- simulare_ansamblu.m
def simulare_ansamblu(S, M, T):
    ip, r, N, k_rd = S["ip"], S["C2"]["r"], T["N"], T["k_rd"]
    c, R3, B, cel = ip["simulare"], S["R3"], S["B"], S["cel"]
    a, V1, t1 = R3["a"], R3["V1"], R3["t1"]
    t2 = t1 + c["C_t_palier"]
    t3 = t2 + t1
    t_end = t3 + c["C_t_oprire"]

    def v_ref(t):
        return a * np.minimum(t, t1) - a * np.minimum(np.maximum(t - t2, 0), t1)

    C = dict(t1=t1, t2=t2, t3=t3, a=a, V1=V1)
    P = parametri_model(S, M, T, "vehicul")
    P["mod"] = "viteza"
    P["U_min"] = -M["U_n"]
    wc = 2 * math.pi * c["B_fc_Hz"]
    P["Kp"] = P["L"] * wc
    P["Ki"] = P["R"] * wc
    wn, zeta = c["C_wn_viteza"], c["C_zeta_viteza"]
    P["Kp_w"] = 2 * zeta * wn * P["J"]
    P["Ki_w"] = wn ** 2 * P["J"]
    T_ad = S["R2"]["Fa"] * r / (N * k_rd * T["eta_rd"])
    P["Tlim_fun"] = lambda W: min([T_ad, M["M_max"], M["P_max"] / max(W, 1e-6)])
    P["Wref_fun"] = lambda t: float(v_ref(t)) * k_rd / r
    C.update(Kp_w=P["Kp_w"], Ki_w=P["Ki_w"], J=P["J"], T_ad=T_ad)
    t, X, Y = rk4(P, t_end, c["C_dt"], [0, 0, 0, 0], c["C_salvare"])
    C.update(t=t, I=X[:, 0], W=X[:, 1], v=X[:, 1] * r / k_rd, v_ref=v_ref(t), U=Y[:, 0], phi=Y[:, 1],
             T_ax=Y[:, 3], I_ref=Y[:, 5])
    C["eroare_v_max"] = float(np.max(np.abs(C["v"] - C["v_ref"])))
    C["P_ax"] = N * C["T_ax"] * C["W"]
    C["P_el"] = N * C["U"] * C["I"]
    C["P_dc"] = C["P_el"] / ip["eta_invertor"] ** np.sign(C["P_el"])
    C["P_bat"] = C["P_dc"] / ip["eta_dcdc"] ** np.sign(C["P_dc"])
    C["R_bat"] = B["Ns"] * cel["R_dc_mOhm"] * 1e-3 / B["Np"]
    C["U_0"] = B["U_nom"]
    C["I_bat"] = (C["U_0"] - np.sqrt(C["U_0"] ** 2 - 4 * C["R_bat"] * C["P_bat"])) / (2 * C["R_bat"])
    C["U_bat"] = C["U_0"] - C["R_bat"] * C["I_bat"]
    C["P_chim"] = C["U_0"] * C["I_bat"]
    C["I_bat_max"] = float(C["I_bat"].max())
    C["I_bat_min"] = float(C["I_bat"].min())
    C["I_celula_max"] = C["I_bat_max"] / B["Np"]
    C["U_bat_min"] = float(C["U_bat"].min())
    C["D_max"] = 1 - C["U_bat_min"] / T["U_conv"]
    C["P_bat_max"] = float(C["P_bat"].max())
    C["E"] = {}
    for nume, ta, tb in (("acc", 0, t1), ("palier", t1, t2), ("franare", t2, t3 + c["C_t_oprire"])):
        m = (t >= ta - 1e-12) & (t <= tb + 1e-12)
        C["E"][nume] = dict(ax=trapz(t[m], C["P_ax"][m]), el=trapz(t[m], C["P_el"][m]),
                            dc=trapz(t[m], C["P_dc"][m]), bat=trapz(t[m], C["P_chim"][m]))
    E = C["E"]
    E["total_bat"] = E["acc"]["bat"] + E["palier"]["bat"] + E["franare"]["bat"]
    E["total_ax"] = E["acc"]["ax"] + E["palier"]["ax"] + E["franare"]["ax"]
    C["Q_bat"] = trapz(t, C["I_bat"])
    C["dSOC_pct"] = C["Q_bat"] / (B["Cap_Ah"] * 3600) * 100
    eta = S["C2"]["eta"]
    C["P3"] = dict(W01=R3["W01_exact"], W12=R3["P1p"] * c["C_t_palier"], W2f=R3["W01_exact"])
    C["P3"]["W_stocata"] = C["P3"]["W01"] / eta + C["P3"]["W12"] / eta - eta * C["P3"]["W2f"]
    C["eta_acc"] = E["acc"]["ax"] / E["acc"]["bat"]
    C["eta_pal"] = E["palier"]["ax"] / E["palier"]["bat"]
    C["eta_rec"] = E["franare"]["bat"] / E["franare"]["ax"]
    return C


# ---------------------------------------------------------------- incalzire.m
def incalzire(S, M, T, Z):
    r, k_rd, N = S["C2"]["r"], T["k_rd"], T["N"]
    mc = M["masa"] * M["c"]
    H = {}
    B = Z["B"]
    m100 = B["v"] <= 100 / 3.6
    W, I, t = B["W"][m100], B["I"][m100], B["t"][m100]
    P = (M["R_a"] * I ** 2 + M["dU_p"] * np.abs(I) + M["K_H"] * W + M["K_F"] * W ** 2 + M["T_m0"] * W
         + M["F_m"] * W ** 2)
    Q = trapz(t, P)
    H["acc"] = dict(Q=Q, dT=Q / mc, durata=float(t[-1]), P_med=Q / float(t[-1]))
    W = min(M["W_b"], M["P_max"] / M["M_max"])
    L = scalar(punct_functionare(M, W, M["M_max"]))
    d = S["mot"]["durata_varf_s"]
    H["varf"] = dict(n=W * RPM, SP=L["SP"], durata=d, Q=L["SP"] * d, dT=L["SP"] * d / mc, eta=L["eta"])
    W = T["n_m_vmax"] / RPM
    L = scalar(punct_functionare(M, W, T["M_nec_n"] / N))
    H["vmax"] = dict(SP=L["SP"], eta=L["eta"], T=T["M_nec_n"] / N, n=T["n_m_vmax"], dT_min=L["SP"] * 60 / mc)
    R3 = S["R3"]
    W = R3["V1"] / r * k_rd
    Tm = R3["Ft1p"] * r / (N * k_rd * T["eta_rd"])
    L = scalar(punct_functionare(M, W, Tm))
    H["p3"] = dict(SP=L["SP"], eta=L["eta"], T=Tm, n=W * RPM, Q=L["SP"] * R3["t12"],
                   dT=L["SP"] * R3["t12"] / mc)
    H["mc"] = mc
    return H


# ---------------------------------------------------------------- harta_randament.m
def harta_randament(M, n_puncte=120):
    n = np.linspace(M["n_max"] / n_puncte, M["n_max"], n_puncte)
    Tq = np.linspace(0, M["M_max"], n_puncte)
    NN, TT = np.meshgrid(n, Tq)
    L = punct_functionare(M, NN * 2 * math.pi / 60, TT)
    H = dict(n=n, T=Tq, eta=L["eta"], SP=np.where(L["in_anvelopa"], L["SP"], np.nan),
             phi=np.where(L["in_anvelopa"], L["phi"], np.nan))
    H["anv_n"] = n
    H["anv_T"] = np.minimum(M["M_max"], M["P_max"] / (n * 2 * math.pi / 60))
    ef = L["eta"].flatten(order="F")
    kmax = int(np.nanargmax(ef))
    H["eta_max"] = float(ef[kmax])
    H["n_eta_max"] = float(NN.flatten(order="F")[kmax])
    H["T_eta_max"] = float(TT.flatten(order="F")[kmax])
    H["cota_95"] = float(np.sum(L["eta"] >= 0.95) / np.sum(~np.isnan(L["eta"])))
    return H


# ---------------------------------------------------------------- caracteristici_mecanice.m
def caracteristici_mecanice(M, U_rel, phi_rel, n_puncte=50):
    T = np.linspace(0, M["M_max"], n_puncte)

    def viteza(U, phi):
        kp = M["k"] * phi
        W = (U - M["dU_p"] - M["R_a"] * (T + M["T_f0"]) / kp) / (kp + M["R_a"] * M["F_v"] / kp)
        return np.maximum(W, 0)

    K = dict(T=T, U_rel=list(U_rel), phi_rel=list(phi_rel))
    K["n_U"] = np.array([viteza(u * M["U_n"], 1) * RPM for u in U_rel])
    K["n_phi"] = np.array([viteza(M["U_n"], p) * RPM for p in phi_rel])
    K["anv_n"] = np.linspace(1, M["n_max"], n_puncte)
    K["anv_T"] = np.minimum(M["M_max"], M["P_max"] / (K["anv_n"] * 2 * math.pi / 60))
    return K


# ---------------------------------------------------------------- punctele caracteristice (main_pierderi.m)
def puncte_caracteristice(S, M, T):
    r, k_rd, N, eta_rd = S["C2"]["r"], T["k_rd"], T["N"], T["eta_rd"]
    F100 = e2.forte(S["R2"]["Va"], 0, S["V"], S["C2"])
    pct = [
        ("nominal (n_n, M_n)", M["W_n"], M["M_n"]),
        ("cuplu maxim (P_max/M_max)", min(M["W_b"], M["P_max"] / M["M_max"]), M["M_max"]),
        ("putere maximă la n_max", M["W_max"], M["P_max"] / M["W_max"]),
        ("v_max (P_n necesar / N)", T["n_m_vmax"] / RPM, T["M_nec_n"] / N),
        ("100 km/h, viteză constantă", T["n_m_Va"] / RPM, float(np.asarray(F100["Ft"])) * r / (N * k_rd * eta_rd)),
        ("50 km/h, viteză constantă (P3)", S["R3"]["V1"] / r * k_rd, S["R3"]["Ft1p"] * r / (N * k_rd * eta_rd)),
    ]
    out = []
    for nume, W, Tq in pct:
        L = scalar(punct_functionare(M, W, Tq))
        out.append(dict(nume=nume, n=W * RPM, T=Tq, phi=L["phi"], U=L["U"], I=L["I"], P1=L["P1"], P_a=L["P_a"],
                        P_Fe=L["P_Fe"], P_fv=L["P_fv"], P2=L["P2"], eta=L["eta"]))
    return out


def calculeaza_tot(cu_simulari=True):
    S = incarca_date()
    M = identificare_mcc(S["mot"], S["ip"])
    T = tema_proiect(S, M)
    R = dict(S=S, M=M, T=T, puncte=puncte_caracteristice(S, M, T), harta=harta_randament(M, 120))
    K = caracteristici_mecanice(M, [1, 0.75, 0.5, 0.25], [0.8, 0.6, M["W_b"] / M["W_max"]])
    R["K"] = K
    if cu_simulari:
        Z = simulari(S, M, T)
        R["Z"] = Z
        R["C"] = simulare_ansamblu(S, M, T)
        R["H"] = incalzire(S, M, T, Z)
    return R
