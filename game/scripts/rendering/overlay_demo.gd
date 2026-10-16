extends Node3D
## T-109 demo: overlays over en lille kunstig park. Taster 1-5 = overlay, 0 = skjul, C = farveblind.
## Koeres: godot res://scenes/rendering/overlay_demo.tscn  [-- --kind=happiness --cb --shot=fil.png]

var _ov: OverlayRenderer
var _hl: Array[CellHighlight] = []


func _ready() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_color = Color(0.6, 0.78, 0.95)
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.75, 0.8)
	add_child(env)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(24, 24)
	ground.mesh = pm
	ground.position = Vector3(12, 0, 12)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.35, 0.6, 0.3)
	ground.material_override = gm
	add_child(ground)
	for b in [Vector3(5, 1, 5), Vector3(16, 1.5, 6), Vector3(8, 1, 17)]:
		var box := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(3, b.y * 2, 3)
		box.mesh = bm
		box.position = b
		add_child(box)
	var cam := Camera3D.new()
	cam.position = Vector3(12, 18, 28)
	add_child(cam)
	cam.look_at(Vector3(12, 0, 11))
	_ov = OverlayRenderer.new()
	add_child(_ov)
	for i in 2:
		var h := CellHighlight.new()
		add_child(h)
		_hl.append(h)
	var kind := ""
	var shot := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--kind="):
			kind = a.trim_prefix("--kind=")
		elif a.begins_with("--shot="):
			shot = a.trim_prefix("--shot=")
		elif a == "--cb":
			ParkColors.set_colorblind(true)
	if kind != "":
		_show(StringName(kind))
	else:
		_ghosts()
	if shot != "":
		for i in 30:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(shot)
		get_tree().quit()


func _ghosts() -> void:
	_hl[0].show_at(Vector2i(11, 11), true)
	_hl[1].show_at(Vector2i(13, 11), false)


func _data(kind: StringName) -> Dictionary:
	var cells: Dictionary = {}
	var markers: Array[Vector2i] = []
	for x in range(2, 22):
		for y in [10, 11]:
			var c := Vector2i(x, y)
			var t := float(x - 2) / 19.0
			match kind:
				&"coverage":
					cells[c] = 1.0 if x < 12 else 0.0
				&"queue":
					cells[c] = t
					if t > 0.8:
						markers.append(c)
				_:
					cells[c] = t
	for y in range(2, 22):
		cells[Vector2i(12, y)] = float(y - 2) / 19.0
	return {"cells": cells, "markers": markers}


func _show(kind: StringName) -> void:
	_ov.show_overlay(kind, _data(kind))


func _unhandled_key_input(e: InputEvent) -> void:
	var k := e as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode == KEY_0:
		_ov.hide_overlay()
	elif k.keycode == KEY_C:
		ParkColors.set_colorblind(not ParkColors.colorblind)
		_ghosts()
	elif k.keycode >= KEY_1 and k.keycode <= KEY_5:
		_show(ParkColors.OVERLAY_KINDS[k.keycode - KEY_1])
