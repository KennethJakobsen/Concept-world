class_name KartTrack
extends Spinner
## T-060: Kører børnene (karts) rundt langs banens midterlinje – et "stadion"
## (afrundet rektangel), der matcher den tegnede bane (Track minus Infield).
## Arver Spinner, så RideVisual styrer speed_scale (blød start/stop) som før.
## `speed` tolkes her som meter pr. sekund langs banen.

@export var half_x: float = 1.45  ## midterlinjens halve længde (x)
@export var half_z: float = 0.95  ## midterlinjens halve bredde (z)
@export var corner_radius: float = 0.3
@export var ride_height: float = 0.1

var _s: float = 0.0  ## tilbagelagt distance langs banen
var _placed: bool = false


func length() -> float:
	var sx := 2.0 * (half_x - corner_radius)
	var sz := 2.0 * (half_z - corner_radius)
	return 2.0 * (sx + sz) + TAU * corner_radius


## Punkt på midterlinjen ved distance s (mod-uret set ovenfra, start midt på +z-langsiden).
func point_at(s: float) -> Vector3:
	return _sample(s)[0]


func tangent_at(s: float) -> Vector3:
	return _sample(s)[1]


func _sample(s: float) -> Array[Vector3]:
	var r := corner_radius
	var ax := half_x - r
	var az := half_z - r
	var segs: Array[float] = [2.0 * ax, PI * r * 0.5, 2.0 * az, PI * r * 0.5, 2.0 * ax, PI * r * 0.5, 2.0 * az, PI * r * 0.5]
	var d := fposmod(s + ax, length())  # s=0 midt på +z-langsiden
	# Lige stykker (start, retning) og hjørnecentre i rækkefølge (mod uret: +x på +z-siden).
	var starts: Array[Vector3] = [Vector3(-ax, 0, half_z), Vector3(half_x, 0, az), Vector3(ax, 0, -half_z), Vector3(-half_x, 0, -az)]
	var dirs: Array[Vector3] = [Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT, Vector3.BACK]
	var centers: Array[Vector3] = [Vector3(ax, 0, az), Vector3(ax, 0, -az), Vector3(-ax, 0, -az), Vector3(-ax, 0, az)]
	for i in 8:
		if d <= segs[i] or i == 7:
			var k := i / 2
			if i % 2 == 0:
				return [starts[k] + dirs[k] * d, dirs[k]]
			# kvartcirkel: fra retning dirs[k] til dirs[k+1]
			var a := d / r
			var n0 := (starts[k] + dirs[k] * segs[i - 1] - centers[k]).normalized()
			var n := n0.rotated(Vector3.UP, a)
			var t := dirs[k].rotated(Vector3.UP, a)
			return [centers[k] + n * r, t]
		d -= segs[i]
	return [Vector3.ZERO, Vector3.RIGHT]


func _karts() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for c in get_children():
		if c is Node3D:
			out.append(c)
	return out


func _place() -> void:
	var karts := _karts()
	var L := length()
	for i in karts.size():
		var s := _s + L * float(i) / karts.size()
		var smp := _sample(s)
		var t: Vector3 = smp[1]
		var b := Basis(Vector3.UP.cross(t), Vector3.UP, t)  # lokal +Z = fremad (spoiler sidder bagerst på -Z)
		karts[i].transform = Transform3D(b, smp[0] + Vector3.UP * ride_height)
	_placed = true


func _process(delta: float) -> void:
	if speed_scale > 0.0001:
		_s = fposmod(_s + speed * speed_scale * delta, length())
		_place()
	elif not _placed:
		_place()


func _ready() -> void:
	_place()
