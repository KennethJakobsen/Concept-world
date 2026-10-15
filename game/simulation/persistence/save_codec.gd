class_name SaveCodec
extends RefCounted
## Hjælpere til JSON-venlig (de)serialisering. JSON-tal parses som float → konvertér eksplicit.


const FLOAT_BITS_PREFIX: String = "f:"


## Float → JSON-værdi. Tal der ikke overlever JSON-roundtrip bit-præcist gemmes som "f:<int64-bits>".
static func f(x: float) -> Variant:
	if JSON.parse_string(JSON.stringify(x, "", false, true)) == x:
		return x
	var b := PackedFloat64Array([x]).to_byte_array()
	return FLOAT_BITS_PREFIX + str(b.decode_s64(0))


static func to_f(v: Variant, fallback: float = 0.0) -> float:
	if v is String:
		var s: String = v
		if s.begins_with(FLOAT_BITS_PREFIX):
			var b := PackedByteArray()
			b.resize(8)
			b.encode_s64(0, s.trim_prefix(FLOAT_BITS_PREFIX).to_int())
			return b.decode_double(0)
		return s.to_float()
	if v is float or v is int:
		return float(v)
	return fallback


## Dictionary String -> float til JSON.
static func float_dict(d: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k: Variant in d:
		out[str(k)] = f(float(d[k]))
	return out


static func v2i(v: Vector2i) -> Array:
	return [v.x, v.y]


static func to_v2i(a: Variant, fallback: Vector2i = Vector2i.ZERO) -> Vector2i:
	if a is Array and (a as Array).size() >= 2:
		return Vector2i(int(a[0]), int(a[1]))
	return fallback


static func v2i_array(arr: Array) -> Array:
	var out: Array = []
	for v: Vector2i in arr:
		out.append(v2i(v))
	return out


static func to_v2i_array(a: Variant) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if a is Array:
		for e: Variant in a:
			out.append(to_v2i(e))
	return out


static func to_int_array(a: Variant) -> Array[int]:
	var out: Array[int] = []
	if a is Array:
		for e: Variant in a:
			out.append(int(e))
	return out


## Utypet Array med ints (fx køer).
static func to_int_list(a: Variant) -> Array:
	var out: Array = []
	if a is Array:
		for e: Variant in a:
			out.append(int(e))
	return out


## Dictionary String -> int.
static func to_int_dict(a: Variant) -> Dictionary:
	var out: Dictionary = {}
	if a is Dictionary:
		for k: Variant in a:
			out[str(k)] = int(a[k])
	return out


## Dictionary String -> float.
static func to_float_dict(a: Variant) -> Dictionary:
	var out: Dictionary = {}
	if a is Dictionary:
		for k: Variant in a:
			out[str(k)] = to_f(a[k])
	return out


static func dict(d: Dictionary, key: String) -> Dictionary:
	var v: Variant = d.get(key, {})
	return v if v is Dictionary else {}


static func arr(d: Dictionary, key: String) -> Array:
	var v: Variant = d.get(key, [])
	return v if v is Array else []


## JSON-streng med fuld float-præcision (nødvendigt for determinisme efter load).
static func stringify(d: Dictionary) -> String:
	return JSON.stringify(d, "", false, true)


static func parse(text: String) -> Dictionary:
	var v: Variant = JSON.parse_string(text)
	return v if v is Dictionary else {}
