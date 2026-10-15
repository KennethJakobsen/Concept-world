# T-028: Test-runner tæller script-fejl som bestået

- **Status:** done
- **Milepæl:** M2
- **Agent:** qa
- **Afhænger af:** T-005

## Mål
Fundet under T-027: hvis en test crasher med script-fejl, tælles den som bestået. Runneren skal fange det (fx tjek om metoden nåede til ende via en markør, og/eller scan stderr/Engine-fejl), så crash = fejl.

## Acceptkriterier
- [x] En test der crasher midtvejs tælles som FAIL
- [x] Alle eksisterende tests er stadig grønne (eller skjulte fejl rettes/rapporteres)
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – qa: Empirisk: script-fejl afbryder kun den kaldte metode (caller fortsætter, sentinel i wrapper virker ikke pålideligt). Løsning: `tests/framework/error_counter.gd` (Logger via `OS.add_logger`) tæller fejl pr. test; runneren tilføjer dem som failures. Verificeret med midlertidig crash-test (null.foo()) → FAIL, 48/1; fjernet igen. `./tools/test.sh`: 48 passed, 0 failed – ingen skjulte fejl. → done
