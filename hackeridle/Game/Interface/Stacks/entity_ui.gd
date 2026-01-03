extends Control
class_name EntityUI

@onready var stack_name_label: Label = %StackNameLabel
@onready var entity_name_label: Label = %EntityNameLabel
@onready var stack_grid: GridContainer = %StackGrid
@onready var hp_progress_bar: ProgressBar = %HpProgressBar
@onready var shield_progress_bar: ProgressBar = %ShieldProgressBar

@onready var penetration_label: Label = %PenetrationLabel
@onready var penetration_value: Label = %PenetrationValue
@onready var encryption_label: Label = %EncryptionLabel
@onready var encryption_value: Label = %EncryptionValue
@onready var flux_label: Label = %FluxLabel
@onready var flux_value: Label = %FluxValue

var entity_name_ui: String = "default_ui_name"
var entity_associated: Entity

const STACK_COMPONENT = preload("res://Game/Interface/Stacks/stack_component.tscn")

@export var tween_duration_hp: float = 0.35
@export var tween_duration_shield: float = 0.25

# Feedback damage HP
@export var hp_flash_duration: float = 0.10
@export var hp_flash_return_duration: float = 0.18
@export var hp_punch_scale: float = 1.04
@export var hp_punch_in_duration: float = 0.08
@export var hp_punch_out_duration: float = 0.12

var _hp_tween: Tween
var _shield_tween: Tween
var _hp_feedback_tween: Tween

var _hp_base_modulate: Color = Color(1, 1, 1, 1)
var _hp_base_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	_clear()


func _draw() -> void:
	stack_name_label.text = "$Stack"
	penetration_label.text = "$Penetration"
	encryption_label.text = "$Encryption"
	flux_label.text = "$Flux"


func initialize_stack_grid(entity: Entity, sequence: Array[String]) -> void:
	"""Initialisation de l'entité UI"""
	_clear()
	entity_associated = entity
	entity_name_ui = entity.entity_name
	entity_name_label.text = entity.entity_name

	# Init bars based on actual entity state (no assumptions)
	hp_progress_bar.min_value = 0
	hp_progress_bar.max_value = entity.max_hp
	hp_progress_bar.value = clamp(float(entity.current_hp), 0, float(hp_progress_bar.max_value))

	shield_progress_bar.min_value = 0
	shield_progress_bar.max_value = entity.max_hp
	shield_progress_bar.value = clamp(float(entity.current_shield), 0, float(shield_progress_bar.max_value))

	# Save base visuals for feedback
	_hp_base_modulate = hp_progress_bar.modulate
	_hp_base_scale = hp_progress_bar.scale

	# Ensure shield visibility matches initial state
	_on_shield_progress_bar_value_changed(shield_progress_bar.value)

	for component_name in sequence:
		var new_component = STACK_COMPONENT.instantiate()
		stack_grid.add_child(new_component)
		new_component.set_component(component_name)


func set_stack_script_values(dict: Dictionary) -> void:
	for key in dict:
		match key:
			"penetration":
				penetration_value.text = str(dict["penetration"])
			"encryption":
				encryption_value.text = str(dict["encryption"])
			"flux":
				flux_value.text = str(dict["flux"])


