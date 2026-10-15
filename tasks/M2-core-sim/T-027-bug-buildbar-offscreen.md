# T-027: Bug – Byggemenuen er uden for skærmen

- **Status:** done
- **Milepæl:** M2
- **Agent:** ui
- **Afhænger af:** T-022

## Mål
Brugerrapport (screenshot): vinduet (1600×900) er højere end skærmen på en MacBook, så byggemenuen i bunden er skåret af.
- Vinduet skal tilpasse sig skærmen (fx maksimeret eller størrelse = ~85 % af skærmens brugbare område, centreret).
- UI skal skalere fornuftigt ved forskellige opløsninger og ved HiDPI (stretch mode canvas_items / aspect expand eller content scale efter DPI).
- Byggemenuen må aldrig gå ud over viewportens kant; ved smalle vinduer skal knapperne ombrydes eller scrolle.
- Virker også i browseren (canvas resize).

## Acceptkriterier
- [x] Byggemenuen er synlig på en 1440×900-skærm og i et browservindue på 1280×720
- [x] Test der verificerer at HUD-panelerne ligger inden for viewport ved 1280×720 og 1024×600
## Log
- 2026-10-15 – architect: oprettet efter brugerrapport
- 2026-10-15 – ui: viewport 1280×720, stretch canvas_items/expand, allow_hidpi; vindue skaleres til ≤85% af usable rect og centreres (Hud.fit_window_to_screen); HUD layout(vp) ved size_changed – top-bar/byggemenu som HFlowContainer, menu forankret i bunden med margin og højde efter ombrydning; knaptekst trimmes ikke; web canvas_resize_policy=2. Tests 1280×720/1024×600/640×480 grønne, import/smoke/web-build ok → review
- 2026-10-15 – orkestrator: brugeren har godkendt. Status: done.
