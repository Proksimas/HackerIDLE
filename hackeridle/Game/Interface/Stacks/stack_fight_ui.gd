extends Control

const STACK_FIGHT_MANAGER = preload("res://Game/Stacks/stack_fight_manager.tscn")

var hacker: Entity
var robot_ia: Entity
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hacker = Entity.new()
	robot_ia = Entity.new()
	pass # Replace with function body.


func _on_start_fight_button_pressed() -> void:
	var fight = STACK_FIGHT_MANAGER.instantiate()
	var arr:Array[Entity] = [robot_ia]
	StackManager.learn_stack_script(hacker, "syn_flood")
	StackManager.learn_stack_script(robot_ia, "syn_flood")
	hacker.init_sequence(["syn_flood", "syn_flood"])
	robot_ia.init_sequence(["syn_flood"])
	fight.new_fight(hacker, arr)
	pass # Replace with function body.
