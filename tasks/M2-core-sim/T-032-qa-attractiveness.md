# T-032: QA – Tiltrækning og balance

- **Status:** done
- **Milepæl:** M2
- **Agent:** qa
- **Afhænger af:** T-029..T-031

## Acceptkriterier
- [x] tools/balance.sh med 3 scenarier: startpark, fuld park (alle 7), startpark med entré 30 – gæstestrøm og penge over 5 dage
- [x] Break-even for startpark stadig omkring dag 3
- [x] Tests, smoke, web-build grønne
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – qa: balance_sim.gd kører 3 scenarier à 5 dage (penge, netto, omdømme, rate, nye, nu/max, glæde). Ny regressionstest tests/test_hud_live.gd (main.tscn + rigtig ParkSim). 61/61 tests, smoke (main.tscn 300 frames, ingen fejl), web-build grønne. T-029/030/031 → done.
  - Startpark: kumuleret netto -1406/+804/+721 → break-even dag 3 ✔. Omdømme 50→73→86→93→96, kapacitet 48/48 fra dag 2.
  - Fuld park: rate 89→115, men 96/96 fra dag 2, glæde falder til ~47–57 og omdømme kollapser 78→36 på dag 4 (trængsel/køer).
  - Entré 30: rate på gulvet 10/dag, underskud fra dag 3 – prisstraf virker.
  - **Balanceforslag (designer, content ikke rørt):** (1) reputation_learn_rate 0.02→~0.005: med ~50 gæster/dag konvergerer omdømmet ~64 %/dag nu; gode parker skal stige, men over ~1–2 uger, ikke 2 dage. (2) Fuld park bliver kapacitetsbegrænset og trængselskollapser – undersøg om gæster forlader parken når max er nået/de er utilfredse, og overvej max_guests_per_capacity 2.0→1.5 eller at max_guests også skalerer med sti-areal. (3) Overvej at spawn_min_per_day (10) ikke gælder ved ekstrem entré, eller accepter – 10/dag ved entré 30 er rimeligt straffende.
