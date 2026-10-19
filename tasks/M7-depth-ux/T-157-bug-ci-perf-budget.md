# T-157: Bug: CI fejler på sim-tidsbudget (9,5 ms > 8 ms)

- **Status:** done
- **Milepæl:** M7
- **Agent:** qa
- **Afhænger af:** T-118

## Mål
CI-kørsel 39209236649: `test_qa_m7.gd::test_determinism_and_budget_500_guests` fejler med 9,48 ms/tick på GitHub-runneren (lokalt ca. 4,4 ms). Vægur-tid på delte CI-maskiner er ustabil.

## Acceptkriterier
- [x] Determinisme testes stadig strengt
- [x] Tidsbudgettet er robust i CI (fx kun advarsel, når `CI`-miljøvariablen er sat, eller en grænse relativt til en kalibreringsmåling); lokalt håndhæves 8 ms fortsat
- [x] CI grøn

## Log
- 2026-10-19 – orkestrator: oprettet fra CI-fejl
- 2026-10-19 – qa: budget-asserts i test_qa_m7.gd og test_m7_queues.gd håndhæves kun uden `CI` (GitHub sætter CI=true); i CI kun push_warning. Determinisme-asserts uændrede. test.sh: 447/0 lokalt og med CI=true. Afventer grøn CI efter push.
- 2026-10-19 – orkestrator: CI-kørsel 39209873969 grøn → done
