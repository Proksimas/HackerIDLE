extends PanelContainer

signal slot_drop(slot_index: int, data: Dictionary)


func _can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("name"):
		return false
	var source := str(data.get("source", ""))
	if source == "available":
		return true
	if source == "sequence":
		return true
	return false


func _drop_data(at_position: Vector2, data) -> void:
	if typeof(data) != TYPE_DICTIONARY or not data.has("name"):
		return
	slot_drop.emit(get_index(), data)
