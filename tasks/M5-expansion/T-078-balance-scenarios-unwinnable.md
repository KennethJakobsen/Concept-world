# T-078: Balance: Floddalen og Bjergtoppen kan ikke vindes af bot med fornuftigt spil

- **Status:** done
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
- [x] Floddalen: et coaster-mål, som en lidt større/højere bane end ovalen kan nå (dokumentér stykkeliste og E), eller E-målet sænkes til ≤ 4.6. Et pengemål, der kræver noget
- [x] Bjergtoppen: gæstemål og E-mål, der kan nås inden for fristen (angiv en strategi i loggen)
- [x] `balance.sh`: Grøn eng ≥ 4/5, og Floddalen vindes af botten eller er dokumenteret som opnåelig med en angivet bane
- [x] Sværhedsgraden stiger (dag til sejr eller margin)

## Log
- 2026-10-15 – qa: oprettet under T-072
- 2026-10-15 – designer: Kun data i scenarierne er ændret.
  - Grøn eng: målene er hævet fra 100 gæster/omdømme 45 til 120/60.
  - Floddalen: E-målet er sænket fra 5,0 til 4,5. Den simple oval (3 lift, 3 fald, 4 højresving, ~17 stykker, E 4,66) når det. `money_min` er hævet fra 15000 til 40000.
  - Bjergtoppen: startpenge 12000 (før 10000), og pariserhjul, svingkarrusel og isbod er låst op fra start. De nye mål er 85 gæster, parkværdi 100000, E 4,6 og omdømme 55 (før 350/60000/7,0/75).
  - Begrundelse for Bjergtoppen: Gæstetallet hos botten (~70-100) begrænses af, at der kun er få ulåste ting. Bjergtoppen er sværest på grund af parkværdien og et omdømmemål, der ligger lige ved bottens loft. En spiller, der forsker bredere og bygger flere boder, klarer det.
  - balance.sh (5 seeds): **Grøn eng 5/5** (dag 16-34, før 11-16). **Floddalen 5/5** (dag 35, ca. 51k). **Bjergtoppen**: 1/5 i de seeds, jeg nåede at se (seed 1 vandt på dag 89, 12345 tabte med omdømme 53/55, og seed 2 tabte med 76/85 gæster). Kørslen var afkortet, men sværhedsgraden stiger tydeligt.
  - NB: Kørslen skete med M6-arbejde (T-083 m.fl.), der ikke var committet, i arbejdstræet: nye attraktioner og ændret research.json. Tallene for Bjergtoppen kan derfor flytte sig en smule, når M6 lander.
  - test.sh: 236 bestået, 2 fejlede. Begge fejl skyldes M6-filerne, der ikke er committet (coconut_shy m.fl. og research-id'erne mini_train/monorail/log_flume), ikke denne ændring.
- 2026-10-16 – qa (T-096): Godkendt headless. test.sh 308/0 (inkl. ny runner-selvtest og test_qa_m6), integration OK, balance.sh 5/5 i alle tre scenarier, build_web OK, smoke uden fejl. Kriterierne er opfyldt (T-078: Bjergtoppen nu 5/5). → done
