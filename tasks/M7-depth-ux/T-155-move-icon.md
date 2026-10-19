# T-155: Ikon til Flyt-værktøjet (pan-ikon)

- **Status:** done
- **Milepæl:** M7
- **Agent:** graphics
- **Afhænger af:** T-110, T-137

## Mål
Brugerfeedback: Flyt virker, men knappen viser bare et "M". Lav et `tool_move`-ikon i stilen fra `docs/ui-style.md`, fx et pan-ikon (fire pile ud fra midten / åben hånd), og brug det på Flyt-knappen.

## Acceptkriterier
- [x] `tool_move` i `gen_ui_icons.gd` (64 + 128 px) i samme stil som de andre værktøjsikoner
- [x] Flyt-knappen i docken viser ikonet; tooltip "Flyt (M)"
- [x] Tests grønne, web-build lavet

## Log
- 2026-10-19 – orkestrator: oprettet fra brugerfeedback
- 2026-10-19 – graphics: `tool_move` (pan: hvidt kryds med fire messingpile og messingnav, INK-kontur) tilføjet i `gen_ui_icons.gd`; 64 + 128 px genereret (LFS). Ingen kodeændring nødvendig: `BuildDock.add_card` laver medaljonen med `UiTheme.medallion("tool_" + id)`, så ikonet bliver fundet automatisk, og fallbacken med "M" i `build_tool.gd` slår ikke længere til (verificeret: `b.icon` = tool_move.png, text ''). Tooltip er uændret "Flyt (M)". Screenshot: `docs/screenshots/t155_move.png`. Test 446/0, integration OK, web-build OK. Venter på, at brugeren kigger på det.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
