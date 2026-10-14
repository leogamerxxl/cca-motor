# Etapa 2 – Calcule de dimensionare (Proiect P2 și P3)

Calculele cerute în suporturile **CCA – Proiect P2** (07.10.2026) și **CCA – Proiect P3** (14.10.2026):

- **P2** – prelucrarea datelor din documentare (transformare în S.I.), forțele rezistente pe vehicul și
  **puterea maximă / nominală a mașinii electrice**, cu reductorul și cuplul la ax;
- **P3** – **necesarul de energie electrică** pentru un ciclu accelerare – 50 km/h constant – decelerare a cărui
  lungime este autonomia cerută (inclusiv exercițiul Matlab cu n = 100 și n = 1000 de pași) și **calculul bateriei**
  cu celule Li-ion.

Conform suportului („se preiau datele medii rezultate din faza de documentare”), tema se calculează pentru
**vehiculul mediu** al celor 10 vehicule de serie din tabelul etapei 1. Același calcul este făcut și pentru vehiculul
de referință **Mercedes-AMG GT 63 4MATIC+ 4-Door Coupé**, pentru comparație.

## Fișiere

| Fișier | Conținut |
|---|---|
| [`CCA_Etapa2_Calcule.xlsx`](CCA_Etapa2_Calcule.xlsx) | Toate calculele ca formule Excel: Date documentare, Sinteză, Ipoteze, P2 Putere, P3 Energie, P3 n=100, P3 n=1000, Baterie, Surse |
| [`matlab/`](matlab) | Programul Matlab: `main_p2.m`, `main_p3.m` (afișează pașii și trasează graficele), `ruleaza_tot.m`, funcțiile de calcul |
| [`date/date_documentare.csv`](date/date_documentare.csv) | Datele de intrare din documentare (o linie pe vehicul) |
| [`date/celula_aleasa.json`](date/celula_aleasa.json) | Parametrii celulei Li-ion alese (Molicel INR-21700-P50B) |
| [`python/calcule_p2_p3.py`](python/calcule_p2_p3.py) | A doua implementare (verificare), generează registrul Excel, figurile și tabelele din acest README |
| [`figuri/`](figuri) | Graficele P2 și P3 |
| [`rezultate/`](rezultate) | Rezultatele numerice (JSON) din Matlab/Octave și din Python |

**Rulare Matlab:** din folderul `matlab/` se execută `main_p2` și apoi `main_p3` (sau `ruleaza_tot`, care salvează și
`rezultate/rezultate_matlab.json`). Fișierele `.m` sunt în UTF-8 (Matlab R2020a sau mai nou); funcționează și în GNU Octave 8.
**Rulare Python:** `python3 etapa2-calcule/python/calcule_p2_p3.py` (numpy, matplotlib, openpyxl).

**Verificare:** aceleași calcule sunt făcute în trei moduri independente – Matlab (rulat în Octave 8.4), Python și
formulele din Excel (recalculate cu LibreOffice). Toate mărimile comparate coincid (eroare relativă < 10⁻⁶), iar registrul
nu are erori de formulă.

## Ipoteze de calcul

| Mărime | Valoare | Justificare |
|---|---|---|
| g | 9,81 m/s² | valoare uzuală |
| ρ (densitatea aerului) | 1,293 kg/m³ | „condiții normale” (0 °C, 101 325 Pa): ρ = p/(R·T) = 101 325/(287,05 · 273,15); la 15 °C (atmosfera standard ISA) ρ = 1,225 kg/m³ – vezi sensibilitatea |
| µf (frecare la rulare) | 0,013 | exemplul din curs |
| µa (aderență) | 0,8 | exemplul din curs (asfalt uscat); anvelopele de performanță ajung la 1,0–1,2 – vezi sensibilitatea |
| α, Vv | 0, 0 | drum drept, fără vânt (simplificările din curs) |
| r (raza dinamică a roții) | 0,35 m | media razelor anvelopelor spate publicate (Porsche 305/30 R21, Audi 285/40 R20, Lucid 295/30 R21, Rimac 315/35 R20) este 0,361 m; raza dinamică ≈ 0,97 · 0,361 ≈ 0,35 m (și exemplul „35 cm” din curs) |
| Pp (pierderi în reductor) | Pax / 100 | curs (P2, slide 7) |
| Va | 100 km/h | accelerația se ia din timpul 0–100 km/h din documentare |
| n_max (turația maximă a mașinii la v_max) | 15 000 rot/min | alegere de proiectare; motoarele clasei: GT 63 > 13 000 / > 15 000 rot/min, Xiaomi V8s 27 200 rot/min |
| V1, η, rezervă | 50 km/h, 80 %, 30 % | curs (P3) |
| U_bat | ≈ 800 V | arhitectura de 800 V a clasei de vehicule |
| Masa bateriei | ≤ 30 % din M | curs (P3, slide 9) |

