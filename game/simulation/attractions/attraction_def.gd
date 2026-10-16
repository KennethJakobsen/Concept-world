class_name AttractionDef
extends Resource
## Statiske data for en attraktionstype (indlæses fra JSON).

@export var id: String = ""
@export var name: String = ""
@export var footprint: Vector2i = Vector2i(1, 1)
@export var capacity: int = 1
@export var ride_ticks: int = 20
@export var ticket_price: int = 0
@export var kind: String = "ride"  ## ride | shop | toilet
@export var build_cost: int = 0
@export var running_cost_per_day: int = 0
@export var excitement: int = 0
@export var satisfies: Dictionary = {}  ## behov -> ændring ved endt besøg
@export var model: String = ""
## Sandsynlighed for IKKE at bryde ned pr. tur (1 = aldrig; shops/toiletter).
@export var reliability: float = 1.0
@export var repair_ticks: int = 150
## Rutsjebane (T-068): tog-id og maks højde i niveauer.
@export var train: String = ""
@export var max_height: int = 8
## M6 (T-084): intensitet og kvalme 0..100 (rutsjebaner: ratings × 10).
@export var intensity: float = 0.0
@export var nausea: float = 0.0
## M6 (T-085): sideshow-præmier.
@export var win_chance: float = 0.0
@export var prize_cost: int = 0
@export var prize_happiness: float = 0.0
@export var prize_item: String = ""
@export var carry_item: String = ""  ## T-086: shop-køb giver denne ting
## T-090: vandbane – tørst-ændring efter en tur (negativ = mindre tørst).
@export var wet_thirst: float = 0.0
## T-091: transport – vægt for kanten i stigrafen.
@export var transport_cost: float = 4.0
## M7 (T-102): justerbar konfiguration {capacity|ride_ticks|speed: {min,max,default}}.
@export var config: Dictionary = {}
## M7 (T-102): valgfrie opskrifter (shops) [{id, name, cost_per_sale, satisfies, happiness, price_tolerance}].
@export var recipes: Array[Dictionary] = []
## M7 (T-102): prisvirkninger [{below_ratio, extra_purchase_chance, nausea, thought}].
@export var price_effects: Array[Dictionary] = []
## M7 (T-104): hæveautomat (kind "atm").
@export var withdraw_min: int = 20
@export var withdraw_max: int = 50
@export var fee: int = 0
@export var max_per_visit: int = 2
@export var range_cells: int = 30
@export var min_happiness: float = 40.0
## M7 (T-133): sporstykker der skal være låst op, før banen kan startes (tom = ingen krav).
@export var required_pieces: Array[String] = []


