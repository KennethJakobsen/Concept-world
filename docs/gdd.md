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

## M5 – Udvidelse (T-065)

### Forskning (`research.json`)
- Spilleren vælger et finansieringsniveau 0–3. Det koster 0/500/1000/2000 pr. dag og giver `10 × niveau` point pr. dag.
- Emnerne er rolige forlystelser, vilde forlystelser, rutsjebaner, butikker og natur/pynt. Spilleren kan prioritere ét emne. Ellers forskes der i den rækkefølge, `items` står i. Den er lagt sådan, at der kommer billige rutsjebanestykker tidligt, og go-karts kommer til sidst.
- Fra start er grundpakken låst op: karrusel, burger- og drikkebod, toilet, bænk, skraldespand, lampe, rundt træ, rutsjebanestation og lige skinne. Med niveau 2 (20 point/dag) tager hele træet cirka 78 dage.

### Scenarier (`scenarios/`)
Man vinder, når alle mål er opfyldt samme dag. Man taber, hvis fristen udløber, eller hvis en tabsbetingelse holder i N dage i træk. Fri leg (`sandbox`) har ingen mål og ingen forskning, og alt er låst op.

| Scenarie | Start | Mål | Frist | Tab |
|---|---|---|---|---|
| 1 Grøn eng (48×48) | 15000, omd. 50, karrusel+drikkebod | 115 gæster, omdømme ≥ 60 | 40 dage | penge < -5000 i 5 dage |
| 2 Floddalen (64×64) | 12000, omd. 45, karrusel | rutsjebane-excitement ≥ 5,0, ≥ 5 forlystelser, penge ≥ 20000 | 60 dage | penge < -5000 i 3 dage, omd. < 20 i 5 dage |
| 3 Bjergtoppen (64×64) | 12000, omd. 35, tom | 75 gæster, parkværdi ≥ 92000, excitement ≥ 4,6, omdømme ≥ 52 | 90 dage | penge < -3000 i 3 dage, omd. < 15 i 4 dage |

### Rutsjebane (`coaster/`, `attractions/wooden_coaster.json`)
- Træ-rutsjebanen har en grundpris på 1000, og hvert stykke koster ekstra: station 300, lige 40, sving 60, op/ned 70, kædelift 120. Billetten koster 8 og driften 300 pr. dag. Toget har 3 vogne med 4 pladser hver (12 i alt), og max højde er 8 niveauer.
- Banen bygges stykke for stykke fra stationen og skal være lukket. Et fald giver fart. En kædelift trækker toget op med mindst 2,5 m/s.
- **Ratings i ord** (`ratings.json`): hver rating består af en grundværdi plus vægtede bidrag.
  - *Excitement* stiger med længde (bonusen er højst 2), topfart, antal fald, max vertikal g, max lateral g og turens varighed.
  - *Intensity* stiger mest med g-kræfter (især laterale) og topfart.
  - *Nausea* stiger med lateral g, vertikal g og antal sving.
  - Over 4,0 vertikal g eller 2,5 lateral g halveres excitement-bidraget (straf). Alle ratings klippes til 0..10.
- Excitement ganges med 10 til den eksisterende 0–100-skala for besøgsvalg. Gæster vil i udgangspunktet have en intensity mellem 3 og 8. Hvis den er højere, afviser de turen med begrundelsen "too_intense". Risikoen for at blive syg efter turen er 2 % pr. nausea-point.
- Forventning: en simpel oval med lift, ét fald og 4 sving bør give cirka E 4–5, I 3–5 og N 2–3. Det skal verificeres efter T-068.

## M5 – Forslag til nyt indhold (T-079)

Inspiration: Bullfrog's Theme Park (1994) havde bl.a. hoppeborg, kopkarrusel, minitog, rumringe, piratskib, raket, trampolin, vandrutsjebane, monorail samt boder (burger, cola, pommes frites, kaffe, balloner, souvenir, spøg og skæmt) og sideshows (kokosnødder, skydetelt, fang-en-and, stærk mand). Vi låner kun *genrerne*. Navne, modeller og tal er vores egne.

**Sim-status i dag:** attraktioner har `kind` (ride/shop/toilet), `excitement` og `satisfies` (hunger/thirst/toilet/energy). Der findes ingen `intensity`- eller `nausea`-felter. Derfor er de I/N-værdier, der står nedenfor, *forslag til et fremtidigt felt* (se "Ny mekanik B"). Indtil det felt findes, bruges kun excitement.

