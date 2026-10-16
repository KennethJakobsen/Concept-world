# T-121: balance_sim måler M6 (opkast, sideshow-margin, impulskøb)

- **Status:** done
- **Milepæl:** M7
- **Agent:** simulation (game/tools/balance_sim.gd)
- **Afhænger af:** T-095, T-119

## Mål
`balance.sh` dækker ikke M6-mekanikken. T-095 målte opkast og sideshow-margin med et midlertidigt script, og scenarie-botten bygger hverken ballon- eller souvenirbod, så impulskøb (T-119) bliver ikke målt.

## Acceptkriterier
- [x] balance_sim udskriver pr. scenarie/seed: opkast i alt og opkastets andel af affaldet (mål < 15 %)
- [x] balance_sim udskriver netto-margin pr. sideshow (indtægt − drift − præmier)
- [x] Scenarie-botten bygger en ballonbod og en souvenirbutik, når de er låst op, og besøgstallet udskrives
- [x] balance.sh er stadig 5/5 i alle scenarier (eller afvigelser er dokumenteret)

## Log
- 2026-10-16 – qa (T-096): oprettet som opfølgning på T-095-fundet
- 2026-10-16 – orkestrator: flyttet til M7 (før T-117).
- 2026-10-16 – simulation: udført (kun game/tools/balance_sim.gd).
  - `_m6_report` efter hver `_run`, hver scenarie-bot-seed og den nye M6-park: opkast i alt (signal `guest_vomited`), stående opkast/affald i % (markeres med "OVER MÅL", hvis ≥ 15 %), netto pr. sideshow (indtægt − drift·dage siden bygning − præmier) og besøg/indtægt for ballonbod og souvenirbutik.
  - Scenarie-botten bygger balloon_stand/souvenir_shop, når de er låst op, og skifter forskningsprioritet til shops og derefter sideshows, når banen står. Afvigelse: i alle tre scenarier vinder botten (dag 15–84), før butikkerne er forsket frem (forskningsniveau 1, og banestykker prioriteres). Der står derfor "ingen bygget", og scenarie-resultaterne er uændrede.
  - Derfor er der ny `_m6_park` (sandbox, startpark + is + 4 sideshows + ballon + souvenir, mekaniker/rengøring, 5 dage, seeds 12345/1/2): sideshow-netto +62..+254 (alle positive), ballon 159–169 besøg, souvenir 103–118 besøg, opkast 0 (ingen intense forlystelser i layoutet).
  - balance.sh: Grøn eng 5/5, Floddalen 5/5, Bjergtoppen 5/5. Opkast i scenarier 0–1, 0 % af stående affald.
  - test.sh 329/2. De 2 fejl er atm.json/atm-node (`test_real_content_parses`, `test_build_all_m6_buildings`) fra en parallel content-task, ikke fra denne ændring.
- 2026-10-16 – qa: verificeret (test.sh 446/446, integration, balance 5/5 scenarier vundet, web-build, smoke, v1/v2/v3→v4 i test_qa_m7). review → done.
