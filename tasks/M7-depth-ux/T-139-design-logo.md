# T-139: Design: logo i Tivoli-skilt-stilen

- **Status:** review
- **Milepæl:** M7
- **Agent:** designer
- **Afhænger af:** T-136, T-138

## Mål
Brugerønske: et logo for Concept-world, der passer til `docs/ui-style.md`. Bruges i hovedmenuen (erstatter det midlertidige logo-skilt fra T-138), som web-favicon/boot-splash og app-ikon.

## Acceptkriterier
- [x] Logo som egen SVG (vektor) + PNG-eksporter (stor, 512, 256, 64, favicon 32/16) i `game/assets/ui/logo/`
- [x] Varianter: fuldt logo (ordmærke + symbol) og kun symbol
- [x] Afsnit om logo i `docs/ui-style.md` (brug, minimumsstørrelse, farver)
- [x] Kun egne/CC0-assets; credits opdateret

## Log
- 2026-10-16 – orkestrator: oprettet efter brugerønske
- 2026-10-16 – designer: SVG'er (fuldt logo, symbol, forenklet favicon-symbol) og PNG-eksport via inkscape i `game/assets/ui/logo/`. Ordmærket er konverteret til paths. Afsnit i ui-style.md, credits og preview `docs/screenshots/t139_logo.png`. Brugeren skal godkende visuelt. UI-agenten kobler logoet på menu/favicon.

### 2026-10-16 – ui: logo integreret
- Hovedmenu: træ-skilt + Label + blinkende pærer erstattet af `TextureRect` "Logo" (logo_full_512.png, 340x146, keep-aspect). Pærerne droppet – logoet har dem allerede tegnet.
- project.godot: `config/icon` = logo_symbol_256.png, `boot_splash/image` = logo_full_512.png (ikke fullsize, grøn bg).
- export_presets.cfg har intet favicon-felt; Godots web-export bruger `config/icon` som favicon.
- Test: `test_menu_uses_logo_texture`. test.sh: 334 bestået, 2 kendte atm-fejl. integration.sh OK. docs/screenshots/t138_menu.png opdateret.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
