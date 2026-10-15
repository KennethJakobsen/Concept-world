# T-043: Simulation – Affald spredes langs gæstens rute

- **Status:** todo
- **Milepæl:** M3
- **Agent:** simulation
- **Afhænger af:** T-037

## Mål
Affald lægges i dag kun på bodens indgangscelle (loft 5), så parken aldrig bliver rigtig beskidt. Gæsten skal i stedet "bære" sin vare og smide affaldet et tilfældigt sted på de næste N sti-celler (eller i en skraldespand inden for rækkevidde), jf. GDD (~50 affald/dag i startpark uden spande). Broken rides skal ikke tælle i attraction_score (gæster ved det godt) – men behold dem i max_guests.

## Acceptkriterier
- [ ] Tests: affald spredes over flere celler; skraldespand opsamler; save-roundtrip med båret affald
- [ ] balance.sh: startpark uden rengøring bliver tydeligt beskidt over 5 dage
## Log
- 2026-10-15 – architect: oprettet efter simulations note
