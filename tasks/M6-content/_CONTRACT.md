# M6 kontrakt – Mere indhold

Mål: alt indhold fra designerens godkendte forslag (`tasks/M6-content/T-079-design-more-content.md`, `docs/gdd.md`). Det er **10 forlystelser**, **8 butikker/sideshows** og **mekanik A–E**, og Bimmelbanen kører på rigtigt spor. Sporsystemet generaliseres efter `docs/adr/ADR-004-track-systems.md`.

Gælder fortsat (M5-reglerne):
- **Compatibility/web:** ingen compute, ingen Forward+-features, ingen `PhysicsServer` i sim. Meshes laves proceduralt med `SurfaceTool`/`ArrayMesh`/primitiver. Partikler skal være `CPUParticles3D`.
- **Lag:** `game/simulation/` er `RefCounted`/`Resource` uden noder. Ingen import fra `scripts/` eller `scenes/`.
- **Determinisme:** al tilfældighed (opkast, præmier, ballon flyver væk, tolerance pr. gæst) bruger simulationens seedede RNG i en fast rækkefølge og 20 tick/s. Ingen `randf()`/`randi()` globalt. Fysik og pathfinding med transportkanter skal give bit-identisk `to_save()` efter N ticks.
- **Data:** balance ligger i `game/content/`. UI-tekster bruger kun glyffer fra standardfonten (`test_hud_glyphs`).
- **Tests:** alle eksisterende tests, `integration.sh` og `balance.sh` skal være grønne efter hver task.

## Indholdsoversigt
| id | Navn | kind | Mekanik | Data-task | Sim | Props/mesh |
|---|---|---|---|---|---|---|
| bouncy_castle | Hoppeborgen | ride | B | T-081 | T-084 | T-083 |
| teacups | Tekopperne | ride | B | T-081 | T-084 | T-083 |
| trampoline | Springfjedrene | ride | B | T-081 | T-084 | T-083 |
| sky_rings | Himmelringene | ride | B | T-081 | T-084 | T-083 |
| pirate_ship | Gyngeskibet | ride | B | T-081 | T-084 | T-083 |
| space_rocket | Månefærgen | ride | B | T-081 | T-084 | T-083 |
| drop_tower | Faldtårnet | ride | B | T-081 | T-084 | T-083 |
| mini_train | Bimmelbanen | train | spor (ADR-004) | T-082 | T-090 | T-092 |
| log_flume | Tømmerrenden | flume | A | T-082 | T-090 | T-092 |
| monorail | Svævebanen | transport | C | T-082 | T-091 | T-092 |
| fries_stand | Fritterbixen | shop | – | T-081 | – | T-083 |
| coffee_stand | Kaffekoppen | shop | – | T-081 | – | T-083 |
| balloon_stand | Ballonbåsen | shop | E | T-081 | T-086 | T-083 + T-087 |
| souvenir_shop | Mindebutikken | shop | E | T-081 | T-086 | T-083 + T-087 |
| coconut_shy | Kokoskasteriet | sideshow | D | T-081 | T-085 | T-083 |
| shooting_gallery | Skydeteltet | sideshow | D | T-081 | T-085 | T-083 |
| hook_a_duck | Andefiskeriet | sideshow | D | T-081 | T-085 | T-083 |
| strength_tester | Kraftklokken | sideshow | D | T-081 | T-085 | T-083 |

Intensity/nausea (B) gælder **alle** forlystelser, også de eksisterende 6 og rutsjebanen.

## 0. Data (designer)
### T-081: bygninger uden spor, `game/content/attractions/*.json`, `research.json`
- 14 nye filer med de nuværende felter. Ukendte felter ignoreres af sim indtil T-084/T-085/T-086, og det skal stadig loades.
- **B-felter** på *alle* `kind: "ride"`, også eksisterende: `"intensity": 0..100`, `"nausea": 0..100` (default 0).
- **D-felter** på `kind: "sideshow"`: `"win_chance": 0..1`, `"prize_cost": int` (parkens udgift pr. gevinst), `"prize_happiness": float`, `"prize_item": "prize_duck" | "prize_bear" | ...`. `satisfies` er som for shops. `excitement` er glæden ved et tab.
- **E-felter** på shops, der sælger bærbare ting: `"carry_item": "balloon" | "souvenir"`.
- `game/content/items.json` (ny): `{ "items": [ { "id": "balloon", "happiness_per_hour": 2.0, "aura_radius": 2, "aura_happiness": 0.5, "lose_chance_per_hour": 0.05, "duration_hours": 0 }, ... ] }`. Det er alle bærbare ting: `balloon`, `souvenir` og præmierne.
- `guests.json`: `"intensity_tolerance": {"min": 10, "max": 90}` (fordeling pr. gæst), `"nausea_per_point": float`, `"vomit_threshold": float`, `"vomit_happiness": float` og `"vomit_litter": int`.
- `research.json`: nye topics `water_rides` og `sideshows`, item-points efter forslaget og `bouncy_castle` i `start_unlocked`.
- `vomit` tilføjes som affaldstype, hvis affald har typer i data. Ellers som `litter_kind` i `guests.json`.

