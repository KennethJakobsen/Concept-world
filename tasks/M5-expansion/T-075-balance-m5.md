# T-075: Balance M5 – rutsjebane-ratings og scenarier

- **Status:** review
- **Milepæl:** M5
- **Agent:** designer
- **Afhænger af:** T-067, T-068

## Mål
Rutsjebane-ratings i et fornuftigt spænd, start-stier i scenarierne der hænger sammen, og forskning/scenarier der kan vindes, med sværhedsgrad der stiger. Kun data.

## Acceptkriterier
- [x] Simpel oval: E 4–5, I 3–5, N 2–3
- [x] `sick_happiness_penalty` (10) i ratings.json
- [x] Karrusellens indgang er forbundet til start-stien i Grøn eng og Floddalen
- [x] Forskningspriser, startpenge og mål justeret, stigende sværhedsgrad
- [x] test.sh og balance.sh er kørt, og resultaterne står i loggen

## Log
- 2026-10-15 – designer: oprettet og startet.
- 2026-10-15 – designer: færdig.
  - trains.json: `curve_radius` 4,0 og `transition_len` 3,0 (oval: max_g 5,93 → 2,64, max_lat 11,8 → 1,48). ratings.json: vægtene er sænket (E speed 0,15/g 0,4/lat 0,3; I speed 0,15/g 0,8/lat 1,0; N lat 0,8/g 0,5), og `sick_happiness_penalty` 10 er tilføjet. **Oval: E 4,66 / I 4,67 / N 2,50.**
  - Forskning: `cost_per_level` 500/1000/2000 → 150/300/600 pr. dag.
  - Grøn eng: sti (25,45) er tilføjet, og pariserhjul, svingkarrusel og isbod er låst op fra start. Målene er 100 gæster og omdømme 45 (før 150/60).
  - Floddalen: sti (33,61) er tilføjet, og pariserhjul er låst op fra start. `money_min` er 15000 (før 20000).
  - Bjergtoppen: startpenge 10000 (før 8000), og `money_below` er -4000 i 4 dage (før -3000/3). Det er fortsat det sværeste scenarie.
  - test.sh: 218 bestået, 0 fejlede.
  - balance.sh (botten, forskning 0): Grøn eng taber på fristen (55/100 gæster, omdømme 32,8, 21066 kr.). Floddalen taber på fristen (pengemålet er nået med 36863 kr., men der er 4/5 forlystelser og ingen rutsjebane). Bjergtoppen går fallit på dag 59 (før: dag 57, 354 kr. i Floddalen og 11039 kr. i Grøn eng). Botten er stadig ikke i stand til at vinde, fordi den hverken ansætter personale (omdømmet falder af skrald og nedbrud), forsker eller bygger rutsjebaner. Coaster-målene kan altså ikke nås af botten. Det kræver en bedre bot i `tools/` (uden for designerens område), hvis det skal verificeres automatisk.
- 2026-10-15 – qa (T-072): Sendt tilbage. Med den nye bot (personale, forskning niv. 1, oval) vindes Grøn eng 5/5, men Floddalen og Bjergtoppen vindes 0/5. Floddalen: ovalen giver E 4.66, mens målet er 5.0. Bjergtoppen: der er ~80-108 gæster, og målet er 350. Se T-078 for tal.
- 2026-10-15 – designer: Scenariemålene er rebalanceret under T-078. Botten vinder nu Grøn eng 5/5, Floddalen 5/5 og Bjergtoppen ~1/5. Se T-078.
