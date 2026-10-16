# M7 kontrakt – Dybde og UX

Grundlag: `docs/gdd.md` §M7 (T-097) og `docs/adr/ADR-005-guest-mass-queues.md`. **Implementeringen starter først, når T-096 er done.**

Gælder fortsat (M5/M6-reglerne): Compatibility/web (ingen compute, `CPUParticles3D`, procedurelle meshes), `game/simulation/` består af `RefCounted`/`Resource` uden noder og uden import fra `scripts/`/`scenes/`, determinisme (seedet sim-RNG, 20 tick/s, fast rækkefølge efter id), balance ligger i `game/content/`, UI bruger kun glyffer fra standardfonten (`test_hud_glyphs`), og alle tests, `integration.sh` og `balance.sh` skal være grønne efter hver task.

## Beslutninger (architects svar på GDD'ens åbne spørgsmål)
| # | Spørgsmål | Beslutning |
|---|---|---|
| 1 | Fortryd | Kommandostak med inverse kommandoer i sim (`UndoStack`). Den har 20 skridt og fører pengene præcist tilbage, men gæster, tid og RNG rulles ikke tilbage. Den gemmes ikke. ADR-005 §4. |
| 2 | Gæsteseparation, 500+ gæster | Sim bruger en belægningstæller pr. celle (maks 6). Undvigelsen er rent visuel. Gæster tegnes med MultiMesh/LOD. ADR-005 §1, §7. |
| 3 | Køstier i pathfinding | Celletypen `QUEUE`, som `PathFinder` ikke følger. Køen er en ordnet cellekæde fra indgangen. ADR-005 §2. |
| 4 | Flyt sporbaner | **Ja** (brugeren): hele banen flyttes og roteres i 90°-trin som en stiv helhed. ADR-005 §5. |
| 5 | Salgssignal | `sales_tick(Dictionary)` én gang pr. tick. Bridge samler i 0,25 s-vinduer. |
| 6 | Brugerindstillinger | Den eksisterende `user://settings.cfg` (bruges allerede af `AudioManager`) får sektionerne `[ui]` og `[accessibility]`. Ingen ny fil. Indstillingerne er ikke en del af saven. |
| 7 | Milepæle i gamle saves | **Ja** (brugeren): migrationen sætter `milestones_backfill = true`, og sim evaluerer de betingelser, der kan beregnes fra state, ved første tick efter load. Det udløser ingen belønninger i penge/point, kun låser op for grene, og der vises ingen toasts. |
| 8 | Opskrifter i saven | Ja, pr. bygningsinstans: `attractions[].recipes: Array[String]`, default `[]`. |

## 0. Data (designer, T-100)
- `attractions/*.json`: valgfrit `config` (`capacity`/`ride_ticks`/`speed` som `{min,max,default}`), `recipes` (shops) og `price_effects` (shops) efter GDD §1. `speed` gives kun til flat rides. Sporbaner har ingen `config` i M7.
- `attractions/atm.json` (`kind: "atm"`, 1×1, build 400, upkeep 20, research `shops` 90, `withdraw: {min:20,max:50}`, `fee: 1`, `max_per_visit: 2`, `range_cells: 30`, `min_happiness: 40`).
- `guests.json`: `queue_patience_ticks {min,max}`, `queue_impatient_decay`, `queue_abandon_happiness`, `queue_weight_cells`, `leave_energy`, `guest_radius` (kun visuel), `max_guests_per_cell`, `crowd_reroute_ticks`, `crowd_ticks`, `crowd_decay`.
- `park.json`: `queue_slots_per_cell`, `queue_default_max`, `queue_entertained_factor`, `queue_path_cost`/`queue_path_refund`, `dark_path_penalty_per_tick`, `sell_full_refund_ticks` (200), `undo_steps` (20), `surroundings {wall, margin_cells, theme}`.
- `decor/*.json`: bænk `seats: 2`, lampe `night_aura: 1.5` og spand `capacity` (fyldniveau).
- `milestones.json` (ny) med de 6 milepæle fra GDD §10. `research.json`: `start_topics: ["gentle_rides","shops"]`. Scenarier kan have `"milestones": false` og `surroundings.theme`.
- `scenarios/tutorial.json` laves først i T-114.

## 1. Simulation – API (alle nye felter har defaults)

