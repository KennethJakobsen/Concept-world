class_name TopBar
extends PanelContainer
## Top-bar (T-101, GDD §4): dagsur + dato, penge/gæster (tekst), glæde-smiley i 5 trin,
## omdømme-stjerner, hastighed (pause/1x/2x/4x) og varsler-klokke. Første barn er en
## HFlowContainer, så Hud.layout kan beregne højden ved ombrydning.

signal pause_pressed
signal speed_pressed(speed: float)
signal bell_pressed

const SPEEDS: Array[float] = [1.0, 2.0, 4.0]

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


func build() -> void:
	name = "TopBar"
	mouse_filter = Control.MOUSE_FILTER_STOP
	flow = HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 12)
	add_child(flow)
	var clock := HBoxContainer.new()
	clock.name = "Clock"
	clock.visible = false
	flow.add_child(clock)
	clock_icon = ClockIcon.new()
	clock_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clock.add_child(clock_icon)
	clock_label = Label.new()
	clock_label.name = "ClockLabel"
	clock.add_child(clock_label)
	label = Label.new()
	label.name = "Stats"
	flow.add_child(label)
	smiley = UiIcons.new("smiley", 20.0)
	smiley.name = "Happiness"
	smiley.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	smiley.mouse_filter = Control.MOUSE_FILTER_PASS
	TooltipService.attach(smiley, "Gæsternes glæde", "Gennemsnit for alle gæster i parken")
	flow.add_child(smiley)
	stars = StarRating.new()
	stars.name = "ReputationStars"
	stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stars.visible = false
	flow.add_child(stars)
	var speed := HBoxContainer.new()
	speed.name = "Speed"
	flow.add_child(speed)
	pause_btn = _btn(speed, "Pause", func() -> void: pause_pressed.emit())
	TooltipService.attach(pause_btn, "Pause", "Mellemrum")
	for s: float in SPEEDS:
		var b: Button = _btn(speed, "%dx" % int(s), func() -> void: speed_pressed.emit(s))
		b.toggle_mode = true
		TooltipService.attach(b, "Hastighed %dx" % int(s), "+ og - skifter hastighed")
		speed_btns.append(b)
	bell_btn = _btn(flow, "", func() -> void: bell_pressed.emit())
	bell_btn.name = "Bell"
	bell_btn.custom_minimum_size = Vector2(44, 28)
	var ic := UiIcons.new("bell", 18.0)
	ic.position = Vector2(4, 5)
	ic.color = Color(0.95, 0.85, 0.4)
	bell_btn.add_child(ic)
	bell_count = Label.new()
	bell_count.name = "Count"
	bell_count.position = Vector2(24, 3)
	bell_btn.add_child(bell_count)
	TooltipService.attach(bell_btn, "Varsler", "Vis de seneste varsler igen")


func _btn(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func set_unread(n: int) -> void:
	bell_count.text = str(n) if n > 0 else ""


## Opdaterer tilstand for hastighedsknapperne.
func set_clock_state(paused: bool, speed: float) -> void:
	pause_btn.text = "Fortsæt" if paused else "Pause"
	for i in SPEEDS.size():
		speed_btns[i].set_pressed_no_signal(not paused and is_equal_approx(speed, SPEEDS[i]))