## P2 – Datele din documentare

Datele de intrare ale fiecărui vehicul (etapa 1, completate cu autonomia și consumul, cu surse în foaia „Surse”):

<!-- AUTO:vehicule -->
| Vehicul | P [kW] | v_max [km/h] | a 0–100 [m/s²] | M [kg] | Cuplu [Nm] | Baterie [kWh] | Autonomie [km] | Consum [kWh/100 km] | Cx | S [m²] |
|---|---|---|---|---|---|---|---|---|---|---|
| Mercedes-AMG GT 63 4MATIC+ 4-Door Coupe | 860 | 300 | 11,57 | 2 460 | 2 000 | 106,0 | 646,0 WLTP | 19,45 | 0,220 | 2,44 |
| Porsche Taycan Turbo GT (Weissach) | 760 | 305 | 12,63 | 2 220 | 1 240 | 97,0 | 546,5 WLTP | 20,95 | 0,310 | 2,35 |
| Audi RS e-tron GT performance | 680 | 250 | 11,11 | 2 320 | 1 027 | 97,0 | 562,5 WLTP | 19,75 | 0,260 | 2,35 |
| Lotus Emeya R | 675 | 256 | 9,99 | 2 565 | 985 | 102,0 | 460,0 WLTP | – | – | – |
| Tesla Model S Plaid | 760 | 322 | 13,23 | 2 178 | 1 420 | 96,0 | 605,5 WLTP | 18,35 | 0,208 | – |
| Lucid Air Sapphire | 908 | 330 | 14,19 | 2 420 | 1 940 | 118,0 | 694,0 WLTP | 19,10 | – | – |
| Xiaomi SU7 Ultra | 1 138 | 350 | 14,03 | 2 360 | 1 770 | 93,7 | 592,5 CLTC | 16,50 | – | – |
| Yangwang U9 | 960 | 309 | 11,77 | 2 475 | 1 680 | 80,0 | 450,0 CLTC | – | – | – |
| Rimac Nevera | 1 408 | 412 | 15,35 | 2 300 | 2 340 | 120,0 | 489,0 WLTP | 30,00 | 0,300 | – |
| Maserati GranTurismo Folgore | 560 | 325 | 10,29 | 2 260 | 1 350 | 83,0 | 454,5 WLTP | 22,10 | – | – |
| **Medie** | **870,9** | **315,9** | **12,42** | **2 355,8** | **1 575,2** | **99,3** | **557,2** (WLTP) | **21,39** (WLTP) | **0,2596** | **2,380** |
<!-- /AUTO:vehicule -->

Accelerația fiecărui vehicul este a = v / t pentru 0–100 km/h (Lucid: 0–60 mph = 96,56 km/h); media accelerațiilor dă
timpul echivalent 0–100 km/h. **Autonomia și consumul se mediază doar pe valorile WLTP**: Xiaomi și Yangwang declară
ciclul chinezesc CLTC (mai lent și fără porțiuni de autostradă, deci cu autonomii mai mari decât WLTP). Cx și S sunt
mediate pe valorile publicate (5, respectiv 3 vehicule).

Transformarea în unități S.I. (slide 2):

