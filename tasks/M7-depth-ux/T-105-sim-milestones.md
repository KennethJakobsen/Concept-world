# T-105: Sim: milepæle, der låser forskningsgrene op

- **Status:** done
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-104

## Mål
Kontraktens §1 T-105 (GDD §10). Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `milestones()`, `topic_available`, `milestone_achieved`
- [x] Sandbox og `milestones: false` håndteres
- [x] Backfill ved load af migrerede saves uden belønning i penge/point og med `milestones_backfilled`
- [x] Udvider `_v3_to_v4`. Tests for hver betingelse

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – simulation: in-progress → review. `MilestoneDef`/`Milestones` (`simulation/milestones/`), `ParkSim.milestones()`, `milestone_measure(cond)`, `topic_available(topic)`, `topic_locked_by(topic)`, `milestones_enabled()` (scenarie + forskning slået til + `milestones != false`; sandbox = alt åbent, ingen belønning). Låste emner (gated af milepæl, ikke i `research.json.start_topics`) springes over af forskningen, og `cmd_set_research_priority` afviser dem. Evaluering hvert 20. tick + ved dagsskift; `days_clean` = sammenhængende dage med ≤ `clean_max_litter` (10, kan sættes i milestones.json). Belønning: `money` → kategori `rewards`, `research_points` → `Research.add_points`, `unlock_topic`. Backfill (saves migreret fra v≤3) ved første tick: kun beregnelige betingelser, ingen penge/point, signal `milestones_backfilled(ids)`. Save: `park.milestones`, `milestones_backfill`, `milestones_days_clean` (+ migration). `test_qa_m5::test_research_unlocks_then_build` bruger nu `milestones: false`. Tests: `test_m7_milestones.gd` (8). balance.sh 5/5 i alle scenarier.
- 2026-10-16 – qa: verificeret (test.sh 446/446, integration, balance 5/5 scenarier vundet, web-build, smoke, v1/v2/v3→v4 i test_qa_m7). review → done.
