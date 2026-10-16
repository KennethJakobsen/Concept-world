# T-133: Sim: required_pieces – bane kan kun startes, når den kan lukkes

- **Status:** review
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-131

## Mål
Opfølgning på T-131 (data er lagt ind). `AttractionDef.required_pieces` + funktion, der afgør om en sporbane er bygbar ud fra oplåste stykker.

## Acceptkriterier
- [x] `AttractionDef.required_pieces` læses (default tom)
- [x] Byggeri af sporbane afvises, når et påkrævet stykke ikke er låst op
- [x] Test pr. scenarie: minimal lukket træbane (station + lige + 4 sving) validerer og er ikke for langsom; ellers tilføj lift/fald til data og meld til designer

## Log
- 2026-10-16 – orkestrator: oprettet efter T-131
- 2026-10-16 – simulation: in-progress → review. `AttractionDef.required_pieces` (default `[]`, med i `to_dict`). `ParkSim.missing_pieces(def_id) -> Array[String]` og `can_complete(def_id) -> bool`; `cmd_start_coaster` afviser (uden at trække penge), når et påkrævet stykke er låst. Test pr. scenarie: minimal flad lukket bane (station + 2 højre + lige + 2 højre) validerer uden `too_slow` for træbane, tømmerrende og minitog (kun sandbox har sving låst op fra start; i de andre er banerne korrekt låst). Ingen data-ændring nødvendig. `test_coaster`/`test_qa_m5` tilpasset (sving låses op før start).
