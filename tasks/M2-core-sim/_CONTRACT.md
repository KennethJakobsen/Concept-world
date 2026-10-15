# M2 kontrakt – fælles for alle M2-tasks

## Bygninger (alle i `game/content/attractions/<id>.json`)
```json
{
  "id": "burger_stand", "name": "Burgerbod",
  "kind": "ride | shop | toilet",
  "footprint": [1, 1],
  "build_cost": 300,
  "running_cost_per_day": 20,
  "capacity": 2,
  "ride_ticks": 40,            // servicetid (ride: turens længde)
  "ticket_price": 4,           // default-pris; kan ændres in-game
  "excitement": 0,             // ride: glæde-gevinst (0..100)
  "satisfies": { "hunger": -70, "thirst": 10 },  // ændring af behov ved endt besøg
  "model": "res://scenes/props/burger_stand.tscn"
}
```
Indhold i M2 (id · kind · footprint):
- carousel · ride · 3×3 (findes)
- ferris_wheel · ride · 3×3
- bumper_cars · ride · 4×4
- burger_stand · shop · 1×1
- drinks_stand · shop · 1×1
- ice_cream_stand · shop · 1×1
- toilet · toilet · 1×1

Indgangscelle: midt under footprint (som i M1). Alle props: origo i footprint-centrum, y=0, front mod +Z (mod indgangscellen).

## Global balance
- `game/content/economy.json`: `{ "start_money", "entry_fee", "path_cost", "path_refund", "guest_money_min", "guest_money_max", "day_ticks" }`
- `game/content/guests.json`: `{ "needs": { "hunger": {"rate": per tick, "threshold"}, "thirst": {...}, "toilet": {...}, "energy": {...} }, "happiness_start", "happiness_decay_when_need_over_threshold", "leave_happiness", "spawn_interval_ticks", "max_guests", "speed" }`
Behov 0..100 (100 = akut). Glæde 0..100.

## Simulation API (tilføjelser)
- `class_name Economy extends RefCounted` (`game/simulation/economy/economy.gd`): `money: int`, `func can_afford(amount:int)->bool`, `func spend(amount:int, category:String)->bool`, `func earn(amount:int, category:String)`, `signal money_changed(money:int)`, `history`/daglige totaler pr. kategori.
- `ParkSim.economy: Economy`, `ParkSim.day: int`, `signal day_passed(day:int)`.
- Kommandoer fejler (returnerer false/null) hvis man ikke har råd: `cmd_place_path`, `cmd_place_attraction`. Ny: `cmd_remove_attraction(id)->bool` (refunderer 50%), `cmd_set_price(attraction_id, price:int)->bool`, `cmd_set_open(attraction_id, open:bool)->bool`, `cmd_set_entry_fee(fee:int)`.
- `Guest`: `money:int`, `happiness:float`, `needs: Dictionary` (navn→float), `thought: String` (kort dansk tekst, fx "Jeg er sulten!", "For dyrt!").
- `Attraction`: `is_open:bool`, `price:int`, `total_visitors:int`, `total_revenue:int`.
- Statistik: `ParkSim.get_stats() -> Dictionary` {guests, avg_happiness, money, day}.
