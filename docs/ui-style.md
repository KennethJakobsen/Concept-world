# Concept-world – UI-stilguide (T-136)

Retning: **"Tivoli-skilt"**. Varme, malede træplader med messingkanter og cremefarvede papirkort, ligesom skiltene ved en gammel forlystelsespark. Det passer til det stiliserede low-poly-look (mættet grønt græs, lyseblå himmel, gule busser, se `docs/screenshots/t108_*.png`). UI'et skal ligne noget, der står **i** parken, og ikke et kontorprogram oven på den.

Erstatter: blå knapper på grå bjælke (T-101).

---

## 1. Research – hvad gør de andre?

| Spil | Hvad de gør | Hvad vi tager | Hvad vi undgår |
|---|---|---|---|
| **RollerCoaster Tycoon 2** | Små vinduer med farvet ramme og faneblade med ikoner. Byggevinduet viser en **miniature af forlystelsen** og navn/pris nedenunder. Værktøjslinje med lutter ikoner. | Ikon-fanerne, billede + navn + pris, værktøjslinje kun med ikoner og tooltip | Mange flydende vinduer og pixel-gråt |
| **RCT3** | Runde ikonknapper i en bjælke forneden og kategori-"hjul" | Store, runde kategori-knapper | Gennemsigtigt, koldt glas |
| **Planet Coaster 1/2** | Mørkt halvgennemsigtigt UI med farvede kategoriikoner og **store miniaturer i et gitter**. Kritiseret for for mange faner og lag (især PC2). | Gitter med store, tydelige miniaturer og farvekoder pr. kategori | Mørke, kolde paneler og menuer i flere niveauer. Højst 2 klik til et kort |
| **Parkitect** | Lyst, rent, fladt UI. Ikoner i en bundbjælke, og byggemenuen har miniaturer. Hyggeligt og læseligt. | Klar læsbarhed, flade ikoner med tydelig silhuet og venlige farver | Det helt neutrale/grå |
| **Two Point Hospital/Campus** | **Stemningsfuldt**: runde, kraftige knapper nederst til venstre, varme farver, tykke afrundede paneler og en legende tone. Stor ikonknap → panel med kort. | Runde "medaljon"-knapper, tykke kanter, en legende og varm tone, panel der glider op fra knappen | – |
| **Jurassic World Evolution** | Mørke paneler med temafarve og kategoriikoner i en ring | Én klar accentfarve pr. kategori | Mørkt/realistisk |

**Konklusion:** byggemenuen er **ikoner (kategorier) → gitter af billedkort (miniature + navn + pris)**. Panelerne er varme materialer (træ/papir/messing) og ikke flade blå/grå flader. Én samlet palet og ét sæt StyleBoxes bruges overalt.

---

## 2. Farvepalet

| Token | Hex | Brug |
|---|---|---|
| `wood_dark` | `#5A3A22` | Panelramme, bjælkebaggrund (TopBar, BuildDock-bund) |
| `wood_mid` | `#7A4E2D` | Knapper (normal), faneblade |
| `wood_light` | `#9C6A3F` | Knapper (hover) |
| `paper` | `#F6EBD3` | Kort- og panelindhold (Inspector-krop, kort) |
| `paper_shade` | `#E6D5B0` | Alternerende rækker, indre felter, sliders |
| `brass` | `#D9A441` | Kanter, valgt-markering, stjerner |
| `brass_light` | `#F2C96B` | Hover-glød, fremhævet kant |
| `ink` | `#3B2A1E` | Brødtekst på papir |
| `cream_text` | `#FFF4DC` | Tekst på træ |
| `red_sign` | `#C8452F` | Fare/fjern, ulæste varsler, udgifter |
| `green_ok` | `#4F9A3A` | Indtægt, OK, "råd til" |
| `teal` | `#2F8C8C` | Info/sekundær accent |
| `locked` | `#8A8174` | Låste kort (desatureret) |
| `shadow` | `#000000` α 0,35 | Drop-skygger |

Kategorifarver (bånd i kortets top og ring om kategoriknappen):

| Kategori | Hex |
|---|---|
| Stier | `#B08A5A` |
| Forlystelser | `#D9534F` |
| Butikker | `#E8A33D` |
| Pynt | `#5BA05B` |
| Personale | `#3F7CBF` |
| Rutsjebane | `#8E5BB5` |

Kontrast: `ink` på `paper` og `cream_text` på `wood_dark` ligger begge over 7:1. Farveblind-tilstand: kategorier skelnes **altid** også på ikonet. Farven er aldrig eneste bærer af information.

