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
| **Mercedes-AMG** | **GT 63 4-Door Coupé (AMG.EA)** | serie 2026 | 300 | 860 | ≈2000 | 3 × flux axial, 2 spate + 1 față | 106 | 800 |
| Porsche | Taycan Turbo GT (Weissach) | serie 2024 | 305 | 760 (LC) | 1240 | 2 × PSM; spate cutie 2 trepte | 97 / 105 | 800 |
| Audi | RS e-tron GT performance | serie 2024 | 250 | 680 (LC) | 1027 | 2 × PSM; spate cutie 2 trepte | 97 / 105 | 800 |
| Lotus | Emeya R | serie 2024 | 256 | 675 | 985 | 2 motoare (față + spate) | 102 | 800 |
| Tesla | Model S Plaid | serie 2021 | 322 | 760 | 1420 | 3 × PMSM, 1 față + 2 spate | ≈96 | ≈400 |
| Lucid | Air Sapphire | serie 2023 | 330 | ≈920 | ≈1939 | 3 × PMSM, 1 față + 2 spate | 118 | 900+ |
| Xiaomi | SU7 Ultra | serie 2025 | 350 | 1138 | 1770 | 2 × V8s + 1 × V6s | 93,7 | 897 |
| BYD (Yangwang) | U9 | serie 2024 | 309 | 960 | 1680 | 4 × 240 kW, câte unul pe roată | 80 (LFP) | 800 |
| Rimac | Nevera | serie 2021 | 412 | 1408 | 2360 | 4 × PMSM (2 × 220 + 2 × 480 kW) | 120 | 730 |
| Maserati | GranTurismo Folgore | serie 2023 | 325 | 560 | 1350 | 3 × PMSM × 300 kW | 83 / 92,5 | 800 |

LC = Launch Control. Datele complete (0–100 km/h, masă, consum, Cx, observații, sursă) sunt în fișierul Excel.

## Observații pentru etapele următoare

- **Etapa 3 cere un vehicul de serie.** Concept GT XX nu este produs în serie; versiunea de serie este
  Mercedes-AMG GT 63 (sau GT 55) 4-Door Coupé, care păstrează arhitectura conceptului: trei motoare cu flux axial,
  două pe puntea spate (fiecare cu reductor planetar) și unul pe puntea față, baterie de 800 V.
- **Puterea nominală vs. de vârf.** Producătorii publică aproape doar puterea de vârf (adesea doar cu Launch Control).
  Puterea continuă (30 min, UNECE R85) apare doar la Audi (163 kW); pentru vehiculul ales se găsește în certificatul
  de conformitate (CoC).
- **Date pentru calculul din etapa 5** (din cursul C1 – dinamica longitudinală): pentru GT 63 avem deja
  M ≈ 2460–2535 kg, Cx = 0,22, v_max = 300 km/h, 0–100 km/h în 2,1 s. Mai trebuie găsite aria frontală,
  raza dinamică a roții și rapoartele de transmisie.
- Valorile marcate „S” (sursă secundară) în Excel trebuie verificate pe pagina producătorului înainte de predare.
