# M5 kontrakt – Udvidelse

Mål: **forskning** (låste bygninger), **scenarier** (mål, sejr/nederlag, valg i hovedmenuen og fri leg) og **rutsjebane-bygger** (se `docs/adr/ADR-003-coaster.md`). Gælder fortsat:
- Compatibility/web: ingen compute, ingen `PhysicsServer` i sim, procedurelle meshes via `SurfaceTool`/`ArrayMesh`.
- Lag-reglerne i `docs/conventions.md`: `game/simulation/` er `RefCounted`/`Resource` uden noder og er deterministisk med seedet RNG og 20 tick/s.
- Balance ligger i data. UI-tekster bruger kun tegn fra standardfonten (`test_hud_glyphs`).
- Alle eksisterende tests, `integration.sh` og `balance.sh` skal forblive grønne.

## 0. Data (designer, T-065), `game/content/`
- `research.json`:
  ```json
  { "points_per_day_base": 10, "cost_per_level": [0, 500, 1000, 2000],
    "topics": [ { "id": "thrill_rides", "name": "Vilde forlystelser", "unlocks": ["swing_ride", "go_karts"] }, ... ],
    "items":  [ { "id": "ferris_wheel", "topic": "gentle_rides", "points": 120 }, ... ],
    "start_unlocked": ["carousel", "burger_stand", "drinks_stand", "toilet", "bench", "bin", "lamp", "tree_round", "coaster_station", "track_straight"] }
  ```
  `items[].id` er et attraktions-id, et decor-id eller et coaster-stykke-id (`track_*`). Alle id'er skal findes i kataloget (der er en test for det).
- `scenarios/<id>.json` (mindst 3 + `sandbox.json`):
  ```json
  { "id": "green_meadow", "name": "Grøn eng", "description": "...", "order": 1,
    "map": { "width": 64, "height": 64, "entrance": [32, 63] },
    "start": { "money": 15000, "loan": 0, "reputation": 50, "paths": [[32,63],[32,62]],
               "attractions": [{"def": "carousel", "origin": [30, 58]}], "decor": [], "staff": [],
               "unlocked": [], "research_enabled": true, "entry_fee": 10 },
    "objectives": [ { "type": "guests_in_park", "value": 300 },
                    { "type": "reputation_min", "value": 70 } ],
    "deadline_days": 30,
    "lose": [ { "type": "money_below", "value": -5000, "days": 3 } ] }
  ```
  Objective-typer i M5: `guests_in_park`, `reputation_min`, `money_min`, `park_value_min`, `rides_count_min`, `coaster_excitement_min`. Lose-typer: `money_below` (i N dage i træk) og `reputation_below` (i N dage). `deadline_days` er 0 for ingen frist. `sandbox.json` har ingen objectives og `research_enabled: false`, og alt er låst op.
- `coaster/pieces.json`: liste af stykker:
  `{ "id": "track_straight", "cost": 40, "length": 1.0, "turn": 0, "rise": 0, "kind": "track" }`.
  `turn` ∈ {-1, 0, 1} (venstre/lige/højre 90°, kurven fylder én celle), `rise` ∈ {-1, 0, 1} niveauer, `kind` ∈ `track | station | lift`. Minimum: `track_straight`, `track_turn_left`, `track_turn_right`, `track_up`, `track_down`, `track_lift_up` (kæde), `coaster_station`. Mulige ekstra felter: `"friction"` og `"lift_speed"`.
- `coaster/trains.json`: `{ "id": "basic_train", "cars": 3, "seats_per_car": 4, "mass": 1.0, "friction": 0.02, "station_speed": 2.0, "lift_speed": 2.5 }`.
- `attractions/wooden_coaster.json`: `kind: "coaster"`, `build_cost` (grundpris, stykkerne lægges oveni), `running_cost_per_day`, `ticket_price`, `reliability`, `repair_ticks`, `train`: `"basic_train"`, `max_height`: 8. `footprint` ignoreres. `capacity` = `cars * seats_per_car`.
- `coaster/ratings.json`: vægte og tærskler for excitement/intensity/nausea (se §3.4) og gæsternes tolerance (`intensity_pref_min/max` pr. gæst er allerede en del af gæstemodellen, hvis den findes; ellers et nyt `guests.json`-felt med default).
- `docs/gdd.md`: nye afsnit om forskning, scenarier og rutsjebane.