---

## 3. Materialer og StyleBoxes

Alt laves som `StyleBoxFlat` (ingen 9-patch-teksturer er påkrævet; virker i Compatibility/web). Træ-årer er valgfrie: `StyleBoxTexture` med en egen CC0-tekstur (`ui/wood_grain.png`, 64×64, flisebar) kan komme senere. Fallback er den flade farve.

Navngivning i `game/scenes/ui/theme/concept_theme.tres` (T-138):

| StyleBox | bg | Kant | Hjørner | Skygge | content_margin |
|---|---|---|---|---|---|
| `panel_wood` | `wood_dark` | 3 px `brass` | 10 px | 6 px, offset (0,3) | 10 px |
| `panel_paper` | `paper` | 2 px `#C9B58C` | 8 px | 4 px, offset (0,2) | 12 px |
| `button_normal` | `wood_mid` | 2 px `#3F2816` (bund 4 px = "tykkelse") | 8 px | 2 px | 8/6 px (h/v) |
| `button_hover` | `wood_light` | 2 px `brass_light` (bund 4 px) | 8 px | 3 px | samme |
| `button_pressed` | `wood_dark` | 2 px `brass` (top 4 px, bund 2 px = trykket ned) | 8 px | 0 | samme |
| `button_disabled` | `#6E5E50` | 2 px `#4E4339` | 8 px | 0 | samme |
| `medallion` (rund knap) | `wood_mid` | 3 px `brass`, ved valgt 4 px `brass_light` | 50 % (radius = halv størrelse) | 4 px | 6 px |
| `card` | `paper` | 2 px `#C9B58C` | 8 px | 3 px, offset (0,2) | 6 px |
| `card_hover` | `#FFF8E6` | 2 px `brass_light` | 8 px | 6 px, offset (0,4) | 6 px |
| `card_selected` | `paper` | 3 px `brass` | 8 px | 6 px + 2 px `brass` glød | 6 px |
| `tab` (inaktiv) | `wood_mid` | 0, kun top-hjørner 8 px | | | 10/4 px |
| `tab_selected` | `paper` (smelter sammen med panelet) | 2 px `#C9B58C`, ingen bundkant | | | 10/4 px |
| `tooltip` | `#3B2A1E` α 0,95 | 2 px `brass` | 6 px | 4 px | 8 px |
| `progress_bg` / `fill` | `paper_shade` / `green_ok` | 1 px `#C9B58C` | 4 px | | |

Anti-aliasing slået til (`anti_aliasing = true`, størrelse 1). Undgå `blur`/shaders i UI (web-perf).

---

## 4. Typografi

- **Standard:** Godots standardfont (gældende glyph-test `test_hud_glyphs` gælder fortsat: ingen emoji, ingen specielle pile/symboler. Brug ikoner i stedet).
- **Valgfri displayfont (anbefalet til overskrifter og tal):** *Kenney Future* fra *Kenney Fonts*, https://kenney.nl/assets/kenney-fonts – **CC0 1.0**. Læg den i `game/assets/fonts/` og skriv kilde + licens i `game/assets/CREDITS.md`. Hvis den tilføjes, skal glyph-testen udvides til også at tjekke den (æ, ø, å, Æ, Ø, Å, kr, %, cifre). Mangler danske tegn, bruges den **kun til cifre** (penge, dato), og standardfonten bruges til tekst.
- Størrelser (ved 100 % UI-skala): titel 22 px, panel-overskrift 18 px, brødtekst 14 px, kort-navn 13 px, kort-pris 13 px fed, tooltip 13 px, TopBar-tal 18 px.
- Tekst på træ: `cream_text` med 1 px outline `#2A1A0E` (`outline_size = 2`). Tekst på papir: `ink` uden outline.
- Penge: `12.500 kr` (punktum som tusindtalsseparator). Negative tal i `red_sign`.

---

## 5. Ikonstil (til T-137)

- **Format:** PNG, 64×64 kilde (vises 32 eller 48 px), med alfa. Også en 128×128 version til medaljoner.
- **Stil:** flade, venlige former med 2–3 toner pr. ikon. **Outline 3 px (ved 64 px) i `#3B2A1E`**, lille highlight øverst til venstre og ingen gradienter ud over én skygge-tone. Samme perspektiv: forfra, let ovenfra (ca. 15°).
- **Farve:** ikonet selv er farvet (ikke monokromt) og har cremefarvede/hvide flader, så det står godt på både `wood_mid` og `paper`.
- **Fremstilling:** tegnet i SVG af os selv (importeres som SVG i Godot, `scale` efter behov) eller genereret med script. Ingen tredjeparts-ikonpakker, medmindre de er CC0 og krediteret.
- **Placering:** `game/assets/ui/icons/<id>.svg|png` og id'er som i §8.

