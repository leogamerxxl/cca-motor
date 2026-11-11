# Modelele Simulink ale proiectului (MATLAB R2023b)

Toate modelele se **construiesc automat** din scripturi (blocurile, parametrii și legăturile sunt create cu
`add_block` / `set_param` / `add_line`), apoi se simulează și se compară cu calculele Matlab din etapele 3 și 4.
După rulare, fișierele `.slx` din [`modele/`](modele) se deschid ca orice model Simulink și pot fi modificate.
Valorile din blocuri sunt cele calculate în proiect (nu se introduc de mână): `parametri_simulink.m` le ia din
scripturile etapelor 2–4.

## Cerințe

- MATLAB **R2023b** (sau mai nou, până la R2025b) cu **Simulink** și **Simscape Electrical** – biblioteca
  **Specialized Power Systems** (`sps_lib`, cu `powergui`), aceeași cu care sunt făcute exemplele de curs
  (`MCC_CCA.slx`, `Buck_Model 1.slx`, `Boost_Model 1.slx`). Modelul C3 (`c3_A`, `c3_D`) are nevoie doar de Simulink.
- Folderul întregului depozit (scripturile citesc datele din `etapa2-calcule`, `etapa3-tema-motor`, `etapa4-convertoare`).

## Rulare

În MATLAB, în folderul `simulink/`:

```matlab
ruleaza_simulink                         % toate modelele
MODELE = {'c3_A', 'masina'}; ruleaza_simulink   % doar unele
```

Fiecare model se rulează separat (o eroare la un model nu le oprește pe celelalte). La final se afișează un rezumat,
iar în [`rezultate/`](rezultate) apar: `jurnal_simulink.txt` (tot ce s-a afișat), `rezultate_simulink.json` și câte o
figură PNG pentru fiecare model.

| Cheie | Model (`modele/*.slx`) | Ce conține | Comparat cu | Durata estimată |
|---|---|---|---|---|
| `c3_A` | `cca_c3_mcc_A` | C3, ex. 2: ecuațiile MCC cu blocuri Simulink (Sum, Gain, Integrator, Product, Sign, MinMax), cuplul la ax, slăbirea câmpului; pornire în gol la U_p + treaptă de sarcină | `rk4.m` (același algoritm, ode4) | secunde |
| `c3_D` | `cca_c3_mcc_D` | același model, rampă de tensiune cu sarcina vehiculului | `rk4.m` | secunde |
| `masina` | `cca_sps_masina_ym720` | blocul **DC Machine** (magneți permanenți) cu parametrii YM720 echivalenți: R_a, L_a, k, J, B_m = F_v, T_f = T_f0 (ca în `MCC_CCA.slx`) | `rk4.m` și valorile teoretice | secunde |
| `dcdc` | `cca_sps_dcdc_bidirectional` | baterie + DC-DC bidirecțional cu 4 faze (MOSFET, bobine, condensator), PI tensiune → PI curent → PWM intercalat; treaptă tracțiune → recuperare | `sim_dcdc_comutatie.m` | ~1 min |
| `incarcator` | `cca_sps_incarcator_cccv` | coborâtor cu MOSFET + diodă, curent reglat prin histerezis (Relay), PI de tensiune (CC-CV), baterie R + C (timp scalat), oprire la I_tăiere | `sim_incarcare_comutatie.m` | ~1 min |
| `ansamblu` | `cca_sps_ansamblu` | sistemul complet: baterie → DC-DC 4 faze → punte H → DC Machine + sarcina vehiculului; ciclul P3 cu regulator de viteză și de curent, frânare recuperativă | `simulare_ansamblu.m` (model mediu) | câteva minute |

Ciclul simulat pe ansamblu are palierul de 50 km/h scurtat la 2 s (`model_sps_ansamblu(P, t_palier, Ts)` permite alte
valori; durata de calcul crește proporțional).

## Cum sunt construite

- `biblioteci.m` – căile blocurilor (pentru fiecare bloc sunt date variantele `sps_lib/...` și `sps...Lib/...`,
  verificate în modelele de curs și în documentația R2023b);
- `bloc.m`, `leaga.m` – adăugarea unui bloc cu parametrii și legarea porturilor (inclusiv bornele fizice LConn/RConn);
- `adauga_dcdc.m` – bateria și DC-DC-ul, folosite de modelele `dcdc` și `ansamblu`;
- `powergui` în modul **Discrete** pentru circuitele cu comutație (pasul = pasul simulărilor Matlab, 0,25 µs pentru
  convertoare, 2 µs pentru ansamblu), rezolvitor cu pas fix `ode4`;
- măsurile folosite de regulatoare trec printr-o întârziere de un pas (`Unit Delay`), ca în simulările Matlab și ca
  să nu apară bucle algebrice;
- polaritatea surselor de curent comandate (sarcina DC-DC și „celelalte două motoare”) este verificată după simulare;
  dacă este inversă, modelul se reconstruiește automat cu bornele schimbate.

## Starea verificării

Scripturile **nu au putut fi rulate în Simulink** în mediul în care au fost scrise (nu există MATLAB/Simulink).
Au fost verificate astfel:

1. calculele de referință (etapele 3 și 4) – în GNU Octave și independent în Python, cu rezultate identice;
2. **structura modelelor** – în GNU Octave, cu un simulator al funcțiilor `add_block` / `set_param` / `add_line` /
   `sim` ([`verificare_octave/`](verificare_octave)): căile blocurilor, valorile permise ale parametrilor importanți,
   ordinea parametrilor la DC Machine (`PresetModel = 'No'` înainte de restul), existența porturilor, intrări și borne
   nelegate și lista nodurilor electrice ale fiecărui circuit;
3. numele de blocuri, parametri și opțiuni – față de modelele de curs (XML din `.slx`) și documentația R2023b.

Dacă la rularea în MATLAB apare o eroare, mesajul indică blocul și parametrul (de exemplu
`Blocul "Masina": FieldType = "Permanent magnet" nu a putut fi setat: ...`), iar tot jurnalul este în
`rezultate/jurnal_simulink.txt`.
