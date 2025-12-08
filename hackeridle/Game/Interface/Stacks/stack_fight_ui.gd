extends Control

var hacker: Entity
var robot_ia: Entity
var robot_ia_2: Entity


@onready var stack_fight_panel: Panel = $StackFightPanel


signal s_fight_ui_phase_finished
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hacker = Entity.new(true)
	robot_ia = Entity.new(false, "robot_a", 5,0,0)
	robot_ia_2 = Entity.new(false, "robot_b",3,3,3)
	pass # Replace with function body.


### POUR LES TEST
func _on_start_fight_button_pressed() -> void:
	var arr:Array[Entity] = [robot_ia, robot_ia_2]
	StackManager.learn_stack_script(hacker, "syn_flood")
	StackManager.learn_stack_script(robot_ia, "syn_flood")
	StackManager.learn_stack_script(robot_ia_2, "syn_flood")
	hacker.save_sequence(["syn_flood", "syn_flood"])
	robot_ia.save_sequence(["syn_flood"])
	robot_ia_2.save_sequence(["syn_flood"])
	var fight = StackManager.new_fight(hacker, arr)
	fight_connexions(fight)
	fight.start_fight(hacker, arr)
	pass # Replace with function body.
### ### ### ### ### ### ### ### ### ### ### ### 
	
func fight_connexions(fight: StackFight):
	"""on setup toutes les connexions pour le fight pour l'ui"""
	
	#connexions des signaux du fights
	fight.s_fight_started.connect(_on_fight_started)
	
	#connexions des signaux d'uis
	s_fight_ui_phase_finished.connect(fight._on_fight_ui_phase_finished)
	
func _on_fight_started(hacker, robots: Array):
	"""Le fight va commencer. On setup les grilles"""
	var lst_entities = robots
	lst_entities.append(hacker)
	await stack_fight_panel.set_entities_container(lst_entities)
	#on attends le true du await pour lancer le signal
	s_fight_ui_phase_finished.emit("fight_start")