### Miniaturer af props (kort-billeder)
- 160×120 PNG, renderet **offline af props-scenen selv** (headless SubViewport-script i `tools/`, kørt én gang og committet) fra fast vinkel: isometrisk 30° op og 45° rundt, varmt sollys, **transparent baggrund**. Kortet giver selv baggrunden (blød radial gradient i kategorifarven 25 % → `paper`, lavet som en lille gradient-tekstur eller som kortets `bg`).
- Prop'en fylder ca. 80 % af højden og står på en lille græs-/stiflise (oval skygge).
- Fil: `game/assets/ui/thumbs/<content_id>.png`. Mangler den, vises kategori-ikonet 64 px centreret (fallback, ingen fejl).
- Runtime-rendering af miniaturer frarådes (web-starttid).

---

## 6. Komponenter

Alle mål ved 100 % UI-skala (1280×720 referencer).

### 6.1 BuildDock (byggemenu), nederst i midten
```
            ┌───────────────── kort-panel (panel_paper) ─────────────────┐
            │ [kort][kort][kort][kort][kort][kort]   <  1/2  >           │
            └────────────────────────────────────────────────────────────┘
   ╭───────────────── dock-bjælke (panel_wood) ──────────────────╮
   │ (Vælg)(Fjern) │ (Sti)(Forl.)(Butik)(Pynt)(Pers.)(Rutsj.)    │
   ╰─────────────────────────────────────────────────────────────╯
```
- **Dock-bjælke:** `panel_wood`, højde 76 px, centreret, svæver 12 px over bunden (ikke kant-til-kant). En lille messingplade på bjælkens top-midte med ordet "Byg" (14 px) er valgfri pynt.
- **Kategoriknapper:** `medallion` 60×60 px, ikon 40 px, 8 px mellemrum. Ring i kategorifarven (3 px inden for messingkanten). Ingen tekst. Navnet vises i tooltip og som lille label (12 px) under den **valgte** knap.
- **Værktøjer (Vælg/Fjern):** medallion 48×48 px, til venstre, adskilt med en 2 px lodret messing-skillelinje. Fjern har `red_sign`-ring.
- **Kort-panel:** glider op over bjælken (0,15 s, ease-out). `panel_paper` med faneblad-tunge i kategorifarven, der forbinder det med den valgte knap. Højst 7 kort pr. række, 1 række (2 rækker ved ≥ 900 px vindueshøjde). Sideskift med pileknapper, der er ikoner (`arrow_left`/`arrow_right`), ikke tegn.
- **Kort:** 120×150 px, `card`. Fra toppen: 4 px bånd i kategorifarven, miniature 112×84, navn (13 px, `ink`, 1 linje, ellipsis), pris-række: lille mønt-ikon 14 px + `1.200 kr` (fed). Har man ikke råd, er prisen `red_sign`.
- **Tilstande:**
  - *Hover:* `card_hover`, løftes 3 px (position.y −3, 0,08 s), tooltip efter 0,4 s med statistik.
  - *Valgt* (placeres nu): `card_selected` + lille messing-flueben-ikon øverst til højre.
  - *Låst:* miniaturen moduleres `#8A8174` med 60 % mætning væk, hængelås-ikon 24 px i midten, pris erstattes af "Forskning". Tooltip: hvad der låser den op.
  - *Ikke råd:* normalt kort, men pris i `red_sign`, og klik giver varsel.
- Tastatur: 1–6 vælger kategori, Esc lukker kort-panelet.

### 6.2 TopBar, øverst
- Ikke en kant-til-kant-bjælke, men **3 skilte** (`panel_wood`, højde 44 px, 8 px fra toppen):
  - Venstre: penge-ikon + beløb (18 px), blink grønt/rødt (GDD).
  - Midt: dato, dagsur-ikon (sol/måne efter tid), gæste-ikon + antal, glæde-smiley (5 ikoner), 5 stjerner (`brass` fyldte / `#6E5E50` tomme).
  - Højre: hastighedsknapper som medallion 32 px (pause/1×/2×/4×-ikoner, valgt = `brass_light`-ring) + klokke med rødt badge (cirkel 16 px `red_sign`, tal 11 px hvid).
- Skiltene "hænger" i to små messingkæder (valgfri pynt, 2×10 px rektangler).

