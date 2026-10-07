"""Build the Stage 1 (Documentare) workbook for the CCA project."""
import sys
from openpyxl import Workbook
from openpyxl.comments import Comment
from openpyxl.formatting.rule import FormulaRule
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

OUT = sys.argv[1]

FONT = "Arial"
BLUE = "0000FF"  # hardcoded inputs (date preluate din surse)
F_BASE = Font(name=FONT, size=10)
F_INPUT = Font(name=FONT, size=10, color=BLUE)
F_BOLD = Font(name=FONT, size=10, bold=True)
F_HEAD = Font(name=FONT, size=10, bold=True, color="FFFFFF")
F_TITLE = Font(name=FONT, size=14, bold=True)
F_NOTE = Font(name=FONT, size=9, italic=True, color="555555")
FILL_HEAD = PatternFill("solid", fgColor="1F3864")
FILL_REF = PatternFill("solid", fgColor="FFF2CC")  # rândurile vehiculului ales
FILL_BAR = PatternFill("solid", fgColor="2F75B5")
FILL_TEST = PatternFill("solid", fgColor="C00000")
FILL_VAC = PatternFill("solid", fgColor="D9D9D9")
THIN = Side(style="thin", color="A6A6A6")
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)
WRAP = Alignment(wrap_text=True, vertical="top")
CENTER = Alignment(horizontal="center", vertical="center", wrap_text=True)

wb = Workbook()

# ---------------------------------------------------------------- Tabel
ws = wb.active
ws.title = "Tabel comparativ"

ws["A1"] = "Etapa 1 – Documentare: acționări electrice pe automobile electrice de înaltă performanță (GT / super-sport)"
ws["A1"].font = F_TITLE
ws["A2"] = ("Vehicul ales: Mercedes-AMG Concept GT XX (concept, iunie 2025) și versiunea sa de serie, "
            "Mercedes-AMG GT 63 4MATIC+ 4-Door Coupé (platforma AMG.EA, prezentat mai 2026). "
            "Date culese la 07.10.2026.")
ws["A2"].font = F_BASE
ws["A3"] = ("Legendă: text albastru = valoare preluată din sursă; text negru = formulă. "
            "Încredere: O = sursă oficială a producătorului, S = sursă secundară (presă / baze de date). "
            "n.d. = nedeclarat / negăsit. Rândurile galbene = vehiculul ales.")
ws["A3"].font = F_NOTE

headers = [
    "Nr.", "Producător", "Model", "Stadiu / an", "Viteză max. [km/h]",
    "Putere max. (vârf) [kW]", "Putere max. [CP]", "Cuplu max. [Nm]", "0–100 km/h [s]",
    "Motoare electrice (nr., tip, dispunere)", "Transmisie", "Baterie [kWh]",
    "Tensiune sistem [V]", "Masă proprie [kg]", "Consum energie [kWh/100 km]", "Cx",
    "Încredere", "Observații",
]
HR = 5
for c, h in enumerate(headers, 1):
    cell = ws.cell(row=HR, column=c, value=h)
    cell.font = F_HEAD
    cell.fill = FILL_HEAD
    cell.alignment = CENTER
    cell.border = BORDER

