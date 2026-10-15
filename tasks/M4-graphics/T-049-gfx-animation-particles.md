# T-049: Grafik – animation og partikler

- **Status:** review
- **Milepæl:** M4
- **Agent:** graphics
- **Afhænger af:** – (parallel med T-048; samme agent, kan køres i forlængelse)

## Mål
Procedurel animation og effekter jf. `_CONTRACT.md` §3.

## Acceptkriterier
- [x] Pariserhjulets gondoler hænger lodret under rotation (backlog fra T-021)
- [x] Alle forlystelser: `set_running(bool)` (accelerer/decelerer, ikke hak) og `set_broken(bool)` (stopper, evt. hældning/blink)
- [x] `GuestVisual`/`StaffVisual`: gå-cyklus via `set_walking`, `play_emote(kind)` for happy/angry/sick/sweep/repair
- [x] Effektscener `repair_sparks`, `coins`, `confetti`, `build_dust`, `sweep_dust` (CPUParticles3D, `play()`, one-shots auto-free)
- [x] Animation på 200 gæster må ikke bruge `AnimationPlayer` pr. gæst (brug billig kode/shader-vertex-bob)
- [x] `test_props.gd` udvidet: alle nye metoder/scener findes og kan kaldes headless

## Ejer / må ikke røre
Som T-048.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – graphics: `RideVisual`: blød acceleration via `Spinner.speed_scale`, `set_broken` stopper + let hældning + rødt blink; pariserhjulets kabiner kontra-roteres (test). `PersonAnim` (RefCounted, ingen AnimationPlayer; processing kun aktiv mens der animeres) bruges af `GuestVisual`/`StaffVisual`: `set_walking`, `play_emote(happy|angry|sick|sweep|repair)` (bevægelse + farvet ikon-kugle). `hop()` = happy-emote. Effekter `repair_sparks` (loop, `stop()`), `coins`, `confetti`, `build_dust`, `sweep_dust` via fælles `ParticleFx` (`play()`, one-shots auto-free); `breakdown_smoke` fik også `play()` (autoplay som før). Tests udvidet. Venter på visuelt check (demo-scenen).
- 2026-10-15 – qa (T-053): headless OK (alle effekter CPUParticles3D, ingen AnimationPlayer pr. gæst, tests grønne). Visuelt check kræver brugeren (se T-053-tjekliste). Bliver på review.
