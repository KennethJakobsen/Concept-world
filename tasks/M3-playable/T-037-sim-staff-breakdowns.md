# T-037: Simulation – Personale, nedbrud, affald, dekoration

- **Status:** todo
- **Milepæl:** M3
- **Agent:** simulation
- **Afhænger af:** T-035, T-036

## Mål
Implementér personale (mekaniker, rengøring, entertainer), nedbrud/reparation, affald og dekorationer inkl. bænke og skraldespande. Alt nyt state skal med i save (opdater to_save/from_save + tests). Se `_CONTRACT.md`.

## Acceptkriterier
- [ ] Tests for hver mekanik (nedbrud→reparation af mekaniker, affald→fejet, bænk sænker træthed, skraldespand mindsker affald, entertainer øger glæde)
- [ ] Lønninger trækkes dagligt (kategori "wages")
- [ ] Save-round-trip inkluderer alt nyt
- [ ] balance.sh scenarie med personale
## Log
- 2026-10-15 – architect: oprettet