### T-102: config, opskrifter, prisvirkninger, salg og save v4
- `AttractionDef.config: Dictionary`, `recipes: Array[Dictionary]` og `price_effects: Array[Dictionary]`.
- `Attraction.config: Dictionary` (kun ændrede nøgler, ellers defaults fra def), `Attraction.recipes: Array[String]`, `Attraction.customers_today: int`, `revenue_days: PackedInt32Array` (de sidste 7 dage) og `payback_day: int` (-1).
- `cmd_set_config(id: int, key: String, value: float) -> bool` (clamp til min/max, gælder fra næste tur) og `cmd_set_recipe(id: int, recipe_id: String, on: bool) -> bool`.
- `effective_config(id) -> Dictionary` (`capacity`, `ride_ticks`, `speed` og afledte `upkeep_per_day`, `excitement`, `intensity`, `nausea`).
- Formlerne i GDD §1 bruges til drift, excitement, intensity, nausea og reliability. `cost_per_sale` bogføres som kategorien `"supplies"` i `finance_report()`.
- `price_effects`: et ekstra køb med sim-RNG, `nausea +=` og tanken `too_much`.
- Signal `sales_tick(sales: Dictionary)` (building_id → kr i ticket). `attraction_stats(id)` udvides med `revenue_today`, `revenue_yesterday`, `revenue_total`, `upkeep_total`, `net_total`, `customers_today`, `revenue_days` og `payback_day`.
- **Save v4 (T-102 ejer bumpet):** `SaveMigrations.CURRENT = 4`, `_v3_to_v4`. De senere M7-sim-tasks **udvider `_v3_to_v4`** og bumper ikke igen. Samlede defaults:

| Sti | Default | Task |
|---|---|---|
| `attractions[].config` | `{}` | T-102 |
| `attractions[].recipes` | `[]` | T-102 |
| `attractions[].customers_today` | `0` | T-102 |
| `attractions[].revenue_days` | `[]` | T-102 |
| `attractions[].payback_day` | `-1` | T-102 |
| `attractions[].built_tick` | `0` (gamle bygninger kan ikke fuld-refunderes) | T-106 |
| `paths[].kind` / `queue_paths` | `"path"` / `[]` | T-103 |
| `guests[].patience` | `1050` (midten af intervallet) | T-103 |
| `guests[].queue_index` | `-1` | T-103 |
| `guests[].blocked_ticks` | `0` | T-103 |
| `guests[].leaving` | `false` | T-104 |
| `guests[].atm_uses` | `0` | T-104 |
| `guests[].resting_on` | `-1` (bænk-decor-id) | T-104 |
| `decor[].fill` | `0` | T-104 |
| `park.milestones` | `[]` | T-105 |
| `park.milestones_backfill` | `true` for migrerede saves, `false` for nye | T-105 |

- Ikke gemt (genberegnes): belægning, crowd-tællere, `queue_cells`, undo-stak, bænke-pladser (fra `resting_on`), links.
- Tests: v3→v4, v2→v4 og v1→v4 (kæde). Round-trip med config og opskrifter giver identisk `to_save()` efter N ticks.

### T-103: køstier, tålmodighed, ledig frem for optaget, masse (ADR-005 §1–3)
- `ParkWorld.CellKind.QUEUE`, `cmd_place_queue_path(cell) -> bool` og `cmd_remove_queue_path(cell) -> bool`. `Attraction.queue_cells` og `queue_capacity() -> int`.
- `Guest.patience`, `queue_index` og `blocked_ticks`. Tanker: `queue_too_long`, `queue_bored`, `crowded`.
- `ParkWorld.occupancy(cell) -> int` og `crowded_cells() -> Array[Vector2i]` (til overlay).
- `attraction_stats` udvides med `queue_length`, `queue_capacity` og `wait_ticks_estimate`.
- Signal `queue_changed(attraction_id: int)`.

### T-104: gå hjem, hæveautomat, spande, bænke og lys
- `Guest.leaving` (tilstand `LEAVING`, sti til porten). Tanker: `tired`, `no_money`, `unhappy`.
- ATM: `kind == "atm"` og signal `atm_used(guest_id, attraction_id, amount)`. Gebyret bogføres som `"atm_fees"`.
- `Decor.fill` og `decor_info(id)` med `fill_ratio` og `occupants`. Fuld spand tæller ikke, og overløb lægges på cellen. Signal `bin_state_changed(decor_id: int, level: int)` (0/1/2 = 0/50/100 %).
- Bænk: `Guest.resting_on` og signal `guest_sat(guest_id: int, decor_id: int, seat: int)`/`guest_stood(guest_id: int)`.
- Lys: `ParkWorld.light_level(cell) -> float` (afhænger af dag/nat-fasen i sim) og straffen `dark_path_penalty_per_tick`.
- `litter_at(cell) -> Array[Dictionary]` (`{kind, index}`, så rendering kan placere props deterministisk) og signal `litter_changed(cell)`.