### T-082: spor-data, `game/content/tracks/`, `attractions/`
- `tracks/flume.json`, `tracks/train.json` og `tracks/monorail.json` med `{ "system": {closed_loop, max_stations, clearance_levels, speed_mode}, "pieces": [...] }` efter ADR-004. Stykkerne følger samme skema som `coaster/pieces.json`, plus `system`, `splash`, `water`, `station_role`, `min_level`/`max_level`.
  - Flume skal mindst have `flume_station`, `flume_straight`, `flume_turn_left/right`, `flume_lift_up` og `flume_drop` (rise −2, `splash: true`).
  - Train skal mindst have `train_station`, `train_straight` og `train_turn_left/right` (rise kun 0, `max_level` 0).
  - Monorail skal mindst have `monorail_station_start`, `monorail_station_end`, `monorail_straight`, `monorail_turn_left/right` og `monorail_up/down` (`min_level` 2).
- `attractions/log_flume.json` (`kind: "flume"`, `train: "log_boat"`, `wet_thirst: -10`), `attractions/mini_train.json` (`kind: "train"`, `train: "mini_loco"`) og `attractions/monorail.json` (`kind: "transport"`, `train: "monorail_cabin"`, `transport_cost`: stigraf-vægt).
- Togene lægges i `coaster/trains.json` (eller `tracks/trains.json`, som så skal læses af `CoasterContent.trains()`). Til `constant`-systemer bruges `cruise_speed`.

## 1. Mekanik B – intensity og kvalme (simulation, T-084), samt save v3
- `AttractionDef.intensity: float` og `AttractionDef.nausea: float` (0..100, default 0). For rutsjebaner overskrives de af `ratings` ×10, som excitement gør i M5.
- `Guest.intensity_tolerance: float` trækkes med sim-RNG ved spawn fra `guests.json`. `Guest.nausea: float` (0..100) er et nyt behov, der falder langsomt over tid.
- Besøgsvalg: forlystelser med `intensity > intensity_tolerance` fravælges med reason `"too_intense"`. Forlystelser med `intensity < tolerance − 40` vægtes ned (`"too_tame"`, tanke).
- Efter en tur: `nausea += def.nausea * nausea_per_point`. Hvis `nausea ≥ vomit_threshold`, sker der med sim-RNG-sandsynlighed `(nausea − threshold)/(100 − threshold)` et **opkast**: der lægges `vomit_litter` affald af typen `vomit` på gæstens celle, glæden falder med `vomit_happiness`, nausea nulstilles, og der sendes `warning(&"guest_vomit", {"cell": c})`.
- Nyt signal `guest_vomited(guest_id: int, cell: Vector2i)`, som bridge bruger til effekt og lyd.
- Rengøring: opkast fjernes som affald (samme opgavesystem som T-076).
- **Save v3 (T-084 ejer bumpet):**
  - `SaveMigrations.CURRENT = 3` med `_v2_to_v3`, der tilføjer `guests[].intensity_tolerance = 50.0`, `guests[].nausea = 0.0`, `guests[].items = []` (E), `attractions[].prizes_won = 0` (D) og `litter[].kind = "litter"` (hvis der er affaldsliste).
  - De senere M6-sim-tasks (T-085, T-086, T-090, T-091) **udvider `_v2_to_v3`** med deres egne defaults i stedet for at bumpe igen. M6 udgives som én version.
  - Tests: v2-fixture → v3, og v1-fixture → v3 (kæde). Round-trip med gæster med kvalme og opkastet affald giver identisk `to_save()` efter N ticks.

## 2. Mekanik D – sideshow-præmier (simulation, T-085)
- `kind: "sideshow"` behandles som en shop i køer, pris og `satisfies`, men efter et besøg trækker sim-RNG en gevinst med `win_chance`.
- Ved gevinst: parken bogfører `prize_cost` som `"prizes"`, gæsten får `prize_happiness` og bærer `prize_item` (via E), og `attraction.prizes_won += 1`. Ved tab: gæsten får `excitement` som glæde.
- API: `attraction_stats(id)` udvides med `"prizes_won"` og `"prize_cost_total"`, og `finance_report()` får kategorien `"prizes"`.
- Signal: `prize_won(guest_id: int, attraction_id: int, item_id: String)`.

