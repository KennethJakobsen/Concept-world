# T-058: Flere detaljer på modellerne

- **Status:** review
- **Milepæl:** M4
- **Agent:** graphics
- **Afhænger af:** –

## Mål
Brugerønske: flere detaljer på de procedurelle props i `game/scenes/props/`. Prioritet: forlystelser → butikker → personer → dekoration. Eksisterende node-navne/API'er (RideVisual, Wheel/Cab*, Top/Arm*, Ghost, LampVisual/Light, PersonAnim-dele Body/Head/Figure) og footprint bevares.

## Acceptkriterier
- [x] Forlystelser: indgangsportal/trappe, hegn/rækværk, skilte, lister, flere farvedetaljer, sæder/vogne, heste med ben/saddel/manke/hale, gondoler med tag
- [x] Butikker: stribet markise med kugle-kant, disk, serveringsluge, menutavle, kasseapparat, ikon-detaljer (salat/ost/sesam, kop-bånd, 2. kugle + kirsebær)
- [x] Personer: gæst maks 2 ekstra meshes (bukser + hår, 4 i alt); personale: arme, hænder, øjne, bukser + værktøjskasse/spand/forklæde/krave/ballon
- [x] Dekoration: bænk, skraldespand, lampe, træer
- [x] Kun primitive meshes + StandardMaterial3D (Compatibility/web), delte sub-resources, ingen nye shaders/assets
- [x] Test: `test_guest_mesh_budget` (loft 5) og `test_detail_keeps_api_nodes`; `test_no_stretched_meshes` dækker nu også guest/entrance
- [x] `tools/test.sh`, `tools/integration.sh`, smoke grønne
- [ ] Brugeren bekræfter visuelt

## Ejer / må ikke røre
Ejer: `game/scenes/props/*.tscn`, `game/tests/test_props.gd`. Må ikke røre simulation, audio, ui, bridge.

## Log
- 2026-10-15 – graphics: oprettet og udført. Detaljer tilføjet som nye noder/sub-resources (ingen eksisterende noder flyttet/omdøbt). Mesh-antal (før→efter): carousel 24→130, swing 20→116, ferris 24→81, bumper 24→77, go_karts 15→53, haunted 10→45, stande ~10→30-36, toilet 5→17, entrance 7→35, guest 2→4, staff 5→16-19, bænk 4→10, spand 2→7, lampe 3→8, træer +1-6. Meshes deles inden for hver scene (fx én saddel-mesh til alle heste). Tjekket med offscreen-rendering i Compatibility (opengl3) – taget-ribber, gondoltage og markise-striber flugter. test.sh 152/0, integration OK, smoke uden fejl. Afventer brugerens øjne (bemærk: forlystelserne har nu 50-130 draw calls hver; hvis web-performance bliver et problem, kan hegn/vimpler slås sammen til MultiMesh).
- 2026-10-15 – orkestrator: brugeren har godkendt visuelt/lyd. Status: done.
