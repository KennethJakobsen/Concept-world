extends SceneTree
## T-083/T-099: Genererer M6-props (15 bygninger) som .tscn i res://scenes/props/.
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
const TREAD := preload("res://assets/textures/tread.png")
const PANEL := preload("res://assets/textures/panel.png")
const ROOF := preload("res://assets/textures/roof_tiles.png")
const BRICK := preload("res://assets/textures/brick.png")
const COBBLE := preload("res://assets/textures/cobble.png")

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


## Delt materiale fra res://assets/materials (samme som M4/M5-props: træ, metal, tagsten osv.).
func lib(nm: String) -> Material:
	var key := "lib_" + nm
	if not _mats.has(key):
		_mats[key] = load("res://assets/materials/%s.tres" % nm)
	return _mats[key]


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


# ---------------------------------------------------------------- fælles detaljer (T-099)

## Gulvplade med kantsten rundt om (som M4-props' fundamenter).
func deck(w: float, d: float, top: Material, kerb: Material) -> void:
	put(_root, "Base", box(w, 0.1, d, top), Vector3(0, 0.05, 0))
	put(_root, "KerbF", box(w, 0.14, 0.06, kerb), Vector3(0, 0.07, d * 0.5 - 0.03))
	put(_root, "KerbB", box(w, 0.14, 0.06, kerb), Vector3(0, 0.07, -d * 0.5 + 0.03))
	put(_root, "KerbL", box(0.06, 0.14, d - 0.12, kerb), Vector3(-w * 0.5 + 0.03, 0.07, 0))
	put(_root, "KerbR", box(0.06, 0.14, d - 0.12, kerb), Vector3(w * 0.5 - 0.03, 0.07, 0))


## Rundt fundament med kantring.
func round_deck(r: float, top: Material, kerb: Material) -> void:
	put(_root, "Base", cyl(r, r, 0.1, top, 28), Vector3(0, 0.05, 0))
	put(_root, "Kerb", torus(r - 0.06, r, kerb, 28, 6), Vector3(0, 0.1, 0))


## Hegn langs et rektangel (sider + bagside + forside med åbning `gap` på midten).
func fence_rect(w: float, d: float, gap: float, post_mat: Material, rail_mat: Material, h: float = 0.32,
		sides: Array = ["F", "B", "L", "R"]) -> void:
	var f := node(_root, "Fence")
	var hw := w * 0.5 - 0.05
	var hd := d * 0.5 - 0.05
	var segs: Array = []
	if "B" in sides: segs.append([Vector3(-hw, 0, -hd), Vector3(hw, 0, -hd)])
	if "L" in sides: segs.append([Vector3(-hw, 0, -hd), Vector3(-hw, 0, hd)])
	if "R" in sides: segs.append([Vector3(hw, 0, -hd), Vector3(hw, 0, hd)])
	if "F" in sides:
		segs.append([Vector3(-hw, 0, hd), Vector3(-gap * 0.5, 0, hd)])
		segs.append([Vector3(gap * 0.5, 0, hd), Vector3(hw, 0, hd)])
	var k := 0
	for sg: Array in segs:
		var a: Vector3 = sg[0]
		var b: Vector3 = sg[1]
		var n := maxi(1, ceili(a.distance_to(b) / 0.4))
		for i in n + 1:
			var p := a.lerp(b, float(i) / float(n))
			put(f, "Post%d" % k, box(0.05, h, 0.05, post_mat), p + Vector3(0, 0.1 + h * 0.5, 0))
			put(f, "Cap%d" % k, sph(0.035, post_mat, false, 6), p + Vector3(0, 0.1 + h + 0.02, 0))
			k += 1
		stick(f, "RailTop%d" % k, a + Vector3(0, 0.1 + h * 0.85, 0), b + Vector3(0, 0.1 + h * 0.85, 0), 0.018, rail_mat)
		stick(f, "RailLow%d" % k, a + Vector3(0, 0.1 + h * 0.4, 0), b + Vector3(0, 0.1 + h * 0.4, 0), 0.018, rail_mat)


## Indgangsportal med skilt (stolper, skiltebræt med ramme og "bogstaver", små flag).
func gate(pos: Vector3, w: float, board: String, letters: String, h: float = 0.9) -> void:
	var g := node(_root, "Gate", pos)
	for s: float in [-1.0, 1.0]:
		var tag := "L" if s < 0 else "R"
		put(g, "Post" + tag, box(0.07, h, 0.07, lib("wood_dark")), Vector3(w * 0.5 * s, h * 0.5, 0))
		put(g, "PostCap" + tag, sph(0.06, m("gold", METAL), false, 8), Vector3(w * 0.5 * s, h + 0.04, 0))
		stick(g, "Pennant" + tag, Vector3(w * 0.5 * s, h + 0.06, 0), Vector3(w * 0.5 * s, h + 0.3, 0), 0.01, lib("metal"), 4)
		put(g, "Flag" + tag, prism(0.12, 0.16, 0.015, m(letters, CANVAS)), Vector3(w * 0.5 * s + 0.07, h + 0.24, 0), Vector3(0, 0, -90))
	put(g, "Board", box(w + 0.12, 0.2, 0.05, m(board, PANEL)), Vector3(0, h - 0.08, 0))
	put(g, "BoardFrame", box(w + 0.18, 0.26, 0.03, lib("wood_dark")), Vector3(0, h - 0.08, -0.03))
	var n := clampi(int(w / 0.12), 3, 7)
	for i in n:
		var x := (float(i) - float(n - 1) * 0.5) * 0.1
		put(g, "Letter%d" % i, box(0.06, 0.1, 0.02, m(letters)), Vector3(x, h - 0.08, 0.03))


## Lille betjeningshus med vindue og tegltag.
func booth(pos: Vector3, yaw: float, color: String = "teal") -> void:
	var b := node(_root, "Booth", pos, Vector3(0, yaw, 0))
	put(b, "Walls", box(0.34, 0.42, 0.3, m(color, PLANKS)), Vector3(0, 0.31, 0))
	put(b, "Window", box(0.24, 0.14, 0.02, glass()), Vector3(0, 0.38, 0.16))
	put(b, "WindowFrame", box(0.28, 0.18, 0.015, m("white", PLASTER)), Vector3(0, 0.38, 0.152))
	put(b, "Sill", box(0.3, 0.03, 0.06, lib("wood_dark")), Vector3(0, 0.3, 0.17))
	put(b, "Roof", prism(0.42, 0.16, 0.38, lib("roof_tiles")), Vector3(0, 0.6, 0))
	put(b, "Panel", box(0.12, 0.08, 0.02, lib("metal")), Vector3(0.1, 0.25, 0.16))
	put(b, "Button", cyl(0.02, 0.02, 0.02, glow("red"), 8), Vector3(0.06, 0.26, 0.175), Vector3(90, 0, 0))


## Lygtepæl (metal, glødende kugle – ingen lysnoder, jf. M4).
func lamp(pos: Vector3, nm: String = "Lamp") -> void:
	var l := node(_root, nm, pos)
	put(l, "Foot", cyl(0.06, 0.08, 0.08, lib("metal"), 8), Vector3(0, 0.14, 0))
	put(l, "Pole", cyl(0.022, 0.022, 0.9, lib("metal"), 6), Vector3(0, 0.6, 0))
	put(l, "Head", cyl(0.04, 0.08, 0.06, lib("metal"), 8), Vector3(0, 1.08, 0))
	put(l, "Globe", sph(0.07, glow("cream"), false, 8), Vector3(0, 1.0, 0))


## Stribet markise med kamkant (canvas), centreret i (0, y, z), hældning tilt.
func awning(parent: Node, w: float, d: float, pos: Vector3, a: String, b: String, n: int = 6, tilt: float = -18.0) -> void:
	var aw := node(parent, "AwningRig", pos, Vector3(tilt, 0, 0))
	var sw := w / float(n)
	for i in n:
		put(aw, "AwnStripe%d" % i, box(sw, 0.04, d, m(a if i % 2 == 0 else b, CANVAS)), Vector3(-w * 0.5 + sw * (float(i) + 0.5), 0, 0))
		put(aw, "Scallop%d" % i, sph(sw * 0.5, m(a if i % 2 == 0 else b, CANVAS), true, 8), Vector3(-w * 0.5 + sw * (float(i) + 0.5), -0.01, d * 0.5), Vector3(180, 0, 0))
	put(parent, "AwnTrim", box(w, 0.03, 0.03, m("gold", METAL)), pos + Vector3(0, -0.02 + sin(deg_to_rad(-tilt)) * d * 0.5, cos(deg_to_rad(tilt)) * d * 0.5))


## Menutavle (mørk tavle i træramme med kridtlinjer).
func menu(parent: Node, pos: Vector3, yaw: float = 0.0, w: float = 0.26, h: float = 0.2) -> void:
	var mn := node(parent, "Menu", pos, Vector3(0, yaw, 0))
	put(mn, "Frame", box(w + 0.04, h + 0.04, 0.02, lib("wood_dark")), Vector3.ZERO)
	put(mn, "Board", box(w, h, 0.01, m("dark", PANEL)), Vector3(0, 0, 0.012))
	for i in 3:
		put(mn, "Line%d" % i, box(w * (0.75 - 0.15 * float(i % 2)), 0.018, 0.005, m("cream")), Vector3(-0.02 * float(i % 2), h * 0.3 - h * 0.3 * float(i), 0.02))


## Vimpelsnor mellem a og b.
func bunting(parent: Node, nm: String, a: Vector3, b: Vector3, n: int, cols: Array) -> void:
	var bn := node(parent, nm)
	stick(bn, "String", a, b, 0.006, m("white", CANVAS), 4)
	var yaw := rad_to_deg(atan2(-(b - a).z, (b - a).x))
	for i in n:
		var t := (float(i) + 0.5) / float(n)
		var p := a.lerp(b, t) + Vector3(0, -0.05 - 0.06 * sin(t * PI), 0)
		put(bn, "Pennant%d" % i, prism(0.08, 0.1, 0.012, m(cols[i % cols.size()], CANVAS)), p, Vector3(180, yaw, 0))


## Træbod-krop: plankevægge med malet bånd, hjørnestolper og disk.
func booth_body(w: float, h: float, d: float, z: float, paint: String) -> void:
	put(_root, "Booth", box(w, h, d, lib("wood")), Vector3(0, 0.1 + h * 0.5, z))
	put(_root, "PaintBand", box(w + 0.01, 0.12, d + 0.01, m(paint, PANEL)), Vector3(0, 0.1 + h * 0.25, z))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			put(_root, "Corner%s%s" % ["L" if sx < 0 else "R", "B" if sz < 0 else "F"], box(0.05, h + 0.02, 0.05, lib("wood_dark")),
				Vector3((w * 0.5) * sx, 0.1 + h * 0.5, z + (d * 0.5) * sz))


# ---------------------------------------------------------------- forlystelser