<!-- AUTO:date_si -->
| Mărime | Vehicul mediu | în S.I. | GT 63 (S.I.) |
|---|---|---|---|
| Putere maximă | 870,9 kW | 870 900 W | 860 000 W |
| Viteză maximă | 315,9 km/h | 87,750 m/s | 83,333 m/s |
| Accelerație maximă (medie 0–100 km/h) | 2,24 s | 12,416 m/s² | 11,574 m/s² |
| Autonomie | 557,2 km | 557 250 m | 646 000 m |
| Masă | 2 355,8 kg | 2 355,8 kg | 2 460 kg |
| Capacitate baterie | 99,27 kWh | 357 372 000 Ws | 381 600 000 Ws |
| Cuplu | 1 575,2 Nm | 1 575,2 Nm | 2 000 Nm |
| Consum mediu | 21,39 kWh/100 km | 769,9 Ws/m | 700,2 Ws/m |
| Cx | 0,2596 | 0,2596 | 0,22 |
| Suprafață frontală S | 2,380 m² | 2,380 m² | 2,44 m² |
<!-- /AUTO:date_si -->

## P2 – Puterea mașinii electrice (pașii 1–9)

Se calculează succesiv Ft → Mr → Pr → Pax: întâi în punctul (Va, ta) de la sfârșitul accelerării (puterea maximă),
apoi la v_max constantă, cu a = 0 (puterea nominală).

<!-- AUTO:p2 -->
| Pas | Mărime | Unitate | Vehicul mediu | GT 63 |
|---|---|---|---|---|
| 2 | a_doc = Va / ta | m/s² | 12,416 | 11,574 |
| 3 | Fra(Va) | N | 308,2 | 267,8 |
| 3 | Ff | N | 300,4 | 313,7 |
| 3 | Ft = Fra + Ff + Gt + M·a_doc | N | 29 857,5 | 29 053,7 |
| 4 | Fa = µa·M·g | N | 18 488,3 | 19 306,1 |
| 4 | a realizabil (Ft = Fa) | m/s² | 7,590 | 7,612 |
| 4 | ta realizabil (0–100 km/h) | s | 3,66 | 3,65 |
| 5 | Mr = r·Ft | Nm | 6 470,9 | 6 757,1 |
| 5 | Ωr = Va / r | rad/s | 79,37 | 79,37 |
| 5 | Pr = Mr·Ωr | kW | 513,56 | 536,28 |
| 5 | Pax = Pr / 0,99 | kW | 518,75 | 541,70 |
| 6 | i_rd = Ωr / Ωax (n_max = 15 000 rot/min) | - | 0,1596 | 0,1516 |
| 6 | 1 / i_rd | - | 6,27 | 6,60 |
| 6 | n_ax la Va (turația de bază) | rot/min | 4 748 | 5 000 |
| 6 | Max = Pax / Ωax | Nm | 1 043,3 | 1 034,6 |
| 7 | Fra(v_max) | N | 3 075,7 | 2 410,0 |
| 7 | Ft(v_max) = Fra + Ff + Gt | N | 3 376,1 | 2 723,7 |
| 8 | Pax la v_max | kW | 299,25 | 229,27 |
| 8 | Max la v_max | Nm | 190,5 | 146,0 |
| 9 | **P_max (puterea maximă)** | kW | **518,8** | **541,7** |
| 9 | **P_nom (puterea nominală)** | kW | **299,2** | **229,3** |
| – | Pax cu a_doc, fără limita de aderență | kW | 837,8 | 815,2 |
| – | Puterea declarată (documentare) | kW | 870,9 | 860,0 |
<!-- /AUTO:p2 -->

![P2 – forțe și putere](figuri/p2_forte_putere.png)

**Observații P2**

1. **Aderența nu este respectată cu accelerația din documentare.** Media vehiculelor de serie face 0–100 km/h în
   ≈ 2,2 s (a ≈ 12,4 m/s² ≈ 1,27 g), dar cu µa = 0,8 forța de aderență permite cel mult a ≈ 7,6 m/s². Conform pasului 4,
   s-a luat Ft = Fa și s-a recalculat accelerația: 0–100 km/h în ≈ 3,7 s. Vehiculele reale depășesc 1 g pentru că au
   anvelope de performanță (µ ≈ 1,1–1,3), tracțiune integrală și apăsare aerodinamică.
2. **Verificarea coerenței:** cu accelerația din documentare (fără limita de aderență) aceeași formulă dă o putere la
   ax foarte apropiată de puterea declarată (vezi ultimele două rânduri ale tabelului). Datele din documentare sunt deci
   coerente între ele, iar diferența până la P_max provine numai din coeficientul de aderență ales.
