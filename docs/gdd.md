# Concept-world – Game Design Document (skelet)

## Vision
Et hyggeligt 3D park-management-spil inspireret af klassiske theme-park-spil. Byg forlystelser, stier og butikker, hold gæsterne glade og tjen penge.

## Kerneloop
Byg → gæster kommer → de bruger penge og får behov → du justerer priser, personale og udbud → udvid.

## Systemer (udfyldes af designer)
- Gæster: behov (sult, tørst, glæde, toilet, træthed), penge, beslutninger
- Forlystelser: kapacitet, varighed, kø, spænding, pris, nedbrud
- Butikker: varer, pris, kvalitet
- Personale: mekanikere, rengøring, underholdere
- Økonomi: indtægter, udgifter, lån
- Forskning (M5), scenarier (M5), rutsjebane-bygger (M5)

## Stil
Stiliseret low-poly 3D, varme farver, blød belysning. Kun egne/CC0-assets.

## M2 – Gæster, behov og økonomi

### Tid
- 20 ticks/s, `day_ticks` = 2400 → 1 dag ≈ 2 min realtid ved 1x.

### Behov (0..100, 100 = akut)
| Behov | rate/tick | threshold | Tid til threshold fra 0 |
|---|---|---|---|
| hunger | 0.03 | 60 | 2000 ticks (~0,8 dag) |
| thirst | 0.04 | 60 | 1500 ticks (~0,6 dag) |
| toilet | 0.02 | 70 | 3500 ticks (~1,5 dag), boder øger toilet |
| energy | 0.015 | 80 | ~5300 ticks (~2,2 dag) – træthed, gæsten går hjem |
Nye gæster starter med tilfældige behov 0–30. Ved et besøg på 1–2 dage bliver en gæst typisk sulten 1–2 gange og tørstig 2–3 gange.

### Gæsteloop (pr. beslutning, når gæsten står på en sti uden mål)
1. Find det behov med højest værdi over sin threshold.
2. Hvis et findes: gå til nærmeste **åbne** bygning hvis `satisfies[behov] < 0`, og som gæsten har råd til og vil betale for (se pris-vurdering). Tanke: "Jeg er sulten!", "Jeg er tørstig!", "Jeg skal tisse!".
3. Ellers: vælg en tilfældig åben forlystelse (vægtet efter excitement) som gæsten har råd til/vil betale for.
4. Ellers: gå tilfældigt rundt.
5. Ved endt besøg: læg `satisfies` til behov (clamp 0..100), læg `excitement` til glæde (clamp), træk pris fra penge.
6. Hvert tick hvor et behov er over threshold: glæde -= `happiness_decay_when_need_over_threshold` pr. behov over grænsen.
7. Forlad parken (gå til indgang) hvis glæde < `leave_happiness`, penge < billigste åbne pris, eller energy ≥ 100. Tanke: "Jeg vil hjem."

### Pris-vurdering (maks betalingsvilje)
- Forlystelse: `max_pris = 2 + excitement / 5` (karrusel 7, pariserhjul 9, radiobiler 11).
- Bod/toilet: `max_pris = basis_pris * (1 + behov / 100)`, hvor `basis_pris` er content-default `ticket_price` (sulten 80 → villig til 1,8× standardpris). Toilet med pris 0 er altid ok.
- Glæde-modifier: `max_pris *= 0.75 + happiness / 200` (glad gæst 100 → 1,25×, sur 0 → 0,75×).
- Er `price > max_pris`: gæsten afviser, tanke "For dyrt!", glæde -2, og vælger igen (ekskl. denne bygning) næste beslutning.

### Økonomi
- Start 2200; entré 6; sti 10 (refusion 5); gæster medbringer 30–80.
- Start-budget: karrusel 800 + burger 300 + drikke 250 + toilet 200 + ~25 stier (250) = 1800 → ~400 buffer.
- Drift pr. dag for start-park: 360 (~30% af omsætningen). Netto ca. +800/dag fra dag 2; investeringen er tjent hjem i løbet af dag 3.

#### Balance-rationale (T-026)
Balance-sim (`tools/balance.sh`, seed 12345, startpark):

| Dag | Penge | Gæster | Glæde | Karrusel/Burger/Drikke/Toilet | Entré | Billetter | Drift | Byg | Netto | Kumuleret | For dyrt! |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 961 | 29 | 81.3 | 99/9/10/10 | 354 | 546 | −360 | −1800 | −1260 | −1260 | 0 |
| 2 | 1765 | 46 | 81.9 | 106/37/42/34 | 360 | 814 | −360 | 0 | +814 | −446 | 0 |
| 3 | 2582 | 49 | 82.8 | 98/60/61/44 | 264 | 918 | −360 | 0 | +822 | +376 | 0 |
| 4 | 3384 | 48 | 81.3 | 88/62/72/50 | 258 | 904 | −360 | 0 | +802 | | 0 |
| 5 | 4230 | 48 | 81.8 | 103/46/53/36 | 348 | 858 | −360 | 0 | +846 | | 0 |