func _build_bouncy_castle() -> void:
	deck(1.95, 1.95, m("teal", TREAD), m("white", COBBLE))
	fence_rect(1.95, 1.95, 0.55, lib("wood_dark"), m("red", METAL), 0.26, ["F", "L", "R"])
	var c := osc(_root, "Castle", Vector3(0, 0.1, -0.05), 0, 1, 0.06, 5.0)
	put(c, "Floor", box(1.5, 0.28, 1.4, m("blue", CANVAS)), Vector3(0, 0.14, 0))
	put(c, "FloorSeam", box(1.52, 0.04, 1.42, m("yellow", CANVAS)), Vector3(0, 0.27, 0))
	for i in 4:
		var x := -0.7 if i % 2 == 0 else 0.7
		var z := -0.65 if i < 2 else 0.65
		var col := "red" if i % 2 == 0 else "yellow"
		put(c, "Tower%d" % i, cyl(0.19, 0.21, 0.95, m(col, CANVAS)), Vector3(x, 0.62, z))
		for k in 3:
			put(c, "TowerSeam%d_%d" % [i, k], torus(0.18, 0.22, m("white", CANVAS), 14, 4), Vector3(x, 0.35 + 0.25 * float(k), z))
		put(c, "TowerCap%d" % i, cyl(0.0, 0.24, 0.32, m("yellow" if col == "red" else "red", CANVAS), 14), Vector3(x, 1.25, z))
		stick(c, "FlagPole%d" % i, Vector3(x, 1.4, z), Vector3(x, 1.62, z), 0.01, lib("metal"), 4)
		put(c, "Flag%d" % i, prism(0.12, 0.14, 0.015, m(["blue", "green", "purple", "orange"][i], CANVAS)), Vector3(x + 0.07, 1.56, z), Vector3(0, 0, -90))
	put(c, "WallBack", box(1.2, 0.5, 0.16, m("red", CANVAS)), Vector3(0, 0.53, -0.65))
	put(c, "WallL", box(0.16, 0.5, 1.1, m("yellow", CANVAS)), Vector3(-0.7, 0.53, 0))
	put(c, "WallR", box(0.16, 0.5, 1.1, m("yellow", CANVAS)), Vector3(0.7, 0.53, 0))
	for k in 4:
		var t := -0.45 + 0.3 * float(k)
		put(c, "MerlonB%d" % k, box(0.14, 0.12, 0.16, m("yellow", CANVAS)), Vector3(t, 0.84, -0.65))
		put(c, "MerlonL%d" % k, box(0.16, 0.12, 0.14, m("red", CANVAS)), Vector3(-0.7, 0.84, t))
		put(c, "MerlonR%d" % k, box(0.16, 0.12, 0.14, m("red", CANVAS)), Vector3(0.7, 0.84, t))
	put(c, "Arch", torus(0.28, 0.4, m("red", CANVAS), 16, 6), Vector3(0, 0.36, 0.66), Vector3(90, 0, 0))
	put(c, "Ramp", box(0.6, 0.06, 0.3, m("blue", CANVAS)), Vector3(0, 0.12, 0.78), Vector3(25, 0, 0))
	put(c, "Keep", cyl(0.3, 0.34, 0.8, m("pink", CANVAS)), Vector3(0, 0.7, -0.4))
	put(c, "KeepWindow", box(0.16, 0.22, 0.04, m("dark", CANVAS)), Vector3(0, 0.72, -0.08))
	put(c, "KeepWindowTop", cyl(0.08, 0.08, 0.04, m("dark", CANVAS), 10), Vector3(0, 0.83, -0.08), Vector3(90, 0, 0))
	put(c, "KeepRim", torus(0.26, 0.38, m("yellow", CANVAS), 16, 6), Vector3(0, 1.1, -0.4))
	for k in 3:
		put(c, "Ball%d" % k, sph(0.07, m(["red", "green", "blue"][k], CANVAS), false, 8), Vector3(-0.3 + 0.3 * float(k), 0.35, 0.2 - 0.15 * float(k % 2)))
	# Blæser + slange bag borgen.
	put(_root, "Blower", cyl(0.14, 0.14, 0.2, lib("metal"), 12), Vector3(0.78, 0.2, -0.85), Vector3(90, 0, 0))
	put(_root, "BlowerGrill", torus(0.08, 0.13, lib("steel"), 12, 4), Vector3(0.78, 0.2, -0.74), Vector3(90, 0, 0))
	stick(_root, "Hose", Vector3(0.78, 0.14, -0.95), Vector3(0.45, 0.18, -0.8), 0.04, m("dark", TREAD), 8)
	# Skohylde ved indgangen.
	var sh := node(_root, "ShoeRack", Vector3(-0.65, 0.1, 0.78))
	put(sh, "Shelf", box(0.36, 0.14, 0.14, lib("wood")), Vector3(0, 0.07, 0))
	for k in 3:
		put(sh, "Shoe%d" % k, box(0.07, 0.04, 0.11, m(["red", "blue", "yellow"][k], CANVAS)), Vector3(-0.11 + 0.11 * float(k), 0.16, 0))
	put(_root, "Sign", box(0.3, 0.2, 0.03, m("yellow", PANEL)), Vector3(0.62, 0.5, 0.88))
	stick(_root, "SignPost", Vector3(0.62, 0.1, 0.86), Vector3(0.62, 0.42, 0.86), 0.02, lib("wood_dark"))
	put(_root, "SignShoe", box(0.12, 0.06, 0.01, m("red")), Vector3(0.62, 0.5, 0.9))
	var t := node(c, "Theme", Vector3(0, 1.38, -0.4))
	duck(t, "Duck", Vector3.ZERO, 0.32)
	put(t, "Crown", cyl(0.14, 0.11, 0.12, m("gold", METAL), 8), Vector3(0, 0.62, 0.1))
	for k in 4:
		var a := TAU * float(k) / 4.0
		put(t, "CrownGem%d" % k, sph(0.03, m(["red", "blue", "green", "purple"][k]), false, 6), Vector3(cos(a) * 0.14, 0.7, 0.1 + sin(a) * 0.14))


func _build_teacups() -> void:
	round_deck(1.45, lib("path_stone"), m("pink", COBBLE))
	var plat := spinner(_root, "Platter", Vector3(0, 0.1, 0), 0.5)
	put(plat, "Disc", cyl(1.34, 1.34, 0.08, m("cream", PANEL), 28), Vector3(0, 0.04, 0))
	put(plat, "DiscRim", torus(1.28, 1.36, m("gold", METAL), 28, 4), Vector3(0, 0.08, 0))
	for k in 8:
		var a := TAU * float(k) / 8.0
		put(plat, "Tile%d" % k, box(0.5, 0.012, 0.14, m("pink" if k % 2 == 0 else "mint", PANEL)), Vector3(cos(a) * 0.95, 0.085, sin(a) * 0.95), Vector3(0, -rad_to_deg(a), 0))
	var cols := ["blue", "yellow", "mint", "red"]
	for i in 4:
		var a := TAU * float(i) / 4.0 + PI / 4.0
		var cup := spinner(plat, "Cup%d" % i, Vector3(cos(a) * 0.92, 0.08, sin(a) * 0.92), 1.6 if i % 2 == 0 else -1.3)
		put(cup, "Saucer", cyl(0.42, 0.36, 0.05, m("white", PLASTER), 18), Vector3(0, 0.025, 0))
		put(cup, "SaucerRim", torus(0.38, 0.43, m(cols[i]), 18, 4), Vector3(0, 0.05, 0))
		put(cup, "Bowl", cyl(0.34, 0.24, 0.36, m(cols[i]), 18), Vector3(0, 0.23, 0))
		put(cup, "Rim", torus(0.31, 0.38, m("white"), 18, 6), Vector3(0, 0.41, 0))
		put(cup, "Handle", torus(0.06, 0.12, m(cols[i]), 12, 6), Vector3(0.36, 0.25, 0), Vector3(90, 0, 0))
		for k in 5:
			var b := TAU * float(k) / 5.0 + 0.4
			put(cup, "Dot%d" % k, sph(0.05, m("white"), true, 8), Vector3(cos(b) * 0.3, 0.26, sin(b) * 0.3), Vector3(0, -rad_to_deg(b), -90))
		put(cup, "Seat", cyl(0.24, 0.24, 0.08, m("red", CANVAS), 14), Vector3(0, 0.3, 0))
		put(cup, "Wheel", cyl(0.07, 0.07, 0.02, lib("metal"), 10), Vector3(0, 0.45, 0))
		stick(cup, "Shaft", Vector3(0, 0.3, 0), Vector3(0, 0.44, 0), 0.015, lib("metal"), 4)
		put(cup, "Rider", sph(0.08, m("cream", PLASTER), false, 8), Vector3(-0.12, 0.45, 0.05))
	# Hjørner: lygter, betjeningshus og skilt (udenfor cirklen).
	lamp(Vector3(-1.3, 0, -1.3), "LampBL")
	lamp(Vector3(1.3, 0, -1.3), "LampBR")
	booth(Vector3(-1.25, 0, 1.25), 45.0, "pink")
	var sg := node(_root, "SignPost", Vector3(1.28, 0, 1.28), Vector3(0, -45, 0))
	put(sg, "Post", cyl(0.025, 0.025, 0.8, lib("wood_dark"), 6), Vector3(0, 0.4, 0))
	put(sg, "Plate", cyl(0.2, 0.2, 0.03, m("blue", PANEL), 16), Vector3(0, 0.75, 0.03), Vector3(90, 0, 0))
	put(sg, "Cup", cyl(0.08, 0.06, 0.08, m("white"), 10), Vector3(0, 0.75, 0.06))
	var t := node(_root, "Theme", Vector3(0, 0.1, 0))
	put(t, "Foot", cyl(0.32, 0.38, 0.2, m("blue", METAL)), Vector3(0, 0.1, 0))
	put(t, "Pot", sph(0.55, m("white"), false, 18), Vector3(0, 0.72, 0))
	put(t, "Band", torus(0.5, 0.58, m("blue"), 18, 6), Vector3(0, 0.72, 0))
	put(t, "BandHigh", torus(0.4, 0.46, m("gold", METAL), 18, 4), Vector3(0, 1.02, 0))
	for k in 6:
		var a := TAU * float(k) / 6.0
		put(t, "Rose%d" % k, sph(0.07, m("pink"), false, 8), Vector3(cos(a) * 0.53, 0.55, sin(a) * 0.53))
		put(t, "Leaf%d" % k, sph(0.04, m("green"), false, 6), Vector3(cos(a + 0.18) * 0.52, 0.5, sin(a + 0.18) * 0.52))
	put(t, "Spout", cyl(0.07, 0.14, 0.6, m("white"), 10), Vector3(0.62, 0.92, 0), Vector3(0, 0, -50))
	put(t, "SpoutTip", torus(0.05, 0.08, m("blue"), 10, 4), Vector3(0.84, 1.11, 0), Vector3(0, 0, -50))
	put(t, "Handle", torus(0.18, 0.26, m("white"), 14, 6), Vector3(-0.6, 0.78, 0), Vector3(90, 0, 0))
	var lid := osc(t, "Lid", Vector3(0, 1.2, 0), 0, 1, 0.18, 2.5)
	put(lid, "Cap", cyl(0.22, 0.34, 0.1, m("blue")), Vector3(0, 0.05, 0))
	put(lid, "Knob", sph(0.08, m("gold", METAL), false, 10), Vector3(0, 0.16, 0))
	put(t, "Steam", sph(0.1, m("white"), false, 8), Vector3(0.95, 1.25, 0))
	put(t, "Steam2", sph(0.07, m("white"), false, 8), Vector3(1.02, 1.42, 0.04))


