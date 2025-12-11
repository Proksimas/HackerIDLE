extends Control

var hacker: Entity
var robot_ia: Entity
var robot_ia_2: Entity


@onready var stack_fight_panel: Panel = $StackFightPanel
@onready var hacker_container: Control = %HackerContainer
@onready var robots_container: HBoxContainer = %RobotsContainer


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
	StackManager.stack_script_stats = {"penetration": 4,
							"encryption": 0,
							"flux": 0}
	
	var arr:Array[Entity] = [robot_ia, robot_ia_2]
	StackManager.learn_stack_script(hacker, "syn_flood")
	StackManager.learn_stack_script(robot_ia, "syn_flood")
	StackManager.learn_stack_script(robot_ia_2, "syn_flood")
	hacker.save_sequence(["syn_flood", "syn_flood"])
	robot_ia.save_sequence(["syn_flood"])
	robot_ia_2.save_sequence(["syn_flood"])
	
	var fight = StackManager.new_fight(hacker, arr)
	fight_connexions(fight)
	#arr.all(entity_connexions)
	#entity_connexions(hacker)
	fight.start_fight(hacker, arr, self)
	pass # Replace with function body.
### ### ### ### ### ### ### ### ### ### ### ### 
	
func fight_connexions(fight: StackFight):
	"""on setup toutes les connexions pour le fight pour l'ui"""
	#connexions des signaux du fights
	fight.s_fight_started.connect(_on_fight_started)
	#connexions des signaux d'uis
	s_fight_ui_phase_finished.connect(fight._on_fight_ui_phase_finished)

	
func _on_fight_started(_hacker: Entity, robots: Array[Entity]):
	"""Le fight va commencer. On setup l'ui des entités"""
	stack_fight_panel.set_entity_container(_hacker)
	for entity in robots:
		stack_fight_panel.set_entity_container(entity)
	#on attends le true du await pour lancer le signal
	s_fight_ui_phase_finished.emit("fight_start")

func _on_execute_script(script_index: int, data_from_execution: Dictionary):
	"""On reçoit toutes les data qu'on a sur l'éxécution du script."""
	 # gérer sur l'ui avec la fin du cd. 
	# pour le moment on force un attente
	#await get_tree().create_timer(0).timeout
	if data_from_execution["caster"] == "hacker":
		# BUG ON A PAS LE TEMPS D ACTIVIE LE COMPONENT
		var component = hacker_container.get_child(0).stack_grid.get_child(script_index)
		component.start_component()

	#On lance l'animation du component
	print(data_from_execution)
	#####
	#print("L'ui a terminé de s'afficher")
	#s_execute_script_ui_finished.emit()
	pass
