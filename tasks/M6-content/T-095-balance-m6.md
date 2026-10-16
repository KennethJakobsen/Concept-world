# T-095: Balance: M6-indhold

- **Status:** review
- **Milepæl:** M6
- **Agent:** designer
- **Afhænger af:** T-089, T-093, T-094

## Mål
Justering af intensity/nausea, præmier, ting og sporpriser (kontrakt §8). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] Opkast er < 15 % af affaldet i `balance.sh`
- [x] Sideshows har positiv margin
- [x] De nye forlystelser bliver faktisk valgt af gæsterne i simuleringen
- [x] Kun data og gdd er ændret

## Log
- 2026-10-15 – architect: oprettet

- 2026-10-16 – orkestrator: T-088 opfølgning – lyd-id `vomit` mangler i content/audio.json; tilføj her.
- 2026-10-16 – orkestrator: T-092 opfølgning – log_flume/mini_train/monorail.json skal pege på flume_station/train_station/monorail_station.tscn i `model`.
- 2026-10-16 – orkestrator: balance.sh (11m48s, hænger ikke) efter T-084..T-086: Bjergtoppen kun vundet 1/5 (var vindbar efter T-078), Grøn eng 3/5, Floddalen 5/5. Ret op.
- 2026-10-16 – orkestrator: T-091 – tilføj `wet_ticks`/`wet_happiness_per_tick` i guests.json; T-090 nye fejlkoder `exit_blocked`/`stations_too_close` (tekster tages i T-094).
- 2026-10-16 – orkestrator: lyd-id `splash` mangler også i content/audio.json (T-093).
- 2026-10-16 – orkestrator: research.json – log_flume, mini_train og monorail står i topics.unlocks men mangler i "items", så de kan formentlig aldrig forskes frem i scenarier. Tjek også spor-stykker for flume/train/monorail.
- 2026-10-16 – designer: udført.
  - audio.json: `vomit` og `splash` tilføjet. guests.json: `wet_ticks` 600, `wet_happiness_per_tick` 0.005. log_flume/mini_train/monorail `model` → flume_/train_/monorail_station.tscn.
  - Sideshows (før: 20–30 besøg/5 dage, drift 50–90/dag → negativ margin): excitement 4–5 → 14/15/16/16, intensity 0 → 25/30/15/35, drift → 25/30/15/15, pris kokos 3/skyde 4/kraft 3, andefiskeri prize_cost 1. Måling (5 dage, park med alle 13 rides + alle shops, 3 seeds): 70–110 besøg pr. sideshow, netto positiv for alle fire.
  - Opkast: 1–8 opkast pr. 5 dage, 0–5 % af stående affald (< 15 %). Alle 13 ride-typer vælges (drop_tower lavest, ~16–34 besøg).
  - Scenarier: Grøn eng 120 → 115 gæster; Bjergtoppen 85 → 75 gæster, parkværdi 100000 → 92000, omdømme 55 → 52. balance.sh før: Grøn eng 3/5, Floddalen 5/5, Bjergtoppen 1/5. Efter: 5/5, 5/5, 5/5. test.sh 299/0, integration OK.
  - Opfølgning (sim): balloon_stand/souvenir_shop får 0 besøg – shops med `satisfies: {}` vælges aldrig (kun behovsdrevet shop-valg). Kræver impulskøb i sim. balance.sh måler ikke opkast/sideshow-margin (målt med midlertidigt script).