## 1. Forskning (simulation, T-066), `game/simulation/research/`
- `ResearchDef` (Resource) indlæses fra `research.json`. `Research` (RefCounted) ejes af `ParkSim.research`.
- State: `unlocked: Dictionary` (id → true), `funding_level: int` (0..3), `current_item: String` ("" = intet), `progress: float` (point), `enabled: bool`.
- Hver dag i `_end_day`: `progress += points_per_day_base * funding_level`, og `cost_per_level[funding_level]` bogføres som `"research"`. Når `progress >= item.points`, bliver item låst op, og næste item vælges deterministisk: det første ulåste i `items`-rækkefølgen, der hører til et prioriteret emne, ellers det første ulåste.
- API på `ParkSim`:
  - `is_unlocked(id: String) -> bool` (altid true, når `research.enabled == false`)
  - `cmd_set_research_funding(level: int) -> bool`
  - `cmd_set_research_priority(topic_id: String) -> bool` ("" = ingen)
  - `research_status() -> Dictionary` `{ "enabled", "funding_level", "current_item", "progress", "points_needed", "priority", "unlocked": Array[String] }`
  - signal `research_unlocked(item_id: String)` og `warning(&"research_done", {"item_id": id})`
- `cmd_place_attraction`, `cmd_place_decor` og `cmd_place_track_piece` returnerer null/-1/false for låste id'er. Der kommer intet nyt signal. UI/gameplay spørger selv `is_unlocked`.

## 2. Scenarier (simulation, T-067), `game/simulation/scenario/`
- `ScenarioDef` (Resource), `ScenarioDef.from_json(path)`, `ScenarioDef.list_all() -> Array[ScenarioDef]` (sorteret efter `order`, læser `res://content/scenarios/`). Bemærk at `DirAccess` virker i eksporterede builds, fordi content er med i pck'en. Det skal testes i `integration.sh`.
- `ParkSim.new_from_scenario(def: ScenarioDef, seed: int, balance: Balance = null) -> ParkSim` (static): opretter verden i kortets størrelse og sætter penge, omdømme, entré, stier, attraktioner, decor, personale og `research.unlocked = start_unlocked ∪ start.unlocked` op. Forskning slås til eller fra efter `research_enabled`.
- `Scenario` (RefCounted) på `ParkSim.scenario` (null ved ældre saves er det samme som sandbox): `def_id`, `state: StringName` (`&"running" | &"won" | &"lost"`), `days_elapsed`, `lose_streaks: Dictionary`.
- Evaluering sker i `_end_day` efter økonomi og omdømme. Alle objectives opfyldt samme dag ⇒ `won`. `days_elapsed >= deadline_days > 0` uden sejr ⇒ `lost` (reason `"deadline"`). En lose-betingelse med streak ≥ days ⇒ `lost`. Sejr vinder over nederlag samme dag. Efter `won`/`lost` stopper evalueringen, men simulationen kører videre, så spilleren kan fortsætte i fri leg.
- API: `scenario_status() -> Dictionary` `{ "id", "name", "state", "days_elapsed", "deadline_days", "objectives": [ {"type", "value", "current", "met": bool} ] }`, signal `scenario_finished(won: bool, reason: String)`.
- `park_value() -> int` = sum af `build_cost` for bygninger og stykker × 0.8 + penge − lån (hvis der ikke er lån, udelades lån).