- Drift ×4–5 så den betyder noget (≈30% af omsætning) og hver ny bygning skal tjene sig selv ind.
- Entré 10→6: entré var ~45% af indtægten; nu ~25–30%, så forlystelser/boder driver økonomien.
- Start 2500→2200: første park er stram (~400 buffer).
- Hunger-rate 0.03→0.04 og `need_start_max` 30→40: boder bruges fra dag 1.
- Pris-konstanter skrives eksplicit i guests.json. Ved standardpriser ingen "For dyrt!" (karrusel max ≈ (2+25·0.2)·(0.75+0.005·82) ≈ 8.1 vs. pris 5); hæves priserne ~60%+ kommer de første afvisninger.
- Fjernelse af bygning refunderer 50% af build_cost.

### Bygninger
| id | kind | fp | pris (byg) | drift/dag | kap. | ticks | billet | excitement | satisfies |
|---|---|---|---|---|---|---|---|---|---|
| carousel | ride | 3×3 | 800 | 180 | 8 | 200 | 5 | 25 | energy -10 |
| ferris_wheel | ride | 3×3 | 1200 | 240 | 12 | 320 | 6 | 35 | energy -15 |
| bumper_cars | ride | 4×4 | 1500 | 280 | 10 | 240 | 7 | 45 | energy +10, thirst +10 |
| burger_stand | shop | 1×1 | 300 | 70 | 2 | 40 | 4 | 0 | hunger -70, thirst +10, toilet +15 |
| drinks_stand | shop | 1×1 | 250 | 60 | 2 | 30 | 3 | 0 | thirst -70, toilet +20 |
| ice_cream_stand | shop | 1×1 | 280 | 60 | 2 | 30 | 3 | 5 | hunger -25, thirst -20, toilet +10 |
| toilet | toilet | 1×1 | 200 | 50 | 2 | 60 | 0 | 0 | toilet -90 |

## Tiltrækning, omdømme og gæstestrøm (T-029)
Konstanter i `game/content/park.json`. Kun **åbne** bygninger tæller.

- `raw = Σ_rides excitement × weight_ride + antal(shops+toilets) × weight_facility`
- `attraction_score = sqrt(raw)` (faldende merværdi)
- `reputation` ∈ [0,100], start `reputation_start` (50). Når en gæst forlader parken: `reputation += (guest.happiness − reputation) × reputation_learn_rate` (0.0025 – T-034: en god park bygger omdømme over 1–2 uger; startpark ≈70 efter 5 dage).
- `expected_fee = expected_entry_fee_per_score × attraction_score`
- `price_penalty = clamp((entry_fee − expected_fee) / expected_fee × price_penalty_factor, 0, price_penalty_max)` (kun straf ved for høj entré; 0 hvis score = 0)
- `rep_mult = reputation_mult_base + reputation/100` (0.5..1.5; 1.0 ved start)
- `spawn_per_day = clamp(spawn_per_score × attraction_score × rep_mult × (1 − price_penalty), spawn_min_per_day, spawn_max_per_day)` hvis entré er forbundet til sti og ≥1 åben ride; ellers 0.
- `max_guests = max_guests_base + Σ capacity(åbne bygninger) × max_guests_per_capacity` (afrundet ned)
- Ankomst: hver tick spawnes en gæst med sandsynlighed `spawn_per_day / day_ticks` (seedet RNG), hvis `guests < max_guests`. Erstatter `spawn_interval_ticks`/`max_guests` i guests.json.

### Eksempeltabel (entré 6, gæster/dag)
| Park | score | forventet entré | straf | max_guests | omd. 30 | omd. 50 (start) | omd. 60 | omd. 90 |
|---|---|---|---|---|---|---|---|---|
| Kun karrusel | 5.00 | 5.0 | 0.20 | 36 | 26 | 32 | 35 | 45 |
| Startpark (karrusel+burger+drikke+toilet) | 6.32 | 6.3 | 0 | 48 | 40 | **51** | 56 | 71 |
| Alle 7 bygninger (3 rides + 4 faciliteter) | 11.18 | 11.2 | 0 | 96 | 72 | 89 | 98 | 125 |

