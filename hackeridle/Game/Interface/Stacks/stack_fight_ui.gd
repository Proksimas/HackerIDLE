extends Control

var hacker: Entity
var robot_ia: Entity
var robot_ia_2: Entity


@onready var stack_fight_panel: Panel = $StackFightPanel


signal s_fight_ui_phase_finished
signal s_execute_script_ui_finished
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	pass # Replace with function body.


### POUR LES TEST
func _on_start_fight_button_pressed() -> void:
	hacker = Entity.new(true)
	robot_ia = Entity.new(false, "robot_a", 5,0,0)
	robot_ia_2 = Entity.new(false, "robot_b",3,3,3)
	
	var arr:Array[Entity] = [robot_ia, robot_ia_2]
	StackManager.learn_stack_script(hacker, "syn_flood")
	StackManager.learn_stack_script(robot_ia, "syn_flood")
	StackManager.learn_stack_script(robot_ia_2, "syn_flood")
	hacker.save_sequence(["syn_flood", "syn_flood"])
	robot_ia.save_sequence(["syn_flood"])
	robot_ia_2.save_sequence(["syn_flood"])
	
	var fight = StackManager.new_fight(hacker, arr)
	fight_connexions(fight)
	arr.all(entity_connexions)
	entity_connexions(hacker)
	fight.start_fight(hacker, arr)
	pass # Replace with function body.
### ### ### ### ### ### ### ### ### ### ### ### 
	
func fight_connexions(fight: StackFight):
	"""on setup toutes les connexions pour le fight pour l'ui"""
	
	#connexions des signaux du fights
	fight.s_fight_started.connect(_on_fight_started)

	#connexions des signaux d'uis
	s_fight_ui_phase_finished.connect(fight._on_fight_ui_phase_finished)

func entity_connexions(entity: Entity):
		
	entity.s_execute_script.connect(_on_execute_script)
	s_execute_script_ui_finished.connect(entity._on_s_execute_script_ui_finished)

	
func _on_fight_started(hacker, robots: Array):
	"""Le fight va commencer. On setup les grilles"""
	stack_fight_panel.set_entity_container(hacker)
	for entity in robots:
		stack_fight_panel.set_entity_container(entity)
	#on attends le true du await pour lancer le signal
	s_fight_ui_phase_finished.emit("fight_start")

func _on_execute_script(data_from_execution: Dictionary):
	 # gérer sur l'ui avec la fin du cd. 
	# pour le moment on force un attente
	await  get_tree().create_timer(3).timeout
	#####
	print("L'ui a terminé de s'afficher")
	s_execute_script_ui_finished.emit()
	pass
