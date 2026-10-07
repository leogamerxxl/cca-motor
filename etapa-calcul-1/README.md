# Etapa 1 de calcul – dinamica longitudinală a vehiculului

**Vehicul:** Mercedes-AMG GT 63 4MATIC+ 4-Door Coupé (versiunea de serie a Concept AMG GT XX)
**Metodă:** relațiile (1)–(50) din „Noțiuni generale de dinamica vehiculului” (curs CCA C1, L. Popescu, UPB)

| Fișier | Conținut |
|---|---|
| [`CCA_Calcul1_Dinamica_GT63.xlsx`](CCA_Calcul1_Dinamica_GT63.xlsx) | Calculul complet, cu formule: **Rezultate** (sinteza pentru predare), **Date de intrare**, **Calcul regimuri** (relație cu relație), **Caracteristica tractiune** (F(v), P(v), timpi de accelerare + grafice) |
| [`calcul_dinamica_GT63.m`](calcul_dinamica_GT63.m) | Același calcul în MATLAB (rulează și în GNU Octave) – afișează tabelul regimurilor și desenează graficele |
| `fig_forte_tractiune.png`, `fig_puteri.png`, `fig_accelerare.png` | Graficele pentru raport |
| `build_calcul.py`, `grafice_calcul1.py` | Regenerează fișierul Excel și graficele |

Valorile din Excel și din scriptul MATLAB au fost comparate (GNU Octave 8.4): coincid pentru toate regimurile și pentru
timpii de accelerare. Calculul a fost refăcut și independent, pornind direct de la relațiile din curs (abateri < 10⁻¹³).

## 1. Date de intrare

| Mărime | Valoare | Tip |
|---|---|---|
| Masa de calcul M (masa UE în ordine de mers = 2460 kg DIN + 75 kg șofer) | 2535 kg | oficial |
| Cx / aria frontală S | 0,22 / 2,44 m² | oficial |
| Cuplul maxim al sistemului / puterea de vârf / puterea continuă | 2000 N·m / 860 kW / 530 kW | oficial |
| v_max / 0–100 km/h / 0–200 km/h | 300 km/h / 2,4 s / 6,8 s | oficial |
| Raza dinamică r_w (anvelopă 295/30 R21, k = 0,97) | 0,345 m | ipoteză |
| Raportul de transmitere i_g (din „peste 13 000 rot/min” la 300 km/h) | 5,63 | estimat |
| Randamentul transmisiei η / coeficientul maselor în rotație δ | 0,95 / 1,0 | ipoteză / curs (rel. 23) |
| ρ / f / μ | 1,225 kg/m³ / 0,012 / 0,85 | atmosferă standard / tabelele cursului (asfalt uscat) |
| μ pentru anvelope de performanță | 1,20 | calibrare (μ necesar pentru 2,4 s = 1,19) |
| Puterea medie disponibilă P_cal | 750 kW | calibrare (reproduce 0–200 km/h în 6,8 s) |

