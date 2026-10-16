# T-095: Balance: M6-indhold

- **Status:** review
- **Milepæl:** M6
- **Agent:** designer
- **Afhænger af:** T-089, T-093, T-094

## Mål
Justering af intensity/nausea, præmier, ting og sporpriser (kontrakt §8). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] Opkast er < 15 % af affaldet i `balance.sh`
- [x] Sideshows har positiv margin
- [x] De nye forlystelser bliver faktisk valgt af gæsterne i simuleringen
- [x] Kun data og gdd er ændret

## Log
- 2026-10-15 – architect: oprettet

- 2026-10-16 – orkestrator: T-088 opfølgning – lyd-id `vomit` mangler i content/audio.json; tilføj her.
- 2026-10-16 – orkestrator: T-092 opfølgning – log_flume/mini_train/monorail.json skal pege på flume_station/train_station/monorail_station.tscn i `model`.
- 2026-10-16 – orkestrator: balance.sh (11m48s, hænger ikke) efter T-084..T-086: Bjergtoppen kun vundet 1/5 (var vindbar efter T-078), Grøn eng 3/5, Floddalen 5/5. Ret op.
- 2026-10-16 – orkestrator: T-091 – tilføj `wet_ticks`/`wet_happiness_per_tick` i guests.json; T-090 nye fejlkoder `exit_blocked`/`stations_too_close` (tekster tages i T-094).
- 2026-10-16 – orkestrator: lyd-id `splash` mangler også i content/audio.json (T-093).
- 2026-10-16 – orkestrator: research.json – log_flume, mini_train og monorail står i topics.unlocks men mangler i "items", så de kan formentlig aldrig forskes frem i scenarier. Tjek også spor-stykker for flume/train/monorail.
- 2026-10-16 – designer: udført.
  - audio.json: `vomit` og `splash` tilføjet. guests.json: `wet_ticks` 600, `wet_happiness_per_tick` 0.005. log_flume/mini_train/monorail `model` → flume_/train_/monorail_station.tscn.
  - Sideshows (før: 20–30 besøg/5 dage, drift 50–90/dag → negativ margin): excitement 4–5 → 14/15/16/16, intensity 0 → 25/30/15/35, drift → 25/30/15/15, pris kokos 3/skyde 4/kraft 3, andefiskeri prize_cost 1. Måling (5 dage, park med alle 13 rides + alle shops, 3 seeds): 70–110 besøg pr. sideshow, netto positiv for alle fire.
  - Opkast: 1–8 opkast pr. 5 dage, 0–5 % af stående affald (< 15 %). Alle 13 ride-typer vælges (drop_tower lavest, ~16–34 besøg).
  - Scenarier: Grøn eng 120 → 115 gæster; Bjergtoppen 85 → 75 gæster, parkværdi 100000 → 92000, omdømme 55 → 52. balance.sh før: Grøn eng 3/5, Floddalen 5/5, Bjergtoppen 1/5. Efter: 5/5, 5/5, 5/5. test.sh 299/0, integration OK.
  - Opfølgning (sim): balloon_stand/souvenir_shop får 0 besøg – shops med `satisfies: {}` vælges aldrig (kun behovsdrevet shop-valg). Kræver impulskøb i sim. balance.sh måler ikke opkast/sideshow-margin (målt med midlertidigt script).
- 2026-10-16 – designer: opfølgning. research.json `items` += mini_train (gentle_rides, 140), monorail (gentle_rides, 260), log_flume (water_rides, 220). Tjek: alle id'er i `topics[].unlocks` findes nu i `items` (python: `[u for t in topics for u in t.unlocks if u not in item_ids] == []`). test.sh 303/0, balance.sh 5/5 i alle tre scenarier.
  - **BLOKERET (kræver sim/test):** sporstykkerne i `tracks/*.json` (flume_*, train_*, monorail_*) er ikke låst op nogen steder, og `cmd_start_coaster`/`cmd_place_track_piece` kræver `is_unlocked(piece_id)`. Så i scenarier med forskning kan banerne stadig ikke bygges. Jeg prøvede at lægge stykkerne i `start_unlocked`, men `test_research_ids_exist_in_catalog` afviser id'er, der ikke er `track_*`, eller som ikke står i `coaster/pieces.json`. Det blev derfor rullet tilbage. Forslag: sim betragter stykker fra ikke-coaster-systemer som låst op, når banens def er låst op, eller testen accepterer id'er fra `tracks/*.json` (så kan data lægge dem i start_unlocked).
- 2026-10-16 – simulation (opfølgning T-119): sporstykker fra ikke-coaster-systemer (flume_*, train_*, monorail_* inkl. stationer) regnes som låst op, når en bane af systemet er låst op (`ParkSim.is_unlocked`). Rutsjebanestykker forskes fortsat individuelt. Test: `test_research.gd::test_flume_pieces_follow_ride_unlock`. test.sh 304/304, integration OK.
  - 2026-10-16 – designer (T-095): `impulse` tilføjet i guests.json (0.35/12/40/1.0, uændret). Måling i en park med alle 13 forlystelser og alle butikker, 5 dage, seeds 1/2/3: Ballonbåsen 0/0/0 → 179/203/182, Mindebutikken 0/0/0 → 114/134/96 (ca. 1070 gæster i alt). Besøg på forlystelser 1588/1606/1564 → 1568/1508/1487 (−1 til −6 %). Øvrige boder er stort set uændrede. balance.sh 5/5 i alle tre scenarier (scenarie-botten bygger ikke ballon- og souvenirbutikker, så resultaterne er de samme som før). test.sh 304/0.