# producer, model, stage, vmax, kW, Nm, 0-100, motors, transmission, battery, V, mass, consumption, Cx, trust, notes
# Numbers stay numeric where the source gives one value; ranges/qualified values are text.
rows = [
    ("Mercedes-AMG", "Concept AMG GT XX", "Concept (06/2025)", 360, 1000, "n.d.", "n.d.",
     "3 motoare sincrone cu flux axial (YASA): 2 pe puntea spate + 1 pe puntea față, integrate în 2 unități HP.EDU (motor + reductor + invertor)",
     "Spate: câte un set planetar compact pentru fiecare motor (o carcasă comună); față: reductor cu roți dințate cilindrice + unitate de decuplare (DCU)",
     "≈114", ">800", "n.d.", "n.d.", 0.198, "O / S",
     "Valori declarate pentru concept: v_max >360 km/h, P >1000 kW, încărcare DC >850 kW (medie), Cx 0,198, arie frontală 2,24 m², "
     ">3000 celule cilindrice NCMA. Record Nardò 08/2025: 5479 km în 24 h; 40 075 km în 7 zile 13 h 24 min. "
     "Mercedes nu publică capacitatea bateriei și cuplul conceptului – ≈114 kWh provine din presă (S)."),
    ("Mercedes-AMG", "GT 63 4MATIC+ 4-Door Coupé (AMG.EA)", "Serie (prezentat 05/2026)", 300, 860, 2000, 2.4,
     "3 motoare sincrone cu flux axial (YASA, fabricate la Berlin-Marienfelde): 2 spate + 1 față, în unități HP.EDU; 3 invertoare SiC",
     "Spate: reductor planetar cu o treaptă, carcasă comună pentru cele 2 motoare; față: reductor cu roți dințate cilindrice + unitate de decuplare (DCU)",
     "106 (net)", 800, 2460, "17,9–21,0", 0.22, "O",
     "860 kW = putere de vârf cu AMG Launch Control la 80 % SoC; putere continuă 530 kW; boost 63 s. 0–100 km/h: 2,4 s "
     "(2,1 s cu „1-foot rollout”); 0–200 km/h: 6,8 s (6,4 s). v_max 300 km/h cu Driver's Package. Masa = DIN (fără șofer); "
     "≈2535 kg în varianta UE cu șofer de 75 kg. Arie frontală 2,44 m². 2660 celule cilindrice NCMA răcite direct în ulei; DC 600 kW. "
     "WLTP 596–696 km. GT 55: 600 kW (continuu 375 kW), 1800 Nm, 2,8 s (2,5 s rollout), 2460 kg, 17,8–21,0 kWh/100 km, WLTP 597–700 km."),
    ("Porsche", "Taycan Turbo GT (pachet Weissach)", "Serie (2024)", 305, 760, 1240, 2.2,
     "2 motoare sincrone cu magneți permanenți (PSM): 1 față + 1 spate; invertor spate cu SiC, 900 A",
     "Față: o treaptă; spate: cutie de viteze cu 2 trepte",
     "97 net / 105 brut", 800, 2220, "20,6–21,3", 0.31, "O",
     "580 kW putere maximă; 760 kW overboost cu Launch Control (815 kW timp de 2 s); Attack Mode +120 kW / 10 s. "
     "Date pentru pachetul Weissach (fișa tehnică UE 03/2024): masă DIN, arie frontală 2,35 m², anvelope 265/35 ZR21 / 305/30 ZR21."),
    ("Audi", "RS e-tron GT performance", "Serie (2024)", 250, 680, 1027, 2.5,
     "2 motoare sincrone cu magneți permanenți: 1 față + 1 spate",
     "Față: o treaptă; spate: cutie de viteze cu 2 trepte",
     "97 net / 105 brut", 800, 2320, "18,7–20,8", 0.26, "O",
     "550 kW nominal / 680 kW cu Launch Control; push-to-pass +70 kW / 10 s. Cuplu motoare față / spate: 409 / 590 Nm. "
     "Putere continuă declarată: 163 kW. Masa = fără șofer (2395 kg cu șofer); arie frontală 2,35 m²."),
    ("Lotus", "Emeya R", "Serie (2024)", 256, 675, 985, 2.78,
     "2 motoare electrice: 1 față + 1 spate (tracțiune integrală)",
     "Față: o treaptă; spate: cutie cu 2 trepte (doar la versiunea 900 Sport Carbon; 900 Sport are o treaptă și spate)",
     "102 (brut)", "705 (nominal)", 2565, "17,7–22,4 (gama Emeya)", "n.d.", "O / S",
     "Putere, cuplu, v_max, 0–100, baterie, tensiune nominală (705 V; „arhitectură 800 V” în marketing), transmisie și autonomia "
     "WLTP 435–485 km sunt din fișa de presă Lotus. Masa (S) nu este publicată de Lotus; consumul oficial este dat doar pentru toată gama."),
    ("Tesla", "Model S Plaid", "Serie (2021)", 322, 760, 1420, 2.1,
     "3 motoare sincrone cu magneți permanenți: 1 față + 2 spate (câte unul pe roată)",
     "Reductor cu o treaptă pentru fiecare unitate de acționare",
     "≈96 (util)", "≈400", 2178, "≈15,7", 0.208, "S",
     "322 km/h cu Track Package; arhitectură de 400 V (singura din tabel); încărcare DC 250 kW; autonomie WLTP ≈611 km."),
    ("Lucid", "Air Sapphire", "Serie (2023)", 330, 908, 1940, "1,89 (0–96 km/h)",
     "3 motoare sincrone cu magneți permanenți: 1 față + 2 spate",
     "O treaptă: raport 7:1 (față), 6,8:1 (spate)",
     "118", "900+", 2420, "≈17,2 (EPA)", "n.d.", "O",
     "Fișa tehnică 2024: 1234 hp (908 kW), 1430 lb-ft (1940 Nm), v_max 205 mph, masă 5336 lb. Anvelope 265/35R20 / 295/30R21. "
     "Consumul este calculat din eficiența EPA de 3,61 mi/kWh (nu WLTP)."),
    ("Xiaomi", "SU7 Ultra", "Serie (2025)", 350, 1138, 1770, 1.98,
     "3 motoare: 2 × HyperEngine V8s (425 kW, 635 Nm, 27 200 rpm) + 1 × V6s (288 kW)",
     "Reductor cu o treaptă pentru fiecare motor",
     "93,7 net / 95 brut", 897, 2360, "≈16,5 (CLTC)", "n.d.", "S",
     "Baterie CATL Qilin 2.0 (putere maximă de descărcare 1330 kW). Consumul este pe ciclul chinezesc CLTC (nu WLTP); "
     "Cx-ul versiunii Ultra (cu eleron) nu este publicat (0,195 este valoarea SU7 standard)."),
    ("BYD (Yangwang)", "U9", "Serie (2024)", 309, 960, 1680, 2.36,
     "4 motoare × 240 kW, câte unul pe fiecare roată (platforma e4)",
     "n.d.",
     "80 (LFP Blade)", 800, 2475, "n.d.", "n.d.", "O / S",
     "Comunicat BYD: ≈1300 CP, 1680 Nm, 309,19 km/h, 0–100 km/h 2,36 s, 4 motoare independente (O); masa, tensiunea și bateria sunt din surse secundare. Varianta U9 Track Edition / Xtreme: 1200 V, >2200 kW, 496,22 km/h (09/2025, record într-un singur sens)."),
    ("Rimac", "Nevera", "Serie (2021, 150 ex.)", 412, 1408, 2340, 1.81,
     "4 motoare sincrone cu magneți permanenți (rotor cu manșon din carbon): față 2 × 220 kW / 280 Nm, spate 2 × 480 kW / 900 Nm; 4 invertoare",
     "Față: 2 reductoare cu o treaptă (la capetele punții); spate: reductor dublu cu o treaptă (2 reductoare într-o carcasă)",
     "120", "730 (max.)", 2300, "30,0 (WLTP)", 0.30, "O",
     "6960 celule cilindrice 21700; încărcare DC 500 kW; autonomie WLTP 490 km. Cuplu la motoare 2340 Nm, la roți 13 430 Nm. "
     "0–100 km/h cu „1-foot rollout”. Cx 0,30 în modul low-drag. Pagina web Rimac indică 226 / 450 kW pe motor (fișa PDF: 220 / 480 kW)."),
    ("Maserati", "GranTurismo Folgore", "Serie (2023)", 325, 560, 1350, 2.7,
     "3 motoare sincrone cu magneți permanenți × 300 kW: 1 față + 2 spate",
     "n.d.",
     "83 net / 92,5 brut", 800, 2260, "n.d.", "n.d.", "O / S",
     "Putere limitată de baterie la 560 kW (≈610 kW în regim de boost, sursă secundară). Masa 2260 kg = „masă omologată” din "
     "comunicatul Stellantis (citit doar prin motorul de căutare; site-urile Maserati / Stellantis blochează accesul automat). "
     "Cx raportat diferit (0,26 / 0,27) – nepreluat."),
]

