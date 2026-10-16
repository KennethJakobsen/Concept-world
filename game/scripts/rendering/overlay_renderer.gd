class_name OverlayRenderer
extends Node3D
## T-109: kort-overlay (glæde, skrald, kø, dækning, lys) over parken, mens resten af verden dæmpes.
##
## API (bridge T-111 / UI T-113):
##   show_overlay(kind: StringName, data: Dictionary)  # kind ∈ ParkColors.OVERLAY_KINDS
##   hide_overlay()
##   current_kind() -> StringName   (&"" når skjult)
##   signal overlay_changed(kind)   (&"" ved skjul)
## `data`:
##   "cells": Dictionary[Vector2i, float 0..1]  eller  Array[Vector2i] (= 1.0 hver)
##   "markers": Array[Vector2i] (valgfri; fx crowded_cells() – tegnes som små ringe)
##   "dim": float (valgfri, 0..1, default 0.55)
## Værdien er 0..1, hvor 1 = godt (glæde/dækning/lys) eller "meget" (skrald/kø) – ParkColors
## vender skalaen for skrald/kø, så gul altid er godt.
## (Navnene show_overlay/hide_overlay i stedet for kontraktens show/hide, fordi Node3D allerede
##  har show()/hide() som ikke kan overskrives.)

signal overlay_changed(kind: StringName)

const DIM_SHADER := """
shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, blend_mix;
uniform float dim = 0.55;
void vertex() { POSITION = vec4(VERTEX.xy * 2.0, 0.0, 1.0); }
void fragment() { ALBEDO = vec3(0.02, 0.03, 0.06); ALPHA = dim; }
"""

var _kind: StringName = &""
var _dim: MeshInstance3D
var _dim_mat: ShaderMaterial
var _tiles: MultiMeshInstance3D
var _markers: MultiMeshInstance3D


func _ready() -> void:
	_build()


func _build() -> void:
	if _dim != null:
		return
	_dim = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	_dim.mesh = q
	_dim_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = DIM_SHADER
	_dim_mat.shader = sh
	_dim_mat.render_priority = 0
	_dim.material_override = _dim_mat
	_dim.extra_cull_margin = 16384.0
	_dim.custom_aabb = AABB(Vector3(-1e5, -1e5, -1e5), Vector3(2e5, 2e5, 2e5))
	_dim.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_dim)
	_tiles = _mm_instance(_tile_mesh(0.94), 1)
	_markers = _mm_instance(_ring_mesh(), 2)
	visible = false


func _mm_instance(mesh: Mesh, prio: int) -> MultiMeshInstance3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true
	mat.render_priority = prio
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi


func _tile_mesh(s: float) -> Mesh:
	var p := PlaneMesh.new()
	p.size = Vector2(s, s)
	return p


func _ring_mesh() -> Mesh:
	var t := TorusMesh.new()
	t.inner_radius = 0.22
	t.outer_radius = 0.32
	t.rings = 12
	t.ring_segments = 4
	return t


func current_kind() -> StringName:
	return _kind


func show_overlay(kind: StringName, data: Dictionary) -> void:
	_build()
	_kind = kind
	_dim_mat.set_shader_parameter("dim", float(data.get("dim", 0.55)))
	var cells: Dictionary = {}
	var raw: Variant = data.get("cells", {})
	if raw is Dictionary:
		cells = raw
	elif raw is Array:
		for c in raw:
			cells[c] = 1.0
	var mm := _tiles.multimesh
	mm.instance_count = cells.size()
	var i := 0
	for c in cells:
		var cell: Vector2i = c
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(cell.x + 0.5, 0.05, cell.y + 0.5)))
		var col := ParkColors.overlay_color(kind, float(cells[c]))
		col.a = 0.85
		mm.set_instance_color(i, col)
		i += 1
	var marks: Array = data.get("markers", [])
	var mk := _markers.multimesh
	mk.instance_count = marks.size()
	for j in marks.size():
		var m: Vector2i = marks[j]
		mk.set_instance_transform(j, Transform3D(Basis(), Vector3(m.x + 0.5, 0.08, m.y + 0.5)))
		mk.set_instance_color(j, Color(1, 1, 1, 0.95))
	visible = true
	overlay_changed.emit(kind)


func hide_overlay() -> void:
	if _kind == &"" and not visible:
		return
	_kind = &""
	visible = false
	overlay_changed.emit(&"")


func tile_count() -> int:
	return 0 if _tiles == null else _tiles.multimesh.instance_count
