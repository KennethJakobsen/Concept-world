# M3 kontrakt – Spilbar loop

## Save/load
- Format: JSON, `{"save_version": 1, "game_version": "0.3", "created": iso, "park": {...}}`.
- `ParkSim.to_save() -> Dictionary`, `static ParkSim.from_save(d: Dictionary) -> ParkSim` (eller `load_save(d)`), migrationer via `SaveMigrations.migrate(d) -> Dictionary` (version-trin).
- Alt simulation-state inkl. RNG-state, tick, økonomi-historik, gæster (position, behov, mål), køer, personale, affald.
- `SaveStore` (simulation-neutral, i `game/scripts/persistence/`): `save(slot:String, d)`, `load(slot) -> Dictionary`, `list() -> Array`, `delete(slot)`. Bruger `user://saves/<slot>.json` (virker på web via IndexedDB). Autosave-slot `"autosave"` hver spildag.
- Krav: gem → indlæs → kør N ticks giver identisk state som uden gem (determinisme-test).

## Personale
- `game/content/staff/<id>.json`: `{ "id", "name", "wage_per_day", "speed", "work_radius" (0 = hele parken), "model" }`
- Typer M3: `mechanic` (reparerer nedbrudte forlystelser, laver forebyggende inspektion), `cleaner` (fejer affald, tømmer skraldespande), `entertainer` (øger glæde for gæster i radius).
- `ParkSim.cmd_hire_staff(type_id, cell) -> int` (id), `cmd_fire_staff(id) -> bool`, `cmd_move_staff(id, cell) -> bool`, `ParkSim.staff: Dictionary`, signaler `staff_hired(s)`, `staff_fired(id)`. Personale går på stier.

## Nedbrud
- Ride-def nye felter: `reliability` (0..1, sandsynlighed for ikke-nedbrud pr. tur), `repair_ticks`.
- `Attraction.status`: `OPERATING | BROKEN | CLOSED`. Ved nedbrud: rytterne færdiggøres, kø opløses med tanke "Den er i stykker!", mekaniker kaldes (nærmeste ledige). Signal `attraction_broken(a)`, `attraction_repaired(a)`.
- Uden mekaniker forbliver den i stykker.

## Affald og dekoration
- Gæster smider affald efter mad/drikke (sandsynlighed, lavere hvis skraldespand inden for N celler). `ParkWorld` har affald pr. sti-celle (0..n). Glæde falder når gæster går over beskidte stier ("Her er beskidt!").
- Dekorationer i `game/content/decor/<id>.json`: `{ "id","name","kind":"bin|bench|tree|flowers|lamp","footprint":[1,1],"build_cost","on_path": bool, "happiness_aura": float, "aura_radius": int, "model" }`. Bænk og skraldespand står på sti-kanten (on_path=true, deler celle med sti), træer/blomster på græs.
- `cmd_place_decor(def_id, cell) -> int`, `cmd_remove_decor(id)`, signaler `decor_placed(d)`, `decor_removed(id)`. Bænke: trætte gæster hviler (energi ned).

## Nye forlystelser (M3)
- `swing_ride` (svingkarrusel) 3×3, `haunted_house` (spøgelseshus) 3×2, `go_karts` 4×3. Samme skema som M2 + reliability/repair_ticks.

## UI
- Hovedmenu (Ny park / Fortsæt / Indlæs / Afslut – afslut skjules på web).
- Pause-menu (Esc når intet værktøj aktivt): Gem / Indlæs / Hovedmenu.
- Personale-panel: ansæt (vælg type → placer på sti), liste med løn og status, fyr.
- Bygningspanel viser status (kører/i stykker/lukket) og pålidelighed.