func _build_trampoline() -> void:
	deck(1.95, 1.95, lib("wood"), m("blue", COBBLE))
	fence_rect(1.95, 1.95, 1.95, lib("wood_dark"), m("yellow", METAL), 0.28, ["B", "L", "R"])
	for i in 3:
		var x := -0.55 + 0.55 * float(i)
		var z := -0.4 if i != 1 else -0.15
		var tr := node(_root, "Tramp%d" % i, Vector3(x, 0.0, z))
		put(tr, "Frame", torus(0.24, 0.3, lib("metal"), 18, 6), Vector3(0, 0.3, 0))
		put(tr, "Pad", torus(0.26, 0.33, m(["blue", "red", "green"][i], CANVAS), 18, 6), Vector3(0, 0.32, 0))
		put(tr, "Bed", cyl(0.25, 0.25, 0.02, m("dark", TREAD), 18), Vector3(0, 0.3, 0))
		put(tr, "Target", torus(0.06, 0.1, m("yellow", CANVAS), 12, 4), Vector3(0, 0.315, 0))
		for k in 4:
			var a := TAU * float(k) / 4.0 + PI / 4.0
			put(tr, "Leg%d" % k, cyl(0.018, 0.018, 0.3, lib("metal"), 6), Vector3(cos(a) * 0.27, 0.2, sin(a) * 0.27))
			stick(tr, "NetPole%d" % k, Vector3(cos(a) * 0.3, 0.32, sin(a) * 0.3), Vector3(cos(a) * 0.3, 0.95, sin(a) * 0.3), 0.012, m("white", METAL), 4)
			put(tr, "NetCap%d" % k, sph(0.025, m("red", CANVAS), false, 6), Vector3(cos(a) * 0.3, 0.96, sin(a) * 0.3))
		put(tr, "NetRing", torus(0.29, 0.31, m("white", METAL), 16, 4), Vector3(0, 0.94, 0))
		var j := osc(tr, "Jumper", Vector3(0, 0.32, 0), 0, 1, 0.38, 4.0 + float(i) * 0.4, Vector3.UP, float(i) * 1.1)
		put(j, "Legs", cyl(0.05, 0.05, 0.12, m("blue", CANVAS), 8), Vector3(0, 0.06, 0))
		put(j, "Body", cyl(0.06, 0.08, 0.16, m(["red", "yellow", "purple"][i], CANVAS), 8), Vector3(0, 0.2, 0))
		stick(j, "ArmL", Vector3(-0.05, 0.26, 0), Vector3(-0.14, 0.38, 0), 0.02, m(["red", "yellow", "purple"][i], CANVAS), 4)
		stick(j, "ArmR", Vector3(0.05, 0.26, 0), Vector3(0.14, 0.38, 0), 0.02, m(["red", "yellow", "purple"][i], CANVAS), 4)
		put(j, "Head", sph(0.07, m("cream", PLASTER), false, 8), Vector3(0, 0.34, 0))
	booth(Vector3(0.72, 0.1, 0.25), -90.0, "blue")
	put(_root, "Bench", box(0.4, 0.06, 0.14, lib("wood")), Vector3(-0.6, 0.3, 0.3))
	put(_root, "BenchLegs", box(0.36, 0.2, 0.1, lib("metal")), Vector3(-0.6, 0.2, 0.3))
	# Tema: kæmpe spiralfjeder som indgangsbue.
	var t := node(_root, "Theme", Vector3(0, 0.1, 0.72))
	for s: float in [-1.0, 1.0]:
		for k in 6:
			put(t, "Coil%s%d" % ["L" if s < 0 else "R", k], torus(0.11, 0.17, m("red", METAL), 10, 6),
				Vector3(0.72 * s, 0.1 + 0.17 * float(k), 0), Vector3(0, 0, 8.0 * (1 if k % 2 == 0 else -1)))
	for k in 9:
		put(t, "Top%d" % k, torus(0.11, 0.17, m("yellow", METAL), 10, 6), Vector3(-0.68 + 0.17 * float(k), 1.15, 0), Vector3(8.0 * (1 if k % 2 == 0 else -1), 0, 90))
	put(t, "PadL", cyl(0.2, 0.2, 0.08, m("dark", TREAD)), Vector3(-0.72, 0.0, 0))
	put(t, "PadR", cyl(0.2, 0.2, 0.08, m("dark", TREAD)), Vector3(0.72, 0.0, 0))
	put(t, "Sign", box(0.6, 0.18, 0.04, m("blue", PANEL)), Vector3(0, 1.0, 0.03))
	for k in 5:
		put(t, "Letter%d" % k, box(0.07, 0.1, 0.02, m("yellow")), Vector3(-0.2 + 0.1 * float(k), 1.0 + 0.02 * float(k % 2), 0.06))


func _build_sky_rings() -> void:
	deck(1.95, 1.95, lib("tread_plate"), m("purple", COBBLE))
	fence_rect(1.95, 1.95, 0.5, lib("metal"), m("yellow", METAL), 0.3, ["F", "B"])
	put(_root, "Pad", cyl(0.6, 0.7, 0.12, m("dark", TREAD)), Vector3(0, 0.16, 0))
	put(_root, "PadStripe", torus(0.55, 0.62, m("yellow", PANEL), 20, 4), Vector3(0, 0.22, 0))
	for s: float in [-1.0, 1.0]:
		var tag := "L" if s < 0 else "R"
		put(_root, "Post" + tag, cyl(0.07, 0.1, 2.3, m("white", METAL)), Vector3(0.88 * s, 1.15, 0))
		put(_root, "PostFoot" + tag, box(0.3, 0.1, 0.3, lib("steel")), Vector3(0.88 * s, 0.15, 0))
		stick(_root, "BraceF" + tag, Vector3(0.88 * s, 0.15, 0.5), Vector3(0.88 * s, 1.3, 0.0), 0.035, m("white", METAL))
		stick(_root, "BraceB" + tag, Vector3(0.88 * s, 0.15, -0.5), Vector3(0.88 * s, 1.3, 0.0), 0.035, m("white", METAL))
		put(_root, "Bearing" + tag, cyl(0.12, 0.12, 0.12, lib("steel"), 12), Vector3(0.82 * s, 1.25, 0), Vector3(0, 0, 90))
		put(_root, "Ladder" + tag, box(0.12, 1.6, 0.02, lib("metal")), Vector3(0.88 * s, 1.0, -0.11))
	put(_root, "Beam", box(1.9, 0.16, 0.16, m("purple", METAL)), Vector3(0, 2.3, 0))
	for k in 5:
		put(_root, "Bolt%d" % k, cyl(0.025, 0.025, 0.02, lib("steel"), 6), Vector3(-0.8 + 0.4 * float(k), 2.3, 0.085), Vector3(90, 0, 0))
	var outer := spinner(_root, "Outer", Vector3(0, 1.25, 0), 1.1, Vector3(1, 0, 0))
	put(outer, "AxleL", cyl(0.04, 0.04, 0.2, lib("steel"), 6), Vector3(-0.78, 0, 0), Vector3(0, 0, 90))
	put(outer, "AxleR", cyl(0.04, 0.04, 0.2, lib("steel"), 6), Vector3(0.78, 0, 0), Vector3(0, 0, 90))
	put(outer, "Ring", torus(0.62, 0.7, m("yellow", METAL), 24, 6), Vector3.ZERO, Vector3(0, 0, 90))
	for k in 8:
		var a := TAU * float(k) / 8.0
		put(outer, "Rivet%d" % k, sph(0.03, lib("steel"), false, 6), Vector3(0, cos(a) * 0.66, sin(a) * 0.66) + Vector3(0.05, 0, 0))
	var inner := spinner(outer, "Inner", Vector3.ZERO, 1.7, Vector3(0, 0, 1))
	put(inner, "Ring", torus(0.48, 0.56, m("red", METAL), 24, 6), Vector3.ZERO, Vector3(90, 0, 0))
	stick(inner, "SpokeT", Vector3(0, 0.22, 0), Vector3(0, 0.5, 0), 0.03, lib("steel"))
	stick(inner, "SpokeB", Vector3(0, -0.22, 0), Vector3(0, -0.5, 0), 0.03, lib("steel"))
	put(inner, "Pod", sph(0.22, m("sky", PANEL)), Vector3.ZERO)
	put(inner, "PodWindow", sph(0.16, glass(), true, 10), Vector3(0, 0.0, 0.14), Vector3(90, 0, 0))
	put(inner, "PodBand", torus(0.2, 0.24, m("white", METAL), 14, 4), Vector3.ZERO)
	put(inner, "Rider", sph(0.09, m("cream", PLASTER), false, 8), Vector3(0, 0.1, 0.08))
	booth(Vector3(-0.68, 0.1, 0.72), 90.0, "purple")
	# Tema: kæmpe planet med ring over portalen.
	var t := node(_root, "Theme", Vector3(0, 2.38, 0))
	put(t, "Mast", cyl(0.05, 0.08, 0.35, m("white", METAL), 8), Vector3(0, 0.17, 0))
	var p := spinner(t, "Planet", Vector3(0, 0.82, 0), 0.4)
	put(p, "Globe", sph(0.48, m("purple", PLASTER), false, 18), Vector3.ZERO)
	put(p, "Ring", torus(0.62, 0.82, m("gold", METAL), 24, 4), Vector3.ZERO, Vector3(20, 0, 12))
	put(p, "Ring2", torus(0.86, 0.9, m("orange", METAL), 24, 4), Vector3.ZERO, Vector3(20, 0, 12))
	put(p, "Crater1", sph(0.1, m("pink"), true, 8), Vector3(0.0, 0.2, 0.43), Vector3(65, 0, 0))
	put(p, "Crater2", sph(0.07, m("pink"), true, 8), Vector3(-0.3, -0.15, 0.32), Vector3(70, 0, 40))
	put(p, "Crater3", sph(0.08, m("pink"), true, 8), Vector3(0.32, 0.05, -0.32), Vector3(-70, 0, -40))
	put(p, "Moon", sph(0.11, m("cream"), false, 10), Vector3(0.75, 0.35, -0.2))
	for k in 4:
		var a := TAU * float(k) / 4.0 + 0.3
		put(t, "Star%d" % k, cyl(0.07, 0.07, 0.02, glow("yellow"), 5), Vector3(cos(a) * 0.55, 0.3 + 0.12 * float(k % 2), sin(a) * 0.3), Vector3(90, 0, 0))