### T-105: milepæle
- `MilestoneDef` (Resource) og `Milestones` (RefCounted). `milestones() -> Array[Dictionary]` (`{id, name, achieved, progress 0..1, reward}`). `topic_available(topic_id) -> bool`, som `cmd_set_research_priority` respekterer.
- Signal `milestone_achieved(id: String)`. Sandbox: alt er åbent og giver ingen belønning. `scenario.milestones == false` slår systemet fra.
- Backfill (beslutning 7): sim evaluerer de betingelser, der kan beregnes fra state (`total_guests`, `rides_open`, `reputation`, `coaster_built`, `total_revenue`). `days_clean` kan ikke beregnes og må vente. Backfill udsender ingen toast-signal, men `milestones_backfilled(ids: Array)`.

### T-106: flyt, sælg-refusion og fortryd (ADR-005 §4–5)
- `cmd_move_attraction(id: int, origin: Vector2i, rotation: int) -> Dictionary` (`{ok, reason}`), som også virker for sporbaner. `preview_move(id, origin, rotation) -> Dictionary` (`{ok, reason, cells}`).
- `cmd_move_decor(id, cell) -> bool` og `cmd_move_staff` (findes).
- `sell_refund(id) -> int`: 100 % inden for `sell_full_refund_ticks` efter `built_tick`, og kun hvis `customers_total == 0`. Ellers som i dag.
- `cmd_undo() -> Dictionary`, `cmd_redo() -> Dictionary` (`{ok, reason, kind}`), `can_undo() -> bool`, `can_redo() -> bool` og `undo_label() -> String`. Signal `undo_changed()`.
- Fortrydes: sti, køsti, bygning (inkl. sporbane som helhed), pynt, flyt, sælg, pris, config og opskrift. Fortrydes ikke: tid, forskning, entré, personale og åbning/lukning.

## 2. Grafik
- **T-107:** skrald-props (1–5 pr. celle, position = hash(cell, index)), spand med fyldniveau og fuld-ikon, siddende gæst på bænk, ATM-prop med tema, mesh til køsti (rækværk) og visuel separation/baner i `GuestVisual` (ADR-005 §1). `GuestCrowdRenderer` (MultiMesh + LOD, ≤ 120 individuelle visuals) og svævetal `FloatingText3D` (`show_amount(pos, amount, color)`). Det hele skjules over 40 m.
- **T-108:** omgivelser: hæk/hegn-mur med port, et bælte på 24 celler med græs, træer, mark og vej, kosmetiske biler/busser og gæster fra stoppested til port. Læser `park.json.surroundings` og scenariets tema (countryside/river/mountain). Ingen sim-afhængighed.
- **T-109:** `OverlayRenderer` (`show(kind: StringName, data: Dictionary)`/`hide()`) til glæde, skrald, kø, dækning og lys. Resten af verden dæmpes. `ColorPalette` (viridis og farveblind-par blå/orange) bruges af ghosts, overlays og UI. Ghost-farver kommer fra paletten.

## 3. Gameplay/bridge
- **T-110:** værktøjer: `BuildTool`-tilstandene `queue_path`, `move` (M) og rotér (R, også for sporbaner som helhed) samt Ctrl+Z / Ctrl+Shift+Z → `cmd_undo/redo`. Ghost med pris ved musen. Sælg viser `sell_refund` før klik. Stier, der mister forbindelsen efter et flyt, markeres røde.
- **T-111:** bridge for M7-signaler: `sales_tick` → `FloatingText3D` (0,25 s-samling, kun hvis `settings.floating_money` er slået til) og `GameSession.money_flash(sign)`. `litter_changed`/`bin_state_changed`/`guest_sat`/`atm_used`/`queue_changed` → visuals. `GameSession.overlay_data(kind) -> Dictionary` samler data fra sim til `OverlayRenderer`. `GameSession.focus_cell(cell)` bruges, når der klikkes på en toast.

