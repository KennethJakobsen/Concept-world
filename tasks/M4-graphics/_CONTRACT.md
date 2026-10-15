# M4 kontrakt – Grafikløft

Mål: lys, dag/nat-cyklus, partikler, animation, lyd – plus en lille sim-rettelse (startpark dør ved nedbrud uden mekaniker). Alt skal virke i **Compatibility-rendereren (web)**: ingen SDFGI/VoxelGI/SSR/SSAO/volumetrisk tåge, kun `CPUParticles3D`, maks. ~8 samtidige `OmniLight3D` med skygge slået fra, ingen compute-shaders. Kun egne/CC0 eller procedurelt genererede assets (lyd inkl.). Lag-reglerne i `docs/conventions.md` gælder: `game/simulation/` kender ingen noder, ingen lyd, ingen grafik.

## 1. Tid på dagen (simulation, T-047)
- Dag/nat er **visuelt + let gameplay**: simulation ejer tiden, scenen viser den. Tid afledes af eksisterende `day_tick` (0..`balance.day_ticks`-1) – intet nyt gemt state ud over hvad der allerede gemmes (ingen save-version-bump nødvendig; hvis der alligevel tilføjes felter: default + migration).
- `ParkSim.time_of_day() -> float` ∈ [0,1) (0 = midnat, 0.25 = 06:00, 0.5 = middag). `day_tick == 0` svarer til `day_start_time` (data, default 0.25 = parken åbner 06:00).
- `ParkSim.is_night() -> bool` – sand når `time_of_day` ∉ [`dawn`, `dusk`).
- `ParkSim.clock_text() -> String` – "HH:MM" (kun ASCII-cifre og kolon).
- Signal `ParkSim.phase_changed(phase: StringName)` med `&"dawn" | &"day" | &"dusk" | &"night"`; udsendes ved overgang (ikke hver tick). `ParkSim.phase() -> StringName`.
- Data: `game/content/daynight.json` (designer, T-046):
  `{ "day_start_time": 0.25, "dawn": 0.22, "day": 0.30, "dusk": 0.78, "night": 0.86 }` (grænser i time_of_day). Mangler filen → disse defaults.
- Gameplay-effekt i M4: ingen (ingen ændring i spawn/behov). Evt. nat-effekter er M5.

## 2. Nedbrud uden mekaniker (simulation, T-047; tal fra designer T-046)
- `staff_rules.json` nye felter: `"self_repair_ticks": int` (default 2400 – en forlystelse uden tilgængelig mekaniker repareres langsomt af "ekstern service"), `"self_repair_cost": int` (default 200, trækkes fra økonomi under kategori `"repairs"`). 0 = slået fra (gammel adfærd).
- Kun aktiv når parken ikke har nogen ansat mekaniker. Signal `attraction_repaired(a)` genbruges.
- Signal `ParkSim.warning(code: StringName, data: Dictionary)` – generisk advarsel til UI. M4-koder: `&"broken_no_mechanic"` (`{"attraction_id": int}`), udsendes én gang pr. nedbrud.
- Determinisme og save/load round-trip skal stadig holde (ny tæller pr. attraktion gemmes med default 0).

## 3. Rendering (graphics, T-048 / T-049) – `game/scripts/rendering/`, `game/scenes/`
- `DayNightRig` (`class_name DayNightRig extends Node3D`, scene `game/scenes/rendering/day_night_rig.tscn`) indeholder `DirectionalLight3D` (sol/måne) + `WorldEnvironment` (ProceduralSky eller gradient). API:
  - `set_time_of_day(t: float) -> void` – sætter solvinkel, lysfarve, energi, ambient, himmel. Kontinuerlig (kaldes hver frame med interpoleret tid).
  - `night_factor() -> float` 0..1 (1 = fuld nat) – til lamper/forlystelseslys.
  - signal `night_factor_changed(f: float)` (kun ved ændring > 0.01).
- Lamper: eksisterende `LampVisual.set_on(bool)` bevares; ny `set_intensity(f: float)` (0..1).
- Forlystelser får valgfri `RideVisual`-grænseflade (duck-typed metoder på rodnoden – brug `has_method`):
  - `set_running(on: bool)`, `set_broken(on: bool)`, `set_lights(f: float)` (natbelysning 0..1).
- Pariserhjul: gondoler kontra-roterer, så de altid hænger lodret.
- Personer: `GuestVisual`/`StaffVisual` får `set_walking(on: bool)` (gå-cyklus: bob + arm/ben-sving, proceduralt) og `play_emote(kind: StringName)` – `&"happy" | &"angry" | &"sick" | &"sweep" | &"repair"`.
- Effekter (scener i `game/scenes/effects/`, alle `CPUParticles3D`, one-shot hvor nævnt, auto-free): `breakdown_smoke.tscn` (findes), `repair_sparks.tscn` (loop mens mekaniker reparerer), `coins.tscn` (one-shot ved køb), `confetti.tscn` (one-shot, ny forlystelse åbnet), `build_dust.tscn` (one-shot ved placering/fjernelse), `sweep_dust.tscn` (one-shot). Alle har metoden `play()`.
- Performance-budget web: 200 gæster + 20 forlystelser ≥ 30 fps på en middelklasse-laptop i Chrome (manuel, brugeren bekræfter).

