# T-023: Gameplay – Generisk byggeri, valg og bridge-udvidelser

- **Status:** done
- **Milepæl:** M2
- **Agent:** gameplay
- **Afhænger af:** T-020, T-021

## Mål
BuildTool generaliseres til alle bygninger (model fra JSON), select-værktøj (klik bygning/gæst → signal til UI), fjernelse af bygning, tanke-bobler over gæster (hvis T-021 leverer), penge-feedback ved køb (fx flydende "+4"/"-300").

## Acceptkriterier
- [x] Alle 7 bygninger kan bygges og fjernes
- [x] Valg af bygning/gæst udsender signal UI kan bruge (koordinér API med T-022 via `game/scripts/bridge/selection.gd`: `signal selected_attraction(id)`, `signal selected_guest(id)`, `signal cleared`, `signal build_tool_requested(def_id:String)`)
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – gameplay: BuildTool generisk (alle 7 bygninger via Selection.build_tool_requested + taster 1-8, X=fjern, Esc/0=vælg), select-værktøj (bygning/gæst/tomrum → Selection-signaler), ParkView lytter på attraction_removed og loader model fra AttractionDef.model, tankebobler (max 8, 3 s), flydende -/+ tekst ved byg/fjern. Debug-label fjernet. Selection-node i main.tscn (gruppe selection), ParkView i gruppe park_view. Tests: byg/fjern alle 7 + boble-loft. import/test/smoke/web ok.
- 2026-10-15 – qa: godkendt (45/45 tests, smoke uden fejl, web-build ok, kontrakt tjekket). Manuel visuel verifikation afventer bruger. → done
