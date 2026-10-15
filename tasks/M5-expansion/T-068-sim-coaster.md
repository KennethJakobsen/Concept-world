# T-068: Sim – rutsjebane: bane, validering, fysik, ratings

- **Status:** review
- **Milepæl:** M5
- **Agent:** simulation
- **Afhænger af:** T-065, T-066, T-067 (samme filer, køres sekventielt)

## Mål
Implementér `_CONTRACT.md` §3 og ADR-003.

## Acceptkriterier
- [x] `TrackPieceDef`, `TrackPiece`, `CoasterTrack` (`next_entry`, `is_closed`, `validate` med alle fejlkoder)
- [x] `cmd_start_coaster`, `cmd_place_track_piece`, `cmd_remove_last_piece`, `cmd_finish_coaster`, `can_place_track_piece`, `preview_track_piece` og signalet `coaster_changed(coaster_id)`
- [x] Kollisionsregler (sti, bygning, decor, egen og anden bane, |Δlevel| ≥ 2). `ParkWorld.occupied_by_track`, og stier og bygninger afvises under lave baner
- [x] `CoasterPhysics.simulate`, `CoasterProfile` (`position_at`, `speed_at`) og `CoasterRatings.rate`. En test af en lukket oval med kendt profil (fart og ratings inden for tolerance) og en test af en bane, der er for flad (`too_slow`)
- [x] Rutsjebanen fungerer som `Attraction`: kø, billet, nedbrud, mekaniker og `ride_progress()`. Gæsterne afviser ved for høj intensitet, og nausea påvirker `sick`
- [x] Låste stykker afvises (`is_unlocked`)
- [x] Save round-trip for en bane under bygning og en lukket bane med kørende tog. Profilen genberegnes ved load og er identisk
- [x] `tools/test.sh`, `tools/integration.sh` og `tools/balance.sh` er grønne

## Ejer / må ikke røre
Som T-066.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: implementeret i `game/simulation/coaster/` (TrackPieceDef, TrackPiece, CoasterTrack, CoasterPhysics, CoasterProfile, CoasterRatings, CoasterContent) + ParkSim/ParkWorld/Attraction. Tests: `game/tests/test_coaster.gd` (12 tests). test.sh: alt grønt undtagen `test_props::test_rides_fully_textured` (graphics' igangværende prop-ændringer, ikke sim). integration.sh og balance.sh grønne.
  - Konventioner: kurve-stykket ligger i sin celle og fører ud til `cell + dir(heading+turn)` (samme som `CoasterTrackMesh.centerline`), lineær højde. Stationens gæsteindgang er cellen til **venstre** for stationen (heading+3), så en oval med højresving kan lukke rundt. Kollision bruger stykkets laveste niveau. `position_at(t)`/`speed_at(t)`: t = andel 0..1 af køretiden (= `ride_progress()`); ilæsning (`load_ticks`) ligger i starten af turen med progress 0.
  - Intensitets-tolerance pr. gæst: deterministisk ud fra gæste-id inden for `guest_tolerance` (ingen RNG-træk). Sick: tanke "Jeg har kvalme!" + glæde-straf (`sick_happiness_penalty`, default 10).
  - `cmd_place_attraction` afviser `kind: coaster` (brug `cmd_start_coaster`). Fysikkens kurveradius/overgangslængde kan overskrives i trains.json (`curve_radius`, `transition_len`).
  - **Faktiske ratings for simpel oval** (station, 3× kædelift til niveau 3, 2 lige, 2 højre, 3× fald, 3 lige, 2 højre; 16 stykker): længde 17,6 m, 5,1 s, vmax 7,85 m/s, max_g 5,93, max_lat 11,8 → **E 3,30, I 10,0, N 10,0**. Forventet E 4–5, I 3–5, N 2–3. Årsag: med 1 m celler og r = 0,5 m giver v²/(r·g) ekstreme laterale g, og overgangen fald→fladt over 1 m giver ~6 g. Det skal designer balancere (fx `curve_radius`/`transition_len` i trains.json eller lavere `per_max_lat`/`per_max_g`); max_lat > 2,5 halverer også excitement.
