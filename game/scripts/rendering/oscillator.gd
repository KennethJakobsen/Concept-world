class_name Oscillator
extends Spinner
## T-083: Periodisk bevægelse (gynge, hop, fald) i stedet for konstant rotation.
## Arver Spinner, så RideVisual styrer speed_scale (blød start/stop) uden ændringer.
## speed = radianer fase pr. sekund. amplitude = meter (POSITION) eller radianer (ROTATION).
## Transformen er altid base + forskydning eller base * ren rotation, så den forbliver ortonormal.

enum Mode { POSITION, ROTATION }
enum Shape { SINE, BOUNCE, DROP, STRIKE }

@export var mode: Mode = Mode.POSITION
@export var shape: Shape = Shape.SINE
@export var amplitude: float = 0.1
@export var phase: float = 0.0

var _t: float = 0.0
var _base: Transform3D
var _has_base: bool = false


func _ready() -> void:
	_capture()


func _capture() -> void:
	if not _has_base:
		_base = transform
		_has_base = true


func _process(delta: float) -> void:
	_capture()
	if speed_scale <= 0.0001:
		return
	_t = fmod(_t + speed * speed_scale * delta, TAU * 64.0)
	var v := wave(_t + phase)
	var ax := axis.normalized()
	if mode == Mode.POSITION:
		transform = Transform3D(_base.basis, _base.origin + ax * amplitude * v)
	else:
		transform = Transform3D(_base.basis * Basis(ax, amplitude * v), _base.origin)


## Bølgeform i [-1, 1] (SINE) eller [0, 1] (øvrige).
func wave(t: float) -> float:
	match shape:
		Shape.BOUNCE:
			return absf(sin(t))
		Shape.DROP:
			var p := fposmod(t / TAU, 1.0)
			if p < 0.55:
				return smoothstep(0.0, 0.55, p)  # langsomt op
			if p < 0.7:
				return 1.0  # hænger i toppen
			if p < 0.78:
				var f := (p - 0.7) / 0.08
				return 1.0 - f * f  # frit fald
			return 0.0
		Shape.STRIKE:
			var p := fposmod(t / TAU, 1.0)
			if p < 0.15:
				return sin(p / 0.15 * PI * 0.5)  # skudt op
			if p < 0.6:
				return 1.0 - smoothstep(0.15, 0.6, p)
			return 0.0
	return sin(t)
