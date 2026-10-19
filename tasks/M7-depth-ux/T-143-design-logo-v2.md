# T-143: Design: logo v2 – mere sammenhængende

- **Status:** done
- **Milepæl:** M7
- **Agent:** designer
- **Afhænger af:** T-139

## Mål
Brugerfeedback: logoet fra T-139 er "ikke rigtigt sammenhængende nok". Elementerne (skilt, medaljon, ordmærke, bånd) skal smelte sammen til én tydelig form. Samtidig: ordmærket må ikke bygge på Georgia (kommerciel font) – brug egne bogstavformer eller en CC0-font.

## Acceptkriterier
- [x] Ny version med én samlet silhuet og klart hierarki; virker også lille
- [x] Ingen afhængighed af ikke-frie fonte; credits opdateret
- [x] Samme filnavne i `game/assets/ui/logo/`, så menu/ikon/splash ikke skal ændres
- [x] Preview `docs/screenshots/t143_logo.png` (gerne 2–3 varianter, valgt én)

## Log
- 2026-10-16 – orkestrator: oprettet fra brugerfeedback
- 2026-10-16 – designer: v2 genereret af `game/assets/ui/logo/src/gen_logo.py`. Én silhuet: skilt + kuppel, hvor pariserhjulet stiger op af skiltet, "CONCEPT" på træ og "WORLD" i skiltets røde bundfelt. Egne monoline-bogstaver (ingen Georgia/font), credits og ui-style opdateret. Samme filnavne og PNG'er gen-eksporteret; `src/logo_full_src.svg` (Georgia) er slettet. Jeg valgte én variant og itererede på tekststørrelsen. Preview `docs/screenshots/t143_logo.png`. Menuens TextureRect er 340x146 og passer stadig til 1024x440. Brugeren skal godkende visuelt.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
