"""CCA – P4 / C3: tema de proiect, pierderile și hărțile de randament, simulările – raport Python.

Rulare (din rădăcina depozitului):
    python3 etapa3-tema-motor/python/calcule_p4.py

Ce face:
  1. refă toate calculele din matlab/ (model_p4.py: aceleași formule, același RK4);
  2. scrie rezultate/rezultate_python.json și, dacă există rezultate/rezultate_matlab.json
     (din matlab/ruleaza_tot.m), compară cele două implementări;
  3. desenează figurile din figuri/ și completează tabelele din README.md (blocurile AUTO).
"""
import json
import math
import sys
from pathlib import Path

import numpy as np
import matplotlib
import matplotlib.ticker

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.colors import ListedColormap, BoundaryNorm  # noqa: E402
from matplotlib.patches import FancyBboxPatch  # noqa: E402

AICI = Path(__file__).resolve().parent
sys.path.insert(0, str(AICI))
import model_p4 as mp  # noqa: E402
from calcule_p2_p3 import ro, virgula, actualizeaza_readme  # noqa: E402  (din etapa 2, prin model_p4)

RADACINA = mp.RADACINA
RPM = mp.RPM

# paleta de referință (categorială, în ordinea fixă) și rampa secvențială albastră
CUL = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100", "#e87ba4", "#008300", "#6250d6", "#e34948"]
ALBASTRU = ["#cde2fb", "#b7d3f6", "#9ec5f4", "#86b6ef", "#6da7ec", "#5598e7", "#3987e5", "#2a78d6",
            "#256abf", "#1c5cab", "#184f95", "#104281", "#0d366b"]
TEXT = "#0b0b0b"
TEXT2 = "#52514e"


def stil():
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 9.5, "axes.edgecolor": "#8a8984",
                         "axes.labelcolor": TEXT, "xtick.color": TEXT2, "ytick.color": TEXT2,
                         "axes.titlesize": 10.5, "lines.linewidth": 2, "axes.spines.top": False,
                         "axes.spines.right": False, "legend.frameon": False})


def grila(ax):
    ax.grid(alpha=0.25, lw=0.6)
    virgula(ax)


# ---------------------------------------------------------------- JSON
def curata(o):
    if isinstance(o, dict):
        return {k: curata(v) for k, v in o.items() if not callable(v)}
    if isinstance(o, (list, tuple)):
        return [curata(v) for v in o]
    if isinstance(o, (np.floating, np.integer)):
        return o.item()
    if isinstance(o, np.bool_):
        return bool(o)
    if isinstance(o, np.ndarray):
        return curata(o.tolist())
    if isinstance(o, float) and math.isnan(o):
        return None
    return o


SERII = ("t", "I", "W", "v", "v_ref", "U", "phi", "T_ax", "I_ref", "P_ax", "P_el", "P_dc", "P_bat", "I_bat",
         "U_bat", "P_chim")


def esant(Q, tt):
    return [[float(np.interp(x, Q["t"], Q["I"])), float(np.interp(x, Q["t"], Q["W"]))] for x in tt]


def iesire(R):
    Z, C = R["Z"], R["C"]
    o = dict(motor=R["M"], tema=R["T"], puncte=R["puncte"],
             harta={k: R["harta"][k] for k in ("eta_max", "n_eta_max", "T_eta_max", "cota_95")},
             caracteristici=dict(n0_Un=float(R["K"]["n_U"][0, 0]), n_Mmax_Un=float(R["K"]["n_U"][0, -1])),
             incalzire=R["H"])
    o["sim"] = dict(
        A={k: Z["A"][k] for k in ("I_varf", "W_gol", "W_final", "I_final", "W_gol_teoretic", "W_sarcina_teoretic",
                                  "I_sarcina_teoretic")} | {"esantioane": esant(Z["A"], [0.002, 0.01, 0.03])},
        B={k: Z["B"][k] for k in ("t_100", "t_200", "t_vmax", "atins_vmax", "I_varf", "T_ad")}
        | {"esantioane": esant(Z["B"], [1, 3, 10])},
        D={k: Z["D"][k] for k in ("I_varf", "W_final")} | {"esantioane": esant(Z["D"], [2, 5, 8])},
        C={k: v for k, v in C.items() if k not in SERII} | {"esantioane": esant(C, [1, 4, 8])})
    return curata(o)


