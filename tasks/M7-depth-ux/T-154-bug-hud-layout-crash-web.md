# T-154: Bug: web-crash ved Fortsæt – HUD-layout før TopBar/BuildMenu findes

- **Status:** done
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-142, T-153

## Mål
Brugerens browserkonsol ved "Fortsæt":
```
ERROR: Node not found: "TopBar" (relative to "/root/Main/Hud/Root")
ERROR: Node not found: "BuildMenu" (relative to "/root/Main/Hud/Root")
RuntimeError: call_indirect to a signature that does not match (evaluating 'func()')
```
`Hud._layout_impl` bruger `root.get_node("TopBar"/"BuildMenu")`. Layout bliver kaldt, mens HUD'en bygges (fx `top_bar.minimum_size_changed -> _relayout`, sat før BuildMenu er tilføjet) eller efter nedrivning ved load (`viewport.size_changed`-forbindelsen bliver ikke frakoblet; deferred `layout`). På web ender null-adgangen/den døde callable i et wasm-crash.

## Acceptkriterier
- [x] `layout` er no-op, indtil begge noder findes; ingen get_node-fejl
- [x] Signalforbindelser (viewport.size_changed, minimum_size_changed, deferred calls) frakobles i `_exit_tree`/bliver sikre over for frigjorte objekter
- [x] Gennemgå andre UI-scripts for samme mønster (forbindelser til viewport/GameSession uden frakobling)
- [x] Regressionstest: Fortsæt/indlæs flere gange i træk og nyt spil → menu → Fortsæt uden fejl i loggen (integration.sh skal fejle på "Node not found")
- [ ] Web-build lavet; brugeren bekræfter i browseren

## Log
- 2026-10-19 – orkestrator: oprettet fra brugerens konsol-output
- 2026-10-19 – ui: `Hud.layout` er no-op indtil TopBar/BuildMenu/build_dock findes og når HUD'en er queued for deletion; `_exit_tree` frakobler `viewport.size_changed`; `_on_viewport_resized` tjekker `is_inside_tree`; deferred layout går via `_relayout` (bruger aktuel viewport). Gennemgang: `main_menu.gd` havde en lambda på `viewport.size_changed`, som aldrig blev frakoblet (frigjort menu -> død callable = sandsynlig `call_indirect`-crash ved Fortsæt) -> nu metode + frakobling i `_exit_tree`. Øvrige UI-scripts forbinder ikke til viewport/GameSession. Ingen ændring i game_session/park_view nødvendig. `integration.sh` fejler nu på `ERROR:` hvor som helst i linjen og `Node not found`; `integration_flow.gd` kører Fortsæt 3x i træk med `size_changed` udsendt før/efter scene-skift. test (446 ok), integration OK, smoke uden fejl, web-build lavet. Afventer brugerens browsertest.
- 2026-10-19 – orkestrator: brugeren bekræfter at Fortsæt virker i browseren → done
