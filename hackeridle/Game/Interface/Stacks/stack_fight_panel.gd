extends Panel

@onready var hacker_container: Control = %HackerContainer
@onready var robots_container: Control = %RobotsContainer
@onready var fight_logs: Panel = %FightLogs

const ENTITY_UI = preload("res://Game/Interface/Stacks/entity_ui.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func set_entities_container(entities: Array[Entity]):
	_clear()
	for entity in entities:
		var new_entity_ui = ENTITY_UI.instantiate()
		new_entity_ui.set_stack_grid(entity.sequence_order)
		match entity.entity_is_hacker:
			true:
				hacker_container.add_child(new_entity_ui)
			false:
				robots_container.add_child(new_entity_ui)
	

func _clear():
	for elmt in hacker_container.get_children():
		elmt.queue_free()
	for elmt2 in robots_container.get_children():
		elmt2.queue_free()