func target_receive_data_from_execute(data_effect: Dictionary) -> void:
	"""L'entité est la cible du script d'execution.
	Reçoit les données concernant cette entité post script execution (hp, shield, etc.)
	On privilégie la 'resolution' (vérité du combat) pour éviter les désync.
	"""
	var entry := _find_resolution_entry_for_self(data_effect)

	# ✅ Source de vérité : résolution (after)
	if not entry.is_empty():
		var after: Dictionary = entry.get("after", {})
		var new_hp: float = float(after.get("hp", hp_progress_bar.value))
		var new_shield: float = float(after.get("shield", shield_progress_bar.value))

		# Clamp to bars range (shield capped to max_hp)
		new_hp = clamp(new_hp, 0.0, float(hp_progress_bar.max_value))
		new_shield = clamp(new_shield, 0.0, float(shield_progress_bar.max_value))

		# 🔥 Feedback uniquement si HP baisse (ici, pas dans _animate_progress)
		if new_hp < float(hp_progress_bar.value):
			_play_hp_damage_feedback()

		_animate_progress(hp_progress_bar, new_hp, tween_duration_hp, true)
		_animate_progress(shield_progress_bar, new_shield, tween_duration_shield, false)
		return

	# Fallback (si jamais pas de resolution)
	var action_type: String = str(data_effect.get("action_type", ""))

	if action_type == "Damage":
		for _effect in data_effect.get("effects", []):
			var value := float(_effect.get("value", 0))
			match str(_effect.get("type", "")):
				"HP":
					var new_hp = clamp(float(hp_progress_bar.value) - value, 0.0, float(hp_progress_bar.max_value))
					if new_hp < float(hp_progress_bar.value):
						_play_hp_damage_feedback()
					_animate_progress(hp_progress_bar, new_hp, tween_duration_hp, true)

	elif action_type == "Shield":
		for _effect in data_effect.get("effects", []):
			var value := float(_effect.get("value", 0))
			match str(_effect.get("type", "")):
				"Shield":
					var new_shield = clamp(float(shield_progress_bar.value) + value, 0.0, float(shield_progress_bar.max_value))
					_animate_progress(shield_progress_bar, new_shield, tween_duration_shield, false)


func _find_resolution_entry_for_self(data_effect: Dictionary) -> Dictionary:
	if not data_effect.has("resolution"):
		return {}
	var per_target: Array = data_effect["resolution"].get("perTarget", [])
	for entry in per_target:
		if entry.has("target") and entry["target"] == entity_associated:
			return entry
	return {}


func _animate_progress(bar: ProgressBar, to_value: float, duration: float, is_hp: bool) -> void:
	# Kill previous tween on that bar to avoid stacking
	if is_hp:
		if _hp_tween and _hp_tween.is_valid():
			_hp_tween.kill()
	else:
		if _shield_tween and _shield_tween.is_valid():
			_shield_tween.kill()

	var from_value: float = float(bar.value)
	if is_equal_approx(from_value, to_value):
		# Still ensure shield visibility reacts if needed
		if bar == shield_progress_bar:
			_on_shield_progress_bar_value_changed(to_value)
		return

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_OUT)

	# Animate the ProgressBar.value
	t.tween_property(bar, "value", to_value, max(0.01, duration))

	# Keep a reference
	if is_hp:
		_hp_tween = t
	else:
		_shield_tween = t
		# Ensure show/hide happens at the end (cleaner visually)
		t.finished.connect(func():
			_on_shield_progress_bar_value_changed(bar.value)
		)


func _play_hp_damage_feedback() -> void:
	# Kill previous feedback tween to avoid stacking
	if _hp_feedback_tween and _hp_feedback_tween.is_valid():
		_hp_feedback_tween.kill()

	# Reset to base first (in case the previous tween was interrupted)
	hp_progress_bar.modulate = _hp_base_modulate
	hp_progress_bar.scale = _hp_base_scale

	_hp_feedback_tween = create_tween()
	_hp_feedback_tween.set_trans(Tween.TRANS_SINE)
	_hp_feedback_tween.set_ease(Tween.EASE_OUT)

	# Flash to white then return
	_hp_feedback_tween.tween_property(
		hp_progress_bar,
		"modulate",
		Color(1, 1, 1, 1),
		max(0.01, hp_flash_duration)
	)
	_hp_feedback_tween.tween_property(
		hp_progress_bar,
		"modulate",
		_hp_base_modulate,
		max(0.01, hp_flash_return_duration)
	)

	# Mini punch scale (parallel)
	var punch := create_tween()
	punch.set_trans(Tween.TRANS_SINE)
	punch.set_ease(Tween.EASE_OUT)
	punch.tween_property(
		hp_progress_bar,
		"scale",
		_hp_base_scale * hp_punch_scale,
		max(0.01, hp_punch_in_duration)
	)
	punch.tween_property(
		hp_progress_bar,
		"scale",
		_hp_base_scale,
		max(0.01, hp_punch_out_duration)
	)


func _clear() -> void:
	for elmt in stack_grid.get_children():
		elmt.queue_free()


func _on_shield_progress_bar_value_changed(value: float) -> void:
	if value > 0.0:
		shield_progress_bar.show()
	else:
		shield_progress_bar.hide()
