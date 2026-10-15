# ADR-004: Generaliseret sporsystem (rutsjebane, vandbane, minitog, svævebane)

- **Status:** accepteret
- **Dato:** 2026-10-15
- **Kontekst:** M6 tilføjer tre sporbaserede attraktioner: Tømmerrenden (vandbane, mekanik A), Bimmelbanen (minitog) og Svævebanen (transport mellem to stationer, mekanik C). ADR-003 byggede sporet specifikt til rutsjebanen (`CoasterTrack`, `coaster/pieces.json`, `kind == "coaster"`). Hvis vi kopierer det tre gange, får vi fire næsten ens byggekommandoer, fire mesh-klasser og fire save-formater.

## Beslutning
1. **Ét spor, flere "track systems".** `CoasterTrack`, `TrackPiece`, `TrackPieceDef` og `CoasterPhysics` beholder deres navne, så M5-koden og testene ikke skal ændres. Til gengæld får de en **systemparameter**:
   - `TrackPieceDef.system: StringName` (`&"coaster" | &"flume" | &"train" | &"monorail"`, default `&"coaster"`).
   - Stykker ligger i `game/content/tracks/<system>.json`. `coaster/pieces.json` læses fortsat som system `coaster`, og der flyttes ingen filer.
   - `CoasterContent.pieces(system: StringName = &"coaster") -> Dictionary`.
   - En bane må kun bestå af stykker fra ét system. Det håndhæves af `cmd_place_track_piece` med fejlen `"wrong_system"`.
2. **Attraktions-`kind` bestemmer systemet.** Kind og system hænger sammen sådan: `coaster` → coaster, `flume` → flume, `train` → train og `transport` → monorail. `Attraction.is_tracked() -> bool` er sand for alle fire. De eksisterende `cmd_start_coaster`/`cmd_place_track_piece`/`cmd_remove_last_piece`/`cmd_finish_coaster` virker for alle sporbaserede kinds. Navnet "coaster" er historisk, og der laves ingen alias-API.
3. **Systemforskelle ligger i data og ikke i nye klasser:**
   - Nye felter på stykkerne (alle med default): `friction`, `splash` (bool), `water` (bool), `min_level`, `max_level`, `station_role` (`""`, `"start"` eller `"end"`), `allow_rise` og `allow_turn`.
   - Systemdefinition i `tracks/<system>.json` → `"system": {...}`: `closed_loop` (bool, true for coaster/flume/train og false for monorail), `max_stations` (1 eller 2), `clearance_levels` (2 for coaster, 1 for train/flume, 3 for monorail) og `speed_mode` (`"physics"` eller `"constant"`).
   - `CoasterPhysics.simulate` giver ved `speed_mode == "constant"` en profil med konstant fart (`train.cruise_speed`) og g = 1. Det sker uden særlig rating-logik, og ratings kommer fra attraktionens data i stedet for profilen.
4. **Åbne baner (svævebane).** Når `closed_loop == false`, er banen gyldig, hvis den går fra en `station_role:"start"` til en `station_role:"end"` uden at lukke. `CoasterTrack.is_closed()` erstattes i valideringen af `is_complete()`, som er `is_closed()` for lukkede systemer og "slutter i en end-station" for åbne. Transportens to stationsindgange registreres i `ParkWorld` som en **kant i stigrafen** med vægten `transport_cost` fra data. Pathfinding behandler kanten som en almindelig nabo, der kun kan bruges, når attraktionen er åben og ikke er brudt ned. Det er stadig deterministisk A*, bare med en ekstra nabo-kilde.
5. **Rendering er også generisk.** `CoasterTrackMesh.build(pieces, defs)` dispatcher på `defs[*].system` til et profil-snit: skinner+sveller (coaster/train), trug med vand (flume) eller bjælke (monorail). `centerline()` er fælles. Køretøjer er `CoasterTrain` med `set_style(system: StringName)` (vogn, træstamme-båd, lokomotiv+vogne eller kabine).

## Konsekvenser
- Det er billigt at tilføje et nyt sporbaseret system: det kræver kun data, et snit i meshet og et køretøj.
- Save-formatet er uændret for spor (`attractions[].track` er allerede generisk). Kun `def.kind` bestemmer systemet, så der er ingen migration for spor-strukturen.
- Pathfinding får en kant, der ikke er en sti. Testene skal dække både en lukket og en brudt svævebane.
- Afvist alternativ: en `TrackSystem`-klassehierarki pr. type. Det giver mere kode og dårligere testbarhed, og forskellene kan udtrykkes i data.
