# Etapa 1 – Documentare

**Tipul de vehicul ales:** automobil electric de înaltă performanță (GT / super-sport).
**Vehicul de referință:** Mercedes-AMG Concept GT XX (concept, iunie 2025) și versiunea sa de serie,
Mercedes-AMG GT 63 4MATIC+ 4-Door Coupé (platforma AMG.EA, prezentat în mai 2026).

Fișierul de lucru este [`CCA_Etapa1_Documentare.xlsx`](CCA_Etapa1_Documentare.xlsx):

| Foaie | Conținut |
|---|---|
| Tabel comparativ | 11 vehicule de la 10 producători (cerința: minimum 7) – viteză maximă, putere, cuplu, motoare, transmisie, baterie, tensiune, masă, consum, Cx, sursă |
| Gantt | Diagrama Gantt a proiectului (14 ședințe, 07.10.2026 – 13.01.2027), cu cele 3 teste |
| Surse | Linkurile folosite pentru fiecare vehicul |

Fișierul se regenerează cu `python3 build_etapa1.py CCA_Etapa1_Documentare.xlsx`.

## Tabel comparativ (rezumat)

| Producător | Model | Stadiu | v_max [km/h] | P_max [kW] | Cuplu [Nm] | Motoare | Baterie [kWh] | U [V] |
|---|---|---|---|---|---|---|---|---|
| **Mercedes-AMG** | **Concept AMG GT XX** | concept 2025 | >360 | >1000 | n.d. | 3 × flux axial (YASA), 2 spate + 1 față | ≈114 | >800 |
| **Mercedes-AMG** | **GT 63 4-Door Coupé (AMG.EA)** | serie 2026 | 300 | 860 (continuu 530) | 2000 | 3 × flux axial, 2 spate + 1 față | 106 (net) | 800 |
| Porsche | Taycan Turbo GT (Weissach) | serie 2024 | 305 | 760 (LC) | 1240 | 2 × PSM; spate cutie 2 trepte | 97 / 105 | 800 |
| Audi | RS e-tron GT performance | serie 2024 | 250 | 680 (LC) | 1027 | 2 × PSM; spate cutie 2 trepte | 97 / 105 | 800 |
| Lotus | Emeya R | serie 2024 | 256 | 675 | 985 | 2 × PMSM (față + spate); spate cutie 2 trepte (900 Sport Carbon) | 102 (brut) | 705 (nominal) |
| Tesla | Model S Plaid | serie 2021 | 322 | 760 | 1420 | 3 × PMSM, 1 față + 2 spate | ≈96 | ≈400 |
| Lucid | Air Sapphire | serie 2023 | 330 | 908 | 1940 | 3 × PMSM, 1 față + 2 spate; o treaptă (7:1 / 6,8:1) | 118 | 900+ |
| Xiaomi | SU7 Ultra | serie 2025 | 350 | 1138 | 1770 | 2 × V8s + 1 × V6s | 93,7 | 897 |
| BYD (Yangwang) | U9 | serie 2024 | 309 | 960 | 1680 | 4 × 240 kW, câte unul pe roată | 80 (LFP) | 800 |
| Rimac | Nevera | serie 2021 | 412 | 1408 | 2340 | 4 × PMSM (2 × 220 + 2 × 480 kW) | 120 | 730 (max.) |
| Maserati | GranTurismo Folgore | serie 2023 | 325 | 560 | 1350 | 3 × PMSM × 300 kW | 83 / 92,5 | 800 |

LC = Launch Control. Datele complete (0–100 km/h, masă, consum, Cx, observații, sursă) sunt în fișierul Excel.

Date verificate direct pe documentele producătorului la 07.10.2026: Mercedes-AMG (Mercedes-Benz Media), Porsche, Audi,
Lotus, Lucid, Rimac (fișe tehnice) și BYD (comunicat). Site-urile Tesla, Maserati/Stellantis și Xiaomi blochează accesul
automat, așa că o parte din valorile lor rămân marcate „S” (sursă secundară).

## Observații pentru etapele următoare

