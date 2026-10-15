# T-036: Simulation – Save/load med versionering

- **Status:** review
- **Milepæl:** M3
- **Agent:** simulation
- **Afhænger af:** T-033

## Mål
Fuld serialisering af ParkSim inkl. RNG og alle under-objekter, migrationsramme og determinismetest. SaveStore i game/scripts/persistence/ må simulation-agenten også lave (ren fil-I/O). Se `_CONTRACT.md`.

## Acceptkriterier
- [x] to_save/from_save for alt state
- [x] Determinisme-test: gem midtvejs → indlæs → identisk state efter 2000 ticks
- [x] Migration-test (v0 dummy → v1)
- [x] SaveStore med tests (user://)
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: startet
- 2026-10-15 – simulation: Implementeret. `ParkSim.to_save()` → `{save_version, game_version, created, park}`; `static ParkSim.from_save(d, balance=null)` (migrerer, returnerer null ved ugyldig/nyere save). Hver klasse har sin egen `to_save()`/`from_save()`/`load_save()` (Guest, Attraction, AttractionDef.to_dict, Economy, SimClock, ParkWorld). RNG gemmes som strenge (seed+state er uint64). Floats: `SaveCodec.f()` gemmer tal direkte når de overlever JSON-roundtrip bit-præcist, ellers som "f:<int64-bits>" – nødvendigt, da Godots JSON ikke altid er bit-præcis (93.72000000000025 → …24). Attraktioner gemmes med def_id + def-snapshot (content vinder; snapshot er fallback for stub/fjernet content). Signaler genskabes via ny ParkSim-instans + _on_attraction_placed. Load udsender ikke tile_changed/attraction_placed – bridge skal genopbygge visningen fra den nye sim (setup(sim) på en frisk ParkView). `SaveMigrations` (CURRENT=1) med trin v0→v1 (dummy: ingen envelope + flade needs_*). `SaveStore` (game/scripts/persistence/save_store.gd): save/load/list/delete/exists, base_dir injicerbar, AUTOSAVE_SLOT="autosave"; autosave-hook ved day_passed skal kobles af gameplay/UI. Udvidelse til T-037: tilføj nøgler i `_park_to_save()`/`_park_load()` (med defaults). Tests: test_save_load.gd (8 – inkl. determinisme: gem midt i dag 1 → load → 2000 ticks → bit-identisk park + rng), test_save_store.gd (3). 81/81 grøn.
