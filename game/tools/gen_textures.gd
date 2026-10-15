extends SceneTree
## T-059: Genererer de stiliserede, tilebare teksturer i res://assets/textures/.
## Kør: cd game && godot --headless --script res://tools/gen_textures.gd
## Alle teksturer er egne (procedurelt genereret, deterministisk seed) og
## overvejende lyse gråtoner, så materialets albedo_color farver dem.

const OUT := "res://assets/textures/"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_save(_grass(128), "grass")
	_save(_cobble(128), "cobble")
	_save(_planks(128), "planks")
	_save(_roof_tiles(128), "roof_tiles")
	_save(_brick(128), "brick")
	_save(_metal(64), "metal")
	_save(_plaster(64), "plaster")
	quit()


func _save(img: Image, name: String) -> void:
	var err := img.save_png(OUT + name + ".png")
	print("%s: %s" % [name, error_string(err)])


# --- periodisk value-noise -------------------------------------------------

func _hash(x: int, y: int, seed: int) -> float:
	var h := (x * 374761393 + y * 668265263 + seed * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0


func _vnoise(u: float, v: float, period: int, seed: int) -> float:
	var x0 := int(floor(u))
	var y0 := int(floor(v))
	var fx := u - x0
	var fy := v - y0
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _hash(posmod(x0, period), posmod(y0, period), seed)
	var b := _hash(posmod(x0 + 1, period), posmod(y0, period), seed)
	var c := _hash(posmod(x0, period), posmod(y0 + 1, period), seed)
	var d := _hash(posmod(x0 + 1, period), posmod(y0 + 1, period), seed)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


## fbm i [0,1]; (u,v) i [0,1) tile-koordinater.
func _fbm(u: float, v: float, base: int, octaves: int, seed: int) -> float:
	var sum := 0.0
	var amp := 0.5
	var norm := 0.0
	var p := base
	for o in octaves:
		sum += _vnoise(u * p, v * p, p, seed + o) * amp
		norm += amp
		amp *= 0.5
		p *= 2
	return sum / norm


func _gray(img: Image, x: int, y: int, g: float) -> void:
	g = clampf(g, 0.0, 1.0)
	img.set_pixel(x, y, Color(g, g, g))


# --- teksturer ---------------------------------------------------------------

func _grass(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var u := float(x) / s
			var v := float(y) / s
			var n := _fbm(u, v, 4, 4, 11)
			var blade := _hash(x, y, 5)
			var g := 0.86 + (n - 0.5) * 0.22 + (blade - 0.5) * 0.08
			# Gul-grøn tone; shaderen farver resten.
			img.set_pixel(x, y, Color(g * (0.97 + n * 0.06), g, g * 0.95))
	return img


func _cobble(s: int) -> Image:
	# Periodisk Worley: 6x6 celler med jitter.
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var cells := 6
	var pts := {}
	for cy in cells:
		for cx in cells:
			pts[Vector2i(cx, cy)] = Vector2(cx + 0.2 + 0.6 * _hash(cx, cy, 21), cy + 0.2 + 0.6 * _hash(cx, cy, 22))
	for y in s:
		for x in s:
			var p := Vector2(float(x) / s * cells, float(y) / s * cells)
			var c := Vector2i(int(p.x), int(p.y))
			var d1 := 99.0
			var d2 := 99.0
			var owner := Vector2i.ZERO
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var k := Vector2i(posmod(c.x + ox, cells), posmod(c.y + oy, cells))
					var q: Vector2 = pts[k] + Vector2(c.x + ox - k.x, c.y + oy - k.y)
					var d := p.distance_to(q)
					if d < d1:
						d2 = d1
						d1 = d
						owner = k
					elif d < d2:
						d2 = d
			var edge := smoothstep(0.04, 0.16, d2 - d1)
			var tone := 0.88 + (_hash(owner.x, owner.y, 23) - 0.5) * 0.14
			var n := _fbm(float(x) / s, float(y) / s, 8, 2, 24)
			_gray(img, x, y, lerpf(0.62, tone + (n - 0.5) * 0.08, edge))
	return img


func _planks(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var rows := 4
	for y in s:
		for x in s:
			var v := float(y) / s * rows
			var row := int(v)
			var fv := v - row
			var u := float(x) / s
			# Forskudt endestød pr. planke.
			var shift := _hash(row, 0, 31)
			var fu := fposmod(u + shift, 1.0)
			var grain := _vnoise(u * 2.0 + row * 3.0, v * 24.0, 24 * rows, 32)
			grain = _vnoise(u * 4.0, v * 6.0 + grain * 2.0, 6 * rows, 33) * 0.5 + grain * 0.5
			var tone := 0.86 + (_hash(row, 1, 34) - 0.5) * 0.12 + (grain - 0.5) * 0.12
			var seam := smoothstep(0.0, 0.06, fv) * smoothstep(1.0, 0.94, fv)
			var butt := smoothstep(0.0, 0.015, fu) * smoothstep(1.0, 0.985, fu)
			_gray(img, x, y, tone * lerpf(0.6, 1.0, minf(seam, butt)))
	return img


func _roof_tiles(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var rows := 6
	var cols := 6
	for y in s:
		for x in s:
			var v := float(y) / s * rows
			var row := int(v)
			var fv := v - row
			var u := float(x) / s * cols + (0.5 if row % 2 == 1 else 0.0)
			var col := int(floor(u))
			var fu := u - col
			# Afrundet nederkant: skygge ved bunden af hver række, buet.
			var arc := 1.0 - pow(abs(fu - 0.5) * 2.0, 2.0) * 0.35
			var shade := smoothstep(arc, arc - 0.25, fv)
			var side := smoothstep(0.0, 0.05, fu) * smoothstep(1.0, 0.95, fu)
			var tone := 0.88 + (_hash(posmod(col, cols), row, 41) - 0.5) * 0.14
			var n := _fbm(float(x) / s, float(y) / s, 8, 2, 42)
			var g := tone * lerpf(0.62, 1.0, shade * lerpf(0.75, 1.0, side)) + (n - 0.5) * 0.06
			_gray(img, x, y, g + (1.0 - fv) * 0.05)
	return img


func _brick(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var rows := 8
	var cols := 4
	for y in s:
		for x in s:
			var v := float(y) / s * rows
			var row := int(v)
			var fv := v - row
			var u := float(x) / s * cols + (0.5 if row % 2 == 1 else 0.0)
			var col := int(floor(u))
			var fu := u - col
			var m := smoothstep(0.0, 0.1, fv) * smoothstep(1.0, 0.9, fv) * smoothstep(0.0, 0.04, fu) * smoothstep(1.0, 0.96, fu)
			var tone := 0.84 + (_hash(posmod(col, cols), row, 51) - 0.5) * 0.16
			var n := _fbm(float(x) / s, float(y) / s, 8, 3, 52)
			_gray(img, x, y, lerpf(1.0, tone + (n - 0.5) * 0.1, m))
	return img


func _metal(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var u := float(x) / s
			var v := float(y) / s
			var streak := _vnoise(u * 2.0, v * 32.0, 32, 61)
			var n := _fbm(u, v, 4, 3, 62)
			_gray(img, x, y, 0.9 + (streak - 0.5) * 0.08 + (n - 0.5) * 0.1)
	return img


func _plaster(s: int) -> Image:
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var n := _fbm(float(x) / s, float(y) / s, 4, 4, 71)
			_gray(img, x, y, 0.9 + (n - 0.5) * 0.16 + (_hash(x, y, 72) - 0.5) * 0.04)
	return img
