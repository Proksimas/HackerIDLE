@tool
extends EditorPlugin

const MENU_ITEM := "Generate Graphics Usage Report"
const GraphicsUsageReport := preload("res://Game/tools/graphics_usage_report.gd")


func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM, _generate_report)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM)


func _generate_report() -> void:
	var summary: Dictionary = GraphicsUsageReport.new().generate()
	EditorInterface.get_resource_filesystem().scan()
	print("Generated graphics usage report from Project > Tools.")
	print("Report: %s" % summary["report_path"])
