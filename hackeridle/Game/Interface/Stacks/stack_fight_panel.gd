extends Panel

@onready var hacker_container: Control = %HackerContainer
@onready var robots_container: Control = %RobotsContainer
@onready var fight_logs: Panel = %FightLogs

const ENTITY_UI = preload("res://Game/Interface/Stacks/entity_ui.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hacker_container.hide()
	robots_container.hide()
	_clear()
	pass # Replace with function body.


func set_entity_container(entity: Entity)->bool:

	var new_entity_ui = ENTITY_UI.instantiate()
	match entity.entity_is_hacker:
		true:
			hacker_container.add_child(new_entity_ui)
		false:
			robots_container.add_child(new_entity_ui)
	new_entity_ui.set_stack_grid(entity.entity_name, entity.sequence_order)
	hacker_container.show()
	robots_container.show()
	return true
	

func _clear():
	for elmt in hacker_container.get_children():
		elmt.queue_free()
	for elmt2 in robots_container.get_children():
		elmt2.queue_free()
