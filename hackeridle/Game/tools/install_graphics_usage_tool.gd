@tool
extends EditorScript

const PLUGIN_DIR := "res://addons/graphics_usage_report"
const PLUGIN_CFG := "res://addons/graphics_usage_report/plugin.cfg"
const PLUGIN_CFG_CONTENT := """[plugin]

name="Graphics Usage Report"
description="Adds a Project > Tools action that scans graphic assets and writes unused_graphics_report.csv."
author="HackerIDLE"
version="1.0.0"
script="res://Game/tools/graphics_usage_editor_plugin.gd"
"""


func _run() -> void:
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PLUGIN_DIR))
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		push_error("Cannot create plugin directory: %s" % PLUGIN_DIR)
		return

	var file := FileAccess.open(PLUGIN_CFG, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write plugin config: %s" % PLUGIN_CFG)
		return

	file.store_string(PLUGIN_CFG_CONTENT)
	file.close()

	_enable_plugin_in_project_settings()
	EditorInterface.get_resource_filesystem().scan()

	print("Graphics Usage Report plugin installed.")
	print("Plugin config: %s" % PLUGIN_CFG)
	print("If the menu item is not visible yet, reload the project and check Project > Project Settings > Plugins.")


func _enable_plugin_in_project_settings() -> void:
	var enabled_plugins: PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray())
	if not enabled_plugins.has(PLUGIN_CFG):
		enabled_plugins.append(PLUGIN_CFG)
		ProjectSettings.set_setting("editor_plugins/enabled", enabled_plugins)
		var save_error := ProjectSettings.save()
		if save_error != OK:
			push_error("Cannot save project settings after enabling plugin.")
