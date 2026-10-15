class_name SaveSlotList
extends VBoxContainer
## Scrollbar liste over gemte slots fra SaveStore. Udsender slot_chosen(slot).

signal slot_chosen(slot: String)

var store: SaveStore = SaveStore.new()
var _list: VBoxContainer
var _scroll: ScrollContainer


func build(height: float = 160.0) -> void:
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(0, height)
	add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	reload()


func set_height(h: float) -> void:
	if _scroll != null:
		_scroll.custom_minimum_size.y = h


func reload() -> void:
	if _list == null:
		return
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var slots: Array = store.list()
	if slots.is_empty():
		var l := Label.new()
		l.text = "Ingen gemte parker"
		_list.add_child(l)
	for slot: String in slots:
		var b := Button.new()
		b.text = "Autosave" if slot == SaveStore.AUTOSAVE_SLOT else slot
		b.name = "Slot_" + slot
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: slot_chosen.emit(slot))
		_list.add_child(b)


func slot_count() -> int:
	return store.list().size()
