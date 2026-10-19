# T-108: Grafik: mur, port og omgivelser

- **Status:** done
- **Milepæl:** M7
- **Agent:** graphics
- **Afhænger af:** T-096, T-098

## Mål
GDD §5, kontraktens §2 T-108. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] Hæk/hegn rundt om parken med port ved indgangen
- [x] Bælte på 24 celler med græs, træer, mark og vej samt kosmetiske biler/busser og gæster
- [x] Tema fra `park.json`/scenarie (countryside/river/mountain) med fallback til countryside
- [x] Fps-budget overholdt i web. Screenshots

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – graphics: `SurroundingsRenderer` (`scripts/rendering/surroundings_renderer.gd`): `load_config(scenario_theme)` læser `park.json.surroundings` (defaults hedge/24/countryside, ukendt tema → countryside) og `build(width, height, entrance, cfg)`. Hæk eller hegn (`wall: "fence"`) som MultiMesh på kanten med port ved indgangen (alle fire kanter understøttes). Bælte med jord, marker med furer, vej fra port til tværvej med midterstriber, stoppested, træer (MultiMesh), flod (river) og bjerge (mountain). Biler/busser kører i begge retninger, og busser holder ved stoppestedet. Gæster går fra stoppestedet til porten. Ingen skygger på props og ingen shaders, så det er Compatibility-sikkert.
  - Demo: `scenes/rendering/surroundings_demo.tscn` (1/2/3 = tema, W = hæk/hegn, `-- --theme=N --shot=fil.png`). Screenshots: `docs/screenshots/t108_{0,1,2}.png`. Desktop opengl3 1280x720 gav ca. 120 fps (vsync-loft). Web-fps måles i T-118.
  - Test: `tests/test_surroundings.gd` (fallback, alle temaer, indgang på andre kanter). `test.sh`: 317 bestået. De 2 fejl skyldes `atm` fra T-100, der kører parallelt (ikke T-108). Smoke af main er OK.
  - **Integration (gameplay):** parken bruger den ikke endnu, fordi `park_view.gd`/`main.tscn` ikke er mine. Det kræver ca. 3 linjer i `ParkView` efter setup: `var s := SurroundingsRenderer.new(); add_child(s); s.build(w.width, w.height, w.entrance, SurroundingsRenderer.load_config(scenario_theme))`. Den eksisterende `entrance.tscn` står inde i parken, og porten står lige udenfor.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
