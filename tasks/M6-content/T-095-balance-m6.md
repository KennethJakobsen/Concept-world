# T-095: Balance: M6-indhold

- **Status:** todo
- **Milepæl:** M6
- **Agent:** designer
- **Afhænger af:** T-089, T-093, T-094

## Mål
Justering af intensity/nausea, præmier, ting og sporpriser (kontrakt §8). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [ ] Opkast er < 15 % af affaldet i `balance.sh`
- [ ] Sideshows har positiv margin
- [ ] De nye forlystelser bliver faktisk valgt af gæsterne i simuleringen
- [ ] Kun data og gdd er ændret

## Log
- 2026-10-15 – architect: oprettet

- 2026-10-16 – orkestrator: T-088 opfølgning – lyd-id `vomit` mangler i content/audio.json; tilføj her.
- 2026-10-16 – orkestrator: T-092 opfølgning – log_flume/mini_train/monorail.json skal pege på flume_station/train_station/monorail_station.tscn i `model`.
- 2026-10-16 – orkestrator: balance.sh (11m48s, hænger ikke) efter T-084..T-086: Bjergtoppen kun vundet 1/5 (var vindbar efter T-078), Grøn eng 3/5, Floddalen 5/5. Ret op.
- 2026-10-16 – orkestrator: T-091 – tilføj `wet_ticks`/`wet_happiness_per_tick` i guests.json; T-090 nye fejlkoder `exit_blocked`/`stations_too_close` (tekster tages i T-094).
- 2026-10-16 – orkestrator: lyd-id `splash` mangler også i content/audio.json (T-093).
- 2026-10-16 – orkestrator: research.json – log_flume, mini_train og monorail står i topics.unlocks men mangler i "items", så de kan formentlig aldrig forskes frem i scenarier. Tjek også spor-stykker for flume/train/monorail.
