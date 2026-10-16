class_name VomitFx
extends ParticleFx
## T-087: Opkast-effekt. Draaber (CPUParticles3D) + lille poel-mesh (ingen projektor-decal,
## Compatibility). Poelen vokser ind og toner ud efter PUDDLE_TIME; derefter frigives noden.
## Den vedvarende tilsmudsning vises af affaldet (world.get_vomit) – dette er kun effekten.

const PUDDLE_TIME: float = 6.0


func play() -> void:
	for p in _particles():
		p.restart()
		p.emitting = true
	var puddle := get_node_or_null("Puddle") as Node3D
	if puddle == null or not is_inside_tree():
		return
	puddle.scale = Vector3(0.2, 1.0, 0.2)
	var tw := create_tween()
	tw.tween_property(puddle, "scale", Vector3.ONE, 0.5).set_delay(0.3)
	tw.tween_interval(PUDDLE_TIME)
	tw.tween_property(puddle, "scale", Vector3(0.05, 1.0, 0.05), 1.0)
	tw.tween_callback(queue_free)
