extends Control

var hacker: Entity
var robot_ia: Entity
var robot_ia_2: Entity


@onready var stack_fight_panel: Panel = $StackFightPanel
@onready var hacker_container: Control = %HackerContainer
@onready var robots_container: HBoxContainer = %RobotsContainer
@onready var fight_logs: Panel = %FightLogs


signal s_fight_ui_phase_finished
signal s_execute_script_ui_finished
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	pass # Replace with function body.


### POUR LES TEST
func _on_start_fight_button_pressed() -> void:
	###on init le hacker
	hacker = Entity.new(true)
	StackManager.stack_script_stats = {"penetration": 4,
							"encryption": 0,
							"flux": 0}
	StackManager.learn_stack_script(hacker, "syn_flood")
	hacker.save_sequence(["syn_flood", "syn_flood"])
	####
	### init des ennemis selon l'etat de la wave
	var wava_data = $StackFightManager.start_encounter()
	var new_entity: Entity
	var arr:Array[Entity]
	for enemy in wava_data["enemies"]:
		new_entity = Entity.new(false,
								enemy["variant"],
									enemy["hp"],
									enemy["penetration"],
									enemy["encryption"],
									enemy["flux"])
		arr.append(new_entity)
		$StackFightManager.setup_robot_scripts(new_entity,enemy["variant"],{})
	
	#robot_ia = Entity.new(false, "robot_a", 20, 5,0,0)
	#robot_ia_2 = Entity.new(false, "robot_b",20, 3,3,3)
#
	#StackManager.learn_stack_script(robot_ia, "syn_flood")
	#StackManager.learn_stack_script(robot_ia_2, "syn_flood")
	#
	#robot_ia.save_sequence(["syn_flood"])
	#robot_ia_2.save_sequence(["syn_flood"])
	
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
	stack_fight_panel.set_entity_ui_container(_hacker)
	for entity in robots:
		stack_fight_panel.set_entity_ui_container(entity)
	#on attends le true du await pour lancer le signal
	s_fight_ui_phase_finished.emit("fight_start")

func _on_execute_script(script_index: int, data_from_execution: Dictionary):
	"""On reçoit toutes les data qu'on a sur l'éxécution du script."""
	 # gérer sur l'ui avec la fin du cd. 
	# pour le moment on force un attente
	# ne pas oublier un process_frame pour s'assurer du bon clear avant
	await get_tree().process_frame
	var entity_ui_caster: EntityUI
	var entities_ui_targets: Array[EntityUI]
	var component: StackComponent
	if data_from_execution["caster"].entity_name == "hacker":
		entity_ui_caster = hacker_container.get_child(0)
		component = entity_ui_caster.stack_grid.get_child(script_index)

	else:
		for _robot_ia: EntityUI in robots_container.get_children():
			if data_from_execution["caster"].entity_name == _robot_ia.entity_name_ui:
				entity_ui_caster = _robot_ia
				component = _robot_ia.stack_grid.get_child(script_index)
				
	#Puis parse des targets
	var entities_ui = hacker_container.get_children()
	entities_ui.append_array(robots_container.get_children())
	for target in data_from_execution["targets"]:
		for target_ui in entities_ui:
			if target_ui.entity_name_ui == target.entity_name:
				entities_ui_targets.append(target_ui)
	component.s_stack_component_completed.connect(\
	_on_s_stack_component_completed.bind(component, 
										entity_ui_caster,
										entities_ui_targets,
										 data_from_execution))
				#await component.get_tree().process_frame
	component.start_component()

	pass

func _on_s_stack_component_completed(component: StackComponent,
						 caster_ui:EntityUI,
						targets_ui: Array[EntityUI],
						data_from_execution: Dictionary):
	"""Toutes las animations liées à la stack sont finies.
	On doit mettre à jour l'ui post stack des entités"""
	component.s_stack_component_completed.disconnect(_on_s_stack_component_completed)

	# TODO REMPLIR SELON LES DIFFERENTS EFFETS
	
	for target_ui in targets_ui:
		target_ui.target_receive_data_from_execute(data_from_execution)
	
	var targets_name : Array
	for target in data_from_execution["targets"]:
		targets_name.append(target.entity_name)
	var dict_log = \
	{"caster_name": data_from_execution["caster"].entity_name,
	"target_names": targets_name,
	"action_type": data_from_execution["action_type"],
	"effects": [data_from_execution["effects"]]}
	#On est pret à anticiper si il y a plusieurs effets
	#print("data post script: ", data_from_execution)
	fight_logs.add_log(dict_log)
	s_execute_script_ui_finished.emit()
	
