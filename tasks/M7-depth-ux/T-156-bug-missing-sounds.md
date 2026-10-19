# T-156: Bug: lydene 'splash' og 'vomit' findes ikke

- **Status:** review
- **Milepæl:** M7
- **Agent:** gameplay
- **Afhænger af:** T-050, T-087

## Mål
Brugerens browserkonsol: `WARNING: AudioManager: ukendt lyd-id 'splash'`. `audio.json` har `vomit` og `splash` (procedural), men `AudioSynth` kan ikke generere dem.

## Acceptkriterier
- [x] `AudioSynth` genererer `splash` og `vomit` efter beskrivelserne i `audio.json`
- [x] Test: alle id'er i `audio.json` uden `file` kan genereres af `AudioSynth`
- [x] Tests grønne, web-build lavet

## Log
- 2026-10-19 – orkestrator: oprettet fra brugerens konsol-output
- 2026-10-19 – gameplay: AudioSynth genererer nu `splash` (båndpas-støj 800-4000 Hz, 0.6 s decay, amp 0.14) og `vomit` (lavpas-støj med cutoff 400->120 Hz, 0.3 s, amp 0.16) – holdt diskrete jf. T-055. Ny test `test_catalog_ids_without_file_synthesize` i test_audio.gd. test.sh 447/0, integration OK, web-build OK. Lydniveau kræver brugerens ører.
