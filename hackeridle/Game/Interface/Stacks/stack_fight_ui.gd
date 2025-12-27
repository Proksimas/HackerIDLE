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
signal s_must_execute_script
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	pass # Replace with function body.


### POUR LES TEST
func _on_start_fight_button_pressed() -> void:
	###on init le hacker
	
	StackManager.stack_script_stats = {"penetration": 4,
							"encryption": 4,
							"flux": 4}
	hacker = Entity.new(true)
	StackManager.learn_stack_script(hacker, "malware_apt")
	StackManager.learn_stack_script(hacker, "data_healing")
	StackManager.learn_stack_script(hacker, "malware_apt")
	
	hacker.save_sequence(["malware_apt", "data_healing","malware_apt"])
	####
	### init des ennemis selon l'etat de la wave
	var wave_data = $StackFightManager.start_encounter()
	var new_entity: Entity
	var arr:Array[Entity]
	for enemy in wave_data["enemies"]:
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
	
	stack_fight_panel.set_wave_state(wave_data)
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
	
func _on_s_cast_script(script_index: int, data_before_execution: Dictionary):
	"""On demande de cast le lancement du prochain script, qui est le component"""
	await get_tree().process_frame
	var entity_ui_caster: EntityUI
	var component: StackComponent
	if data_before_execution["caster"].entity_name == "hacker":
		entity_ui_caster = hacker_container.get_child(0)
		component = entity_ui_caster.stack_grid.get_child(script_index)

	else:
		for _robot_ia: EntityUI in robots_container.get_children():
			if data_before_execution["caster"].entity_name == _robot_ia.entity_name_ui:
				entity_ui_caster = _robot_ia
				component = _robot_ia.stack_grid.get_child(script_index)
	component.s_stack_component_completed.connect(\
	_on_s_stack_component_completed.bind(component, data_before_execution))
				#await component.get_tree().process_frame
	component.start_component()
func _on_execute_script(_script_index: int, data_from_execution: Dictionary) -> void:
	"""On reçoit toutes les data qu'on a sur APRES l'éxécution du script."""
	await get_tree().process_frame

	# --- Construire la liste des EntityUI disponibles ---
	var entities_ui: Array[EntityUI] = []
	entities_ui.append_array(hacker_container.get_children())
	entities_ui.append_array(robots_container.get_children())

	# --- Déduire les cibles depuis targetEffects (canon) ---
	var targets_entities: Array[Entity] = []

	if data_from_execution.has("targetEffects"):
		for te in data_from_execution.get("targetEffects", []):
			if te is Dictionary:
				var t: Entity = te.get("target", null)
				if t != null and not targets_entities.has(t):
					targets_entities.append(t)

	# --- Fallback si jamais pas de targetEffects : résolution ---
	if targets_entities.is_empty() and data_from_execution.has("resolution"):
		var per_target: Array = data_from_execution["resolution"].get("perTarget", [])
		for entry in per_target:
			if entry is Dictionary:
				var t: Entity = entry.get("target", null)
				if t != null and not targets_entities.has(t):
					targets_entities.append(t)

	# --- Appliquer aux UI correspondantes ---
	for target_entity: Entity in targets_entities:
		for entity_ui: EntityUI in entities_ui:
			if target_entity.entity_name == entity_ui.entity_name_ui:
				entity_ui.target_receive_data_from_execute(data_from_execution)
				break

	# Logs (déjà compatibles targetEffects dans ton nouveau logger)
	fight_logs.add_log(data_from_execution)

	s_execute_script_ui_finished.emit()


	pass

func _on_s_stack_component_completed(component: StackComponent,
						data_before_execution: Dictionary):
	"""Toutes las animations liées à la stack sont finies.
	On peut donc lancer le script !"""
	#await get_tree().process_frame
	component.s_stack_component_completed.disconnect(_on_s_stack_component_completed)
	data_before_execution["caster"].execute_next_script()
	print(data_before_execution)
	print("le stack component est terminé")
	s_must_execute_script.emit()
