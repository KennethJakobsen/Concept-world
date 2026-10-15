# ADR-003: Rutsjebane-arkitektur

- **Status:** accepteret
- **Dato:** 2026-10-15
- **Kontekst:** M5 tilføjer en rutsjebane, som spilleren selv bygger stykke for stykke. Det er den første attraktion med variabel form, fysik og eget mesh. Det skal fungere deterministisk, kunne gemmes og testes headless og køre i Compatibility-rendereren (web).

## Beslutning
1. **Banen er data i simulation.** `CoasterTrack` (RefCounted) er en ordnet liste af `TrackPiece` (cell, heading 0..3, højde i niveauer, `piece_id`). Geometrien for hvert stykke (ind-/udgang, højdeændring, længde, krumning) står i `game/content/coaster/pieces.json`. Simulation kender ingen kurver eller meshes, kun den diskrete graf.
2. **Fysikken er en forudberegnet 1D-profil.** Når banen er lukket og gyldig, beregner `CoasterPhysics.simulate(track, train_def)` en profil med faste skridt på 0,05 s langs banens buelængde (energibevarelse, friktion, kædelift og stationsbooster med konstant fart). Resultatet er arrays med fart, g-kraft og position. Ratings (spænding, intensitet, kvalme) afledes af profilen. Der bruges ingen floats fra rendering og ingen `PhysicsServer`. Profilen gemmes ikke, men genberegnes ved load, så den er deterministisk.
3. **Rutsjebanen er en `Attraction`.** Den har `def.kind == "coaster"` og har kø, billet, nedbrud og mekaniker til fælles med de øvrige attraktioner. Turens længde (`ride_ticks`) og `excitement` bliver overskrevet af profilen. Footprint er sættet af celler, banen optager (`Attraction.cells`), og stationens indgangscelle er `entrance_cell`.
4. **Visningen samples fra profilen.** Bridge interpolerer vognenes position ud fra `ride_progress` (0..1) og profilens buelængde. Meshet bygges proceduralt (`SurfaceTool`/`ArrayMesh`) i `rendering/` ud fra stykkernes centerlinjer i `pieces.json`, så sim og grafik bruger samme kilde.
5. **Grid-regler:** et stykke fylder én celle (2x1 for kurve-stor er ikke med i M5). Højden går i niveauer á 1 m (0..8). Stykker kan krydse over stier og andre baner, hvis højdeforskellen er mindst 2 niveauer. Ellers optager de cellen.

## Konsekvenser
- Fysikken kan testes fuldt i unit-tests (lukket oval → kendt fart/rating ± tolerance).
- Nye stykketyper kræver kun data i `pieces.json` plus en centerlinje-generator i rendering, ikke ny sim-kode, så længe de kan beskrives med ind/ud/højde/længde/krumning.
- Ingen loops, inversioner eller banking i M5 (de kan tilføjes senere som nye `piece_id`).