3. **Puterea nominală** (rulare cu v_max) este dominată de rezistența aerodinamică: Fra(v_max) ≈ 91 % din Ft.
4. **Reductorul:** cu n_max = 15 000 rot/min la v_max rezultă i_rd ≈ 0,16 (≈ 1 : 6,3), apropiat de valorile reale ale
   clasei (Lucid Air Sapphire 7 : 1 față / 6,8 : 1 spate). Turația de bază (la Va) este ≈ 4 750 rot/min, deci mașina
   trebuie să lucreze la putere constantă pe un domeniu de ≈ 3,2 : 1 (slăbire de câmp).
5. Cuplul și puterea calculate sunt pentru tot vehiculul; repartizarea pe 2–4 motoare (față / spate) se face la schema
   acționării (etapa 4).

Sensibilitatea față de µa și ρ (vehicul mediu):

<!-- AUTO:sensibilitate -->
| µa | ρ [kg/m³] | a [m/s²] | ta 0–100 [s] | P_max [kW] | P_nom [kW] |
|---|---|---|---|---|---|
| 0,8 | 1,293 | 7,59 | 3,66 | 518,8 | 299,2 |
| 0,8 | 1,225 | 7,60 | 3,66 | 518,8 | 284,9 |
| 1,0 | 1,293 | 9,55 | 2,91 | 648,4 | 299,2 |
| 1,0 | 1,225 | 9,56 | 2,91 | 648,4 | 284,9 |
| 1,2 | 1,293 | 11,51 | 2,41 | 778,1 | 299,2 |
| 1,2 | 1,225 | 11,52 | 2,41 | 778,1 | 284,9 |
<!-- /AUTO:sensibilitate -->

Cu µa = 1,2 (anvelope de performanță) accelerația și puterea maximă se apropie de valorile reale ale clasei.
Densitatea aerului influențează numai puterea nominală.

## P3 – Necesarul de energie electrică (pașii 1–14)

Ciclul de testare: accelerare cu accelerația a din P2 până la V1 = 50 km/h, rulare cu V1 constantă, decelerare
simetrică (df = d1). Lungimea totală a ciclului este autonomia medie din documentare.

![P3 – ciclul](figuri/p3_ciclu.png)

<!-- AUTO:p3 -->
| Pas | Mărime | Unitate | Vehicul mediu | GT 63 |
|---|---|---|---|---|
| 1 | V1 | m/s | 13,8889 | 13,8889 |
| 2–4 | a (din P2; Ft1 ≤ Fa) | m/s² | 7,590 | 7,612 |
| 3 | Ft1 = Fra + Ff + Gt + M·a | N | 18 257,2 | 19 105,2 |
| 3 | P1 = Ft1·V1 | kW | 253,572 | 265,351 |
| 5 | Ft1' = Fra + Ff + Gt | N | 377,49 | 380,67 |
| 5 | P1' = Ft1'·V1 | kW | 5,2429 | 5,2871 |
| 6 | t1 = V1 / a | s | 1,8300 | 1,8247 |
| 7 | Pmed = P1 / 2 | kW | 126,786 | 132,675 |
| 7 | P01-med (n = 1000) | kW | 126,645 | 132,576 |
| 8 | Wmed = Pmed·t1 | kJ | 232,016 | 242,092 |
| 8 | W01-med = P01-med·t1 | kJ | 231,758 | 241,910 |
| 8 | W01 = Σ Pti·Δti (n = 1000) | kJ | 231,758 | 241,910 |
| 8 | W01 exact (integrală) | kJ | 231,526 | 241,668 |
| 9 | d1 = df = V1·t1 / 2 | m | 12,708 | 12,672 |
| 10 | autonomie = d1 + d2 + df | km | 557,2 | 646,0 |
| 10 | d2 | km | 557,225 | 645,975 |
| 10 | t2 − t1 = d2 / V1 | h | 11,144 | 12,919 |
| 11 | W12 = P1'·(t2 − t1) | kWh | 58,429 | 68,306 |
| 12 | Wmec = W01 + W12 − W2f | kWh | 58,429 | 68,306 |
| 13 | Wstocată = W01/η + W12/η − η·W2f | kWh | 73,066 | 85,413 |
| 14 | Wbat = Wstocată / (1 − 0,30) | kWh | 104,38 | 122,02 |
| – | consum echivalent (Wstocată / autonomie) | kWh/100 km | 13,11 | 13,22 |
| – | consum mediu din documentare | kWh/100 km | 21,39 | 19,45 |
| – | baterie din documentare | kWh | 99,3 | 106,0 |
<!-- /AUTO:p3 -->

