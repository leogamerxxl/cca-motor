"""CCA – Proiect P2 / P3: implementare Python, registrul Excel cu formule și figurile.

Rulare (din rădăcina depozitului):
    python3 etapa2-calcule/python/calcule_p2_p3.py

Ce face:
  1. citește date/date_documentare.csv (aceleași date ca scripturile MATLAB);
  2. refă calculele P2 și P3 (aceleași formule ca în matlab/*.m) și scrie
     rezultate/rezultate_python.json;
  3. dacă există rezultate/rezultate_matlab.json (din matlab/ruleaza_tot.m),
     compară cele două implementări;
  4. generează CCA_Etapa2_Calcule.xlsx (toate calculele ca formule Excel) și
     figurile din figuri/.
"""
import csv
import json
import math
import sys
import time
from pathlib import Path

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

AICI = Path(__file__).resolve().parent
RADACINA = AICI.parent

# Aceleași ipoteze ca matlab/constante.m
C = dict(g=9.81, rho=1.293, mu_f=0.013, mu_a=0.8, alpha=0.0, Vv=0.0,
         r=0.35, pp=0.01, Va_kmh=100.0, n_max=15000.0,
         V1_kmh=50.0, eta=0.80, rezerva=0.30, n_pasi=[100, 1000],
         U_bat_tinta=800.0, k_masa_bat=0.30)

# Aceeași celulă ca matlab/celula_aleasa.m
CELULA = None  # completat din celula_aleasa.json

ET1 = "Etapa 1 – sursele din etapa1-documentare/CCA_Etapa1_Documentare.xlsx, foaia Surse"
SURSE = [
    ("Date vehicule: putere, v_max, 0–100, masă, cuplu, baterie, Cx", ET1, "../etapa1-documentare/README.md"),
    ("GT 63 – autonomie WLTP 596–696 km, consum 17,9–21,0, S = 2,44 m²",
     "Mercedes-Benz Media – comunicat de lansare (tabel tehnic)",
     "https://media.mercedes-benz.com/en/article/c8b7109f-2287-4070-b776-9204da1513ef"),
    ("Porsche Taycan Turbo GT Weissach – WLTP 538–555 km, anvelope, S = 2,35 m²", "Porsche – fișă tehnică (PDF)",
     "https://newsroom.porsche.com/dam/jcr:c96cbebc-3745-4700-b385-981a9c4fe91d/pag-taycan-turbo-gt-weissachpaket-td-en.pdf"),
    ("Audi RS e-tron GT performance – WLTP 533–592 km, anvelope, S = 2,35 m²", "Audi MediaCenter – date tehnice (PDF)",
     "https://uploads.audi-mediacenter.com/system/production/car_motorizations/1392/file_en/"
     "91bfc69ec55530e277b5023245b77c1c82772920/eTD-Audi-RS-e-tron-GT-performance-550kW_250515.pdf"),
    ("Lotus Emeya R – WLTP 435–485 km", "Lotus – presă, specificații tehnice Emeya",
     "https://www.lotuscars.com/en/press/models/emeya"),
    ("Tesla Model S Plaid – WLTP 600–611 km, 18,0–18,7 kWh/100 km (S)", "EV Database (tesla.com blochează accesul)",
     "https://ev-database.org/car/3384/Tesla-Model-S-Plaid"),
    ("Lucid Air Sapphire – WLTP 694 km, 19,1 kWh/100 km", "Lucid – pagina Air (Germania)",
     "https://lucidmotors.com/de-de/air"),
    ("Lucid Air Sapphire – anvelope 295/30R21 spate", "Lucid – fișă tehnică 2024 (PDF)",
     "https://lucidmotors.com/media/document/lucid-air-sapphire-technical-specs-2024.pdf"),
    ("Xiaomi SU7 Ultra – CLTC 555–630 km", "Xiaomi – tabel de parametri SU7 Ultra",
     "https://www.xiaomiev.com/car-config?carItemId=500010402"),
    ("Xiaomi SU7 Ultra – consum 16,5 kWh/100 km CLTC (S)", "CarNewsChina – baza de date",
     "https://data.carnewschina.com/xiaomi-auto/su7-ultra/2025/params"),
    ("Yangwang U9 – CLTC 450 km", "Yangwang – broșura U9 (PDF, 23.12.2025)",
     "https://www.yangwangauto.com/material/yangwang_cn/images/u9/2025-12-23/U9%E8%BD%A6%E4%B9%A620251223.pdf"),
    ("Rimac Nevera – WLTP 489 km, 30,0 kWh/100 km, anvelope 315/35 R20", "Rimac – pagina Nevera",
     "https://www.rimac-automobili.com/nevera/"),
    ("Maserati GranTurismo Folgore – WLTP 450–459 km, 21,9–22,3 kWh/100 km (S)",
     "EV Database (maserati.com blochează accesul)", "https://ev-database.org/car/1803/Maserati-GranTurismo-Folgore"),
    ("Celula Molicel INR-21700-P50B", "Molicel – Product Data Sheet v1.1 (PDF)",
     "https://www.molicel.com/wp-content/uploads/4.TR%E7%B0%A1%E6%98%93%E8%A6%8F%E6%A0%BC_INR21700P50B_1.1_"
     "Product-Data-Sheet-of-INR-21700-P50B-80122.pdf"),
    ("Celule analizate: Molicel P45B", "Molicel – Product Data Sheet v1.4 (PDF)",
     "https://www.molicel.com/wp-content/uploads/INR21700P45B_1.4_Product-Data-Sheet-of-INR-21700-P45B-80109.pdf"),
    ("Metoda de calcul", "Suport curs CCA – Proiect P2 (07.10.2026) și P3 (14.10.2026)", "–"),
]


# ---------------------------------------------------------------- date
def citeste_date(cale):
    with open(cale, encoding="utf-8") as f:
        randuri = list(csv.DictReader(f))
    vehicule = []
    for r in randuri:
        v = {k: (val if k in ("vehicul", "ciclu") else float(val)) for k, val in r.items()}
        vehicule.append(v)
    return vehicule


