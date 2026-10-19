# T-134: UI: låst byggekort for sporbane med forskningskrav

- **Status:** done
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-131, T-133

## Mål
Byggekortet for en sporbane er gråtonet med låseteksten fra GDD (T-131), når `required_pieces` ikke alle er låst op.

## Acceptkriterier
- [x] Kort gråtonet + tooltip med kravet; bliver aktivt når stykkerne er forsket
- [x] Test (`game/tests/test_ui_t134.gd`)

## Log
- 2026-10-16 – orkestrator: oprettet efter T-131
- 2026-10-16 – ui: `LockOverlay.track_lock_text(sim, def_id)` bygger "Kræver forskning: <emne> – <stykker>" ud fra `sim.missing_pieces` + research-emner + stykkenavne. `Hud.build_lock_text()`; refresh låser kortet (BuildDock-låsetilstand fra T-138) med teksten som tooltip; låses op når stykkerne er forsket. test.sh 403/0, integration OK. Visuelt ikke set headless.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
