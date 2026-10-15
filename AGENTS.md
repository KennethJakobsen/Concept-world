# Concept-world – instruktioner til AI-sessioner

3D park-management-spil (inspireret af klassiske theme-park-spil, eget navn og egne assets) i **Godot 4.7.2 med statisk typet GDScript**. Målplatforme: desktop + **web** (derfor Compatibility-renderer og ikke C#, se `docs/adr/ADR-001-platform.md`).

## Start her
1. Læs `tasks/BOARD.md` (status) og `tasks/README.md` (task-regler).
2. Læs `docs/conventions.md` (lag og kodestil) og den aktuelle milepæls `_CONTRACT.md` i `tasks/M<n>-*/`.
3. Design: `docs/gdd.md`. Arkitektur: `docs/adr/`.

## Arbejdsform
- **Alt arbejde går gennem tasks** i `tasks/`. Ingen kodeændring uden en task. Brugeren følger fremdriften i `tasks/BOARD.md`.
- Hovedsessionen er **orkestrator**: opretter tasks (med API-kontrakt, når flere agenter arbejder parallelt) og uddelegerer til agenterne i `.opencode/agents/`:
  `architect`, `designer` (kun content/docs), `simulation` (`game/simulation/` + tests), `gameplay` (`game/scripts/bridge|building/`), `graphics` (props/shaders/rendering), `ui` (`game/scripts/ui/`, `game/scenes/ui/`), `qa` (verificerer og flytter review → done).
- Kør uafhængige agenter parallelt, og giv hver agent eksplicit besked om, hvilke mapper den ikke må røre.
- Fejl, som brugeren rapporterer: opret en bug-task (`T-<næste nr>`) i den aktuelle milepæl og send den til den relevante agent.
- Visuelle ting kan ikke verificeres headless. Tasks, der kræver brugerens øjne, bliver stående på `review`, indtil brugeren har bekræftet dem.
- Commit-beskeder starter med task-id'er, f.eks. `T-012: ...`. Commit efter hver afsluttet runde.

## Kommandoer
```bash
./tools/test.sh          # unit-tests (egen runner, crash = fejl)
./tools/integration.sh   # headless flow: menu → park → gem → indlæs
./tools/balance.sh       # balance-simulation (flere scenarier/seeds)
./tools/build_web.sh     # web-build → build/web
cd game && godot --headless --import                         # efter nye class_name-filer
cd game && godot --headless --quit-after 300 res://scenes/main.tscn   # smoke
```

## Git/GitHub
- Remote: `https://github.com/KennethJakobsen/Concept-world.git` (CI: `.github/workflows/ci.yml`).
- `gh` har to konti. Den aktive er `kja-logos`, men der skal pushes som `KennethJakobsen`:
  `gh auth switch -u KennethJakobsen && git push; gh auth switch -u kja-logos`
- CI-status: `GH_TOKEN=$(gh auth token -u KennethJakobsen) gh run list -R KennethJakobsen/Concept-world -L 1`

## Kerneprincipper
- `game/simulation/` er ren logik (`RefCounted`/`Resource`, aldrig `Node`), deterministisk (seedet RNG, fast tick 20/s) og fuldt testet.
- Indholdet er datadrevet (`game/content/*.json`). Balance justeres i data, ikke i kode.
- Save-formatet er versioneret (`SaveMigrations`). Nye felter skal have defaults.
- Alt skal virke i Compatibility-rendereren (web). Kun egne eller CC0-assets.
- UI'et må kun bruge tegn, som standardfonten har (der er en test for det).
