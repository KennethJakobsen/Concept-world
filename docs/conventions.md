# Konventioner – Concept-world

## Lag
| Mappe | Indhold | Må afhænge af |
|---|---|---|
| `game/simulation/` | Spillogik (`RefCounted`/`Resource`) | kun sig selv |
| `game/content/` | Data: rides, shops, priser | – |
| `game/scripts/bridge/` | Sim → scene-synk | simulation |
| `game/scripts/building/` | Byggeværktøjer | simulation, bridge |
| `game/scripts/rendering/` | Kamera, lys, effekter | – |
| `game/scripts/audio/` | `AudioManager` (autoload), procedurelle lyde (`AudioSynth`), busser i `default_bus_layout.tres` | – (kaldes fra bridge/ui via id'er) |
| `game/scripts/ui/` | HUD, menuer | simulation (læs + kommandoer) |

## Kode
- Statisk typning overalt (`var x: int`, returtyper).
- `snake_case` filer/funktioner, `PascalCase` klasser (`class_name`).
- Simulation: fast tick 20/s (`SimClock`), seedet RNG, ingen `Node`.
- Visning taler til simulation via kommandoer; simulation svarer via signaler.

## Workflow
- Alt arbejde via `tasks/` (se `tasks/README.md`).
- `tools/test.sh` skal være grøn før `review`.
- Commit-besked starter med task-id: `T-012: ...`.
