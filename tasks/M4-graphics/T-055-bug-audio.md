# T-055: Bug – pling for voldsomt/hyppigt, musik for monoton

- **Status:** review
- **Milepæl:** M4
- **Agent:** gameplay
- **Afhænger af:** T-050, T-051

## Mål
Brugerfeedback: "pling-lyden er for voldsom og det er hele tiden, samt musikken er for monoton".

## Acceptkriterier
- [x] Cash-pling: meget lavere volumen (-22 dB), blødere klang (én sinus + svag oktav, blød attack/eksp. decay)
- [x] Cash højst 1 pr. 3 s og kun nær kameraet; coins-effekt højst 1 pr. 2,5 s
- [x] Andre hyppige SFX throttlet (sweep 2 s + kun nær kamera, ride_start 4 s, repair 1,5 s)
- [x] Generel throttling i AudioManager via katalogfelt `min_interval_s`
- [x] Musik: længere loop med A-A'-B-A'-sektioner, akkordprogression, melodi-variation, bas/pad, lavere volumen (menu -20, park -22 dB); deterministisk og procedurel
- [x] `tools/test.sh` grøn
- [ ] Brugeren bekræfter lyden

## Ejer / må ikke røre
Ejer: `game/scripts/audio/`, `game/content/audio.json`, lyd-kald i `game/scripts/bridge/park_view.gd`. Må ikke røre rendering, props, simulation, ui.

## Log
- 2026-10-15 – gameplay: oprettet og løst. AudioSynth: `_soft_pling` til cash; ny `_compose` (8-takters sektioner A/A'/B/A'', I-vi-IV-V m.fl., seedet motiv + variation, B løftet en kvart oktav op, oom-pah bas, pad, percussion i park) – menu ~43 s vals, park ~35 s. AudioManager: `min_interval_s`-throttle pr. id. audio.json: lavere volumener + intervaller. ParkView: COIN_INTERVAL 0.25→2.5, cash/sweep kun ved `_camera_near`. test.sh 147/0. Afventer brugerens ører.
