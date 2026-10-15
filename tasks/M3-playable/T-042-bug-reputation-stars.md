# T-042: Bug – Omdømme-stjerner vises som firkanter

- **Status:** review
- **Milepæl:** M3
- **Agent:** ui
- **Afhænger af:** T-031

## Mål
Brugerrapport (screenshot): "Omdømme: □□□□□ 50%". Godots standardfont mangler ★/☆. Løs uden afhængighed af fontens glyffer – fx tegnede stjerner (Control med _draw/polygon) eller en lille ikon-tekstur genereret i kode – eller indlejr en CC0-font med glyfferne (notér i CREDITS.md). Gennemgå også resten af UI for andre ikke-ASCII symboler (danske æøå er ok).

## Acceptkriterier
- [x] Stjerner vises korrekt på desktop og web
- [x] Test der sikrer at HUD-tekster ikke indeholder glyffer uden for standardfontens dækning (fx via Font.has_char)
## Log
- 2026-10-15 – architect: oprettet efter brugerrapport
- 2026-10-15 – ui: ny StarRating (scripts/ui/star_rating.gd) tegner 5 stjerner med draw_colored_polygon, halve via Geometry2D-clipping; topbar viser 'Omdømme: N%' + StarRating. '…' → '...'. tests/test_hud_glyphs.gd: alle HUD-tekster dækket af ThemeDB.fallback_font (has_char) + StarRating-test. Import/smoke grønne; test.sh: alle UI-tests grønne, 1 fejl i test_staff_decor (simulation, igangværende arbejde) → review
