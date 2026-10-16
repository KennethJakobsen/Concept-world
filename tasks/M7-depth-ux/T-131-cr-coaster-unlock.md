# T-131: Ændringsønske: rutsjebane kan ikke færdiggøres i scenarier (kun lige spor låst op)

- **Status:** review
- **Milepæl:** M7
- **Agent:** designer
- **Afhænger af:** T-065, T-095

## Mål
Brugerrapport: I Grøn eng kan man kun bygge lige spor til rutsjebanen, så den aldrig kan lukkes. `research.json` har `wooden_coaster`, `coaster_station` og `track_straight` i `start_unlocked`, mens sving/op/ned/lift kræver forskning.

Regel: En bane må kun kunne startes, når der er låst stykker nok op til at lukke den. Løs i data, f.eks. ved at lade sving (og evt. lift) være låst op sammen med banen, eller ved at flytte `wooden_coaster`/`coaster_station` ind i forskningsemnet `roller_coasters`. Tjek alle tre scenarier og at en minimal lukket bane (station + lige + 4 sving, evt. lift) faktisk validerer i sim. Gælder også tømmerrende/tog/svævebane (de følger banens oplåsning efter T-119).

## Acceptkriterier
- [ ] I alle scenarier kan en rutsjebane, der kan startes, også færdiggøres
- [ ] Test der for hvert scenarie tjekker, at oplåste baner har nok stykker til en lukket bane
- [ ] balance.sh: scenarierne stadig vindbare

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens rapport
- 2026-10-16 – bruger: ikke en bug (sving kan forskes) men et ændringsønske. f8ab4cb revertet (3c86cce). Løsning (A gråtonet indtil sving er forsket / B advarsel i byggemenu / C andet) afventer brugeren. Designerens forslag om højere excitement-mål (~5.0) i Floddalen/Bjergtoppen tages med.
- 2026-10-16 – bruger: valgt A – banen er gråtonet, indtil de nødvendige stykker er forsket, med tekst der beskriver forskningskravet (f.eks. "Kræver forskning: Rutsjebaner – sving"). Gælder alle sporbaner. Kræver formentlig ui (byggekort) + evt. sim-API for "kan lukkes"; architect fordeler ved M7-start.
- 2026-10-16 – designer: in-progress
- 2026-10-16 – designer: data-delen af løsning A: `required_pieces` på wooden_coaster/log_flume/mini_train/monorail (station, lige, begge sving). Regel + tekst ("Kræver forskning: <emne> – <stykker>") beskrevet i GDD §M7 Data-noter. Tømmerrende/tog/svævebane er altid komplette pga. T-119. Mangler (ikke designer): sim-API/def-felt `AttractionDef.required_pieces` + `can_complete(def_id)`, gråtonet byggekort (ui), og testen "oplåste baner kan lukkes pr. scenarie" inkl. at en flad lukket træbane består `validate()` (too_slow). Foreslår opfølgnings-tasks til simulation og ui. Balance uændret (5/5 i alle scenarier).
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
