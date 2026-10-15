class_name Balance
extends RefCounted
## Global balance (economy.json + guests.json) med defaults hvis felter/filer mangler.

const ECONOMY_PATH: String = "res://content/economy.json"
const GUESTS_PATH: String = "res://content/guests.json"
const PARK_PATH: String = "res://content/park.json"
const STAFF_RULES_PATH: String = "res://content/staff_rules.json"

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
## Startværdi for behov trækkes i [0, need_start_max] (GDD: 0–30).
var need_start_max: float = 30.0
## Gæsten går hjem når energy >= denne værdi (GDD: 100).
var leave_energy: float = 100.0
## Prisvurdering (GDD):
##   forlystelse: max = ride_price_base + excitement * ride_price_per_excitement
##   bod/toilet:  max = ticket_price(default) * (1 + behov / 100)
##   begge:       max *= happiness_price_base + happiness * happiness_price_factor
var ride_price_base: float = 2.0
var ride_price_per_excitement: float = 0.2
var happiness_price_base: float = 0.75
var happiness_price_factor: float = 0.005
## Ældre nøgler fra T-020 (ubrugt efter T-025, bevaret for kompatibilitet).
var price_tolerance: float = 1.5
var excitement_value: float = 0.1
## Glæde-tab når en gæst afviser pga. pris / ikke finder noget til et akut behov.
var reject_happiness_penalty: float = 2.0
## Glæde-gevinst ved at få dækket et behov over tærsklen.
var need_relief_happiness: float = 5.0


# Tiltrækning/omdømme (park.json, T-029). has_park = false → fast spawn-interval (legacy).
var has_park: bool = false
var weight_ride: float = 1.0
var weight_facility: float = 5.0
var reputation_start: float = 50.0
var reputation_learn_rate: float = 0.02
var expected_entry_fee_per_score: float = 1.0
var price_penalty_factor: float = 1.0
var price_penalty_max: float = 0.9
var spawn_per_score: float = 8.0
var reputation_mult_base: float = 0.5
var spawn_min_per_day: float = 10.0
var spawn_max_per_day: float = 400.0
var max_guests_base: int = 20
var max_guests_per_capacity: float = 2.0
## T-033: maks kølængde = capacity × queue_max_cycles (0 = ubegrænset). Fuld kø → "Køen er for lang!".
var queue_max_cycles: float = 3.0
## T-033: glæde-tab når en gæst opgiver en fuld kø.
var queue_full_happiness_penalty: float = 1.0

# Personale/affald/dekoration (staff_rules.json, T-035/T-037)
var litter_chance_after_shop: float = 0.5
var litter_chance_with_bin: float = 0.1
var bin_radius: int = 4
var bin_capacity: int = 20
var litter_max_per_cell: int = 5
## T-043: gæsten bærer varen og smider affaldet efter 1..litter_carry_cells sti-celler.
var litter_carry_cells: int = 8
var dirty_threshold: int = 2
var happiness_penalty_dirty_per_tick: float = 0.05
var thought_dirty: String = "Her er beskidt!"
var cleaner_sweep_ticks: int = 20
var cleaner_empty_bin_ticks: int = 30
var bench_energy_restore: float = -30.0
var bench_rest_ticks: int = 60
var bench_seek_energy: float = 70.0
var decor_aura_max_per_tick: float = 0.03
var aura_scale_per_tick: float = 0.01
var entertainer_happiness_per_tick: float = 0.03
var mechanic_inspect_interval_ticks: int = 1200
var inspection_reliability_bonus: float = 0.01
var inspection_ticks: int = 40
var thought_broken: String = "Den er i stykker!"


