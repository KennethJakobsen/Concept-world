# T-131: Bug: rutsjebane kan ikke færdiggøres i scenarier (kun lige spor låst op)

- **Status:** review
- **Milepæl:** M6
- **Agent:** designer
- **Afhænger af:** T-065, T-095

## Mål
Brugerrapport: I Grøn eng kan man kun bygge lige spor til rutsjebanen, så den aldrig kan lukkes. `research.json` har `wooden_coaster`, `coaster_station` og `track_straight` i `start_unlocked`, mens sving/op/ned/lift kræver forskning.

Regel: En bane må kun kunne startes, når der er låst stykker nok op til at lukke den. Løs i data, f.eks. ved at lade sving (og evt. lift) være låst op sammen med banen, eller ved at flytte `wooden_coaster`/`coaster_station` ind i forskningsemnet `roller_coasters`. Tjek alle tre scenarier og at en minimal lukket bane (station + lige + 4 sving, evt. lift) faktisk validerer i sim. Gælder også tømmerrende/tog/svævebane (de følger banens oplåsning efter T-119).

## Acceptkriterier
- [x] I alle scenarier kan en rutsjebane, der kan startes, også færdiggøres
- [x] Test der for hvert scenarie tjekker, at oplåste baner har nok stykker til en lukket bane
- [x] balance.sh: scenarierne stadig vindbare

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens rapport
- 2026-10-16 – designer: Løst i `research.json`: `track_turn_left/right`, `track_lift_up` og `track_down` er flyttet til `start_unlocked` (fjernet fra items/topic). `roller_coasters` forsker nu kun `track_up` (bakker). Begrundelse: rutsjebanen er parkens trækplaster og et mål i Floddalen/Bjergtoppen; at gemme banen bag forskning ville gøre starten fattigere. En flad oval validerer ikke (kræver lift for fart), så lift+ned skal med for at en bane kan lukkes; venstre-/højre-alene ville give skæve baner. Tømmerrende/tog følger banen (T-119) og har sving med.
  Ny test `game/tests/test_scenario_track_unlocks.gd`: for hvert scenarie bygges en lukket bane for hver oplåst sporbane via sim-kommandoer og valideres (transport: tjekker at sving er oplåst). Grøn.
  balance.sh: alle 3 scenarier 5/5 vundet. NB: start-ovalen giver E=4.66, så excitement-målene (4.5/4.6) nås fra dag 0 – overvej at hæve dem (fx 5.0+, kræver track_up) i en senere task.
  **3 eksisterende tests fejler nu, fordi de koder den gamle opførsel (sving/lift låst ved start)** – uden for mit område: `test_coaster.gd::test_locked_pieces_rejected` (brug `track_up` i stedet for `track_lift_up`), `test_qa_m5.gd::test_research_unlocks_then_build` (brug `track_up`), `test_research.gd::test_flume_pieces_follow_ride_unlock` linje 238 (brug `track_up`). Skal rettes af simulation/qa.