**Exercițiul Matlab – discretizarea intervalului [0, t1]** (vehicul mediu). Pe fiecare interval [t(i−1), t(i)] forța
Fti și viteza Vti se consideră constante (valorile din t(i)):

<!-- AUTO:discretizare -->
| n | Δt [ms] | P01-med [kW] | W01 [kJ] | eroare față de integrala exactă | timp de calcul [µs] |
|---|---|---|---|---|---|
| 100 | 18,300 | 127,786 | 233,846 | +1,002 % | 8,8 |
| 1000 | 1,830 | 126,645 | 231,758 | +0,100 % | 11,8 |
| exact | – | 126,518 | 231,526 | 0 | – |
| Pmed = P1/2 | – | 126,786 | 232,016 | +0,211 % | – |
<!-- /AUTO:discretizare -->

![P3 – P(t) pentru n = 100 și n = 1000](figuri/p3_putere_discretizare.png)

**Observații P3**

1. **Precizie vs. efort de calcul:** eroarea sumei Σ Pti·Δti este proporțională cu Δt – de 10 ori mai mulți pași dau o
   eroare de 10 ori mai mică (≈ 1 % → ≈ 0,1 %). Timpul de calcul crește mult mai puțin decât de 10 ori, pentru că
   programul este vectorizat; timpul exact depinde de calculator (valorile din tabel sunt din Python, cele din Matlab
   sunt de același ordin, câteva zeci de µs).
2. Cu ipoteza din curs (Fti și Vti constante pe interval) avem P01-med · t1 = Σ Pti·Δti, deci **W01-med = W01**.
   Aproximarea Pmed = P1/2 presupune P(t) liniar; termenul aerodinamic crește cu t³, deci Wmed supraestimează puțin
   integrala exactă (sub 0,3 %). La viteza de 50 km/h energia de accelerare W01 este neglijabilă față de W12.
3. Pe slide-ul 7 relația „t2 − t1 = V1/d2” trebuie citită **t2 − t1 = d2 / V1** (timp = distanță / viteză).
4. Wmec = W12, pentru că W01 = W2f; în energia stocată rămâne doar pierderea pe ciclul accelerare – frânare
   recuperativă: W01/η − η·W01 = 0,45 · W01.
5. **Coerența cu documentarea:** energia necesară în baterie (cu rezerva de 30 %) iese apropiată de capacitatea medie a
   bateriilor din documentare. Consumul ciclului (≈ 13 kWh/100 km) este însă mult mai mic decât consumul WLTP mediu
   (≈ 21 kWh/100 km), pentru că la 50 km/h rezistența aerodinamică este mică, iar WLTP conține porțiuni la 130 km/h,
   pierderi la încărcare și consumatori auxiliari. Rezerva de 30 % compensează în mare parte această diferență.

## P3 – Calculul bateriei electrice

Celula aleasă: **Molicel INR-21700-P50B** (fișa tehnică oficială v1.1): 3,6 V nominal (2,5–4,2 V), 5,0 Ah, 18 Wh,
71 g, 60 A descărcare continuă, rezistență internă DC 12,8 mΩ; producătorul o recomandă pentru „Hyper EVs & Racing
Sports Cars”. Alternativele analizate (Molicel P45B, Samsung SDI 50S – 45 A; Ampace JP50 – fără rezistență internă
publicată) ar necesita mai multe ramuri în paralel la aceeași putere.

- celulele **în serie** dau tensiunea: Ns = round(800 V / 3,6 V) = 222 ⇒ U = 799 V (555–932 V);
- celulele **în paralel** dau curentul și capacitatea: Np = max(Np din energie, Np din curent);
- curentul maxim al bateriei corespunde puterii maxime P2 la randamentul η = 80 %.

