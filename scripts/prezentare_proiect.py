"""Generează PREZENTARE_PROIECT.md – prezentarea întregului proiect, cu toate calculele.

Rulare (din rădăcina depozitului):   python3 scripts/prezentare_proiect.py

Toate valorile sunt recalculate cu implementările Python ale etapelor (verificate față de Matlab/Octave),
deci prezentarea rămâne la zi dacă se schimbă o ipoteză.
"""
import json
import math
import sys
from pathlib import Path

RAD = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAD / "etapa2-calcule" / "python"))
sys.path.insert(0, str(RAD / "etapa3-tema-motor" / "python"))
sys.path.insert(0, str(RAD / "etapa4-convertoare" / "python"))
import calcule_p2_p3 as e2  # noqa: E402
import model_p4 as mp  # noqa: E402
import model_p5p6 as m5  # noqa: E402

ro = e2.ro


def da(x):
    return "DA" if x else "NU"


def main():
    cel = json.loads((RAD / "etapa2-calcule" / "date" / "celula_aleasa.json").read_text(encoding="utf-8"))
    e2.CELULA = cel
    tab, rez = e2.ruleaza(RAD / "etapa2-calcule" / "date" / "date_documentare.csv", cel)
    C = e2.C
    V, R2, R3, B = rez["medie"]["date"], rez["medie"]["p2"], rez["medie"]["p3"], rez["medie"]["baterie"]
    G2 = rez["gt63"]["p2"]
    R = mp.calculeaza_tot(cu_simulari=True)
    M, T, S, P4, H4, Z, CA, HC = R["M"], R["T"], R["S"], R["puncte"], R["harta"], R["Z"], R["C"], R["H"]
    ip = S["ip"]
    Q = m5.calculeaza_tot(cu_simulari=True)
    D, Hc, Ci, Im, Ic, Dc = Q["D"], Q["H"], Q["C"], Q["Im"], Q["Ic"], Q["Dc"]
    cv = Q["S"]["cv"]
    g, rho = C["g"], C["rho"]
    L = []
    w = L.append

    w("# Proiect CCA – Sistem de propulsie electrică: prezentarea întregului proiect")
    w("")
    w("**Disciplina:** Concepția Asistată de Calculator a Acționărilor Electrice – Proiect (UPB)  ")
    w("**Vehicul de referință:** Mercedes-AMG GT 63 4MATIC+ 4-Door Coupé (AMG.EA, motoare cu flux axial)  ")
    w(f"**Tema:** calculată pentru **vehiculul mediu** al celor {len(tab)} vehicule electrice de serie din documentare "
      "(„se preiau datele medii rezultate din faza de documentare”, suport P4).")
    w("")
    w("Acest document rezumă toate etapele, cu formulele și valorile numerice. Valorile sunt generate automat "
      "(`python3 scripts/prezentare_proiect.py`) din aceleași funcții care au fost verificate față de programele "
      "Matlab (GNU Octave) – diferențe sub 10⁻⁶. Detaliile sunt în README-ul fiecărei etape.")
    w("")
    w("| Etapă | Suport de curs | Folder |")
    w("|---|---|---|")
    w("| 1. Documentare | P1 | [`etapa1-documentare`](etapa1-documentare) |")
    w("| Calcul 1. Dinamica vehiculului de referință | C1 | [`etapa-calcul-1`](etapa-calcul-1) |")
    w("| 2. Puterea mașinii, energia, bateria | P2, P3 | [`etapa2-calcule`](etapa2-calcule) |")
    w("| 3. Tema de proiect, modelul MCC, pierderi, hărți de randament, simulări | P4, C3 | [`etapa3-tema-motor`](etapa3-tema-motor) |")
    w("| 4. Convertoare DC-DC, încărcarea bateriei | P5-P6 | [`etapa4-convertoare`](etapa4-convertoare) |")
    w("| Modelele Simulink (R2023b) | C3 ex. 2, P4–P6 | [`simulink`](simulink) |")
    w("")

    # ------------------------------------------------------------------ etapa 1
    w("## 1. Documentare – datele vehiculelor")
    w("")
    w("| Vehicul | P [kW] | v_max [km/h] | 0–100 [s] | M [kg] | Cuplu [Nm] | Baterie [kWh] | Cx | S [m²] |")
    w("|---|---|---|---|---|---|---|---|---|")
    for t in tab:
        cx = "–" if math.isnan(t["Cx"]) else ro(t["Cx"], 3)
        sa = "–" if math.isnan(t["A_m2"]) else ro(t["A_m2"], 2)
        w(f"| {t['vehicul']} | {ro(t['P_max_kW'], 0)} | {ro(t['v_max_kmh'], 0)} | {ro(100/3.6/t['a_ms2'], 2)} | "
          f"{ro(t['masa_kg'], 0)} | {ro(t['cuplu_Nm'], 0)} | {ro(t['baterie_kWh'], 1)} | {cx} | {sa} |")
    w(f"| **Vehicul mediu** | **{ro(V['P_doc']/1e3, 1)}** | **{ro(V['vmax']*3.6, 1)}** | **{ro(100/3.6/V['a_doc'], 2)}** | "
      f"**{ro(V['M'], 1)}** | **{ro(V['cuplu_doc'], 1)}** | **{ro(V['W_bat_doc']/3.6e6, 1)}** | **{ro(V['Cx'], 4)}** | "
      f"**{ro(V['S'], 3)}** |")
    w("")
    w(f"Autonomia medie (WLTP): {ro(V['autonomie']/1e3, 1)} km; consumul mediu {ro(V['consum_doc']*100/3600, 2)} kWh/100 km. "
      "Sursele fiecărei valori sunt în registrul etapei 1 (foaia „Surse”) și în etapa 2.")
    w("")

    w("### Calcul 1 – dinamica longitudinală a vehiculului de referință (curs C1)")
    w("")
    w("Analiza separată din [`etapa-calcul-1`](etapa-calcul-1) (relațiile (1)–(50) din C1, pentru GT 63): la 300 km/h sunt "
      "necesari 2 582 N la roți și 226,5 kW la motoare (viteza maximă este limitată electronic, nu de putere); "
      "accelerarea 0–100 km/h în 2,4 s cere un coeficient de aderență µ ≈ 1,19, deci este limitată de aderență – "
      "aceeași concluzie ca în P2 pentru vehiculul mediu.")
    w("")
    # ------------------------------------------------------------------ P2
    F3 = e2.forte(R2["Va"], R2["a_doc"], V)
    w("## 2. P2 – Puterea și cuplul mașinii electrice")
    w("")
    w("Ipoteze (curs): g = 9,81 m/s², ρ = 1,293 kg/m³, µf = 0,013, µa = 0,8, α = 0, Vv = 0, r = 0,35 m, "
      "pierderi în reductor P_p = P_ax/100.")
    w("")
    w("| Pas | Relația | Calcul | Rezultat |")
    w("|---|---|---|---|")
    w(f"| 2 | a_doc = Va/ta | {ro(R2['Va'], 3)} / {ro(R2['ta_doc'], 2)} | {ro(R2['a_doc'], 3)} m/s² |")
    w(f"| 3 | Fra = ½·ρ·S·Cx·Va² | ½·{ro(rho, 3)}·{ro(V['S'], 3)}·{ro(V['Cx'], 4)}·{ro(R2['Va'], 3)}² | {ro(R2['Fra_Va'], 1)} N |")
    w(f"| 3 | Ff = µf·M·g·cos α | {ro(C['mu_f'], 3)}·{ro(V['M'], 1)}·{ro(g, 2)} | {ro(R2['Ff'], 1)} N |")
    w(f"| 3 | Ft = Fra + Ff + Gt + M·a_doc | {ro(R2['Fra_Va'], 1)} + {ro(R2['Ff'], 1)} + 0 + {ro(V['M']*R2['a_doc'], 1)} | {ro(R2['Ft_doc'], 1)} N |")
    w(f"| 4 | Fa = µa·M·g | {ro(C['mu_a'], 1)}·{ro(V['M'], 1)}·{ro(g, 2)} | {ro(R2['Fa'], 1)} N |")
    w(f"| 4 | Ft ≤ Fa ? | {ro(R2['Ft_doc'], 0)} ≤ {ro(R2['Fa'], 0)} | **{da(R2['aderenta_ok'])}** → Ft = Fa, a = {ro(R2['a'], 3)} m/s², ta = {ro(R2['ta'], 2)} s |")
    w(f"| 5 | Mr = r·Ft | 0,35·{ro(R2['Ft'], 1)} | {ro(R2['Mr'], 1)} Nm |")
    w(f"| 5 | Pr = Mr·Ωr, Ωr = Va/r | {ro(R2['Mr'], 1)}·{ro(R2['Omega_r_Va'], 2)} | {ro(R2['Pr']/1e3, 2)} kW |")
    w(f"| 5 | Pax = Pr/0,99 | | **{ro(R2['Pax']/1e3, 2)} kW = P_max** |")
    w(f"| 7 | Ft(v_max) = Fra + Ff | v_max = {ro(R2['vmax'], 2)} m/s | {ro(R2['Ft_vmax'], 1)} N |")
    w(f"| 8 | P(v_max) = Ft·v_max/0,99 | | **{ro(R2['Pax_nom']/1e3, 2)} kW = P_n** |")
    w("")
    w(f"Puterea cerută de accelerare este limitată de aderență: cu a_doc ar fi fost necesari "
      f"{ro(R2['Pax_fara_aderenta']/1e3, 0)} kW (puterea medie declarată {ro(V['P_doc']/1e3, 0)} kW). "
      f"Pentru GT 63: P_max = {ro(G2['P_max']/1e3, 1)} kW, P_n = {ro(G2['P_nom']/1e3, 1)} kW.")
    w("")

    # ------------------------------------------------------------------ P3
    w("## 3. P3 – Necesarul de energie și bateria")
    w("")
    w(f"Ciclul: accelerare 0 → V1 = 50 km/h cu a = {ro(R3['a'], 3)} m/s², rulare cu V1, decelerare simetrică; "
      f"lungimea ciclului = autonomia {ro(R3['autonomie']/1e3, 1)} km; η = 0,8; rezervă 30 %.")
    w("")
    w("| Mărime | Relația | Valoare |")
    w("|---|---|---|")
    w(f"| t1 | V1/a | {ro(R3['t1'], 4)} s |")
    w(f"| P1 | Ft(V1, a)·V1 | {ro(R3['P1']/1e3, 2)} kW |")
    w(f"| P_med | (P0 + P1)/2 | {ro(R3['Pmed']/1e3, 2)} kW |")
    for d in R3["disc"]:
        w(f"| W01 (n = {d['n']}) | Σ P_ti·Δt | {ro(d['W01']/1e3, 3)} kJ (eroare {ro(d['eroare_W01_pct'], 3)} % față de integrala exactă) |")
    w(f"| d1 = df | V1·t1/2 | {ro(R3['d1'], 2)} m |")
    w(f"| d2, t12 | autonomie − 2·d1; d2/V1 | {ro(R3['d2']/1e3, 2)} km; {ro(R3['t12']/3600, 2)} h |")
    w(f"| P1' (V1 constant) | Ft(V1, 0)·V1 | {ro(R3['P1p']/1e3, 3)} kW |")
    w(f"| W12 | P1'·t12 | {ro(R3['W12']/3.6e6, 2)} kWh |")
    w(f"| W_stocată | W01/η + W12/η − η·W2f | {ro(R3['Wstocata_kWh'], 2)} kWh |")
    w(f"| **W_bat** | W_stocată/(1 − 0,3) | **{ro(R3['Wbat_kWh'], 2)} kWh** |")
    w("")
    w(f"**Bateria** (celula {cel['nume']}: {ro(cel['U_nom'], 1)} V, {ro(cel['Cap_Ah'], 1)} Ah, {cel['I_max_cont']} A continuu, "
      f"{ro(cel['R_dc_mOhm'], 1)} mΩ): Ns = ⌊800/4,2⌋ = {B['Ns']} în serie, Np = max(energie {B['Np_energie']}, curent "
      f"{B['Np_curent']}) = {B['Np']} în paralel → **{B['Ns']}s{B['Np']}p**, {B['N']} celule, {ro(B['W_real_kWh'], 2)} kWh, "
      f"{ro(B['U_min'], 0)}–{ro(B['U_max'], 0)} V (nominal {ro(B['U_nom'], 0)} V), celule {ro(B['m_celule'], 0)} kg, pachet "
      f"≈ {ro(B['m_pachet'], 0)} kg ({ro(B['procent_pachet'], 1)} % din M ≤ 30 %: {da(B['masa_ok_pachet'])}).")
    w("")

    # ------------------------------------------------------------------ P4
    N = T["N"]
    w("## 4. P4 – Tema de proiect")
    w("")
    w(f"Mașina electrică: **{N} × {S['mot']['nume']}** ({S['mot']['tip']}), {S['mot']['dispunere']}; "
      "descrisă și simulată cu ecuațiile MCC din C3 (echivalentul de curent continuu al motorului comandat vectorial).")
    w("")
    w("| Mărime | Pe motor | Total | Obținută din |")
    w("|---|---|---|---|")
    w(f"| P_n | {ro(M['P_n']/1e3, 0)} kW | {ro(N*M['P_n']/1e3, 0)} kW | catalog; necesar {ro(T['P_nec_n']/1e3, 1)} kW (P2) |")
    w(f"| U_n | {ro(M['U_n'], 0)} V | – | circuitul intermediar (DC-DC) |")
    w(f"| I_n | {ro(M['I_n'], 1)} A | {ro(N*M['I_n'], 1)} A | P_n/(η_n·U_n), η_n = {ro(M['eta_n'], 2)} |")
    w(f"| n | {ro(M['n_n'], 0)} rot/min (n_max {ro(M['n_max'], 0)}) | – | n_n = P_n/M_n |")
    w(f"| M_n | {ro(M['M_n'], 0)} Nm | {ro(N*M['M_n'], 0)} Nm | catalog |")
    w(f"| P_max | {ro(M['P_max']/1e3, 0)} kW | {ro(N*M['P_max']/1e3, 0)} kW | catalog; necesar {ro(T['P_nec_max']/1e3, 1)} kW (P2) |")
    w(f"| I_max | {ro(M['I_max'], 1)} A | {ro(N*M['I_max'], 1)} A | (M_max + T_f0 + F_v·Ω_b)/k |")
    w(f"| M_max | {ro(M['M_max'], 0)} Nm | {ro(N*M['M_max'], 0)} Nm | catalog; necesar față {ro(T['M_nec_fata'], 0)} Nm, spate {ro(T['M_nec_spate'], 0)} Nm/motor |")
    w(f"| Reductor i_rd | {ro(T['i_rd'], 4)} (1:{ro(T['k_rd'], 2)}) | – | ales: n(v_max) = {ro(T['n_m_vmax'], 0)} rot/min ≤ n_max |")
    w(f"| Baterie W_bat | {ro(T['W_bat_nec']/3.6e6, 2)} kWh necesar | {ro(T['W_bat_inst']/3.6e6, 2)} kWh instalat | P3 |")
    w("")
    w(f"Cerințele vehiculului: P_rn = {ro(T['P_rn']/1e3, 1)} kW, n_rn = {ro(T['n_rn'], 0)} rot/min, M_rn = {ro(T['M_rn'], 1)} Nm; "
      f"P_rmax = {ro(T['P_rmax']/1e3, 1)} kW, n_rmax = {ro(T['n_rmax'], 0)} rot/min, M_rmax = {ro(T['M_rmax'], 1)} Nm.")
    w("")
    w("**Confirmări:** "
      f"MCC – N·P_max ≥ P_max ({da(T['ok_P_max'])}), N·P_n ≥ P_n ({da(T['ok_P_n'])}), cuplu pe punți ({da(T['ok_M_fata'] and T['ok_M_spate'])}), "
      f"tensiune ({da(T['ok_U'])}); reductor – turație ({da(T['ok_n_max'])}), cuplu la roți {ro(T['M_roti_disp'], 0)} ≥ {ro(T['M_rmax'], 0)} Nm "
      f"({da(T['ok_M_roti'])}); baterie – energie ({da(T['ok_W_bat'])}), curent pe celulă {ro(B['I_celula'], 1)} A ≤ 60 A "
      f"({da(T['ok_I_cel'])}), putere ({da(T['ok_P_bat'])}).")
    w("")
    w("![Schema bloc](etapa3-tema-motor/figuri/p4_schema_bloc.png)")
    w("")

    # ------------------------------------------------------------------ C3
    w("## 5. C3 – Modelul MCC echivalent, pierderi, hărți de randament, încălzire")
    w("")
    w("U = E + R_a·I + ΔU_p, E = k·Φ·Ω, T_E = k·Φ·I; P_Fe = K_H·Ω + K_F·Ω², P_fv = T_m0·Ω + F_m·Ω²; "
      "T_ax = T_E − T_f0 − F_v·Ω (T_f0 = K_H + T_m0, F_v = K_F + F_m); η = P2/P1.")
    w("")
    w("| Parametru | Valoare | Relația |")
    w("|---|---|---|")
    w(f"| P1_n, ΣP_n, I_n | {ro(M['P1_n']/1e3, 2)} kW, {ro(M['SP_n']/1e3, 2)} kW, {ro(M['I_n'], 2)} A | P_n/η_n; P1_n − P_n; P1_n/U_n |")
    w(f"| R_a | {ro(M['R_a'], 5)} Ω | {ro(ip['cota_Cu'], 2)}·ΣP_n/I_n² |")
    w(f"| k | {ro(M['k'], 5)} Nm/A | (U_n − R_a·I_n)/Ω_n |")
    w(f"| K_H; K_F | {ro(M['K_H'], 4)} Nm; {ro(M['K_F']*1e3, 4)}·10⁻³ Nm·s | P_Fe(n_n) = {ro(ip['cota_Fe'], 2)}·ΣP_n, P_Fe(n_max) = {ro(ip['raport_Fe_max'], 1)}·P_Fe(n_n) |")
    w(f"| T_m0; F_m | {ro(M['T_m0'], 4)} Nm; {ro(M['F_m']*1e3, 4)}·10⁻³ Nm·s | P_fv(n_max) = {ro(ip['raport_mec_max'], 1)}·P_fv(n_n) |")
    w(f"| T_f0; F_v | {ro(M['T_f0'], 4)} Nm; {ro(M['F_v']*1e3, 4)}·10⁻³ Nm·s | verificare T_ax(n_n) = {ro(M['T_ax_n_verif'], 2)} Nm = M_n |")
    w(f"| n_b | {ro(M['n_b'], 0)} rot/min | U_n = k·Ω_b + R_a·I_max |")
    w(f"| L_a; J_rotor | {ro(M['L_a']*1e3, 3)} mH; {ro(M['J_rotor'], 2)} kg·m² | L_a = τ_a·R_a, τ_a = {ro(M['tau_a']*1e3, 0)} ms (YASA) |")
    w(f"| U_p (pornire) | {ro(M['U_p'], 2)} V | R_a·I_max (direct la U_n: I_p = {ro(M['I_p_Un'], 0)} A) |")
    w("")
    w("| Punct | n [rot/min] | T_ax [Nm] | P1 [kW] | P_a [kW] | P_Fe [kW] | P_fv [kW] | η [%] |")
    w("|---|---|---|---|---|---|---|---|")
    for p in P4:
        w(f"| {p['nume']} | {ro(p['n'], 0)} | {ro(p['T'], 1)} | {ro(p['P1']/1e3, 2)} | {ro(p['P_a']/1e3, 3)} | {ro(p['P_Fe']/1e3, 3)} | "
          f"{ro(p['P_fv']/1e3, 3)} | {ro(100*p['eta'], 2)} |")
    w("")
    w(f"Harta de randament: η_max = {ro(100*H4['eta_max'], 2)} % la {ro(H4['n_eta_max'], 0)} rot/min și {ro(H4['T_eta_max'], 0)} Nm; "
      f"η ≥ 95 % pe {ro(100*H4['cota_95'], 1)} % din domeniu.")
    w("")
    w("![Harta de randament](etapa3-tema-motor/figuri/c3_harta_randament.png)")
    w("")
    w(f"Încălzirea (Q = m·c·ΔT, m·c = {ro(HC['mc'], 0)} J/K, fără răcire): accelerare 0–100 km/h ΔT = {ro(HC['acc']['dT'], 2)} K; "
      f"{HC['varf']['durata']} s la M_max ΔT = {ro(HC['varf']['dT'], 1)} K; la v_max pierderi {ro(HC['vmax']['SP']/1e3, 2)} kW/motor "
      f"({ro(HC['vmax']['dT_min'], 1)} K/min fără răcire); la 50 km/h {ro(HC['p3']['SP'], 0)} W/motor – puterea de răcire în regim permanent.")
    w("")

    # ------------------------------------------------------------------ simulări
    A, Bz, Dz = Z["A"], Z["B"], Z["D"]
    w("## 6. Simulările mașinii și ale ansamblului")
    w("")
    w("| Simulare | Rezultat |")
    w("|---|---|")
    w(f"| A – pornire în gol la U_p, treaptă de sarcină M_n | I vârf {ro(A['I_varf'], 1)} A; Ω gol {ro(A['W_gol'], 3)} rad/s (teoretic {ro(A['W_gol_teoretic'], 3)}); "
      f"cu sarcină {ro(A['W_final'], 3)} rad/s, {ro(A['I_final'], 1)} A (teoretic {ro(A['W_sarcina_teoretic'], 3)} rad/s, {ro(A['I_sarcina_teoretic'], 1)} A) |")
    w(f"| B – accelerare cu regulator de curent și slăbire de câmp | 0–100 km/h {ro(Bz['t_100'], 2)} s (P2: {ro(R2['ta'], 2)} s), 0–200 km/h {ro(Bz['t_200'], 2)} s, "
      f"v_max în {ro(Bz['t_vmax'], 1)} s |")
    w(f"| D – rampă de tensiune cu sarcina vehiculului | I vârf {ro(Dz['I_varf'], 1)} A, n final {ro(Dz['W_final']*60/(2*math.pi), 0)} rot/min |")
    E = CA["E"]
    w(f"| C – ansamblu pe ciclul P3 scurtat (baterie → DC-DC → invertoare → motoare → roți) | eroare de viteză ≤ {ro(CA['eroare_v_max']*3.6, 2)} km/h; "
      f"η lanț: accelerare {ro(CA['eta_acc'], 3)}, palier {ro(CA['eta_pal'], 3)}, recuperare {ro(CA['eta_rec'], 3)}; "
      f"I_bat {ro(CA['I_bat_min'], 0)} … {ro(CA['I_bat_max'], 0)} A; energie din baterie {ro(E['total_bat']/1e3, 1)} kJ (P3: {ro(CA['P3']['W_stocata']/1e3, 1)} kJ) |")
    w("")
    w("![Ansamblu](etapa3-tema-motor/figuri/sim_C_ansamblu.png)")
    w("")

    # ------------------------------------------------------------------ P5-P6
    tr, rec = Dc["tr"], Dc["rec"]
    w("## 7. P5-P6 – Convertoarele și încărcarea bateriei")
    w("")
    w("| Bloc | Calcul | Simulare cu comutație |")
    w("|---|---|---|")
    w(f"| DC-DC bidirecțional, {D['N_faze']} faze, {ro(D['f_s']/1e3, 0)} kHz, {cv['dcdc']['modul']['nume']} | "
      f"P = {ro(D['P_dc_max']/1e3, 0)} kW; D = 1 − U_bat/U_dc = {ro(D['D_min'], 4)}…{ro(D['D_max'], 3)}; I_bat max {ro(D['I_bat_max'], 0)} A; "
      f"L = U_bat·D/(ΔI·f_s) = {ro(D['L']*1e6, 1)} µH/fază; C ≥ {ro(D['C']*1e6, 0)} µF; pierderi {ro(D['P_pierderi']/1e3, 2)} kW | "
      f"tracțiune: D = {ro(tr['D_med'], 4)} (teoretic {ro(tr['D_teoretic'], 4)}), ΔI faza {ro(tr['dI_faza'], 1)} A (formula {ro(tr['dI_faza_teoretic'], 1)}), "
      f"ΔI_bat {ro(tr['dI_bat'], 1)} A (intercalare); recuperare {ro(rec['I_bat_med'], 0)} A; U_dc {ro(Dc['U_dc_min'], 0)}…{ro(Dc['U_dc_max'], 0)} V la trepte |")
    w(f"| Chopper în punte H (invertorul echivalent), {ro(Hc['f_pwm']/1e3, 0)} kHz | ΔI = U_dc/(8·L_a·f) = {ro(Hc['dI_max'], 1)} A "
      f"({ro(100*Hc['dI_max_rel'], 1)} % din I_max) | în modelul Simulink de ansamblu |")
    w(f"| Încărcător {ro(Ci['P_AC']/1e3, 0)} kW: PFC {ro(Ci['U_dc'], 0)} V + coborâtor cu histerezis | CC {ro(Ci['I_CC'], 2)} A ({ro(Ci['C_rate'], 2)}C) până la "
      f"{ro(Ci['U_CV'], 0)} V, CV până la {ro(Ci['I_taiere'], 2)} A; L = {ro(Ci['L']*1e6, 0)} µH (h = {ro(Ci['h'], 1)} A); "
      f"10 → 100 %: {ro(Ci['t_total']/3600, 2)} h | trecerea CC → CV la {ro(Ic['t_CC']*1e3, 1)} ms (mediu: {ro(cv['simulare']['incarcare']['t_CC_s']*1e3, 0)} ms, timp scalat), "
      f"oprire la {ro(Ic['t_stop']*1e3, 1)} ms ({ro(Ic['t_stop_teoretic']*1e3, 1)}) |")
    w("")
    w(f"Încărcarea completă (model mediu): CC {ro(Im['t_CC']/3600, 2)} h, total {ro(Im['t_total']/3600, 2)} h; din rețea "
      f"{ro(Im['E_AC']/3.6e6, 2)} kWh, stocat {ro(Im['E_stocata']/3.6e6, 2)} kWh.")
    w("")
    w("![DC-DC](etapa4-convertoare/figuri/p5_dcdc_comutatie.png)")
    w("")

    # ------------------------------------------------------------------ Simulink
    w("## 8. Modelele Simulink (MATLAB R2023b)")
    w("")
    w("În folderul [`simulink`](simulink), `ruleaza_simulink` construiește automat, simulează și compară cu calculele "
      "Matlab șase modele: modelul MCC din C3 cu blocuri Simulink (scenariile A și D), mașina ca bloc **DC Machine** "
      "(Specialized Power Systems, ca în exemplul de curs), DC-DC-ul bidirecțional cu 4 faze, încărcătorul CC-CV cu "
      "histerezis și sistemul complet (baterie → DC-DC → punte H → DC Machine + vehicul, pe ciclul P3). Fișierele `.slx` "
      "rezultate se deschid și se modifică normal în Simulink.")
    w("")

    # ------------------------------------------------------------------ concluzii
    w("## 9. Concluzii")
    w("")
    w(f"1. Vehiculul mediu ({ro(V['M'], 0)} kg) cere P_max = {ro(R2['P_max']/1e3, 0)} kW la ax (limitat de aderență, 0–100 km/h în "
      f"{ro(R2['ta'], 2)} s) și P_n = {ro(R2['P_nom']/1e3, 0)} kW la v_max = {ro(R2['vmax']*3.6, 0)} km/h.")
    w(f"2. Bateria {B['Ns']}s{B['Np']}p cu celule Molicel P50B ({ro(B['W_real_kWh'], 1)} kWh) acoperă energia P3 "
      f"({ro(R3['Wbat_kWh'], 1)} kWh cu rezerva de 30 %) și curentul de vârf ({ro(B['I_celula'], 1)} A/celulă).")
    w(f"3. Cele {N} motoare YASA YM720 (1:{ro(T['k_rd'], 2)}) confirmă tema cu rezervă de putere; modelul MCC echivalent "
      f"are η_max = {ro(100*H4['eta_max'], 1)} % și reproduce 0–100 km/h în {ro(Bz['t_100'], 2)} s.")
    w(f"4. DC-DC-ul bidirecțional cu 4 faze SiC (L = {ro(D['L']*1e6, 0)} µH/fază, C ≈ {ro(D['C']*1e3, 1)} mF) menține 800 V la "
      f"tracțiune și recuperare; încărcătorul de 22 kW încarcă bateria în {ro(Ci['t_total']/3600, 1)} h.")
    w("5. La viteză constantă mică randamentul lanțului scade (3 motoare mari pentru câțiva kW): η = 0,8 din P3 este "
      "optimist pe palierul de 50 km/h, dar rezerva de 30 % a bateriei acoperă diferența; folosirea unui singur motor la "
      "viteză constantă ar crește randamentul.")
    w("")
    (RAD / "PREZENTARE_PROIECT.md").write_text("\n".join(L) + "\n", encoding="utf-8")
    print("scris PREZENTARE_PROIECT.md,", len(L), "linii")


if __name__ == "__main__":
    main()
