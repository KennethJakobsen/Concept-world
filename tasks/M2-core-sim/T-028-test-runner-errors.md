# T-028: Test-runner tæller script-fejl som bestået

- **Status:** todo
- **Milepæl:** M2
- **Agent:** qa
- **Afhænger af:** T-005

## Mål
Fundet under T-027: hvis en test crasher med script-fejl, tælles den som bestået. Runneren skal fange det (fx tjek om metoden nåede til ende via en markør, og/eller scan stderr/Engine-fejl), så crash = fejl.

## Acceptkriterier
- [ ] En test der crasher midtvejs tælles som FAIL
- [ ] Alle eksisterende tests er stadig grønne (eller skjulte fejl rettes/rapporteres)
## Log
- 2026-10-15 – architect: oprettet