def nanmean(xs):
    xs = [x for x in xs if not math.isnan(x)]
    return sum(xs) / len(xs)


def derivate(v):
    d = dict(v)
    d["P_W"] = v["P_max_kW"] * 1e3
    d["vmax_ms"] = v["v_max_kmh"] / 3.6
    d["a_ms2"] = (v["v_acc_kmh"] / 3.6) / v["t_acc_s"]
    d["bat_Ws"] = v["baterie_kWh"] * 3.6e6
    d["aut_km"] = (v["autonomie_min_km"] + v["autonomie_max_km"]) / 2
    d["cons_kWh100"] = (v["consum_min_kWh100"] + v["consum_max_kWh100"]) / 2
    d["cons_Wsm"] = d["cons_kWh100"] / 100 * 3600
    d["r_static_m"] = (v["janta_spate_inch"] * 25.4 / 2
                       + v["anv_spate_latime_mm"] * v["anv_spate_profil_pct"] / 100) / 1000
    return d


def vehicul_mediu(tab):
    m = lambda k: nanmean([t[k] for t in tab])  # noqa: E731
    w = lambda k: nanmean([t[k] for t in tab if t["ciclu"] == "WLTP"])  # noqa: E731  autonomie/consum: doar WLTP
    return dict(nume="Vehicul mediu (documentare)", P_doc=m("P_W"), vmax=m("vmax_ms"), a_doc=m("a_ms2"),
                M=m("masa_kg"), cuplu_doc=m("cuplu_Nm"), W_bat_doc=m("bat_Ws"), autonomie=w("aut_km") * 1e3,
                consum_doc=w("cons_Wsm"), Cx=m("Cx"), S=m("A_m2"), r_static=m("r_static_m"))


def vehicul_gt63(tab, med):
    t = next(t for t in tab if t["vehicul"].startswith("Mercedes-AMG GT 63"))
    return dict(nume=t["vehicul"], P_doc=t["P_W"], vmax=t["vmax_ms"], a_doc=t["a_ms2"], M=t["masa_kg"],
                cuplu_doc=t["cuplu_Nm"], W_bat_doc=t["bat_Ws"], autonomie=t["aut_km"] * 1e3,
                consum_doc=t["cons_Wsm"], Cx=t["Cx"], S=t["A_m2"], r_static=med["r_static"])


# ---------------------------------------------------------------- calcule (oglinda fișierelor .m)
def forte(v, a, V, c=C):
    v = np.asarray(v, dtype=float)
    Ff = c["mu_f"] * V["M"] * c["g"] * math.cos(c["alpha"]) * np.ones_like(v)
    Fra = 0.5 * c["rho"] * V["S"] * V["Cx"] * (v - c["Vv"]) ** 2
    Gt = V["M"] * c["g"] * math.sin(c["alpha"]) * np.ones_like(v)
    Fi = V["M"] * a * np.ones_like(v)
    return dict(Ff=Ff, Fra=Fra, Gt=Gt, Fi=Fi, Ft=Fra + Ff + Gt + Fi,
                Fa=c["mu_a"] * V["M"] * c["g"] * math.cos(c["alpha"]))


def f(x):
    return float(np.asarray(x).item()) if np.ndim(x) == 0 or np.size(x) == 1 else x


def calcul_p2(V, c=C):
    R = dict(nume=V["nume"])
    R["Va"] = c["Va_kmh"] / 3.6
    R["a_doc"] = V["a_doc"]
    R["ta_doc"] = R["Va"] / R["a_doc"]
    F3 = forte(R["Va"], R["a_doc"], V, c)
    R["Fra_Va"], R["Ff"], R["Gt"], R["Ft_doc"], R["Fa"] = (f(F3["Fra"]), f(F3["Ff"]), f(F3["Gt"]),
                                                          f(F3["Ft"]), F3["Fa"])
    R["aderenta_ok"] = R["Ft_doc"] <= R["Fa"]
    if R["aderenta_ok"]:
        R["a"], R["Ft"] = R["a_doc"], R["Ft_doc"]
    else:
        R["a"] = (R["Fa"] - R["Fra_Va"] - R["Ff"] - R["Gt"]) / V["M"]
        R["Ft"] = R["Fa"]
    R["ta"] = R["Va"] / R["a"]
    R["Omega_r_Va"] = R["Va"] / c["r"]
    R["Mr"] = c["r"] * R["Ft"]
    R["Pr"] = R["Mr"] * R["Omega_r_Va"]
    R["Pax"] = R["Pr"] / (1 - c["pp"])
    R["Pp"] = R["Pax"] - R["Pr"]
    R["Omega_r_max"] = V["vmax"] / c["r"]
    R["Omega_ax_max"] = c["n_max"] * 2 * math.pi / 60
    R["i_rd"] = R["Omega_r_max"] / R["Omega_ax_max"]
    R["k_rd"] = 1 / R["i_rd"]
    R["Omega_ax_Va"] = R["Omega_r_Va"] / R["i_rd"]
    R["n_ax_Va"] = R["Omega_ax_Va"] * 60 / (2 * math.pi)
    R["Max"] = R["Pax"] / R["Omega_ax_Va"]
    F7 = forte(V["vmax"], 0.0, V, c)
    R["vmax"] = V["vmax"]
    R["Fra_vmax"], R["Ft_vmax"] = f(F7["Fra"]), f(F7["Ft"])
    R["aderenta_vmax_ok"] = R["Ft_vmax"] <= R["Fa"]
    if not R["aderenta_vmax_ok"]:
        R["vmax"] = math.sqrt((R["Fa"] - R["Ff"] - R["Gt"]) / (0.5 * c["rho"] * V["S"] * V["Cx"])) + c["Vv"]
        R["Ft_vmax"] = R["Fa"]
    R["Mr_vmax"] = c["r"] * R["Ft_vmax"]
    R["Pr_vmax"] = R["Ft_vmax"] * R["vmax"]
    R["Pax_nom"] = R["Pr_vmax"] / (1 - c["pp"])
    R["Max_vmax"] = R["Pax_nom"] / R["Omega_ax_max"]
    R["P_max"], R["P_nom"] = R["Pax"], R["Pax_nom"]
    R["Pax_fara_aderenta"] = R["Ft_doc"] * R["Va"] / (1 - c["pp"])
    R["P_doc"] = V["P_doc"]
    R["raport_vmax"] = R["vmax"] / R["Va"]
    return R


