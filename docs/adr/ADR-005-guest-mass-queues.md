# ADR-005: Gæster med masse, køstier, fortryd og ydeevne på web

- **Status:** accepteret
- **Dato:** 2026-10-16
- **Kontekst:** M7 (`docs/gdd.md` §M7, T-097) giver gæsterne fylde (højst 6 pr. celle, undvigelse og trængsel), indfører køstier med tålmodighed, lader gæsterne vælge ledige bygninger frem for optagede og tilføjer flyt og fortryd. Simulationen er cellebaseret (`Guest.cell` + `progress`), har fast tick på 20/s og skal være deterministisk. Web-buildet (Compatibility, single-thread) skal kunne klare mindst 500 gæster.

## Beslutning

### 1. Masse = belægning i sim, undvigelse i rendering
- Simulationen kender **ikke** gæsternes kontinuerte position. Den holder `ParkWorld.occupancy: PackedInt32Array` med én tæller pr. celle (index = `y * width + x`). Tælleren nulstilles og bygges op igen én gang pr. tick i gæste-id-orden. Det er O(n) uden hash-tabeller eller floats.
- En gæst må kun gå ind i næste celle, hvis `occupancy[next] < max_guests_per_cell` (6). Ellers venter hun (`Guest.blocked_ticks += 1`). Efter `crowd_reroute_ticks` (20) beregner hun ruten igen med cellen som "dyr" (+8 i vægt i ét A*-kald). Hun forbyder ikke cellen, så hun kan ikke blive låst inde.
- Trængsel: når en celle har været fuld i over 200 ticks (`ParkWorld.crowd_ticks[cell]`), får gæsterne på cellen glæde −0,01/tick og tanken `crowded`.
- **Undvigelse er kun visuel.** `GuestVisual` får en deterministisk sidelæns forskydning ud fra `guest_id` (6 baner pr. celle, ±0,3 celle) plus en simpel lokal separation mellem visuals i samme celle. Det påvirker ikke sim og gemmes ikke. Begrundelse: rigtig agent-separation i sim ville kræve floats pr. gæst, nabosøgning og save af positioner, og det ville gøre determinisme og ydeevne dyrere uden at ændre spillet. Det, spilleren mærker (kapacitet, ventetid og trængsel), ligger i tælleren.

### 2. Køstier er en celletype, som normal pathfinding ikke bruger
- `ParkWorld` får celletypen `QUEUE` ved siden af `PATH`. `PathFinder.find_path` følger kun `PATH` (og transport-links fra ADR-004). En køsti er **ikke** en separat graf.
- En køsti er en kæde af `QUEUE`-celler, der starter ved en attraktions indgangscelle. `Attraction.queue_cells: Array[Vector2i]` er ordnet fra indgang til ende og udledes af verden (flood fra indgangen langs naboer uden forgrening). Det genberegnes ved hver ændring og gemmes ikke. Køens **ende** er den celle, der støder op til en `PATH`-celle. Gæsten går med normal pathfinding til den `PATH`-celle og træder derfra ind i køen.
- Kapacitet: `queue_cells.size() * queue_slots_per_cell`. Hvis der ikke er nogen køsti, er kapaciteten `queue_default_max` (4), og køen er virtuel ved indgangen som i dag.
- I køen er gæsten i tilstanden `QUEUING` med en plads (`queue_index`). Det er uafhængigt af belægningstælleren, så køceller tæller ikke med i `max_guests_per_cell`. Det visuelle laves af bridge: plads i → celle `queue_cells[i / slots]`.
- Afvist: en separat kø-graf (giver to pathfindere og dobbelt vedligehold) og en "fri" kø uden celler (ingen visuel og ingen reel byggebeslutning).

### 3. Valg af ledig bygning
`score = manhattan_afstand + queue_length × queue_weight_cells`. Fyldte køer springes over. Afstanden er manhattan og ikke A*, så valget koster O(bygninger) pr. beslutning. Den rigtige rute findes bagefter med A* som i dag.

