# T-046: Design – dag/nat, lydkatalog, nedbrud uden mekaniker

- **Status:** done
- **Milepæl:** M4
- **Agent:** designer
- **Afhænger af:** –

## Mål
Data og GDD-afsnit for M4. Se `_CONTRACT.md` §1, §2, §4.

## Acceptkriterier
- [x] `game/content/daynight.json` med fasegrænser og begrundelse i GDD (hvor stor del af en spildag er nat; natten skal ikke være så mørk, at parken er svær at bygge i)
- [x] `staff_rules.json`: `self_repair_ticks`, `self_repair_cost` med rationale – startparken må ikke dø af ét nedbrud, men en mekaniker skal stadig betale sig (brug `tools/balance.sh`-tal fra T-041)
- [x] `game/content/audio.json`: alle lyd-id'er fra kontrakten med bus, volumen og beskrivelse af lyden (til procedurel generering)
- [x] GDD: nyt afsnit "M4 – Grafik og lyd" (stemning, farvepalet dag/skumring/nat)
- [x] Ingen kodeændringer

## Ejer / må ikke røre
Ejer: `game/content/`, `docs/gdd.md`. Må ikke røre kode.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – designer: daynight.json, audio.json (17 id'er), staff_rules self_repair 1200/250, GDD-afsnit M4. Bør valideres med balance.sh efter T-047.
- 2026-10-15 – qa (T-053): verificeret – daynight.json/audio.json/staff_rules gyldige og indlæses; balance.sh: ingen seed kollapser uden personale (ødelagt-dage maks 1.5), personale giver bedre snit (4309 vs 3619 penge, 75.4 vs 59.6 omdømme). → done
