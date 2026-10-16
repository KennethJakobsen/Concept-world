# T-151: balance_sim: salt-målingen bruger en Fritterbix, der næsten ikke sælger

- **Status:** done
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-150

## Mål
I `_m7_balance` står `fries_stand` på `e.x + 6`, lige ved siden af burger- og drikkeboden. Der sælger den kun ca. 5 portioner pr. kørsel, fordi gæsterne vælger burgeren. Salt kan derfor ikke påvirke noget, og de −1,2 % er støj. Målt af T-117 over seeds 1–5 + 12345:
- `e.x + 6`: fritter 32 → 34 salg, drikke +8,3 % (støj)
- `e.x - 6`: fritter 122 → 99 salg, drikke **+13,5 %** (882 → 1001 drikke)

Ret: flyt boden til `Vector2i(e.x - 6, 49)`, brug seeds `[1, 2, 3, 4, 5, 12345]`, og udskriv også antal Fritterbix-salg, så det kan ses, at målingen har signal.

## Acceptkriterier
- [x] Salt-linjen viser fritter-salg og drikkesalg ≈ +10–20 %
- [x] balance.sh er grøn

## Log
- 2026-10-16 – designer: oprettet fra T-117
- 2026-10-16 – simulation: `_m7_balance` flytter Fritterbixen til `(e.x - 6, 49)`, bruger seeds [1, 2, 3, 4, 5, 12345] og tæller fritter-salg via `purchase_made`. Resultat: fritter 122 → 99 solgt, drikkesalg 2646 → 3003 (+13,5 %), som designeren målte. Tests 443/443, balance.sh grøn.
- 2026-10-16 – qa: verificeret (test.sh 446/446, integration, balance 5/5 scenarier vundet, web-build, smoke, v1/v2/v3→v4 i test_qa_m7). review → done.
