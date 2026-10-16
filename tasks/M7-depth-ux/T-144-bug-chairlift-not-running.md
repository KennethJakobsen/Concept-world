# T-144: Bug: svævebanen kører ikke

- **Status:** review
- **Milepæl:** M7
- **Agent:** gameplay
- **Afhænger af:** T-091, T-092, T-093

## Mål
Brugerrapport (screenshot): en bygget svævebane med to stationer og bjælke/master står stille – ingen gondoler bevæger sig. Find årsagen (sim-status, åbning, gæster eller manglende visualisering af køretøjer) og ret den.

## Acceptkriterier
- [x] Årsag dokumenteret i log
- [x] Svævebanen kører synligt med gondoler og transporterer gæster
- [x] Regressionstest

## Log
- 2026-10-16 – orkestrator: oprettet fra brugerrapport
- 2026-10-16 – gameplay: Årsag: simulationen kører kun svævebanen (riders ≠ ∅), når en gæst bruger den som genvej i stigrafen (transport_cost + billet). Bygges den parallelt med eksisterende stier, vælger ingen gæst den (repro: 6000 ticks, 32 gæster, 0 passagerer), og ParkView poserede kabinen stillestående ved stationen. Kabinen/toget blev oprettet korrekt – det var ikke en render-fejl.
  Rettelse (bridge, ingen sim-ændring): `ParkView._transport_leg` pendler kabinen i tomgang mellem stationerne, når banen er åben, ikke i stykker og uden passagerer (samme hastighed som en tur, ophold = load_ticks ved hver station; stopper ved pause/lukket/nedbrud). Når en rigtig tur starter, overtager sim-progress (en tomgangstur over halvvejs regnes som ankommet). Gæster transporteres fortsat af sim'en, når ruten er billigere (test_transport.test_guests_ride_transport).
  Regressionstest: `test_track_view.test_transport_cabin_idles_without_riders`. Kræver brugerens øjne → review.
