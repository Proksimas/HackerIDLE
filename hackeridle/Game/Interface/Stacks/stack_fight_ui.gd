extends Control

var hacker: Entity
var robot_ia: Entity
var robot_ia_2: Entity
var current_fight: StackFight
var run_active: bool = false
var _last_wave_enemy_count: int = 0

@onready var stack_fight_panel: Panel = $StackFightPanel
@onready var hacker_container: Control = %HackerContainer
@onready var robots_container: HBoxContainer = %RobotsContainer
@onready var fight_logs: Panel = %FightLogs
@onready var stack_fight_manager: StackFightManager = %StackFightManager

signal s_fight_ui_phase_finished
signal s_execute_script_ui_finished
signal s_must_execute_script

func _ready() -> void:
	if StackManager.has_signal("s_hacker_loadout_changed") and not StackManager.s_hacker_loadout_changed.is_connected(_on_hacker_loadout_changed):
		StackManager.s_hacker_loadout_changed.connect(_on_hacker_loadout_changed)

func on_opened() -> void:
	"""Precharge l'UI de combat a l'ouverture, sans demarrer le run."""
	if run_active:
		return

	hacker = StackManager.create_hacker_entity()

	if stack_fight_panel.has_method("_clear"):
		stack_fight_panel.call("_clear")
	if fight_logs.has_method("_clear"):
		fight_logs.call("_clear")

	stack_fight_panel.set_entity_ui_container(hacker)
	stack_fight_panel.set_wave_state(_build_wave_preview_data())

func _on_start_fight_button_pressed() -> void:
	if run_active:
		return
	_start_roguelike_run(false)

func _start_roguelike_run(reset_progression: bool = false) -> void:
	run_active = true
	if reset_progression:
		stack_fight_manager.reset_run()
	hacker = StackManager.create_hacker_entity()
	_start_next_encounter()

func _start_next_encounter() -> void:
	if not run_active:
		return
	if hacker == null or hacker.current_hp <= 0:
		_end_run(false)
		return

	var wave_data := stack_fight_manager.start_encounter()
	_last_wave_enemy_count = _count_wave_enemies(wave_data)
	var robots := _build_robots_from_wave(wave_data)

	if stack_fight_panel.has_method("_clear"):
		stack_fight_panel.call("_clear")
	if fight_logs.has_method("_clear"):
		fight_logs.call("_clear")

	stack_fight_panel.set_wave_state(wave_data)
	current_fight = StackManager.new_fight(hacker, robots)
	fight_connexions(current_fight)
	current_fight.s_combat_ended.connect(_on_combat_ended)
	current_fight.start_fight(hacker, robots, self)

func _build_robots_from_wave(wave_data: Dictionary) -> Array[Entity]:
	var enemies_data: Array = []
	if wave_data.has("enemies"):
		enemies_data = wave_data["enemies"]
	elif wave_data.has("boss"):
		enemies_data = [wave_data["boss"]]

	var robots: Array[Entity] = []
	for enemy in enemies_data:
		if not (enemy is Dictionary):
			continue
		var enemy_dict: Dictionary = enemy
		var new_entity := Entity.new(
			false,
			str(enemy_dict.get("variant", "robot")),
			int(enemy_dict.get("hp", 20)),
			int(enemy_dict.get("penetration", 0)),
			int(enemy_dict.get("encryption", 0)),
			int(enemy_dict.get("flux", 0))
		)
		robots.append(new_entity)
		stack_fight_manager.setup_robot_scripts(new_entity, str(enemy_dict.get("variant", "robot")), {})

	return robots

func _count_wave_enemies(wave_data: Dictionary) -> int:
	if wave_data.has("enemies"):
		return int((wave_data.get("enemies", []) as Array).size())
	if wave_data.has("boss"):
		return 1
	return 0

func _build_wave_preview_data() -> Dictionary:
	return {
		"sector_index": stack_fight_manager.sector_index,
		"level_index": stack_fight_manager.level_index,
		"wave_index": stack_fight_manager.wave_index,
		"waves_per_level": stack_fight_manager.waves_per_level()
	}

func _on_combat_ended(victory: bool) -> void:
	if victory and _last_wave_enemy_count > 0:
		Player.earn_cyber_implants(_last_wave_enemy_count)
	stack_fight_manager.resolve_encounter(victory)
	current_fight = null

	if victory and hacker != null and hacker.current_hp > 0:
		call_deferred("_start_next_encounter")
		return

	_end_run(victory)

func _end_run(_victory: bool) -> void:
	run_active = false
	current_fight = null
	if hacker != null and hacker.current_hp <= 0:
		print("Run termine: hacker mort")

func _on_hacker_loadout_changed() -> void:
	"""Reflete instantanement les changements de sequence si aucun combat n'est en cours."""
	if run_active:
		return
	on_opened()

func fight_connexions(fight: StackFight):
	"""on setup toutes les connexions pour le fight pour l'ui"""
	fight.s_fight_started.connect(_on_fight_started)
	s_fight_ui_phase_finished.connect(fight._on_fight_ui_phase_finished)

func _on_fight_started(_hacker: Entity, robots: Array[Entity]):
	"""Le fight va commencer. On setup l'ui des entites"""
	stack_fight_panel.set_entity_ui_container(_hacker)
	for entity in robots:
		stack_fight_panel.set_entity_ui_container(entity)
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
	component.s_stack_component_completed.connect(_on_s_stack_component_completed.bind(component, data_before_execution))
	component.start_component()

func _on_execute_script(_script_index: int, data_from_execution: Dictionary) -> void:
	"""On recoit toutes les data qu'on a sur APRES l'execution du script."""
	await get_tree().process_frame

	var entities_ui: Array[EntityUI] = []
	entities_ui.append_array(hacker_container.get_children())
	entities_ui.append_array(robots_container.get_children())

	var targets_entities: Array[Entity] = []
	if data_from_execution.has("targetEffects"):
		for te in data_from_execution.get("targetEffects", []):
			if te is Dictionary:
				var t: Entity = te.get("target", null)
				if t != null and not targets_entities.has(t):
					targets_entities.append(t)

	if targets_entities.is_empty() and data_from_execution.has("resolution"):
		var per_target: Array = data_from_execution["resolution"].get("perTarget", [])
		for entry in per_target:
			if entry is Dictionary:
				var t: Entity = entry.get("target", null)
				if t != null and not targets_entities.has(t):
					targets_entities.append(t)

	for target_entity: Entity in targets_entities:
		for entity_ui: EntityUI in entities_ui:
			if target_entity.entity_name == entity_ui.entity_name_ui:
				entity_ui.target_receive_data_from_execute(data_from_execution)
				break

	fight_logs.add_log(data_from_execution)
	s_execute_script_ui_finished.emit()

func _on_s_stack_component_completed(component: StackComponent, data_before_execution: Dictionary):
	"""Toutes les animations liees a la stack sont finies. On peut lancer le script."""
	component.s_stack_component_completed.disconnect(_on_s_stack_component_completed)
	data_before_execution["caster"].execute_next_script()
	s_must_execute_script.emit()
