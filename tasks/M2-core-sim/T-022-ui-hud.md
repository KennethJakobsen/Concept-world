# T-022: UI – HUD, byggemenu, info-panel

- **Status:** todo
- **Milepæl:** M2
- **Agent:** ui
- **Afhænger af:** T-020

## Mål
Fælles Theme (`game/ui/theme.tres`). Top-bar: penge, dag, gæster, gns. glæde, hastighed/pause-knapper. Byggemenu (bund): sti, fjern, og knapper genereret ud fra content (navn + pris, grået hvis ikke råd). Info-panel ved klik på bygning: navn, besøgende, omsætning, pris (+/-), åben/lukket, rive ned. Info-panel ved klik på gæst: behov, glæde, penge, tanke. Erstatter debug-label.

## Acceptkriterier
- [ ] UI læser kun state og sender kommandoer
- [ ] Museklik på UI går ikke igennem til byggeriet
## Log
- 2026-10-15 – architect: oprettet