first = HR + 1
for i, r in enumerate(rows):
    row = first + i
    (prod, model, stage, vmax, kw, nm, acc, motors, trans, batt, volt, mass, cons, cx, trust, note) = r
    values = [i + 1, prod, model, stage, vmax, kw, None, nm, acc, motors, trans, batt, volt, mass, cons, cx, trust, note]
    for c, v in enumerate(values, 1):
        cell = ws.cell(row=row, column=c, value=v)
        cell.border = BORDER
        cell.alignment = WRAP
        cell.font = F_INPUT if c not in (1, 7) else F_BASE
    # CP derived from kW with the metric horsepower factor (input cell below the table)
    ws.cell(row=row, column=7, value=f"=ROUND(F{row}*$C${first + len(rows) + 2},0)")
    ws.cell(row=row, column=7).font = F_BASE
    if i < 2:
        for c in range(1, len(headers) + 1):
            ws.cell(row=row, column=c).fill = FILL_REF

last = first + len(rows) - 1

# Concept values are lower bounds ("peste"), shown with a ">" prefix.
ws.cell(row=first, column=5).number_format = '">"0'
ws.cell(row=first, column=6).number_format = '">"#,##0'
ws.cell(row=first, column=7).number_format = '">"#,##0'
for row in range(first + 1, last + 1):
    ws.cell(row=row, column=6).number_format = "#,##0"
    ws.cell(row=row, column=7).number_format = "#,##0"