### 6.3 ParkRail, venstre kant
- Lodret `panel_wood`-strimmel, 64 px bred, afrundet på højre side (hjørner 0/10/10/0), centreret lodret.
- Medallion 48 px pr. post: Park, Personale, Forskning, Indstillinger, Menu (+ registrerede). 10 px mellemrum. Aktivt panel: messingring + lille trekant-"tunge" mod panelet.
- Åbnede rail-paneler: `panel_wood`-ramme med `panel_paper`-krop, titel-"skilt" øverst (træplade med `cream_text` 18 px), X-knap som medallion 28 px med `close`-ikon.

### 6.4 Inspector, højre
- 340 px bred, fuld højde minus TopBar og 12 px margin. Ramme `panel_wood`, krop `panel_paper`.
- Header: titel-skilt (træplade, 18 px), lille rundt portræt/miniature 56 px (prop-thumb eller gæste-ikon) til venstre, X til højre.
- Faner: `tab`/`tab_selected` med **ikon 20 px + kort tekst**. Mangler pladsen, vises kun ikon.
- Nøgletal som rækker: ikon 16 px, label, værdi højrejusteret. Bjælker bruger `progress_*`. Glæde-bjælken skifter farve rød → gul `#E8C53D` → `green_ok`.
- Glider ind fra højre (0,15 s).

### 6.5 AlertTray, nederst til højre
- Hvert varsel er en lille papirseddel: `panel_paper` 300×48 px, venstre-kant 6 px i type-farve (fare `red_sign`, info `teal`, ok `green_ok`), ikon 28 px, tekst 13 px (2 linjer maks.).
- Glider ind fra højre og forsvinder (fade) efter 4 s. Hover pauser timeren, og cursoren bliver en hånd, hvis varslet har en celle.

### 6.6 Hovedmenu
- Baggrund: live 3D-scene af en demo-park (eller seneste screenshot) med langsom kamera-orbit og en varm vignet (`ColorRect` med gradient-tekstur, sort α 0 → 0,45 i kanterne).
- Logo: "Concept-world" på et stort buet træskilt (`panel_wood`, 40 px tekst, messingkant 4 px) med pærer-prikker (små cirkler `brass_light`) langs kanten. Pærerne blinker langsomt, ingen shader.
- Knapper: lodret stak, 280×52 px, `button_*`-styles, ikon 24 px + tekst 18 px (Fortsæt, Ny park, Indlæs, Indstillinger, Afslut).
- Pause-menu og dialogboks bruger samme knapper i et `panel_wood`/`panel_paper`-vindue, og baggrunden dæmpes med sort α 0,4.

### 6.7 Tooltip
`tooltip`-stylebox. Titel 14 px `brass_light`, krop 13 px `cream_text`, maks. bredde 280 px. Pris/effekt-linjer har ikon 14 px foran.

### 6.8 Animation (fælles)
Kun Tween på position/modulate/scale: hover-løft 0,08 s, paneler 0,15 s ease-out, knaptryk scale 0,95 i 0,06 s. Respekter "reducer bevægelse", hvis den indstilling findes (så er varigheden 0).

---

## 7. Lyd (hook til eksisterende audio)
Klik: træ-"tok". Hover: blødt tik (lav volumen). Placering: eksisterende byggelyd. Afvist: dæmpet "bonk". Kun egne/CC0-lyde.

---

## 8. Ikonliste (T-137)

### Kategorier (64 + 128 px)
| id | Motiv |
|---|---|
| `cat_paths` | To brostens-fliser i perspektiv med en lille lygtepæl |
| `cat_rides` | Karrusel-tag (rød/hvid stribet kegle med flag) |
| `cat_shops` | Bod med stribet markise og en is i vinduet |
| `cat_decor` | Rundt træ og en blomst |
| `cat_staff` | Kasket med parkens logo (stjerne) |
| `cat_coaster` | Rutsjebane-loop/bakke med vogn |

### Værktøjer
| id | Motiv |
|---|---|
| `tool_select` | Hvid handske/pegefinger |
| `tool_remove` | Bulldozer-skovl, rød |
| `tool_rotate` | Buet pil rundt om en lille kasse |
| `tool_undo` | Buet pil mod venstre |
| `arrow_left` / `arrow_right` | Messing-trekant-pile |
| `close` | X lavet af to træstave |
| `check` | Messing-flueben |
| `lock` | Hængelås, messing |
| `coin` | Guldmønt med "k" |