Typekoder: **D** = data plus en prop (eksisterende sim). **A–E** = kræver ny mekanik (se nederst).

### Forlystelser
| id | Navn | Type | Fod | Byg | Kap. | Billet | Exc / I / N | Forskning | Tema-element | Impl. |
|---|---|---|---|---|---|---|---|---|---|---|
| bouncy_castle | Hoppeborgen | ride | 2×2 | 400 | 10 | 3 | 20 / 10 / 5 | start (billig børneforlystelse) | Oppustet borg med kæmpe gummiand på tårnet | D |
| teacups | Tekopperne | ride | 3×3 | 900 | 12 | 4 | 28 / 25 / 35 | gentle_rides, 100 | Kæmpe tekande i midten, låget løfter sig | D |
| mini_train | Bimmelbanen | ride (sporbaseret) | station 3×1 + spor | 1200 + 20/felt | 16 | 4 | 25 / 5 / 0 | gentle_rides, 160 | Lokomotiv med overdreven skorsten og røgsky | B: genbrug coaster-spor (ADR-003) med flad profil. Kan tages som D med en fast rundtur på 4×4 |
| sky_rings | Himmelringene | ride | 2×2 | 1400 | 2 | 7 | 45 / 70 / 60 | thrill_rides, 220 | Gyroskop-ringe under en kæmpe planet med ring | D |
| pirate_ship | Gyngeskibet | ride | 4×2 | 1600 | 20 | 6 | 45 / 50 / 45 | thrill_rides, 200 | Dødningehoved-flag og kæmpe blæksprutte, der holder om masten | D |
| trampoline | Springfjedrene | ride | 2×2 | 600 | 6 | 3 | 22 / 30 / 15 | gentle_rides, 80 | Kæmpe spiralfjeder som indgangsbue | D |
| space_rocket | Månefærgen | ride | 3×3 | 2200 | 12 | 8 | 55 / 60 / 40 | thrill_rides, 280 | Høj tegneserieraket med flammer af plaster-kegler | D |
| log_flume | Tømmerrenden | ride, vandbane | station 3×2 + rende | 2800 + 40/felt | 8 | 8 | 60 / 40 / 10 | ny topic water_rides, 300 | Kæmpe træstamme med økse ved stationen | A (vandbane), afhænger af spor-systemet |
| drop_tower | Faldtårnet | ride | 2×2 | 3000 | 12 | 9 | 65 / 85 / 30 | thrill_rides, 350 | Tårnet er en kæmpe termometer-stang med "kogepunkt" på toppen | D |
| monorail | Svævebanen | transport | station 2×2 ×2 + bane | 2500 | 20 | 2 | 15 / 0 / 0 | gentle_rides, 300 | Stationer formet som kæmpe tandhjul | C (transport mellem to punkter) |

### Butikker og sideshows
| id | Navn | Type | Fod | Byg | Kap. | Pris | Dækker | Forskning | Tema-element | Impl. |
|---|---|---|---|---|---|---|---|---|---|---|
| fries_stand | Fritterbixen | shop | 1×1 | 260 | 2 | 3 | hunger -50, thirst +15 | shops, 60 | Kæmpe pommes frites-bæger | D |
| coffee_stand | Kaffekoppen | shop | 1×1 | 300 | 2 | 3 | thirst -40, energy -20 | shops, 120 | Bod i en kæmpe dampende kop | D (energy findes allerede i satisfies) |
| balloon_stand | Ballonbåsen | shop | 1×1 | 220 | 2 | 2 | glæde. Gæsten bærer ballon | shops, 100 | Klase af kæmpe balloner | E (vare/glæde-effekt). D-light: kun excitement 10 |
| souvenir_shop | Mindebutikken | shop | 2×1 | 500 | 3 | 5 | glæde. Gæsten bærer souvenir | shops, 200 | Kæmpe snekugle med parken i | E. D-light som ovenfor |
| coconut_shy | Kokoskasteriet | sideshow | 2×1 | 350 | 3 | 3 | glæde, præmie med 25 % chance | ny topic sideshows, 80 | Tre kæmpe kokosnødder på pinde | D (gevinst = excitement). Præmier = D (ny mekanik) |
| shooting_gallery | Skydeteltet | sideshow | 2×1 | 450 | 3 | 4 | glæde, præmie 20 % | sideshows, 140 | Stribet telt med kæmpe blikand på taget | D/D som ovenfor |
| hook_a_duck | Andefiskeriet | sideshow | 1×1 | 250 | 2 | 2 | glæde, præmie 50 % (lav værdi) | sideshows, 60 | Kæmpe gul and med fiskestang | D/D som ovenfor |
| strength_tester | Kraftklokken | sideshow | 1×1 | 300 | 1 | 3 | glæde, energy +5 | sideshows, 120 | Høj skala med kæmpe klokke og hammer | D/D som ovenfor |

