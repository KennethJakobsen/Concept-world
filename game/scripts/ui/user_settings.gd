class_name UserSettings
extends RefCounted
## Brugerindstillinger (T-101, kontrakt M7 beslutning 6) i `user://settings.cfg`:
## `[ui] scale, floating_money` og `[accessibility] colorblind`. Andre sektioner (fx AudioManagers
## `[audio]`) bevares, fordi filen indlæses før der skrives. Ikke en del af saven.

const PATH: String = "user://settings.cfg"
const SCALES: Array[float] = [0.75, 1.0, 1.25, 1.5, 2.0]
const MIN_SCALE: float = 0.75
const MAX_SCALE: float = 2.0

var path: String = PATH
var scale: float = 1.0
var floating_money: bool = true
var colorblind: bool = false


static func clamp_scale(v: float) -> float:
	return clampf(v, MIN_SCALE, MAX_SCALE)


## Indlæser fra disk. Manglende fil/nøgler giver defaults.
static func load_from(p: String = PATH) -> UserSettings:
	var s := UserSettings.new()
	s.path = p
	var cfg := ConfigFile.new()
	if cfg.load(p) == OK:
		s.scale = clamp_scale(float(cfg.get_value("ui", "scale", 1.0)))
		s.floating_money = bool(cfg.get_value("ui", "floating_money", true))
		s.colorblind = bool(cfg.get_value("accessibility", "colorblind", false))
	return s


## Skriver kun egne nøgler; resten af filen røres ikke.
func save() -> Error:
	var cfg := ConfigFile.new()
	cfg.load(path)  # fejl = ny fil
	cfg.set_value("ui", "scale", clamp_scale(scale))
	cfg.set_value("ui", "floating_money", floating_money)
	cfg.set_value("accessibility", "colorblind", colorblind)
	return cfg.save(path)


## UI-skala via Window.content_scale_factor (virker med stretch-mode canvas_items, også på web).
func apply(tree: SceneTree) -> void:
	if tree != null and tree.root != null:
		tree.root.content_scale_factor = clamp_scale(scale)
