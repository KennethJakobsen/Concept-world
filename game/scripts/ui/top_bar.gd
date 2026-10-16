class_name TopBar
extends PanelContainer
## Top-bar (T-101, restylet T-138 §6.2): tre træskilte i en flow-række.
##   Venstre: penge-ikon + park-tal (tekst). Midt: dagsur + dato, glæde-smiley, omdømme-stjerner.
##   Højre: hastighed (pause/1x/2x/4x som medaljoner) og varsler-klokke med rødt badge.
## Første barn er en HFlowContainer, så Hud.layout kan beregne højden ved ombrydning.

signal pause_pressed
signal speed_pressed(speed: float)
signal bell_pressed

const SPEEDS: Array[float] = [1.0, 2.0, 4.0]
const SPEED_ICONS: Array[String] = ["speed_1", "speed_2", "speed_4"]
const BTN_PX: float = 34.0

var flow: HFlowContainer
var clock_icon: ClockIcon
var clock_label: Label
var label: Label
var smiley: UiIcons
var stars: StarRating
var pause_btn: Button
var speed_btns: Array[Button] = []
var bell_btn: Button
var bell_count: Label
var _badge: PanelContainer


func build() -> void:
	name = "TopBar"
	theme_type_variation = &"DockRoot"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 6)
	flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flow)
	# Venstre skilt: park-tal.
	var left: HBoxContainer = _sign("Money")
	left.add_child(UiTheme.icon_rect("money", 26.0))
	label = Label.new()
	label.name = "Stats"
	label.theme_type_variation = &"WoodLabel"
	label.add_theme_font_size_override("font_size", 16)
	left.add_child(label)
	# Midter-skilt: ur, glæde, stjerner.
	var mid: HBoxContainer = _sign("Status")
	var clock := HBoxContainer.new()
	clock.name = "Clock"
	clock.visible = false
	mid.add_child(clock)
	clock_icon = ClockIcon.new()
	clock_icon.custom_minimum_size = Vector2(26, 26)
	clock_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clock.add_child(clock_icon)
	clock_label = Label.new()
	clock_label.name = "ClockLabel"
	clock_label.theme_type_variation = &"WoodLabel"
	clock_label.add_theme_font_size_override("font_size", 16)
	clock.add_child(clock_label)
	smiley = UiIcons.new("smiley", 26.0)
	smiley.name = "Happiness"
	smiley.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	smiley.mouse_filter = Control.MOUSE_FILTER_PASS
	TooltipService.attach(smiley, "Gæsternes glæde", "Gennemsnit for alle gæster i parken")
	mid.add_child(smiley)
	stars = StarRating.new()
	stars.name = "ReputationStars"
	stars.star_size = 18.0
	stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stars.visible = false
	mid.add_child(stars)
	# Højre skilt: hastighed og klokke.
	var right: HBoxContainer = _sign("Controls")
	var speed := HBoxContainer.new()
	speed.name = "Speed"
	speed.add_theme_constant_override("separation", 4)
	right.add_child(speed)
	pause_btn = _btn(speed, "speed_pause", func() -> void: pause_pressed.emit())
	pause_btn.toggle_mode = true
	TooltipService.attach(pause_btn, "Pause", "Mellemrum")
	for i in SPEEDS.size():
		var s: float = SPEEDS[i]
		var b: Button = _btn(speed, SPEED_ICONS[i], func() -> void: speed_pressed.emit(s))
		b.toggle_mode = true
		TooltipService.attach(b, "Hastighed %dx" % int(s), "+ og - skifter hastighed")
		speed_btns.append(b)
	right.add_child(VSeparator.new())
	bell_btn = _btn(right, "bell", func() -> void: bell_pressed.emit())
	bell_btn.name = "Bell"
	_badge = PanelContainer.new()
	_badge.name = "Badge"
	var bs: StyleBoxFlat = UiTheme.box(UiTheme.RED, UiTheme.CREAM, 1, 8, 0, 1.0)
	bs.content_margin_left = 4.0
	bs.content_margin_right = 4.0
	_badge.add_theme_stylebox_override("panel", bs)
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.position = Vector2(BTN_PX - 14.0, -4.0)
	_badge.visible = false
	bell_btn.add_child(_badge)
	bell_count = Label.new()
	bell_count.name = "Count"
	bell_count.add_theme_font_size_override("font_size", 11)
	bell_count.add_theme_color_override("font_color", Color.WHITE)
	_badge.add_child(bell_count)
	TooltipService.attach(bell_btn, "Varsler", "Vis de seneste varsler igen")


func _sign(n: String) -> HBoxContainer:
	var p := PanelContainer.new()
	p.name = n
	p.theme_type_variation = &"PanelWood"
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.custom_minimum_size = Vector2(0, 44)
	flow.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	p.add_child(h)
	return h


func _btn(parent: Control, icon_id: String, cb: Callable) -> Button:
	var b: Button = UiTheme.medallion(icon_id, BTN_PX)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func set_unread(n: int) -> void:
	bell_count.text = str(n) if n > 0 else ""
	_badge.visible = n > 0


## Opdaterer tilstand for hastighedsknapperne.
func set_clock_state(paused: bool, speed: float) -> void:
	pause_btn.set_pressed_no_signal(paused)
	var tip: String = "Fortsæt" if paused else "Pause"
	if str(pause_btn.get_meta(TooltipService.META_TITLE, "")) != tip:
		TooltipService.attach(pause_btn, tip, "Mellemrum")
	for i in SPEEDS.size():
		speed_btns[i].set_pressed_no_signal(not paused and is_equal_approx(speed, SPEEDS[i]))


## T-113: pengeblink efter salg (+1 grøn) eller udgift (-1 rød); toner ud over 0,4 s.
var _flash_tween: Tween
var last_flash: int = 0


func flash_money(sign: int) -> void:
	last_flash = sign
	if label == null:
		return
	var c: Color = UiTheme.GREEN.lightened(0.35) if sign >= 0 else UiTheme.RED.lightened(0.25)
	label.add_theme_color_override("font_color", c)
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	if not is_inside_tree():
		return
	_flash_tween = create_tween()
	_flash_tween.tween_interval(0.4)
	_flash_tween.tween_callback(func() -> void: label.remove_theme_color_override("font_color"))
