# T-060: Bug: gokarts følger ikke banen

- **Status:** review
- **Milepæl:** M4
- **Agent:** graphics
- **Afhænger af:** T-058

## Mål
Brugerrapport: gokart-bilerne kører i en cirkel (Spinner om Y) og ikke langs den tegnede bane. De skal følge banens midterlinje, vende i kørselsretningen, være jævnt fordelt og stoppe/accelerere blødt via `set_running`/`set_broken`.

## Acceptkriterier
- [x] `scripts/rendering/kart_track.gd` (`KartTrack extends Spinner`): stadion-kurve (afrundet rektangel 2.9 x 1.9, hjørneradius 0.3) midt mellem `Track` og `Infield`; `point_at(s)`, `tangent_at(s)`, `length()`
- [x] Bilerne placeres jævnt (L/3), lokal +Z = tangent; `speed` = m/s; `speed_scale` styres af RideVisual (blød start/stop som før)
- [x] Node-navne (`Karts/Kart0..2`) og RideVisual-API uændret
- [x] Test `test_go_karts_follow_track`: efter N frames < 0.05 fra midterlinjen, fremadretning·tangent > 0.95, på asfalten, ikke i infield; blødt stop
- [x] test.sh, integration.sh, smoke grønne; kontrolrender (Compatibility)
- [ ] Brugeren bekræfter visuelt

## Ejer / må ikke røre
Ejer: `game/scripts/rendering/kart_track.gd`, `game/scenes/props/go_karts.tscn`, `game/tests/test_props.gd`. Må ikke røre simulation, audio, ui.

## Log
- 2026-10-15 – graphics: oprettet og udført. Årsag: `Karts` var en Spinner, så bilerne roterede i en cirkel med radius 1.45 – ud over banens langsider/infield. Ny `KartTrack` arver Spinner (så RideVisual stadig samler den op) og placerer bilerne langs stadion-kurven. test.sh 153/0, integration OK, smoke uden fejl. Kontrolrender viser bilerne på asfalten.
