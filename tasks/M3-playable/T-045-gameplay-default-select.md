# T-045: Gameplay – Start i vælg-værktøj

- **Status:** done
- **Milepæl:** M3
- **Agent:** gameplay
- **Afhænger af:** T-039

## Mål
BuildTool starter i sti-værktøj, så Esc skal trykkes to gange for pause-menu. Start i "select". Opdater tests/integration.

## Acceptkriterier
- [x] Ny park starter i select; Esc én gang åbner pause-menu
## Log
- 2026-10-15 – architect: oprettet efter QA-fund
- 2026-10-15 – gameplay: BuildTool.tool starter i "select" → Esc én gang åbner pause-menu. Integration tjekker start-værktøj; unit-test test_build_tool_starts_in_select. test.sh 117/117, integration.sh OK.
- 2026-10-15 – qa: test.sh 117/117, integration OK, balance.sh reproducerer tal, smoke main_menu/main uden fejl → done
