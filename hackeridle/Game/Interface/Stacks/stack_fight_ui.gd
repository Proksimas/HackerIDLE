extends Control

var hacker: Entity
var robot_ia: Entity
var robot_ia_2: Entity
var current_fight: StackFight
var run_active: bool = false
var _last_wave_enemy_count: int = 0
var _last_encounter_type: String = ""
var _last_encounter_is_boss: bool = false
var _pending_victory_resolution: bool = false
var _between_fights_countdown_seconds: int = 5

const BETWEEN_FIGHTS_FADE_OUT_DURATION: float = 0.3
const BETWEEN_FIGHTS_FADE_IN_DURATION: float = 0.25

const STACK_SCRIPT_REWARD_SELECTOR = preload("res://Game/Interface/Stacks/StackScriptRewardUI/StackScriptRewardSelector.tscn")

@onready var stack_fight_panel: Panel = $StackFightPanel
@onready var hacker_container: Control = %HackerContainer
@onready var robots_container: HBoxContainer = %RobotsContainer
@onready var fight_logs: Panel = %FightLogs
@onready var stack_fight_manager: StackFightManager = %StackFightManager
@onready var next_fight_countdown_label: Label = %NextFightCountdownLabel

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
	_last_encounter_type = ""
	_last_encounter_is_boss = false

	hacker = StackManager.create_hacker_entity()

	if stack_fight_panel.has_method("_clear"):
		stack_fight_panel.call("_clear")
	if fight_logs.has_method("_clear"):
		fight_logs.call("_clear")
	_hide_between_fights_countdown()

	stack_fight_panel.set_entity_ui_container(hacker)
	stack_fight_panel.set_wave_state(_build_wave_preview_data())

func _on_start_fight_button_pressed() -> void:
	if run_active:
		return
	_start_roguelike_run(false)

func _start_roguelike_run(reset_progression: bool = false) -> void:
	run_active = true
	_last_encounter_type = ""
	_last_encounter_is_boss = false
	if reset_progression:
		stack_fight_manager.reset_run()
	hacker = StackManager.create_hacker_entity()
	_start_next_encounter()

func _start_next_encounter() -> void:
	if not run_active:
		print("StackFightUI | _start_next_encounter annulé: run inactive")
		return
	if hacker == null or hacker.current_hp <= 0:
		print("StackFightUI | _start_next_encounter annulé: hacker absent ou mort")
		_end_run(false)
		return

	var wave_data := stack_fight_manager.start_encounter()
	_last_wave_enemy_count = _count_wave_enemies(wave_data)
	_last_encounter_type = str(wave_data.get("type", ""))
	_last_encounter_is_boss = wave_data.has("boss") or _last_encounter_type == "BOSS"
	print("StackFightUI | start encounter | type=%s | is_boss=%s | sector=%s | level=%s | wave=%s" % [
		_last_encounter_type,
		str(_last_encounter_is_boss),
		str(wave_data.get("sector_index", "?")),
		str(wave_data.get("level_index", "?")),
		str(wave_data.get("wave_index", "?"))
	])
	var robots := _build_robots_from_wave(wave_data)

	if stack_fight_panel.has_method("_clear"):
		stack_fight_panel.call("_clear")
	if fight_logs.has_method("_clear"):
		fight_logs.call("_clear")
	_hide_between_fights_countdown()

	stack_fight_panel.set_wave_state(wave_data)
	current_fight = StackManager.new_fight(hacker, robots)
	fight_connexions(current_fight)
	current_fight.s_combat_ended.connect(_on_combat_ended)
	current_fight.start_fight(hacker, robots, self)
	await _fade_in_combat_entities()

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
	print("StackFightUI | combat fini | victory=%s | encounter_type=%s | is_boss=%s | enemy_count=%s" % [
		str(victory),
		_last_encounter_type,
		str(_last_encounter_is_boss),
		str(_last_wave_enemy_count)
	])
	if victory and _last_wave_enemy_count > 0:
		Player.earn_cyber_implants(_last_wave_enemy_count)
	current_fight = null
	if fight_logs != null and fight_logs.has_method("add_log"):
		await fight_logs.add_log({
			"action_type": "Resolution",
			"victory": victory,
			"encounter_type": _last_encounter_type
		})
	await get_tree().create_timer(0.6).timeout
	print("Combat terminé | victory=%s | encounter_type=%s | is_boss=%s" % [
		str(victory),
		_last_encounter_type,
		str(_last_encounter_is_boss)
	])

	if victory and _is_current_encounter_boss():
		print("StackFightUI | boss détecté en fin de combat")
		if _show_boss_rewards_if_needed():
			print("StackFightUI | reward boss affichée")
			_pending_victory_resolution = true
			return

	print("StackFightUI | pas de reward boss, finalisation et enchaînement")
	await _finalize_encounter(victory)


