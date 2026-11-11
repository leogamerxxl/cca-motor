"""CCA – P5-P6: convertoarele DC-DC și încărcarea bateriei – raport Python.

Rulare (din rădăcina depozitului):
    python3 etapa4-convertoare/python/calcule_p5p6.py

Ce face:
  1. refă dimensionarea și simulările din matlab/ (model_p5p6.py: aceleași formule și algoritmi);
  2. scrie rezultate/rezultate_python.json și îl compară cu rezultate/rezultate_matlab.json (din matlab/ruleaza_tot.m);
  3. desenează figurile din figuri/ și completează tabelele din README.md (blocurile AUTO).
"""
import json
import math
import sys
from pathlib import Path

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

AICI = Path(__file__).resolve().parent
sys.path.insert(0, str(AICI))
import model_p5p6 as m5  # noqa: E402
sys.path.insert(0, str(m5.RADACINA.parent / "etapa3-tema-motor" / "python"))
import calcule_p4 as c4  # noqa: E402
from calcule_p2_p3 import virgula, actualizeaza_readme  # noqa: E402
ro = c4.ro

RADACINA = m5.RADACINA
CUL, TEXT, TEXT2 = c4.CUL, c4.TEXT, c4.TEXT2

SERII = {"t", "I", "U", "SOC", "P_bat", "P_AC", "Iref", "s", "IL", "UDC", "IB", "UB", "D", "P"}


def iesire(R):
    def fara(d):
        return {k: v for k, v in d.items() if k not in SERII}
    o = dict(dcdc=R["D"], chopper=R["H"], incarcator=R["C"], incarcare_medie=fara(R["Im"]),
             incarcare_comutatie=fara(R["Ic"]), dcdc_comutatie=fara(R["Dc"]))
    return c4.curata(o)


# ---------------------------------------------------------------- figuri
def fig_dcdc(R, d):
    Dc, D = R["Dc"], R["D"]
    sc = R["S"]["cv"]["simulare"]["dcdc"]
    t = Dc["t"] * 1e3
    fig, ax = plt.subplots(4, 1, figsize=(8.4, 8.4), sharex=True)
    ax[0].plot(t, Dc["P"] / 1e3, color=CUL[0], lw=1.6)
    ax[0].set_ylabel("P sarcină [kW]")
    ax[1].plot(t, Dc["UDC"], color=CUL[0], lw=1.2)
    ax[1].axhline(D["U_dc"], color=TEXT2, lw=0.8, ls="--")
    ax[1].set_ylabel("U_dc [V]")
    for q in range(D["N_faze"]):
        ax[2].plot(t, Dc["IL"][:, q], color=CUL[q], lw=0.8, label=f"faza {q+1}")
    ax[2].set_ylabel("i_L [A]")
    ax[2].legend(fontsize=7.5, ncol=4, loc="upper right")
    ax[3].plot(t, Dc["IB"], color=CUL[0], lw=1.0)
    ax[3].set_ylabel("I_bat [A]")
    ax[3].set_xlabel("t [ms]")
    for a in ax:
        c4.grila(a)
    fig.suptitle(f"DC-DC bidirecțional, {D['N_faze']} faze intercalate, f_s = {ro(D['f_s']/1e3, 0)} kHz: "
                 f"tracțiune {ro(D['P_dc_max']/1e3, 0)} kW → recuperare {ro(sc['P_franare_rel']*D['P_dc_max']/1e3, 0)} kW",
                 fontsize=10.5)
    fig.tight_layout()
    fig.savefig(d / "p5_dcdc_comutatie.png", dpi=140)
    plt.close(fig)
    # zoom: două perioade de comutație în regim de tracțiune
    t0 = sc["t_franare"] - 2e-4
    m = (Dc["t"] >= t0) & (Dc["t"] <= t0 + 1e-4)
    fig, ax = plt.subplots(2, 1, figsize=(8.4, 5.0), sharex=True)
    tz = (Dc["t"][m] - t0) * 1e6
    for q in range(D["N_faze"]):
        ax[0].plot(tz, Dc["IL"][m, q], color=CUL[q], lw=1.2, label=f"faza {q+1}")
    ax[0].set_ylabel("i_L [A]")
    ax[0].legend(fontsize=7.5, ncol=4, loc="upper right")
    ax[1].plot(tz, Dc["IB"][m], color=CUL[0], lw=1.2, label="I_bat = Σ i_L")
    ax[1].set_ylabel("I_bat [A]")
    ax[1].set_xlabel("t [µs]")
    tr = Dc["tr"]
    ax[0].set_title(f"Detaliu la tracțiune: ondulația pe fază {ro(tr['dI_faza'], 1)} A (formula {ro(tr['dI_faza_teoretic'], 1)} A), "
                    f"a curentului bateriei {ro(tr['dI_bat'], 1)} A", fontsize=9.5)
    for a in ax:
        c4.grila(a)
    fig.tight_layout()
    fig.savefig(d / "p5_dcdc_intercalare.png", dpi=140)
    plt.close(fig)