static func from_dict(d: Dictionary) -> AttractionDef:
	var def := AttractionDef.new()
	def.id = str(d.get("id", ""))
	def.name = str(d.get("name", def.id))
	var fp: Array = d.get("footprint", [1, 1])
	def.footprint = Vector2i(int(fp[0]), int(fp[1]))
	def.capacity = int(d.get("capacity", 1))
	def.ride_ticks = int(d.get("ride_ticks", 20))
	def.ticket_price = int(d.get("ticket_price", 0))
	def.kind = str(d.get("kind", "ride"))
	def.build_cost = int(d.get("build_cost", 0))
	def.running_cost_per_day = int(d.get("running_cost_per_day", 0))
	def.excitement = int(d.get("excitement", 0))
	var sat: Variant = d.get("satisfies", {})
	if sat is Dictionary:
		for k: Variant in sat:
			def.satisfies[str(k)] = float(sat[k])
	def.model = str(d.get("model", ""))
	def.reliability = clampf(float(d.get("reliability", 1.0)), 0.0, 1.0)
	def.repair_ticks = int(d.get("repair_ticks", 150))
	def.train = str(d.get("train", ""))
	def.max_height = int(d.get("max_height", 8))
	def.intensity = clampf(float(d.get("intensity", 0.0)), 0.0, 100.0)
	def.nausea = clampf(float(d.get("nausea", 0.0)), 0.0, 100.0)
	def.win_chance = clampf(float(d.get("win_chance", 0.0)), 0.0, 1.0)
	def.prize_cost = maxi(0, int(d.get("prize_cost", 0)))
	def.prize_happiness = float(d.get("prize_happiness", 0.0))
	def.prize_item = str(d.get("prize_item", ""))
	def.carry_item = str(d.get("carry_item", ""))
	def.wet_thirst = float(d.get("wet_thirst", 0.0))
	def.transport_cost = maxf(0.0, float(d.get("transport_cost", 4.0)))
	var cfg: Variant = d.get("config", {})
	if cfg is Dictionary:
		for k: Variant in cfg:
			var e: Variant = cfg[k]
			if e is Dictionary:
				var lo: float = float(e.get("min", 0.0))
				var hi: float = maxf(lo, float(e.get("max", lo)))
				def.config[str(k)] = {"min": lo, "max": hi, "default": clampf(float(e.get("default", lo)), lo, hi)}
	var rec: Variant = d.get("recipes", [])
	if rec is Array:
		for r: Variant in rec:
			if r is Dictionary and str(r.get("id", "")) != "":
				def.recipes.append(_recipe(r))
	var pe: Variant = d.get("price_effects", [])
	if pe is Array:
		for e: Variant in pe:
			if e is Dictionary:
				def.price_effects.append({"below_ratio": float(e.get("below_ratio", 0.0)),
					"extra_purchase_chance": clampf(float(e.get("extra_purchase_chance", 0.0)), 0.0, 1.0),
					"nausea": float(e.get("nausea", 0.0)), "thought": str(e.get("thought", ""))})
	var wd: Variant = d.get("withdraw", {})
	if wd is Dictionary:
		def.withdraw_min = maxi(0, int(wd.get("min", def.withdraw_min)))
		def.withdraw_max = maxi(def.withdraw_min, int(wd.get("max", def.withdraw_max)))
	def.fee = maxi(0, int(d.get("fee", 0)))
	def.max_per_visit = maxi(0, int(d.get("max_per_visit", def.max_per_visit)))
	def.range_cells = maxi(0, int(d.get("range_cells", def.range_cells)))
	def.min_happiness = float(d.get("min_happiness", def.min_happiness))
	var rp: Variant = d.get("required_pieces", [])
	if rp is Array:
		for p: Variant in rp:
			def.required_pieces.append(str(p))
	return def


static func _recipe(r: Dictionary) -> Dictionary:
	var sat: Dictionary = {}
	var rs: Variant = r.get("satisfies", {})
	if rs is Dictionary:
		for k: Variant in rs:
			sat[str(k)] = float(rs[k])
	return {"id": str(r["id"]), "name": str(r.get("name", r["id"])),
		"cost_per_sale": maxf(0.0, float(r.get("cost_per_sale", 0.0))), "satisfies": sat,
		"happiness": float(r.get("happiness", 0.0)), "price_tolerance": float(r.get("price_tolerance", 0.0))}


func recipe(recipe_id: String) -> Dictionary:
	for r in recipes:
		if str(r["id"]) == recipe_id:
			return r
	return {}


static func from_json(path: String) -> AttractionDef:
	var text: String = FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		push_error("AttractionDef: kunne ikke læse %s" % path)
		return null
	return from_dict(data)


## JSON-venlig snapshot (samme skema som content-JSON).
func to_dict() -> Dictionary:
	return {
		"id": id, "name": name, "kind": kind, "footprint": [footprint.x, footprint.y],
		"build_cost": build_cost, "running_cost_per_day": running_cost_per_day,
		"capacity": capacity, "ride_ticks": ride_ticks, "ticket_price": ticket_price,
		"excitement": excitement, "satisfies": satisfies.duplicate(), "model": model,
		"reliability": reliability, "repair_ticks": repair_ticks,
		"train": train, "max_height": max_height,
		"intensity": intensity, "nausea": nausea,
		"win_chance": win_chance, "prize_cost": prize_cost, "prize_happiness": prize_happiness,
		"prize_item": prize_item, "carry_item": carry_item,
		"wet_thirst": wet_thirst, "transport_cost": transport_cost,
		"config": config.duplicate(true), "recipes": recipes.duplicate(true),
		"price_effects": price_effects.duplicate(true),
		"withdraw": {"min": withdraw_min, "max": withdraw_max}, "fee": fee, "max_per_visit": max_per_visit,
		"range_cells": range_cells, "min_happiness": min_happiness,
		"required_pieces": required_pieces.duplicate(),
	}


## ADR-004: sporbaseret kind (coaster, flume, train, transport).
func is_tracked() -> bool:
	return CoasterContent.is_tracked_kind(kind)


func track_system() -> StringName:
	return CoasterContent.system_for_kind(kind)