def compara(py, cale, tol=1e-6):
    if not cale.exists():
        print("(nu există rezultate_matlab.json – rulați matlab/ruleaza_tot.m pentru comparație)")
        return None
    m = json.loads(cale.read_text(encoding="utf-8"))
    dif, nr = [], 0

    def rec(a, b, cale_k):
        nonlocal nr
        if isinstance(a, dict) and isinstance(b, dict):
            for k in a:
                if k in b:
                    rec(a[k], b[k], f"{cale_k}.{k}")
        elif isinstance(a, list) and isinstance(b, list) and len(a) == len(b):
            for q, (x, y) in enumerate(zip(a, b)):
                rec(x, y, f"{cale_k}[{q}]")
        elif isinstance(a, bool) or isinstance(b, bool):
            nr += 1
            if bool(a) != bool(b):
                dif.append((cale_k, a, b))
        elif isinstance(a, (int, float)) and isinstance(b, (int, float)):
            nr += 1
            if abs(a - b) > tol * max(1.0, abs(a)):
                dif.append((cale_k, a, b))

    rec(m, py, "")
    print(f"Comparație MATLAB/Octave – Python: {nr} mărimi comparate, {len(dif)} diferențe (toleranță relativă {tol:g})")
    for d in dif[:30]:
        print("  DIFERENȚĂ", d)
    return nr, dif


# ---------------------------------------------------------------- figuri
def fig_harta(R, d):
    H, M, P = R["harta"], R["M"], R["puncte"]
    niv = [0.5, 0.80, 0.85, 0.88, 0.90, 0.92, 0.93, 0.94, 0.95, 0.96, 1.0]
    cmap = ListedColormap([ALBASTRU[i] for i in (0, 1, 2, 3, 4, 6, 7, 9, 11, 12)])
    norm = BoundaryNorm(niv, cmap.N)
    fig, ax = plt.subplots(figsize=(8.6, 6.4))
    cs = ax.contourf(H["n"], H["T"], H["eta"], levels=niv, cmap=cmap, norm=norm)
    cl = ax.contour(H["n"], H["T"], H["eta"], levels=niv[1:-1], colors="white", linewidths=0.6)
    ax.clabel(cl, fmt=lambda v: f"{v*100:.0f} %", fontsize=7, colors=TEXT, inline_spacing=2)
    ax.plot(H["anv_n"], H["anv_T"], color=TEXT, lw=1.6, label="limita din catalog: min(M_max, P_max/Ω)")
    ax.axvline(M["n_b"], color=TEXT2, lw=1, ls="--")
    ax.text(M["n_b"] + 60, M["M_max"] * 0.04, f"n_b = {ro(M['n_b'], 0)} rot/min\n(începe slăbirea de câmp)",
            fontsize=7.5, color=TEXT2)
    for q, p in enumerate(P):
        ax.plot(p["n"], p["T"], "o", ms=7, mfc="white", mec=TEXT, mew=1.4)
        ax.annotate(f"{q+1}", (p["n"], p["T"]), textcoords="offset points", xytext=(6, 4), fontsize=8, color=TEXT)
    txt = [f"{q+1} – {p['nume']}: η = {ro(100*p['eta'], 1)} %" for q, p in enumerate(P)]
    fig.text(0.08, 0.015, "\n".join(txt[:3]), fontsize=7.8, color=TEXT, va="bottom")
    fig.text(0.50, 0.015, "\n".join(txt[3:]), fontsize=7.8, color=TEXT, va="bottom")
    cb = fig.colorbar(cs, ax=ax, fraction=0.04, pad=0.02)
    cb.set_ticks(niv[1:-1])
    cb.set_ticklabels([f"{v*100:.0f}" for v in niv[1:-1]])
    cb.set_label("η [%]")
    ax.set(xlabel="n [rot/min]", ylabel="T_ax [Nm]", xlim=(0, M["n_max"]), ylim=(0, M["M_max"] * 1.03),
           title=f"Harta de randament – un motor YM720, model MCC echivalent (η_max = {ro(100*H['eta_max'], 2)} %)")
    ax.legend(loc="upper right", fontsize=8)
    virgula(ax)
    fig.tight_layout(rect=(0, 0.1, 1, 1))
    fig.savefig(d / "c3_harta_randament.png", dpi=140)
    plt.close(fig)


def fig_pierderi(R, d):
    P = R["puncte"]
    fig, ax = plt.subplots(figsize=(8.6, 3.6))
    y = np.arange(len(P))[::-1]
    st = np.zeros(len(P))
    for cheie, nume, cul in (("P_a", "P_a = R_a·I² (înfășurări)", CUL[0]), ("P_Fe", "P_Fe = K_H·Ω + K_F·Ω² (fier)", CUL[1]),
                             ("P_fv", "P_fv = T_m0·Ω + F_m·Ω² (mecanice)", CUL[2])):
        v = np.array([p[cheie] for p in P]) / 1e3
        ax.barh(y, v, left=st, height=0.55, color=cul, edgecolor="white", linewidth=2, label=nume)
        st += v
    for yy, p, s in zip(y, P, st):
        ax.text(s + 0.15, yy, f"{ro(s, 2)} kW (η = {ro(100*p['eta'], 1)} %)", va="center", fontsize=8, color=TEXT)
    ax.set_yticks(y, [p["nume"] for p in P], fontsize=8)
    ax.set(xlabel="pierderi pe motor [kW]", xlim=(0, st.max() * 1.45),
           title="Pierderile în punctele caracteristice (diagrama de puteri, C3)")
    ax.legend(fontsize=7.5, loc="lower right")
    ax.grid(alpha=0.25, lw=0.6, axis="x")
    ax.xaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(lambda x, _: f"{x:g}".replace(".", ",")))
    fig.tight_layout()
    fig.savefig(d / "c3_pierderi_puncte.png", dpi=140)
    plt.close(fig)