### Ny mekanik (kræver sim-tasks)
- **A – Vandbane:** spor med vand-segmenter (lav friktion og plask-sektion), giver thirst -10 og en "våd"-tilstand. Bygger på coaster-sporet fra ADR-003. Størst opgave.
- **B – Intensity/nausea:** to nye felter (default 0), en gæstetolerance pr. gæst og et kvalmebehov, der giver opkast (affald) og glædetab. Uden dette ligner forlystelserne hinanden for meget. Det kræver også, at save-formatet migreres (felt-defaults).
- **C – Transport:** to stationer, og gæsten bruger forbindelsen som sti i pathfinding. Kan udskydes.
- **Sideshow-balance (T-095):** tab-glæde (excitement) 14/15/16/16 og intensity 25/30/15/35 (kokos/skyde/and/kraft), så de ikke er "for tamme" for alle. Drift 25/30/15/15 pr. dag, præmieudgift 5/8/1/3. Forventet margin pr. besøg ca. +1,75/+2,4/+1,5/+2,1 før drift; positiv netto i balance-målingen.
- **Impulskøb (T-119, `guests.json` "impulse"):** base_chance 0.35, radius 12 sti-celler, min. glæde 40, price_sensitivity 1.0. Chance = base × glæde/100 × (1 − pris/penge). Det gælder kun shops med `carry_item`, og hver gæst køber højst én af hver ting. Ca. 17 % af gæsterne køber en ballon og ca. 11 % en souvenir, mens besøgene på forlystelserne falder 1–5 %.
- **D – Sideshow-præmier:** `kind: "sideshow"` plus `win_chance`, `prize_cost` og `prize_happiness`. Parkens udgift pr. gevinst giver en lille risiko i økonomien, og gæsten bærer en synlig præmie.
- **E – Varer, der bæres:** ballon og souvenir er en tilstand på gæsten med glæde-aura. Ballonen kan flyve væk.

### Anbefaling
1. **Data-only nu (én designer-task + én graphics-task til props):** Hoppeborgen, Tekopperne, Springfjedrene, Himmelringene, Gyngeskibet, Månefærgen, Faldtårnet, Fritterbixen og Kaffekoppen. Ballonbåsen, Mindebutikken og de fire sideshows kan også tages med som "D-light" (`kind: ride`/`shop` med excitement-glæde) for at få bredden hurtigt.
2. **Næste sim-runde:** B (intensity/nausea) først, fordi den gør de nye forlystelser forskellige. Derefter D (sideshow-præmier), som er lille og selvstændig.
3. **Senere:** A (Tømmerrenden), som er spor-baseret og bør vente på erfaring med coasteren, og C (Svævebanen) samt Bimmelbanen på spor.
4. **Forskning:** to nye topics, `water_rides` og `sideshows`. Hoppeborgen bliver startunlock, så startparken får en billig børneforlystelse.

## M7 – Dybde og UX (T-097)

Udskudt til M8: løn/træthed/områder for personale, lån/regnskab/reklame, terræn og gæstegrupper. Alle nye felter er valgfrie og har defaults, så gammelt content og gamle saves virker uændret (SaveMigrations).

### 1. Konfiguration pr. bygning
**Forlystelser** (`attractions/*.json`, nyt objekt `config`):
```json
"config": {"capacity": {"min": 4, "max": 12, "default": 8},
           "ride_ticks": {"min": 120, "max": 320, "default": 200},
           "speed": {"min": 0.8, "max": 1.3, "default": 1.0}}
```
- Kapacitet pr. tur: drift/dag skaleres `× (0.7 + 0.3 × cap/cap_default)`. Flere pladser giver mere gennemløb men højere drift.
- Turlængde: excitement `× clamp(0.85 + 0.15 × ride_ticks/default, 0.85, 1.15)`. Længere tur er sjovere men giver lavere gennemløb og længere kø.
- Hastighed (kun flat rides med `speed`): excitement `× speed`, intensity `× speed²`, nausea `× speed²`, reliability-tab pr. tur `× speed`. Hurtigere er sjovere, men flere bliver syge og flere ting går i stykker.
- Ændringer gælder fra næste tur. Under en tur er værdierne låst.

