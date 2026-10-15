# T-018: Design – M2 indholdsdata og balance

- **Status:** done
- **Milepæl:** M2
- **Agent:** designer
- **Afhænger af:** –

## Mål
Skriv alle JSON-filer fra `_CONTRACT.md` med gennemtænkte værdier, og udvid docs/gdd.md med sektioner om behov, gæstebeslutninger, økonomi og balance-rationale.

## Acceptkriterier
- [x] 7 bygnings-JSON + economy.json + guests.json gyldige iht. kontrakten
- [x] GDD beskriver gæsteloop: behov stiger → søg nærmeste åbne bygning der dækker behovet og som de har råd til → ellers forlystelse → forlad ved lav glæde/ingen penge
- [x] Balance: start med nok til ca. 1 forlystelse + stier + 2 boder; overskud muligt efter ~3 dage
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – designer: 7 bygnings-JSON + economy.json + guests.json skrevet (gyldig JSON). GDD udvidet med behov, gæsteloop, pris-vurdering, økonomi. day_ticks 2400 (~2 min).
- 2026-10-15 – qa: godkendt (45/45 tests, smoke uden fejl, web-build ok, kontrakt tjekket). Balance-kriteriet opfyldt i den forstand at overskud er muligt – men alt for let (driftsoverskud fra dag 1); se T-024/T-026. → done
