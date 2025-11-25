extends Control

const STACK_FIGHT_MANAGER = preload("res://Game/Stacks/stack_fight_manager.tscn")

var hacker: Entity
var robot_ia: Entity
var robot_ia_2: Entity
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hacker = Entity.new()
	robot_ia = Entity.new()
	robot_ia_2 = Entity.new()
	pass # Replace with function body.


func _on_start_fight_button_pressed() -> void:
	var fight = STACK_FIGHT_MANAGER.instantiate()
	var arr:Array[Entity] = [robot_ia, robot_ia_2]
	StackManager.learn_stack_script(hacker, "syn_flood")
	StackManager.learn_stack_script(robot_ia, "syn_flood")
	StackManager.learn_stack_script(robot_ia_2, "syn_flood")
	hacker.save_sequence(["syn_flood", "syn_flood"])
	hacker.entity_name = "hacker"
	robot_ia.save_sequence(["syn_flood"])
	robot_ia.entity_name = "robot a"
	robot_ia_2.save_sequence(["syn_flood"])
	robot_ia_2.entity_name = "robot b"
	fight.new_fight(hacker, arr)
	pass # Replace with function body.
