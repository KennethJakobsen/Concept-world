extends SceneTree
## T-083: Genererer M6-props (15 bygninger) som .tscn i res://scenes/props/.
## Kør: cd game && godot --headless --script res://scripts/rendering/props/m6_prop_builder.gd
## Alle transforms laves med Basis.from_euler/Quaternion og pakkes af Godot (ingen håndskrevne
## række-major-matricer). Ingen skalering, ingen spejling, kugler altid height = 2r (eller r som halvkugle).
## Origin = footprintets midte (ParkView placerer i midten), forsiden vender mod +Z.

const RV := preload("res://scripts/rendering/ride_visual.gd")
const SPIN := preload("res://scripts/rendering/spinner.gd")
const OSC := preload("res://scripts/rendering/oscillator.gd")
const PLASTER := preload("res://assets/textures/plaster.png")
const CANVAS := preload("res://assets/textures/canvas.png")
const PLANKS := preload("res://assets/textures/planks.png")
const METAL := preload("res://assets/textures/metal.png")

## Footprint (celler) pr. id. Kilde: T-079/kontrakt, justeres efter T-081.
const FOOTPRINTS: Dictionary = {
	"bouncy_castle": Vector2i(2, 2), "teacups": Vector2i(3, 3), "trampoline": Vector2i(2, 2),
	"sky_rings": Vector2i(2, 2), "pirate_ship": Vector2i(4, 2), "space_rocket": Vector2i(3, 3),
	"drop_tower": Vector2i(2, 2), "fries_stand": Vector2i(1, 1), "coffee_stand": Vector2i(1, 1),
	"balloon_stand": Vector2i(1, 1), "souvenir_shop": Vector2i(2, 1), "coconut_shy": Vector2i(2, 1),
	"shooting_gallery": Vector2i(2, 1), "hook_a_duck": Vector2i(1, 1), "strength_tester": Vector2i(1, 1),
}

var _mats: Dictionary = {}
var _root: Node3D


func _init() -> void:
	for id: String in FOOTPRINTS:
		_root = Node3D.new()
		_root.name = _pascal(id)
		_root.set_script(RV)
		_root.set_meta(&"footprint", FOOTPRINTS[id])
		call("_build_" + id)
		_own(_root, _root)
		var ps := PackedScene.new()
		var err := ps.pack(_root)
		assert(err == OK)
		err = ResourceSaver.save(ps, "res://scenes/props/%s.tscn" % id)
		print("%s: %s" % [id, "ok" if err == OK else str(err)])
		_root.free()
	quit()


func _pascal(id: String) -> String:
	var out := ""
	for p in id.split("_"):
		out += p.capitalize()
	return out


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)


# ---------------------------------------------------------------- materialer

const COLORS: Dictionary = {
	"red": Color(0.88, 0.26, 0.24), "yellow": Color(0.98, 0.84, 0.25), "blue": Color(0.3, 0.5, 0.88),
	"sky": Color(0.55, 0.78, 0.95), "green": Color(0.38, 0.72, 0.4), "white": Color(0.96, 0.95, 0.92),
	"cream": Color(0.98, 0.9, 0.74), "dark": Color(0.16, 0.16, 0.2), "brown": Color(0.45, 0.28, 0.16),
	"pink": Color(0.95, 0.58, 0.68), "orange": Color(0.98, 0.55, 0.18), "purple": Color(0.58, 0.38, 0.8),
	"teal": Color(0.25, 0.66, 0.66), "grey": Color(0.6, 0.62, 0.66), "gold": Color(0.93, 0.74, 0.28),
	"coffee": Color(0.36, 0.22, 0.12), "mint": Color(0.6, 0.88, 0.75), "black": Color(0.08, 0.08, 0.1),
}


## Farvet materiale med triplanar tekstur (plaster som standard, jf. T-074).
func m(color: String, tex: Texture2D = PLASTER) -> StandardMaterial3D:
	var key := color + str(tex.resource_path)
	if _mats.has(key):
		return _mats[key]
	var mat := StandardMaterial3D.new()
	mat.resource_name = color
	mat.albedo_color = COLORS[color]
	mat.albedo_texture = tex
	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(2, 2, 2)
	mat.roughness = 0.75
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_mats[key] = mat
	return mat