## 3. Rutsjebane (simulation, T-068), `game/simulation/coaster/`
### 3.1 Bane
- `TrackPieceDef` (fra `pieces.json`), `TrackPiece` (RefCounted: `def_id`, `cell: Vector2i`, `heading: int` 0=N(−y),1=Ø(+x),2=S(+y),3=V(−x), `level: int` = højde ved indgangen).
- `CoasterTrack` (RefCounted): `pieces: Array[TrackPiece]`. `next_entry() -> Dictionary {cell, heading, level}` beregnes ud fra det sidste stykke. `is_closed() -> bool`. `validate() -> Array[String]` (fejlkoder: `"no_station"`, `"multiple_stations"`, `"not_closed"`, `"too_high"`, `"below_ground"`, `"collision"`, `"too_slow"`, hvor det sidste betyder, at toget ikke kan gennemføre runden).
- Byggekommandoer på `ParkSim` (bygning sker altid fra banens ende, i retning af `next_entry`):
  - `cmd_start_coaster(def_id: String, station_cell: Vector2i, heading: int) -> int` lægger det første stationsstykke og returnerer coaster-id (= attraktions-id) eller -1. Attraktionen er `is_open = false`, indtil `cmd_finish_coaster` er kaldt.
  - `cmd_place_track_piece(coaster_id: int, piece_id: String) -> bool` tjekker penge, at stykket er låst op, grænser, højde og kollision.
  - `cmd_remove_last_piece(coaster_id: int) -> bool` (refunderer 100 % under bygning).
  - `cmd_finish_coaster(coaster_id: int) -> Array[String]` validerer. Er der ingen fejl, beregnes fysik og ratings, og banen åbner. Listen er tom ved succes.
  - `cmd_remove_attraction` virker også for rutsjebaner (refusion som andre attraktioner).
  - `can_place_track_piece(coaster_id, piece_id) -> bool` og `preview_track_piece(coaster_id, piece_id) -> Dictionary {cell, heading, level, ok: bool, reason: String}` bruges til ghost-preview.
- Kollision: et stykke optager `(cell, level)`. Celler med stier, bygninger eller decor er blokeret, medmindre `level ≥ 2`. Et andet stykke i samme celle er tilladt, hvis |Δlevel| ≥ 2. `ParkWorld` får `occupied_by_track(cell) -> Array[int]` (niveauer) og nægter at placere bygninger/stier på celler, hvor banen ligger på level < 2.
- Lukning: banen er lukket, når `next_entry()` er lig med det første stykkes (cell, heading, level).
- `Attraction` får `cells: Array[Vector2i]` (tom for almindelige attraktioner = brug footprint), `track: CoasterTrack` (null for andre) og `ratings: Dictionary`. `occupies()` skal tage højde for `cells`.

### 3.2 Fysik (`CoasterPhysics`, static)
- `simulate(track: CoasterTrack, train: Dictionary, pieces: Dictionary) -> CoasterProfile` med `dt = 0.05` s. `CoasterProfile`: `length: float`, `duration_s: float`, `samples_s: PackedFloat32Array` (buelængde), `samples_v: PackedFloat32Array`, `samples_g: PackedFloat32Array` (vertikal), `samples_lat: PackedFloat32Array` (lateral), `max_speed`, `max_g`, `max_lat`, `drops: int`, `max_height: int`, `ok: bool`.
- Model: højde h(s) er lineær over hvert stykke. `v² += 2·g·(h_prev − h) − friction·v²·ds`. På `lift`-stykker gælder `v = max(v, lift_speed)`, og på `station` gælder `v = station_speed`. `v ≤ 0.1` uden for lift/station ⇒ `ok = false` (`"too_slow"`). Vertikal g = 1 + v²·κ_v/9.81 (κ_v fra overgange mellem rise-værdier), lateral g = v²/(r·9.81) med r = 0,5 celle for kurver.
- `ride_ticks = ceil(duration_s · 20)` plus ilæsning (data). Alt er float-deterministisk: samme input giver bit-identisk output på samme platform. Testen sammenligner med en tolerance på 1e-4.