**Butikker** (`recipes`, en liste af valgfrie tilsætninger, som spilleren slår til/fra pr. bod):
```json
"recipes": [{"id": "salt", "name": "Ekstra salt", "cost_per_sale": 0.1, "satisfies": {"thirst": 20}, "happiness": 1},
            {"id": "big", "name": "Stor portion", "cost_per_sale": 0.5, "satisfies": {"hunger": -15}, "price_tolerance": 0.15}]
```
- Fritterbix/burger kan få "Ekstra salt": thirst +20 efter køb, så drikkeboder sælger mere (ca. +15 % drikkesalg i en startpark). Prisen er lidt smag (+1 glæde) og en mindre glad gæst, hvis der ikke er en drikkebod i nærheden.
- Drikke kan få "Is i": thirst −10 ekstra og toilet +5.
- `cost_per_sale` trækkes fra omsætningen pr. salg (varekøb).

**Pris med adfærdseffekt** (`price_effects` i shop-json):
```json
"price_effects": [{"below_ratio": 0.6, "extra_purchase_chance": 0.35, "nausea": 15, "thought": "too_much"}]
```
- `ratio = price / default ticket_price`. Is under 0,6× (fx 1 kr i stedet for 3): 35 % chance for at gæsten køber én gang mere med det samme. Hvert ekstra køb giver nausea +15 (bruger M5-nausea, opkast over 60). Tanke: "Jeg spiste for meget".
- Over 1,5× gælder den almindelige pris-vurdering ("For dyrt!"). Det er altså kun den lave ende, der er ny.
- Det gør pris til en reel knap: billigt giver salg men skrald og opkast. Dyrt giver afvisninger.

### 2. Synlige salg
- Hvert salg udsender et sim-event `sale(building_id, amount)`. Den findes allerede i bogføringen og skal bare eksponeres.
- **I verden:** en grøn "+4 kr" svæver 1,0 s op over bygningen. Den samler salg inden for 0,25 s, så der ikke står 10 tal oven i hinanden. Den vises kun, når kameraets afstand er under ca. 40 m, og kan slås fra i indstillinger.
- **HUD:** pengetallet blinker grønt (0,3 s) ved indtægt og rødt ved udgift over 100 kr. Det tæller ikke op/ned, det springer.
- **Info-panel** (fanen Økonomi): omsætning i dag, i går og i alt, drift i alt, netto i alt, antal kunder i dag og en sparkline over de sidste 7 dage. Tilbagebetalt-markør: "Tjent hjem på dag 6".

### 3. Synligt skrald, spande, bænke og lamper
- Affald er allerede simuleret (M3). Nu vises det: 1–5 små props pr. celle (papir, bæger, opkast som en grøn plet). Stillingen er deterministisk ud fra celle og indeks, så den ikke hopper.
- Skraldespand: der vises fyldniveau (0/50/100 %). Fuld spand får et lille ikon. Fuld spand tæller ikke længere som spand (`litter_chance_after_shop` 0.5 igen), og overløb lægges på cellen.
- Bænk: en gæst, der hviler, sidder synligt. 2 pladser pr. bænk (`seats: 2`). Er den optaget, går gæsten videre.
- Lampe: aura 0,5 om dagen og 1,5 om natten (`night_aura: 1.5`). Uden lamper om natten: glæde −0,01/tick på stier med lys < 1 (nyt `park.json: dark_path_penalty_per_tick`). Det er lille, men giver lamperne et formål.

### 4. UX-redesign
**Problem:** i dag er menuerne lister af tekstknapper. Spilleren skal læse for at bygge, og information ligger spredt ud.