func _finalize_encounter(victory: bool) -> void:
	print("StackFightUI | finalize encounter | victory=%s | previous_type=%s | previous_is_boss=%s" % [
		str(victory),
		_last_encounter_type,
		str(_last_encounter_is_boss)
	])

	if victory and hacker != null and hacker.current_hp > 0:
		await _fade_out_combat_entities()

	_pending_victory_resolution = false
	stack_fight_manager.resolve_encounter(victory)
	_last_encounter_type = ""
	_last_encounter_is_boss = false

	if victory and hacker != null and hacker.current_hp > 0:
		print("StackFightUI | enchainement sur le combat suivant")
		call_deferred("_start_next_encounter_with_countdown")
		return

	print("StackFightUI | fin de run après combat")
	_end_run(victory)


func _is_current_encounter_boss() -> bool:
	return _last_encounter_is_boss


func _show_boss_rewards_if_needed() -> bool:
	var rewards := _build_boss_rewards()
	if rewards.is_empty():
		print("StackFightUI | aucun reward boss disponible")
		return false

	var selector: StackScriptRewardSelector = STACK_SCRIPT_REWARD_SELECTOR.instantiate() as StackScriptRewardSelector
	if selector == null:
		print("StackFightUI | échec instanciation reward selector")
		return false

	add_child(selector)
	selector.reward_selected.connect(_on_boss_reward_selected)
	selector.show_rewards(rewards, "Récompense de boss")
	return true


func _build_boss_rewards() -> Array[Dictionary]:
	if typeof(StackManager.stack_script_pool) != TYPE_DICTIONARY or StackManager.stack_script_pool.is_empty():
		StackManager.initialize_pool()

	var candidates: Array[String] = []
	for script_name_variant in StackManager.stack_script_pool.keys():
		var script_name := str(script_name_variant)
		if StackManager.stack_hacker_script_learned.has(script_name):
			continue
		candidates.append(script_name)

	candidates.shuffle()

	var rewards: Array[Dictionary] = []
	var reward_count: int = min(3, candidates.size())
	for i in range(reward_count):
		var script_name := candidates[i]
		var script_path := str(StackManager.stack_script_pool.get(script_name, ""))
		if script_path == "":
			continue
		var script_resource = load(script_path)
		if not (script_resource is StackScript):
			continue

		var title := script_name
		if str(script_resource.stack_script_name).strip_edges() != "" and script_resource.stack_script_name != "Script Inconnu":
			title = script_resource.stack_script_name

		rewards.append({
			"id": "%s_reward" % script_name,
			"kind": "script",
			"title": title,
			"description": tr("%s_desc" % script_name),
			"script_resource": script_resource,
			"custom_payload": {
				"script_name": script_name
			}
		})

	return rewards


func _on_boss_reward_selected(selected_data: Dictionary) -> void:
	var payload: Dictionary = selected_data.get("payload", {})
	var script_name := str(payload.get("script_name", ""))
	print("StackFightUI | reward boss sélectionnée | script=%s" % script_name)
	if script_name != "":
		StackManager.unlock_hacker_script(script_name)
		if hacker != null:
			StackManager.learn_stack_script(hacker, script_name)

	if _pending_victory_resolution:
		await _finalize_encounter(true)

