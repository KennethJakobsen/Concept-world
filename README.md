# Concept-world

3D park-management-spil i Godot 4.7 (GDScript). Kører på desktop og web.

- Følg fremdrift: [`tasks/BOARD.md`](tasks/BOARD.md)
- Design: [`docs/gdd.md`](docs/gdd.md) · Arkitektur: [`docs/adr/`](docs/adr/) · [`docs/conventions.md`](docs/conventions.md)

## Kom i gang
```bash
brew install --cask godot && brew install git-lfs
./tools/test.sh          # kør tests
./tools/build_web.sh     # byg web → build/web
python3 -m http.server -d build/web 8000
godot -e --path game     # åbn editoren
```
