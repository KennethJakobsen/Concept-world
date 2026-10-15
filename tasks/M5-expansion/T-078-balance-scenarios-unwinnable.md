# T-078: Balance: Floddalen og Bjergtoppen kan ikke vindes af bot med fornuftigt spil

- **Status:** todo
- **Milepæl:** M5
- **Agent:** designer
- **Afhænger af:** T-075, T-072

## Mål
Justér data (`game/content/scenarios/`, evt. `coaster/ratings.json`/`research.json`), så Floddalen og Bjergtoppen kan vindes med fornuftigt spil, og så sværhedsgraden stiger fra Grøn eng over Floddalen til Bjergtoppen.

## Tal (balance.sh, T-072-bot, 5 seeds: 12345/1/2/3/4)
Botten ansætter mekaniker og rengøring, sætter 2 skraldespande, forsker på niveau 1 med prioritet `roller_coasters`, bygger den simple oval (3 lift, 3 fald, 4 højresving, ~17 stykker), så snart stykkerne er låst op, og bygger den billigste ulåste forlystelse/bod hver dag, så længe der er en reserve på 2000.
- **Grøn eng:** 5/5 vundet på dag 11-16 (101-123 gæster, omdømme ~75). Det er let.
- **Floddalen:** 0/5. Den taber på fristen (dag 60). Ovalen er først låst op på dag 34 med forskning på niveau 1, og dens excitement er 4.66, mens målet er 5.0. Rides 5/5 ok, og pengene er ~100.000 (mål 15.000). Pengemålet er alt for let. Coaster-målet kræver altså mere end den "typiske" oval, som T-075 selv satte til E 4-5.
- **Bjergtoppen:** 0/5. Den taber på fristen (dag 90). Der er 65-108 gæster (mål 350) og omdømme 63-67 (mål 75), og E er 4.66 (mål 7.0). Parkværdien er ~94.000 og dermed ok (mål 60.000). Med seed 2 bygger botten kun 1 forlystelse og ender med 121 kr. Der er kun få ting låst op fra start, så gæstetallet når ikke i nærheden af 350.

## Acceptkriterier
- [ ] Floddalen: et coaster-mål, som en lidt større/højere bane end ovalen kan nå (dokumentér stykkeliste og E), eller E-målet sænkes til ≤ 4.6. Et pengemål, der kræver noget
- [ ] Bjergtoppen: gæstemål og E-mål, der kan nås inden for fristen (angiv en strategi i loggen)
- [ ] `balance.sh`: Grøn eng ≥ 4/5, og Floddalen vindes af botten eller er dokumenteret som opnåelig med en angivet bane
- [ ] Sværhedsgraden stiger (dag til sejr eller margin)

## Log
- 2026-10-15 – qa: oprettet under T-072
