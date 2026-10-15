# T-056: Bug – tankebobler passer ikke til teksten

- **Status:** review
- **Milepæl:** M4
- **Agent:** graphics
- **Afhænger af:** T-051

## Mål
Brugerrapport: den hvide baggrundsboble over gæsterne er for lille/forskudt, så tekst som "Her er beskidt!" og "Det var godt!" stikker ud og bliver ulæselig.

## Acceptkriterier
- [x] Boblens størrelse beregnes ud fra tekstens målte størrelse (`Font.get_multiline_string_size` med samme font_size/pixel_size som Label3D) + padding
- [x] Boble og tekst centreret om samme punkt (begge billboard, center-alignment)
- [x] Virker i Compatibility/web (ingen nye shaders/features)
- [x] Test (`tests/test_thought_bubble.gd`) verificerer bredde/højde >= tekst for flere tekster
- [x] `tools/test.sh` grøn
- [ ] Brugeren bekræfter boblerne visuelt

## Ejer / må ikke røre
Ejer: `game/scripts/rendering/thought_bubble.gd`, `game/scenes/props/thought_bubble.tscn`. Må ikke røre simulation, audio, ui.

## Log
- 2026-10-15 – graphics: oprettet og løst. Før: bredde gættet som `0.09 * længde + 0.2`, højde fast 0.3 m. Nu: statiske `ThoughtBubble.text_size()`/`bubble_size()` måler teksten (fallback-font, 40 px, 0.004 m/px), padding 0.08/0.05 m, min. bredde 0.3 m; quad skaleres i x og y. test.sh 149/0. Afventer brugerens øjne.