def calcul_p3(V, R2, c=C):
    R = dict(nume=V["nume"])
    R["V1"] = c["V1_kmh"] / 3.6
    R["a"] = R2["a"]
    F1 = forte(R["V1"], R["a"], V, c)
    R["aderenta_ok"] = bool(f(F1["Ft"]) <= F1["Fa"])
    if not R["aderenta_ok"]:
        R["a"] = (F1["Fa"] - f(F1["Fra"]) - f(F1["Ff"]) - f(F1["Gt"])) / V["M"]
        F1 = forte(R["V1"], R["a"], V, c)
    R["Fra_V1"], R["Ff"], R["Gt"], R["Fa"], R["Ft1"] = (f(F1["Fra"]), f(F1["Ff"]), f(F1["Gt"]),
                                                       F1["Fa"], f(F1["Ft"]))
    R["P1"] = R["Ft1"] * R["V1"]
    R["Ft1p"] = f(forte(R["V1"], 0.0, V, c)["Ft"])
    R["P1p"] = R["Ft1p"] * R["V1"]
    R["t1"] = R["V1"] / R["a"]
    R["P0"] = 0.0
    R["Pmed"] = (R["P0"] + R["P1"]) / 2
    A = R["Ff"] + R["Gt"] + V["M"] * R["a"]
    B = 0.5 * c["rho"] * V["S"] * V["Cx"]
    R["W01_exact"] = A * R["a"] * R["t1"] ** 2 / 2 + B * R["a"] ** 3 * R["t1"] ** 4 / 4
    R["P01_exact"] = R["W01_exact"] / R["t1"]
    R["disc"] = []
    for n in c["n_pasi"]:
        dt = R["t1"] / n
        t = np.linspace(0, R["t1"], n + 1)
        v = R["a"] * t
        P = forte(v, R["a"], V, c)["Ft"] * v
        P01 = float(P[1:].sum() / n)
        W01 = float(P.sum() * dt)
        nrep = 2000
        t0 = time.perf_counter()
        for _ in range(nrep):
            tt = np.linspace(0, R["t1"], n + 1)
            vv = R["a"] * tt
            float(((B * vv ** 2 + A) * vv).sum() * dt)
        durata = (time.perf_counter() - t0) / nrep
        R["disc"].append(dict(n=n, dt=dt, t=t, P=P, P01_med=P01, W01=W01, W01_med=P01 * R["t1"],
                              eroare_W01_pct=(W01 - R["W01_exact"]) / R["W01_exact"] * 100, timp_s=durata))
    R["Wmed"] = R["Pmed"] * R["t1"]
    R["P01_med"] = R["disc"][-1]["P01_med"]
    R["W01_med"] = R["disc"][-1]["W01_med"]
    R["W01"] = R["disc"][-1]["W01"]
    R["d1"] = R["V1"] * R["t1"] / 2
    R["df"] = R["d1"]
    R["autonomie"] = V["autonomie"]
    R["d2"] = R["autonomie"] - R["d1"] - R["df"]
    R["t12"] = R["d2"] / R["V1"]
    R["t2"] = R["t1"] + R["t12"]
    R["tf"] = R["t2"] + R["t1"]
    R["W12"] = R["P1p"] * R["t12"]
    R["W2f"] = R["W01"]
    R["Wmec"] = R["W01"] + R["W12"] - R["W2f"]
    R["Wstocata"] = R["W01"] / c["eta"] + R["W12"] / c["eta"] - c["eta"] * R["W2f"]
    R["Wbat"] = R["Wstocata"] / (1 - c["rezerva"])
    R["Wbat_kWh"] = R["Wbat"] / 3.6e6
    R["Wstocata_kWh"] = R["Wstocata"] / 3.6e6
    R["consum_stoc_kWh100"] = R["Wstocata"] / R["autonomie"] * 100 / 3600
    R["W_bat_doc_kWh"] = V["W_bat_doc"] / 3.6e6
    R["consum_doc_kWh100"] = V["consum_doc"] * 100 / 3600
    return R


def dimensionare_baterie(Wbat, cel, V, P_max, c=C):
    B = {}
    B["W_celula"] = cel["Cap_Ah"] * 3600 * cel["U_nom"]
    B["N_min"] = math.ceil(Wbat / B["W_celula"])
    B["Ns"] = round(c["U_bat_tinta"] / cel["U_nom"])
    B["U_nom"] = B["Ns"] * cel["U_nom"]
    B["U_max"] = B["Ns"] * cel["U_max"]
    B["U_min"] = B["Ns"] * cel["U_min"]
    B["Np_energie"] = math.ceil(B["N_min"] / B["Ns"])
    B["P_el_max"] = P_max / c["eta"]
    B["I_bat_max"] = B["P_el_max"] / B["U_nom"]
    B["Np_curent"] = math.ceil(B["I_bat_max"] / cel["I_max_cont"])
    B["Np"] = max(B["Np_energie"], B["Np_curent"])
    B["N"] = B["Ns"] * B["Np"]
    B["W_real"] = B["N"] * B["W_celula"]
    B["W_real_kWh"] = B["W_real"] / 3.6e6
    B["Cap_Ah"] = B["Np"] * cel["Cap_Ah"]
    B["I_celula"] = B["I_bat_max"] / B["Np"]
    B["m_celule"] = B["N"] * cel["m_kg"]
    B["m_pachet"] = B["m_celule"] / cel["k_celula_pachet"]
    B["m_limita"] = c["k_masa_bat"] * V["M"]
    B["masa_ok_celule"] = B["m_celule"] <= B["m_limita"]
    B["masa_ok_pachet"] = B["m_pachet"] <= B["m_limita"]
    B["procent_celule"] = B["m_celule"] / V["M"] * 100
    B["procent_pachet"] = B["m_pachet"] / V["M"] * 100
    return B