## 4. UI
- **T-101 (tidligt, før de andre UI-tasks): UX-fundament.** Skærmzoner efter GDD §4: `TopBar`, `BuildDock` (6 kategorier + bakke med kort), `Inspector` (højre panel med faner og et API, som senere tasks udvider), `ParkRail` (venstre kant), `AlertTray` (toasts med klik → `focus_cell`) og `TooltipService` (0,4 s). Den eksisterende funktionalitet flyttes ind i de nye zoner uden ændringer i sim. `UserSettings` udvider `user://settings.cfg` med `[ui] scale, floating_money` og `[accessibility] colorblind`. UI-skala bruger `content_scale_factor`.
  - Udvidelses-API (kontrakt for T-112/T-113/T-116): `Inspector.register_tab(context: StringName, tab_id: StringName, title: String, factory: Callable)`, `ParkRail.register(id, icon, panel_factory)`, `AlertTray.push(text, icon, cell := Vector2i(-1,-1))` og `TooltipService.attach(control, title, body)`.
- **T-112:** Inspector-faner for bygninger: Indstillinger (skydere for config, opskrift-afkrydsning og pris-stepper med advarsel ved < 0,6×), Økonomi (tal, sparkline over 7 dage og "Tjent hjem på dag N") og Kø (længde/kapacitet, ventetid og tålmodighed). Kontrollerne kalder `cmd_*`, så handlingerne kan fortrydes.
- **T-113:** milepælspanel (ParkRail, fremskridtslinjer og toast + fanfare ved `milestone_achieved`), overlay-vælger med legende, indstillingspanel (UI-skala, farveblind og svævetal), låste forskningsgrene med en tekst om, hvilken milepæl der åbner dem, og danske tekster til de nye tanker (`m7_texts.gd`). Pengeblink i TopBar.
- **T-116:** tutorial-UI (trinpanel og "Spring over").

## 5. Tutorial, balance og QA
- **T-114 (designer):** `scenarios/tutorial.json` med `steps: [{id, text, highlight, complete_when}]`. `complete_when` er en af: `path_connected_to_entrance`, `attraction_built:<kind>`, `price_changed`, `overlay_opened:<kind>` og `staff_hired:<type>`.
- **T-115 (gameplay):** `TutorialDirector` i bridge lytter på sim- og UI-signaler og viser pile i verden. Sim ændres ikke.
- **T-117 (designer):** balance: config-tradeoffs, ekstra salt (+10–20 % drikkesalg), køkapacitet og tålmodighed (≤ 10 % opgiver i en sund park), ATM (+15–25 % omsætning) og milepælstempo (første tema-gren inden dag 5 i startpark).
- **T-118 (qa):** `test_qa_m7.gd`, v1/v2/v3→v4-loads, backfill, determinisme med 500 gæster, ydeevnebudget (ADR-005 §7, inkl. web med ≥ 30 fps) og web-build. Visuelle ting bliver på `review`, indtil brugeren har set dem.

## Ejerskab
| Agent | Må røre | Må ikke røre |
|---|---|---|
| designer | `game/content/**`, `docs/gdd.md` | kode |
| simulation | `game/simulation/`, sim-tests, `game/tests/fixtures/` | scripts/, scenes/, content/ |
| graphics | `game/scripts/rendering/`, `game/scenes/props|effects|rendering/`, `game/shaders/`, `game/assets/`, render-tests | simulation/, bridge/, building/, ui/, content/ |
| gameplay | `game/scripts/bridge|building|persistence/`, `game/scenes/main.tscn`, gameplay-tests | simulation/, rendering/, ui/, content/ |
| ui | `game/scripts/ui/`, `game/scenes/ui/`, `game/scenes/main_menu.tscn`, UI-tests. T-101 må læse/skrive i `user://settings.cfg` via `ConfigFile` uden at fjerne `AudioManager`s nøgler | simulation/, bridge/, rendering/, content/, `scripts/audio/` |
| qa | `game/tests/test_qa_m7.gd`, `tools/` | produktionskode |
| architect | `docs/adr/`, `docs/conventions.md`, `tasks/` | game/ |

## Runder (efter T-096 done)
1. **Fundament (parallelt):** T-100 (designer, data), T-101 (ui, UX-fundament) og T-108 (graphics, omgivelser).
2. **Sim A og visuals:** T-102 (sim, save v4). Parallelt T-107 (graphics).
3. **Sim B og inspektør:** T-103 → T-104 → T-105 (sim, sekventielt i samme filer). Parallelt T-112 (ui, kræver T-101 + T-102) og T-109 (graphics).
4. **Flyt/fortryd og bridge:** T-106 (sim). Parallelt T-111 (gameplay, kræver T-104/T-107/T-109).
5. **Værktøjer og paneler:** T-110 (gameplay, kræver T-106) og T-113 (ui, kræver T-105/T-111) parallelt. Derefter T-114 (designer).
6. **Tutorial og balance:** T-115 (gameplay) og T-116 (ui) parallelt, derefter T-117 (designer).
7. **QA:** T-118.