for row in range(first, last + 1):
    ws.cell(row=row, column=16).number_format = "0.000"
    if isinstance(ws.cell(row=row, column=9).value, float):
        ws.cell(row=row, column=9).number_format = "0.00"

# Factor + summary block (factor_row must match the CP formula above)
factor_row = first + len(rows) + 2
ws.cell(row=factor_row - 1, column=2, value="Factor conversie kW → CP (cal-putere metric):").font = F_BOLD
ws.cell(row=factor_row, column=2, value="1 kW =").font = F_BASE
ws.cell(row=factor_row, column=3, value=1.35962).font = F_INPUT
ws.cell(row=factor_row, column=4, value="CP (1 CP = 0,73549875 kW)").font = F_BASE

sr = factor_row + 2
ws.cell(row=sr, column=2, value="Sinteză (vehicule de serie, rândurile 2–11)").font = F_BOLD
stats = [
    ("Număr de producători în tabel", f"=SUMPRODUCT(1/COUNTIF(B{first}:B{last},B{first}:B{last}))", "0"),
    ("Putere de vârf medie [kW]", f"=AVERAGE(F{first + 1}:F{last})", "#,##0"),
    ("Putere de vârf maximă [kW]", f"=MAX(F{first + 1}:F{last})", "#,##0"),
    ("Viteză maximă medie [km/h]", f"=AVERAGE(E{first + 1}:E{last})", "0"),
    ("Cuplu mediu [Nm]", f"=AVERAGE(H{first + 1}:H{last})", "#,##0"),
    ("Vehicule cu arhitectură ≥800 V", f'=COUNTIF(M{first + 1}:M{last},">=800")+COUNTIF(M{first + 1}:M{last},"900+")', "0"),
]
for k, (label, formula, fmt) in enumerate(stats, 1):
    ws.cell(row=sr + k, column=2, value=label).font = F_BASE
    c = ws.cell(row=sr + k, column=5, value=formula)  # C:D left empty so the label stays readable
    c.font = F_BASE
    c.number_format = fmt

widths = [5, 15, 26, 16, 11, 12, 10, 10, 10, 42, 30, 14, 11, 12, 14, 7, 10, 60]
for c, w in enumerate(widths, 1):
    ws.column_dimensions[get_column_letter(c)].width = w
ws.row_dimensions[HR].height = 42
ws.freeze_panes = ws.cell(row=first, column=4)

ws.cell(row=HR, column=6).comment = Comment(
    "Producătorii publică puterea de vârf (pe durată scurtă, adesea doar cu Launch Control). "
    "Puterea nominală / continuă (30 min, Regulamentul UNECE R85) apare rar în materialele de presă – "
    "se găsește în certificatul de conformitate (CoC) al vehiculului.", "Etapa 1")
ws.cell(row=HR, column=15).comment = Comment(
    "Cerința din fișă: „putere dezvoltată / consumată”. Puterea dezvoltată = coloana F; "
    "pentru partea consumată s-a folosit consumul de energie WLTP (dacă nu e altfel notat).", "Etapa 1")

# ---------------------------------------------------------------- Gantt
g = wb.create_sheet("Gantt")
g["A1"] = "Diagrama Gantt – Proiect CCA (Concepția Asistată de Calculator a Acționărilor Electrice)"
g["A1"].font = F_TITLE
g["A2"] = ("Ipoteze: o ședință de proiect pe săptămână, miercurea, începând cu 07.10.2026; durata etapelor din fișa proiectului "
           "(1s = o ședință/săptămână). Vacanța de iarnă 24.12.2026–03.01.2027 conform structurii naționale a anului universitar – "
           "de confirmat cu orarul UPB. Modificați coloana „Durată” și diagrama se actualizează.")
g["A2"].font = F_NOTE
g.merge_cells("A2:T2")
g.row_dimensions[2].height = 40
g["A2"].alignment = WRAP

GH = 4
N_SESS = 14
gh = ["Nr.", "Etapă", "Durată [ședințe]", "Ședința de început", "Ședința de final", "Livrabil"]
for c, h in enumerate(gh, 1):
    cell = g.cell(row=GH, column=c, value=h)
    cell.font = F_HEAD
    cell.fill = FILL_HEAD
    cell.alignment = CENTER
    cell.border = BORDER