### TopBar
| id | Motiv |
|---|---|
| `money` | Stak mønter |
| `guests` | To små gæste-silhuetter |
| `clock_day` / `clock_night` | Sol / måne med stjerne |
| `mood_1` … `mood_5` | Smiley: meget sur (rød) → glad (grøn), 5 trin |
| `star_full` / `star_empty` | Messingstjerne / grå kontur |
| `speed_pause`, `speed_1`, `speed_2`, `speed_4` | Pause-streger; 1, 2 og 3 trekanter (4× = tre trekanter + lille "4"-prik) |
| `bell` | Messingklokke |

### ParkRail
| id | Motiv |
|---|---|
| `rail_park` | Indgangsport med flag |
| `rail_staff` | Udklipsholder med tre personer |
| `rail_research` | Kolbe/pære med tandhjul |
| `rail_settings` | Tandhjul |
| `rail_menu` | Tre træplanker (burger) |
| `rail_finance` | Pengepung (reserveret til senere paneler) |

### Varsler / Inspector
| id | Motiv |
|---|---|
| `alert_danger` | Rød trekant med udråbstegn |
| `alert_info` | Teal cirkel med "i" |
| `alert_ok` | Grøn cirkel med flueben |
| `alert_broken` | Skruenøgle over tandhjul |
| `alert_trash` | Fyldt skraldespand |
| `stat_hunger`, `stat_thirst`, `stat_toilet`, `stat_energy`, `stat_fun` | Burger, dråbe, toiletdør, batteri, ballon |
| `stat_queue` | Tre prikker i række med en pil |
| `stat_capacity` | Sæde |
| `stat_excitement`, `stat_intensity`, `stat_nausea` | Lyn, flamme, grøn spiral |
| `guest_portrait` / `staff_portrait` | Rundt hoved, neutralt / med kasket |

### Hovedmenu
`menu_continue` (play-trekant), `menu_new` (plus på et skilt), `menu_load` (åben mappe), `menu_settings` (tandhjul, samme som rail), `menu_quit` (dør med pil).

### Miniaturer
Én pr. byggeligt content-id: alle filer i `game/content/attractions/*.json` (30 stk., inkl. `atm`, `toilet`), `decor/*.json` (7), stier (`path`, `queue_path`) og rutsjebane-stykker (én fælles `coaster_station`), og personale bruger portrætter (`staff_cleaner`, `staff_mechanic`, `staff_entertainer`).

---

## 9. Tekniske krav
- Kun `StyleBoxFlat`, `Tween`, `TextureRect`, PNG/SVG. Ingen custom shaders i UI og ingen `BackBufferCopy`/blur (Compatibility/web).
- Alle størrelser i Theme-konstanter, så UI-skalering (`content_scale_factor`) virker.
- Teksturer: importeres med mipmaps fra og filter "Linear" til ikoner/miniaturer.
- Alle assets er egne eller CC0 med kilde i `game/assets/CREDITS.md`.
- Ingen tegn uden for standardfonten. Pile, flueben, stjerner osv. er **ikoner**, ikke Unicode.

---

## Logo (T-139)

Filer i `game/assets/ui/logo/` (alt er eget arbejde, håndskrevet SVG):

| Fil | Brug |
|---|---|
| `logo_full.svg` + `logo_full_{1024,512,256}.png` | Fuldt logo: buet træskilt med messingkant, pærer, pariserhjul-medaljon og ordmærket "Concept / WORLD". Hovedmenu, boot-splash |
| `logo_symbol.svg` + `logo_symbol_{512,256,64}.png` | Kun symbol (medaljon med pærekrans og pariserhjul). App-ikon og knapper |
| `logo_symbol_small.svg` + `favicon_{32,16}.png` | Forenklet symbol til små størrelser (favicon) |
| `src/logo_full_src.svg` | Kilde med `<text>`. `logo_full.svg` er konverteret til paths (inkscape `--export-text-to-path`), så den ikke afhænger af en font |

- **Minimumsstørrelser:** fuldt logo mindst 256 px bredt. Detaljeret symbol mindst 48 px. Under det bruges `logo_symbol_small`.
- **Farver:** kun paletten: `wood_*`, `brass`/`brass_light`, `paper`, `cream_text`, `ink` og `red_sign` (WORLD-båndet). Kurvene i hjulet bruger kategorifarverne.
- **Frirum:** mindst 1/8 af logoets højde på alle sider. Logoet må ikke strækkes, omfarves eller lægges på en baggrund med lav kontrast, dvs. mellembrun træfarve.
- **Baggrund:** logoet er designet til himmelblå/grøn (spilscenen) og `wood_dark`. PNG'erne har transparent baggrund.
- Preview: `docs/screenshots/t139_logo.png`.