def ruleaza(vehicule_csv, celula):
    tab = [derivate(v) for v in citeste_date(vehicule_csv)]
    med = vehicul_mediu(tab)
    gt = vehicul_gt63(tab, med)
    rez = {}
    for cheie, V in (("medie", med), ("gt63", gt)):
        R2 = calcul_p2(V)
        R3 = calcul_p3(V, R2)
        B = dimensionare_baterie(R3["Wbat"], celula, V, R2["P_max"])
        rez[cheie] = dict(date=V, p2=R2, p3=R3, baterie=B)
    return tab, rez


# ---------------------------------------------------------------- comparația cu MATLAB
def compara_cu_matlab(rez, cale_json, tol=1e-6):
    if not cale_json.exists():
        print("(nu există rezultate_matlab.json – rulați matlab/ruleaza_tot.m pentru comparație)")
        return None
    m = json.loads(cale_json.read_text(encoding="utf-8"))
    dif = []
    nr = 0
    for cheie in ("medie", "gt63"):
        for bloc_py, bloc_m in (("p2", "p2"), ("p3", "p3"), ("baterie", "baterie"), ("date", "date")):
            for k, vm in m[cheie][bloc_m].items():
                vp = rez[cheie][bloc_py].get(k)
                if isinstance(vm, bool) or isinstance(vp, bool):
                    nr += 1
                    if bool(vm) != bool(vp):
                        dif.append((cheie, bloc_py, k, vm, vp))
                    continue
                if not isinstance(vm, (int, float)) or not isinstance(vp, (int, float, np.floating)):
                    continue
                nr += 1
                if abs(vm - vp) > tol * max(1.0, abs(vm)):
                    dif.append((cheie, bloc_py, k, vm, vp))
        dm = m[cheie]["p3_discretizare"]
        for q, n in enumerate(dm["n"]):
            for k in ("P01_med", "W01"):
                nr += 1
                vp = rez[cheie]["p3"]["disc"][q][k]
                if abs(dm[k][q] - vp) > tol * max(1.0, abs(vp)):
                    dif.append((cheie, "disc", f"{k}[n={n}]", dm[k][q], vp))
    print(f"Comparație MATLAB/Octave – Python: {nr} mărimi comparate, {len(dif)} diferențe (toleranță relativă {tol:g})")
    for d in dif:
        print("  DIFERENȚĂ", d)
    return nr, dif


