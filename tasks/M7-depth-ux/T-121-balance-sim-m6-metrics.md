# T-121: balance_sim måler M6 (opkast, sideshow-margin, impulskøb)

- **Status:** todo
- **Milepæl:** M7
- **Agent:** simulation (game/tools/balance_sim.gd)
- **Afhænger af:** T-095, T-119

## Mål
`balance.sh` dækker ikke M6-mekanikken. T-095 målte opkast og sideshow-margin med et midlertidigt script, og scenarie-botten bygger hverken ballon- eller souvenirbod, så impulskøb (T-119) bliver ikke målt.

## Acceptkriterier
- [ ] balance_sim udskriver pr. scenarie/seed: opkast i alt og opkastets andel af affaldet (mål < 15 %)
- [ ] balance_sim udskriver netto-margin pr. sideshow (indtægt − drift − præmier)
- [ ] Scenarie-botten bygger en ballonbod og en souvenirbutik, når de er låst op, og besøgstallet udskrives
- [ ] balance.sh er stadig 5/5 i alle scenarier (eller afvigelser er dokumenteret)

## Log
- 2026-10-16 – qa (T-096): oprettet som opfølgning på T-095-fundet
- 2026-10-16 – orkestrator: flyttet til M7 (før T-117).
