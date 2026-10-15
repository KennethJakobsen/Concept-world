class_name SimClock
extends RefCounted
## Fast simulation-tick, uafhængig af framerate.

signal ticked(tick: int)

const TICKS_PER_SECOND: int = 20
const TICK_DELTA: float = 1.0 / TICKS_PER_SECOND

var tick: int = 0
var speed: float = 1.0
var paused: bool = false
var _accumulator: float = 0.0


## Kaldes med frame-delta; returnerer antal udførte ticks.
func advance(delta: float) -> int:
	if paused:
		return 0
	_accumulator += delta * speed
	var count: int = 0
	while _accumulator >= TICK_DELTA - 1e-6:
		_accumulator -= TICK_DELTA
		tick += 1
		count += 1
		ticked.emit(tick)
	return count