# ---------------------------------------------------------------- figuri
def figuri(rez, dir_fig):
    dir_fig.mkdir(exist_ok=True)
    V, R2, R3 = rez["medie"]["date"], rez["medie"]["p2"], rez["medie"]["p3"]
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10})

    v = np.linspace(0, V["vmax"], 300)
    va = np.linspace(0, R2["Va"], 120)  # faza de accelerare: 0 – Va
    Fd_ = forte(va, R2["a_doc"], V)      # cu accelerația din documentare
    Fa_ = forte(va, R2["a"], V)          # cu accelerația limitată de aderență
    Fc_ = forte(v, 0.0, V)               # rulare cu viteză constantă
    fig, ax = plt.subplots(1, 2, figsize=(11, 4.2))
    ax[0].plot(va * 3.6, Fd_["Ft"] / 1e3, ":", color="C3",
               label=f"$F_t$ cu $a_{{doc}}$ = {R2['a_doc']:.2f} m/s² (depășește aderența)")
    ax[0].plot(va * 3.6, Fa_["Ft"] / 1e3, color="C0", label=f"$F_t$ cu a = {R2['a']:.2f} m/s² (0–100 km/h)")
    ax[0].plot(v * 3.6, Fc_["Ft"] / 1e3, color="C1", label="$F_t$ la viteză constantă (a = 0)")
    ax[0].axhline(Fd_["Fa"] / 1e3, ls="--", color="k", lw=1, label=f"$F_a$ = µ$_a$Mg = {Fd_['Fa']/1e3:.1f} kN")
    ax[0].plot([R2["Va"] * 3.6], [R2["Ft"] / 1e3], "o", color="C0")
    ax[0].plot([R2["vmax"] * 3.6], [R2["Ft_vmax"] / 1e3], "s", color="C1")
    ax[0].set(xlabel="v [km/h]", ylabel="F [kN]", title="Forța de tracțiune necesară")
    ax[0].legend(fontsize=7.5, loc="center right")
    ax[1].plot(va * 3.6, Fd_["Ft"] * va / (1 - C["pp"]) / 1e3, ":", color="C3", label="$P_{ax}$ cu $a_{doc}$")
    ax[1].plot(va * 3.6, Fa_["Ft"] * va / (1 - C["pp"]) / 1e3, color="C0", label="$P_{ax}$ cu a (0–100 km/h)")
    ax[1].plot(v * 3.6, Fc_["Ft"] * v / (1 - C["pp"]) / 1e3, color="C1", label="$P_{ax}$ la viteză constantă")
    ax[1].axhline(V["P_doc"] / 1e3, ls="--", color="0.5", lw=1, label=f"P declarată (medie) = {V['P_doc']/1e3:.0f} kW")
    ax[1].plot([R2["Va"] * 3.6], [R2["P_max"] / 1e3], "o", color="C0")
    ax[1].annotate(f"P_max = {R2['P_max']/1e3:.0f} kW", (R2["Va"] * 3.6, R2["P_max"] / 1e3),
                   textcoords="offset points", xytext=(8, -14), fontsize=8)
    ax[1].plot([R2["vmax"] * 3.6], [R2["P_nom"] / 1e3], "s", color="C1")
    ax[1].annotate(f"P_nom = {R2['P_nom']/1e3:.0f} kW", (R2["vmax"] * 3.6, R2["P_nom"] / 1e3),
                   textcoords="offset points", xytext=(-95, 6), fontsize=8)
    ax[1].set(xlabel="v [km/h]", ylabel="P [kW]", title="Puterea la axul mașinii electrice")
    ax[1].legend(fontsize=7.5, loc="upper right", bbox_to_anchor=(1.0, 0.92))
    for a_ in ax:
        a_.grid(alpha=0.3)
    fig.suptitle("P2 – vehicul mediu (date din documentare)")
    fig.tight_layout()
    fig.savefig(dir_fig / "p2_forte_putere.png", dpi=130)
    plt.close(fig)

    fig, ax = plt.subplots(1, 2, figsize=(11, 4.2), sharey=True)
    tt = np.linspace(0, R3["t1"], 400)
    Pc = forte(R3["a"] * tt, R3["a"], V)["Ft"] * R3["a"] * tt
    for q, d in enumerate(R3["disc"]):
        ax[q].step(d["t"][1:], d["P"][1:] / 1e3, where="pre", lw=1, label="$P_{ti}$ constant pe interval")
        ax[q].plot(tt, Pc / 1e3, "--", lw=1, label="P(t) continuu")
        ax[q].axhline(R3["Pmed"] / 1e3, ls=":", color="k", label=f"$P_{{med}}$ = P$_1$/2 = {R3['Pmed']/1e3:.1f} kW")
        ax[q].axhline(d["P01_med"] / 1e3, ls="-.", color="C2", lw=1,
                      label=f"$P_{{01-med}}$ = {d['P01_med']/1e3:.2f} kW")
        ax[q].set(xlabel="t [s]", title=f"n = {d['n']} intervale (Δt = {d['dt']*1e3:.3f} ms)")
        ins = ax[q].inset_axes([0.56, 0.06, 0.4, 0.3])
        z = R3["t1"] * 0.06
        m = d["t"] <= z + d["dt"]
        ins.step(d["t"][m][1:], d["P"][m][1:] / 1e3, where="pre", lw=1)
        tz = np.linspace(0, z, 100)
        ins.plot(tz, forte(R3["a"] * tz, R3["a"], V)["Ft"] * R3["a"] * tz / 1e3, "--", lw=1)
        ins.set_xlim(0, z)
        ins.set_ylim(0, R3["P1"] * 0.07 / 1e3)
        ins.text(0.03, 0.85, f"zoom 0–{z:.2f} s", fontsize=7, transform=ins.transAxes)
        ins.tick_params(labelsize=6)
        ins.grid(alpha=0.3)
        ax[q].grid(alpha=0.3)
        ax[q].legend(fontsize=8, loc="upper left")
    ax[0].set_ylabel("P [kW]")
    fig.suptitle(f"P3 – puterea pe intervalul [0, t1], t1 = {R3['t1']:.3f} s (vehicul mediu)")
    fig.tight_layout()
    fig.savefig(dir_fig / "p3_putere_discretizare.png", dpi=130)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(8, 3.6))
    t_h = np.array([0, R3["t1"], R3["t2"], R3["tf"]]) / 3600
    ax.plot(t_h, np.array([0, R3["V1"], R3["V1"], 0]) * 3.6, lw=2)
    ax.fill_between(t_h, np.array([0, R3["V1"], R3["V1"], 0]) * 3.6, alpha=0.12)
    ax.set(xlabel="t [h]", ylabel="V [km/h]", ylim=(0, 60),
           title=f"P3 – ciclul de testare: {R3['autonomie']/1e3:.0f} km la {R3['V1']*3.6:.0f} km/h "
                 f"(t1 = {R3['t1']:.2f} s, t2 – t1 = {R3['t12']/3600:.2f} h)")
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(dir_fig / "p3_ciclu.png", dpi=130)
    plt.close(fig)


# ---------------------------------------------------------------- tabelele din README.md
def ro(x, d=2):
    """Număr în format românesc: virgulă zecimală, spațiu pentru mii."""
    s = f"{x:,.{d}f}"
    return s.replace(",", " ").replace(".", ",")