SC = len(gh) + 1  # first session column
for s in range(N_SESS):
    col = SC + s
    cell = g.cell(row=GH, column=col, value=s + 1)
    cell.font = F_HEAD
    cell.fill = FILL_HEAD
    cell.alignment = CENTER
    cell.border = BORDER
    d = g.cell(row=GH + 1, column=col)
    L = get_column_letter(col)
    prev = get_column_letter(col - 1)
    if s == 0:
        d.value = "=DATE(2026,10,7)"
        d.font = F_INPUT
    elif s == 12:
        # session 13 comes after the winter holiday (Dec 30 falls inside it)
        d.value = f"={prev}{GH + 1}+14"
        d.font = F_BASE
        d.comment = Comment("+14 zile: miercurea 30.12.2026 cade în vacanța de iarnă.", "Etapa 1")
    else:
        d.value = f"={prev}{GH + 1}+7"
        d.font = F_BASE
    d.number_format = "dd.mm"
    d.alignment = CENTER
    d.border = BORDER
    g.column_dimensions[L].width = 6.5
g.cell(row=GH + 1, column=2, value="Data ședinței →").font = F_BOLD

stages = [
    # (label, duration, start rule, deliverable)
    ("1. Documentare", 1, "first", "Tabel comparativ (min. 7 producători) + diagrama Gantt"),
    ("2. Formularea temei", 2, "next", "Tema de proiectare: cerințe și specificații"),
    ("3. Caz real: acționare electrică pe vehicul de serie", 2, "parallel", "Alegerea vehiculului de serie (în paralel cu etapa 2)"),
    ("Test 1", 0, "test:2", "Test individual (max. 10 p)"),
    ("4. Schema acționării", 2, "after:2", "Schema bloc a acționării"),
    ("Test 2", 0, "test:5", "Test individual (max. 10 p)"),
    ("5. Calcul și simulare", 3, "next", "Calcul de dimensionare + model MATLAB/Simulink"),
    ("Test 3", 0, "test:7", "Test individual (max. 10 p)"),
    ("6. Elaborarea raportului tehnic", 2, "next", "Raport tehnic (redactare individuală)"),
    ("7. Realizarea prezentării", 1, "next", "Prezentare"),
    ("8. Susținerea prezentării", 2, "next", "Susținere în fața grupei (max. 50 p)"),
]
r0 = GH + 2
rowmap = {}
prev_stage_row = None
for i, (label, dur, rule, deliv) in enumerate(stages):
    row = r0 + i
    rowmap[i + 1] = row
    is_test = rule.startswith("test")
    if not is_test:
        g.cell(row=row, column=1, value=int(label.split(".")[0]))
    g.cell(row=row, column=2, value=label)
    g.cell(row=row, column=6, value=deliv)
    if is_test:
        ref = rowmap[int(rule.split(":")[1])]
        g.cell(row=row, column=3, value=0)
        g.cell(row=row, column=4, value=f"=E{ref}")
        g.cell(row=row, column=5, value=f"=E{ref}")
    else:
        g.cell(row=row, column=3, value=dur).font = F_INPUT
        if rule == "first":
            g.cell(row=row, column=4, value=1).font = F_INPUT
        elif rule == "parallel":
            g.cell(row=row, column=4, value=f"=D{prev_stage_row}")
        elif rule.startswith("after"):
            ref = rowmap[int(rule.split(":")[1])]
            g.cell(row=row, column=4, value=f"=E{ref}+1")
        else:
            g.cell(row=row, column=4, value=f"=E{prev_stage_row}+1")
        g.cell(row=row, column=5, value=f"=D{row}+C{row}-1")
        prev_stage_row = row
    input_cols = set() if is_test else ({3, 4} if rule == "first" else {3})
    for c in range(1, SC):
        cell = g.cell(row=row, column=c)
        cell.border = BORDER
        cell.alignment = WRAP if c in (2, 6) else CENTER
        cell.font = F_INPUT if c in input_cols else (F_BOLD if is_test else F_BASE)
    for s in range(N_SESS):
        col = SC + s
        cell = g.cell(row=row, column=col,
                      value=f"=IF(AND({get_column_letter(col)}${GH}>=$D{row},{get_column_letter(col)}${GH}<=$E{row}),1,0)")
        cell.number_format = ";;;"  # hide the 0/1 flag; colour comes from conditional formatting
        cell.border = BORDER