func _build_pirate_ship() -> void:
	deck(3.95, 1.95, lib("wood"), m("blue", COBBLE))
	fence_rect(3.95, 1.95, 0.6, lib("wood_dark"), m("red", METAL), 0.28, ["F", "L", "R"])
	var pivot_y := 3.0
	for s: float in [-1.0, 1.0]:
		var z := 0.78 * s
		var tag := "F" if s > 0 else "B"
		stick(_root, "Leg%sL" % tag, Vector3(-1.2, 0.1, z), Vector3(0, pivot_y, z), 0.07, m("red", METAL), 8)
		stick(_root, "Leg%sR" % tag, Vector3(1.2, 0.1, z), Vector3(0, pivot_y, z), 0.07, m("red", METAL), 8)
		stick(_root, "Brace%s" % tag, Vector3(-0.62, 1.55, z), Vector3(0.62, 1.55, z), 0.035, lib("steel"), 6)
		put(_root, "FootL" + tag, box(0.26, 0.08, 0.26, lib("steel")), Vector3(-1.2, 0.14, z))
		put(_root, "FootR" + tag, box(0.26, 0.08, 0.26, lib("steel")), Vector3(1.2, 0.14, z))
		put(_root, "Hub" + tag, cyl(0.12, 0.12, 0.1, lib("steel"), 12), Vector3(0, pivot_y, z), Vector3(90, 0, 0))
	put(_root, "Axle", cyl(0.06, 0.06, 1.7, lib("steel"), 8), Vector3(0, pivot_y, 0), Vector3(90, 0, 0))
	# Påstigningsplatform.
	put(_root, "Platform", box(1.6, 0.18, 0.32, lib("wood_dark")), Vector3(0, 0.19, 0.6))
	for k in 3:
		put(_root, "Step%d" % k, box(0.4, 0.06, 0.12, lib("wood_dark")), Vector3(1.0, 0.13 + 0.05 * float(k), 0.8 - 0.1 * float(k)))
	booth(Vector3(-1.6, 0.1, 0.65), 0.0, "red")
	var sw := osc(_root, "Swing", Vector3(0, pivot_y, 0), 1, 0, deg_to_rad(26.0), 1.4, Vector3(0, 0, 1))
	var arm := 2.25
	for z: float in [-0.42, 0.42]:
		put(sw, "Arm%s" % ("B" if z < 0 else "F"), box(0.08, arm, 0.08, m("yellow", METAL)), Vector3(0, -arm * 0.5, z))
	var hy := -arm
	put(sw, "Hull", box(2.2, 0.42, 0.8, lib("wood")), Vector3(0, hy, 0))
	put(sw, "Keel", prism(2.0, 0.22, 0.6, lib("wood_dark")), Vector3(0, hy - 0.32, 0), Vector3(180, 0, 0))
	put(sw, "Bow", box(0.4, 0.4, 0.8, lib("wood")), Vector3(1.15, hy + 0.12, 0), Vector3(0, 0, 25))
	put(sw, "Bowsprit", cyl(0.025, 0.04, 0.5, lib("wood_dark"), 6), Vector3(1.45, hy + 0.42, 0), Vector3(0, 0, -60))
	put(sw, "Stern", box(0.45, 0.5, 0.8, lib("wood")), Vector3(-1.12, hy + 0.2, 0), Vector3(0, 0, -15))
	put(sw, "SternWindow", box(0.02, 0.14, 0.4, m("yellow", PANEL)), Vector3(-1.36, hy + 0.25, 0), Vector3(0, 0, -15))
	put(sw, "Lantern", sph(0.06, glow("orange"), false, 8), Vector3(-1.3, hy + 0.55, 0))
	put(sw, "Stripe", box(2.24, 0.08, 0.82, m("gold", PANEL)), Vector3(0, hy + 0.12, 0))
	put(sw, "StripeLow", box(2.24, 0.05, 0.82, m("red", PANEL)), Vector3(0, hy - 0.1, 0))
	for s: float in [-1.0, 1.0]:
		var zt := 0.39 * s
		var tag := "F" if s > 0 else "B"
		stick(sw, "Rail" + tag, Vector3(-0.95, hy + 0.38, zt), Vector3(0.95, hy + 0.38, zt), 0.02, m("gold", METAL), 6)
		for k in 6:
			var x := -0.9 + 0.36 * float(k)
			put(sw, "Baluster%s%d" % [tag, k], box(0.03, 0.17, 0.03, lib("wood_dark")), Vector3(x, hy + 0.29, zt))
		for k in 3:
			put(sw, "Port%s%d" % [tag, k], torus(0.04, 0.07, m("gold", METAL), 10, 4), Vector3(-0.5 + 0.5 * float(k), hy - 0.02, 0.41 * s), Vector3(90, 0, 0))
		put(sw, "Cannon" + tag, cyl(0.035, 0.045, 0.24, m("dark", METAL), 8), Vector3(0.75, hy + 0.05, 0.47 * s), Vector3(90 * s, 0, 0))
	for i in 4:
		put(sw, "Bench%d" % i, box(0.1, 0.12, 0.7, m("red", CANVAS)), Vector3(-0.75 + 0.5 * float(i), hy + 0.27, 0))
		put(sw, "Rider%d" % i, sph(0.07, m("cream", PLASTER), false, 8), Vector3(-0.68 + 0.5 * float(i), hy + 0.43, 0.2 - 0.4 * float(i % 2)))
	# Tema: dødningehoved-flag, sejl og blæksprutte om masten.
	var t := node(sw, "Theme", Vector3(0, hy + 0.21, 0))
	put(t, "Mast", cyl(0.05, 0.06, 1.5, lib("wood_dark"), 8), Vector3(0.0, 0.75, 0.0))
	put(t, "Yard", cyl(0.025, 0.025, 0.7, lib("wood_dark"), 6), Vector3(-0.0, 1.15, 0.0), Vector3(90, 0, 0))
	put(t, "Sail", box(0.03, 0.42, 0.62, m("cream", CANVAS)), Vector3(0.05, 0.92, 0.0))
	put(t, "SailStripe", box(0.035, 0.1, 0.62, m("red", CANVAS)), Vector3(0.05, 0.92, 0.0))
	put(t, "Nest", cyl(0.12, 0.09, 0.1, lib("wood"), 10), Vector3(0, 1.3, 0))
	put(t, "Flag", box(0.55, 0.36, 0.02, m("black", CANVAS)), Vector3(0.3, 1.58, 0.0))
	put(t, "Skull", sph(0.08, m("white"), false, 10), Vector3(0.3, 1.62, 0.02))
	put(t, "BoneA", box(0.26, 0.04, 0.02, m("white")), Vector3(0.3, 1.5, 0.02), Vector3(0, 0, 35))
	put(t, "BoneB", box(0.26, 0.04, 0.02, m("white")), Vector3(0.3, 1.5, 0.02), Vector3(0, 0, -35))
	put(t, "OctoHead", sph(0.3, m("purple"), false, 14), Vector3(0, 0.35, 0))
	for k in 5:
		var a := TAU * float(k) / 5.0
		put(t, "OctoSpot%d" % k, sph(0.05, m("pink"), true, 6), Vector3(cos(a) * 0.2, 0.55, sin(a) * 0.2 - 0.05), Vector3(0, 0, 0))
	eyes(t, Vector3(0, 0.42, 0.22), 0.11, 0.08, "OctoEye")
	for k in 4:
		put(t, "Tentacle%d" % k, torus(0.07, 0.13, m("purple"), 12, 6), Vector3(0, 0.6 + 0.12 * float(k), 0),
			Vector3(12.0 * (1 if k % 2 == 0 else -1), 0, 10.0 * (1 if k < 2 else -1)))
	for k in 2:
		var s := -1.0 if k == 0 else 1.0
		put(t, "Curl%d" % k, torus(0.06, 0.12, m("purple"), 12, 6), Vector3(0.4 * s, 0.15, 0.36), Vector3(90, 0, 0))
	put(sw, "Figurehead", sph(0.09, m("gold", METAL), false, 10), Vector3(1.38, hy + 0.3, 0))