## 4. Lyd (gameplay, T-050) – `game/scripts/audio/`, `game/assets/audio/`
- Bus-layout `game/default_bus_layout.tres`: `Master` → `Music`, `SFX`, `Ambience`, `UI`.
- Autoload `AudioManager` (`game/scripts/audio/audio_manager.gd`, `extends Node`):
  - `play_sfx(id: StringName, pos: Vector3 = Vector3.INF) -> void` – 3D (`AudioStreamPlayer3D` fra pool, maks. 16) hvis pos er sat, ellers 2D.
  - `play_ui(id: StringName) -> void`
  - `set_ambience(id: StringName, fade_s: float = 2.0) -> void` (`&"day"`, `&"night"`, `&""` = stop) – crossfade.
  - `play_music(id: StringName) / stop_music()` – `&"menu"`, `&"park"`.
  - `set_bus_volume(bus: StringName, linear: float) -> void`, `get_bus_volume(bus) -> float`, `set_muted(bus, on)`, `is_muted(bus) -> bool`. Indstillinger persisteres i `user://settings.cfg` (sektion `audio`).
- Lyd-id'er (katalog `game/content/audio.json`, designer T-046 – id → fil/generator + volumen + bus):
  SFX: `build`, `demolish`, `cash`, `breakdown`, `repair`, `sweep`, `ride_start`, `cheer`, `error`. UI: `click`, `hover`, `open`, `close`. Ambience: `day`, `night`. Musik: `menu`, `park`.
- Lyd skal være egne/CC0 eller **procedurelt genereret** (`AudioStreamWAV` bygget i kode eller `AudioStreamGenerator`). Ukendt id → `push_warning` én gang, ingen crash. Web: lyd startes først efter første brugerinput (browser-autoplay); AudioManager håndterer det (kø indtil første input).
- Headless (`DisplayServer.get_name() == "headless"`): alle kald er no-ops uden fejl.

## 5. Bridge (gameplay, T-051) – `game/scripts/bridge/`
- `ParkView` instansierer `DayNightRig` og kalder `set_time_of_day()` hver frame (interpoleret mellem ticks), og sætter lamper/forlystelseslys ud fra `night_factor()`.
- `ParkView` mapper sim-signaler → visuelt + lyd:
  | Sim-signal | Effekt | Lyd |
  |---|---|---|
  | attraction_placed / decor_placed | build_dust (+ confetti for rides) | build |
  | attraction_removed / decor_removed | build_dust | demolish |
  | attraction_broken | breakdown_smoke, `set_broken(true)` | breakdown |
  | mekaniker reparerer | repair_sparks, emote repair | repair |
  | attraction_repaired | stop røg/gnister, `set_broken(false)` | – |
  | gæst køber (shop/billet) | coins (throttlet, maks. 4/s) | cash (throttlet) |
  | affald fejet | sweep_dust | sweep |
  | ride-cyklus starter | `set_running(true)` | ride_start (kun hvis kameraet er tæt på) |
  | phase_changed | – | `set_ambience(day/night)` |
- Hvis sim mangler et signal til en række (fx køb, fej, ride-start), tilføjer simulation det i T-047: `ParkSim.purchase_made(guest_id: int, building_id: int, amount: int)`, `ParkSim.litter_swept(cell: Vector2i)`, `ParkSim.ride_cycle_started(attraction_id: int)`. Disse tre signaler er **en del af kontrakten** (simulation implementerer dem).
- ParkView udsender selv `signal fx_event(kind: StringName, pos: Vector3)` (til tests og evt. UI).

## 6. UI (ui, T-052) – `game/scripts/ui/`, `game/scenes/ui/`
- HUD: ur (`clock_text()`) + sol/måne-ikon (tegnet med `draw_*`/shapes, ikke unicode-symboler – fonttesten!).
- Indstillinger-panel (fra hovedmenu og pausemenu): volumen-skydere for Master/Music/SFX/Ambience/UI + mute, via AudioManager-API. Dag/nat-hastighed er ikke en indstilling.
- `play_ui(&"click")` på knapper (brug en fælles hjælper, ikke pr. knap).
- Vis `warning`-signalet som toast ("Forlystelse i stykker – ansæt en mekaniker!").

## Ejerskab (hvem må røre hvad)
| Agent | Må røre | Må ikke røre |
|---|---|---|
| designer | `game/content/*.json`, `docs/gdd.md` | kode |
| simulation | `game/simulation/`, `game/tests/` (sim-tests) | scripts/, scenes/ |
| graphics | `game/scripts/rendering/`, `game/scenes/props|effects|rendering/`, `game/shaders/`, `game/assets/` (ikke audio), `game/tests/test_props.gd` | simulation/, bridge/, ui/ |
| gameplay | `game/scripts/bridge|building|audio/`, `game/assets/audio/`, `game/default_bus_layout.tres`, autoload i `project.godot`, `game/scenes/main.tscn` | simulation/, rendering/, ui/ |
| ui | `game/scripts/ui/`, `game/scenes/ui/` | simulation/, bridge/, rendering/ |
