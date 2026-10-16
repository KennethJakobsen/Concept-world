class_name SalesBatcher
extends RefCounted
## T-111: Samler sim.sales_tick (building_id -> kr) i vinduer på WINDOW sekunder (kontrakt beslutning 5).
## add() kaldes pr. tick; advance(delta) returnerer den samlede sum pr. bygning, når vinduet lukker, ellers {}.

const WINDOW: float = 0.25

var _acc: Dictionary = {}  ## building_id -> int
var _t: float = 0.0


func add(sales: Dictionary) -> void:
	for id: Variant in sales:
		_acc[int(id)] = int(_acc.get(int(id), 0)) + int(sales[id])


func advance(delta: float) -> Dictionary:
	_t += delta
	if _t < WINDOW:
		return {}
	_t = 0.0
	var out: Dictionary = _acc
	_acc = {}
	return out


func pending() -> Dictionary:
	return _acc
