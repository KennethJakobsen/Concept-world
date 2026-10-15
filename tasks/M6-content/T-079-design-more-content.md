# T-079: Forslag til flere forlystelser, butikker og sideshows

- **Status:** done
- **Milepæl:** M6 (flyttet fra M5)
- **Agent:** designer
- **Afhænger af:** –

## Mål
Brugeren vil have flere forlystelser og butikker med inspiration fra Theme Park (1994). Kun et forslag. Tal og data implementeres i senere tasks.

## Acceptkriterier
- [x] 8–10 forlystelser og 6–8 butikker/sideshows med egne danske navne
- [x] Hvert forslag har id, type, footprint, pris, kapacitet, excitement/behov, forskning, tema-element og implementeringstype
- [x] Ny mekanik er identificeret og anbefalet prioriteret
- [x] Afsnit i `docs/gdd.md`. Ingen filer i `game/content/` er ændret (T-078 kører parallelt)

## Forslag
Inspiration: Bullfrog's Theme Park (1994) havde bl.a. hoppeborg, kopkarrusel, minitog, rumringe, piratskib, raket, trampolin, vandrutsjebane, monorail samt boder (burger, cola, pommes frites, kaffe, balloner, souvenir, spøg og skæmt) og sideshows (kokosnødder, skydetelt, fang-en-and, stærk mand). Vi låner kun *genrerne*. Navne, modeller og tal er vores egne.

**Sim-status i dag:** attraktioner har `kind` (ride/shop/toilet), `excitement` og `satisfies` (hunger/thirst/toilet/energy). Der findes ingen `intensity`- eller `nausea`-felter. Derfor er de I/N-værdier, der står nedenfor, *forslag til et fremtidigt felt* (se "Ny mekanik B"). Indtil det felt findes, bruges kun excitement.

Typekoder: **D** = data plus en prop (eksisterende sim). **A–E** = kræver ny mekanik (se nederst).

### Forlystelser
| id | Navn | Type | Fod | Byg | Kap. | Billet | Exc / I / N | Forskning | Tema-element | Impl. |
|---|---|---|---|---|---|---|---|---|---|---|
| bouncy_castle | Hoppeborgen | ride | 2×2 | 400 | 10 | 3 | 20 / 10 / 5 | start (billig børneforlystelse) | Oppustet borg med kæmpe gummiand på tårnet | D |
| teacups | Tekopperne | ride | 3×3 | 900 | 12 | 4 | 28 / 25 / 35 | gentle_rides, 100 | Kæmpe tekande i midten, låget løfter sig | D |
| mini_train | Bimmelbanen | ride (sporbaseret) | station 3×1 + spor | 1200 + 20/felt | 16 | 4 | 25 / 5 / 0 | gentle_rides, 160 | Lokomotiv med overdreven skorsten og røgsky | B: genbrug coaster-spor (ADR-003) med flad profil. Kan tages som D med en fast rundtur på 4×4 |
| sky_rings | Himmelringene | ride | 2×2 | 1400 | 2 | 7 | 45 / 70 / 60 | thrill_rides, 220 | Gyroskop-ringe under en kæmpe planet med ring | D |
| pirate_ship | Gyngeskibet | ride | 4×2 | 1600 | 20 | 6 | 45 / 50 / 45 | thrill_rides, 200 | Dødningehoved-flag og kæmpe blæksprutte, der holder om masten | D |
| trampoline | Springfjedrene | ride | 2×2 | 600 | 6 | 3 | 22 / 30 / 15 | gentle_rides, 80 | Kæmpe spiralfjeder som indgangsbue | D |
| space_rocket | Månefærgen | ride | 3×3 | 2200 | 12 | 8 | 55 / 60 / 40 | thrill_rides, 280 | Høj tegneserieraket med flammer af plaster-kegler | D |
| log_flume | Tømmerrenden | ride, vandbane | station 3×2 + rende | 2800 + 40/felt | 8 | 8 | 60 / 40 / 10 | ny topic water_rides, 300 | Kæmpe træstamme med økse ved stationen | A (vandbane), afhænger af spor-systemet |
| drop_tower | Faldtårnet | ride | 2×2 | 3000 | 12 | 9 | 65 / 85 / 30 | thrill_rides, 350 | Tårnet er en kæmpe termometer-stang med "kogepunkt" på toppen | D |
| monorail | Svævebanen | transport | station 2×2 ×2 + bane | 2500 | 20 | 2 | 15 / 0 / 0 | gentle_rides, 300 | Stationer formet som kæmpe tandhjul | C (transport mellem to punkter) |

