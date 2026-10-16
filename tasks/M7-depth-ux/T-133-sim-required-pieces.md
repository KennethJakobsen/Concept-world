# T-133: Sim: required_pieces – bane kan kun startes, når den kan lukkes

- **Status:** todo
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-131

## Mål
Opfølgning på T-131 (data er lagt ind). `AttractionDef.required_pieces` + funktion, der afgør om en sporbane er bygbar ud fra oplåste stykker.

## Acceptkriterier
- [ ] `AttractionDef.required_pieces` læses (default tom)
- [ ] Byggeri af sporbane afvises, når et påkrævet stykke ikke er låst op
- [ ] Test pr. scenarie: minimal lukket træbane (station + lige + 4 sving) validerer og er ikke for langsom; ellers tilføj lift/fald til data og meld til designer

## Log
- 2026-10-16 – orkestrator: oprettet efter T-131
