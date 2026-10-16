# T-088: Gameplay: B/D/E i scenen

- **Status:** done
- **Milepæl:** M6
- **Agent:** gameplay
- **Afhænger af:** T-086, T-087

## Mål
Bridge-forbindelse af signalerne for opkast, præmier og ting (kontrakt §6 T-088). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] `guest_vomited` → effekt og lyd
- [x] `prize_won` → cheer og pling
- [x] `item_gained`/`item_lost` → `set_items` og `balloon_float`
- [x] Gameplay-tests og `integration.sh` er grønne

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-16 – gameplay: ParkView forbinder guest_vomited (vomit-fx, sick-emote, lyd `vomit`), prize_won (happy-emote, cheer + cash, fx_event `prize`), item_gained/item_lost (set_items fra guest.items; balloon_float ved tabt ballon). FX_SCENES har balloon_float/vomit/splash. Items gendannes ved spawn/rebuild (load); opkast gendannes som affald via litter. Tests: alle ikke-sporbaserede bygninger bygges med node, items/præmie/opkast-bridge. Bemærk: lyd-id `vomit` findes ikke i content/audio.json endnu (AudioManager advarer én gang og er tavs) – kræver content-task.
- 2026-10-16 – bruger: godkendt.