func _build_space_rocket() -> void:
	put(_root, "Base", cyl(1.45, 1.45, 0.12, m("dark", TREAD), 28), Vector3(0, 0.06, 0))
	put(_root, "Kerb", torus(1.39, 1.47, m("yellow", METAL), 28, 6), Vector3(0, 0.12, 0))
	for k in 8:
		var a := TAU * float(k) / 8.0 + PI / 8.0
		put(_root, "Star%d" % k, cyl(0.08, 0.08, 0.015, m("gold", PANEL), 5), Vector3(cos(a) * 1.15, 0.125, sin(a) * 1.15))
	put(_root, "Pad", cyl(0.6, 0.7, 0.3, lib("tread_plate")), Vector3(0, 0.25, 0))
	put(_root, "PadStripe", torus(0.62, 0.68, m("yellow", PANEL), 20, 4), Vector3(0, 0.36, 0))
	put(_root, "Column", cyl(0.42, 0.42, 0.5, lib("steel"), 16), Vector3(0, 0.6, 0))
	var arms := spinner(_root, "Arms", Vector3(0, 0.95, 0), 1.0)
	put(arms, "Hub", cyl(0.48, 0.48, 0.14, m("yellow", METAL)), Vector3.ZERO)
	put(arms, "HubRim", torus(0.44, 0.5, m("red", METAL), 16, 4), Vector3(0, 0.07, 0))
	var cols := ["red", "blue", "mint", "orange"]
	for i in 4:
		var a := TAU * float(i) / 4.0
		var arm := node(arms, "Arm%d" % i, Vector3.ZERO, Vector3(0, rad_to_deg(a), 0))
		put(arm, "Bar", box(0.9, 0.08, 0.08, lib("steel")), Vector3(0.9, 0, 0))
		put(arm, "BarBrace", box(0.6, 0.04, 0.04, lib("steel")), Vector3(0.8, -0.08, 0), Vector3(0, 0, 8))
		put(arm, "Car", cyl(0.17, 0.17, 0.5, m(cols[i], PANEL)), Vector3(1.22, 0.05, 0), Vector3(90, 0, 0))
		put(arm, "CarBand", torus(0.16, 0.19, m("white", METAL), 12, 4), Vector3(1.22, 0.05, -0.1), Vector3(90, 0, 0))
		put(arm, "Nose", cyl(0.0, 0.17, 0.26, m("white", METAL)), Vector3(1.22, 0.05, -0.38), Vector3(-90, 0, 0))
		put(arm, "Exhaust", cyl(0.12, 0.08, 0.08, lib("metal"), 10), Vector3(1.22, 0.05, 0.29), Vector3(90, 0, 0))
		put(arm, "Fin", prism(0.06, 0.18, 0.2, m(cols[i], METAL)), Vector3(1.22, 0.27, 0.15))
		put(arm, "Window", sph(0.13, glass(), true, 10), Vector3(1.22, 0.2, -0.05))
		put(arm, "Seat", sph(0.08, m("cream", PLASTER), false, 8), Vector3(1.22, 0.22, -0.05))
	lamp(Vector3(-1.3, 0, -1.3), "LampBL")
	lamp(Vector3(1.3, 0, -1.3), "LampBR")
	booth(Vector3(-1.25, 0, 1.25), 45.0, "blue")
	gate(Vector3(1.22, 0, 1.22), 0.4, "dark", "yellow")
	(_root.get_node("Gate") as Node3D).rotation = Vector3(0, deg_to_rad(-45), 0)
	# Tema: høj tegneserieraket med flammer af plaster-kegler.
	var t := node(_root, "Theme", Vector3(0, 0.4, 0))
	put(t, "Body", cyl(0.34, 0.34, 2.0, m("white", PANEL), 18), Vector3(0, 1.6, 0))
	put(t, "Nose", cyl(0.0, 0.34, 0.75, m("red", METAL), 18), Vector3(0, 2.97, 0))
	put(t, "Tip", sph(0.06, m("gold", METAL), false, 8), Vector3(0, 3.36, 0))
	put(t, "Band", torus(0.32, 0.38, m("red", METAL), 18, 6), Vector3(0, 2.3, 0))
	put(t, "BandLow", torus(0.32, 0.38, m("blue", METAL), 18, 6), Vector3(0, 1.0, 0))
	for k in 2:
		var y := 2.0 - 0.5 * float(k)
		put(t, "Window%d" % k, cyl(0.12, 0.12, 0.06, m("sky", PANEL), 12), Vector3(0, y, 0.33), Vector3(90, 0, 0))
		put(t, "WindowRim%d" % k, torus(0.11, 0.16, m("gold", METAL), 12, 6), Vector3(0, y, 0.34), Vector3(90, 0, 0))
	for k in 10:
		var a := TAU * float(k) / 10.0
		put(t, "Rivet%d" % k, sph(0.025, lib("steel"), false, 6), Vector3(cos(a) * 0.345, 2.45, sin(a) * 0.345))
	for k in 3:
		var a := TAU * float(k) / 3.0 + PI / 6.0
		var fin := node(t, "FinMount%d" % k, Vector3(0, 0.85, 0), Vector3(0, rad_to_deg(a), 0))
		put(fin, "Fin", prism(0.5, 0.7, 0.06, m("red", METAL)), Vector3(0.45, 0.0, 0), Vector3(0, 0, 0))
		put(fin, "FinTip", sph(0.05, m("yellow", METAL), false, 6), Vector3(0.68, -0.33, 0))
	var fl := osc(t, "Flames", Vector3(0, 0.6, 0), 0, 0, 0.04, 14.0)
	put(fl, "FlameOuter", cyl(0.3, 0.0, 0.55, glow("orange"), 12), Vector3(0, -0.05, 0))
	put(fl, "FlameInner", cyl(0.17, 0.0, 0.4, glow("yellow"), 10), Vector3(0, 0.0, 0))


func _build_drop_tower() -> void:
	deck(1.95, 1.95, lib("tread_plate"), m("red", COBBLE))
	fence_rect(1.95, 1.95, 0.5, lib("metal"), m("yellow", METAL), 0.32)
	put(_root, "Pad", cyl(0.75, 0.85, 0.15, m("dark", TREAD)), Vector3(0, 0.17, 0))
	put(_root, "PadStripe", torus(0.7, 0.78, m("yellow", PANEL), 20, 4), Vector3(0, 0.25, 0))
	var g := osc(_root, "Gondola", Vector3(0, 1.15, 0), 0, 2, 3.4, 0.9)
	put(g, "Ring", torus(0.3, 0.62, m("blue", METAL), 20, 6), Vector3.ZERO)
	put(g, "Collar", cyl(0.3, 0.3, 0.3, lib("steel"), 16), Vector3(0, 0.1, 0))
	for k in 6:
		var a := TAU * float(k) / 6.0
		var seat := node(g, "Seat%d" % k, Vector3(cos(a) * 0.52, 0.0, sin(a) * 0.52), Vector3(0, -rad_to_deg(a) + 90, 0))
		put(seat, "Back", box(0.22, 0.34, 0.06, m("yellow", CANVAS)), Vector3(0, 0.13, -0.08))
		put(seat, "Bar", torus(0.07, 0.09, lib("steel"), 10, 4), Vector3(0, 0.18, 0.02), Vector3(90, 0, 0))
		put(seat, "Rider", sph(0.08, m("cream", PLASTER), false, 8), Vector3(0, 0.3, 0))
		put(seat, "Feet", box(0.1, 0.12, 0.06, m(["red", "blue", "green"][k % 3], CANVAS)), Vector3(0, -0.1, 0.04))
	booth(Vector3(-0.7, 0.1, 0.7), 90.0, "blue")
	# Tema: tårnet er et kæmpe termometer med "kogepunkt" på toppen.
	var t := node(_root, "Theme", Vector3(0, 0.25, 0))
	put(t, "Bulb", sph(0.42, m("red", PLASTER), false, 16), Vector3(0, 0.4, 0))
	put(t, "TubeLow", cyl(0.24, 0.24, 2.6, m("white", PANEL), 14), Vector3(0, 2.0, 0))
	put(t, "TubeHigh", cyl(0.24, 0.24, 2.6, m("white", PANEL), 14), Vector3(0, 4.6, 0))
	put(t, "Cap", sph(0.24, m("white", METAL), true, 14), Vector3(0, 5.9, 0))
	for k in 5:
		put(t, "Brace%d" % k, torus(0.23, 0.28, lib("steel"), 14, 4), Vector3(0, 1.0 + 1.2 * float(k), 0))
	for s: float in [-1.0, 1.0]:
		put(t, "Rail" + ("L" if s < 0 else "R"), box(0.05, 5.2, 0.05, lib("steel")), Vector3(0.27 * s, 3.2, 0))
	put(t, "MercuryLow", box(0.12, 2.6, 0.06, m("red", PANEL)), Vector3(0, 2.0, 0.23))
	put(t, "MercuryHigh", box(0.12, 2.0, 0.06, m("red", PANEL)), Vector3(0, 4.3, 0.23))
	for k in 8:
		put(t, "Tick%d" % k, box(0.3 if k % 2 == 0 else 0.18, 0.04, 0.04, m("dark")), Vector3(0.0, 1.2 + 0.6 * float(k), 0.26))
	put(t, "Motor", box(0.4, 0.22, 0.4, lib("metal")), Vector3(0, 5.75, -0.05))
	put(t, "Sign", box(0.8, 0.32, 0.06, m("yellow", PANEL)), Vector3(0, 5.55, 0.3))
	put(t, "SignFrame", box(0.86, 0.38, 0.03, m("red", METAL)), Vector3(0, 5.55, 0.26))
	put(t, "SignStar", cyl(0.12, 0.12, 0.04, m("red"), 5), Vector3(-0.25, 5.55, 0.34), Vector3(90, 0, 0))
	for k in 3:
		put(t, "SignLetter%d" % k, box(0.07, 0.14, 0.02, m("dark")), Vector3(0.0 + 0.11 * float(k), 5.55, 0.34))
	put(t, "Beacon", sph(0.07, glow("red"), false, 8), Vector3(0, 6.05, -0.05))
	put(t, "Steam1", sph(0.13, m("white"), false, 8), Vector3(0.12, 6.15, 0.1))
	put(t, "Steam2", sph(0.09, m("white"), false, 8), Vector3(-0.08, 6.32, 0.15))


# ---------------------------------------------------------------- butikker

## Lille bod (1×1): træbod med malet bånd, disk, stribet markise, menutavle og kasse.
func kiosk(color: String, stripe: String) -> void:
	put(_root, "Base", box(0.95, 0.1, 0.95, lib("path_stone")), Vector3(0, 0.05, 0))
	booth_body(0.76, 0.62, 0.56, -0.1, color)
	put(_root, "ServeWindow", box(0.56, 0.24, 0.02, m("dark", PANEL)), Vector3(0, 0.56, 0.185))
	put(_root, "Counter", box(0.84, 0.05, 0.22, lib("wood_dark")), Vector3(0, 0.46, 0.27))
	put(_root, "CounterFront", box(0.8, 0.36, 0.04, m(color, PANEL)), Vector3(0, 0.28, 0.36))
	for k in 4:
		put(_root, "FrontStripe%d" % k, box(0.08, 0.36, 0.045, m(stripe, PANEL)), Vector3(-0.3 + 0.2 * float(k), 0.28, 0.36))
	put(_root, "Register", box(0.12, 0.08, 0.1, lib("metal")), Vector3(-0.26, 0.53, 0.25))
	put(_root, "RegisterTop", box(0.1, 0.04, 0.03, m("dark")), Vector3(-0.26, 0.6, 0.21), Vector3(-30, 0, 0))
	for s: float in [-1.0, 1.0]:
		put(_root, "AwnPost" + ("L" if s < 0 else "R"), box(0.04, 0.42, 0.04, lib("wood_dark")), Vector3(0.4 * s, 0.68, 0.36))
	put(_root, "Roof", box(0.84, 0.06, 0.66, m(stripe, CANVAS)), Vector3(0, 0.75, -0.1))
	awning(_root, 0.88, 0.32, Vector3(0, 0.84, 0.24), stripe, "white", 6, -18.0)
	menu(_root, Vector3(0.4, 0.5, -0.1), 90.0, 0.3, 0.24)


