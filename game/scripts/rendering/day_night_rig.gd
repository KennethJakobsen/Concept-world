class_name DayNightRig
extends Node3D
## Sol/maane + himmel + ambient. Kun Compatibility-features (ProceduralSky, fog,
## ACES-tonemap, skyggeløs-venlig). Kald set_time_of_day(t) hver frame (t i [0,1),
## 0 = midnat, 0.5 = middag).

signal night_factor_changed(f: float)

## Debug: spol tiden selv (til demo-scenen). 0 = styres udefra.
@export var debug_day_seconds: float = 0.0

const DAY_SKY_TOP := Color(0.32, 0.55, 0.9)
const DAY_HORIZON := Color(0.72, 0.84, 0.95)
const DUSK_SKY_TOP := Color(0.32, 0.3, 0.55)
const DUSK_HORIZON := Color(0.98, 0.55, 0.3)
const NIGHT_SKY_TOP := Color(0.03, 0.05, 0.14)
const NIGHT_HORIZON := Color(0.1, 0.13, 0.26)
const SUN_DAY := Color(1.0, 0.96, 0.88)
const SUN_DUSK := Color(1.0, 0.6, 0.35)
const MOON := Color(0.6, 0.7, 1.0)

var time_of_day: float = 0.5
var _night: float = 0.0
var _last_emitted: float = -1.0
@onready var _sun: DirectionalLight3D = $Sun
@onready var _env: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_sun.shadow_enabled = true
	set_time_of_day(time_of_day)


func night_factor() -> float:
	return _night


func set_time_of_day(t: float) -> void:
	time_of_day = fposmod(t, 1.0)
	# Solhoejde: -1 ved midnat, +1 ved middag.
	var h := -cos(time_of_day * TAU)
	var day := smoothstep(-0.12, 0.18, h)  # 0 nat .. 1 dag
	var dusk := clampf(1.0 - absf(h) / 0.3, 0.0, 1.0) * 1.0  # topper ved horisont
	_night = 1.0 - day
	# Lysretning: sol om dagen, maane (modsat side, hoejt) om natten.
	if _sun == null:
		_sun = $Sun
		_env = $WorldEnvironment
	var az := time_of_day * TAU
	var elev: float
	if day > 0.0 or h > -0.12:
		elev = maxf(deg_to_rad(8.0), asin(clampf(h, -1.0, 1.0)))
	else:
		elev = deg_to_rad(45.0)
	if _night > 0.5:
		elev = deg_to_rad(50.0)
		az += PI
	_sun.rotation = Vector3(-elev, az + PI * 0.25, 0.0)
	var sun_col := SUN_DAY.lerp(SUN_DUSK, dusk)
	_sun.light_color = sun_col.lerp(MOON, _night)
	_sun.light_energy = lerpf(0.25, 1.15, day) * (1.0 - 0.3 * dusk * day)
	_sun.shadow_opacity = lerpf(0.35, 0.8, day)
	var env := _env.environment
	var top := NIGHT_SKY_TOP.lerp(DAY_SKY_TOP, day).lerp(DUSK_SKY_TOP, dusk * 0.6)
	var hor := NIGHT_HORIZON.lerp(DAY_HORIZON, day).lerp(DUSK_HORIZON, dusk * 0.8)
	var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
	sky_mat.sky_top_color = top
	sky_mat.sky_horizon_color = hor
	sky_mat.ground_horizon_color = hor
	sky_mat.ground_bottom_color = top.darkened(0.4)
	# Ambient holdes hoejt nok om natten til at stier/grid kan ses.
	env.ambient_light_color = Color(0.35, 0.42, 0.7).lerp(Color(0.85, 0.88, 0.95), day)
	env.ambient_light_energy = lerpf(0.55, 0.6, day)
	env.fog_light_color = hor
	env.fog_density = lerpf(0.004, 0.002, day)
	env.tonemap_exposure = lerpf(1.1, 1.0, day)
	if absf(_night - _last_emitted) > 0.01:
		_last_emitted = _night
		night_factor_changed.emit(_night)


func _process(delta: float) -> void:
	if debug_day_seconds > 0.0:
		set_time_of_day(time_of_day + delta / debug_day_seconds)
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam:
		LampVisual.update_lod(cam.global_position)
