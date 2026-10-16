# T-140: Gameplay: køsti-værktøj og kø/gæstemasse i scenen (prioriteret)

- **Status:** review
- **Milepæl:** M7
- **Agent:** gameplay
- **Afhænger af:** T-103, T-107

## Mål
Brugeren savner kø-konceptet. Køsti-delen af T-110 og kø/gæstemasse-delen af T-111 rykkes frem: man kan bygge køstier til forlystelsernes indgang, og gæster står i kø langs dem med plads til hver gæst (ingen overlap) og spredes på almindelige stier.

## Acceptkriterier
- [x] Køsti-værktøj i byggemenuen (kategori Stier), forbinder til forlystelsens indgang, regler fra kontrakten/ADR-005
- [x] Gæster i kø vises én pr. plads langs køstien; gæster på stier overlapper ikke synligt (masse/separation fra T-103)
- [x] Kølængde/ventetid vises ved valg af forlystelse (hvis T-112 ikke er klar: simpel linje i Oversigt)
- [x] Tests + integration grønne; bliver på review til brugeren har set det

## Log
- 2026-10-16 – orkestrator: oprettet efter brugerfeedback om manglende køer
- 2026-10-16 – gameplay: implementeret → review.
  - `BuildTool.TOOL_QUEUE = "queue_path"`: træk for at bygge (`cmd_place_queue_path`, -15 svævetal), højreklik-træk fjerner (`cmd_remove_queue_path`, +7); Fjern-værktøjet fjerner også køsti. Preview-highlight grøn/rød (pris + `can_place_path`). Aldrig låst (`tool_content_id` = "").
  - `ParkView`: `QueuePathVisual` pr. QUEUE-celle (også ved rebuild/load). Rækværkets åbninger følger kæden: forreste celle åbner mod indgangen, bageste mod stien ved `approach_cell`, løse køceller mod andre køceller. Opdateres på `tile_changed` og `queue_changed` (genindgangsværn).
  - Gæster placeres med `sim.guest_position(id)` (køplads langs køstien, ellers ADR-005-bane på stien) og vender mod pladsen foran i køen. GuestCrowdRenderer (MultiMesh/LOD) er ikke koblet på endnu – det hører til T-111 (ydeevne ved 500 gæster).
  - UI (minimal): kort "Køsti" ($15) i Stier via `_add_build_button` + `research_id`-undtagelse; kølinjen i Oversigt viser "Kø: n/kap, ventetid ca. N s" (indtil T-112). Kortet bruger kategori-ikonet som miniature (ingen `thumbs/queue_path.png` endnu).
  - Tests: `tests/test_queue_view.gd` (værktøj, penge, visual-masker, gæster på separate køpladser, kølinje). 370 grønne; eneste røde er `test_ui_m7_foundation::test_dock_returns_to_bottom_after_close` (ui-agentens igangværende dock-arbejde, ikke berørt). Integration OK, smoke uden fejl.
  - Screenshots: `docs/screenshots/t140_queue.png`, `t140_queue_close.png` (Compatibility, simpel testscene: karrusel med 6-celle køsti med knæk, 12/12 i kø, to pr. celle, ingen overlap). Afventer brugerens øjne.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