def fig_caracteristici(R, d):
    K, M = R["K"], R["M"]
    fig, ax = plt.subplots(figsize=(7.6, 4.6))
    ramp = ["#0d366b", "#1c5cab", "#3987e5", "#86b6ef"]
    for q, u in enumerate(K["U_rel"]):
        ax.plot(K["T"], K["n_U"][q], color=ramp[q], label=f"U = {ro(u, 2)}·U_n, Φ = Φ_n")
        ax.annotate(f"{ro(u, 2)}·U_n", (K["T"][-1], K["n_U"][q][-1]), textcoords="offset points", xytext=(4, -3),
                    fontsize=7.5, color=TEXT2)
    stiluri = ["--", "-.", ":"]
    for q, p in enumerate(K["phi_rel"]):
        ax.plot(K["T"], K["n_phi"][q], color=CUL[1], ls=stiluri[q], lw=1.6, label=f"U = U_n, Φ = {ro(p, 2)}·Φ_n")
    ax.plot(K["anv_T"], K["anv_n"], color=TEXT, lw=1.4, label="limita din catalog")
    ax.axhline(M["n_max"], color=TEXT2, lw=0.8, ls=":")
    ax.set(xlabel="T_ax [Nm]", ylabel="n [rot/min]", xlim=(0, M["M_max"] * 1.12), ylim=(0, M["n_max"] * 1.35),
           title="Caracteristici mecanice n = f(T_ax): reglare prin tensiune și slăbire de câmp")
    ax.legend(fontsize=7.5, loc="upper right", ncol=2)
    grila(ax)
    fig.tight_layout()
    fig.savefig(d / "c3_caracteristici_mecanice.png", dpi=140)
    plt.close(fig)


def panouri(serii, titlu, fis, d, xlabel="t [s]"):
    fig, axs = plt.subplots(len(serii), 1, figsize=(8.2, 1.9 * len(serii) + 0.6), sharex=True)
    axs = np.atleast_1d(axs)
    for ax, (ylabel, linii) in zip(axs, serii):
        for x, y, eti, cul, ls in linii:
            ax.plot(x, y, color=cul, ls=ls, lw=1.6, label=eti)
        ax.set_ylabel(ylabel)
        if len(linii) > 1:
            ax.legend(fontsize=7.5, loc="best")
        grila(ax)
    axs[-1].set_xlabel(xlabel)
    fig.suptitle(titlu, fontsize=10.5)
    fig.tight_layout()
    fig.savefig(d / fis, dpi=140)
    plt.close(fig)


def fig_simulari(R, d):
    Z, C, M = R["Z"], R["C"], R["M"]
    A = Z["A"]
    panouri([("I [A]", [(A["t"] * 1e3, A["I"], "I", CUL[0], "-")]),
             ("n [rot/min]", [(A["t"] * 1e3, A["W"] * RPM, "n", CUL[0], "-")])],
            f"A – pornire în gol la U_p = {ro(M['U_p'], 1)} V, apoi treaptă de sarcină (vârf I = {ro(A['I_varf'], 0)} A)",
            "sim_A_pornire_gol.png",
            d, xlabel="t [ms]")
    B = Z["B"]
    panouri([("v [km/h]", [(B["t"], B["v"] * 3.6, "v", CUL[0], "-")]),
             ("I [A]", [(B["t"], B["I"], "I", CUL[0], "-")]),
             ("U [V]", [(B["t"], B["U"], "U", CUL[0], "-")]),
             ("T_ax [Nm]", [(B["t"], B["T_ax"], "T_ax", CUL[0], "-")]),
             ("Φ/Φ_n", [(B["t"], B["phi"], "Φ", CUL[0], "-")])],
            f"B – accelerare cu regulator de curent: 0–100 km/h în {ro(B['t_100'], 2)} s, v_max în {ro(B['t_vmax'], 1)} s",
            "sim_B_accelerare.png", d)
    D = Z["D"]
    panouri([("U [V]", [(D["t"], D["U"], "U", CUL[0], "-")]),
             ("I [A]", [(D["t"], D["I"], "I", CUL[0], "-")]),
             ("n [rot/min]", [(D["t"], D["W"] * RPM, "n", CUL[0], "-")])],
            "D – rampă de tensiune cu sarcina vehiculului (scenariul refăcut în Simulink)", "sim_D_rampa.png", d)
    panouri([("v [km/h]", [(C["t"], C["v_ref"] * 3.6, "referință", TEXT2, "--"), (C["t"], C["v"] * 3.6, "vehicul", CUL[0], "-")]),
             ("P [kW]", [(C["t"], C["P_ax"] / 1e3, "P la axul celor 3 motoare", CUL[0], "-"),
                         (C["t"], C["P_bat"] / 1e3, "P la bornele bateriei", CUL[1], "-")]),
             ("I_bat [A]", [(C["t"], C["I_bat"], "I_bat", CUL[0], "-")]),
             ("U_bat [V]", [(C["t"], C["U_bat"], "U_bat", CUL[0], "-")])],
            "C – simulare pe ansamblu: ciclul P3 scurtat (accelerare, palier 50 km/h, frânare recuperativă)",
            "sim_C_ansamblu.png", d)