**Principper**
1. *Verden først.* Information vises på/ved tingen (svævetal, ikoner, overlays), før den vises i paneler.
2. *Ét klik for at se, to for at ændre.* Klik på noget åbner dets panel. Ændringer sker i panelet med direkte kontroller (skydere/stepper), aldrig i dialoger.
3. *Ikoner + tal, tekst i tooltip.* Alle knapper har ikon og tooltip (0,4 s forsinkelse) med navn, pris og effekt.
4. *Alt kan fortrydes.* Bygge/fjerne/flytte/pris-ændringer kan fortrydes (Ctrl+Z, 20 skridt, også pengene).
5. *Konsistente pladser.* Penge/dato/gæster altid øverst. Byg altid nederst. Detaljer altid højre side.

**Informationsarkitektur (skærmzoner)**
| Zone | Indhold |
|---|---|
| Top-bar | penge (blink), dato + dagsur, gæster, glæde-ikon (smiley i 5 trin), omdømme-stjerner, hastighed (pause/1×/2×/4×), varsler-klokke |
| Bund-dok (byg) | 6 kategori-ikoner: Stier, Forlystelser, Butikker, Pynt, Personale, Rutsjebane. Klik → vandret bakke med kort (ikon/miniature, pris, ★ hvis nyt, lås hvis ikke forsket). Hover = tooltip med stats |
| Højre panel (inspektør) | kontekst: bygning/gæst/personale/sti. Faner: Oversigt, Indstillinger (config/pris/opskrift), Økonomi, Kø. Kun én åben ad gangen. Esc lukker |
| Venstre kant (park) | små ikoner: Økonomi-oversigt, Forskning, Mål/milepæle, Gæster, Overlays, Indstillinger. Åbner store paneler, der dækker midten, men ikke top-bar |
| Nederst til højre | varsler (toast, 4 s): "Karrusellen er i stykker" – klik flytter kameraet dertil |

**Værktøjer**
- *Flyt* (M): saml en bygning op og sæt den ned igen. Gratis. Gæster i kø/på turen bliver smidt af (de mister ikke penge). Stier, der mister forbindelsen, markeres rødt.
- *Rotér* (R) under placering og flytning.
- *Sælg*: refusion 100 % de første 10 s (eller indtil første kunde) – "fortrydelse". Derefter 50 % af byggeprisen + konfig-tilvalg (som i dag). Prisen vises på knappen før klik.
- *Fortryd* (Ctrl+Z) / *Gentag* (Ctrl+Shift+Z): byg, sælg, flyt, pris, konfig. Ikke tid, forskning eller personale-ansættelse (kan sælges/fyres i stedet).
- Ghost-forhåndsvisning: grøn = ok, rød = blokeret, med prisen ved musen.

**Kort-overlays** (tast O eller venstre kant; ét ad gangen, resten af verden dæmpes):
| Overlay | Visning | Skala |
|---|---|---|
| Glæde | gæster farvet efter glæde | 0–100 |
| Skrald | sti-celler farvet efter affald | 0–5 |
| Kø | forlystelser farvet efter kø-længde/kapacitet + ventetid i tal | 0–100 % |
| Dækning | radius for spande, mekanikere, rengøring og underholdere | ja/nej |
| Lys (nat) | stier uden lys | ja/nej |
Farveskalaer bruger en farveblind-sikker palet (viridis-lignende: mørkeblå → gul) og har altid en signatur/legende.

**Tilgængelighed**
- UI-skalering: 75 %, 100 %, 125 %, 150 %, 200 % (standard følger skærmens DPI). Gemmes i brugerindstillinger, ikke i saven.
- Farveblind-tilstand: overlays bruger allerede sikker palet. Tilstanden ændrer også grøn/rød i ghosts og pengeblink til blå/orange og tilføjer form (✓/✗-lignende ikoner tegnet som grafik, ikke tegn, så fonten ikke er et problem).
- Alle farvesignaler har et andet signal ved siden af (ikon, form eller tal).

**Tutorial (bygges sidst, efter det andet er stabilt)**
- Separat, valgfrit scenarie "Første park" med 6 trin med pile i verden: læg sti fra indgang → byg karrusel → byg bod → sæt pris → åbn kø-overlay → ansæt rengøring. Hvert trin fuldføres ved handling, ikke ved klik på "Næste". Kan springes over. Data i `scenarios/tutorial.json` (`steps: [{id, text, highlight, complete_when}]`).

