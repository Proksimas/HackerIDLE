extends ScrollContainer

signal script_drop(data: Dictionary)


func _can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("name"):
		return false
	return str(data.get("source", "")) == "sequence"


func _drop_data(at_position: Vector2, data) -> void:
	if typeof(data) != TYPE_DICTIONARY or not data.has("name"):
		return
	script_drop.emit(data)