last_g = r0 + len(stages) - 1
bar_rng = f"{get_column_letter(SC)}{r0}:{get_column_letter(SC + N_SESS - 1)}{last_g}"
first_cell = f"{get_column_letter(SC)}{r0}"
g.conditional_formatting.add(bar_rng, FormulaRule(formula=[f'AND({first_cell}=1,$C{r0}=0)'], fill=FILL_TEST, stopIfTrue=True))
g.conditional_formatting.add(bar_rng, FormulaRule(formula=[f'{first_cell}=1'], fill=FILL_BAR))

vr = last_g + 1
g.cell(row=vr, column=2, value="Vacanța de iarnă (24.12.2026–03.01.2027)").font = F_NOTE
g.cell(row=vr, column=6, value="Fără ședințe între ședințele 12 și 13").font = F_NOTE
lr = vr + 2
g.cell(row=lr, column=2, value="Legendă:").font = F_BOLD
g.cell(row=lr + 1, column=2, value="Etapă de lucru").font = F_BASE
g.cell(row=lr + 1, column=3).fill = FILL_BAR
g.cell(row=lr + 2, column=2, value="Test individual").font = F_BASE
g.cell(row=lr + 2, column=3).fill = FILL_TEST
g.cell(row=lr + 3, column=2, value="Total ședințe ocupate de etape (fără etapa 3, paralelă):").font = F_BASE
tot = g.cell(row=lr + 3, column=4,
             value=f"=SUM(C{r0}:C{last_g})-C{rowmap[3]}")
tot.font = F_BASE
g.cell(row=lr + 4, column=2, value="Ședința 14 rămâne rezervă (recuperări / susțineri restante).").font = F_NOTE

g.column_dimensions["A"].width = 5
g.column_dimensions["B"].width = 40
g.column_dimensions["C"].width = 10
g.column_dimensions["D"].width = 11
g.column_dimensions["E"].width = 11
g.column_dimensions["F"].width = 44
g.row_dimensions[GH].height = 32
g.freeze_panes = g.cell(row=GH + 2, column=SC)

# ---------------------------------------------------------------- Surse
s = wb.create_sheet("Surse")
s["A1"] = "Surse (accesate 07.10.2026; verificare directă a paginilor producătorilor la 07.10.2026)"
s["A1"].font = F_TITLE
s["A2"] = ("Notă: Mercedes, Porsche, Audi, Lotus, Lucid, Rimac și BYD au fost verificate direct pe documentele producătorului. "
           "Tesla, Maserati și Xiaomi blochează accesul automat – valorile lor rămân parțial S. "
           "Datele de concept nu sunt valori omologate.")