### Butikker og sideshows
| id | Navn | Type | Fod | Byg | Kap. | Pris | Dækker | Forskning | Tema-element | Impl. |
|---|---|---|---|---|---|---|---|---|---|---|
| fries_stand | Fritterbixen | shop | 1×1 | 260 | 2 | 3 | hunger -50, thirst +15 | shops, 60 | Kæmpe pommes frites-bæger | D |
| coffee_stand | Kaffekoppen | shop | 1×1 | 300 | 2 | 3 | thirst -40, energy -20 | shops, 120 | Bod i en kæmpe dampende kop | D (energy findes allerede i satisfies) |
| balloon_stand | Ballonbåsen | shop | 1×1 | 220 | 2 | 2 | glæde. Gæsten bærer ballon | shops, 100 | Klase af kæmpe balloner | E (vare/glæde-effekt). D-light: kun excitement 10 |
| souvenir_shop | Mindebutikken | shop | 2×1 | 500 | 3 | 5 | glæde. Gæsten bærer souvenir | shops, 200 | Kæmpe snekugle med parken i | E. D-light som ovenfor |
| coconut_shy | Kokoskasteriet | sideshow | 2×1 | 350 | 3 | 2 | glæde, præmie med 25 % chance | ny topic sideshows, 80 | Tre kæmpe kokosnødder på pinde | D (gevinst = excitement). Præmier = D (ny mekanik) |
| shooting_gallery | Skydeteltet | sideshow | 2×1 | 450 | 3 | 3 | glæde, præmie 20 % | sideshows, 140 | Stribet telt med kæmpe blikand på taget | D/D som ovenfor |
| hook_a_duck | Andefiskeriet | sideshow | 1×1 | 250 | 2 | 2 | glæde, præmie 50 % (lav værdi) | sideshows, 60 | Kæmpe gul and med fiskestang | D/D som ovenfor |
| strength_tester | Kraftklokken | sideshow | 1×1 | 300 | 1 | 2 | glæde, energy +5 | sideshows, 120 | Høj skala med kæmpe klokke og hammer | D/D som ovenfor |

### Ny mekanik (kræver sim-tasks)
- **A – Vandbane:** spor med vand-segmenter (lav friktion og plask-sektion), giver thirst -10 og en "våd"-tilstand. Bygger på coaster-sporet fra ADR-003. Størst opgave.
- **B – Intensity/nausea:** to nye felter (default 0), en gæstetolerance pr. gæst og et kvalmebehov, der giver opkast (affald) og glædetab. Uden dette ligner forlystelserne hinanden for meget. Det kræver også, at save-formatet migreres (felt-defaults).
- **C – Transport:** to stationer, og gæsten bruger forbindelsen som sti i pathfinding. Kan udskydes.
- **D – Sideshow-præmier:** `kind: "sideshow"` plus `win_chance`, `prize_cost` og `prize_happiness`. Parkens udgift pr. gevinst giver en lille risiko i økonomien, og gæsten bærer en synlig præmie.
- **E – Varer, der bæres:** ballon og souvenir er en tilstand på gæsten med glæde-aura. Ballonen kan flyve væk.

### Anbefaling
1. **Data-only nu (én designer-task + én graphics-task til props):** Hoppeborgen, Tekopperne, Springfjedrene, Himmelringene, Gyngeskibet, Månefærgen, Faldtårnet, Fritterbixen og Kaffekoppen. Ballonbåsen, Mindebutikken og de fire sideshows kan også tages med som "D-light" (`kind: ride`/`shop` med excitement-glæde) for at få bredden hurtigt.
2. **Næste sim-runde:** B (intensity/nausea) først, fordi den gør de nye forlystelser forskellige. Derefter D (sideshow-præmier), som er lille og selvstændig.
3. **Senere:** A (Tømmerrenden), som er spor-baseret og bør vente på erfaring med coasteren, og C (Svævebanen) samt Bimmelbanen på spor.
4. **Forskning:** to nye topics, `water_rides` og `sideshows`. Hoppeborgen bliver startunlock, så startparken får en billig børneforlystelse.

## Log
- 2026-10-15 – designer: oprettet og startet (in-progress)
- 2026-10-15 – designer: forslaget er skrevet her og i gdd.md. Bliver stående på in-progress, til brugeren har valgt.
- 2026-10-15 – architect: brugeren har godkendt hele forslaget. Flyttet til M6 og sat til done. Implementeringen ligger i T-080..T-096 (se `_CONTRACT.md`).
