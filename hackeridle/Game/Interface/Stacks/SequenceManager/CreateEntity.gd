extends Control

signal entity_created(entity: Entity)

@onready var header: HBoxContainer = %Header
@onready var close_button: Button = %CloseButton
@onready var name_edit: LineEdit = %NameEdit
@onready var hacker_check: CheckBox = %HackerCheck
@onready var hp_spin: SpinBox = %HpSpin
@onready var pen_spin: SpinBox = %PenSpin
@onready var enc_spin: SpinBox = %EncSpin
@onready var flux_spin: SpinBox = %FluxSpin
@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	_update_status()

func _on_create_button_pressed() -> void:
	var name := name_edit.text.strip_edges()
	if name == "":
		name = "entity"
	var is_hacker := hacker_check.button_pressed
	var hp := int(hp_spin.value)
	var pen := int(pen_spin.value)
	var enc := int(enc_spin.value)
	var flux := int(flux_spin.value)

	var ent := Entity.new(is_hacker, name, hp, pen, enc, flux)

	entity_created.emit(ent)
	_update_status("Entite creee: %s" % name)

func _on_reset_button_pressed() -> void:
	name_edit.text = ""
	hacker_check.button_pressed = false
	hp_spin.value = 20
	pen_spin.value = 0
	enc_spin.value = 0
	flux_spin.value = 0
	_update_status("Champs reinitialises.")

func _update_status(extra: String = "") -> void:
	var base := "Pret a creer une entite."
	if extra != "":
		base += " " + extra
	status_label.text = base

# --- Drag & close -----------------------------------------------------------
var _dragging := false
var _drag_offset := Vector2.ZERO

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = event.position
			accept_event()
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		global_position += event.relative
		accept_event()

func _on_close_button_pressed() -> void:
	queue_free()
