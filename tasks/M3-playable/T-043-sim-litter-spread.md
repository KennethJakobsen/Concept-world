# T-043: Simulation – Affald spredes langs gæstens rute

- **Status:** done
- **Milepæl:** M3
- **Agent:** simulation
- **Afhænger af:** T-037

## Mål
Affald lægges i dag kun på bodens indgangscelle (loft 5), så parken aldrig bliver rigtig beskidt. Gæsten skal i stedet "bære" sin vare og smide affaldet et tilfældigt sted på de næste N sti-celler (eller i en skraldespand inden for rækkevidde), jf. GDD (~50 affald/dag i startpark uden spande). Broken rides skal ikke tælle i attraction_score (gæster ved det godt) – men behold dem i max_guests.

## Acceptkriterier
- [x] Tests: affald spredes over flere celler; skraldespand opsamler; save-roundtrip med båret affald
- [x] balance.sh: startpark uden rengøring bliver tydeligt beskidt over 5 dage
## Log
- 2026-10-15 – architect: oprettet efter simulations note
- 2026-10-15 – simulation: startet
- 2026-10-15 – simulation: Efter bod-køb får gæsten `Guest.litter_steps_left` = rng 1..`litter_carry_cells` (ny Balance-default 8, valgfri nøgle i staff_rules.json – til designer). Tælles ned for hver sti-celle gæsten træder ind på; ved 0 smides affaldet på den celle: skraldespand med plads inden for bin_radius → spanden (med litter_chance_with_bin alligevel på jorden), ellers på jorden med litter_chance_after_shop. Forlader gæsten parken før, forsvinder affaldet. `attraction_score()` springer ødelagte forlystelser over; `current_max_guests()` er uændret. Save: `litter_steps_left` (default 0). API kun tilføjelser.
- 2026-10-15 – simulation: Tests: test_litter_spread.gd (4): spredning over ≥ 4 celler og > 5 i alt, spand opsamler båret affald, save-roundtrip med båret affald + 1000 ticks determinisme, ødelagt forlystelse ude af score men i max_guests. 100/100 grøn.
- 2026-10-15 – simulation: balance.sh, startpark uden personale, affald ved dagsslut: **før** 5/10/10/10/10 (loft på indgangsceller) → **efter** 5/36/54/62/65; glæde 80→84→81→81→77. Med rengøring + 2 spande: affald 0 alle dage, glæde 80–85. (Kørslen havde tilfældigvis ingen nedbrud i startparken.)
- 2026-10-15 – qa: godkendt (T-041): test.sh 116/116, integration.sh grøn, smoke main_menu+main 300 frames uden ERROR/WARNING, web-build ok. → done
