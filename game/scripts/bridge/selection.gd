class_name Selection
extends Node
## Delt valg-/værktøjsbus mellem gameplay (BuildTool) og UI. Findes i gruppen "selection".
## Ingen logik – kun signaler.

signal selected_attraction(id: int)
signal selected_guest(id: int)
signal cleared
## def_id: "path", "remove", "select" eller et bygnings-id (fx "carousel").
signal build_tool_requested(def_id: String)