func glass() -> StandardMaterial3D:
	if _mats.has("glass"):
		return _mats["glass"]
	var mat := StandardMaterial3D.new()
	mat.resource_name = "glass"
	mat.albedo_color = Color(0.8, 0.92, 1.0, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	_mats["glass"] = mat
	return mat


func glow(color: String) -> StandardMaterial3D:
	var key := "glow_" + color
	if _mats.has(key):
		return _mats[key]
	var mat := StandardMaterial3D.new()
	mat.resource_name = key
	mat.albedo_color = COLORS[color]
	mat.emission_enabled = true
	mat.emission = COLORS[color]
	mat.emission_energy_multiplier = 0.6
	_mats[key] = mat
	return mat


# ---------------------------------------------------------------- byggeklodser

func node(parent: Node, nm: String, pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.name = nm
	n.transform = Transform3D(Basis.from_euler(rot * (PI / 180.0)), pos)
	parent.add_child(n)
	return n


func spinner(parent: Node, nm: String, pos: Vector3, speed: float, ax: Vector3 = Vector3.UP) -> Node3D:
	var n := node(parent, nm, pos)
	n.set_script(SPIN)
	n.set("speed", speed)
	n.set("axis", ax)
	return n


func osc(parent: Node, nm: String, pos: Vector3, mode: int, shape: int, amp: float, speed: float,
		ax: Vector3 = Vector3.UP, ph: float = 0.0) -> Node3D:
	var n := node(parent, nm, pos)
	n.set_script(OSC)
	n.set("mode", mode)
	n.set("shape", shape)
	n.set("amplitude", amp)
	n.set("speed", speed)
	n.set("axis", ax)
	n.set("phase", ph)
	return n


func put(parent: Node, nm: String, mesh: Mesh, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.transform = Transform3D(Basis.from_euler(rot * (PI / 180.0)), pos)
	parent.add_child(mi)
	return mi


func box(sx: float, sy: float, sz: float, mat: Material) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(sx, sy, sz)
	b.material = mat
	return b


func cyl(top: float, bottom: float, h: float, mat: Material, seg: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	c.material = mat
	return c


func sph(r: float, mat: Material, hemi: bool = false, seg: int = 14) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r if hemi else r * 2.0
	s.is_hemisphere = hemi
	s.radial_segments = seg
	s.rings = maxi(3, seg / 2)
	s.material = mat
	return s


func torus(inner: float, outer: float, mat: Material, rings: int = 16, seg: int = 6) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = rings
	t.ring_segments = seg
	t.material = mat
	return t


func prism(sx: float, sy: float, sz: float, mat: Material) -> PrismMesh:
	var p := PrismMesh.new()
	p.size = Vector3(sx, sy, sz)
	p.material = mat
	return p


## Cylinder (pind/snor) fra a til b med ren rotation.
func stick(parent: Node, nm: String, a: Vector3, b: Vector3, r: float, mat: Material, seg: int = 6) -> MeshInstance3D:
	var d := b - a
	var mi := put(parent, nm, cyl(r, r, d.length(), mat, seg), (a + b) * 0.5)
	var q := Quaternion(Vector3.UP, d.normalized()) if absf(d.normalized().y) < 0.9999 else Quaternion.IDENTITY
	if d.y < 0.0 and absf(d.normalized().y) >= 0.9999:
		q = Quaternion.IDENTITY
	mi.transform = Transform3D(Basis(q), mi.position)
	return mi


func base_plate(w: float, d: float, color: String = "grey") -> void:
	put(_root, "Base", box(w, 0.1, d, m(color)), Vector3(0, 0.05, 0))


## Tegneserie-øjne (hvide kugler med sorte pupiller) ved pos, vendt mod +Z (eller dir).
func eyes(parent: Node, pos: Vector3, spread: float, r: float, prefix: String = "Eye") -> void:
	for s: float in [-1.0, 1.0]:
		var p := pos + Vector3(spread * s, 0, 0)
		put(parent, prefix + ("L" if s < 0 else "R"), sph(r, m("white"), false, 8), p)
		put(parent, prefix + "Pupil" + ("L" if s < 0 else "R"), sph(r * 0.5, m("black"), false, 6), p + Vector3(0, 0, r * 0.75))


## Gummiand (gul, orange næb), vender mod +Z. size ~ kropsradius.
func duck(parent: Node, nm: String, pos: Vector3, size: float, color: String = "yellow") -> Node3D:
	var d := node(parent, nm, pos)
	put(d, "Body", sph(size, m(color)), Vector3.ZERO)
	put(d, "Head", sph(size * 0.62, m(color)), Vector3(0, size * 0.95, size * 0.35))
	put(d, "Beak", box(size * 0.5, size * 0.16, size * 0.4, m("orange")), Vector3(0, size * 0.85, size * 0.95))
	put(d, "Tail", cyl(0.0, size * 0.3, size * 0.5, m(color), 8), Vector3(0, size * 0.55, -size * 0.95), Vector3(-50, 0, 0))
	put(d, "WingL", sph(size * 0.4, m(color), true, 10), Vector3(-size * 0.88, 0.0, 0), Vector3(0, 0, 90))
	put(d, "WingR", sph(size * 0.4, m(color), true, 10), Vector3(size * 0.88, 0.0, 0), Vector3(0, 0, -90))
	eyes(d, Vector3(0, size * 1.1, size * 0.72), size * 0.22, size * 0.13)
	return d


# ---------------------------------------------------------------- forlystelser

func _build_bouncy_castle() -> void:
	base_plate(1.9, 1.9, "green")
	var c := osc(_root, "Castle", Vector3(0, 0.1, 0), 0, 1, 0.06, 5.0)
	put(c, "Floor", box(1.6, 0.3, 1.6, m("blue")), Vector3(0, 0.15, 0))
	for i in 4:
		var x := -0.75 if i % 2 == 0 else 0.75
		var z := -0.75 if i < 2 else 0.75
		put(c, "Tower%d" % i, cyl(0.2, 0.22, 0.9, m("red" if i % 2 == 0 else "yellow")), Vector3(x, 0.6, z))
		put(c, "TowerCap%d" % i, sph(0.22, m("yellow" if i % 2 == 0 else "red"), true), Vector3(x, 1.05, z))
	put(c, "WallBack", box(1.3, 0.5, 0.18, m("red")), Vector3(0, 0.55, -0.72))
	put(c, "WallL", box(0.18, 0.5, 1.3, m("yellow")), Vector3(-0.72, 0.55, 0))
	put(c, "WallR", box(0.18, 0.5, 1.3, m("yellow")), Vector3(0.72, 0.55, 0))
	put(c, "Arch", torus(0.3, 0.42, m("red"), 16, 6), Vector3(0, 0.3, 0.75), Vector3(90, 0, 0))
	put(c, "Keep", cyl(0.3, 0.34, 0.8, m("pink")), Vector3(0, 0.7, -0.45))
	put(c, "KeepRim", torus(0.26, 0.38, m("yellow"), 16, 6), Vector3(0, 1.1, -0.45))
	var t := node(c, "Theme", Vector3(0, 1.38, -0.45))
	duck(t, "Duck", Vector3.ZERO, 0.32)


func _build_teacups() -> void:
	put(_root, "Base", cyl(1.45, 1.45, 0.1, m("cream"), 24), Vector3(0, 0.05, 0))
	var plat := spinner(_root, "Platter", Vector3(0, 0.1, 0), 0.5)
	put(plat, "Disc", cyl(1.38, 1.38, 0.08, m("pink"), 24), Vector3(0, 0.04, 0))
	var cols := ["blue", "yellow", "mint", "red"]
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI / 4.0
		var cup := spinner(plat, "Cup%d" % i, Vector3(cos(a) * 0.95, 0.08, sin(a) * 0.95), 1.6 if i % 2 == 0 else -1.3)
		put(cup, "Bowl", cyl(0.36, 0.26, 0.36, m(cols[i])), Vector3(0, 0.18, 0))
		put(cup, "Rim", torus(0.32, 0.4, m("white"), 16, 6), Vector3(0, 0.36, 0))
		put(cup, "Handle", torus(0.07, 0.13, m(cols[i]), 12, 6), Vector3(0.4, 0.2, 0), Vector3(90, 0, 0))
		put(cup, "Seat", cyl(0.22, 0.22, 0.1, m("white")), Vector3(0, 0.2, 0))
	var t := node(_root, "Theme", Vector3(0, 0.1, 0))
	put(t, "Foot", cyl(0.32, 0.38, 0.2, m("blue")), Vector3(0, 0.1, 0))
	put(t, "Pot", sph(0.55, m("white"), false, 18), Vector3(0, 0.72, 0))
	put(t, "Band", torus(0.5, 0.58, m("blue"), 18, 6), Vector3(0, 0.72, 0))
	put(t, "Spout", cyl(0.07, 0.14, 0.6, m("white"), 10), Vector3(0.62, 0.92, 0), Vector3(0, 0, -50))
	put(t, "Handle", torus(0.18, 0.26, m("white"), 14, 6), Vector3(-0.6, 0.78, 0), Vector3(90, 0, 0))
	var lid := osc(t, "Lid", Vector3(0, 1.2, 0), 0, 1, 0.18, 2.5)
	put(lid, "Cap", cyl(0.22, 0.34, 0.1, m("blue")), Vector3(0, 0.05, 0))
	put(lid, "Knob", sph(0.08, m("gold"), false, 10), Vector3(0, 0.16, 0))
	put(t, "Steam", sph(0.1, m("white"), false, 8), Vector3(0.95, 1.25, 0))


func _build_trampoline() -> void:
	base_plate(1.9, 1.9, "green")
	for i in 3:
		var x := -0.55 + 0.55 * float(i)
		var z := -0.4 if i != 1 else -0.15
		var tr := node(_root, "Tramp%d" % i, Vector3(x, 0.0, z))
		put(tr, "Frame", torus(0.24, 0.3, m("blue"), 16, 6), Vector3(0, 0.3, 0))
		put(tr, "Bed", cyl(0.25, 0.25, 0.02, m("dark")), Vector3(0, 0.3, 0))
		for k in 3:
			var a := TAU * float(k) / 3.0
			put(tr, "Leg%d" % k, cyl(0.02, 0.02, 0.3, m("grey"), 6), Vector3(cos(a) * 0.27, 0.15, sin(a) * 0.27))
		var j := osc(tr, "Jumper", Vector3(0, 0.32, 0), 0, 1, 0.45, 4.0 + float(i) * 0.4, Vector3.UP, float(i) * 1.1)
		put(j, "Body", cyl(0.06, 0.08, 0.22, m(["red", "yellow", "purple"][i]), 8), Vector3(0, 0.11, 0))
		put(j, "Head", sph(0.07, m("cream"), false, 8), Vector3(0, 0.29, 0))
	# Tema: kæmpe spiralfjeder som indgangsbue.
	var t := node(_root, "Theme", Vector3(0, 0.1, 0.62))
	for s: float in [-1.0, 1.0]:
		for k in 6:
			put(t, "Coil%s%d" % ["L" if s < 0 else "R", k], torus(0.11, 0.17, m("red"), 10, 6),
				Vector3(0.72 * s, 0.1 + 0.17 * float(k), 0), Vector3(0, 0, 8.0 * (1 if k % 2 == 0 else -1)))
	for k in 9:
		put(t, "Top%d" % k, torus(0.11, 0.17, m("yellow"), 10, 6), Vector3(-0.68 + 0.17 * float(k), 1.15, 0), Vector3(8.0 * (1 if k % 2 == 0 else -1), 0, 90))
	put(t, "PadL", cyl(0.2, 0.2, 0.08, m("dark")), Vector3(-0.72, 0.0, 0))
	put(t, "PadR", cyl(0.2, 0.2, 0.08, m("dark")), Vector3(0.72, 0.0, 0))


func _build_sky_rings() -> void:
	base_plate(1.9, 1.9, "grey")
	put(_root, "Pad", cyl(0.6, 0.7, 0.12, m("dark")), Vector3(0, 0.16, 0))
	for s: float in [-1.0, 1.0]:
		put(_root, "Post" + ("L" if s < 0 else "R"), cyl(0.07, 0.1, 2.3, m("white")), Vector3(0.88 * s, 1.15, 0))
	put(_root, "Beam", box(1.9, 0.16, 0.16, m("purple")), Vector3(0, 2.3, 0))
	var outer := spinner(_root, "Outer", Vector3(0, 1.25, 0), 1.1, Vector3(1, 0, 0))
	put(outer, "AxleL", cyl(0.04, 0.04, 0.2, m("grey"), 6), Vector3(-0.78, 0, 0), Vector3(0, 0, 90))
	put(outer, "AxleR", cyl(0.04, 0.04, 0.2, m("grey"), 6), Vector3(0.78, 0, 0), Vector3(0, 0, 90))
	put(outer, "Ring", torus(0.62, 0.7, m("yellow"), 24, 6), Vector3.ZERO, Vector3(0, 0, 90))
	var inner := spinner(outer, "Inner", Vector3.ZERO, 1.7, Vector3(0, 0, 1))
	put(inner, "Ring", torus(0.48, 0.56, m("red"), 24, 6), Vector3.ZERO, Vector3(90, 0, 0))
	put(inner, "Pod", sph(0.22, m("sky")), Vector3.ZERO)
	put(inner, "Rider", sph(0.09, m("cream"), false, 8), Vector3(0, 0.16, 0.12))
	# Tema: kæmpe planet med ring over portalen.
	var t := node(_root, "Theme", Vector3(0, 2.38, 0))
	put(t, "Mast", cyl(0.05, 0.08, 0.35, m("white"), 8), Vector3(0, 0.17, 0))
	var p := spinner(t, "Planet", Vector3(0, 0.82, 0), 0.4)
	put(p, "Globe", sph(0.48, m("purple"), false, 18), Vector3.ZERO)
	put(p, "Ring", torus(0.62, 0.82, m("gold"), 24, 4), Vector3.ZERO, Vector3(20, 0, 12))
	put(p, "Crater1", sph(0.1, m("pink"), true, 8), Vector3(0.0, 0.2, 0.43), Vector3(65, 0, 0))
	put(p, "Crater2", sph(0.07, m("pink"), true, 8), Vector3(-0.3, -0.15, 0.32), Vector3(70, 0, 40))
	put(p, "Moon", sph(0.11, m("cream"), false, 10), Vector3(0.75, 0.35, -0.2))


func _build_pirate_ship() -> void:
	base_plate(3.9, 1.9, "brown")
	var pivot_y := 3.0
	for s: float in [-1.0, 1.0]:
		var z := 0.82 * s
		var tag := "F" if s > 0 else "B"
		stick(_root, "Leg%sL" % tag, Vector3(-1.2, 0.1, z), Vector3(0, pivot_y, z), 0.07, m("brown", PLANKS), 8)
		stick(_root, "Leg%sR" % tag, Vector3(1.2, 0.1, z), Vector3(0, pivot_y, z), 0.07, m("brown", PLANKS), 8)
	put(_root, "Axle", cyl(0.07, 0.07, 1.8, m("grey"), 8), Vector3(0, pivot_y, 0), Vector3(90, 0, 0))
	var sw := osc(_root, "Swing", Vector3(0, pivot_y, 0), 1, 0, deg_to_rad(26.0), 1.4, Vector3(0, 0, 1))
	var arm := 2.25
	for z: float in [-0.42, 0.42]:
		put(sw, "Arm%s" % ("B" if z < 0 else "F"), box(0.08, arm, 0.08, m("red")), Vector3(0, -arm * 0.5, z))
	var hy := -arm
	put(sw, "Hull", box(2.2, 0.42, 0.8, m("brown", PLANKS)), Vector3(0, hy, 0))
	put(sw, "Keel", prism(2.0, 0.22, 0.6, m("brown", PLANKS)), Vector3(0, hy - 0.32, 0), Vector3(180, 0, 0))
	put(sw, "Bow", box(0.4, 0.4, 0.8, m("brown", PLANKS)), Vector3(1.15, hy + 0.12, 0), Vector3(0, 0, 25))
	put(sw, "Stern", box(0.45, 0.5, 0.8, m("brown", PLANKS)), Vector3(-1.12, hy + 0.2, 0), Vector3(0, 0, -15))
	put(sw, "Stripe", box(2.24, 0.08, 0.82, m("gold")), Vector3(0, hy + 0.12, 0))
	for i in 4:
		put(sw, "Bench%d" % i, box(0.08, 0.12, 0.7, m("red")), Vector3(-0.75 + 0.5 * float(i), hy + 0.27, 0))
	# Tema: dødningehoved-flag og blæksprutte om masten.
	var t := node(sw, "Theme", Vector3(0, hy + 0.21, 0))
	put(t, "Mast", cyl(0.05, 0.06, 1.5, m("brown", PLANKS), 8), Vector3(0.0, 0.75, 0.0))
	put(t, "Flag", box(0.55, 0.36, 0.02, m("black")), Vector3(0.3, 1.32, 0.0))
	put(t, "Skull", sph(0.08, m("white"), false, 10), Vector3(0.3, 1.36, 0.02))
	put(t, "BoneA", box(0.26, 0.04, 0.02, m("white")), Vector3(0.3, 1.24, 0.02), Vector3(0, 0, 35))
	put(t, "BoneB", box(0.26, 0.04, 0.02, m("white")), Vector3(0.3, 1.24, 0.02), Vector3(0, 0, -35))
	put(t, "OctoHead", sph(0.3, m("purple"), false, 14), Vector3(0, 0.35, 0))
	eyes(t, Vector3(0, 0.42, 0.22), 0.11, 0.08, "OctoEye")
	for k in 4:
		put(t, "Tentacle%d" % k, torus(0.07, 0.13, m("purple"), 12, 6), Vector3(0, 0.7 + 0.18 * float(k), 0),
			Vector3(12.0 * (1 if k % 2 == 0 else -1), 0, 10.0 * (1 if k < 2 else -1)))
	for k in 2:
		var s := -1.0 if k == 0 else 1.0
		put(t, "Curl%d" % k, torus(0.06, 0.12, m("purple"), 12, 6), Vector3(0.4 * s, 0.15, 0.36), Vector3(90, 0, 0))


func _build_space_rocket() -> void:
	put(_root, "Base", cyl(1.45, 1.45, 0.12, m("dark"), 24), Vector3(0, 0.06, 0))
	put(_root, "Pad", cyl(0.6, 0.7, 0.3, m("grey")), Vector3(0, 0.25, 0))
	var arms := spinner(_root, "Arms", Vector3(0, 0.95, 0), 1.0)
	put(arms, "Hub", cyl(0.48, 0.48, 0.14, m("yellow")), Vector3.ZERO)
	var cols := ["red", "blue", "mint", "orange"]
	for i in 4:
		var a := TAU * float(i) / 4.0
		var arm := node(arms, "Arm%d" % i, Vector3.ZERO, Vector3(0, rad_to_deg(a), 0))
		put(arm, "Bar", box(0.9, 0.08, 0.08, m("grey")), Vector3(0.9, 0, 0))
		put(arm, "Car", cyl(0.17, 0.17, 0.5, m(cols[i])), Vector3(1.22, 0.05, 0), Vector3(90, 0, 0))
		put(arm, "Nose", cyl(0.0, 0.17, 0.26, m("white")), Vector3(1.22, 0.05, -0.38), Vector3(-90, 0, 0))
		put(arm, "Seat", sph(0.08, m("cream"), false, 8), Vector3(1.22, 0.25, 0))
	# Tema: høj tegneserieraket med flammer af plaster-kegler.
	var t := node(_root, "Theme", Vector3(0, 0.4, 0))
	put(t, "Body", cyl(0.34, 0.34, 2.0, m("white"), 18), Vector3(0, 1.6, 0))
	put(t, "Nose", cyl(0.0, 0.34, 0.75, m("red"), 18), Vector3(0, 2.97, 0))
	put(t, "Band", torus(0.32, 0.38, m("red"), 18, 6), Vector3(0, 2.3, 0))
	put(t, "Window", cyl(0.14, 0.14, 0.06, m("sky"), 12), Vector3(0, 2.0, 0.33), Vector3(90, 0, 0))
	put(t, "WindowRim", torus(0.13, 0.18, m("gold"), 12, 6), Vector3(0, 2.0, 0.34), Vector3(90, 0, 0))
	for k in 3:
		var a := TAU * float(k) / 3.0 + PI / 6.0
		var fin := node(t, "FinMount%d" % k, Vector3(0, 0.85, 0), Vector3(0, rad_to_deg(a), 0))
		put(fin, "Fin", prism(0.5, 0.7, 0.06, m("red")), Vector3(0.45, 0.0, 0), Vector3(0, 0, 0))
	var fl := osc(t, "Flames", Vector3(0, 0.6, 0), 0, 0, 0.04, 14.0)
	put(fl, "FlameOuter", cyl(0.3, 0.0, 0.55, m("orange"), 12), Vector3(0, -0.05, 0))
	put(fl, "FlameInner", cyl(0.17, 0.0, 0.4, m("yellow"), 10), Vector3(0, 0.0, 0))


func _build_drop_tower() -> void:
	base_plate(1.9, 1.9, "grey")
	put(_root, "Pad", cyl(0.75, 0.85, 0.15, m("dark")), Vector3(0, 0.17, 0))
	var g := osc(_root, "Gondola", Vector3(0, 1.15, 0), 0, 2, 3.4, 0.9)
	put(g, "Ring", torus(0.3, 0.62, m("blue"), 20, 6), Vector3.ZERO)
	for k in 6:
		var a := TAU * float(k) / 6.0
		var seat := node(g, "Seat%d" % k, Vector3(cos(a) * 0.55, 0.0, sin(a) * 0.55), Vector3(0, -rad_to_deg(a) + 90, 0))
		put(seat, "Back", box(0.22, 0.32, 0.06, m("yellow")), Vector3(0, 0.12, -0.08))
		put(seat, "Rider", sph(0.08, m("cream"), false, 8), Vector3(0, 0.3, 0))
	# Tema: tårnet er et kæmpe termometer med "kogepunkt" på toppen.
	var t := node(_root, "Theme", Vector3(0, 0.25, 0))
	put(t, "Bulb", sph(0.42, m("red"), false, 16), Vector3(0, 0.4, 0))
	put(t, "TubeLow", cyl(0.24, 0.24, 2.6, m("white"), 14), Vector3(0, 2.0, 0))
	put(t, "TubeHigh", cyl(0.24, 0.24, 2.6, m("white"), 14), Vector3(0, 4.6, 0))
	put(t, "Cap", sph(0.24, m("white"), true, 14), Vector3(0, 5.9, 0))
	put(t, "MercuryLow", box(0.12, 2.6, 0.06, m("red")), Vector3(0, 2.0, 0.23))
	put(t, "MercuryHigh", box(0.12, 2.0, 0.06, m("red")), Vector3(0, 4.3, 0.23))
	for k in 8:
		put(t, "Tick%d" % k, box(0.3 if k % 2 == 0 else 0.18, 0.04, 0.04, m("dark")), Vector3(0.0, 1.2 + 0.6 * float(k), 0.26))
	put(t, "Sign", box(0.8, 0.32, 0.06, m("yellow")), Vector3(0, 5.55, 0.3))
	put(t, "SignStar", cyl(0.12, 0.12, 0.04, m("red"), 5), Vector3(-0.25, 5.55, 0.34), Vector3(90, 0, 0))
	put(t, "Steam1", sph(0.13, m("white"), false, 8), Vector3(0.12, 6.15, 0))
	put(t, "Steam2", sph(0.09, m("white"), false, 8), Vector3(-0.08, 6.32, 0.05))


# ---------------------------------------------------------------- butikker

## Lille bod (1×1) med disk og markise, til at bære et tema-element.
func kiosk(color: String, stripe: String) -> void:
	put(_root, "Base", box(0.9, 0.08, 0.9, m("grey")), Vector3(0, 0.04, 0))
	put(_root, "Booth", box(0.78, 0.62, 0.62, m(color)), Vector3(0, 0.39, -0.08))
	put(_root, "Counter", box(0.82, 0.08, 0.2, m("brown", PLANKS)), Vector3(0, 0.55, 0.3))
	put(_root, "Awning", box(0.86, 0.06, 0.3, m(stripe, CANVAS)), Vector3(0, 0.82, 0.3), Vector3(-18, 0, 0))
	put(_root, "Roof", box(0.84, 0.08, 0.68, m(stripe, CANVAS)), Vector3(0, 0.74, -0.08))


func _build_fries_stand() -> void:
	kiosk("red", "yellow")
	var t := node(_root, "Theme", Vector3(0, 0.78, -0.08))
	put(t, "Cup", cyl(0.3, 0.22, 0.5, m("red"), 14), Vector3(0, 0.25, 0))
	put(t, "Band", torus(0.25, 0.31, m("white"), 14, 4), Vector3(0, 0.28, 0))
	put(t, "Logo", cyl(0.09, 0.09, 0.03, m("yellow"), 10), Vector3(0, 0.25, 0.27), Vector3(80, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 83
	for k in 11:
		var a := TAU * float(k) / 7.0
		var r := 0.0 if k == 0 else (0.12 if k < 8 else 0.05)
		var h := rng.randf_range(0.4, 0.6)
		put(t, "Fry%d" % k, box(0.06, h, 0.06, m("yellow")), Vector3(cos(a) * r, 0.5 + h * 0.3, sin(a) * r),
			Vector3(rng.randf_range(-12, 12), rng.randf_range(0, 90), rng.randf_range(-12, 12)))


func _build_coffee_stand() -> void:
	put(_root, "Saucer", cyl(0.47, 0.42, 0.07, m("white"), 20), Vector3(0, 0.035, 0))
	put(_root, "Cup", cyl(0.42, 0.32, 0.72, m("white"), 20), Vector3(0, 0.43, 0))
	put(_root, "Hatch", box(0.4, 0.26, 0.1, m("dark")), Vector3(0, 0.48, 0.36), Vector3(-7, 0, 0))
	put(_root, "Counter", box(0.5, 0.06, 0.18, m("brown", PLANKS)), Vector3(0, 0.36, 0.42))
	var t := node(_root, "Theme", Vector3(0, 0.0, 0))
	put(t, "Rim", torus(0.38, 0.44, m("red"), 20, 6), Vector3(0, 0.79, 0))
	put(t, "Coffee", cyl(0.39, 0.39, 0.03, m("coffee"), 20), Vector3(0, 0.76, 0))
	put(t, "Handle", torus(0.1, 0.17, m("white"), 12, 6), Vector3(0.42, 0.45, 0), Vector3(90, 0, 0))
	put(t, "Stripe", torus(0.35, 0.4, m("red"), 20, 4), Vector3(0, 0.2, 0))
	for k in 3:
		var s := osc(t, "Steam%d" % k, Vector3(-0.12 + 0.12 * float(k), 0.98 + 0.22 * float(k), 0.0), 0, 0, 0.06, 2.2, Vector3.UP, float(k))
		put(s, "Puff", sph(0.13 - 0.02 * float(k), m("white"), false, 10), Vector3.ZERO)


func _build_balloon_stand() -> void:
	put(_root, "Base", box(0.9, 0.08, 0.9, m("grey")), Vector3(0, 0.04, 0))
	put(_root, "Cart", box(0.6, 0.35, 0.4, m("teal")), Vector3(0, 0.42, 0.05))
	put(_root, "CartTop", box(0.64, 0.05, 0.44, m("white")), Vector3(0, 0.62, 0.05))
	for s: float in [-1.0, 1.0]:
		put(_root, "Wheel" + ("L" if s < 0 else "R"), cyl(0.16, 0.16, 0.06, m("dark"), 12), Vector3(0.33 * s, 0.2, 0.05), Vector3(0, 0, 90))
	var t := osc(_root, "Theme", Vector3(0, 0.64, 0.05), 1, 0, deg_to_rad(5.0), 1.3, Vector3(0, 0, 1))
	var cols := ["red", "yellow", "blue", "pink", "mint", "purple", "orange"]
	var pts := [Vector3(0, 1.25, 0), Vector3(-0.25, 1.05, 0.05), Vector3(0.26, 1.08, -0.05), Vector3(-0.12, 0.88, -0.22),
		Vector3(0.14, 0.9, 0.22), Vector3(-0.28, 0.8, 0.22), Vector3(0.3, 0.78, -0.24)]
	for i in pts.size():
		var p: Vector3 = pts[i]
		put(t, "Balloon%d" % i, sph(0.17, m(cols[i]), false, 12), p)
		put(t, "Knot%d" % i, cyl(0.0, 0.04, 0.06, m(cols[i]), 6), p + Vector3(0, -0.19, 0))
		stick(t, "String%d" % i, Vector3(0, 0.02, 0), p + Vector3(0, -0.21, 0), 0.008, m("white"), 4)


func _build_souvenir_shop() -> void:
	put(_root, "Base", box(1.9, 0.08, 0.9, m("grey")), Vector3(0, 0.04, 0))
	put(_root, "Hut", box(1.7, 0.7, 0.6, m("cream")), Vector3(0, 0.43, -0.1))
	put(_root, "Roof", prism(0.8, 0.35, 1.84, m("blue", CANVAS)), Vector3(0, 0.955, -0.1), Vector3(0, 90, 0))
	put(_root, "Counter", box(1.4, 0.08, 0.2, m("brown", PLANKS)), Vector3(0, 0.5, 0.28))
	put(_root, "Window", box(1.2, 0.3, 0.02, m("dark")), Vector3(0, 0.6, 0.21))
	for k in 4:
		put(_root, "Goods%d" % k, box(0.14, 0.14, 0.12, m(["red", "yellow", "mint", "pink"][k])), Vector3(-0.45 + 0.3 * float(k), 0.61, 0.28))
	# Tema: kæmpe snekugle med parken i (på taget, ved siden af rygningen).
	var t := node(_root, "Theme", Vector3(0, 1.08, -0.1))
	put(t, "Stand", cyl(0.24, 0.3, 0.2, m("brown", PLANKS), 16), Vector3(0, 0.1, 0))
	put(t, "Ground", cyl(0.27, 0.27, 0.04, m("white"), 16), Vector3(0, 0.22, 0))
	put(t, "Globe", sph(0.32, glass(), false, 18), Vector3(0, 0.45, 0))
	put(t, "MiniWheel", torus(0.1, 0.13, m("red"), 12, 4), Vector3(-0.07, 0.43, 0), Vector3(90, 0, 0))
	put(t, "MiniTree", cyl(0.0, 0.07, 0.2, m("green"), 8), Vector3(0.12, 0.34, 0.03))
	put(t, "MiniTent", cyl(0.0, 0.08, 0.1, m("yellow"), 6), Vector3(0.05, 0.29, -0.12))
	for k in 4:
		var a := TAU * float(k) / 4.0
		put(t, "Flake%d" % k, sph(0.025, m("white"), false, 6), Vector3(cos(a) * 0.18, 0.55 + 0.05 * float(k % 2), sin(a) * 0.18))


## Sideshow-bod 2×1 med bagvæg, disk og stribet tag.
func stall(color: String, stripe: String) -> void:
	put(_root, "Base", box(1.9, 0.08, 0.9, m("grey")), Vector3(0, 0.04, 0))
	put(_root, "BackWall", box(1.8, 1.0, 0.1, m(color)), Vector3(0, 0.58, -0.38))
	put(_root, "SideL", box(0.1, 1.0, 0.7, m(color)), Vector3(-0.85, 0.58, -0.05))
	put(_root, "SideR", box(0.1, 1.0, 0.7, m(color)), Vector3(0.85, 0.58, -0.05))
	put(_root, "Counter", box(1.6, 0.42, 0.14, m("brown", PLANKS)), Vector3(0, 0.29, 0.3))
	put(_root, "Roof", box(1.9, 0.08, 0.86, m(stripe, CANVAS)), Vector3(0, 1.12, -0.02))
	for k in 5:
		put(_root, "Scallop%d" % k, sph(0.17, m(stripe if k % 2 == 0 else "white", CANVAS), true, 10), Vector3(-0.72 + 0.36 * float(k), 1.08, 0.4), Vector3(180, 0, 0))


func _build_coconut_shy() -> void:
	stall("green", "yellow")
	for k in 3:
		var x := -0.5 + 0.5 * float(k)
		put(_root, "Post%d" % k, cyl(0.03, 0.03, 0.4, m("brown", PLANKS), 6), Vector3(x, 0.28, -0.1))
		put(_root, "Nut%d" % k, sph(0.09, m("brown"), false, 10), Vector3(x, 0.55, -0.1))
	# Tema: tre kæmpe kokosnødder på pinde over taget.
	var t := node(_root, "Theme", Vector3(0, 1.16, -0.1))
	for k in 3:
		var x := -0.6 + 0.6 * float(k)
		var h := 0.45 if k == 1 else 0.3
		put(t, "Stick%d" % k, cyl(0.04, 0.05, h, m("brown", PLANKS), 8), Vector3(x, h * 0.5, 0))
		put(t, "Coconut%d" % k, sph(0.24, m("brown"), false, 14), Vector3(x, h + 0.2, 0))
		for e in 3:
			var a := -0.5 + 0.5 * float(e)
			put(t, "Dot%d_%d" % [k, e], sph(0.04, m("dark"), false, 6), Vector3(x + a * 0.16, h + 0.32 - absf(a) * 0.08, 0.2))
	put(t, "Ball", sph(0.1, m("red"), false, 10), Vector3(0.95, 0.1, 0.25))


func _build_shooting_gallery() -> void:
	stall("red", "red")
	put(_root, "Stripe1", box(0.3, 1.0, 0.02, m("white", CANVAS)), Vector3(-0.45, 0.58, -0.32))
	put(_root, "Stripe2", box(0.3, 1.0, 0.02, m("white", CANVAS)), Vector3(0.45, 0.58, -0.32))
	var rail := osc(_root, "Targets", Vector3(0, 0.72, -0.25), 0, 0, 0.45, 1.2, Vector3(1, 0, 0))
	for k in 3:
		var d := node(rail, "TinDuck%d" % k, Vector3(-0.4 + 0.4 * float(k), 0, 0))
		put(d, "Body", cyl(0.1, 0.1, 0.03, m("gold"), 10), Vector3.ZERO, Vector3(90, 0, 0))
		put(d, "Head", cyl(0.06, 0.06, 0.03, m("gold"), 10), Vector3(0.08, 0.1, 0), Vector3(90, 0, 0))
	put(_root, "Rifle", box(0.5, 0.05, 0.06, m("dark")), Vector3(0.3, 0.55, 0.3), Vector3(0, 70, 0))
	# Tema: stribet telt-top med kæmpe blikand.
	put(_root, "TentTop", cyl(0.0, 0.5, 0.45, m("red", CANVAS), 8), Vector3(0, 1.38, -0.02))
	var t := node(_root, "Theme", Vector3(0, 1.58, 0.0))
	put(t, "Stand", box(0.08, 0.3, 0.08, m("grey", METAL)), Vector3(0, 0.15, 0))
	put(t, "Body", cyl(0.36, 0.36, 0.08, m("gold", METAL), 20), Vector3(0, 0.55, 0), Vector3(90, 0, 0))
	put(t, "Head", cyl(0.2, 0.2, 0.08, m("gold", METAL), 16), Vector3(0.3, 0.9, 0), Vector3(90, 0, 0))
	put(t, "Beak", prism(0.2, 0.14, 0.08, m("orange")), Vector3(0.55, 0.9, 0), Vector3(0, 0, -90))
	put(t, "Eye", cyl(0.05, 0.05, 0.1, m("black"), 8), Vector3(0.36, 0.95, 0), Vector3(90, 0, 0))
	put(t, "Target", torus(0.12, 0.2, m("red"), 16, 4), Vector3(-0.05, 0.55, 0.05), Vector3(90, 0, 0))
	put(t, "Bull", cyl(0.07, 0.07, 0.1, m("white"), 10), Vector3(-0.05, 0.55, 0.0), Vector3(90, 0, 0))
	put(t, "Wing", prism(0.32, 0.2, 0.1, m("orange", METAL)), Vector3(-0.22, 0.75, 0), Vector3(0, 0, 30))


func _build_hook_a_duck() -> void:
	put(_root, "Base", box(0.9, 0.08, 0.9, m("grey")), Vector3(0, 0.04, 0))
	put(_root, "Pool", cyl(0.42, 0.44, 0.3, m("red"), 20), Vector3(0, 0.23, 0))
	put(_root, "Water", cyl(0.37, 0.37, 0.02, m("sky"), 20), Vector3(0, 0.36, 0))
	put(_root, "Pole", cyl(0.04, 0.04, 0.85, m("white"), 8), Vector3(0, 0.79, 0))
	put(_root, "Canopy", cyl(0.0, 0.48, 0.25, m("yellow", CANVAS), 10), Vector3(0, 1.3, 0))
	var ducks := spinner(_root, "Ducks", Vector3(0, 0.38, 0), 0.7)
	for k in 5:
		var a := TAU * float(k) / 5.0
		var d := node(ducks, "Duck%d" % k, Vector3(cos(a) * 0.27, 0, sin(a) * 0.27), Vector3(0, -rad_to_deg(a), 0))
		put(d, "Body", sph(0.05, m("yellow"), false, 8), Vector3.ZERO)
		put(d, "Head", sph(0.035, m("yellow"), false, 6), Vector3(0, 0.05, 0.03))
	# Tema: kæmpe gul and med fiskestang på taget.
	var t := node(_root, "Theme", Vector3(0, 1.44, 0))
	duck(t, "Duck", Vector3(0, 0.12, 0), 0.22)
	stick(t, "Rod", Vector3(0.15, 0.15, 0.15), Vector3(0.38, 0.55, 0.38), 0.015, m("brown", PLANKS), 6)
	stick(t, "Line", Vector3(0.38, 0.55, 0.38), Vector3(0.38, 0.0, 0.38), 0.005, m("white"), 4)
	put(t, "Hook", torus(0.02, 0.035, m("grey"), 8, 4), Vector3(0.38, -0.02, 0.38), Vector3(90, 0, 0))


func _build_strength_tester() -> void:
	put(_root, "Base", box(0.9, 0.08, 0.9, m("grey")), Vector3(0, 0.04, 0))
	put(_root, "Pad", box(0.34, 0.12, 0.34, m("dark")), Vector3(0, 0.14, 0.2))
	put(_root, "Board", box(0.36, 2.6, 0.1, m("red")), Vector3(0, 1.38, -0.2))
	put(_root, "Rail", box(0.06, 2.5, 0.04, m("grey", METAL)), Vector3(0, 1.38, -0.13))
	var puck := osc(_root, "Puck", Vector3(0, 0.25, -0.1), 0, 3, 2.25, 1.4)
	put(puck, "Body", cyl(0.07, 0.07, 0.1, m("yellow"), 10), Vector3.ZERO)
	# Tema: høj skala med kæmpe klokke og hammer.
	var t := node(_root, "Theme", Vector3(0, 0, 0))
	for k in 6:
		put(t, "Mark%d" % k, box(0.28 if k % 2 == 0 else 0.18, 0.06, 0.02, m(["green", "yellow", "orange", "red", "purple", "gold"][k])),
			Vector3(0, 0.45 + 0.4 * float(k), -0.14))
	put(t, "Bell", cyl(0.06, 0.26, 0.3, m("gold", METAL), 16), Vector3(0, 2.86, -0.18))
	put(t, "BellLip", torus(0.22, 0.29, m("gold", METAL), 16, 4), Vector3(0, 2.71, -0.18))
	put(t, "BellKnob", sph(0.07, m("gold", METAL), false, 8), Vector3(0, 3.04, -0.18))
	put(t, "HammerHandle", cyl(0.025, 0.025, 0.7, m("brown", PLANKS), 6), Vector3(0.3, 0.42, 0.25), Vector3(0, 0, 25))
	put(t, "HammerHead", cyl(0.1, 0.1, 0.3, m("dark"), 12), Vector3(0.15, 0.75, 0.25), Vector3(0, 0, 90 + 25))
