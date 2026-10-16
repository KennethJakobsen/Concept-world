extends "res://scripts/bridge/m7_bridge_screenshots.gd"
## T-148: skrå nærbilleder af hovedstien med 500 gæster (LOD-overgang). Kør (ikke headless):
## cd game && godot --rendering-method gl_compatibility --resolution 1280x720 \
##   --script res://scripts/rendering/m7/t148_crowd_screenshots.gd -- ../docs/screenshots/t148


func _process(delta: float) -> bool:
	if _f < 30:
		return super(delta)
	_f += 1
	if _f == 31:
		_pv = current_scene.find_children("*", "ParkView", true, false)[0] as ParkView
		_cam = current_scene.find_children("*", "ParkCamera", true, false)[0] as ParkCamera
		_build_park()
		for i in 3000:
			_pv.sim.update(SimClock.TICK_DELTA)
		_view(12.0, 8.0, 0.3)
	elif _f == 60:
		_shot("close")
		_view(14.0, 22.0, 0.0)
	elif _f == 90:
		_shot("normal")
		_view(14.0, 40.0, 0.0)
	elif _f >= 100 and _f < 220:
		_fps_frames += 1
		_fps_t += delta
	elif _f == 220:
		_shot("far")
		print("FPS %d gæster: %.1f (noder %d, instanser %d)" % [_pv.sim.guests.size(),
			_fps_frames / maxf(_fps_t, 0.001), _pv.individual_guest_count(), _pv.crowd.instanced_count()])
		return true
	return false


func _view(along: float, dist: float, yaw: float) -> void:
	var e: Vector3 = ParkView.cell_center(_pv.sim.world.entrance)
	var dir: float = -1.0 if _pv.sim.world.entrance.y > _pv.sim.world.height / 2 else 1.0
	_cam.position = Vector3(e.x, 0.0, e.z + dir * along)
	_cam.rotation.y = (0.0 if dir < 0 else PI) + yaw
	_cam._distance = dist
	_cam._apply_distance()
