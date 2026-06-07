@tool
extends EditorScript

const GraphicsUsageReport := preload("res://Game/tools/graphics_usage_report.gd")


func _run() -> void:
	GraphicsUsageReport.new().generate()
