# T-022: UI – HUD, byggemenu, info-panel

- **Status:** done
- **Milepæl:** M2
- **Agent:** ui
- **Afhænger af:** T-020

## Mål
Fælles Theme (`game/ui/theme.tres`). Top-bar: penge, dag, gæster, gns. glæde, hastighed/pause-knapper. Byggemenu (bund): sti, fjern, og knapper genereret ud fra content (navn + pris, grået hvis ikke råd). Info-panel ved klik på bygning: navn, besøgende, omsætning, pris (+/-), åben/lukket, rive ned. Info-panel ved klik på gæst: behov, glæde, penge, tanke. Erstatter debug-label.

## Acceptkriterier
- [x] UI læser kun state og sender kommandoer
- [x] Museklik på UI går ikke igennem til byggeriet
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – ui: HUD (scenes/ui/hud.tscn + scripts/ui/hud.gd), theme.tres, byggemenu fra content, info-paneler via Selection-signaler (gruppe "selection"/"park_view", null-robust), mouse_filter STOP. tests/test_hud.gd. Test/import/smoke grøn → review
- 2026-10-15 – qa: godkendt (45/45 tests, smoke uden fejl, web-build ok, kontrakt tjekket). Manuel visuel verifikation afventer bruger. → done
