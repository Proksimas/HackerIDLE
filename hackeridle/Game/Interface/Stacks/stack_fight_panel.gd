extends Panel

@onready var hacker_container: Control = %HackerContainer
@onready var robots_container: Control = %RobotsContainer
@onready var fight_logs: Panel = %FightLogs

@onready var sector_label: Label = %SectorLabel
@onready var sector_value: Label = %SectorValue
@onready var level_label: Label = %LevelLabel
@onready var level_value: Label = %LevelValue
@onready var wave_label: Label = %WaveLabel
@onready var wave_value: Label = %WaveValue

const ENTITY_UI = preload("res://Game/Interface/Stacks/entity_ui.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hacker_container.hide()
	robots_container.hide()
	_clear()
	pass # Replace with function body.


func set_entity_ui_container(entity: Entity)->bool:
	"""Initialiser l'ui de l'entité"""
	var target_container: Control = hacker_container if entity.entity_is_hacker else robots_container
	var new_entity_ui: EntityUI = _acquire_entity_ui(target_container)
	if new_entity_ui == null:
		return false
	match entity.entity_is_hacker:
		true:
			new_entity_ui.set_stack_script_values(StackManager.stack_script_stats)
		false:
			new_entity_ui.set_stack_script_values(entity.stats)
			
	new_entity_ui.initialize_stack_grid(entity, entity.sequence_order)
	
	
	hacker_container.show()
	robots_container.show()
	return true
	
func set_wave_state(wave_data):
	sector_label.text = tr("$Sector")
	sector_value.text = "%s" % wave_data["sector_index"]
	level_label.text = tr("$Level")
	level_value.text = "-%s" % wave_data["level_index"]
	wave_label.text = tr("$Wave")
	wave_value.text = "%s/%s" % [wave_data["wave_index"], wave_data["waves_per_level"]]
	pass

func _clear():
	for elmt in hacker_container.get_children():
		if elmt is EntityUI:
			elmt.reset_entity_ui()
	for elmt2 in robots_container.get_children():
		if elmt2 is EntityUI:
			elmt2.reset_entity_ui()



func refresh_stack_components_cooldowns() -> void:
	for entity_ui in hacker_container.get_children():
		if entity_ui.visible and entity_ui.has_method("refresh_stack_components_cooldowns"):
			entity_ui.refresh_stack_components_cooldowns()
	for entity_ui in robots_container.get_children():
		if entity_ui.visible and entity_ui.has_method("refresh_stack_components_cooldowns"):
			entity_ui.refresh_stack_components_cooldowns()


func _acquire_entity_ui(container: Control) -> EntityUI:
	for child in container.get_children():
		if child is EntityUI and not child.visible:
			child.show()
			return child

	var new_entity_ui: EntityUI = ENTITY_UI.instantiate() as EntityUI
	container.add_child(new_entity_ui)
	return new_entity_ui