def fig_schema(d):
    fig, ax = plt.subplots(figsize=(12, 6.0))
    ax.set_xlim(0, 120)
    ax.set_ylim(0, 60)
    ax.axis("off")
    put, reg, gri = "#eef4fd", "#184f95", "#7a7974"

    def bloc(x, y, w, h, txt, cul=put, tc=TEXT, fs=8.5):
        ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.4,rounding_size=1.2", fc=cul, ec="#5f5e5a",
                                    lw=1.1))
        ax.text(x + w / 2, y + h / 2, txt, ha="center", va="center", fontsize=fs, color=tc)

    def traseu(puncte, cul="#3d3d3a", ls="-", lw=1.2):
        xs, ys = zip(*puncte)
        if len(puncte) > 2:
            ax.plot(xs[:-1], ys[:-1], color=cul, ls=ls, lw=lw)
        ax.annotate("", puncte[-1], puncte[-2], arrowprops=dict(arrowstyle="-|>", color=cul, lw=lw, ls=ls,
                                                               shrinkA=0, shrinkB=0))

    y0, h0 = 26, 10
    bloc(2, y0, 15, h0, "Baterie Li-ion\n190s31p Molicel P50B\n475–798 V, 106 kWh")
    bloc(23, y0, 16, h0, "Convertor DC-DC\nbidirecțional\n(ridicător / coborâtor)")
    bloc(45, y0, 14, h0, "3 × invertor SiC\n(chopper în 4 cadrane\nla echivalentul MCC)")
    bloc(65, y0, 15, h0, "3 × mașină YM720\nPMSM, model MCC\n180 kW / 350 kW")
    bloc(86, y0, 12, h0, "3 × reductor\n1/i_rd = 4,15")
    bloc(104, y0, 13, h0, "Roți (1 față +\n2 spate)\nvehicul 2245 kg")
    for x1, x2 in ((17, 23), (39, 45), (59, 65), (80, 86), (98, 104)):
        traseu([(x1 + 0.5, y0 + 6.5), (x2 - 0.5, y0 + 6.5)])
    for x1, x2 in ((17, 23), (39, 45), (59, 65)):
        traseu([(x2 - 0.5, y0 + 3.0), (x1 + 0.5, y0 + 3.0)], cul=CUL[2], ls="--")
    ax.text(42, y0 + 8.4, "U_conv\n800 V", ha="center", fontsize=7.5, color=TEXT2)
    # regulatoare și referințe
    bloc(23, 46, 16, 7, "Regulator U_conv\n(PI tensiune → PI curent)", cul=reg, tc="white", fs=8)
    bloc(50, 46, 26, 7, "Regulator de viteză (PI) → T_ref\nlimitat: M_max, P_max/Ω, aderență", cul=reg, tc="white", fs=8)
    bloc(100, 46, 17, 7, "Ciclu de viteză\n(P3: 0 → 50 → 0 km/h)", cul="#e3f4ec", fs=8)
    bloc(45, 8, 35, 7, "Regulator I_mot (PI, f_c = 500 Hz)\nI_ref = (T_ref + T_f0 + F_v·Ω) / (kΦ)", cul=reg, tc="white", fs=8)
    bloc(2, 8, 15, 7, "Regulator I_bat\n(încărcare CC-CV)", cul=reg, tc="white", fs=8)
    bloc(23, 8, 16, 7, "Încărcător AC-DC\n(PFC + coborâtor)", fs=8)
    traseu([(31, 45.6), (31, y0 + h0 + 0.5)])                              # U_conv → DC-DC
    traseu([(42, y0 + 6.5), (42, 49.5), (39.5, 49.5)], cul=gri, ls=":")     # măsura U_conv
    traseu([(99.6, 49.5), (76.5, 49.5)])                                   # ciclu → regulator viteză
    traseu([(110.5, y0 + h0 + 0.5), (110.5, 42), (70, 42), (70, 45.6)], cul=gri, ls=":")   # măsura vitezei
    traseu([(62, 45.6), (62, 15.5)])                                       # T_ref → regulator I_mot
    traseu([(52, 15.5), (52, y0 - 0.5)])                                   # comenzi invertor
    traseu([(75, y0 - 0.5), (75, 15.5)], cul=gri, ls=":")                 # măsura I_mot
    traseu([(17.5, 11.5), (22.5, 11.5)])                                   # I_bat → încărcător
    traseu([(31, 15.5), (31, 20), (13, 20), (13, y0 - 0.5)])               # încărcător → baterie
    traseu([(6, y0 - 0.5), (6, 15.5)], cul=gri, ls=":")                   # măsura I_bat
    traseu([(31, 2.5), (31, 7.5)])
    ax.text(33, 3.2, "priză AC 3 × 400 V", fontsize=7.5, color=TEXT2)
    # legendă
    lx, ly = 86, 6
    for q, (cul, ls, txt) in enumerate((("#3d3d3a", "-", "flux de putere la tracțiune / comenzi"),
                                        (CUL[2], "--", "frânare recuperativă (invertor + DC-DC coborâtor)"),
                                        (gri, ":", "măsuri: tensiune, curent, viteză"))):
        ax.plot([lx, lx + 5], [ly + 12 - 4 * q] * 2, color=cul, ls=ls, lw=1.4)
        ax.text(lx + 6, ly + 12 - 4 * q, txt, va="center", fontsize=7.5, color=TEXT)
    ax.text(60, 58, "Schema bloc a sistemului de propulsie (după suportul P4, slide 4)", ha="center", fontsize=11,
            color=TEXT)
    fig.tight_layout()
    fig.savefig(d / "p4_schema_bloc.png", dpi=140)
    plt.close(fig)