### 3.3 Vogne (sim-side)
- `Attraction.ride_progress() -> float` 0..1 for den igangværende tur (0 = station). Bridge omsætter progress til buelængde via profilen: `CoasterProfile.position_at(t: float) -> float` (s) og `speed_at(t) -> float`.

### 3.4 Ratings (`CoasterRatings`, static)
- `rate(profile: CoasterProfile, weights: Dictionary) -> Dictionary {"excitement": float, "intensity": float, "nausea": float}` (0..10, 2 decimaler). Vægtene ligger i `ratings.json` (længde, max_speed, drops, max_g, max_lat, varighed).
- Excitement bruges som `excitement` i besøgsvalg (skaleret ×10 til den nuværende 0..100-skala). Gæster med lav tolerance afviser rutsjebaner med intensity > deres grænse (`"too_intense"` som tanke/leave-reason). Nausea øger risikoen for `sick` efter turen. Tallene kommer fra data.

## 4. Save v2 (simulation, T-066 ejer bump; T-067/T-068 udfylder)
- `SaveMigrations.CURRENT = 2`. `_v1_to_v2` tilføjer `park.research = {}` (så alt er låst op og `enabled = false`, hvilket bevarer gammel adfærd), `park.scenario = null` (sandbox) og `attractions[].cells = []`, `track = null`, `ratings = {}`.
- Nye nøgler: `park.research` (`unlocked`, `funding_level`, `current_item`, `progress`, `priority`, `enabled`), `park.scenario` (`def_id`, `state`, `days_elapsed`, `lose_streaks`), `attractions[].track` (`[{def_id, cell, heading, level}]`), `attractions[].building` (bool, banen er under bygning).
- Tests: v1-fixture → v2 load, round-trip for park med forskning i gang, scenarie halvvejs og en lukket rutsjebane med tog i bevægelse giver identisk `to_save()` efter N ticks (determinisme).

## 5. Rendering (graphics, T-069), `game/scripts/rendering/coaster/`, `game/scenes/props/`
- `CoasterTrackMesh` (`class_name`, `extends MeshInstance3D`):
  - `build(pieces: Array[Dictionary], defs: Dictionary) -> void` bygger skinner, sveller og støtteben (lodrette søjler ned til terræn for level > 0) proceduralt. Input er `{def_id, cell, heading, level}`, og der er ingen afhængighed af sim-klasser.
  - `static centerline(piece: Dictionary, def: Dictionary, samples: int = 8) -> PackedVector3Array` i verdenskoordinater med cellemidte-konvention som i resten af scenen og 1 niveau = 1,0 m. Funktionen er offentlig, så bridge kan placere vogne.
  - `set_ghost(ok: bool)` giver en halvgennemsigtig grøn/rød materialevariant til preview.
- `CoasterTrain` (`Node3D`, scene `game/scenes/props/coaster_train.tscn`): `set_cars(n: int)` og `set_path_pose(points: Array[Transform3D])` (én transform pr. vogn). Den implementerer `RideVisual`-metoderne `set_running`, `set_broken` og `set_lights`.
- `coaster_station.tscn`: perron og tag, der passer til et 1-celle-stykke.
- Budget: én rutsjebane med 60 stykker ≤ 20k trekanter, og meshet genbygges kun ved ændring.
- Ikon/hængelås til låste bygninger: tegnes i UI (`draw_*`), ikke i rendering.

