class_name Selection
extends Node
## Delt valg-/værktøjsbus mellem gameplay (BuildTool) og UI. Findes i gruppen "selection".
## Ingen logik – kun signaler.

signal selected_attraction(id: int)
signal selected_guest(id: int)
signal selected_staff(id: int)
signal cleared
## def_id: "path", "remove", "select", et bygnings-id (fx "carousel"),
## "decor:<id>", "staff:<type_id>" (ansæt på sti) eller "staff_move:<staff_id>".
signal build_tool_requested(def_id: String)
## Esc mens select-værktøjet er aktivt.
signal pause_menu_requested
