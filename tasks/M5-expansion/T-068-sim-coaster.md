# T-068: Sim – rutsjebane: bane, validering, fysik, ratings

- **Status:** todo
- **Milepæl:** M5
- **Agent:** simulation
- **Afhænger af:** T-065, T-066, T-067 (samme filer, køres sekventielt)

## Mål
Implementér `_CONTRACT.md` §3 og ADR-003.

## Acceptkriterier
- [ ] `TrackPieceDef`, `TrackPiece`, `CoasterTrack` (`next_entry`, `is_closed`, `validate` med alle fejlkoder)
- [ ] `cmd_start_coaster`, `cmd_place_track_piece`, `cmd_remove_last_piece`, `cmd_finish_coaster`, `can_place_track_piece`, `preview_track_piece` og signalet `coaster_changed(coaster_id)`
- [ ] Kollisionsregler (sti, bygning, decor, egen og anden bane, |Δlevel| ≥ 2). `ParkWorld.occupied_by_track`, og stier og bygninger afvises under lave baner
- [ ] `CoasterPhysics.simulate`, `CoasterProfile` (`position_at`, `speed_at`) og `CoasterRatings.rate`. En test af en lukket oval med kendt profil (fart og ratings inden for tolerance) og en test af en bane, der er for flad (`too_slow`)
- [ ] Rutsjebanen fungerer som `Attraction`: kø, billet, nedbrud, mekaniker og `ride_progress()`. Gæsterne afviser ved for høj intensitet, og nausea påvirker `sick`
- [ ] Låste stykker afvises (`is_unlocked`)
- [ ] Save round-trip for en bane under bygning og en lukket bane med kørende tog. Profilen genberegnes ved load og er identisk
- [ ] `tools/test.sh`, `tools/integration.sh` og `tools/balance.sh` er grønne

## Ejer / må ikke røre
Som T-066.

## Log
- 2026-10-15 – architect: oprettet
