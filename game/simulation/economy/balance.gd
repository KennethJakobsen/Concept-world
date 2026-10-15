class_name Balance
extends RefCounted
## Global balance (economy.json + guests.json) med defaults hvis felter/filer mangler.

const ECONOMY_PATH: String = "res://content/economy.json"
const GUESTS_PATH: String = "res://content/guests.json"

# Økonomi
var start_money: int = 2500
var entry_fee: int = 10
var path_cost: int = 10
var path_refund: int = 5
var guest_money_min: int = 30
var guest_money_max: int = 80
var day_ticks: int = 2400

# Gæster
## behov -> {"rate": float pr. tick, "threshold": float}
var needs: Dictionary = {
	"hunger": {"rate": 0.03, "threshold": 60.0},
	"thirst": {"rate": 0.04, "threshold": 60.0},
	"toilet": {"rate": 0.02, "threshold": 70.0},
	"energy": {"rate": 0.015, "threshold": 80.0},
}
var happiness_start: float = 70.0
var happiness_decay_when_need_over_threshold: float = 0.02
var leave_happiness: float = 20.0
var spawn_interval_ticks: int = 40
var max_guests: int = 50
var speed: float = 0.1
## Startværdi for behov trækkes i [0, need_start_max].
var need_start_max: float = 20.0
## Prisvurdering: værdi = ticket_price(default) * price_tolerance + excitement * excitement_value.
var price_tolerance: float = 1.5
var excitement_value: float = 0.1
## Glæde-tab når en gæst afviser pga. pris / ikke finder noget til et akut behov.
var reject_happiness_penalty: float = 5.0
## Glæde-gevinst ved at få dækket et behov over tærsklen.
var need_relief_happiness: float = 5.0


static func from_dicts(economy: Dictionary, guests: Dictionary) -> Balance:
	var b := Balance.new()
	b.start_money = int(economy.get("start_money", b.start_money))
	b.entry_fee = int(economy.get("entry_fee", b.entry_fee))
	b.path_cost = int(economy.get("path_cost", b.path_cost))
	b.path_refund = int(economy.get("path_refund", b.path_refund))
	b.guest_money_min = int(economy.get("guest_money_min", b.guest_money_min))
	b.guest_money_max = int(economy.get("guest_money_max", b.guest_money_max))
	b.day_ticks = maxi(1, int(economy.get("day_ticks", b.day_ticks)))
	var n: Variant = guests.get("needs", null)
	if n is Dictionary:
		var out: Dictionary = {}
		for k: Variant in n:
			var nd: Dictionary = n[k] if n[k] is Dictionary else {}
			out[str(k)] = {"rate": float(nd.get("rate", 0.0)), "threshold": float(nd.get("threshold", 100.0))}
		b.needs = out
	b.happiness_start = float(guests.get("happiness_start", b.happiness_start))
	b.happiness_decay_when_need_over_threshold = float(guests.get(
		"happiness_decay_when_need_over_threshold", b.happiness_decay_when_need_over_threshold))
	b.leave_happiness = float(guests.get("leave_happiness", b.leave_happiness))
	b.spawn_interval_ticks = int(guests.get("spawn_interval_ticks", b.spawn_interval_ticks))
	b.max_guests = int(guests.get("max_guests", b.max_guests))
	b.speed = float(guests.get("speed", b.speed))
	b.need_start_max = float(guests.get("need_start_max", b.need_start_max))
	b.price_tolerance = float(guests.get("price_tolerance", b.price_tolerance))
	b.excitement_value = float(guests.get("excitement_value", b.excitement_value))
	b.reject_happiness_penalty = float(guests.get("reject_happiness_penalty", b.reject_happiness_penalty))
	b.need_relief_happiness = float(guests.get("need_relief_happiness", b.need_relief_happiness))
	return b


static func load_default() -> Balance:
	return from_dicts(_read(ECONOMY_PATH), _read(GUESTS_PATH))


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


func need_threshold(need: String) -> float:
	return float((needs.get(need, {}) as Dictionary).get("threshold", 100.0))
