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
- Start 2500; entré 10; sti 10 (refusion 5); gæster medbringer 30–80.
- Start-budget: karrusel 800 + 2 boder (~550) + ~50 stier (500) = ~1850 → ~650 buffer.
- Drift pr. dag for start-park: ~75. Indtægt pr. dag ved ~40 gæster/dag: entré ~400 + forlystelse/boder ~300 → overskud fra dag 1–2, og de indledende investeringer er tjent hjem efter ~3 dage.
- Fjernelse af bygning refunderer 50% af build_cost.

### Bygninger
| id | kind | fp | pris (byg) | drift/dag | kap. | ticks | billet | excitement | satisfies |
|---|---|---|---|---|---|---|---|---|---|
| carousel | ride | 3×3 | 800 | 40 | 8 | 200 | 5 | 25 | energy -10 |
| ferris_wheel | ride | 3×3 | 1200 | 60 | 12 | 320 | 6 | 35 | energy -15 |
| bumper_cars | ride | 4×4 | 1500 | 70 | 10 | 240 | 7 | 45 | energy +10, thirst +10 |
| burger_stand | shop | 1×1 | 300 | 20 | 2 | 40 | 4 | 0 | hunger -70, thirst +10, toilet +15 |
| drinks_stand | shop | 1×1 | 250 | 15 | 2 | 30 | 3 | 0 | thirst -70, toilet +20 |
| ice_cream_stand | shop | 1×1 | 280 | 15 | 2 | 30 | 3 | 5 | hunger -25, thirst -20, toilet +10 |
| toilet | toilet | 1×1 | 200 | 10 | 2 | 60 | 0 | 0 | toilet -90 |