func _build_fries_stand() -> void:
	kiosk("red", "yellow")
	for k in 2:
		var bx := node(_root, "Basket%d" % k, Vector3(0.05 + 0.18 * float(k), 0.5, 0.27))
		put(bx, "Box", cyl(0.06, 0.045, 0.08, m("red", PANEL), 8), Vector3(0, 0.04, 0))
		for f in 4:
			put(bx, "Fry%d" % f, box(0.015, 0.08, 0.015, m("yellow", PLASTER)), Vector3(-0.02 + 0.014 * float(f), 0.1, 0.01 * float(f % 2)), Vector3(0, 0, -10 + 7 * float(f)))
	put(_root, "Ketchup", cyl(0.025, 0.03, 0.12, m("red", PLASTER), 8), Vector3(-0.08, 0.55, 0.3))
	put(_root, "Mustard", cyl(0.025, 0.03, 0.12, m("yellow", PLASTER), 8), Vector3(-0.14, 0.55, 0.3))
	var t := node(_root, "Theme", Vector3(0, 0.78, -0.12))
	put(t, "Cup", cyl(0.3, 0.22, 0.5, m("red", PANEL), 16), Vector3(0, 0.25, 0))
	put(t, "Band", torus(0.25, 0.31, m("white", PANEL), 16, 4), Vector3(0, 0.28, 0))
	put(t, "Lip", torus(0.28, 0.32, m("white", PANEL), 16, 4), Vector3(0, 0.5, 0))
	put(t, "Logo", cyl(0.1, 0.1, 0.03, m("yellow", PANEL), 12), Vector3(0, 0.22, 0.26), Vector3(80, 0, 0))
	put(t, "LogoM", torus(0.03, 0.05, m("red"), 8, 4), Vector3(0, 0.22, 0.28), Vector3(80, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 83
	for k in 15:
		var a := TAU * float(k) / 7.0
		var r := 0.0 if k == 0 else (0.15 if k < 8 else 0.07)
		var h := rng.randf_range(0.4, 0.6)
		put(t, "Fry%d" % k, box(0.06, h, 0.06, m("yellow", PLASTER)), Vector3(cos(a) * r, 0.5 + h * 0.3, sin(a) * r),
			Vector3(rng.randf_range(-12, 12), rng.randf_range(0, 90), rng.randf_range(-12, 12)))
	put(t, "KetchupBlob", sph(0.08, m("red", PLASTER), true, 10), Vector3(0.08, 0.86, 0.06))


func _build_coffee_stand() -> void:
	put(_root, "Base", box(0.95, 0.1, 0.95, lib("path_stone")), Vector3(0, 0.05, 0))
	put(_root, "Saucer", cyl(0.47, 0.42, 0.07, m("white", PLASTER), 24), Vector3(0, 0.135, 0))
	put(_root, "SaucerRim", torus(0.42, 0.48, m("blue", PANEL), 24, 4), Vector3(0, 0.17, 0))
	put(_root, "Cup", cyl(0.4, 0.3, 0.7, m("white", PLASTER), 24), Vector3(0, 0.52, 0))
	put(_root, "Sleeve", cyl(0.37, 0.33, 0.22, m("brown", CANVAS), 24), Vector3(0, 0.5, 0))
	put(_root, "Hatch", box(0.36, 0.24, 0.1, m("dark", PANEL)), Vector3(0, 0.58, 0.34), Vector3(-7, 0, 0))
	put(_root, "HatchFrame", box(0.42, 0.3, 0.06, lib("wood_dark")), Vector3(0, 0.58, 0.32), Vector3(-7, 0, 0))
	put(_root, "Counter", box(0.5, 0.05, 0.16, lib("wood_dark")), Vector3(0, 0.45, 0.42))
	put(_root, "Machine", box(0.12, 0.12, 0.08, lib("metal")), Vector3(-0.15, 0.53, 0.42))
	put(_root, "Mug", cyl(0.03, 0.03, 0.06, m("red", PLASTER), 8), Vector3(0.12, 0.5, 0.44))
	put(_root, "Mug2", cyl(0.03, 0.03, 0.06, m("blue", PLASTER), 8), Vector3(0.2, 0.5, 0.42))
	awning(_root, 0.5, 0.18, Vector3(0, 0.78, 0.38), "red", "white", 4, -20.0)
	var mp := node(_root, "MenuStand", Vector3(0.38, 0.1, 0.36), Vector3(0, -30, 0))
	put(mp, "Leg", box(0.03, 0.3, 0.03, lib("wood_dark")), Vector3(0, 0.15, 0))
	menu(mp, Vector3(0, 0.38, 0), 0.0, 0.18, 0.16)
	var t := node(_root, "Theme", Vector3(0, 0.1, 0))
	put(t, "Rim", torus(0.36, 0.42, m("red", PLASTER), 24, 6), Vector3(0, 0.79, 0))
	put(t, "Coffee", cyl(0.37, 0.37, 0.03, m("coffee", PLASTER), 24), Vector3(0, 0.76, 0))
	put(t, "Foam", torus(0.12, 0.2, m("cream", PLASTER), 14, 4), Vector3(0, 0.78, 0))
	put(t, "Heart", sph(0.07, m("cream", PLASTER), true, 8), Vector3(0, 0.77, 0))
	put(t, "Handle", torus(0.1, 0.17, m("white", PLASTER), 12, 6), Vector3(0.4, 0.45, 0), Vector3(90, 0, 0))
	put(t, "Stripe", torus(0.33, 0.38, m("red", PLASTER), 24, 4), Vector3(0, 0.2, 0))
	for k in 3:
		put(t, "Bean%d" % k, sph(0.05, m("coffee", PLASTER), false, 8), Vector3(-0.3 + 0.08 * float(k), 0.13, 0.33 + 0.02 * float(k % 2)))
	put(t, "Spoon", box(0.04, 0.02, 0.4, lib("metal")), Vector3(-0.22, 0.86, -0.1), Vector3(0, 30, 35))
	for k in 3:
		var s := osc(t, "Steam%d" % k, Vector3(-0.12 + 0.12 * float(k), 0.98 + 0.22 * float(k), 0.0), 0, 0, 0.06, 2.2, Vector3.UP, float(k))
		put(s, "Puff", sph(0.13 - 0.02 * float(k), m("white"), false, 10), Vector3.ZERO)


func _build_balloon_stand() -> void:
	put(_root, "Base", box(0.95, 0.1, 0.95, lib("path_stone")), Vector3(0, 0.05, 0))
	put(_root, "Cart", box(0.6, 0.35, 0.4, lib("wood")), Vector3(0, 0.44, 0.05))
	for k in 3:
		put(_root, "CartStripe%d" % k, box(0.1, 0.35, 0.41, m(["teal", "pink", "teal"][k], PANEL)), Vector3(-0.2 + 0.2 * float(k), 0.44, 0.05))
	put(_root, "CartTop", box(0.64, 0.05, 0.44, lib("wood_dark")), Vector3(0, 0.64, 0.05))
	put(_root, "Handle", torus(0.08, 0.1, lib("metal"), 10, 4), Vector3(0.0, 0.62, -0.25), Vector3(90, 0, 0))
	for s: float in [-1.0, 1.0]:
		var tag := "L" if s < 0 else "R"
		put(_root, "Wheel" + tag, cyl(0.16, 0.16, 0.05, m("dark", TREAD), 14), Vector3(0.33 * s, 0.26, 0.05), Vector3(0, 0, 90))
		put(_root, "WheelRim" + tag, torus(0.08, 0.12, m("gold", METAL), 12, 4), Vector3(0.36 * s, 0.26, 0.05), Vector3(0, 0, 90))
		put(_root, "Hubcap" + tag, sph(0.04, m("gold", METAL), false, 6), Vector3(0.36 * s, 0.26, 0.05))
	put(_root, "Leg", box(0.04, 0.2, 0.04, lib("metal")), Vector3(0, 0.2, -0.12))
	put(_root, "Sign", box(0.3, 0.14, 0.02, m("yellow", PANEL)), Vector3(0, 0.44, 0.26))
	for k in 3:
		put(_root, "SignDot%d" % k, cyl(0.03, 0.03, 0.01, m(["red", "blue", "pink"][k]), 8), Vector3(-0.08 + 0.08 * float(k), 0.44, 0.275), Vector3(90, 0, 0))
	put(_root, "Pump", cyl(0.05, 0.05, 0.22, m("red", METAL), 8), Vector3(0.22, 0.78, 0.18))
	put(_root, "PumpTop", box(0.12, 0.03, 0.03, lib("metal")), Vector3(0.22, 0.9, 0.18))
	var t := osc(_root, "Theme", Vector3(-0.05, 0.66, 0.05), 1, 0, deg_to_rad(5.0), 1.3, Vector3(0, 0, 1))
	put(t, "Holder", cyl(0.03, 0.03, 0.16, lib("metal"), 6), Vector3(0, 0.08, 0))
	var cols := ["red", "yellow", "blue", "pink", "mint", "purple", "orange", "red", "teal"]
	var pts := [Vector3(0, 1.25, 0), Vector3(-0.25, 1.05, 0.05), Vector3(0.26, 1.08, -0.05), Vector3(-0.12, 0.88, -0.22),
		Vector3(0.14, 0.9, 0.22), Vector3(-0.28, 0.8, 0.22), Vector3(0.3, 0.78, -0.24), Vector3(0.05, 1.1, 0.25), Vector3(-0.05, 1.0, -0.3)]
	for i in pts.size():
		var p: Vector3 = pts[i]
		put(t, "Balloon%d" % i, sph(0.17, m(cols[i], PLASTER), false, 10), p)
		put(t, "Shine%d" % i, sph(0.04, m("white"), false, 6), p + Vector3(-0.07, 0.07, 0.12))
		put(t, "Knot%d" % i, cyl(0.0, 0.04, 0.06, m(cols[i], PLASTER), 6), p + Vector3(0, -0.19, 0))
		stick(t, "String%d" % i, Vector3(0, 0.16, 0), p + Vector3(0, -0.21, 0), 0.008, m("white", CANVAS), 4)
	var bear := node(t, "MouseBalloon", Vector3(0.0, 1.5, 0.0))
	put(bear, "Head", sph(0.14, m("purple", PLASTER), false, 12), Vector3.ZERO)
	put(bear, "EarL", sph(0.07, m("purple", PLASTER), false, 8), Vector3(-0.12, 0.12, 0))
	put(bear, "EarR", sph(0.07, m("purple", PLASTER), false, 8), Vector3(0.12, 0.12, 0))
	eyes(bear, Vector3(0, 0.03, 0.12), 0.05, 0.03, "Eye")


func _build_souvenir_shop() -> void:
	put(_root, "Base", box(1.95, 0.1, 0.95, lib("path_stone")), Vector3(0, 0.05, 0))
	put(_root, "Hut", box(1.7, 0.7, 0.6, m("cream", PLASTER)), Vector3(0, 0.45, -0.1))
	put(_root, "Plinth", box(1.74, 0.14, 0.64, m("blue", BRICK)), Vector3(0, 0.17, -0.1))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			put(_root, "Beam%s%s" % ["L" if sx < 0 else "R", "B" if sz < 0 else "F"], box(0.06, 0.72, 0.06, lib("wood_dark")), Vector3(0.85 * sx, 0.46, -0.1 + 0.3 * sz))
	put(_root, "Roof", prism(0.8, 0.35, 1.84, lib("roof_tiles")), Vector3(0, 0.975, -0.1), Vector3(0, 90, 0))
	put(_root, "Eaves", box(1.84, 0.04, 0.04, lib("wood_dark")), Vector3(0, 0.81, 0.3))
	put(_root, "Counter", box(1.0, 0.06, 0.2, lib("wood_dark")), Vector3(0.3, 0.5, 0.28))
	put(_root, "CounterFront", box(0.96, 0.36, 0.03, lib("wood")), Vector3(0.3, 0.3, 0.37))
	put(_root, "Window", box(0.9, 0.3, 0.02, m("dark", PANEL)), Vector3(0.3, 0.64, 0.21))
	put(_root, "Door", box(0.28, 0.52, 0.03, m("blue", PLANKS)), Vector3(-0.6, 0.36, 0.21))
	put(_root, "DoorKnob", sph(0.025, m("gold", METAL), false, 6), Vector3(-0.5, 0.36, 0.235))
	put(_root, "DoorLamp", sph(0.04, glow("cream"), false, 6), Vector3(-0.6, 0.7, 0.26))
	for k in 4:
		put(_root, "Goods%d" % k, box(0.14, 0.14, 0.12, m(["red", "yellow", "mint", "pink"][k], PANEL)), Vector3(-0.08 + 0.25 * float(k), 0.6, 0.28))
	put(_root, "Bear", sph(0.07, m("brown", CANVAS), false, 8), Vector3(0.12, 0.6, 0.3))
	awning(_root, 1.1, 0.26, Vector3(0.3, 0.86, 0.36), "blue", "white", 8, -20.0)
	# Postkortstativ og ballonbuket ved døren.
	var rk := node(_root, "Rack", Vector3(-0.85, 0.1, 0.38))
	put(rk, "Pole", cyl(0.015, 0.015, 0.5, lib("metal"), 6), Vector3(0, 0.25, 0))
	for k in 3:
		put(rk, "Card%d" % k, box(0.12, 0.09, 0.01, m(["sky", "pink", "yellow"][k], PANEL)), Vector3(0, 0.2 + 0.11 * float(k), 0.02))
	put(_root, "Sign", box(0.5, 0.14, 0.03, m("gold", PANEL)), Vector3(0.3, 1.0, 0.25), Vector3(-15, 0, 0))
	for k in 5:
		put(_root, "SignLetter%d" % k, box(0.05, 0.08, 0.01, m("blue")), Vector3(0.1 + 0.1 * float(k), 1.0, 0.27), Vector3(-15, 0, 0))
	# Tema: kæmpe snekugle med parken i (på taget, ved siden af rygningen).
	var t := node(_root, "Theme", Vector3(0, 1.1, -0.1))
	put(t, "Stand", cyl(0.24, 0.3, 0.2, lib("wood_dark"), 16), Vector3(0, 0.1, 0))
	put(t, "StandBand", torus(0.25, 0.29, m("gold", METAL), 16, 4), Vector3(0, 0.12, 0))
	put(t, "Ground", cyl(0.27, 0.27, 0.04, m("white"), 16), Vector3(0, 0.22, 0))
	put(t, "Globe", sph(0.32, glass(), false, 18), Vector3(0, 0.45, 0))
	put(t, "MiniWheel", torus(0.1, 0.13, m("red", METAL), 12, 4), Vector3(-0.07, 0.43, 0), Vector3(90, 0, 0))
	put(t, "MiniTree", cyl(0.0, 0.07, 0.2, m("green"), 8), Vector3(0.12, 0.34, 0.03))
	put(t, "MiniTent", cyl(0.0, 0.08, 0.1, m("yellow"), 6), Vector3(0.05, 0.29, -0.12))
	for k in 6:
		var a := TAU * float(k) / 6.0
		put(t, "Flake%d" % k, sph(0.025, m("white"), false, 6), Vector3(cos(a) * 0.18, 0.5 + 0.06 * float(k % 3), sin(a) * 0.18))


## Sideshow-bod 2×1 med plankevægge, malede striber, disk, stribet tag, vimpler og præmiehylde.
func stall(color: String, stripe: String) -> void:
	put(_root, "Base", box(1.95, 0.1, 0.95, lib("path_stone")), Vector3(0, 0.05, 0))
	put(_root, "BackWall", box(1.8, 1.0, 0.1, lib("wood")), Vector3(0, 0.6, -0.38))
	put(_root, "BackPaint", box(1.6, 0.7, 0.02, m(color, PANEL)), Vector3(0, 0.65, -0.32))
	put(_root, "SideL", box(0.1, 1.0, 0.7, lib("wood")), Vector3(-0.85, 0.6, -0.05))
	put(_root, "SideR", box(0.1, 1.0, 0.7, lib("wood")), Vector3(0.85, 0.6, -0.05))
	for s: float in [-1.0, 1.0]:
		var tag := "L" if s < 0 else "R"
		put(_root, "SidePaint" + tag, box(0.11, 0.2, 0.71, m(color, PANEL)), Vector3(0.85 * s, 0.3, -0.05))
		put(_root, "Pillar" + tag, box(0.08, 1.04, 0.08, lib("wood_dark")), Vector3(0.85 * s, 0.62, 0.3))
	put(_root, "Counter", box(1.6, 0.42, 0.14, lib("wood")), Vector3(0, 0.31, 0.3))
	put(_root, "CounterTop", box(1.66, 0.04, 0.2, lib("wood_dark")), Vector3(0, 0.54, 0.3))
	for k in 4:
		put(_root, "CounterStripe%d" % k, box(0.18, 0.42, 0.01, m(stripe if k % 2 == 0 else "white", PANEL)), Vector3(-0.54 + 0.36 * float(k), 0.31, 0.375))
	put(_root, "Roof", box(1.9, 0.08, 0.86, m("white", CANVAS)), Vector3(0, 1.14, -0.02))
	for k in 6:
		put(_root, "RoofStripe%d" % k, box(0.16, 0.085, 0.87, m(stripe, CANVAS)), Vector3(-0.8 + 0.32 * float(k), 1.14, -0.02))
	for k in 5:
		put(_root, "Scallop%d" % k, sph(0.17, m(stripe if k % 2 == 0 else "white", CANVAS), true, 10), Vector3(-0.72 + 0.36 * float(k), 1.1, 0.4), Vector3(180, 0, 0))
	put(_root, "AwnTrim", box(1.9, 0.03, 0.03, m("gold", METAL)), Vector3(0, 1.1, 0.42))
	# Præmiehylde med bamser.
	put(_root, "Shelf", box(1.5, 0.04, 0.12, lib("wood_dark")), Vector3(0, 0.95, -0.28))
	for k in 5:
		var b := node(_root, "Prize%d" % k, Vector3(-0.6 + 0.3 * float(k), 0.97, -0.28))
		var c: String = ["pink", "sky", "yellow", "mint", "purple"][k]
		put(b, "Body", sph(0.06, m(c, CANVAS), false, 8), Vector3(0, 0.06, 0))
		put(b, "Head", sph(0.045, m(c, CANVAS), false, 8), Vector3(0, 0.15, 0))
		put(b, "EarL", sph(0.02, m(c, CANVAS), false, 6), Vector3(-0.035, 0.19, 0))
		put(b, "EarR", sph(0.02, m(c, CANVAS), false, 6), Vector3(0.035, 0.19, 0))
	bunting(_root, "Bunting", Vector3(-0.85, 1.05, 0.33), Vector3(0.85, 1.05, 0.33), 7, ["red", "yellow", "blue", "green"])


func _build_coconut_shy() -> void:
	stall("green", "yellow")
	for k in 3:
		var x := -0.5 + 0.5 * float(k)
		put(_root, "Post%d" % k, cyl(0.03, 0.03, 0.4, lib("wood_dark"), 6), Vector3(x, 0.3, -0.1))
		put(_root, "Cup%d" % k, cyl(0.06, 0.03, 0.04, lib("metal"), 8), Vector3(x, 0.51, -0.1))
		put(_root, "Nut%d" % k, sph(0.09, m("brown", CANVAS), false, 10), Vector3(x, 0.6, -0.1))
	put(_root, "Bucket", cyl(0.08, 0.06, 0.12, m("red", METAL), 10), Vector3(0.6, 0.62, 0.3))
	for k in 3:
		put(_root, "BucketBall%d" % k, sph(0.04, m("white", CANVAS), false, 6), Vector3(0.58 + 0.03 * float(k), 0.69, 0.3))
	# Tema: tre kæmpe kokosnødder på pinde over taget.
	var t := node(_root, "Theme", Vector3(0, 1.18, -0.1))
	for k in 3:
		var x := -0.6 + 0.6 * float(k)
		var h := 0.45 if k == 1 else 0.3
		put(t, "Stick%d" % k, cyl(0.04, 0.05, h, lib("wood_dark"), 8), Vector3(x, h * 0.5, 0))
		put(t, "Coconut%d" % k, sph(0.24, m("brown", CANVAS), false, 14), Vector3(x, h + 0.2, 0))
		for e in 3:
			var a := -0.5 + 0.5 * float(e)
			put(t, "Dot%d_%d" % [k, e], sph(0.04, m("dark"), false, 6), Vector3(x + a * 0.16, h + 0.32 - absf(a) * 0.08, 0.2))
	for k in 3:
		var a := TAU * float(k) / 3.0
		put(t, "Leaf%d" % k, prism(0.12, 0.4, 0.02, m("green", CANVAS)), Vector3(cos(a) * 0.15, 0.95, sin(a) * 0.15), Vector3(0, -rad_to_deg(a), -70))
	put(t, "Ball", sph(0.1, m("red"), false, 10), Vector3(0.95, 0.1, 0.25))


func _build_shooting_gallery() -> void:
	stall("red", "red")
	put(_root, "Stripe1", box(0.3, 0.7, 0.02, m("white", CANVAS)), Vector3(-0.45, 0.65, -0.305))
	put(_root, "Stripe2", box(0.3, 0.7, 0.02, m("white", CANVAS)), Vector3(0.45, 0.65, -0.305))
	put(_root, "RailTrack", box(1.4, 0.03, 0.04, lib("steel")), Vector3(0, 0.66, -0.25))
	var rail := osc(_root, "Targets", Vector3(0, 0.72, -0.25), 0, 0, 0.45, 1.2, Vector3(1, 0, 0))
	for k in 3:
		var d := node(rail, "TinDuck%d" % k, Vector3(-0.4 + 0.4 * float(k), 0, 0))
		put(d, "Body", cyl(0.1, 0.1, 0.03, m("gold", METAL), 10), Vector3.ZERO, Vector3(90, 0, 0))
		put(d, "Head", cyl(0.06, 0.06, 0.03, m("gold", METAL), 10), Vector3(0.08, 0.1, 0), Vector3(90, 0, 0))
		put(d, "Beak", box(0.05, 0.02, 0.03, m("orange")), Vector3(0.15, 0.1, 0))
	for k in 2:
		var r := node(_root, "Rifle%d" % k, Vector3(-0.3 + 0.6 * float(k), 0.6, 0.3), Vector3(0, 70 - 140 * float(k), 0))
		put(r, "Barrel", cyl(0.012, 0.012, 0.4, lib("metal"), 6), Vector3(0, 0, 0), Vector3(0, 0, 90))
		put(r, "Stock", box(0.18, 0.06, 0.04, lib("wood_dark")), Vector3(-0.22, -0.02, 0))
		put(r, "Chain", cyl(0.005, 0.005, 0.12, lib("metal"), 4), Vector3(-0.2, -0.08, 0))
	# Tema: stribet telt-top med kæmpe blikand.
	put(_root, "TentTop", cyl(0.0, 0.5, 0.45, m("red", CANVAS), 8), Vector3(0, 1.4, -0.02))
	for k in 4:
		var a := TAU * float(k) / 8.0 * 2.0
		put(_root, "TentStripe%d" % k, prism(0.18, 0.44, 0.02, m("white", CANVAS)), Vector3(cos(a) * 0.25, 1.4, sin(a) * 0.25 - 0.02), Vector3(0, 90 - rad_to_deg(a), 0))
	var t := node(_root, "Theme", Vector3(0, 1.6, 0.0))
	put(t, "Stand", box(0.08, 0.3, 0.08, lib("metal")), Vector3(0, 0.15, 0))
	put(t, "Body", cyl(0.36, 0.36, 0.08, m("gold", METAL), 20), Vector3(0, 0.55, 0), Vector3(90, 0, 0))
	put(t, "Head", cyl(0.2, 0.2, 0.08, m("gold", METAL), 16), Vector3(0.3, 0.9, 0), Vector3(90, 0, 0))
	put(t, "Beak", prism(0.2, 0.14, 0.08, m("orange", METAL)), Vector3(0.55, 0.9, 0), Vector3(0, 0, -90))
	put(t, "Eye", cyl(0.05, 0.05, 0.1, m("black"), 8), Vector3(0.36, 0.95, 0), Vector3(90, 0, 0))
	put(t, "Target", torus(0.12, 0.2, m("red", PANEL), 16, 4), Vector3(-0.05, 0.55, 0.05), Vector3(90, 0, 0))
	put(t, "Target2", torus(0.24, 0.3, m("white", PANEL), 18, 4), Vector3(-0.05, 0.55, 0.045), Vector3(90, 0, 0))
	put(t, "Bull", cyl(0.07, 0.07, 0.1, m("white"), 10), Vector3(-0.05, 0.55, 0.0), Vector3(90, 0, 0))
	put(t, "Wing", prism(0.32, 0.2, 0.1, m("orange", METAL)), Vector3(-0.22, 0.75, 0), Vector3(0, 0, 30))
	for k in 3:
		put(t, "Hole%d" % k, cyl(0.025, 0.025, 0.1, m("dark"), 6), Vector3(0.1 + 0.08 * float(k), 0.35 + 0.05 * float(k), 0.0), Vector3(90, 0, 0))


func _build_hook_a_duck() -> void:
	put(_root, "Base", box(0.95, 0.1, 0.95, lib("path_stone")), Vector3(0, 0.05, 0))
	put(_root, "Pool", cyl(0.42, 0.44, 0.3, m("red", PANEL), 20), Vector3(0, 0.25, 0))
	for k in 8:
		var a := TAU * float(k) / 8.0
		put(_root, "PoolStripe%d" % k, box(0.12, 0.3, 0.02, m("white", PANEL)), Vector3(cos(a) * 0.435, 0.25, sin(a) * 0.435), Vector3(0, 90 - rad_to_deg(a), 0))
	put(_root, "PoolRim", torus(0.4, 0.46, m("yellow", PANEL), 20, 6), Vector3(0, 0.4, 0))
	put(_root, "Water", cyl(0.38, 0.38, 0.02, m("sky", PANEL), 20), Vector3(0, 0.38, 0))
	put(_root, "Pole", cyl(0.04, 0.04, 0.85, m("white", METAL), 8), Vector3(0, 0.81, 0))
	put(_root, "PoleStripe", torus(0.035, 0.05, m("red", METAL), 8, 4), Vector3(0, 0.8, 0))
	put(_root, "Canopy", cyl(0.0, 0.48, 0.25, m("yellow", CANVAS), 10), Vector3(0, 1.32, 0))
	for k in 10:
		var a := TAU * (float(k) + 0.5) / 10.0
		put(_root, "CanScallop%d" % k, sph(0.07, m("red" if k % 2 == 0 else "yellow", CANVAS), true, 8), Vector3(cos(a) * 0.44, 1.2, sin(a) * 0.44), Vector3(180, 0, 0))
		if k % 2 == 0:
			stick(_root, "CanRib%d" % k, Vector3(0, 1.45, 0), Vector3(cos(a) * 0.48, 1.2, sin(a) * 0.48), 0.012, m("red", CANVAS), 4)
	for k in 2:
		var a := 0.4 + PI * float(k)
		stick(_root, "HookPole%d" % k, Vector3(cos(a) * 0.48, 0.1, sin(a) * 0.48), Vector3(cos(a) * 0.3, 0.75, sin(a) * 0.3), 0.012, lib("wood_dark"), 4)
	put(_root, "Sign", box(0.26, 0.14, 0.02, m("yellow", PANEL)), Vector3(0, 0.9, 0.05))
	put(_root, "SignDuck", sph(0.04, m("orange"), false, 6), Vector3(0, 0.9, 0.08))
	var ducks := spinner(_root, "Ducks", Vector3(0, 0.4, 0), 0.7)
	for k in 6:
		var a := TAU * float(k) / 6.0
		var d := node(ducks, "Duck%d" % k, Vector3(cos(a) * 0.27, 0, sin(a) * 0.27), Vector3(0, -rad_to_deg(a), 0))
		put(d, "Body", sph(0.05, m("yellow", PLASTER), false, 8), Vector3.ZERO)
		put(d, "Head", sph(0.035, m("yellow", PLASTER), false, 6), Vector3(0, 0.05, 0.03))
		put(d, "Beak", box(0.025, 0.012, 0.02, m("orange")), Vector3(0, 0.05, 0.065))
		put(d, "Ring", torus(0.01, 0.018, m("red"), 6, 4), Vector3(0, 0.1, 0.02), Vector3(90, 0, 0))
	# Tema: kæmpe gul and med fiskestang på taget.
	var t := node(_root, "Theme", Vector3(0, 1.46, 0))
	duck(t, "Duck", Vector3(0, 0.12, 0), 0.22)
	put(t, "Hat", cyl(0.09, 0.11, 0.1, m("blue", CANVAS), 10), Vector3(0, 0.48, 0.07))
	put(t, "HatBrim", cyl(0.15, 0.15, 0.015, m("blue", CANVAS), 12), Vector3(0, 0.43, 0.07))
	stick(t, "Rod", Vector3(0.15, 0.15, 0.15), Vector3(0.38, 0.55, 0.38), 0.015, lib("wood_dark"), 6)
	stick(t, "Line", Vector3(0.38, 0.55, 0.38), Vector3(0.38, 0.0, 0.38), 0.005, m("white"), 4)
	put(t, "Hook", torus(0.02, 0.035, lib("metal"), 8, 4), Vector3(0.38, -0.02, 0.38), Vector3(90, 0, 0))


func _build_strength_tester() -> void:
	put(_root, "Base", box(0.95, 0.1, 0.95, lib("path_stone")), Vector3(0, 0.05, 0))
	put(_root, "Platform", box(0.7, 0.08, 0.7, lib("wood")), Vector3(0, 0.14, 0.05))
	put(_root, "Pad", box(0.3, 0.12, 0.3, m("dark", TREAD)), Vector3(0, 0.22, 0.2))
	put(_root, "Lever", box(0.22, 0.04, 0.08, m("red", METAL)), Vector3(0, 0.3, 0.2))
	put(_root, "Board", box(0.36, 2.6, 0.1, lib("wood")), Vector3(0, 1.42, -0.2))
	put(_root, "BoardPaint", box(0.3, 2.5, 0.02, m("red", PANEL)), Vector3(0, 1.42, -0.145))
	for s: float in [-1.0, 1.0]:
		put(_root, "Frame" + ("L" if s < 0 else "R"), box(0.05, 2.62, 0.12, lib("wood_dark")), Vector3(0.2 * s, 1.42, -0.2))
		stick(_root, "Stay" + ("L" if s < 0 else "R"), Vector3(0.3 * s, 0.18, -0.4), Vector3(0.15 * s, 1.6, -0.26), 0.015, lib("metal"), 4)
	put(_root, "Rail", box(0.06, 2.5, 0.04, lib("steel")), Vector3(0, 1.42, -0.12))
	var puck := osc(_root, "Puck", Vector3(0, 0.29, -0.08), 0, 3, 2.25, 1.4)
	put(puck, "Body", cyl(0.07, 0.07, 0.1, m("yellow", METAL), 10), Vector3.ZERO)
	put(puck, "Star", cyl(0.05, 0.05, 0.02, m("red"), 5), Vector3(0, 0, 0.05), Vector3(90, 0, 0))
	put(_root, "Sign", box(0.5, 0.18, 0.04, m("yellow", PANEL)), Vector3(0, 0.6, 0.38))
	stick(_root, "SignPost", Vector3(0.3, 0.18, 0.38), Vector3(0.3, 0.55, 0.38), 0.015, lib("wood_dark"), 4)
	for k in 4:
		put(_root, "SignLetter%d" % k, box(0.06, 0.1, 0.01, m("red")), Vector3(-0.15 + 0.1 * float(k), 0.6, 0.405))
	# Tema: høj skala med kæmpe klokke og hammer.
	var t := node(_root, "Theme", Vector3(0, 0, 0))
	for k in 6:
		put(t, "Mark%d" % k, box(0.28 if k % 2 == 0 else 0.18, 0.06, 0.02, m(["green", "yellow", "orange", "red", "purple", "gold"][k], PANEL)),
			Vector3(0, 0.5 + 0.4 * float(k), -0.13))
		put(t, "Light%d" % k, sph(0.03, glow(["green", "yellow", "orange", "red", "purple", "gold"][k]), false, 6), Vector3(0.17, 0.5 + 0.4 * float(k), -0.13))
	put(t, "Bell", cyl(0.06, 0.26, 0.3, m("gold", METAL), 16), Vector3(0, 2.9, -0.18))
	put(t, "BellLip", torus(0.22, 0.29, m("gold", METAL), 16, 4), Vector3(0, 2.75, -0.18))
	put(t, "BellKnob", sph(0.07, m("gold", METAL), false, 8), Vector3(0, 3.08, -0.18))
	put(t, "Star", cyl(0.14, 0.14, 0.03, m("red", PANEL), 5), Vector3(0, 2.9, 0.1), Vector3(90, 0, 0))
	put(t, "HammerHandle", cyl(0.025, 0.025, 0.7, lib("wood"), 6), Vector3(0.3, 0.46, 0.25), Vector3(0, 0, 25))
	put(t, "HammerHead", cyl(0.1, 0.1, 0.3, m("dark", METAL), 12), Vector3(0.15, 0.79, 0.25), Vector3(0, 0, 90 + 25))
	put(t, "HammerBand", torus(0.09, 0.11, m("red", METAL), 12, 4), Vector3(0.15, 0.79, 0.25), Vector3(0, 0, 90 + 25))