def fig_incarcare(R, d):
    Im, C, cv = R["Im"], R["C"], R["S"]["cv"]["incarcator"]
    th = Im["t"] / 3600
    c4.panouri([("I_bat [A]", [(th, Im["I"], "I", CUL[0], "-")]),
                ("U_bat [V]", [(th, Im["U"], "U", CUL[0], "-")]),
                ("SOC [%]", [(th, 100 * Im["SOC"], "SOC", CUL[0], "-")]),
                ("P [kW]", [(th, Im["P_AC"] / 1e3, "din rețea", CUL[1], "-"), (th, Im["P_bat"] / 1e3, "în baterie", CUL[0], "-")])],
               f"Încărcare CC-CV, model mediu: CC {ro(C['I_CC'], 1)} A până la {ro(C['U_CV'], 0)} V, apoi CV; "
               f"total {ro(Im['t_total']/3600, 2)} h", "p5_incarcare_cccv.png", d, xlabel="t [h]")
    Ic = R["Ic"]
    sc = R["S"]["cv"]["simulare"]["incarcare"]
    tm = Ic["t"] * 1e3
    fig, ax = plt.subplots(2, 1, figsize=(8.4, 5.6), sharex=True)
    ax[0].plot(tm, Ic["I"], color=CUL[0], lw=0.6, label="i (cu comutație)")
    ax[0].plot(tm, Ic["Iref"], color=CUL[1], lw=1.4, label="I_ref (regulatorul de tensiune)")
    tt = np.linspace(0, sc["t_end"], 400)
    imed = np.where(tt < sc["t_CC_s"], C["I_CC"], C["I_CC"] * np.exp(-(tt - sc["t_CC_s"]) / Ic["tau_s"]))
    imed[tt > Ic["t_stop_teoretic"]] = 0
    ax[0].plot(tt * 1e3, imed, color=TEXT, lw=1.0, ls="--", label="model mediu (aceeași scalare)")
    ax[0].set_ylabel("I [A]")
    ax[0].legend(fontsize=7.5, loc="upper right")
    ax[1].plot(tm, Ic["U"], color=CUL[0], lw=0.6)
    ax[1].axhline(C["U_CV"], color=TEXT2, ls="--", lw=0.8)
    ax[1].set_ylabel("U_bat [V]")
    ax[1].set_xlabel(f"t [ms] (timp scalat: 1 ms ≙ {ro(sc['k_timp']/1e3/60, 2)} min reale)")
    for a in ax:
        c4.grila(a)
    fig.suptitle(f"Încărcătorul cu comutație: coborâtor cu histerezis (h = {ro(C['h'], 1)} A), trecerea CC → CV", fontsize=10.5)
    fig.tight_layout()
    fig.savefig(d / "p5_incarcator_comutatie.png", dpi=140)
    plt.close(fig)
    # modelul OCV comparat cu curba de descărcare 0,2C din fișa celulei
    cd = cv["curba_descarcare_02C"]
    Q = np.array(cd["Q_mAh"]) / 1000
    soc = 1 - Q / R["S"]["cel"]["Cap_Ah"]
    fig, ax = plt.subplots(figsize=(7.2, 4.0))
    ax.plot(100 * soc, cd["U_V"], "o", color=CUL[1], ms=6, label="Molicel P50B: descărcare 0,2C (citit de pe grafic)")
    s = np.linspace(0, 1, 50)
    ax.plot(100 * s, cv["OCV_celula_SOC0_V"] + (R["S"]["cel"]["U_max"] - cv["OCV_celula_SOC0_V"]) * s, color=CUL[0],
            label="model liniar folosit (medie 3,6 V = U_nom)")
    ax.set(xlabel="SOC [%]", ylabel="U celulă [V]", title="Modelul tensiunii de mers în gol al celulei")
    ax.legend(fontsize=8)
    c4.grila(ax)
    fig.tight_layout()
    fig.savefig(d / "p5_model_ocv.png", dpi=140)
    plt.close(fig)