func _end_run(_victory: bool) -> void:
	run_active = false
	current_fight = null
	_last_encounter_type = ""
	_last_encounter_is_boss = false
	_hide_between_fights_countdown()
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
	var entity_ui_caster: EntityUI = null
	var component: StackComponent = null
	if data_before_execution["caster"].entity_name == "hacker":
		if hacker_container.get_child_count() > 0:
			entity_ui_caster = hacker_container.get_child(0) as EntityUI
	else:
		for _robot_ia: EntityUI in robots_container.get_children():
			if data_before_execution["caster"].entity_name == _robot_ia.entity_name_ui:
				entity_ui_caster = _robot_ia
				break

	if entity_ui_caster == null:
		data_before_execution["caster"].execute_next_script()
		s_must_execute_script.emit()
		return

	if script_index >= 0 and script_index < entity_ui_caster.stack_grid.get_child_count():
		component = entity_ui_caster.stack_grid.get_child(script_index) as StackComponent

	if component == null:
		data_before_execution["caster"].execute_next_script()
		s_must_execute_script.emit()
		return

	var completion_callable := Callable(self, "_on_s_stack_component_completed").bind(component, data_before_execution)
	if component.s_stack_component_completed.is_connected(completion_callable):
		component.s_stack_component_completed.disconnect(completion_callable)
	component.s_stack_component_completed.connect(completion_callable, CONNECT_ONE_SHOT)
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

	refresh_stack_components_cooldowns()
	fight_logs.add_log(data_from_execution)
	s_execute_script_ui_finished.emit()

func _on_s_stack_component_completed(component: StackComponent, data_before_execution: Dictionary):
	"""Toutes les animations liees a la stack sont finies. On peut lancer le script."""
	data_before_execution["caster"].execute_next_script()
	s_must_execute_script.emit()


func refresh_stack_components_cooldowns() -> void:
	if stack_fight_panel.has_method("refresh_stack_components_cooldowns"):
		stack_fight_panel.refresh_stack_components_cooldowns()


func _start_next_encounter_with_countdown() -> void:
	if not run_active:
		return
	if hacker == null or hacker.current_hp <= 0:
		_end_run(false)
		return
	for seconds_left in range(_between_fights_countdown_seconds, 0, -1):
		_show_between_fights_countdown(seconds_left)
		await get_tree().create_timer(1.0).timeout
		if not run_active:
			return
		if hacker == null or hacker.current_hp <= 0:
			_end_run(false)
			return
	_hide_between_fights_countdown()
	_start_next_encounter()


func _show_between_fights_countdown(seconds_left: int) -> void:
	hacker_container.hide()
	robots_container.hide()
	if next_fight_countdown_label == null:
		return
	next_fight_countdown_label.text = "Prochain combat dans %d" % max(0, seconds_left)
	next_fight_countdown_label.show()


func _hide_between_fights_countdown() -> void:
	if next_fight_countdown_label != null:
		next_fight_countdown_label.hide()


func _fade_out_combat_entities() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	if hacker_container != null:
		hacker_container.show()
		tween.tween_property(hacker_container, "modulate:a", 0.0, BETWEEN_FIGHTS_FADE_OUT_DURATION)
	if robots_container != null:
		robots_container.show()
		tween.tween_property(robots_container, "modulate:a", 0.0, BETWEEN_FIGHTS_FADE_OUT_DURATION)

	await tween.finished


func _fade_in_combat_entities() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	if hacker_container != null:
		var hacker_modulate := hacker_container.modulate
		hacker_modulate.a = 0.0
		hacker_container.modulate = hacker_modulate
		hacker_container.show()
		tween.tween_property(hacker_container, "modulate:a", 1.0, BETWEEN_FIGHTS_FADE_IN_DURATION)
	if robots_container != null:
		var robots_modulate := robots_container.modulate
		robots_modulate.a = 0.0
		robots_container.modulate = robots_modulate
		robots_container.show()
		tween.tween_property(robots_container, "modulate:a", 1.0, BETWEEN_FIGHTS_FADE_IN_DURATION)

	await tween.finished