Startparken giver ~50/dag og max ~48 samtidige gæster – samme som før (spawn hver 40. tick, max 50), så T-026-balancen holder.

## M3 – Personale, nedbrud, affald, dekoration (T-035)
Konstanter: `game/content/staff_rules.json`. Personale: `game/content/staff/`, dekoration: `game/content/decor/`.

### Personale
| Type | Løn/dag | Fart (celler/tick) | Radius | Rolle |
|---|---|---|---|---|
| Mekaniker | 60 | 0.12 | 0 (hele parken) | reparerer + inspicerer hver 2400. tick (40 ticks) |
| Rengøring | 45 | 0.10 | 12 | fejer en celle på 20 ticks, tømmer skraldespand på 30 |
| Underholder | 70 | 0.08 | 8 | +0.03 glæde/tick for gæster inden for radius |

Rationale: startparken tjener ca. +700/dag. En mekaniker + en rengøring (140/dag) koster ca. 20 % af det, så det mærkes, men kan betale sig. En underholder (70) svarer til ca. 12 karruselture.

### Nedbrud
Efter hver tur: nedbrud med sandsynligheden `1 − reliability`. Shops og toiletter går ikke i stykker (reliability = 1, når feltet mangler). En inspektion giver +0.002 akkumuleret pålidelighed (`inspection_reliability_bonus`, højst 1.0) indtil næste nedbrud.
| Forlystelse | reliability | repair_ticks | ture/dag (2400/ride_ticks) | forventede nedbrud/dag |
|---|---|---|---|---|
| Karrusel | 0.985 | 150 | 12 | 0.18 |
| Pariserhjul | 0.98 | 200 | 7.5 | 0.15 |
| Radiobiler | 0.97 | 180 | 10 | 0.30 |
| Svingkarrusel | 0.975 | 180 | 11 | 0.27 |
| Spøgelseshus | 0.98 | 160 | 13 | 0.27 |
| Gokart | 0.96 | 220 | 9 | 0.37 |
Uden mekaniker står karrusellen typisk i stykker fra dag 4–6 (1/0.18 ≈ 5,5 dage). Så stopper billetindtægten, og gæsterne bliver sure. Med mekaniker: et tab på ca. (150 + gangtid ~100)/2400 ≈ 10 % af én dags ture pr. nedbrud, dvs. ca. 2 % i snit.

### Affald
- Efter køb i shop: affald med sandsynligheden `litter_chance_after_shop` 0.5, eller 0.1 hvis der er en skraldespand inden for `bin_radius` 4 celler. En spand rummer 20 stk. og kræver derefter tømning.
- Op til 5 stk. pr. sti-celle. Celle med ≥ `dirty_threshold` 2 er beskidt: gæster der går der, mister 0.15 glæde/tick og får tanken "Her er beskidt!".
- Forventning i startparken: ~50 gæster × ~2 køb = 100 køb/dag → ~50 affald/dag uden spande, ~10 med. En rengøring fjerner ~120 stk./dag (20 ticks pr. celle inkl. gang ⇒ rigeligt). Uden rengøring bliver stierne nær boderne beskidte på dag 1–2.

### Dekoration
| id | Pris | På sti | Aura | Radius | Effekt |
|---|---|---|---|---|---|
| bin | 40 | ja | 0 | 0 | mindre affald (se ovenfor) |
| bench | 60 | ja | 0.5 | 1 | gæster med energy ≥ 70 hviler 60 ticks, energy −30 |
| tree | 30 | nej | 1.0 | 2 | glæde |
| flowers | 20 | nej | 1.5 | 1 | glæde |
| lamp | 50 | ja | 0.5 | 2 | glæde (forberedt på dag/nat) |
Aura: gæst på en celle får `Σ happiness_aura × aura_scale_per_tick (0.01)` glæde pr. tick, loftet ved `decor_aura_max_per_tick` 0.03. Så det svarer højst til ca. én underholder, og mange dekorationer stabler ikke uendeligt.

### Nye forlystelser
| id | Navn | Fodaftryk | Byg | Drift/dag | Kap. | Ticks | Billet | Excitement |
|---|---|---|---|---|---|---|---|---|
| swing_ride | Svingkarrusel | 3×3 | 1100 | 220 | 12 | 220 | 6 | 35 |
| haunted_house | Spøgelseshus | 3×2 | 1300 | 230 | 8 | 180 | 6 | 40 |
| go_karts | Gokart | 4×3 | 2000 | 320 | 8 | 260 | 8 | 55 |
Gokart har høj excitement og lav pålidelighed, så det trækker gæster men kræver en mekaniker.