- **Etapa 3 cere un vehicul de serie.** Concept GT XX nu este produs în serie; versiunea de serie este
  Mercedes-AMG GT 63 (sau GT 55) 4-Door Coupé, care păstrează arhitectura conceptului: trei motoare cu flux axial,
  două pe puntea spate (fiecare cu reductor planetar) și unul pe puntea față, baterie de 800 V.
- **Puterea nominală vs. de vârf.** Producătorii publică aproape doar puterea de vârf (adesea doar cu Launch Control).
  Puterea continuă este publicată de Audi (163 kW) și de Mercedes-AMG (GT 63: 530 kW; GT 55: 375 kW; GT 53: 270 kW).
- **0–100 km/h la GT 63:** 2,1 s este măsurat cu „1-foot rollout” (primii 30,48 cm nu se cronometrează); valoarea
  standard este 2,4 s – aceasta este trecută în tabel.
- **Masa GT 63:** 2460 kg este masa DIN (fără șofer); 2535 kg = masa UE (cu șofer de 75 kg). Ambele valori din surse erau corecte.
- Valorile marcate „S” (sursă secundară) în Excel trebuie verificate pe pagina producătorului înainte de predare
  (Tesla, Maserati, Xiaomi, Yangwang – masă/tensiune, Lotus – masă, Concept GT XX – baterie).

## Date pentru etapa 5

Date pentru calculul de dinamică longitudinală (cursul C1) – Mercedes-AMG GT 63 4MATIC+ 4-Door Coupé.
Sursa principală: [comunicatul de lansare Mercedes-Benz Media, 20.05.2026](https://media.mercedes-benz.com/en/article/c8b7109f-2287-4070-b776-9204da1513ef)
(tabel tehnic) și [articolul despre motorul cu flux axial](https://media.mercedes-benz.com/en/article/bebac2af-acdc-465a-9538-adb0bf3d8ccf).

| Mărime | Valoare | Sursă / observație |
|---|---|---|
| Masă proprie DIN | 2460 kg | oficial (≈2535 kg UE, cu șofer) |
| Coeficient de rezistență aerodinamică Cx | 0,22 | oficial |
| Arie frontală A | 2,44 m² | oficial (Cx·A = 0,537 m²) |
| Lungime / lățime / înălțime / ampatament | 5094 / 1959 / 1411 / 3040 mm | oficial |
| Putere de vârf / continuă | 860 kW (Launch Control, 80 % SoC) / 530 kW | oficial; durata boost 63 s |
| Cuplu maxim (sistem) | 2000 Nm | oficial |
| v_max | 300 km/h (cu Driver's Package; altfel limitat electronic) | oficial |
| 0–100 / 0–200 km/h | 2,4 s / 6,8 s (2,1 / 6,4 s cu 1-foot rollout) | oficial |
| Baterie | 106 kWh net, 800 V nominal, 2660 celule NCMA | oficial; capacitatea brută nu e publicată (≈111 kWh în EV Database – S) |
| Transmisie spate | 2 motoare, reductor planetar cu **o treaptă**, carcasă comună | oficial; **raportul nu este publicat** |
| Transmisie față | 1 motor, reductor cu roți dințate cilindrice + DCU (decuplare) | oficial; **raportul nu este publicat** |
| Turația motoarelor la v_max | spate > 13 000 rot/min, față > 15 000 rot/min | oficial |
| Jante | 19″ – 21″ | oficial; **dimensiunile anvelopelor pentru versiunea electrică nu sunt publicate** |
| Distribuția masei pe punți | nepublicată | – |

**Estimare (nu valoare oficială) a rapoartelor de transmisie.** Din turația la v_max se poate deduce raportul:
i = n_motor / n_roată, cu n_roată = v / (2π·r_d)·60. Pentru v = 300 km/h = 83,3 m/s și o rază dinamică presupusă
r_d = 0,34–0,36 m (jantă de 21″ cu anvelopă de profil 30–35), n_roată ≈ 2210–2340 rot/min, deci
**i_spate ≳ 5,6–5,9** și **i_față ≳ 6,4–6,8** (limite inferioare, deoarece producătorul dă „peste” 13 000 / 15 000 rot/min).
Raza dinamică trebuie recalculată când se află dimensiunea anvelopelor (de exemplu din certificatul de conformitate CoC
sau din configuratorul Mercedes).