### 4. Fortryd = kommandostak med inverse kommandoer i sim
- `UndoStack` (`game/simulation/commands/undo_stack.gd`, `RefCounted`) ligger i sim, så pengene bliver præcise. Hver *spillerkommando*, der kan fortrydes (byg/sælg/flyt sti, bygning, pynt og køsti, pris og config/opskrift), registrerer en post `{kind, args, inverse_args, money_delta, tick}`. Stakken har højst 20 poster og en redo-stak.
- `cmd_undo()` udfører den inverse kommando og tilbagefører `money_delta` præcist (ikke den almindelige 50 %-refusion). Hvis det inverse ikke kan lade sig gøre længere (cellen er optaget, eller der mangler penge), returnerer kommandoen `false` med `reason`, og posten bliver liggende.
- Fortryd ruller **ikke** gæster, tid eller RNG tilbage. Gæster i kø eller på en tur, der bliver fortrudt væk, bliver smidt af som ved flyt/sælg. Det er acceptabelt, fordi det kun påvirker spillerens egne handlinger, og resultatet stadig er deterministisk (fortryd er selv en kommando).
- Stakken gemmes ikke og ryddes ved indlæsning og ved scenarieskift.
- Afvist: snapshots (`to_save()` pr. handling er for dyrt ved 500 gæster og ville rulle gæster tilbage) og "kun inden for 5 s" (GDD-forslaget, for skrøbeligt og uforståeligt for spilleren).

### 5. Flyt, også af sporbaner
- `cmd_move_attraction(id, new_origin, rotation)` validerer det nye fodaftryk, som om det var en ny bygning (cellen må gerne overlappe sit eget gamle fodaftryk). Køen tømmes, og passagerer sættes af ved den nye indgang uden refusion af billet.
- **Sporbaner flyttes som en stiv helhed** (brugerens beslutning): alle stykker forskydes med `delta` og roteres i 90°-trin om stationens celle. Valideringen er den samme som `cmd_finish_coaster` (højde, frihøjde og kollision mod alt andet end banen selv). Banen beholder sine ratings, fordi profilen er uændret ved translation og rotation. Svævebanens links bygges igen.
- Køstier flyttes ikke med. De bliver liggende og kobles igen, hvis den nye indgang støder op til dem.

### 6. Salgshændelser batches pr. tick
`purchase_made` beholdes, men bridge må ikke lave visuals pr. signal. Sim udsender i stedet `sales_tick(sales: Dictionary)` (building_id → summeret beløb) én gang pr. tick, hvis der har været salg. Bridge samler så i 0,25 s-vinduer. Ved 500 gæster giver det højst 20 signaler i sekundet.

### 7. Ydeevnebudget (web, 500 gæster, 4× hastighed = 80 ticks/s)
- Simulation: ≤ 4 ms pr. tick i headless desktop-benchmark (`tools/balance.sh --perf`, 500 gæster). Pathfinding begrænses til højst 25 A*-kald pr. tick (kø med `budget`). Resten venter et tick.
- Rendering: gæster som `MultiMeshInstance3D` med 3 LOD-niveauer, når de er længere væk end 40 m. Individuelle `GuestVisual`-noder bruges kun tæt på kameraet (højst 120). Svævetal, skrald og bænke skjules også over 40 m.
- QA måler i web-buildet (T-118): mindst 30 fps med 500 gæster på 1×.

## Konsekvenser
- Belægningen er en billig ekstra tæller, der giver kapacitet og trængsel uden fysik. Gæster "overlapper" aldrig mere end 6 pr. celle.
- Visuel undvigelse kan blive forbedret senere uden ændringer i save eller sim.
- Fortryd er præcist for penge og struktur, men ikke for gæsternes oplevelse. Det dokumenteres i tooltip'en.
- Save v4 gemmer gæsternes `patience`, `queue_index`, `blocked_ticks` og `leaving`, men ikke belægning, kø-celler, undo eller crowd-tællere (de genberegnes).