## 6. Gameplay/bridge (gameplay, T-070), `game/scripts/bridge|building/`
- `BuildTool`: nyt værktøj `"coaster:<def_id>"`. Første klik placerer stationen (R roterer heading). Herefter vælger UI et stykke (`set_coaster_piece(piece_id)`), og ghost-preview vises via `preview_track_piece`. Klik/Enter placerer, Backspace fjerner sidste stykke, og "Færdig" kalder `cmd_finish_coaster`, hvorefter fejlene vises som toast via `warning`-lignende signal `BuildTool.coaster_errors(codes: Array[String])`. Esc under bygning lader banen stå lukket og ufærdig (kan genoptages ved at vælge den og klikke "Fortsæt byg").
- `BuildTool` nægter låste id'er (`sim.is_unlocked`) og udsender `error`-lyd.
- `ParkView`: et `CoasterTrackMesh` pr. rutsjebane (genbygges ved `coaster_changed(coaster_id)`, et nyt sim-signal som T-068 tilføjer) og et `CoasterTrain` placeret hver frame ud fra `ride_progress` interpoleret mellem ticks → `profile.position_at` → centerlinjen.
- `GameSession`: `start_scenario(scenario_id: String, seed: int = randi())` og `start_sandbox(seed)` (`start_new` beholdes som alias for sandbox). `ParkView` bruger `ParkSim.new_from_scenario`. `scenario_finished` medfører pause (sim-hastighed 0) og at UI viser resultatet.
- Signaler videre til UI: `research_unlocked` → confetti-lyd/`cheer`. `scenario_finished(won)` → `cheer`/`error`.

## 7. UI (ui, T-071), `game/scripts/ui/`, `game/scenes/ui/`
- Hovedmenu: "Nyt scenarie" åbner en liste over `ScenarioDef.list_all()` med navn, beskrivelse og mål. "Fri leg" kalder `start_sandbox`. "Fortsæt" og "Indlæs" er uændrede.
- HUD: et mål-panel (skjult i sandbox) med `scenario_status()`, dag x/y og hvert mål med current/value og et flueben tegnet med `draw_*`.
- Resultatdialog ved `scenario_finished` med "Fortsæt i fri leg" og "Hovedmenu".
- Forskningspanel: finansieringsniveau 0..3 (med pris pr. dag), prioritet (emne-liste), aktuelt item og en progress-bar. Det skjules, når `research.enabled == false`. Toast ved `research_unlocked`.
- Byggemenu: låste elementer vises grået med hængelås (tegnet) og tooltip "Kræver forskning". Rutsjebane-fanen har en stykke-palet (ikoner tegnet med `draw_*`) og knapperne "Fjern sidste", "Færdig" og "Fortsæt byg". Fejlkoder oversættes til danske tekster.
- Info-panel for rutsjebane: excitement, intensity og nausea (0..10) samt længde, max fart (km/t) og max g.

## Ejerskab (hvem må røre hvad)
| Agent | Må røre | Må ikke røre |
|---|---|---|
| designer | `game/content/**` (inkl. `scenarios/`, `coaster/`), `docs/gdd.md` | kode |
| simulation | `game/simulation/`, sim-tests i `game/tests/`, save-fixtures i `game/tests/fixtures/` | scripts/, scenes/, content/ |
| graphics | `game/scripts/rendering/`, `game/scenes/props|effects|rendering/`, `game/shaders/`, `game/assets/` (ikke audio), `game/tests/test_props.gd` + `test_coaster_mesh.gd` | simulation/, bridge/, building/, ui/ |
| gameplay | `game/scripts/bridge|building|persistence/`, `game/scenes/main.tscn`, gameplay-tests | simulation/, rendering/, ui/ |
| ui | `game/scripts/ui/`, `game/scenes/ui/`, `game/scenes/main_menu.tscn`, UI-tests | simulation/, bridge/, rendering/ |
| qa | `game/tests/test_qa_m5.gd`, `tools/` | produktionskode |

## Parallelisering
- Runde 1 (parallelt): T-065 (designer), T-066 (sim: forskning + save v2), T-069 (graphics: mesh/tog, kan bruge hårdkodede stykke-defs, indtil T-065 lander).
- Runde 2: T-067 (sim: scenarier) og T-068 (sim: rutsjebane). Det er den samme agent og de samme filer (`park_sim.gd`), så de køres **sekventielt** i rækkefølgen T-067 → T-068.
- Runde 3 (parallelt): T-070 (gameplay) og T-071 (ui). UI kan bygges mod sim-API'et og kalder BuildTool-metoder, der er navngivet i §6.
- Runde 4: T-072 (QA).