<!-- AUTO:baterie -->
| Mărime | Vehicul mediu | GT 63 |
|---|---|---|
| Energia necesară Wbat | 104,38 kWh | 122,02 kWh |
| W_celulă = Cap·U | 64 800 Ws (18,0 Wh) | idem |
| N_min = Wbat / W_celulă | 5 799 | 6 779 |
| Celule în serie Ns (U ≈ 800 V) | 222 | 222 |
| Tensiune nominală (min – max) | 799,2 V (555 – 932 V) | 799,2 V |
| Ramuri în paralel: din energie / din curent | 27 / 14 | 31 / 15 |
| **Configurație** | **222s27p = 5 994 celule** | **222s31p = 6 882 celule** |
| Energie instalată / capacitate | 107,89 kWh / 135 Ah | 123,88 kWh / 155 Ah |
| Curent maxim baterie (P_max / η / U) | 811 A | 847 A |
| Curent pe celulă la P_max (max. 60 A) | 30,1 A | 27,3 A |
| Masa celulelor | 425,6 kg (18,1 % din M) | 488,6 kg (19,9 %) |
| Masa estimată a pachetului (celule / 0,70) | 608,0 kg (25,8 %) | 698,0 kg (28,4 %) |
| Limita 30 % din M | 706,7 kg – respectată | 738,0 kg – respectată |
<!-- /AUTO:baterie -->

Masa pachetului se estimează împărțind masa celulelor la 0,70 (celulele reprezintă ≈ 70 % din masa unui pachet cu
celule cilindrice; restul este carcasă, răcire, BMS și conexiuni). Limita de 30 % din masa vehiculului este respectată.

## Sinteză – date pentru proiectare

<!-- AUTO:sinteza -->
| Subsistem | Mărime | Vehicul mediu (temă) | GT 63 (comparație) |
|---|---|---|---|
| Mașina electrică | Puterea maximă / nominală | 519 kW / 299 kW | 542 kW / 229 kW |
| | Cuplul maxim la ax | 1 043 Nm | 1 035 Nm |
| | Turația de bază / maximă | 4 748 / 15 000 rot/min | 5 000 / 15 000 rot/min |
| Reductor | i_rd = Ωr/Ωax (1 : k) | 0,1596 (1 : 6,27) | 0,1516 (1 : 6,60) |
| Vehicul | a realizabil / 0–100 km/h | 7,59 m/s² / 3,66 s | 7,61 m/s² / 3,65 s |
| Baterie | Energie necesară / instalată | 104,4 / 107,9 kWh | 122,0 / 123,9 kWh |
| | Celule Molicel P50B | 222s27p = 5 994 | 222s31p = 6 882 |
| | Tensiune nominală (min – max) | 799 V (555 – 932 V) | idem |
| Convertor / invertor | Curent maxim din baterie | 811 A | 847 A |
<!-- /AUTO:sinteza -->

## Legătura cu calculul de dinamică din `etapa-calcul-1`

Folderul [`../etapa-calcul-1`](../etapa-calcul-1/README.md) calculează dinamica longitudinală a GT 63 cu relațiile din
cursul C1 și cu alte ipoteze: masa UE cu șofer (2535 kg), ρ = 1,225 kg/m³, f = 0,012, µ = 0,85 / 1,20, r = 0,345 m,
randamentul transmisiei 0,95. Aici se folosesc exemplele din suporturile P2/P3 (masa DIN 2460 kg din tabelul etapei 1,
ρ = 1,293 kg/m³, µf = 0,013, µa = 0,8, r = 0,35 m, Pp = 1 %), de aceea valorile diferă puțin. Concluziile coincid:
accelerarea din datele oficiale cere µ ≈ 1,2 (adică este limitată de aderență), iar la v_max puterea necesară
(≈ 230 kW la GT 63) este mult sub puterea continuă de 530 kW.

## Observații pentru etapele următoare

- **Etapa 4 (schema acționării):** puterea și cuplul de mai sus se împart pe motoare (de exemplu 1 față + 2 spate, ca la
  GT 63). Convertorul (invertorul) trebuie să funcționeze pe tot domeniul de tensiune al bateriei, de la 555 V
  (descărcată) la 932 V (încărcată).
- **Etapa 5 (calcul și simulare):** modelul Simulink poate porni de la funcțiile `forte_rezistente.m`, `calcul_p2.m` și
  `calcul_p3.m`. Pentru GT 63, rapoartele reale ale reductoarelor și dimensiunile anvelopelor nu sunt publicate
  (vezi README-ul etapei 1).
