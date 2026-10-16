extends SceneTree
## Gemmer UiTheme.build() som resourcen UiTheme.THEME_PATH (T-138).
## Kør: cd game && godot --headless --script res://scripts/ui/ui_theme_export.gd


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(UiTheme.THEME_PATH.get_base_dir()))
	var err: int = ResourceSaver.save(UiTheme.build(), UiTheme.THEME_PATH)
	print("UiTheme gemt: ", UiTheme.THEME_PATH, " err=", err)
	quit(err)
