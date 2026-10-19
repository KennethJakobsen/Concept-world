# T-153: Bug: spillet hænger ved "Fortsæt"

- **Status:** done
- **Milepæl:** M7
- **Agent:** gameplay
- **Afhænger af:** T-106, T-111, T-115, T-135

## Mål
Brugerrapport (web-build 2026-10-16): spillet hænger, når man trykker "Fortsæt" (hovedmenuen: indlæs autosave). Autosaven i browseren kan være lavet af et ældre build (før M7/v4) eller under M7. Find årsagen (uendelig løkke, migration, rebuild af omgivelser/crowd/tutorial ved load osv.) og ret den.

## Acceptkriterier
- [x] Reproduceret (headless) og årsag dokumenteret i log
- [x] Fortsæt indlæser autosave fra både gammel version (v1–v3) og ny v4 uden at hænge
- [x] En korrupt/ulæselig autosave giver en fejlbesked i stedet for at hænge
- [x] Regressionstest i integration.sh

## Log
- 2026-10-18 – orkestrator: oprettet fra brugerrapport
- 2026-10-18 – gameplay: Reproduceret headless (repro-script, fjernet igen; dækket af integration.sh). Ingen uendelig løkke ved load: frisk park, bygget park (kø, flyttet+drejet karrusel), tutorial, green_meadow/mountain_peak/river_valley, v1-fixture og en rigtig v3-autosave lavet med buildet før v4 (3c80e64^: tømmerrende, minitog, svævebane, 27 dage) indlæses alle på 0,3-0,55 s headless, maks. frame 8-9 ms.
  Årsager (sandsynligvis flere sammen):
  1. **Indlæst park var frosset:** `ParkSim._scenario_day` udsender `scenario_finished` FØR `day_passed`. GameSession pauser ved `scenario_finished`, og derefter skrives autosaven med `paused=true`. Saves fra pause-menuen gemmes også med `paused=true`. Ved Fortsæt kom parken op pauset uden resultat-dialog, så det lignede, at spillet hang. Rettelse: `ParkView._resume_loaded` starter altid indlæste parker kørende (og sætter speed 0 til 1).
  2. **Dødsspiral på web:** `ParkView._process` sendte frame-delta uden loft til `sim.update`. Første frame efter et tungt scene-load varer flere sekunder på web, og det gav hundredvis af ticks i én frame, som så gav en endnu længere frame. Rettelse: `MAX_FRAME_DELTA = 0.25` s (SimClock er urørt, så `update(5.0)` i tests og balance virker som før).
  3. **Ulæselig autosave:** gyldig JSON med en ødelagt park startede stille en ny park. Korrupt JSON gav en ERROR i loggen. Rettelse: `GameSession.load_from` bygger og validerer sim'en før scene-skiftet (`pending_sim`, som ParkView overtager) og returnerer false, så menuen viser "Kunne ikke indlæse autosave". `SaveStore.load` bruger `JSON.new().parse()`, så der ikke logges en ERROR.
  Autosave under frame-løb: skrives kun ved `day_passed` (én gang pr. dag, ca. 50 KB JSON), ikke hvert tick. Det blokerer ikke.
  Pause-menuens "Fortsæt" (`close` → `Hud._on_pause_menu_closed`): hænger ikke. Den genskaber pausetilstanden fra før menuen blev åbnet. Var spillet pauset, forbliver det pauset (det er tilsigtet, og der er en test for det).
  Resultat-dialogens "Fortsæt i fri leg": hænger ikke. Den fjerner pausen og sætter speed 0 til 1. Scenariet er ikke længere `is_running`, så `scenario_finished` udsendes ikke igen.
  Regression i `integration.sh` (`_check_continue`): pauset v4, v1, korrupt JSON og ulæselig park via hovedmenuen → continue_park. Den tjekker også, at en lang frame giver højst 6 ticks. import, test.sh (446/0), integration.sh, smoke og build_web.sh er OK. Ikke verificeret i browseren: brugeren bør prøve Fortsæt i web-buildet.
- 2026-10-19 – orkestrator: brugeren bekræfter at Fortsæt virker i browseren → done