s["A2"].font = F_NOTE
sources = [
    ("Mercedes-AMG Concept GT XX", "mercedes-amg.com – Concept AMG GT XX", "https://www.mercedes-amg.com/en/concept-amg-gt-xx"),
    ("Mercedes-AMG Concept GT XX", "Mercedes-Benz Group – încărcare MW, AMG GT XX", "https://group.mercedes-benz.com/technology/e-mobility/charging/megawatt-charging-amg-gt-xx.html"),
    ("Mercedes-AMG Concept GT XX", "Design News – trei motoare cu flux axial", "https://www.designnews.com/automotive-engineering/mercedes-concept-amg-gt-xx"),
    ("Mercedes-AMG Concept GT XX", "Motor1 – Concept GT XX (Cx 0,198, baterie)", "https://www.motor1.com/news/763606/amg-gt-xx-concept-first-look/"),
    ("Mercedes-AMG Concept GT XX", "Interesting Engineering – record Nardò", "https://interestingengineering.com/photo-story/mercedes-amg-ev-concept-breaks-records"),
    ("Mercedes-AMG Concept GT XX", "Driven (NZ) – arhitectura HP.EDU", "https://www.drivencarguide.co.nz/news/mercedes-amgs-concept-amg-gt-xx-packs-serious-tech-under-throwback-looks/"),
    ("Mercedes-AMG Concept GT XX", "Mercedes-Benz Media – comunicat CONCEPT AMG GT XX (date tehnice, Cx, arie frontală)", "https://media.mercedes-benz.com/en/article/dc62bb92-5082-42f1-bc9a-c838bc09e985"),
    ("Mercedes-AMG Concept GT XX", "Mercedes-Benz Media – recorduri Nardò 08/2025", "https://media.mercedes-benz.com/en/article/b2d73049-f14b-4019-8da3-a0dd5e6dfb89"),
    ("Mercedes-AMG GT 63 4-Door Coupé", "Mercedes-Benz Media – comunicat de lansare 20.05.2026 (tabele tehnice GT 63 / GT 55)", "https://media.mercedes-benz.com/en/article/c8b7109f-2287-4070-b776-9204da1513ef"),
    ("Mercedes-AMG GT 63 4-Door Coupé", "Mercedes-Benz Media – start comenzi 27.05.2026 (consum WLTP, nota „1-foot rollout”)", "https://media.mercedes-benz.com/article/f037de81-64ba-4236-b555-75a5f4c3a56b"),
    ("Mercedes-AMG GT 63 4-Door Coupé", "Mercedes-Benz Media – motorul cu flux axial, HP.EDU cu reductor planetar", "https://media.mercedes-benz.com/en/article/bebac2af-acdc-465a-9538-adb0bf3d8ccf"),
    ("Mercedes-AMG GT 63 4-Door Coupé", "Mercedes-Benz Media – GT 53 4-Door Coupé (aceeași caroserie: arie frontală 2,44 m²)", "https://media.mercedes-benz.com/en/article/0955928c-b613-41b4-b754-08399bbfcccc"),
    ("Mercedes-AMG GT 63 4-Door Coupé", "mercedes-amg.com – GT 4-Door Coupé", "https://www.mercedes-amg.com/en/gt-4-door-coupe"),
    ("Mercedes-AMG GT 63 4-Door Coupé", "Mercedes-Benz – producția motorului cu flux axial (Berlin)", "https://group.mercedes-benz.com/company/production/news/axial-flux-motor-berlin.html"),
    ("Mercedes-AMG GT 63 4-Door Coupé", "electrive.com – prezentare 20.05.2026", "https://www.electrive.com/2026/05/20/electric-powerhouse-mercedes-amg-unveils-gt-4-door-coupe/"),
    ("Mercedes-AMG GT 63 4-Door Coupé", "Autocar India – GT 4-Door Coupé EV", "https://www.autocarindia.com/car-news/2026-mercedes-amg-gt-4-door-coupe-revealed-makes-up-to-1169hp-439771"),
    ("Mercedes-AMG GT 63 4-Door Coupé", "ArenaEV – fișă tehnică (masă, consum)", "https://www.arenaev.com/mercedes_amg_gt_4_door_coup%c3%a9_gt_63_2026-specs-986.php"),
    ("Mercedes-AMG GT 63 4-Door Coupé", "automobile-catalog – fișă tehnică", "https://www.automobile-catalog.com/car/2026/3653165/mercedes-amg_gt_63_4-door_coupe_ev.html"),
    ("Porsche Taycan Turbo GT", "Porsche Newsroom – Taycan Turbo GT", "https://newsroom.porsche.com/en/2024/products/porsche-the-new-taycan-turbo-gt-35479.html"),
    ("Porsche Taycan Turbo GT", "Porsche – date tehnice pachet Weissach (PDF)", "https://newsroom.porsche.com/dam/jcr:c96cbebc-3745-4700-b385-981a9c4fe91d/pag-taycan-turbo-gt-weissachpaket-td-en.pdf"),
    ("Porsche Taycan Turbo GT", "Porsche Newsroom – cel mai puternic Porsche de serie", "https://newsroom.porsche.com/en/2025/products/porsche-taycan-turbo-gt-most-powerful-poduction-porsche-38431.html"),
    ("Audi RS e-tron GT performance", "Audi – comunicat de presă", "https://www.audi.com/en/press-releases/audis-most-powerful-production-vehicle-the-new-rs-e-tron-gt-performance-16222"),
    ("Audi RS e-tron GT performance", "Audi MediaCenter – date tehnice (PDF)", "https://uploads.audi-mediacenter.com/system/production/car_motorizations/1392/file_en/91bfc69ec55530e277b5023245b77c1c82772920/eTD-Audi-RS-e-tron-GT-performance-550kW_250515.pdf"),
    ("Audi RS e-tron GT performance", "Audi Magazine Australia – 1027 Nm", "https://magazine.audi.com.au/article/peak-performance"),
    ("Lotus Emeya R", "Lotus – presă, specificații tehnice Emeya (putere, cuplu, transmisie, 705 V, WLTP)", "https://www.lotuscars.com/en/press/models/emeya"),
    ("Lotus Emeya R", "Lotus – pagina de specificații Emeya (consum WLTP gamă, „2 speed trans.”)", "https://www.lotuscars.com/en-GB/emeya/specifications"),
    ("Lotus Emeya R", "evkx.net – fișă tehnică (masă)", "https://evkx.net/models/lotus/emeya/emeya_r/specifications"),
    ("Lotus Emeya R", "CarNewsChina – baza de date", "https://data.carnewschina.com/database/lotus/lotus-emeya/2024"),
    ("Tesla Model S Plaid", "evkx.net – fișă tehnică (inclusiv Cx 0,208)", "https://evkx.net/models/tesla/model_s/model_s_plaid/specifications/"),
    ("Lucid Air Sapphire", "Lucid – specificații finale de producție", "https://lucidmotors.com/stories/final-production-specs-sapphire"),
    ("Lucid Air Sapphire", "Lucid – fișă tehnică 2024 (PDF)", "https://lucidmotors.com/media/document/lucid-air-sapphire-technical-specs-2024.pdf"),
    ("Xiaomi SU7 Ultra", "evkx.net – fișă tehnică", "https://evkx.net/models/xiaomi/su7/su7_ultra/specifications"),
    ("Xiaomi SU7 Ultra", "ZOL – parametri SU7 Ultra (consum CLTC 16,5 kWh/100 km)", "https://detail.zol.com.cn/2113/2112093/param.shtml"),
    ("Xiaomi SU7 Ultra", "CarNewsChina – lansare SU7 Ultra / V8s", "https://carnewschina.com/2024/07/19/new-xiaomi-su7-ultra-with-1548-horsepower-and-v8s-motor-unveiled-in-china"),
    ("Yangwang U9", "BYD – comunicat de lansare U9 (1680 Nm, 309,19 km/h, 2,36 s)", "https://www.byd.com/us/news-list/YANGWANG-Launched-the-U9-Priced-at-1-68-Million-RMB"),
    ("Yangwang U9", "autotijd.be – fișă tehnică", "https://autotijd.be/en/specs/yangwang/u9/960-kw-awd-4586"),
    ("Yangwang U9", "CarNewsChina – parametri", "https://data.carnewschina.com/database/yangwang/yangwang-u9/2024/params"),
    ("Yangwang U9", "Cars24 – record U9 Track Edition", "https://www.cars24.com.au/car-news/yangwang-u9-track-edition-sets-global-ev-speed-record/"),
    ("Rimac Nevera", "Rimac – specificații tehnice (PDF)", "https://cloudfront.rimac-automobili.com/wp-content/uploads/2023/11/20171226/Nevera_Technical-specifications.pdf"),
    ("Rimac Nevera", "Rimac – Nevera (consum WLTP 30,0 kWh/100 km, Cx 0,3)", "https://www.rimac-automobili.com/nevera/"),
    ("Maserati GranTurismo Folgore", "Maserati – GranTurismo Folgore", "https://www.maserati.com/us/en/models/granturismo/granturismo-folgore"),
    ("Maserati GranTurismo Folgore", "Stellantis Media – comunicat New Maserati GranTurismo (masă omologată 2260 kg; acces blocat, citit prin motor de căutare)", "https://www.media.stellantis.com/em-en/maserati/press/new-maserati-granturismo"),
    ("Maserati GranTurismo Folgore", "ArenaEV – fișă tehnică", "https://m.arenaev.com/maserati_granturismo_folgore_92kwh_2023-specs-amps-362.php"),
    ("Structura anului universitar", "Structura anului universitar 2026–2027 (model național)", "https://unarte.org/wp-content/uploads/2026/08/Structura-anului-universitar-2026-2027.pdf"),
]
for c, h in enumerate(["Vehicul", "Sursă", "URL"], 1):
    cell = s.cell(row=4, column=c, value=h)
    cell.font = F_HEAD
    cell.fill = FILL_HEAD
    cell.border = BORDER
for i, (veh, title, url) in enumerate(sources, 5):
    s.cell(row=i, column=1, value=veh).font = F_BASE
    s.cell(row=i, column=2, value=title).font = F_BASE
    u = s.cell(row=i, column=3, value=url)
    u.hyperlink = url
    u.font = Font(name=FONT, size=10, color="0563C1", underline="single")
    for c in range(1, 4):
        s.cell(row=i, column=c).border = BORDER
s.column_dimensions["A"].width = 32
s.column_dimensions["B"].width = 55
s.column_dimensions["C"].width = 110

for sheet in wb.worksheets:
    sheet.sheet_view.showGridLines = False
    sheet.page_setup.orientation = "landscape"
    sheet.page_setup.paperSize = sheet.PAPERSIZE_A4
    sheet.page_setup.fitToWidth = 1
    sheet.page_setup.fitToHeight = 0
    sheet.sheet_properties.pageSetUpPr.fitToPage = True
    sheet.page_margins.left = sheet.page_margins.right = 0.4

wb.save(OUT)
print("saved", OUT)
