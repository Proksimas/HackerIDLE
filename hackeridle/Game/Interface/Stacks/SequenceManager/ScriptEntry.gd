extends PanelContainer

signal selected(script_name: String)
signal activated(script_name: String)

@onready var name_label: Label = %NameLabel
@onready var type_label: Label = %TypeLabel

const DRAG_THRESHOLD := 6.0
const PREVIEW_SCENE = preload("res://Game/Interface/Stacks/SequenceManager/ScriptEntry.tscn")

var _script_name: String = ""
var _script_kind: int = 0
var _source: String = "available"
var _sequence_index: int = -1
var _drag_started := false
var _drag_start := Vector2.ZERO


func setup(raw_name: String, display_name: String, kind: int, kind_label: String, source: String = "available", sequence_index: int = -1) -> void:
	_ensure_nodes()
	_script_name = raw_name
	_script_kind = kind
	_source = source
	_sequence_index = sequence_index
	if name_label != null:
		name_label.text = display_name
	if type_label != null:
		type_label.text = kind_label
	_apply_style()


func get_script_name() -> String:
	return _script_name


func set_selected(is_selected: bool) -> void:
	self_modulate = Color(1, 1, 1, 1) if is_selected else Color(0.92, 0.92, 0.92, 1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drag_start = event.position
			_drag_started = false
			selected.emit(_script_name)
			if event.double_click:
				activated.emit(_script_name)
				accept_event()
		else:
			_drag_started = false
	elif event is InputEventMouseMotion:
		if not _drag_started and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if event.position.distance_to(_drag_start) >= DRAG_THRESHOLD:
				_drag_started = true
				var preview = PREVIEW_SCENE.instantiate()
				preview.setup(_script_name, name_label.text, _script_kind, type_label.text, _source, _sequence_index)
				var idx := -1
				if _source == "sequence":
					idx = _sequence_index
				force_drag({"name": _script_name, "source": _source, "from_index": idx}, preview)


func _apply_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.09, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6

	match _script_kind:
		StackScript.ScriptKind.DAMAGE:
			style.border_color = Color(0.8, 0.25, 0.25, 1)
		StackScript.ScriptKind.SHIELD:
			style.border_color = Color(0.25, 0.45, 0.85, 1)
		StackScript.ScriptKind.UTILITY:
			style.border_color = Color(0.25, 0.75, 0.45, 1)
		_:
			style.border_color = Color(0.3, 0.3, 0.35, 1)

	add_theme_stylebox_override("panel", style)


func _ensure_nodes() -> void:
	if name_label == null:
		name_label = get_node_or_null("Margin/VBox/NameLabel")
	if type_label == null:
		type_label = get_node_or_null("Margin/VBox/TypeLabel")
