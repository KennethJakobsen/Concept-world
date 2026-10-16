# T-115: Gameplay: TutorialDirector og pile i verden

- **Status:** review
- **Milepæl:** M7
- **Agent:** gameplay
- **Afhænger af:** T-114

## API til ui (T-116)
`GameSession` (autoload/park-session):
- `signal tutorial_step_changed(index: int, step: Dictionary)` – step = rå JSON-dict `{id, text, highlight, complete_when}`. Udsendes ved start (index 0) og ved hvert nyt trin.
- `signal tutorial_finished(skipped: bool)` – alle trin klaret eller sprunget over.
- `func tutorial_skip() -> void` – "Spring over" (kun hvis `skippable`).
- `func tutorial_active() -> bool`, `func tutorial_step_index() -> int`, `func tutorial_step_count() -> int`, `func tutorial_current_step() -> Dictionary`, `func tutorial_skippable() -> bool`.
- UI melder UI-handlinger: `func tutorial_notify(event: String)` med `"overlay_opened:<kind>"` (fx `overlay_opened:queue`). Pris/bygning/sti/personale opdages fra sim.
- UI kan selv vise highlight for `build:<def>`, `overlay:<kind>`, `staff:<type>`; bridge viser pil i verden for `entrance` og `attraction:<kind>`.

## Mål
Kontraktens §5 T-115. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] Trin fuldføres ved handling, ikke ved klik
- [x] Pile/highlight i verden. Spring over virker
- [x] Integrationstest, der gennemfører alle trin headless

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – gameplay: `scripts/bridge/tutorial_director.gd` (TutorialDirector, RefCounted: læser rå JSON `steps/tutorial/skippable`, poller sim-state – sti ved indgang, attraktion af kind, prisændring ift. snapshot ved trinstart, personale af type – og UI-events via notify). `scripts/bridge/tutorial_arrow.gd` (hoppende gul kegle, unlit, ingen skygge). GameSession-wiring + API ovenfor; pil sættes under ParkView og følger `entrance`/`attraction:<kind>`. Tutorial startes kun via `start_scenario("tutorial")` (scenariet er sandbox-agtigt, så `sim.scenario` er null) – en indlæst save genoptager ikke tutorialen. Test: `tests/test_tutorial_director.gd` gennemfører alle 6 trin headless ved handlinger + spring over. test.sh 442/0, integration OK, smoke rent. Pilen kræver brugerens øjne.
