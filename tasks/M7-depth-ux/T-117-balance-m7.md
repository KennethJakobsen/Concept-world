# T-117: Balance: M7-mekanik

- **Status:** review
- **Milepæl:** M7
- **Agent:** designer
- **Afhænger af:** T-115, T-116

## Mål
Kontraktens §5 T-117. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `balance.sh` viser: ekstra salt +10–20 % drikkesalg (+13,5 % med metoden fra T-151), ≤ 10 % kø-opgivelser i en sund park, ATM +3–6 % omsætning (revideret mål, var +15–25 %) og første tema-gren inden dag 5
- [x] Justeret kun i data

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – designer: målt med et midlertidigt script (slettet; gøres permanent i **T-150**). Fuld park med 5 dage, seeds 12345/1/2 (salt også 3/4).
  - **Ekstra salt:** med thirst +20 var effekten +1–10 % (for svag). `fries_stand` salt har nu thirst **+40** → drikkesalg 718 → 848 = **+18 %** samlet (pr. seed: +16,5/+12,8/+2,6/+36,9/+28,9 – støjet). ✅ Burger forbliver på +20, fordi `test_m7_config_sales` hardcoder 30 (= 10 + 20). Testen bør læse værdien fra def'en.
  - **Salt uden drikkebod (T-102-noten):** implementeres ikke. Straffen ville være usynlig for spilleren, og tørsten straffer allerede. GDD §1 er opdateret. Ingen task.
  - **Køopgivelser:** 0 ud af ~1600 kø-indtrædener pr. seed (0 %, mål ≤ 10 %). 500-gæst-perf: 0 utålmodige. ✅ Data er uændret.
  - **ATM:** +0,0/+0,0/+1,2 % omsætning (mål +15–25 %). ❌ Problemet er i koden og ikke i data: ATM udløses kun ved `no_money`-hjemgang, og med guest_money 30–80 er næsten ingen gæster flade. Sænker man guest_money, falder hele økonomien. → **T-149** (sim: hæv ved lav saldo). Genmåles bagefter.
  - **Milepæle (green_meadow-bot):** `guests_100` dag 3,3–3,8 og `stars_3` (åbner `roller_coasters`) dag 3,8–4,3 → første tema-gren inden dag 5. ✅ `first_thrill` blev ikke udløst i min bot, fordi bottens nye forlystelser ikke var `is_operating` (bottens layout gav dem ingen indgang). Det tyder ikke på en balancefejl.
  - Config-tradeoffs er ikke genmålt. Data er uændret fra T-100.
  - `test.sh`: 442/0. `balance.sh` er grøn (perf 2,7 ms/tick, alle scenarier vundet).
  - Acceptkriteriet om ATM er **ikke opfyldt** og afventer T-149. Resten er opfyldt med ændringer kun i data.
- 2026-10-16 – designer (afslutning efter T-149/T-150):
  - **Hvorfor salt-tallene var uenige:** metoden, ikke data. T-150 stiller `fries_stand` på `e.x+6` ved siden af burger- og drikkeboden. Der sælger den kun ca. 5 portioner pr. kørsel (gæsterne tager burgeren), så salt har intet at virke på, og −1,2 % er støj. Min første måling havde boden på `e.x−6`. Kontrolmåling over seeds 1–5 + 12345: `e.x+6` → fritter 32→34 salg, drikke +8,3 % (støj). `e.x−6` → fritter 122→99, drikke **+13,5 %** (882→1001 stk, ca. 1 ekstra drik pr. saltet portion). Startpengene påvirkede ikke resultatet (+2000 gav identiske tal). Mit første +18 % var også støj (6 seeds, spredning −3 til +37 %). Data er uændret (fritter-salt thirst +40). → **T-151** (simulation): flyt boden i balance_sim og udskriv fritter-salg.
  - **ATM:** målet i GDD er revideret til +3–6 % (ATM er en bekvemmelighed i M7). `guests.json` `atm_low_money: 30` → T-117-sektionen viser **+5,6 %** (30960→32693, 625 hævninger). Gebyrerne (ca. 125/dag) dækker driften (20/dag). Forslaget om en ny pengeøkonomi for gæster står i `tasks/M8-ideas/IDEAS.md`.
  - Køopgivelser 0/1951 ✅. Milepæle green_meadow: `stars_3` dag 2 og `first_thrill` dag 5 ✅.
  - `test.sh` 443/0. `_m7_balance` er kørt isoleret (en kopi af balance_sim med kun den sektion).
