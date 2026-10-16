# T-107: Grafik: skrald, spande, bænke, ATM, køsti, svævetal og gæstemængde

- **Status:** review
- **Milepæl:** M7
- **Agent:** graphics
- **Afhænger af:** T-096, T-098

## Mål
Kontraktens §2 T-107. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] Skrald-props med deterministisk placering, spandens fyldniveau, siddende gæst, ATM-prop og køsti-mesh
- [x] `FloatingText3D` og `GuestCrowdRenderer` (MultiMesh + LOD, ≤ 120 individuelle visuals)
- [x] Visuel separation i baner pr. celle (ADR-005 §1)
- [x] Compatibility-screenshots. Bliver på review indtil brugeren har set dem

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – graphics: implementeret. `scenes/props/atm.tscn` (+ thumb `assets/ui/thumbs/atm.png`), `scripts/rendering/m7/`: `QueuePathVisual`, `GuestCrowdRenderer`, `FloatingText3D`, `LitterScatter`, `AmenityVisuals`; showcase `scenes/rendering/m7_showcase.tscn`; tests `tests/test_render_m7.gd` (6). Alle tests grønne (342), smoke ok. Screenshots: `docs/screenshots/t107_overview.png`, `t107_queue_close.png`, `t107_crowd.png` (Compatibility). Venter på brugerens øjne.

## API til gameplay (T-111)
- `QueuePathVisual.new()`; `set_connections(mask)` (N=1,E=2,S=4,W=8; forbundne sider er åbne, øvrige får messingstolper + rød kæde). `QueuePathVisual.mask_from(cell, is_connected: Callable)` – forbind til QUEUE-naboer i kæden og til attraktionsindgang/PATH-cellen ved køens ende.
- `GuestCrowdRenderer.new()`; `update(entries: Array[{id, pos: Vector3, color}], cam_pos) -> PackedInt32Array` = id'er (≤120, < 18 m), som skal være individuelle `GuestVisual`-noder; resten tegnes som MultiMesh i 3 LOD (skjult > 90 m). `lane_offset(id)` / `separate(pos, dir, id)` giver ADR-005 §1-baner (6 baner, ±0,3) – brug også på individuelle visuals.
- `FloatingText3D.new()`; `show_amount(pos, amount, color := grøn)` (pool 32, skjules > 40 m fra kamera).
- `LitterScatter.new()`; sæt `cell`, kald `set_items(sim.litter_at(cell))` ved `litter_changed` (kinds: wrapper/cup/can/food/vomit; visibility_range 40 m).
- `AmenityVisuals.set_bin_level(bin_node, level)` ved `bin_state_changed` (0/1/2; fuld = rødt ikon). `AmenityVisuals.bench_seat_position(seat)` (lokal ift. bænk) + `set_guest_seated(guest, on)` ved `guest_sat`/`guest_stood`.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
