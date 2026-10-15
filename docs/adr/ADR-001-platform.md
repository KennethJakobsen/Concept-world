# ADR-001: Platform – Godot 4.7 + statisk typet GDScript

- **Status:** accepteret · 2026-10-15

## Kontekst
Krav: 3D, alle platforme inkl. **web**, hobbyprojekt med solidt, udvideligt grundlag. Godot 4 kan (pr. 4.7) ikke web-eksportere C#.

## Beslutning
- Godot 4.7.2, **statisk typet GDScript**.
- Renderer: **Compatibility** (WebGL 2) som baseline. Forward+-effekter kun som valgfri desktop-forbedring.
- Simulation i `game/simulation/` som rene `RefCounted`-klasser uden scene-afhængighed, fast tick (20/s).
- Tunge dele kan senere flyttes til C++ GDExtension (virker også på web).

## Konsekvenser
- Ingen SSAO/SDFGI på web; grafikløft via stiliseret low-poly, lys, skygger, farver og partikler.