### 5. Baggrund og mur
- Parkens område omkranses af en mur (hæk/hegn) på kanten. Den er kun visuel og kan ikke fjernes. Indgangen er en port i muren.
- Uden for muren: et bælte på ca. 24 celler med græs, træer, mark og en vej, der fører til indgangen. Ingen sim, kun props. Biler/busser kører på vejen, og gæster går fra en busstoppested til porten (kosmetisk).
- Data: `park.json: "surroundings": {"wall": "hedge", "margin_cells": 24, "theme": "countryside"}`. Scenarier kan ændre temaet (flod/bjerg).

### 6. Køstier
- Ny sti-type `queue_path` (byg 15, refusion 7). Den tilsluttes forlystelsens indgang. Køen er så lang som antal køceller × 2 pladser pr. celle (`queue_slots_per_cell: 2`).
- Uden kø-sti: maks 4 i kø (`queue_default_max: 4`, nuværende adfærd med en kort ventezone).
- Kø fyldt: gæsten vælger noget andet ("Køen er for lang").
- **Tålmodighed:** hver gæst har `patience` trukket fra `queue_patience_ticks` {min: 600, max: 1500} (30–75 s ved 1×). Over halvvejs: glæde −0,02/tick. Når den løber ud: gæsten forlader køen, glæde −10, tanke "Jeg gider ikke vente mere".
- Pynt og underholdere nær køen halverer tålmodighedstabet (`queue_entertained_factor: 0.5`).
- Forventet: karrusel (8 pladser, 200 ticks) betjener 8 gæster pr. 200 ticks (0,8/s) ⇒ 12 køceller (24 pladser) svarer til ca. 600 ticks ventetid, og det er præcis grænsen. Anbefalet kø: 6–10 celler pr. flat ride.

```json
"guests.json": {"queue_patience_ticks": {"min": 600, "max": 1500}, "queue_impatient_decay": 0.02, "queue_abandon_happiness": 10}
"park.json": {"queue_slots_per_cell": 2, "queue_default_max": 4, "queue_entertained_factor": 0.5}
```

### 7. Gæster med masse
- Gæster har radius 0,2 celle (`guest_radius`). De undviger hinanden (lokal separation, ikke fuld fysik), og der kan højst være 6 gæster pr. sti-celle (`max_guests_per_cell`). Er cellen fuld, venter gæsten op til 20 ticks og vælger så en anden rute.
- Fuld celle i mere end 200 ticks er "trængsel": glæde −0,01/tick og tanke "Her er for mange mennesker". Det giver et naturligt incitament til at bygge bredere stier.
- Determinisme: separationen beregnes i fast rækkefølge (gæste-id). Ingen float-afhængighed af frame-rate.

### 8. Vælg ledig frem for optaget
- Når en gæst vælger en bygning til et behov, scorer den `score = afstand + kø_længde × queue_weight (3 celler pr. person i kø)`. Den laveste score vinder.
- Er bygningen fuld (kø fyldt), springes den over. Det gælder toiletter, butikker og forlystelser (forlystelser: til `score` lægges excitement-vægten fra den nuværende tilfældige vægtning).
- `guests.json: "queue_weight_cells": 3`.

### 9. Gå hjem og hæveautomat
- Gæsten sætter kurs mod udgangen (tilstand `leaving`, sti til port) når: energy ≥ `leave_energy` 90, glæde < 20, eller penge < billigste åbne pris og ingen hæveautomat inden for rækkevidde. Tanke vises ("Jeg er træt", "Jeg har ikke flere penge").
- `leaving`-gæster køber ikke og stiller sig ikke i kø, men kan stadig blive sultne (påvirker ikke længere).
- **Hæveautomat** (`atm`, 1×1, byg 400, drift 20/dag, forskning `shops`, 90 point): en gæst uden penge går til nærmeste hæveautomat (op til 30 celler), hvis glæde ≥ 40, og hæver 20–50 kr (seedet). Højst 2 gange pr. besøg. Parken får 1 kr i gebyr pr. hævning.
- Forventning: gæster bliver ca. 20–30 % længere ⇒ +15–25 % omsætning i en moden park. Det dækker automaten på dag 1–2.

