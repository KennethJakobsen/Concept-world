# T-097: Design: GDD-afsnit for M7

- **Status:** in-progress
- **Milepæl:** M7
- **Agent:** designer
- **Afhænger af:** –

## Mål
Skriv M7-afsnittet i `docs/gdd.md` med mekanikker, tal og dataformat for:
1. Konfiguration pr. forlystelse (kapacitet pr. tur, turlængde, evt. hastighed) og pr. butik (opskrift, f.eks. salt i pommes → tørst; pris med adfærdseffekt, f.eks. for billig is → overspisning/kvalme).
2. Synlige salg: "+kr" over butikken, blink i HUD, omsætning i dag og i alt i info-panelet (bogføring findes allerede).
3. Synligt skrald + skraldespande og bænke (evt. lamper).
4. UX-redesign: principper og informationsarkitektur, der erstatter tekstmenuer; fortryd, flyt/rotér, sælg med refusion, tooltips, kort-overlay (glæde/skrald/kø), UI-skalering, farveblind-tilstand. Tutorial til sidst.
5. Baggrund uden for parken og mur rundt om området.
6. Køstier, som spilleren bygger; kø-kapacitet, tålmodighed og opgivelse.
7. Gæster med masse (ingen gennemgang af hinanden).
8. Toiletter/butikker: vælg ledig frem for optaget.
9. Gæster går mod udgangen, når de er trætte eller uden penge; hæveautomat.
10. Milepæle (f.eks. 100 gæster, 3★, første rutsjebane), der låser forskningsgrene op oven på den eksisterende forskning.

Udskudt til M8: personale-løn/træthed/områder, lån/regnskab/reklame, terræn, gæstegrupper.

## Acceptkriterier
- [ ] M7-afsnit i `docs/gdd.md` dækker punkt 1–10 med tal og foreslåede JSON-felter
- [ ] Åbne spørgsmål til architect er listet

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens ønsker