Sursele datelor oficiale: [comunicatul de lansare Mercedes-Benz Media, 20.05.2026](https://media.mercedes-benz.com/en/article/c8b7109f-2287-4070-b776-9204da1513ef)
și [articolul despre motorul cu flux axial](https://media.mercedes-benz.com/en/article/bebac2af-acdc-465a-9538-adb0bf3d8ccf).
Dimensiunile anvelopelor și rapoartele de transmitere nu sunt publicate pentru versiunea electrică – de aceea sunt ipoteze.
Deoarece i_g se calculează din r_w (turația la v_max), raportul i_g/r_w este fix: forțele, puterile și timpii nu depind de
anvelopa aleasă; aceasta influențează doar T_w și n_w.

Ipoteze ale modelului: vânt nul; tracțiune integrală cu distribuție ideală a cuplului între punți (rel. 39), deci
F_z = M·g·cos α (rel. 37); acționarea ca motor echivalent, F_t,drive = min(T_m,max·i_g·η/r_w ; η·P/v) (rel. 6, 30, 40);
f și μ constanți; la limita de aderență forța de contact accelerează doar masa M.

## 2. Regimuri caracteristice

F_t = ½·ρ·Cx·S·v² + f·M·g·cos α + M·g·sin α + δ·M·a (rel. 26), T_w = F_t·r_w (31), P_w = F_t·v (28),
P_m = P_w/η (29), T_m = F_t·r_w/(i_g·η) (33), verificare F_t ≤ min(F_t,drive ; μ·F_z) (42)–(43).

| Regim | v [km/h] | Pantă | a [m/s²] | F_t [N] | T_w [N·m] | P_m [kW] | T_m [N·m] | n_m [rot/min] | μ necesar | Condiția (43) |
|---|---|---|---|---|---|---|---|---|---|---|
| S1 – viteză maximă, drum orizontal | 300 | 0 | 0 | 2 582 | 890 | 226,5 | 166 | 13 000 | 0,10 | îndeplinită (rezervă) |
| S2a – accelerare 0–100 în 2,4 s, la pornire | 0 | 0 | 11,57 | 29 639 | 10 212 | 0 | 1 910 | 0 | 1,19 | **neîndeplinită – limită de aderență (μ = 0,85)** |
| S2b – accelerare 0–100 în 2,4 s, la 100 km/h | 100 | 0 | 11,57 | 29 892 | 10 299 | 874,0 | 1 926 | 4 333 | 1,20 | **neîndeplinită – limită de aderență (μ = 0,85)** |
| S3 – rampă 10 % la 100 km/h | 100 | 10 % | 0 | 3 025 | 1 042 | 88,5 | 195 | 4 333 | 0,12 | îndeplinită (rezervă) |
| S4 – pornire pe pantă de 30 % | 0 | 30 % | 0 | 7 432 | 2 561 | 0 | 479 | 0 | 0,31 | îndeplinită (rezervă) |

## 3. Indicatori de performanță

| Indicator | Calculat | Oficial |
|---|---|---|
| Timp 0–100 km/h cu μ = 0,85 (asfalt uscat, tabelul cursului) | 3,39 s | 2,4 s |
| Timp 0–100 km/h cu μ = 1,20 (calibrare: μ necesar = 1,19) | 2,39 s | 2,4 s |
| Timp 0–200 km/h cu μ = 1,20 și P_vârf = 860 kW | 6,18 s | 6,8 s |
| Timp 0–100 / 0–200 km/h cu μ = 1,20 și P_cal = 750 kW | 2,42 s / 6,80 s | 2,4 s / 6,8 s |
| Coeficient de aderență necesar pentru 0–100 km/h în 2,4 s | 1,19 | – |
| Viteza maximă teoretică limitată de puterea continuă / de vârf | 406 / 480 km/h | 300 km/h (limitată electronic) |
| Panta maximă limitată de aderență (μ = 0,85) | 83,8 % | – |

![Caracteristica de tracțiune](fig_forte_tractiune.png)
![Puterea cerută motoarelor](fig_puteri.png)
![Accelerare](fig_accelerare.png)

## 4. Concluzii

1. **Viteza maximă nu este limitată de putere.** La 300 km/h sunt necesari 2 582 N la roți și 226 kW la motoare (43 % din
   puterea continuă); 88 % din rezistență este aerodinamică. Cu puterea continuă ar fi posibilă teoretic ≈ 406 km/h, deci
   limita de 300 km/h este electronică, conform datelor oficiale. Turația de 13 000 rot/min la v_max este o dată de intrare
   (folosită pentru estimarea i_g), nu un rezultat al calculului.
2. **Accelerarea este limitată de aderență, nu de acționare.** Pentru 0–100 km/h în 2,4 s este nevoie de 29 639 N la
   pornire, adică μ ≥ 1,19. Cu μ = 0,85 (asfalt uscat, tabelul cursului) se pot transmite doar 21 138 N din cei 31 039 N
   pe care îi poate furniza acționarea, iar timpul minim estimat este 3,4 s.
3. **Timpul oficial de 2,4 s se obține numai cu μ ≈ 1,2** (anvelope sport pe asfalt uscat, peste valorile din tabelul
   cursului); cu μ = 1,20 modelul dă 2,39 s – aceasta este o calibrare a lui μ, nu o verificare independentă.
   Raza r_w și raportul i_g nu influențează forțele, puterile și timpii (i_g este calculat din r_w).
4. **Peste ≈ 99 km/h accelerarea este limitată de putere.** Cu P_vârf = 860 kW (817 kW la roți) modelul dă 0–200 km/h în
   6,18 s, cu 9 % mai repede decât valoarea oficială de 6,8 s; timpul oficial se obține cu o putere medie disponibilă de
   ≈ 750 kW. Cauze posibile: puterea de vârf nu este disponibilă integral pe tot intervalul 100–200 km/h, randamentul real
   scade la turații mari, iar masele în rotație au fost neglijate (δ = 1, rel. 23).
5. **Puterea de vârf este necesară doar pentru performanța maximă:** menținerea accelerației medii de 11,57 m/s² până la
   100 km/h ar cere 874 kW, adică 102 % din puterea de vârf.
6. **Rampele nu sunt o problemă:** 10 % la 100 km/h cere 88 kW, iar pornirea pe 30 % cere 7 432 N (μ necesar 0,31).
7. **De confirmat în etapele următoare:** dimensiunea anvelopelor, rapoartele reale față/spate, distribuția cuplului
   între punți (cap. 10, rel. 39), cuplul continuu al motoarelor și curba reală a puterii de vârf în funcție de viteză.
   Pasul următor din curs: modelul dinamic și curbele T(n), P(n) ale motorului.
