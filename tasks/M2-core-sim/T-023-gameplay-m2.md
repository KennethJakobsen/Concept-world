# T-023: Gameplay – Generisk byggeri, valg og bridge-udvidelser

- **Status:** todo
- **Milepæl:** M2
- **Agent:** gameplay
- **Afhænger af:** T-020, T-021

## Mål
BuildTool generaliseres til alle bygninger (model fra JSON), select-værktøj (klik bygning/gæst → signal til UI), fjernelse af bygning, tanke-bobler over gæster (hvis T-021 leverer), penge-feedback ved køb (fx flydende "+4"/"-300").

## Acceptkriterier
- [ ] Alle 7 bygninger kan bygges og fjernes
- [ ] Valg af bygning/gæst udsender signal UI kan bruge (koordinér API med T-022 via `game/scripts/bridge/selection.gd`: `signal selected_attraction(id)`, `signal selected_guest(id)`, `signal cleared`, `signal build_tool_requested(def_id:String)`)
## Log
- 2026-10-15 – architect: oprettet
