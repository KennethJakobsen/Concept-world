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
| T-009 | Hello park – 3D-scene på web | graphics | ✅ done |

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
| T-027 | Bug: byggemenu uden for skærm | ui | ✅ done |
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
| T-048 | Lys og dag/nat-rig | graphics | ✅ done |
| T-049 | Animation og partikler | graphics | ✅ done |
| T-050 | AudioManager, busser, procedurelle lyde | gameplay | ✅ done |
| T-051 | Bridge: dag/nat, effekter og lyd i scenen | gameplay | ✅ done |
| T-052 | Ur, lydindstillinger, advarsler | ui | ✅ done |
| T-053 | M4 verifikation | qa | ✅ done |
| T-055 | Bug: pling for voldsomt, musik monoton | gameplay | ✅ done |
| T-054 | Bug: lange "spyd" (strakte kugle-meshes), nedbrudseffekt | graphics | ✅ done |
| T-056 | Bug: tankebobler passer ikke til teksten | graphics | ✅ done |
| T-057 | Bug: spøgelseshusets tag vender forkert | graphics | ✅ done |
| T-058 | Flere detaljer på modellerne | graphics | ✅ done |
| T-059 | Teksturer på terræn, stier og modeller | graphics | ✅ done |
| T-060 | Bug: gokarts følger ikke banen | graphics | ✅ done |
| T-061 | Bug: karrusel, gokart og pariserhjul mangler teksturer | graphics | ✅ done |
| T-064 | Udviklingsværktøjer ud af web-build | architect | ✅ done |
| T-063 | Grid-linjer kun i byggetilstand | gameplay | ✅ done |
| T-062 | Bug: lyskæde-pærer svæver fra modellen | graphics | ✅ done |

M4 afsluttet 2026-10-15 (genåbnet og lukket igen for T-060/T-061).

## M5 – Udvidelse  ([kontrakt](M5-expansion/_CONTRACT.md), [ADR-003](../docs/adr/ADR-003-coaster.md))
| Task | Titel | Agent | Status |
|---|---|---|---|
| T-065 | Data: forskning, scenarier, rutsjebane | designer | ✅ done |
| T-066 | Sim: forskning + save v2 | simulation | ✅ done |
| T-067 | Sim: scenarier, mål, sejr/nederlag | simulation | ✅ done |
| T-068 | Sim: rutsjebane (bane, fysik, ratings) | simulation | ✅ done |
| T-069 | Grafik: procedurel bane, tog, station | graphics | ✅ done |
| T-070 | Gameplay: rutsjebane-værktøj, bridge, scenarie-flow | gameplay | review |
| T-071 | UI: scenarievalg, mål, forskning, rutsjebane-menu | ui | review |
| T-072 | M5 verifikation | qa | review |
| T-073 | Bug: rutsjebanestationens tag vender forkert | graphics | ✅ done |
| T-074 | Grafik: stiliserede bygninger med tema-elementer | graphics | review |
| T-075 | Balance: rutsjebane-ratings og scenarier | designer | in-progress |
| T-076 | Bug: rengøringsfolk løber i flok (opgavereservation) | simulation | review |
| T-077 | Bug: test_ui_m5 forældet efter T-075-data | ui | review |
| T-078 | Balance: Floddalen/Bjergtoppen kan ikke vindes | designer | todo |

## M6 – Mere indhold  ([kontrakt](M6-content/_CONTRACT.md), [ADR-004](../docs/adr/ADR-004-track-systems.md))
| Task | Titel | Agent | Status |
|---|---|---|---|
| T-079 | Design: forslag til flere forlystelser og butikker | designer | ✅ done |
| T-080 | M6 kontrakt, ADR-004 og tasks | architect | ✅ done |
| T-081 | Data: 14 bygninger, intensity/nausea, præmier, bærbare ting | designer | todo |
| T-082 | Data: spor til tømmerrende, minitog og svævebane | designer | todo |
| T-083 | Grafik: props med tema-elementer til 14 bygninger | graphics | todo |
| T-084 | Sim: intensity, kvalme, opkast + save v3 | simulation | todo |
| T-085 | Sim: sideshows og præmier | simulation | todo |
| T-086 | Sim: bærbare ting (ballon, souvenir, præmier) | simulation | todo |
| T-087 | Grafik: bærbare ting, opkast og plask | graphics | todo |
| T-088 | Gameplay: B/D/E i scenen | gameplay | todo |
| T-089 | UI: intensity, kvalme, præmier og ting | ui | todo |
| T-090 | Sim: generaliseret spor, tømmerrende og minitog | simulation | todo |
| T-091 | Sim: svævebane – transport mellem to stationer | simulation | todo |
| T-092 | Grafik: trug, togskinner, monorail-bjælke og køretøjer | graphics | todo |
| T-093 | Gameplay: byggeværktøj for alle sporsystemer | gameplay | todo |
| T-094 | UI: spor-faner, fejltekster og info | ui | todo |
| T-095 | Balance: M6-indhold | designer | todo |
| T-096 | M6 verifikation | qa | todo |

Runder: 1) T-081→T-082, T-083 · 2) T-084→T-085 · 3) T-086, derefter T-087/T-088/T-089 · 4) T-090→T-091, T-092 · 5) T-093/T-094, derefter T-095 · 6) T-096.

## Kommende milepæle
- Ingen planlagt efter M6.

## Åbne punkter / backlog
- Ingen. (Startpark-nedbrud → T-047, pærer → T-062, grid → T-063, tools i web-build → T-064.)