def tabele_readme(tab, rez):
    m, g = rez["medie"], rez["gt63"]
    T = {}

    rows = ["| Vehicul | P [kW] | v_max [km/h] | a 0–100 [m/s²] | M [kg] | Cuplu [Nm] | Baterie [kWh] | "
            "Autonomie [km] | Consum [kWh/100 km] | Cx | S [m²] |", "|---|---|---|---|---|---|---|---|---|---|---|"]
    nan = lambda x, d: "–" if math.isnan(x) else ro(x, d)  # noqa: E731
    for t in tab:
        rows.append(f"| {t['vehicul']} | {ro(t['P_max_kW'], 0)} | {ro(t['v_max_kmh'], 0)} | {ro(t['a_ms2'], 2)} | "
                    f"{ro(t['masa_kg'], 0)} | {ro(t['cuplu_Nm'], 0)} | {ro(t['baterie_kWh'], 1)} | "
                    f"{nan(t['aut_km'], 1)} {t['ciclu'] if not math.isnan(t['aut_km']) else ''} | "
                    f"{nan(t['cons_kWh100'], 2)} | {nan(t['Cx'], 3)} | {nan(t['A_m2'], 2)} |")
    V = m["date"]
    rows.append(f"| **Medie** | **{ro(V['P_doc']/1e3, 1)}** | **{ro(V['vmax']*3.6, 1)}** | **{ro(V['a_doc'], 2)}** | "
                f"**{ro(V['M'], 1)}** | **{ro(V['cuplu_doc'], 1)}** | **{ro(V['W_bat_doc']/3.6e6, 1)}** | "
                f"**{ro(V['autonomie']/1e3, 1)}** (WLTP) | **{ro(V['consum_doc']*100/3600, 2)}** (WLTP) | **{ro(V['Cx'], 4)}** | "
                f"**{ro(V['S'], 3)}** |")
    T["vehicule"] = "\n".join(rows)

    G = g["date"]
    T["date_si"] = "\n".join([
        "| Mărime | Vehicul mediu | în S.I. | GT 63 (S.I.) |", "|---|---|---|---|",
        f"| Putere maximă | {ro(V['P_doc']/1e3, 1)} kW | {ro(V['P_doc'], 0)} W | {ro(G['P_doc'], 0)} W |",
        f"| Viteză maximă | {ro(V['vmax']*3.6, 1)} km/h | {ro(V['vmax'], 3)} m/s | {ro(G['vmax'], 3)} m/s |",
        f"| Accelerație maximă (medie 0–100 km/h) | {ro(100/3.6/V['a_doc'], 2)} s | {ro(V['a_doc'], 3)} m/s² | "
        f"{ro(G['a_doc'], 3)} m/s² |",
        f"| Autonomie | {ro(V['autonomie']/1e3, 1)} km | {ro(V['autonomie'], 0)} m | {ro(G['autonomie'], 0)} m |",
        f"| Masă | {ro(V['M'], 1)} kg | {ro(V['M'], 1)} kg | {ro(G['M'], 0)} kg |",
        f"| Capacitate baterie | {ro(V['W_bat_doc']/3.6e6, 2)} kWh | {ro(V['W_bat_doc'], 0)} Ws | {ro(G['W_bat_doc'], 0)} Ws |",
        f"| Cuplu | {ro(V['cuplu_doc'], 1)} Nm | {ro(V['cuplu_doc'], 1)} Nm | {ro(G['cuplu_doc'], 0)} Nm |",
        f"| Consum mediu | {ro(V['consum_doc']*100/3600, 2)} kWh/100 km | {ro(V['consum_doc'], 1)} Ws/m | "
        f"{ro(G['consum_doc'], 1)} Ws/m |",
        f"| Cx | {ro(V['Cx'], 4)} | {ro(V['Cx'], 4)} | {ro(G['Cx'], 2)} |",
        f"| Suprafață frontală S | {ro(V['S'], 3)} m² | {ro(V['S'], 3)} m² | {ro(G['S'], 2)} m² |",
    ])

    def p2rows(R):
        return [
            ("2", "a_doc = Va / ta", "m/s²", R["a_doc"], 3), ("3", "Fra(Va)", "N", R["Fra_Va"], 1),
            ("3", "Ff", "N", R["Ff"], 1), ("3", "Ft = Fra + Ff + Gt + M·a_doc", "N", R["Ft_doc"], 1),
            ("4", "Fa = µa·M·g", "N", R["Fa"], 1), ("4", "a realizabil (Ft = Fa)", "m/s²", R["a"], 3),
            ("4", "ta realizabil (0–100 km/h)", "s", R["ta"], 2), ("5", "Mr = r·Ft", "Nm", R["Mr"], 1),
            ("5", "Ωr = Va / r", "rad/s", R["Omega_r_Va"], 2), ("5", "Pr = Mr·Ωr", "kW", R["Pr"] / 1e3, 2),
            ("5", "Pax = Pr / 0,99", "kW", R["Pax"] / 1e3, 2), ("6", "i_rd = Ωr / Ωax (n_max = 15 000 rot/min)", "-",
                                                              R["i_rd"], 4),
            ("6", "1 / i_rd", "-", R["k_rd"], 2), ("6", "n_ax la Va (turația de bază)", "rot/min", R["n_ax_Va"], 0),
            ("6", "Max = Pax / Ωax", "Nm", R["Max"], 1), ("7", "Fra(v_max)", "N", R["Fra_vmax"], 1),
            ("7", "Ft(v_max) = Fra + Ff + Gt", "N", R["Ft_vmax"], 1), ("8", "Pax la v_max", "kW", R["Pax_nom"] / 1e3, 2),
            ("8", "Max la v_max", "Nm", R["Max_vmax"], 1),
        ]
    a, b = p2rows(m["p2"]), p2rows(g["p2"])
    rows = ["| Pas | Mărime | Unitate | Vehicul mediu | GT 63 |", "|---|---|---|---|---|"]
    for (p, et, um, v1, d), (_, _, _, v2, _) in zip(a, b):
        rows.append(f"| {p} | {et} | {um} | {ro(v1, d)} | {ro(v2, d)} |")
    rows.append(f"| 9 | **P_max (puterea maximă)** | kW | **{ro(m['p2']['P_max']/1e3, 1)}** | "
                f"**{ro(g['p2']['P_max']/1e3, 1)}** |")
    rows.append(f"| 9 | **P_nom (puterea nominală)** | kW | **{ro(m['p2']['P_nom']/1e3, 1)}** | "
                f"**{ro(g['p2']['P_nom']/1e3, 1)}** |")
    rows.append(f"| – | Pax cu a_doc, fără limita de aderență | kW | {ro(m['p2']['Pax_fara_aderenta']/1e3, 1)} | "
                f"{ro(g['p2']['Pax_fara_aderenta']/1e3, 1)} |")
    rows.append(f"| – | Puterea declarată (documentare) | kW | {ro(m['p2']['P_doc']/1e3, 1)} | "
                f"{ro(g['p2']['P_doc']/1e3, 1)} |")
    T["p2"] = "\n".join(rows)

    rows = ["| µa | ρ [kg/m³] | a [m/s²] | ta 0–100 [s] | P_max [kW] | P_nom [kW] |", "|---|---|---|---|---|---|"]
    for mu in (0.8, 1.0, 1.2):
        for rho in (1.293, 1.225):
            c = dict(C, mu_a=mu, rho=rho)
            R = calcul_p2(m["date"], c)
            rows.append(f"| {ro(mu, 1)} | {ro(rho, 3)} | {ro(R['a'], 2)} | {ro(R['ta'], 2)} | {ro(R['P_max']/1e3, 1)} | "
                        f"{ro(R['P_nom']/1e3, 1)} |")
    T["sensibilitate"] = "\n".join(rows)

    def p3rows(R):
        return [
            ("1", "V1", "m/s", R["V1"], 4), ("2–4", "a (din P2; Ft1 ≤ Fa)", "m/s²", R["a"], 3),
            ("3", "Ft1 = Fra + Ff + Gt + M·a", "N", R["Ft1"], 1), ("3", "P1 = Ft1·V1", "kW", R["P1"] / 1e3, 3),
            ("5", "Ft1' = Fra + Ff + Gt", "N", R["Ft1p"], 2), ("5", "P1' = Ft1'·V1", "kW", R["P1p"] / 1e3, 4),
            ("6", "t1 = V1 / a", "s", R["t1"], 4), ("7", "Pmed = P1 / 2", "kW", R["Pmed"] / 1e3, 3),
            ("7", "P01-med (n = 1000)", "kW", R["P01_med"] / 1e3, 3), ("8", "Wmed = Pmed·t1", "kJ", R["Wmed"] / 1e3, 3),
            ("8", "W01-med = P01-med·t1", "kJ", R["W01_med"] / 1e3, 3), ("8", "W01 = Σ Pti·Δti (n = 1000)", "kJ",
                                                                         R["W01"] / 1e3, 3),
            ("8", "W01 exact (integrală)", "kJ", R["W01_exact"] / 1e3, 3), ("9", "d1 = df = V1·t1 / 2", "m", R["d1"], 3),
            ("10", "autonomie = d1 + d2 + df", "km", R["autonomie"] / 1e3, 1), ("10", "d2", "km", R["d2"] / 1e3, 3),
            ("10", "t2 − t1 = d2 / V1", "h", R["t12"] / 3600, 3), ("11", "W12 = P1'·(t2 − t1)", "kWh", R["W12"] / 3.6e6, 3),
            ("12", "Wmec = W01 + W12 − W2f", "kWh", R["Wmec"] / 3.6e6, 3),
            ("13", "Wstocată = W01/η + W12/η − η·W2f", "kWh", R["Wstocata"] / 3.6e6, 3),
            ("14", "Wbat = Wstocată / (1 − 0,30)", "kWh", R["Wbat"] / 3.6e6, 2),
            ("–", "consum echivalent (Wstocată / autonomie)", "kWh/100 km", R["consum_stoc_kWh100"], 2),
            ("–", "consum mediu din documentare", "kWh/100 km", R["consum_doc_kWh100"], 2),
            ("–", "baterie din documentare", "kWh", R["W_bat_doc_kWh"], 1),
        ]
    a, b = p3rows(m["p3"]), p3rows(g["p3"])
    rows = ["| Pas | Mărime | Unitate | Vehicul mediu | GT 63 |", "|---|---|---|---|---|"]
    for (p, et, um, v1, d), (_, _, _, v2, _) in zip(a, b):
        rows.append(f"| {p} | {et} | {um} | {ro(v1, d)} | {ro(v2, d)} |")
    T["p3"] = "\n".join(rows)

    rows = ["| n | Δt [ms] | P01-med [kW] | W01 [kJ] | eroare față de integrala exactă | timp de calcul [µs] |",
            "|---|---|---|---|---|---|"]
    for d in m["p3"]["disc"]:
        rows.append(f"| {d['n']} | {ro(d['dt']*1e3, 3)} | {ro(d['P01_med']/1e3, 3)} | {ro(d['W01']/1e3, 3)} | "
                    f"+{ro(d['eroare_W01_pct'], 3)} % | {ro(d['timp_s']*1e6, 1)} |")
    R = m["p3"]
    rows.append(f"| exact | – | {ro(R['P01_exact']/1e3, 3)} | {ro(R['W01_exact']/1e3, 3)} | 0 | – |")
    rows.append(f"| Pmed = P1/2 | – | {ro(R['Pmed']/1e3, 3)} | {ro(R['Wmed']/1e3, 3)} | "
                f"+{ro((R['Wmed']-R['W01_exact'])/R['W01_exact']*100, 3)} % | – |")
    T["discretizare"] = "\n".join(rows)

    Bm, Bg = m["baterie"], g["baterie"]
    rows = ["| Mărime | Vehicul mediu | GT 63 |", "|---|---|---|",
            f"| Energia necesară Wbat | {ro(m['p3']['Wbat_kWh'], 2)} kWh | {ro(g['p3']['Wbat_kWh'], 2)} kWh |",
            f"| W_celulă = Cap·U | {ro(Bm['W_celula'], 0)} Ws ({ro(Bm['W_celula']/3600, 1)} Wh) | idem |",
            f"| N_min = Wbat / W_celulă | {ro(Bm['N_min'], 0)} | {ro(Bg['N_min'], 0)} |",
            f"| Celule în serie Ns (U ≈ 800 V) | {Bm['Ns']} | {Bg['Ns']} |",
            f"| Tensiune nominală (min – max) | {ro(Bm['U_nom'], 1)} V ({ro(Bm['U_min'], 0)} – {ro(Bm['U_max'], 0)} V) | "
            f"{ro(Bg['U_nom'], 1)} V |",
            f"| Ramuri în paralel: din energie / din curent | {Bm['Np_energie']} / {Bm['Np_curent']} | "
            f"{Bg['Np_energie']} / {Bg['Np_curent']} |",
            f"| **Configurație** | **{Bm['Ns']}s{Bm['Np']}p = {ro(Bm['N'], 0)} celule** | "
            f"**{Bg['Ns']}s{Bg['Np']}p = {ro(Bg['N'], 0)} celule** |",
            f"| Energie instalată / capacitate | {ro(Bm['W_real_kWh'], 2)} kWh / {ro(Bm['Cap_Ah'], 0)} Ah | "
            f"{ro(Bg['W_real_kWh'], 2)} kWh / {ro(Bg['Cap_Ah'], 0)} Ah |",
            f"| Curent maxim baterie (P_max / η / U) | {ro(Bm['I_bat_max'], 0)} A | {ro(Bg['I_bat_max'], 0)} A |",
            f"| Curent pe celulă la P_max (max. 60 A) | {ro(Bm['I_celula'], 1)} A | {ro(Bg['I_celula'], 1)} A |",
            f"| Masa celulelor | {ro(Bm['m_celule'], 1)} kg ({ro(Bm['procent_celule'], 1)} % din M) | "
            f"{ro(Bg['m_celule'], 1)} kg ({ro(Bg['procent_celule'], 1)} %) |",
            f"| Masa estimată a pachetului (celule / 0,70) | {ro(Bm['m_pachet'], 1)} kg ({ro(Bm['procent_pachet'], 1)} %) | "
            f"{ro(Bg['m_pachet'], 1)} kg ({ro(Bg['procent_pachet'], 1)} %) |",
            f"| Limita 30 % din M | {ro(Bm['m_limita'], 1)} kg – {'respectată' if Bm['masa_ok_pachet'] else 'DEPĂȘITĂ'} | "
            f"{ro(Bg['m_limita'], 1)} kg – {'respectată' if Bg['masa_ok_pachet'] else 'DEPĂȘITĂ'} |"]
    T["baterie"] = "\n".join(rows)

    P2m, P2g = m["p2"], g["p2"]
    rows = ["| Subsistem | Mărime | Vehicul mediu (temă) | GT 63 (comparație) |", "|---|---|---|---|",
            f"| Mașina electrică | Puterea maximă / nominală | {ro(P2m['P_max']/1e3, 0)} kW / {ro(P2m['P_nom']/1e3, 0)} kW | "
            f"{ro(P2g['P_max']/1e3, 0)} kW / {ro(P2g['P_nom']/1e3, 0)} kW |",
            f"| | Cuplul maxim la ax | {ro(P2m['Max'], 0)} Nm | {ro(P2g['Max'], 0)} Nm |",
            f"| | Turația de bază / maximă | {ro(P2m['n_ax_Va'], 0)} / {ro(C['n_max'], 0)} rot/min | "
            f"{ro(P2g['n_ax_Va'], 0)} / {ro(C['n_max'], 0)} rot/min |",
            f"| Reductor | i_rd = Ωr/Ωax (1 : k) | {ro(P2m['i_rd'], 4)} (1 : {ro(P2m['k_rd'], 2)}) | "
            f"{ro(P2g['i_rd'], 4)} (1 : {ro(P2g['k_rd'], 2)}) |",
            f"| Vehicul | a realizabil / 0–100 km/h | {ro(P2m['a'], 2)} m/s² / {ro(P2m['ta'], 2)} s | "
            f"{ro(P2g['a'], 2)} m/s² / {ro(P2g['ta'], 2)} s |",
            f"| Baterie | Energie necesară / instalată | {ro(m['p3']['Wbat_kWh'], 1)} / {ro(Bm['W_real_kWh'], 1)} kWh | "
            f"{ro(g['p3']['Wbat_kWh'], 1)} / {ro(Bg['W_real_kWh'], 1)} kWh |",
            f"| | Celule Molicel P50B | {Bm['Ns']}s{Bm['Np']}p = {ro(Bm['N'], 0)} | {Bg['Ns']}s{Bg['Np']}p = {ro(Bg['N'], 0)} |",
            f"| | Tensiune nominală (min – max) | {ro(Bm['U_nom'], 0)} V ({ro(Bm['U_min'], 0)} – {ro(Bm['U_max'], 0)} V) | "
            f"idem |",
            f"| Convertor / invertor | Curent maxim din baterie | {ro(Bm['I_bat_max'], 0)} A | {ro(Bg['I_bat_max'], 0)} A |"]
    T["sinteza"] = "\n".join(rows)
    return T


