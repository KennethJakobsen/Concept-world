# T-031: UI – Omdømme, tiltrækning og entré i HUD

- **Status:** done
- **Milepæl:** M2
- **Agent:** ui
- **Afhænger af:** T-030

## Mål
Topbar: omdømme (fx stjerner/procent) og gæster "nu / max". Park-panel (knap i topbar): entré med +/- (cmd_set_entry_fee), tiltrækningsscore, forventede gæster pr. dag, i dag indtægter/udgifter.

## Acceptkriterier
- [x] Viser værdier fra get_stats(); entré kan ændres
- [x] Panel inden for viewport ved 1024×600 (test)
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – ui: topbar med omdømme (★ + %) og gæster nu/max (defensivt via get_stats().get/has); Park-knap → park-panel: entré +/- (cmd_set_entry_fee), tiltrækning, forventede gæster/dag, dagens indtægter/udgifter (economy.today). Tests inkl. panel inden for 1024×600; import/test/smoke grønne → review
- 2026-10-15 – qa: ny test_hud_live.gd instansierer main.tscn med rigtig ParkSim: topbar viser omdømme-% og nu/max, park-panel viser tiltrækning, entré +/- virker. → done