### Balance-forventning (beregnet, ikke målt)
Startpark + mekaniker + rengøring: dagsnetto ≈ 754 − 140 − ~2 % nedbrudstab ≈ +600. Kumuleret fra T-034-målingen: dag 1 ≈ −1585, dag 2 ≈ −1107, dag 3 ≈ −560, dag 4 ≈ +87 ⇒ **break-even dag 4**. Ansættes personalet først på dag 2, kommer break-even på dag 3–4.

### Personale-balance (T-044)
Ændringer: løn mekaniker 80→60, rengøring 60→45. `inspection_reliability_bonus` 0.01→0.002 og `mechanic_inspect_interval_ticks` 1200→2400. Før akkumulerede bonussen til 1.0 på 1 dag, så der var 0 nedbrud; nu er den højst ca. +0.014 på 7 dage. `happiness_penalty_dirty_per_tick` 0.05→0.15. Startpark 7 dage, snit af 5 seeds (balance.sh):
| | Penge d7 | Omdømme | Gæster | Glæde | Nedbrud | Ødelagt-dage |
|---|---|---|---|---|---|---|
| Uden personale | 982 | 58.3 | 204 | 71.8 | 0.8 | 3.97 |
| Med mek.+reng.+2 spande | 4309 | 75.4 | 373 | 83.2 | 1.0 | 0.06 |
Med personale (løn 105/dag): kumuleret −1594 / −994 / −445 / +238 → break-even dag 4. Selv uden nedbrud (seed 12345) koster personalet nu kun ~830 på 7 dage, og omdømmet er +16 højere.

## M4 – Grafik og lyd (T-046)

### Dag/nat (`daynight.json`)
- En spildag = `day_ticks` 2400 (2 min). `day_tick 0` = 06:00 (`day_start_time` 0.25).
- Faser (time_of_day): daggry 0.22–0.30 (05:17–07:12), dag 0.30–0.78 (07:12–18:43), skumring 0.78–0.86 (18:43–20:38), nat 0.86–0.22 (20:38–05:17).
- Nat = 36 % af døgnet, men daggry+skumring (16 %) blødgør overgangene, så "rigtig" mørke kun er ~1/3 af tiden (~43 s pr. dag). Det er nok til at lamper og forlystelseslys giver stemning, men ikke så langt, at det føles som en pause.
- Natten må aldrig være så mørk, at man ikke kan bygge: ambient-lys min. ~35 % af dagniveau, månelys blåligt; grid/stier skal altid være læsbare.
- Ingen gameplay-effekt i M4 (kommer evt. i M5).

### Farvepalet
| Fase | Sollys | Himmel (top/horisont) | Ambient |
|---|---|---|---|
| Daggry | varm fersken #FFC79A | #6E8FC4 / #F6B48A | 0.6 |
| Dag | varm hvid #FFF4E0 | #4A90E2 / #BFE3FF | 1.0 |
| Skumring | orange-rosa #FF9A6B | #3B3F7A / #FF8C69 | 0.6 |
| Nat | måne, kold blå #8FA8FF (energi ~0.25) | #0E1430 / #263A6B | 0.35 |
Lamper: varm gul #FFD27A. Forlystelseslys: mættede tivolifarver (rød, gul, cyan, magenta).

### Stemning og lyd (`audio.json`)
- Hyggeligt, legende tivoli – aldrig skingert. Alt er procedurelt genereret (sinus/trekant/firkant/stoej + envelopes), beskrevet pr. id i `audio.json`.
- Busser: Music, SFX, Ambience, UI. Ambience skifter dag (fugle + brus) ↔ nat (fårekyllinger + vind) ved `phase_changed` (dusk/night → night, dawn/day → day).
- `cash` throttles (maks 4/s); `ride_start` kun når kameraet er tæt på (`max_distance`).

### Nedbrud uden mekaniker (`staff_rules.json`)
- `self_repair_ticks` = 1200 (en halv dag), `self_repair_cost` = 250.
- Rationale (T-041-tal): uden reparation forblev karrusellen nede og startparken endte på -16 til -990 kr. Med ekstern service er en nedbrudt forlystelse nede ~½ dag og koster 250 + tabt billetsalg (~200–300) ≈ 500 pr. nedbrud – overlevelig med startkapital 2200.
- En mekaniker koster 60/dag (420 pr. uge) og reparerer på ~150–220 ticks. Allerede ét nedbrud om ugen gør mekanikeren rentabel; med flere forlystelser er han klart nødvendig.
- UI-advarsel `broken_no_mechanic` lærer spilleren at ansætte en mekaniker.