## 3. Mekanik E – bærbare ting (simulation, T-086)
- `ItemDef` (Resource) læses fra `items.json`. `Guest.items: Array[StringName]` har maks. én af hver id.
- Køb i en shop med `carry_item` eller en sideshow-gevinst giver en ting. Hver time: `happiness += happiness_per_hour`. Glæde-aura: andre gæster inden for `aura_radius` celler (manhattan, beregnet pr. time og ikke pr. tick) får `aura_happiness`.
- Ballonen flyver væk med `lose_chance_per_hour` (sim-RNG), hvilket udløser signalet `item_lost(guest_id, item_id, cell)` og en tanke.
- API: `guest_info(id)` udvides med `"items"`, `"nausea"` og `"intensity_tolerance"`. Signal: `item_gained(guest_id, item_id)`.

## 4. Generaliseret spor – A, Bimmelbanen og C (simulation, T-090 + T-091), ADR-004
### T-090: generalisering, vandbane og minitog
- `TrackPieceDef.system` og `CoasterContent.pieces(system)`. `cmd_start_coaster` vælger systemet ud fra `def.kind`. `cmd_place_track_piece` afviser stykker fra andre systemer med `false`, og `preview_track_piece` giver `reason: "wrong_system"`.
- `validate()` får fejlkoderne `"wrong_system"`, `"too_low"` (mindre end `min_level`) og `"incomplete"` (åbent system uden end-station). `clearance_levels` tages fra systemet i stedet for den faste værdi 2.
- **Vandbane (A):** profilen bruger stykkernes `friction`. `splash`-stykker tæller i `CoasterProfile.splashes: int`. Efter en tur får gæsten `thirst += wet_thirst` og tilstanden `Guest.wet_ticks` (data), der giver lidt glæde, hvis det er varmt (dag/nat-data). Signal `ride_splash(attraction_id, cell)`, når toget passerer et splash-stykke. Det udledes af `ride_progress` i sim-ticket og ikke i bridge, så det er deterministisk.
- **Minitog:** `speed_mode: "constant"` giver en profil med konstant fart og `ok = true`, og ratings kommer fra data (`excitement`/`intensity`/`nausea`).
- `Attraction.is_tracked()`. Alle steder, der i dag tjekker `kind == "coaster"`, skal i stedet bruge `is_tracked()`.

### T-091: transport (C)
- Monorail er et åbent system med `max_stations = 2`. `cmd_finish_coaster` kræver start- og end-station.
- `ParkWorld.add_link(a: Vector2i, b: Vector2i, cost: float, owner_id: int)`, `remove_links(owner_id)` og `links_from(cell) -> Array[Dictionary]`. Endepunkterne er stationernes indgangsceller, som skal støde op til en sti.
- `Pathfinder` bruger links som naboer, når `link_usable(owner_id)` returnerer sand (åben og ikke brudt ned). Det skal være deterministisk med stabil rækkefølge (sortér efter owner_id).
- Gæsten, der bruger en link, går i kø, betaler billet og "kører" `ride_ticks`, hvorefter hun står ved den anden stations indgang. En gæst, der ikke har råd, vælger en rute uden link.
- Save: links gemmes ikke, men genopbygges fra transport-attraktionerne ved load.

## 5. Grafik (graphics)
### T-083: props til 14 bygninger, `game/scenes/props/`
- Én scene pr. id med `RideVisual`-API (`set_running`, `set_broken`, `set_lights`) og animation, mens den kører (gyngende skib, roterende kopper, faldende gondol, hoppende borg).
- **Tema-element i stil med T-074:** `Theme`-undertræ med elementet fra forslaget (gummiand, tekande, planet med ring, blæksprutte, spiralfjeder, raket, termometer, pommes frites-bæger, dampende kop, balloner, snekugle, kokosnødder, blikand, gul and, klokke). Krav: ≤ 3000 trekanter pr. element, `plaster.png` triplanart, ingen strakte kugler eller skalerede/spejlede transforms, footprint/origin som data, og `test_rides_fully_textured` udvides til de nye props.
- Screenshots i opengl3 fra spillets kamera og som nærbilleder.

### T-087: bærbare ting og opkast
- `GuestVisual.set_items(items: Array[StringName])` viser ballon (på snor, svajer), souvenirpose eller præmie-bamse. Ballon, der flyver væk, er effekten `balloon_float(cell)`. Opkast er `vomit(cell)` med en lille pøl-decal (mesh og ikke projektor-decal, da Compatibility ikke understøtter det fuldt), og plask er `splash(cell)`. Alle tre partikeleffekter skal være `CPUParticles3D`.

