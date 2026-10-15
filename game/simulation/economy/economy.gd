class_name Economy
extends RefCounted
## Parkens penge og bogføring pr. kategori og dag.
## Kategorier (brugt af ParkSim): "build", "path", "refund", "entry", "tickets", "running".

signal money_changed(money: int)

var money: int = 0
## Dagens totaler: kategori -> int (indtægter positive, udgifter negative).
var today: Dictionary = {}
## Afsluttede dage: Array af {"day": int, "totals": Dictionary, "net": int}.
var history: Array[Dictionary] = []


func _init(start_money: int = 0) -> void:
	money = start_money


func can_afford(amount: int) -> bool:
	return amount <= money


## Trækker beløbet hvis der er råd. Returnerer false ellers (intet ændres).
func spend(amount: int, category: String) -> bool:
	if amount < 0 or not can_afford(amount):
		return false
	_book(-amount, category)
	return true


## Trækker beløbet uanset saldo (fx driftsomkostninger) – kan give negativ saldo.
func charge(amount: int, category: String) -> void:
	_book(-absi(amount), category)


func earn(amount: int, category: String) -> void:
	if amount <= 0:
		return
	_book(amount, category)


func get_today_total(category: String) -> int:
	return int(today.get(category, 0))


## Afslutter dagen: gemmer totaler i history og nulstiller today.
func close_day(day: int) -> Dictionary:
	var net: int = 0
	for k: Variant in today:
		net += int(today[k])
	var entry: Dictionary = {"day": day, "totals": today.duplicate(), "net": net}
	history.append(entry)
	today = {}
	return entry


func _book(delta: int, category: String) -> void:
	if delta == 0:
		return
	money += delta
	today[category] = int(today.get(category, 0)) + delta
	money_changed.emit(money)


# --- Save/load (T-036) ---

func to_save() -> Dictionary:
	return {"money": money, "today": today.duplicate(), "history": history.duplicate(true)}


func load_save(d: Dictionary) -> void:
	money = int(d.get("money", money))
	today = SaveCodec.to_int_dict(d.get("today", {}))
	history.clear()
	for h: Variant in SaveCodec.arr(d, "history"):
		if h is Dictionary:
			history.append({"day": int(h.get("day", 0)), "totals": SaveCodec.to_int_dict(h.get("totals", {})),
				"net": int(h.get("net", 0))})
