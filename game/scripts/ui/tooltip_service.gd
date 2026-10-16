class_name TooltipService
extends RefCounted
## Fælles tooltips (T-101): titel + brødtekst, 0,4 s forsinkelse. Bruger Godots indbyggede
## tooltip-system (virker med mus, også i browseren). Titel/brødtekst gemmes som metadata, så
## andre (fx LockOverlay) kan gendanne teksten.

const DELAY_SEC: float = 0.4
const META_TITLE: StringName = &"tooltip_title"
const META_BODY: StringName = &"tooltip_body"


## Sætter global forsinkelse (kaldes én gang af HUD'en).
static func install() -> void:
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec", DELAY_SEC)


static func attach(control: Control, title: String, body: String = "") -> void:
	if control == null:
		return
	control.set_meta(META_TITLE, title)
	control.set_meta(META_BODY, body)
	control.tooltip_text = compose(title, body)


static func compose(title: String, body: String) -> String:
	if body == "":
		return title
	if title == "":
		return body
	return title + "\n" + body


## Den tekst, attach() har givet kontrollen ("" hvis ingen).
static func text_for(control: Control) -> String:
	if control == null or not control.has_meta(META_TITLE):
		return ""
	return compose(str(control.get_meta(META_TITLE)), str(control.get_meta(META_BODY, "")))