def figuri(R, d):
    d.mkdir(exist_ok=True)
    stil()
    fig_harta(R, d)
    fig_pierderi(R, d)
    fig_caracteristici(R, d)
    fig_simulari(R, d)
    fig_schema(d)


# ---------------------------------------------------------------- tabelele din README.md
def da(x):
    return "DA" if x else "NU"


def tabele(R, nr_comp=None):
    S, M, T, P, H, Z, C, Hc = R["S"], R["M"], R["T"], R["puncte"], R["harta"], R["Z"], R["C"], R["H"]
    ip, mot, B = S["ip"], S["mot"], S["B"]
    N = T["N"]
    tb = {}
    tb["tema"] = "\n".join([
        "| Mărime | Pe motor | Total (3 motoare) | Cum s-a obținut |",
        "|---|---|---|---|",
        f"| P_n | {ro(M['P_n']/1e3, 0)} kW | {ro(N*M['P_n']/1e3, 0)} kW | catalog YASA (continuu) |",
        f"| U_n | {ro(M['U_n'], 0)} V | – | tensiunea circuitului intermediar, reglată de DC-DC |",
        f"| I_n | {ro(M['I_n'], 1)} A | {ro(N*M['I_n'], 1)} A | echivalent MCC: P_n/(η_n·U_n), η_n = {ro(M['eta_n'], 3)} |",
        f"| n (nominală) | {ro(M['n_n'], 0)} rot/min | – | n_n = P_n/M_n; n_max = {ro(M['n_max'], 0)} rot/min |",
        f"| M_n | {ro(M['M_n'], 0)} Nm | {ro(N*M['M_n'], 0)} Nm | catalog (continuu) |",
        f"| P_max | {ro(M['P_max']/1e3, 0)} kW | {ro(N*M['P_max']/1e3, 0)} kW | catalog (vârf {mot['durata_varf_s']} s) |",
        f"| I_max | {ro(M['I_max'], 1)} A | {ro(N*M['I_max'], 1)} A | echivalent MCC la M_max și n_b = {ro(M['n_b'], 0)} rot/min |",
        f"| M_max | {ro(M['M_max'], 0)} Nm | {ro(N*M['M_max'], 0)} Nm | catalog (vârf) |",
        f"| Reductor i_rd | {ro(T['i_rd'], 4)} (1:{ro(T['k_rd'], 2)}) | – | ales: n motor la v_max = {ro(T['n_m_vmax'], 0)} rot/min ≤ n_max |",
        f"| Baterie W_bat | necesar {ro(T['W_bat_nec']/3.6e6, 2)} kWh | instalat {ro(T['W_bat_inst']/3.6e6, 2)} kWh | P3 + celula Molicel P50B, {B['Ns']}s{B['Np']}p |",
    ])
    tb["vehicul"] = "\n".join([
        "| Regim | P_r | n_r | M_r | Observații |",
        "|---|---|---|---|---|",
        f"| nominal (rulare cu v_max) | {ro(T['P_rn']/1e3, 1)} kW | {ro(T['n_rn'], 0)} rot/min | {ro(T['M_rn'], 1)} Nm | v_max = {ro(S['R2']['vmax']*3.6, 1)} km/h |",
        f"| maxim (accelerare la limita de aderență) | {ro(T['P_rmax']/1e3, 1)} kW | {ro(T['n_rmax'], 0)} rot/min (max.) | {ro(T['M_rmax'], 1)} Nm | P_rmax la 100 km/h ({ro(T['n_r_Va'], 0)} rot/min) |",
    ])
    tb["confirmari"] = "\n".join([
        "| Confirmare | Condiție | Valori | Rezultat |",
        "|---|---|---|---|",
        f"| MCC – putere maximă | N·P_max ≥ P_max necesar | {ro(N*M['P_max']/1e3, 0)} ≥ {ro(T['P_nec_max']/1e3, 1)} kW | {da(T['ok_P_max'])} |",
        f"| MCC – putere nominală | N·P_n ≥ P_n necesar | {ro(N*M['P_n']/1e3, 0)} ≥ {ro(T['P_nec_n']/1e3, 1)} kW | {da(T['ok_P_n'])} |",
        f"| MCC – cuplu puntea față | M_max ≥ f_față·M_nec | {ro(M['M_max'], 0)} ≥ {ro(T['M_nec_fata'], 1)} Nm (f_față = {ro(T['f_fata'], 3)}) | {da(T['ok_M_fata'])} |",
        f"| MCC – cuplu puntea spate | M_max ≥ (1 − f_față)·M_nec/2 | {ro(M['M_max'], 0)} ≥ {ro(T['M_nec_spate'], 1)} Nm | {da(T['ok_M_spate'])} |",
        f"| MCC – tensiune | U_dc,min ≤ U_conv ≤ U_dc,max | {mot['U_dc_min_V']} ≤ {ro(T['U_conv'], 0)} ≤ {mot['U_dc_max_V']} V | {da(T['ok_U'])} |",
        f"| Reductor – turație | n_max ≥ n la v_max | {ro(M['n_max'], 0)} ≥ {ro(T['n_m_vmax'], 0)} rot/min | {da(T['ok_n_max'])} |",
        f"| Reductor – cuplu la roți | N·M_max·k_rd·η_rd ≥ M_rmax | {ro(T['M_roti_disp'], 0)} ≥ {ro(T['M_rmax'], 0)} Nm | {da(T['ok_M_roti'])} |",
        f"| Baterie – energie | W instalat ≥ W necesar | {ro(T['W_bat_inst']/3.6e6, 2)} ≥ {ro(T['W_bat_nec']/3.6e6, 2)} kWh | {da(T['ok_W_bat'])} |",
        f"| Baterie – curent celulă | I_celulă(P_max, U_min) ≤ {S['cel']['I_max_cont']} A | {ro(B['I_celula'], 1)} A | {da(T['ok_I_cel'])} |",
        f"| Baterie – putere | P disponibilă·η ≥ P_max | {ro(T['P_mec_disp']/1e3, 0)} ≥ {ro(T['P_nec_max']/1e3, 1)} kW | {da(T['ok_P_bat'])} |",
    ])
    tb["parametri"] = "\n".join([
        "| Parametru | Valoare | Relația |",
        "|---|---|---|",
        f"| P1_n, pierderi la n_n | {ro(M['P1_n']/1e3, 2)} kW; {ro(M['SP_n']/1e3, 3)} kW | P1_n = P_n/η_n |",
        f"| R_a | {ro(M['R_a'], 5)} Ω | R_a = {ro(ip['cota_Cu'], 2)}·ΣP_n / I_n² |",
        f"| k = k_E = k_M | {ro(M['k'], 5)} V·s/rad = Nm/A | k = (U_n − R_a·I_n − ΔU_p)/Ω_n |",
        f"| K_H, K_F | {ro(M['K_H'], 4)} Nm; {M['K_F']:.4e} Nm·s/rad".replace(".", ",")
        + f" | P_Fe = K_H·Ω + K_F·Ω², P_Fe(n_n) = {ro(M['P_Fe_n']/1e3, 3)} kW, P_Fe(n_max) = {ro(ip['raport_Fe_max'], 1)}·P_Fe(n_n) |",
        f"| T_m0, F_m | {ro(M['T_m0'], 4)} Nm; {M['F_m']:.4e} Nm·s/rad".replace(".", ",")
        + f" | P_fv = T_m0·Ω + F_m·Ω², P_fv(n_max) = {ro(ip['raport_mec_max'], 1)}·P_fv(n_n) |",
        f"| T_f0, F_v | {ro(M['T_f0'], 4)} Nm; {M['F_v']:.4e} Nm·s/rad".replace(".", ",") + " | T_f0 = K_H + T_m0, F_v = K_F + F_m |",
        f"| Verificare T_ax(n_n) | {ro(M['T_ax_n_verif'], 3)} Nm | k·I_n − T_f0 − F_v·Ω_n = M_n |",
        f"| Viteza de bază n_b | {ro(M['n_b'], 0)} rot/min | U_n = k·Ω_b + R_a·I_max |",
        f"| Pornire directă la U_n | I_p = {ro(M['I_p_Un'], 0)} A, M_p = {ro(M['M_p_Un'], 0)} Nm | I_p = (U_n − ΔU_p)/R_a – inadmisibil |",
        f"| Tensiunea de pornire U_p | {ro(M['U_p'], 2)} V | U_p = R_a·I_max + ΔU_p |",
        f"| L_a, τ_a | {M['L_a']*1e6:.0f} µH; {ro(M['tau_a']*1e3, 2)} ms".replace(".", ",") + " | τ_a = L_a/R_a |",
        f"| J_rotor | {ro(M['J_rotor'], 3)} kg·m² | – |",
    ])
    rows = ["| # | Punct de funcționare | n [rot/min] | T_ax [Nm] | Φ/Φ_n | U [V] | I [A] | P1 [kW] | P_a [kW] | P_Fe [kW] | "
            "P_fv [kW] | P2 [kW] | η [%] |", "|---|---|---|---|---|---|---|---|---|---|---|---|---|"]
    for q, p in enumerate(P):
        rows.append(f"| {q+1} | {p['nume']} | {ro(p['n'], 0)} | {ro(p['T'], 1)} | {ro(p['phi'], 3)} | {ro(p['U'], 1)} | "
                    f"{ro(p['I'], 1)} | {ro(p['P1']/1e3, 2)} | {ro(p['P_a']/1e3, 3)} | {ro(p['P_Fe']/1e3, 3)} | "
                    f"{ro(p['P_fv']/1e3, 3)} | {ro(p['P2']/1e3, 2)} | {ro(100*p['eta'], 2)} |")
    tb["puncte"] = "\n".join(rows)
    tb["harta"] = (f"Randamentul maxim al modelului: **η_max = {ro(100*H['eta_max'], 2)} %** la n = {ro(H['n_eta_max'], 0)} rot/min, "
                   f"T_ax = {ro(H['T_eta_max'], 0)} Nm; zona cu η ≥ 95 % ocupă {ro(100*H['cota_95'], 1)} % din domeniul de "
                   f"funcționare (grilă 120 × 120).")
    tb["incalzire"] = "\n".join([
        f"Un motor: m = {ro(M['masa'], 0)} kg, c = {ro(M['c'], 0)} J/(kg·K) → m·c = {ro(Hc['mc'], 0)} J/K (fără răcire).",
        "",
        "| Regim | Pierderi | Durată | Q | ΔT fără răcire |",
        "|---|---|---|---|---|",
        f"| Accelerare 0–100 km/h (simularea B) | {ro(Hc['acc']['P_med']/1e3, 2)} kW (medie) | {ro(Hc['acc']['durata'], 2)} s | "
        f"{ro(Hc['acc']['Q']/1e3, 1)} kJ | {ro(Hc['acc']['dT'], 2)} K |",
        f"| Cuplu maxim la {ro(Hc['varf']['n'], 0)} rot/min (vârf din catalog) | {ro(Hc['varf']['SP']/1e3, 2)} kW (η = {ro(100*Hc['varf']['eta'], 1)} %) | "
        f"{Hc['varf']['durata']} s | {ro(Hc['varf']['Q']/1e3, 0)} kJ | {ro(Hc['varf']['dT'], 1)} K |",
        f"| Rulare cu v_max ({ro(Hc['vmax']['n'], 0)} rot/min, {ro(Hc['vmax']['T'], 1)} Nm) | {ro(Hc['vmax']['SP']/1e3, 2)} kW (η = {ro(100*Hc['vmax']['eta'], 1)} %) | "
        f"1 min | {ro(Hc['vmax']['SP']*60/1e3, 0)} kJ | {ro(Hc['vmax']['dT_min'], 1)} K/min |",
        f"| Ciclul P3, palier 50 km/h ({ro(Hc['p3']['n'], 0)} rot/min, {ro(Hc['p3']['T'], 1)} Nm) | {ro(Hc['p3']['SP'], 0)} W (η = {ro(100*Hc['p3']['eta'], 1)} %) | "
        f"{ro(S['R3']['t12']/3600, 2)} h | {ro(Hc['p3']['Q']/1e6, 1)} MJ | {ro(Hc['p3']['dT'], 0)} K (fără răcire) |",
    ])
    A, Bz, D = Z["A"], Z["B"], Z["D"]
    sim = ip["simulare"]
    tb["simulari"] = "\n".join([
        "| Scenariu | Rezultat |",
        "|---|---|",
        f"| A – pornire în gol la U_p = {ro(M['U_p'], 2)} V, apoi treaptă de sarcină {ro(sim['A_M_treapta'], 0)} Nm la "
        f"{ro(sim['A_t_treapta']*1e3, 0)} ms | I de vârf {ro(A['I_varf'], 1)} A (I_max = {ro(M['I_max'], 1)} A); Ω în gol "
        f"{ro(A['W_gol'], 3)} rad/s (teoretic {ro(A['W_gol_teoretic'], 3)}); cu sarcină Ω = {ro(A['W_final'], 3)} rad/s, "
        f"I = {ro(A['I_final'], 1)} A (teoretic {ro(A['W_sarcina_teoretic'], 3)} rad/s, {ro(A['I_sarcina_teoretic'], 1)} A) |",
        f"| B – accelerare, regulator PI de curent ({sim['B_fc_Hz']} Hz), slăbire de câmp | 0–100 km/h: **{ro(Bz['t_100'], 2)} s** "
        f"(P2: {ro(S['R2']['ta'], 2)} s); 0–200 km/h: {ro(Bz['t_200'], 2)} s; v_max atinsă: {da(Bz['atins_vmax'])} în {ro(Bz['t_vmax'], 1)} s; "
        f"I de vârf {ro(Bz['I_varf'], 1)} A |",
        f"| D – rampă de tensiune {sim['D_panta']} V/s, sarcina vehiculului | I de vârf {ro(D['I_varf'], 1)} A; "
        f"n după {sim['D_t_end']} s = {ro(D['W_final']*RPM, 0)} rot/min (< n_max) |",
    ])
    E = C["E"]
    tb["ansamblu"] = "\n".join([
        f"Ciclul P3 scurtat: 0 → {ro(C['V1']*3.6, 0)} km/h în {ro(C['t1'], 2)} s (a = {ro(C['a'], 2)} m/s²), palier {sim['C_t_palier']} s, "
        f"frânare simetrică, oprire {sim['C_t_oprire']} s. Regulator de viteză PI cu poli dubli la −{sim['C_wn_viteza']} rad/s "
        f"(K_p = {ro(C['Kp_w'], 1)} Nm·s/rad, K_i = {ro(C['Ki_w'], 1)} Nm/rad); eroarea maximă de viteză {ro(C['eroare_v_max']*3.6, 2)} km/h.",
        "",
        "| Faza | E la ax [kJ] | E la bornele motoarelor [kJ] | E în circuitul intermediar [kJ] | E din celule [kJ] | η lanț |",
        "|---|---|---|---|---|---|",
        f"| accelerare | {ro(E['acc']['ax']/1e3, 1)} | {ro(E['acc']['el']/1e3, 1)} | {ro(E['acc']['dc']/1e3, 1)} | {ro(E['acc']['bat']/1e3, 1)} | {ro(C['eta_acc'], 3)} |",
        f"| palier 50 km/h | {ro(E['palier']['ax']/1e3, 1)} | {ro(E['palier']['el']/1e3, 1)} | {ro(E['palier']['dc']/1e3, 1)} | {ro(E['palier']['bat']/1e3, 1)} | {ro(C['eta_pal'], 3)} |",
        f"| frânare recuperativă | {ro(E['franare']['ax']/1e3, 1)} | {ro(E['franare']['el']/1e3, 1)} | {ro(E['franare']['dc']/1e3, 1)} | {ro(E['franare']['bat']/1e3, 1)} | {ro(C['eta_rec'], 3)} (recuperat/ax) |",
        "",
        f"Energia luată din baterie pe ciclu: **{ro(E['total_bat']/1e3, 1)} kJ**; estimarea P3 (η = {ro(S['C2']['eta'], 1)}) pe același ciclu: "
        f"{ro(C['P3']['W_stocata']/1e3, 1)} kJ. Curentul bateriei {ro(C['I_bat_min'], 0)} … {ro(C['I_bat_max'], 0)} A "
        f"(max. {ro(C['I_celula_max'], 1)} A pe celulă), U_bat ≥ {ro(C['U_bat_min'], 0)} V, factorul de umplere al DC-DC ≤ {ro(C['D_max'], 3)}.",
    ])
    if nr_comp:
        tb["comparatie"] = (f"Implementarea Python (python/model_p4.py) refăcută independent de MATLAB/Octave: {nr_comp[0]} mărimi comparate, "
                            f"{len(nr_comp[1])} diferențe peste toleranța relativă 10⁻⁶.")
    return tb


def main():
    R = mp.calculeaza_tot(cu_simulari=True)
    py = iesire(R)
    (RADACINA / "rezultate").mkdir(exist_ok=True)
    (RADACINA / "rezultate" / "rezultate_python.json").write_text(json.dumps(py, indent=1, ensure_ascii=False),
                                                                  encoding="utf-8")
    nr = compara(py, RADACINA / "rezultate" / "rezultate_matlab.json")
    figuri(R, RADACINA / "figuri")
    actualizeaza_readme(RADACINA / "README.md", tabele(R, nr))
    M, Z, C = R["M"], R["Z"], R["C"]
    print(f"R_a={M['R_a']:.5f} k={M['k']:.5f} n_b={M['n_b']:.1f} I_max={M['I_max']:.1f} | t100={Z['B']['t_100']:.3f} "
          f"| ciclu: E_bat={C['E']['total_bat']/1e3:.1f} kJ, I_bat_max={C['I_bat_max']:.1f} A")
    return 0


if __name__ == "__main__":
    sys.exit(main())
