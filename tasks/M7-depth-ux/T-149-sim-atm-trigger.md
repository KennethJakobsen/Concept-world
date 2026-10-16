# T-149: Sim: gæster bruger hæveautomaten, før pengene er helt væk

- **Status:** done
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-104

## Mål
T-117 målte ATM-effekten til +0–1 % omsætning (mål +15–25 %). Årsagen er i koden og ikke i data: `_try_atm` kaldes kun, når gæsten vil gå hjem med `no_money`. Med `guest_money` 30–80 sker det næsten aldrig (penge<5: 0–3 gæster). Hvis guest_money sænkes, falder hele parkens omsætning, så det kan ikke løses i data.

Forslag: en gæst med en ATM inden for `range_cells` hæver, når `money` < prisen på det, gæsten vil købe/køre (eller < en ny data-tærskel `atm_low_money` i `guests.json`, default 10). Gæsten skal stadig have glæde ≥ `min_happiness`, og `max_per_visit` gælder fortsat. Det skal være deterministisk.

## Acceptkriterier
- [x] Test: en gæst med lav saldo og en ATM inden for rækkevidde hæver, før den går hjem
- [x] Ny data-nøgle med default i `BalanceConfig` (designer sætter værdien)
- [ ] Derefter genmåler designer (T-117-opfølgning): ATM +15–25 % omsætning

## Log
- 2026-10-16 – designer: oprettet fra T-117
- 2026-10-16 – simulation: `_choose_goal` sender nu også en gæst med `money < balance.atm_low_money` (ny nøgle i `guests.json`, default 10 i `Balance`, ikke sat i data) til nærmeste ATM via `_try_atm` (samme krav: range_cells, min_happiness, max_per_visit, åben/ikke i stykker). Test `test_atm_low_money_withdraws_before_broke` (test_m7_amenities). Rettede også `test_m7_config_sales.gd`, så opskriftsværdierne læses fra bodens data. Måling (T-150-sektionen, fuld park, 3 seeds, 5 dage): default 10 → −5,4 % (119 hævninger, støj); eksperiment atm_low_money 25 → +3,3 % (483), 40 → +3,6 % (788). **+15–25 % kan ikke nås med udløseren alene**: penge er sjældent det, der begrænser (gæster går hjem pga. glæde/træthed, og parkens kapacitet). Designeren må tage stilling (fx lavere guest_money + ATM, eller nyt mål). Ingen data ændret. Tests 443/443, integration og balance grønne.
- 2026-10-16 – designer (T-117): målet er revideret til +3–6 % i GDD. `atm_low_money: 30` → +5,6 %. Det tredje kriterium er dermed opfyldt med det nye mål.
- 2026-10-16 – qa: verificeret (test.sh 446/446, integration, balance 5/5 scenarier vundet, web-build, smoke, v1/v2/v3→v4 i test_qa_m7). review → done.
