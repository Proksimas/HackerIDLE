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
	# ne pas oublier un process_frame pour s'assurer du bon clear avant
	await get_tree().process_frame
	if data_from_execution["caster"] == "hacker":
		var component: StackComponent = hacker_container.get_child(0).stack_grid.get_child(script_index)
		component.s_stack_component_completed.connect(\
		_on_s_stack_component_completed.bind(component, data_from_execution))
		#await component.get_tree().process_frame
		component.start_component()
	else:
		for _robot_ia: EntityUI in robots_container.get_children():
			if data_from_execution["caster"] == _robot_ia.entity_name_ui:
				var component: StackComponent = _robot_ia.stack_grid.get_child(script_index)
				component.s_stack_component_completed.connect(\
				_on_s_stack_component_completed.bind(component, data_from_execution))
				#await component.get_tree().process_frame
				component.start_component()

	pass

func _on_s_stack_component_completed(component, data_from_execution):
	component.s_stack_component_completed.disconnect(_on_s_stack_component_completed)
	print(data_from_execution)
	s_execute_script_ui_finished.emit()
