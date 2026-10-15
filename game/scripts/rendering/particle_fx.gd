class_name ParticleFx
extends Node3D
## Faelles effekt-rod: play() starter alle CPUParticles3D-boern. One-shot-effekter
## frigiver sig selv, naar partiklerne er faerdige. Loopende (fx repair_sparks) stoppes med stop().

@export var one_shot: bool = true
@export var autoplay: bool = false


func _ready() -> void:
	for p in _particles():
		p.one_shot = one_shot
		p.emitting = false
	if autoplay:
		play()


func _particles() -> Array[CPUParticles3D]:
	var out: Array[CPUParticles3D] = []
	for c in get_children():
		if c is CPUParticles3D:
			out.append(c)
	return out


func play() -> void:
	var longest := 0.0
	for p in _particles():
		p.restart()
		p.emitting = true
		longest = maxf(longest, p.lifetime * (1.0 + p.explosiveness * 0.0) + 0.2)
	if one_shot and is_inside_tree():
		get_tree().create_timer(longest + 0.3).timeout.connect(queue_free)


func stop() -> void:
	for p in _particles():
		p.emitting = false
