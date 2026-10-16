# T-148: Bug: gæster ser forskellige ud (LOD), liggende/strakte kapsler

- **Status:** review
- **Milepæl:** M7
- **Agent:** graphics
- **Afhænger af:** T-107, T-111

## Mål
Brugerrapport (screenshot): på samme sti har nogle gæster hoved/hår/detaljer, andre er glatte kapsler, og nogle er store liggende, strakte lilla/gule kapsler. Årsag: `GuestCrowdRenderer` – de nærmeste 120 (≤18 m) er `GuestVisual`, resten MultiMesh-LOD. Overgangen er for synlig, og MultiMesh-transformen (rotation/skala) er forkert for nogle LOD-niveauer.

## Acceptkriterier
- [x] Ingen liggende/strakte gæster: MultiMesh-instanser står oprejst i korrekt størrelse og samme farver som GuestVisual
- [x] Nærmeste MultiMesh-LOD har samme silhuet og detaljer (hoved, hår, krop, ben) som GuestVisual, så skiftet ikke ses i normal zoom; lavere LOD kun på lang afstand
- [x] Rimelig fps med 500 gæster (Compatibility)
- [x] Regressionstest (transform/skala for MultiMesh-instanser) + screenshots `docs/screenshots/t148_*.png`, samme kameravinkel som brugerens

## Log
- 2026-10-16 – orkestrator: oprettet fra brugerrapport
- 2026-10-16 – graphics: `GuestCrowdRenderer` omskrevet. LOD0 = én MultiMesh pr. del med præcis guest.tscn's meshes/offsets/farver (krop farvet pr. gæst via instance color, denim-bukser, hud-hoved, hår-halvkugle); LOD1 (>60 m) krop+hoved med færre segmenter; skjult >120 m. Den gamle kasse/cylinder-LOD er væk. Transform: altid `Basis.IDENTITY` (`part_transform`), og buffere har fast kapacitet (po2) + `visible_instance_count` i stedet for at ændre `instance_count` hver frame (sandsynlig kilde til strakte/liggende "garbage"-instanser i Compatibility). NEAR_DIST 18 → 30 m (stadig maks 120 noder); da LOD0 er visuelt identisk, ses skiftet ikke. park_view.gd uændret (bridge-fødningen var korrekt).
  Test: `test_crowd_instances_upright_and_match_guest_visual` (test_render_m7). Screenshots `docs/screenshots/t148_{close,normal,far}.png` via `scripts/rendering/m7/t148_crowd_screenshots.gd`. FPS (macOS, Compat, 1280x720, 500 gæster): 63,5 (vsync-loft). Tests: mine grønne; resterende fejl er i test_ui_m7_panels (ui's igangværende arbejde). Integration OK. Afventer brugerens øjne.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