## park tom → legacy-spawn (spawn_interval_ticks/max_guests fra guests).
static func from_dicts(economy: Dictionary, guests: Dictionary, park: Dictionary = {},
		staff_rules: Dictionary = {}) -> Balance:
	var b := Balance.new()
	b.litter_chance_after_shop = float(staff_rules.get("litter_chance_after_shop", b.litter_chance_after_shop))
	b.litter_chance_with_bin = float(staff_rules.get("litter_chance_with_bin", b.litter_chance_with_bin))
	b.bin_radius = int(staff_rules.get("bin_radius", b.bin_radius))
	b.bin_capacity = int(staff_rules.get("bin_capacity", b.bin_capacity))
	b.litter_max_per_cell = int(staff_rules.get("litter_max_per_cell", b.litter_max_per_cell))
	b.litter_carry_cells = int(staff_rules.get("litter_carry_cells", b.litter_carry_cells))
	b.dirty_threshold = int(staff_rules.get("dirty_threshold", b.dirty_threshold))
	b.happiness_penalty_dirty_per_tick = float(staff_rules.get("happiness_penalty_dirty_per_tick", b.happiness_penalty_dirty_per_tick))
	b.thought_dirty = str(staff_rules.get("thought_dirty", b.thought_dirty))
	b.cleaner_sweep_ticks = int(staff_rules.get("cleaner_sweep_ticks", b.cleaner_sweep_ticks))
	b.cleaner_empty_bin_ticks = int(staff_rules.get("cleaner_empty_bin_ticks", b.cleaner_empty_bin_ticks))
	b.bench_energy_restore = float(staff_rules.get("bench_energy_restore", b.bench_energy_restore))
	b.bench_rest_ticks = int(staff_rules.get("bench_rest_ticks", b.bench_rest_ticks))
	b.bench_seek_energy = float(staff_rules.get("bench_seek_energy", b.bench_seek_energy))
	b.decor_aura_max_per_tick = float(staff_rules.get("decor_aura_max_per_tick", b.decor_aura_max_per_tick))
	b.aura_scale_per_tick = float(staff_rules.get("aura_scale_per_tick", b.aura_scale_per_tick))
	b.entertainer_happiness_per_tick = float(staff_rules.get("entertainer_happiness_per_tick", b.entertainer_happiness_per_tick))
	b.mechanic_inspect_interval_ticks = int(staff_rules.get("mechanic_inspect_interval_ticks", b.mechanic_inspect_interval_ticks))
	b.inspection_reliability_bonus = float(staff_rules.get("inspection_reliability_bonus", b.inspection_reliability_bonus))
	b.inspection_ticks = int(staff_rules.get("inspection_ticks", b.inspection_ticks))
	b.thought_broken = str(staff_rules.get("thought_broken", b.thought_broken))
	b.has_park = not park.is_empty()
	b.weight_ride = float(park.get("weight_ride", b.weight_ride))
	b.weight_facility = float(park.get("weight_facility", b.weight_facility))
	b.reputation_start = float(park.get("reputation_start", b.reputation_start))
	b.reputation_learn_rate = float(park.get("reputation_learn_rate", b.reputation_learn_rate))
	b.expected_entry_fee_per_score = float(park.get("expected_entry_fee_per_score", b.expected_entry_fee_per_score))
	b.price_penalty_factor = float(park.get("price_penalty_factor", b.price_penalty_factor))
	b.price_penalty_max = float(park.get("price_penalty_max", b.price_penalty_max))
	b.spawn_per_score = float(park.get("spawn_per_score", b.spawn_per_score))
	b.reputation_mult_base = float(park.get("reputation_mult_base", b.reputation_mult_base))
	b.spawn_min_per_day = float(park.get("spawn_min_per_day", b.spawn_min_per_day))
	b.spawn_max_per_day = float(park.get("spawn_max_per_day", b.spawn_max_per_day))
	b.max_guests_base = int(park.get("max_guests_base", b.max_guests_base))
	b.max_guests_per_capacity = float(park.get("max_guests_per_capacity", b.max_guests_per_capacity))
	b.queue_max_cycles = float(park.get("queue_max_cycles", b.queue_max_cycles))
	b.queue_full_happiness_penalty = float(park.get("queue_full_happiness_penalty", b.queue_full_happiness_penalty))
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
	b.leave_energy = float(guests.get("leave_energy", b.leave_energy))
	b.ride_price_base = float(guests.get("ride_price_base", b.ride_price_base))
	b.ride_price_per_excitement = float(guests.get("ride_price_per_excitement", b.ride_price_per_excitement))
	b.happiness_price_base = float(guests.get("happiness_price_base", b.happiness_price_base))
	b.happiness_price_factor = float(guests.get("happiness_price_factor", b.happiness_price_factor))
	b.price_tolerance = float(guests.get("price_tolerance", b.price_tolerance))
	b.excitement_value = float(guests.get("excitement_value", b.excitement_value))
	b.reject_happiness_penalty = float(guests.get("reject_happiness_penalty", b.reject_happiness_penalty))
	b.need_relief_happiness = float(guests.get("need_relief_happiness", b.need_relief_happiness))
	return b


static func load_default() -> Balance:
	return from_dicts(_read(ECONOMY_PATH), _read(GUESTS_PATH), _read(PARK_PATH), _read(STAFF_RULES_PATH))


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}


func need_threshold(need: String) -> float:
	return float((needs.get(need, {}) as Dictionary).get("threshold", 100.0))
