extends TestCase
## T-109: ParkColors og OverlayRenderer.


func test_viridis_ends() -> void:
	assert_true(ParkColors.viridis(0.0).is_equal_approx(ParkColors.VIRIDIS[0]))
	assert_true(ParkColors.viridis(1.0).is_equal_approx(ParkColors.VIRIDIS[4]))
	assert_true(ParkColors.overlay_color(&"litter", 1.0).is_equal_approx(ParkColors.VIRIDIS[0]))


func test_colorblind_ghost() -> void:
	var old := ParkColors.colorblind
	ParkColors.set_colorblind(false)
	var g := ParkColors.ghost(true)
	ParkColors.set_colorblind(true)
	assert_true(not ParkColors.ghost(true).is_equal_approx(g))
	assert_true(ParkColors.ghost(false).is_equal_approx(ParkColors.invalid(0.45)))
	ParkColors.set_colorblind(old)


func test_legend() -> void:
	for k in ParkColors.OVERLAY_KINDS:
		assert_eq(ParkColors.legend(k).size(), 3, String(k))


func test_overlay_show_hide() -> void:
	var o := OverlayRenderer.new()
	o._build()
	o.show_overlay(&"happiness", {"cells": {Vector2i(1, 1): 0.5, Vector2i(2, 1): 1.0}})
	assert_eq(o.tile_count(), 2)
	assert_eq(o.current_kind(), &"happiness")
	assert_true(o.visible)
	o.show_overlay(&"coverage", {"cells": [Vector2i(0, 0)]})
	assert_eq(o.tile_count(), 1)
	o.hide_overlay()
	assert_eq(o.current_kind(), &"")
	assert_true(not o.visible)
	o.free()
