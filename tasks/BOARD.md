# Board – Concept-world

## M0 – Fundament
| Task | Titel | Agent | Status |
|---|---|---|---|
| T-001 | Installer Godot 4.7 + git-lfs | architect | ✅ done |
| T-002 | Export-templates | architect | ✅ done |
| T-003 | Git-repo, LFS, ignore | architect | ✅ done |
| T-004 | Godot-projekt og mappestruktur | architect | ✅ done |
| T-005 | Test-runner | qa | ✅ done |
| T-006 | GitHub Actions CI | architect | ✅ done |
| T-007 | Docs – GDD, ADR'er, konventioner | architect | ✅ done |
| T-008 | Agent-definitioner | architect | ✅ done |
| T-009 | Hello park – 3D-scene på web | graphics | 🔍 review |

## M1 – Gråboks
| Task | Titel | Agent | Status |
|---|---|---|---|
| T-010 | ParkWorld grid og stier | simulation | ✅ done |
| T-011 | Pathfinding | simulation | ✅ done |
| T-012 | Attraktion (karrusel) | simulation | ✅ done |
| T-013 | Gæster + ParkSim | simulation | ✅ done |
| T-014 | Terræn, picking, props | graphics | ✅ done |
| T-015 | Bridge og byggeværktøjer | gameplay | ✅ done |
| T-016 | M1 verifikation | qa | ✅ done |
| T-017 | Bug: WASD virker ikke | graphics | ✅ done |

## M2 – Kernesimulation  ([kontrakt](M2-core-sim/_CONTRACT.md))
| Task | Titel | Agent | Status |
|---|---|---|---|
| T-018 | Indholdsdata og balance | designer | ✅ done |
| T-019 | Økonomi | simulation | ✅ done |
| T-020 | Behov, butikker, glæde | simulation | ✅ done |
| T-021 | Props til M2-bygninger | graphics | ✅ done |
| T-022 | HUD, byggemenu, info-panel | ui | ✅ done |
| T-023 | Generisk byggeri og valg | gameplay | ✅ done |
| T-025 | Afstem simulation med GDD | simulation | ✅ done |
| T-027 | Bug: byggemenu uden for skærm | ui | 🔍 review |
| T-028 | Test-runner tæller crash som bestået | qa | ✅ done |
| T-029 | Design: tiltrækning og omdømme | designer | ✅ done |
| T-030 | Sim: tiltrækning og omdømme | simulation | ✅ done |
| T-031 | UI: omdømme og entré | ui | ✅ done |
| T-032 | QA: tiltrækning og balance | qa | ✅ done |
| T-033 | Sim: fuld park går i stå | simulation | ✅ done |
| T-034 | Design: omdømme stiger for hurtigt | designer | ✅ done |
| T-024 | M2 verifikation | qa | ✅ done |
| T-026 | Balance-justering | designer | ✅ done |

## M3 – Spilbar loop  ([kontrakt](M3-playable/_CONTRACT.md))
| Task | Titel | Agent | Status |
|---|---|---|---|
| T-035 | Personale, nedbrud, affald, dekoration, 3 forlystelser (data) | designer | ✅ done |
| T-036 | Save/load med versionering | simulation | ✅ done |
| T-037 | Personale, nedbrud, affald, dekoration (sim) | simulation | ✅ done |
| T-038 | Props: personale, dekoration, forlystelser, effekter | graphics | ✅ done |
| T-039 | Personale/dekoration/nedbrud i scenen, indlæsning | gameplay | ✅ done |
| T-040 | Hovedmenu, gem/indlæs, personale-panel | ui | ✅ done |
| T-042 | Bug: omdømme-stjerner som firkanter | ui | ✅ done |
| T-043 | Affald spredes langs rute | simulation | ✅ done |
| T-044 | Personale-balance | designer | ✅ done |
| T-045 | Start i vælg-værktøj | gameplay | ✅ done |
| T-041 | M3 verifikation | qa | ✅ done |

## M4 – Grafikløft  ([kontrakt](M4-graphics/_CONTRACT.md))
| Task | Titel | Agent | Status |
|---|---|---|---|
| T-046 | Dag/nat, lydkatalog, nedbrud uden mekaniker (data) | designer | ✅ done |
| T-047 | Tid på dagen, selv-reparation, nye signaler (sim) | simulation | ✅ done |
| T-048 | Lys og dag/nat-rig | graphics | 🔍 review |
| T-049 | Animation og partikler | graphics | 🔍 review |
| T-050 | AudioManager, busser, procedurelle lyde | gameplay | 🔍 review |
| T-051 | Bridge: dag/nat, effekter og lyd i scenen | gameplay | 🔍 review |
| T-052 | Ur, lydindstillinger, advarsler | ui | 🔍 review |
| T-053 | M4 verifikation | qa | 🔍 review |
| T-055 | Bug: pling for voldsomt, musik monoton | gameplay | 🔍 review |
| T-054 | Bug: lange "spyd" (strakte kugle-meshes), nedbrudseffekt | graphics | 🔍 review |
| T-056 | Bug: tankebobler passer ikke til teksten | graphics | 🔍 review |

## Kommende milepæle
- **M5 Udvidelse:** forskning, scenarier, rutsjebane-bygger

## Åbne punkter / backlog
- T-009, T-027: afventer brugerens visuelle bekræftelse.
- T-048..T-053: afventer brugerens visuelle/lyd-tjek (tjekliste i T-053) og grøn CI efter commit.
- ~~Startpark "dør" ved nedbrud uden mekaniker~~ → løst i T-046/T-047 (verificeret T-053).
- Pariserhjulets gondoler hænger ikke lodret → T-049 (afventer visuelt tjek).