def actualizeaza_readme(cale, T):
    if not cale.exists():
        return
    txt = cale.read_text(encoding="utf-8")
    for k, bloc in T.items():
        a, b = f"<!-- AUTO:{k} -->", f"<!-- /AUTO:{k} -->"
        if a in txt and b in txt:
            i, j = txt.index(a) + len(a), txt.index(b)
            txt = txt[:i] + "\n" + bloc + "\n" + txt[j:]
    cale.write_text(txt, encoding="utf-8")


# ---------------------------------------------------------------- JSON
def curata(o):
    if isinstance(o, dict):
        return {k: curata(v) for k, v in o.items() if k not in ("t", "P")}
    if isinstance(o, list):
        return [curata(v) for v in o]
    if isinstance(o, (np.floating, np.integer)):
        return o.item()
    if isinstance(o, np.ndarray):
        return o.tolist()
    return o


def main():
    global CELULA
    CELULA = json.loads((RADACINA / "date" / "celula_aleasa.json").read_text(encoding="utf-8"))
    tab, rez = ruleaza(RADACINA / "date" / "date_documentare.csv", CELULA)
    (RADACINA / "rezultate").mkdir(exist_ok=True)
    (RADACINA / "rezultate" / "rezultate_python.json").write_text(
        json.dumps(curata(dict(constante=C, celula=CELULA, **rez)), indent=1, ensure_ascii=False), encoding="utf-8")
    compara_cu_matlab(rez, RADACINA / "rezultate" / "rezultate_matlab.json")
    figuri(rez, RADACINA / "figuri")
    import excel_p2_p3  # noqa: E402  (același folder)
    out = RADACINA / "CCA_Etapa2_Calcule.xlsx"
    excel_p2_p3.construieste(tab, rez, C, CELULA, out, SURSE)
    print("salvat", out)
    actualizeaza_readme(RADACINA / "README.md", tabele_readme(tab, rez))
    for k in ("medie", "gt63"):
        R2, R3, B = rez[k]["p2"], rez[k]["p3"], rez[k]["baterie"]
        print(f"{k:6s} a={R2['a']:.3f} ta={R2['ta']:.3f} Pmax={R2['P_max']/1e3:.2f} kW Pnom={R2['P_nom']/1e3:.2f} kW "
              f"Max={R2['Max']:.1f} Nm i_rd={R2['i_rd']:.5f} | t1={R3['t1']:.4f} W01={R3['W01']:.1f} "
              f"Wbat={R3['Wbat_kWh']:.3f} kWh | {B['Ns']}s{B['Np']}p N={B['N']} m={B['m_celule']:.1f} kg")
    return 0


if __name__ == "__main__":
    sys.exit(main())