### T-092: spor-meshes og køretøjer
- `CoasterTrackMesh.build` dispatcher på `system` (ADR-004 §5): flume-trug med vandoverflade (en simpel scrollende UV-shader er tilladt, hvis den virker i Compatibility, ellers vertex-farve), skinner med sveller på jorden til train og betonbjælke på søjler til monorail.
- `CoasterTrain.set_style(system)` dækker træstamme-båd, lokomotiv med overdreven skorsten og røgsky (`CPUParticles3D`) og kabine.
- Stationer med tema: Tømmerrenden har en kæmpe træstamme med økse, Bimmelbanen en perron med skorstens-ur, og Svævebanen har stationer formet som tandhjul.
- Budget: 60 stykker ≤ 20k trekanter pr. bane.

## 6. Gameplay/bridge
### T-088: B/D/E i scenen
- `guest_vomited` → effekten `vomit` og lyd. `prize_won` → `cheer` og pling. `item_gained`/`item_lost` → `GuestVisual.set_items` og `balloon_float`. Sideshows bygges med det generiske byggeværktøj.

### T-093: spor-værktøjer
- `BuildTool` `"coaster:<def_id>"` virker for kinds `flume`, `train` og `transport`. Paletten filtreres efter system (`CoasterContent.pieces(system)`). Svævebanen kræver 2 stationer, så UI'et tilbyder "Endestation", når banen er længere end 1 stykke.
- `ParkView`: `ride_splash` → effekten `splash`. Monorail-gæster, der kører, skjules og vises igen ved endestationen (bridge læser gæstens state `&"riding_transport"`).

## 7. UI
### T-089: B/D/E
- Info-panel for forlystelse: intensity- og kvalme-bjælker (0..10-visning). Gæsteinfo: kvalme, tolerance og bærbare ting som tegnede ikoner. Sideshow-panel: gevinstchance, præmier vundet og præmieudgift. Økonomi har kategorien "Præmier". Tankerne `too_intense`, `too_tame`, `vomit` og `balloon_lost` får danske tekster.

### T-094: spor
- Byggemenuen har faner pr. sporsystem eller én "Spor"-fane med undertyper. Fejlkoderne `wrong_system`, `too_low` og `incomplete` får dansk tekst. Info-panelet for tømmerrenden viser plask, og for svævebanen vises passagerer pr. dag.

## 8. Balance og QA
- **T-095 (designer):** intensity/nausea for alle forlystelser, præmie-økonomi, bærbare ting og track-priser. `balance.sh` skal vise, at opkast ikke dominerer affaldet (< 15 %), og at sideshows har en positiv margin.
- **T-096 (qa):** `game/tests/test_qa_m6.gd`, der verificerer alle acceptkriterier, v1→v3- og v2→v3-loads, determinisme (N ticks i en park med alle 18 nye bygninger og 3 sporbaner) og web-build. Visuelle ting bliver på `review`, indtil brugeren har set dem.

## Ejerskab (hvem må røre hvad)
| Agent | Må røre | Må ikke røre |
|---|---|---|
| designer | `game/content/**` (inkl. `tracks/`, `items.json`), `docs/gdd.md` | kode |
| simulation | `game/simulation/`, sim-tests i `game/tests/`, `game/tests/fixtures/` | scripts/, scenes/, content/ |
| graphics | `game/scripts/rendering/`, `game/scenes/props|effects|rendering/`, `game/shaders/`, `game/assets/` (ikke audio), prop-/mesh-tests | simulation/, bridge/, building/, ui/, content/ |
| gameplay | `game/scripts/bridge|building|persistence/`, `game/scenes/main.tscn`, gameplay-tests | simulation/, rendering/, ui/, content/ |
| ui | `game/scripts/ui/`, `game/scenes/ui/`, `game/scenes/main_menu.tscn`, UI-tests | simulation/, bridge/, rendering/, content/ |
| qa | `game/tests/test_qa_m6.gd`, `tools/` | produktionskode |
| architect | `docs/adr/`, `docs/conventions.md`, `tasks/` | game/ |

## Runder
1. **Data og props (parallelt):** T-081 → T-082 (designer, sekventielt), T-083 (graphics, kan bruge footprints fra forslaget, før T-081 lander). Den aktive T-078 i `game/content/scenarios/` må ikke blive rørt af T-081/T-082.
2. **B og D (simulation, sekventielt):** T-084 (B + save v3) → T-085 (D).
3. **E og præsentation:** T-086 (sim E) først. Derefter parallelt T-087 (graphics), T-088 (gameplay) og T-089 (ui).
4. **Spor (parallelt mellem agenter):** T-090 → T-091 (simulation, sekventielt, samme filer) og T-092 (graphics, parallelt).
5. **Spor i scenen:** T-093 (gameplay) og T-094 (ui) parallelt. Derefter T-095 (balance).
6. **QA:** T-096.
