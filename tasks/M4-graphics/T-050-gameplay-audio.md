# T-050: Lyd – AudioManager, busser og procedurelle lyde

- **Status:** review
- **Milepæl:** M4
- **Agent:** gameplay
- **Afhænger af:** – (bruger indbyggede defaults indtil T-046's `audio.json` lander)

## Mål
`_CONTRACT.md` §4: bus-layout, autoload `AudioManager`, procedurel generering af alle lyd-id'er (eller egne/CC0-filer med licens noteret i `game/assets/audio/LICENSES.md`).

## Acceptkriterier
- [x] `default_bus_layout.tres` med Master/Music/SFX/Ambience/UI
- [x] `AudioManager` autoload med hele API'et; pool af 3D-afspillere (maks. 16); crossfade af ambience
- [x] Alle id'er i kontrakten giver lyd; ukendt id → én warning, ingen crash
- [x] Indstillinger gemmes/indlæses i `user://settings.cfg`
- [x] Web-autoplay: intet afspilles før første input; headless: no-ops uden fejl/warnings
- [x] Tests (headless): API kan kaldes, volumen/mute persisteres, ukendt id crasher ikke
- [x] `tools/test.sh` + smoke grønne

## Ejer / må ikke røre
Ejer: `game/scripts/audio/`, `game/assets/audio/`, `game/default_bus_layout.tres`, autoload-sektion i `project.godot`, audio-tests i `game/tests/`. Må ikke røre `game/simulation/`, `game/scripts/rendering|ui/`, `game/content/`.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – gameplay: `scripts/audio/audio_manager.gd` (autoload) + `audio_synth.gd` (alle 17 id'er procedurelt, deterministisk WAV), `default_bus_layout.tres`, `tests/test_audio.gd`. Læser valgfrit `content/audio.json` (id → file/volume_db/bus). Web: musik/ambience i kø til første input. Headless: no-ops. Indstillinger i `user://settings.cfg` [audio]. test.sh: mine tests grønne; eneste fejl er `test_ui_m4` (UI-agentens igangværende T-052). Smoke OK. Lyden selv kræver brugerens ører → bliver på review.
- 2026-10-15 – qa (T-053): headless OK (test_audio grøn, headless no-ops uden warnings, alle lyde procedurelle – ingen licensbehov). Lyd kræver brugerens ører. Bliver på review.
- 2026-10-15 – orkestrator: brugeren har godkendt visuelt/lyd. Status: done.
