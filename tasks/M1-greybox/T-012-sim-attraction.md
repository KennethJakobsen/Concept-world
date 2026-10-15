# T-012: Simulation – Attraktion (karrusel)

- **Status:** review
- **Milepæl:** M1
- **Agent:** simulation
- **Afhænger af:** T-010

## Mål
Datadrevet attraktion med footprint, indgangscelle, kø, kapacitet og cyklus.

## API-kontrakt
- `game/content/attractions/carousel.json`: `{ "id","name","footprint":[w,h],"capacity","ride_ticks","ticket_price" }`
- `class_name AttractionDef extends Resource` + loader `AttractionDef.from_json(path) -> AttractionDef`
- `class_name Attraction extends RefCounted`: `id:int`, `def`, `origin:Vector2i`, `entrance_cell:Vector2i`, `queue:Array`, `riders:Array`, `func tick()`, `signal ride_started`, `signal ride_finished(guest_ids)`
- `ParkWorld.can_place_attraction(def, origin) -> bool`, `ParkWorld.place_attraction(def, origin) -> Attraction` (sætter tiles til ATTRACTION; entrance_cell = celle lige under footprint midt, skal være græs/sti og bliver PATH), `signal attraction_placed(attraction)`

## Acceptkriterier
- [x] Tests: placering/kollision, kø → ride → finish efter ride_ticks, kapacitet respekteres
- 2026-10-15 – simulation: startet
- 2026-10-15 – simulation: implementeret med tests, ./tools/test.sh grøn (17 tests) → review