def figuri(R, d):
    d.mkdir(exist_ok=True)
    c4.stil()
    fig_dcdc(R, d)
    fig_incarcare(R, d)


# ---------------------------------------------------------------- tabele README
def da(x):
    return "DA" if x else "NU"


def tabele(R, nr=None):
    D, H, C, Im, Ic, Dc, S = R["D"], R["H"], R["C"], R["Im"], R["Ic"], R["Dc"], R["S"]
    cv = S["cv"]
    md, cd = cv["dcdc"]["modul"], cv["dcdc"]["condensator"]
    tb = {}
    tb["dcdc"] = "\n".join([
        "| Mărime | Valoare | Relația / observații |",
        "|---|---|---|",
        f"| Punctul de dimensionare | 3 × {ro(D['T_motor_Pmax'], 1)} Nm la {ro(S['T']['n_m_Va'], 0)} rot/min | P_max (P2) la 100 km/h, η motor = {ro(100*D['eta_motor_Pmax'], 2)} % (harta C3) |",
        f"| P în circuitul intermediar | {ro(D['P_dc_max']/1e3, 1)} kW | 3·P1 / η_invertor (η = {ro(cv['dcdc']['eta_invertor'], 3)}) |",
        f"| P cerută bateriei | {ro(D['P_bat_max']/1e3, 1)} kW | / η_DC-DC (ipoteză {ro(cv['dcdc']['eta_dcdc_ipoteza'], 3)}) |",
        f"| U_dc / U_bat | {ro(D['U_dc'], 0)} V / {ro(D['U_bat_min'], 0)}…{ro(D['U_bat_max'], 0)} V (nominal {ro(D['U_bat_nom'], 0)} V) | – |",
        f"| D ridicător | {ro(D['D_min_regl'], 2)} … {ro(D['D_max'], 4)} (nominal {ro(D['D_nom'], 3)}) | D = 1 − U_bat/U_dc; pentru U_bat > {ro(D['U_trecere'], 0)} V: trecere directă (D = 0) |",
        f"| D coborâtor (recuperare) | {ro(D['Dc_min'], 3)} … {ro(D['Dc_max'], 4)} | D_c = U_bat/U_dc |",
        f"| I_bat max (U_bat = U_min) | {ro(D['I_bat_max'], 0)} A | {D['N_faze']} faze × {ro(D['I_faza_max'], 1)} A |",
        f"| Ondulația curentului pe fază ΔI | {ro(D['dI'], 1)} A ({ro(100*cv['dcdc']['ondulatie_I_rel'], 0)} %) | TI SLVA372D: 20–40 % |",
        f"| Bobina pe fază L | **{ro(D['L']*1e6, 1)} µH** | L = U_bat·D/(ΔI·f_s), maxim la U_bat = {ro(D['U_bat_ondulatie_max'], 0)} V |",
        f"| Curentul de vârf pe fază | {ro(D['I_varf_faza'], 1)} A | I_faza + ΔI/2 |",
        f"| Condensatorul circuitului intermediar | **≥ {ro(D['C']*1e6, 0)} µF** ({math.ceil(D['C']*1e6/cd['C_uF'])} × {cd['C_uF']} µF) | C = I_dc·D_max/(ΔU·f_s), ΔU = {ro(D['dU'], 0)} V (1 %), o fază echivalentă (acoperitor) |",
        f"| Modulul | {md['nume']} | U_DS = {md['U_DS_V']} V ≥ U_dc/0,8: {da(D['ok_U_modul'])}; I_vârf ≤ 0,8·{md['I_D_A']} A: {da(D['ok_I_modul'])} |",
        f"| Pierderi în tranzistoare la P_max | {ro(D['P_pierderi']/1e3, 2)} kW (η = {ro(100*D['eta_calc'], 2)} %) | conducție {ro(D['P_cond_faza'], 0)} W + comutație {ro(D['P_com_faza'], 0)} W pe fază |",
    ])
    tb["chopper"] = "\n".join([
        "| Mărime | Valoare |",
        "|---|---|",
        f"| f_pwm (modulație unipolară, frecvența ondulației 2·f_pwm) | {ro(H['f_pwm']/1e3, 0)} kHz |",
        f"| L_a (= τ_a·R_a) | {ro(H['L_a']*1e3, 3)} mH |",
        f"| Ondulația maximă ΔI = U_dc/(8·L_a·f_pwm) (m = 0,5) | {ro(H['dI_max'], 1)} A ({ro(100*H['dI_max_rel'], 1)} % din I_max) → ΔT = {ro(H['dT_max'], 1)} Nm |",
        f"| Nominal / cuplu maxim / P_max la 100 km/h: m = U/U_dc | {ro(H['m'][0], 3)} / {ro(H['m'][1], 3)} / {ro(H['m'][2], 3)} |",
        f"| ΔI în aceste puncte | {ro(H['dI'][0], 1)} / {ro(H['dI'][1], 1)} / {ro(H['dI'][2], 1)} A |",
        f"| Curentul de vârf al tranzistoarelor | {ro(H['I_varf'], 1)} A |",
    ])
    tb["incarcator"] = "\n".join([
        "| Mărime | Valoare | Observații |",
        "|---|---|---|",
        f"| Rețea / putere AC | 3 × {ro(C['U_AC'], 0)} V, {ro(C['P_AC']/1e3, 0)} kW | încărcător de bord (mod 3, IEC 61851) |",
        f"| U_PFC (tensiunea după PFC) | {ro(C['U_dc'], 0)} V | > √2·U_AC = {ro(C['U_dc_min_PFC'], 0)} V și > U_CV: {da(C['ok_U_PFC'])} |",
        f"| P în baterie | {ro(C['P_bat']/1e3, 2)} kW | η_PFC·η_coborâtor = {ro(cv['incarcator']['eta_PFC']*cv['incarcator']['eta_buck'], 3)} |",
        f"| Faza CC | {ro(C['I_CC'], 2)} A = {ro(C['C_rate'], 3)}C ({ro(C['I_cel_CC'], 3)} A/celulă) | I_CC = P_bat/U_CV; fișa celulei: standard 1C, maxim 5C |",
        f"| Faza CV | {ro(C['U_CV'], 0)} V (4,2 V/celulă) | oprire la {ro(C['I_taiere'], 2)} A (50 mA/celulă, sursă secundară) |",
        f"| D coborâtor | {ro(C['D_min'], 3)} … {ro(C['D_max'], 3)} | D = U_bat/U_PFC |",
        f"| Histerezis / bobină | h = {ro(C['h'], 2)} A → L = {ro(C['L']*1e6, 0)} µH | f = U_PFC·D(1−D)/(h·L) ≤ {ro(cv['incarcator']['f_s_max_Hz']/1e3, 0)} kHz |",
        f"| Baterie (model) | R = {ro(C['R_bat']*1e3, 1)} mΩ, OCV {ro(C['U_0'], 0)}…{ro(C['U_CV'], 0)} V, C_eq = {ro(C['C_eq'], 0)} F, τ_CV = {ro(C['tau_CV'], 0)} s | OCV liniar, medie = U_nom |",
        f"| Durata (analitic) de la SOC = {ro(100*C['SOC0'], 0)} % | CC {ro(C['t_CC']/3600, 2)} h + CV {ro(C['t_CV']/60, 1)} min = {ro(C['t_total']/3600, 2)} h | – |",
    ])
    tr, rec = Dc["tr"], Dc["rec"]
    sc = cv["simulare"]
    tb["simulari"] = "\n".join([
        "| Simulare | Rezultat | Verificare |",
        "|---|---|---|",
        f"| Încărcare completă, model mediu (pas {ro(cv['incarcator']['dt_medie_s'], 0)} s) | CC {ro(Im['t_CC']/3600, 2)} h, total {ro(Im['t_total']/3600, 2)} h, SOC final {ro(100*Im['SOC_final'], 2)} %; "
        f"din rețea {ro(Im['E_AC']/3.6e6, 2)} kWh, în baterie {ro(Im['E_bat']/3.6e6, 2)} kWh, stocat {ro(Im['E_stocata']/3.6e6, 2)} kWh | "
        f"analitic: {ro(C['t_CC']/3600, 2)} h / {ro(C['t_total']/3600, 2)} h |",
        f"| Încărcător cu comutație (timp scalat 1:{sc['incarcare']['k_timp']}) | trecere CC → CV la {ro(Ic['t_CC']*1e3, 2)} ms; I la t_CC + τ = {ro(Ic['I_med_tau'], 2)} A; "
        f"f în CC = {ro(Ic['f_CC']/1e3, 1)} kHz; oprire (I < {ro(C['I_taiere'], 2)} A) la {ro(Ic['t_stop']*1e3, 1)} ms | model mediu: {ro(sc['incarcare']['t_CC_s']*1e3, 0)} ms (impus prin OCV inițial); "
        f"{ro(Ic['I_med_tau_teoretic'], 2)} A; {ro(Ic['f_CC_teoretic']/1e3, 1)} kHz; oprire la {ro(Ic['t_stop_teoretic']*1e3, 1)} ms |",
        f"| DC-DC cu comutație – tracțiune ({ro(D['P_dc_max']/1e3, 0)} kW) | I_bat = {ro(tr['I_bat_med'], 0)} A, U_bat = {ro(tr['U_bat_med'], 1)} V, D = {ro(tr['D_med'], 4)}, "
        f"U_dc = {ro(tr['U_dc_med'], 2)} V; ΔI pe fază {ro(tr['dI_faza'], 1)} A, ΔI_bat {ro(tr['dI_bat'], 1)} A, ΔU_dc {ro(tr['dU_dc'], 2)} V | "
        f"D = {ro(tr['D_teoretic'], 4)}; ΔI pe fază = {ro(tr['dI_faza_teoretic'], 1)} A; ΔU_dc ≤ {ro(D['dU'], 0)} V |",
        f"| DC-DC cu comutație – recuperare ({ro(sc['dcdc']['P_franare_rel']*D['P_dc_max']/1e3, 0)} kW) | I_bat = {ro(rec['I_bat_med'], 0)} A, U_bat = {ro(rec['U_bat_med'], 1)} V, D = {ro(rec['D_med'], 4)}, "
        f"U_dc = {ro(rec['U_dc_med'], 2)} V; ΔI pe fază {ro(rec['dI_faza'], 1)} A, ΔI_bat {ro(rec['dI_bat'], 1)} A | D = {ro(rec['D_teoretic'], 4)}; ΔI pe fază = {ro(rec['dI_faza_teoretic'], 1)} A |",
        f"| DC-DC – schimbările de sarcină (pante de {ro(sc['dcdc']['t_rampa']*1e3, 0)} ms) | U_dc min {ro(Dc['U_dc_min'], 1)} V la intrarea în tracțiune, max {ro(Dc['U_dc_max'], 1)} V la trecerea în recuperare | "
        f"{ro(100*(Dc['U_dc_min']-D['U_dc'])/D['U_dc'], 1)} % / +{ro(100*(Dc['U_dc_max']-D['U_dc'])/D['U_dc'], 1)} % |",
    ])
    Ptr = D["P_dc_max"]
    Pfr = sc["dcdc"]["P_franare_rel"] * Ptr
    tb["dcdc_text"] = (
        f"Cele {D['N_faze']} faze defazate cu T_s/{D['N_faze']} își compensează ondulațiile; efectul depinde de factorul de umplere. "
        f"La tracțiune (D ≈ {ro(tr['D_med'], 2)}, aproape de 1/{D['N_faze']}, unde compensarea este aproape completă) ondulația "
        f"curentului bateriei este de {ro(tr['dI_faza']/tr['dI_bat'], 1)} ori mai mică decât a unei faze ({ro(tr['dI_bat'], 1)} A față de "
        f"{ro(tr['dI_faza'], 1)} A); la recuperare (D ≈ {ro(rec['D_med'], 2)}) reducerea este mai mică ({ro(rec['dI_bat'], 1)} A față de "
        f"{ro(rec['dI_faza'], 1)} A). Ondulația tensiunii circuitului intermediar ({ro(tr['dU_dc'], 2)} V, respectiv {ro(rec['dU_dc'], 2)} V) "
        f"este mult sub cele {ro(D['dU'], 0)} V ale calculului acoperitor cu o singură fază (în simulare sarcina este ideală, fără "
        f"ondulația de curent a invertoarelor). Puterea sarcinii trece de la 0 la {ro(Ptr/1e3, 0)} kW și apoi la −{ro(Pfr/1e3, 0)} kW "
        f"(o schimbare de {ro((Ptr+Pfr)/1e3, 0)} kW) cu pante de {ro(sc['dcdc']['t_rampa']*1e3, 0)} ms; tensiunea circuitului intermediar "
        f"rămâne între {ro(Dc['U_dc_min'], 1)} V și {ro(Dc['U_dc_max'], 1)} V – vârful depășește cu {ro(100*(Dc['U_dc_max']/D['U_dc']-1), 1)} % "
        "tensiunea maximă din domeniul de aplicare al motoarelor (800 V), timp de sub 1 ms.")
    if nr:
        tb["comparatie"] = (f"Implementarea Python (python/model_p5p6.py) refăcută independent de MATLAB/Octave: {nr[0]} mărimi comparate, "
                            f"{len(nr[1])} diferențe peste toleranța relativă 10⁻⁶.")
    return tb


def main():
    R = m5.calculeaza_tot(cu_simulari=True)
    py = iesire(R)
    (RADACINA / "rezultate").mkdir(exist_ok=True)
    (RADACINA / "rezultate" / "rezultate_python.json").write_text(json.dumps(py, indent=1, ensure_ascii=False),
                                                                  encoding="utf-8")
    nr = c4.compara(py, RADACINA / "rezultate" / "rezultate_matlab.json")
    figuri(R, RADACINA / "figuri")
    actualizeaza_readme(RADACINA / "README.md", tabele(R, nr))
    D, C, Im = R["D"], R["C"], R["Im"]
    print(f"DC-DC: L = {D['L']*1e6:.1f} µH, C = {D['C']*1e6:.0f} µF, η = {100*D['eta_calc']:.2f} % | încărcare "
          f"{Im['t_total']/3600:.2f} h, I_CC = {C['I_CC']:.2f} A")
    return 0


if __name__ == "__main__":
    sys.exit(main())
