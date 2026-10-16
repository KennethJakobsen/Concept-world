# T-089: UI: intensity, kvalme, præmier og ting

- **Status:** done
- **Milepæl:** M6
- **Agent:** ui
- **Afhænger af:** T-086

## Mål
Paneler og tekster for B/D/E (kontrakt §7 T-089). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] Intensity- og kvalme-bjælker i info-panelet
- [x] Gæsteinfo med kvalme, tolerance og ting-ikoner (tegnet)
- [x] Sideshow-panel og økonomikategorien "Præmier"
- [x] Danske tanke-tekster, og `test_hud_glyphs` er grøn

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-16 – ui: M6Texts (tanker, ting, kategorier), ItemIcon (tegnede ting), ProgressBar-bjælker for intensitet/kvalme i info-panelet, gæstepanel med kvalme/tolerance + ikoner, sideshow-linjer, "Præmier" i parkpanel, toast for guest_vomit. test_hud_m6.gd; test.sh + integration.sh grønne. Visuelt skal bekræftes af brugeren.
- 2026-10-16 – bruger: godkendt.
