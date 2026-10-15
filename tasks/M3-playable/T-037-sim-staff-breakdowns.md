# T-037: Simulation – Personale, nedbrud, affald, dekoration

- **Status:** review
- **Milepæl:** M3
- **Agent:** simulation
- **Afhænger af:** T-035, T-036

## Mål
Implementér personale (mekaniker, rengøring, entertainer), nedbrud/reparation, affald og dekorationer inkl. bænke og skraldespande. Alt nyt state skal med i save (opdater to_save/from_save + tests). Se `_CONTRACT.md`.

## Acceptkriterier
- [x] Tests for hver mekanik (nedbrud→reparation af mekaniker, affald→fejet, bænk sænker træthed, skraldespand mindsker affald, entertainer øger glæde)
- [x] Lønninger trækkes dagligt (kategori "wages")
- [x] Save-round-trip inkluderer alt nyt
- [x] balance.sh scenarie med personale
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: startet (T-035 på review).
- 2026-10-15 – simulation: Implementeret efter kontrakt + GDD/staff_rules.json.
  - Nye klasser: StaffDef, Staff, StaffAI (statisk, ingen ref-cykler), DecorDef, Decor. Balance læser staff_rules.json (4. arg. i from_dicts).
  - Personale: cmd_hire_staff/cmd_fire_staff/cmd_move_staff, ParkSim.staff, signaler staff_hired/staff_fired; går på stier med def.speed; work_radius (manhattan fra home_cell = ansættelses-/flyttecelle; 0 = hele parken). Løn trækkes ved dagsskift (kategori "wages").
  - Mekaniker: nærmeste (rute-længde) ikke-reparerende mekaniker tildeles hver ødelagt forlystelse (Attraction.mechanic_id), reparerer repair_ticks; inspicerer ellers hver mechanic_inspect_interval_ticks den forlystelse der længst ikke er inspiceret (+inspection_reliability_bonus, total ≤ 1, nulstilles ved nedbrud).
  - Nedbrud: efter hver tur rng.randf() ≥ reliability+bonus → broken. Ryttere færdiggøres, kø opløses (billet refunderes, tanke "Den er i stykker!"), attraction_broken/attraction_repaired. Attraction.status (OPERATING/BROKEN/CLOSED) + effective_reliability(). AttractionDef.reliability (default 1.0) / repair_ticks.
  - Affald: ParkWorld.litter (celle→antal), litter_changed-signal, get_litter/set_litter/total_litter. Efter bod-køb: skraldespand med plads inden for bin_radius → spanden fyldes, ellers affald på cellen med litter_chance_after_shop (med spand: litter_chance_with_bin). Beskidt sti (≥ dirty_threshold): −glæde/tick + "Her er beskidt!". Rengøring: tømmer fulde spande først, fejer ellers nærmeste affald i radius.
  - Dekoration: cmd_place_decor/cmd_remove_decor (50 % refusion), decor_placed/decor_removed, can_place_decor. on_path → sti-celle (én pr. celle; fjernes sammen med stien), ellers græs → ny Tile.DECOR (blokerer sti/bygning). Aura: Σ happiness_aura × aura_scale pr. celle inden for aura_radius (manhattan), loft decor_aura_max_per_tick. Bænk: gæst med energy ≥ bench_seek_energy går til nærmeste bænk → Guest.State.RESTING i bench_rest_ticks → energy += bench_energy_restore.
  - Underholder: patruljerer tilfældigt (seedet RNG) inden for radius; gæster inden for work_radius får +entertainer_happiness_per_tick.
  - Save: staff, decor, litter, Attraction.broken/bonus/mechanic_id/last_inspect_tick, Guest.target_decor_id/rest_ticks_left, next ids – bagudkompatibelt (save_version stadig 1, manglende nøgler → defaults). from_save(d, balance, p_defs=[]) kan forhåndsregistrere defs.
  - get_stats(): + staff, broken, litter.
- 2026-10-15 – simulation: Tests: test_staff_decor.gd (13): nedbrud→reparation, kø opløses med tanke, inspektion, affald→fejet, skraldespand mindsker affald, fuld spand tømmes, beskidt sti, bænk sænker træthed, underholder, aura-loft, decor-regler, ansæt/fyr/flyt/løn, save-roundtrip + 2000 ticks determinisme med alt nyt. 96/96 grøn.
- 2026-10-15 – simulation: balance.sh – nye scenarier. Startpark uden personale: karrusel bryder ned dag 2 og forbliver i stykker → netto ≈ 0/dag, glæde 86→70. Startpark + mekaniker + rengøring + 2 spande: netto −1667/+469/+484/+625/+609, glæde 80–87, ingen ødelagte forlystelser ved dagsslut, affald ≈ 0 → break-even (penge ≥ start 2200) dag 5, designeren beregnede dag 4.
- 2026-10-15 – simulation: Noter til designer/UI/gameplay: (1) Affald lægges på bodens indgangscelle og loftes ved litter_max_per_cell, så affald pr. dag mættes ved ~5 pr. bod – evt. sprede affald over de næste celler gæsten går (kan tilføjes). (2) Ødelagte forlystelser tæller stadig i attraction_score/max_guests (midlertidig tilstand). (3) Bridge: nye signaler (staff_hired/fired, decor_placed/removed, attraction_broken/repaired, world.litter_changed), Guest.State.RESTING (synlig), Tile.DECOR (græs-dekoration) – park_view.gd er ikke ændret.
