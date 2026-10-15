extends TestCase


func test_advances_fixed_ticks() -> void:
	var clock := SimClock.new()
	assert_eq(clock.advance(1.0), SimClock.TICKS_PER_SECOND)
	assert_eq(clock.tick, SimClock.TICKS_PER_SECOND)


func test_paused_does_not_tick() -> void:
	var clock := SimClock.new()
	clock.paused = true
	assert_eq(clock.advance(1.0), 0)


func test_speed_multiplies_ticks() -> void:
	var clock := SimClock.new()
	clock.speed = 2.0
	assert_eq(clock.advance(1.0), SimClock.TICKS_PER_SECOND * 2)
