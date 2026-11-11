# CCA – Proiect: sistem de propulsie electrică

Proiectul disciplinei *Concepția Asistată de Calculator a Acționărilor Electrice* (UPB). Vehicul de referință:
Mercedes-AMG GT 63 4MATIC+ 4-Door Coupé; tema este calculată pentru vehiculul mediu al celor 10 vehicule electrice
de serie din documentare.

**Prezentarea întregului proiect, cu toate calculele: [PREZENTARE_PROIECT.md](PREZENTARE_PROIECT.md)**

| Folder | Conținut | Suport de curs |
|---|---|---|
| [`etapa1-documentare`](etapa1-documentare) | Datele vehiculelor (registrul Excel cu surse) | P1 |
| [`etapa-calcul-1`](etapa-calcul-1) | Dinamica longitudinală a vehiculului de referință | C1 |
| [`etapa2-calcule`](etapa2-calcule) | Puterea mașinii electrice, energia pe ciclu, bateria (Matlab, Python, Excel) | P2, P3 |
| [`etapa3-tema-motor`](etapa3-tema-motor) | Tema de proiect, schema bloc, modelul MCC al mașinii, pierderi, hărți de randament, încălzire, simulări | P4, C3 |
| [`etapa4-convertoare`](etapa4-convertoare) | DC-DC bidirecțional, chopperul invertorului, încărcătorul CC-CV, simulări cu comutație | P5-P6 |
| [`simulink`](simulink) | Constructorii modelelor Simulink (MATLAB R2023b, Specialized Power Systems) | C3 ex. 2, P4–P6 |

Programele Matlab rulează și în GNU Octave 8; fiecare etapă are și o implementare Python independentă, cu care
rezultatele au fost comparate. Prezentarea se regenerează cu `python3 scripts/prezentare_proiect.py`.
