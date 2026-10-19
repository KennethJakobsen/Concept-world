# T-111: Gameplay: bridge for salg, skrald, bænke, kø og overlays

- **Status:** done
- **Milepæl:** M7
- **Agent:** gameplay
- **Afhænger af:** T-104, T-107, T-109

## Mål
Kontraktens §3 T-111. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `sales_tick` → svævetal (0,25 s-samling, kan slås fra) og `money_flash`
- [x] Skrald/spand/bænk/ATM/kø-signaler → visuals
- [x] `overlay_data(kind)` og `focus_cell(cell)`
- [x] Test af batching og overlay-data

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – gameplay: startet.
- 2026-10-16 – gameplay: færdig → review.
  - `SalesBatcher` (bridge): `sales_tick` samles i 0,25 s-vinduer → `FloatingText3D.show_amount` over bygningen (kun hvis `UserSettings.floating_money`), og `money_flash(sign)` (fortegn af pengeændringen i vinduet) på både `ParkView` og `GameSession`. ParkView har også `sales_flushed(sales)`.
  - `OverlayData.build(sim, kind)` → `{cells, markers}` for happiness/litter/queue/coverage/light (kontrakt T-109). `GameSession.overlay_data(kind)`, `show_overlay(kind)`/`hide_overlay()` (ParkView ejer én `OverlayRenderer`, opdateres hvert 1 s, mens den er aktiv).
  - `GameSession.focus_cell(cell)` → kameraet glider (0,4 s) til cellen. `GameSession.refresh_settings()` genlæser svævetal/farveblind (`ParkColors.set_colorblind`). **UI (T-113) bør kalde den efter ændringer i indstillingspanelet.**
  - `GameSession.milestone_achieved(id)` og `milestones_backfilled(ids)` videresendes fra den aktuelle sim (overlever load).
  - Skrald: `LitterScatter` pr. celle (pool), sim-kind "litter" fordeles deterministisk på wrapper/cup/can/food. Spand: `AmenityVisuals.set_bin_level` ved placering og `bin_state_changed`. Bænk: `guest_sat/guest_stood` → siddeplads (`bench_seat_position`) + `set_guest_seated`, også genskabt ved rebuild/load. ATM: `atm_used` → blåt svævetal + `fx_event(&"atm")`. Kø: `queue_changed` (fra T-140).
  - Gæstemasse: `GuestCrowdRenderer` – højst 120 nærmeste vises som `GuestVisual` (de øvrige noder skjules og får process slået fra), resten MultiMesh/LOD. Uden kamera (headless tests) vises alle noder som før.
  - Taster 1-6 åbner BuildDock-kategorierne (`BuildTool.KEY_CATEGORIES` → `Selection.build_category_requested`). De gamle genveje 1-8 til enkelte bygninger er fjernet (X/0 bevaret). **Lille UI-hook:** 2 linjer i `scripts/ui/hud.gd` (`_ready`-forbindelsen til Selection) kalder `build_dock._on_category`.
  - Test: `tests/test_bridge_m7.gd` (6). `./tools/test.sh`: 418 ok, 3 fejl i sim-tests for refusion/undo (T-106 arbejder parallelt; ikke bridge). `integration.sh` OK, smoke OK.
  - Screenshots: `docs/screenshots/t111_{crowd,close,overlay_happiness,overlay_queue,overlay_coverage}.png` (script `scripts/bridge/m7_bridge_screenshots.gd`). FPS (macOS, Compatibility, 1280x720, 500 gæster, kamera 55 m): **63,6** (vsync-loft). Ved overblikket er alle 500 instanser, og ingen er noder.
  - Venter på brugerens øjne (svævetal, bænk, spand, skrald og crowd-LOD ved overgangen til 18 m).
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
