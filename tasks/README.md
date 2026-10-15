# Tasks – Concept-world

Alt arbejde i projektet sker gennem tasks i denne mappe. Ingen kodeændring uden en task.

## Struktur

```
tasks/
├─ README.md          # denne fil: regler og skabelon
├─ BOARD.md           # overblik over alle tasks og status
└─ M<n>-<navn>/       # én mappe pr. milepæl
   └─ T-<nnn>-<slug>.md
```

## Statusser

| Status | Betydning |
|---|---|
| `todo` | Klar, ikke startet |
| `in-progress` | Under arbejde |
| `review` | Færdig, afventer review/QA |
| `done` | Godkendt og afsluttet |
| `blocked` | Venter på noget (angiv hvad i loggen) |

## Regler

1. Hver task har ét ansvarligt agent-navn (se `.opencode/agents/`).
2. Agenten sætter status og skriver i loggen, når arbejdet starter og slutter.
3. Acceptkriterier skal være afkrydset før `review`.
4. `qa` (eller `architect` for doc/arkitektur-tasks) flytter `review` → `done`.
5. `BOARD.md` opdateres ved hver statusændring.
6. Nye tasks får næste ledige nummer (globalt fortløbende).

## Skabelon

```markdown
# T-000: Titel

- **Status:** todo
- **Milepæl:** M0
- **Agent:** architect
- **Afhænger af:** –

## Mål
Hvad og hvorfor.

## Acceptkriterier
- [ ] ...

## Log
- YYYY-MM-DD – agent: oprettet
```