### 10. Milepæle, der låser forskning op
Oven på den eksisterende forskning: en milepæl låser en *gren* (topic) op for forskning eller giver point. Uden milepælen kan grenen ikke vælges.
```json
"milestones": [
  {"id": "guests_100", "name": "100 gæster", "condition": {"total_guests": 100}, "reward": {"research_points": 50}},
  {"id": "first_thrill", "name": "Første vilde tur", "condition": {"rides_open": 3}, "reward": {"unlock_topic": "thrill_rides"}},
  {"id": "stars_3", "name": "3 stjerner", "condition": {"reputation": 60}, "reward": {"unlock_topic": "roller_coasters"}},
  {"id": "first_coaster", "name": "Første rutsjebane", "condition": {"coaster_built": true}, "reward": {"unlock_topic": "water_rides", "money": 1000}},
  {"id": "clean_park", "name": "Ren park", "condition": {"days_clean": 3}, "reward": {"unlock_topic": "scenery"}},
  {"id": "sideshow_ready", "name": "Pengemaskine", "condition": {"total_revenue": 20000}, "reward": {"unlock_topic": "sideshows"}}
]
```
- Fra start åbne: `gentle_rides`, `shops`. Resten kræver milepæle. Stjerner = omdømme / 20 (3★ = 60).
- Fil: `game/content/milestones.json`. Gemmes i saven som et sæt af opnåede id'er (default tomt; ved migration markeres milepæle, hvis betingelsen allerede er opfyldt, så gamle saves ikke mister grene).
- Sandbox: alt åbent, milepæle vises men giver intet. Scenarier kan slå milepæle fra (`"milestones": false`).
- UI: venstre kant → "Mål/milepæle" med fremskridtslinje pr. milepæl. Opnået milepæl giver toast + fanfare.

### Data-noter (T-100, T-131)
- `config` findes på alle `kind: "ride"` (flat rides): kapacitet 0,5–1,5× default, turlængde 0,6–1,6× default (afrundet til 10 ticks), hastighed 0,8–1,3. Sporbaner har ingen `config`.
- Opskrifter: Fritterbix/Burger "Ekstra salt" (+ Burger "Stor portion"), Drikkebod "Is i", Kaffekoppen "Ekstra sukker" (energy −10, +1 glæde), Isbod "Krymmel" (+2 glæde). `price_effects` (< 0,6×) på Isbod, Fritterbix og Burgerbod.
- Hæveautomat: `attractions/atm.json`, forskes i `shops` (90 point). Spand `capacity: 20` affaldsenheder (fyldniveau = fill/capacity).
- Omgivelsestema pr. scenarie: Grøn eng/Sandkasse `countryside`, Floddalen `river`, Bjergtoppen `mountain`.
- **Sporbaner kan kun startes, når de kan lukkes (T-131, brugerens valg A):** hver sporbane har `required_pieces` (station, lige og begge sving). Byggekortet er gråtonet, indtil alle stykker er låst op (`is_unlocked`), med teksten "Kræver forskning: <emne> – <stykker>". For træ-rutsjebanen betyder det i praksis, at sving skal forskes i "Rutsjebaner". Tømmerrende/tog/svævebane er altid komplette, fordi deres stykker følger banens oplåsning (T-119). Stigning/lift kræves ikke, hvis en flad lukket bane (station + lige + 4 sving) består `validate()` inkl. `too_slow`. Det skal en sim-test bekræfte; fejler den, tilføjes `track_lift_up`/`track_down` til `required_pieces`.

### Åbne spørgsmål til architect
1. **Fortryd og determinisme:** skal fortryd være en kommando-stak i sim (inverse kommandoer) eller et snapshot? Hvad med fortryd efter tid er gået (gæster i kø)? Forslag: kun indtil næste sim-tick-batch på 5 s, ellers kommando-baseret uden at rulle gæster tilbage.
2. **Gæste-separation** (pkt. 7) i sim med fast tick og mange gæster: rumlig hash pr. celle? Ydelse på web ved 500+ gæster?
3. **Køstier i pathfinding:** er `queue_path` en separat graf, eller en sti-type, som normal pathfinding ikke må bruge?
4. **Flyt-værktøj:** hvordan håndteres coaster-spor (flyt hele banen eller ikke tilladt)? Forslag: ikke tilladt i M7.
5. **Sale-event:** bridge-signal pr. salg eller batch pr. tick (flere hundrede gæster)?
6. **Brugerindstillinger** (UI-skala, farveblind, svævetal): ny `user://settings.cfg` adskilt fra save – ok?
7. **Milepæls-migration:** er det acceptabelt at evaluere betingelser retroaktivt ved indlæsning af gamle saves (kun dem, vi kan beregne fra state)?
8. **Recipes og save:** gemmes valgte tilsætninger pr. bygningsinstans (ja, foreslået) med default `[]`?
