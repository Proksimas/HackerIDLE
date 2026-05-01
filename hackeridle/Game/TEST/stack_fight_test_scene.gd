extends Control

@export_group("Auto")
@export var auto_start_on_ready: bool = false
@export var auto_chain_on_victory: bool = false
@export var chain_delay_seconds: float = 0.4

@export_group("Manager Progression")
@export var reset_manager_before_launch: bool = true
@export var force_manager_position: bool = true
@export var manager_sector_index: int = 0
@export var manager_level_index: int = 1
@export var manager_wave_index: int = 1

@export_group("Hacker Stats Override")
@export var use_hacker_stats_override: bool = true
@export var hacker_penetration: int = 0
@export var hacker_encryption: int = 0
@export var hacker_flux: int = 0
@export var hacker_hp_bonus: int = 0

@export_group("Hacker Scripts Override")
@export var use_hacker_scripts_override: bool = true
@export var hacker_sequence_scripts: Array[String] = ["syn_flood"]

@onready var stack_fight_ui = %StackFightUi
@onready var start_button: Button = %LaunchCustomFightButton
@onready var result_label: Label = %ResultLabel
@onready var fight_type_label: Label = %FightTypeLabel

var current_fight: StackFight
var test_hacker: Entity


func _ready() -> void:
	if stack_fight_ui != null and stack_fight_ui.has_signal("s_encounter_started") and not stack_fight_ui.s_encounter_started.is_connected(_on_ui_encounter_started):
		stack_fight_ui.s_encounter_started.connect(_on_ui_encounter_started)
	_hide_embedded_start_button()
	_reset_embedded_ui(true)
	if auto_start_on_ready:
		call_deferred("_on_start_fight_button_pressed")


func _on_start_fight_button_pressed() -> void:
	if current_fight != null and is_instance_valid(current_fight):
		print("StackFightTestScene | Un combat est deja en cours.")
		return

	_prepare_manager_for_new_test()
	_apply_hacker_stats_override()
	_apply_hacker_scripts_override()
	test_hacker = StackManager.create_hacker_entity()
	await _launch_next_encounter(test_hacker, true)


func _prepare_manager_for_new_test() -> void:
	var manager: StackFightManager = stack_fight_ui.stack_fight_manager
	if manager == null:
		return

	if reset_manager_before_launch:
		manager.reset_run()

	if force_manager_position:
		manager.sector_index = max(0, manager_sector_index)
		manager.level_index = max(1, manager_level_index)
		manager.wave_index = max(1, manager_wave_index)


func _apply_hacker_stats_override() -> void:
	if not use_hacker_stats_override:
		return
	StackManager.set_hacker_stats({
		"penetration": max(0, hacker_penetration),
		"encryption": max(0, hacker_encryption),
		"flux": max(0, hacker_flux),
		"hp_bonus": max(0, hacker_hp_bonus)
	}, false)


func _apply_hacker_scripts_override() -> void:
	if not use_hacker_scripts_override:
		return

	if StackManager.stack_script_pool.is_empty():
		StackManager.initialize_pool()

	var valid_known: Array[String] = []
	var source_sequence: Array[String] = hacker_sequence_scripts if not hacker_sequence_scripts.is_empty() else valid_known
	var valid_sequence: Array[String] = []
	for script_name in source_sequence:
		var s := str(script_name)
		if StackManager.stack_script_pool.has(s):
			if not valid_known.has(s):
				valid_known.append(s)
			valid_sequence.append(s)
		else:
			push_warning("StackFightTestScene | script inconnu ignore (sequence): %s" % s)

	if valid_known.is_empty() and StackManager.stack_script_pool.has("syn_flood"):
		valid_known.append("syn_flood")
	if valid_sequence.is_empty() and valid_known.has("syn_flood"):
		valid_sequence.append("syn_flood")

	StackManager.save_hacker_loadout(valid_known, valid_sequence)


func _launch_next_encounter(hacker: Entity, clear_logs: bool) -> void:
	if hacker == null:
		return

	var manager: StackFightManager = stack_fight_ui.stack_fight_manager
	if manager == null:
		result_label.text = "Erreur: StackFightManager introuvable."
		return

	if clear_logs and stack_fight_ui.fight_logs != null and stack_fight_ui.fight_logs.has_method("_clear"):
		stack_fight_ui.fight_logs.call("_clear")
	if stack_fight_ui.stack_fight_panel != null and stack_fight_ui.stack_fight_panel.has_method("_clear"):
		stack_fight_ui.stack_fight_panel.call("_clear")
	if stack_fight_ui.has_method("_hide_between_fights_countdown"):
		stack_fight_ui.call("_hide_between_fights_countdown")

	_clamp_manager_position(manager)
	var wave_data: Dictionary = manager.start_encounter()
	_update_fight_type_label(wave_data)
	var robots: Array[Entity] = stack_fight_ui._build_robots_from_wave(wave_data)
	if robots.is_empty():
		result_label.text = "Impossible de lancer: aucun ennemi genere."
		_update_fight_type_label()
		return

	stack_fight_ui.hacker = hacker
	stack_fight_ui.run_active = true
	stack_fight_ui._between_fights_countdown_seconds = max(1, int(ceil(max(0.0, chain_delay_seconds))))
	stack_fight_ui.stack_fight_panel.set_wave_state(wave_data)
	stack_fight_ui._last_wave_enemy_count = stack_fight_ui._count_wave_enemies(wave_data)
	stack_fight_ui._last_encounter_type = str(wave_data.get("type", ""))
	stack_fight_ui._last_encounter_is_boss = wave_data.has("boss") or stack_fight_ui._last_encounter_type == "BOSS"

	current_fight = StackManager.new_fight(hacker, robots)
	stack_fight_ui.current_fight = current_fight
	stack_fight_ui.fight_connexions(current_fight)
	current_fight.s_combat_ended.connect(stack_fight_ui._on_combat_ended, CONNECT_ONE_SHOT)
	current_fight.s_combat_ended.connect(_on_test_combat_ended, CONNECT_ONE_SHOT)
	current_fight.start_fight(hacker, robots, stack_fight_ui)
	await stack_fight_ui._fade_in_combat_entities()
	start_button.disabled = true
	result_label.text = "Resultat: combat en cours..."


func _clamp_manager_position(manager: StackFightManager) -> void:
	var level_max = max(1, manager.levels_per_sector())
	manager.level_index = clamp(manager.level_index, 1, level_max)

	var wave_max = max(1, manager.waves_per_level())
	manager.wave_index = clamp(manager.wave_index, 1, wave_max)


func _on_test_combat_ended(victory: bool) -> void:
	current_fight = null

	if not victory:
		result_label.text = "Resultat: DEFAITE"
		stack_fight_ui.run_active = false
		test_hacker = null
		_update_fight_type_label()
		start_button.disabled = false
		return

	result_label.text = "Resultat: VICTOIRE"
	if not auto_chain_on_victory:
		stack_fight_ui.run_active = false
		test_hacker = null
		start_button.disabled = false
		_update_fight_type_label()
		return

	start_button.disabled = true


func _on_clear_logs_button_pressed() -> void:
	_reset_embedded_ui(true)


func _reset_embedded_ui(clear_logs: bool) -> void:
	if stack_fight_ui.stack_fight_panel != null and stack_fight_ui.stack_fight_panel.has_method("_clear"):
		stack_fight_ui.stack_fight_panel.call("_clear")
	if clear_logs and stack_fight_ui.fight_logs != null and stack_fight_ui.fight_logs.has_method("_clear"):
		stack_fight_ui.fight_logs.call("_clear")
	if stack_fight_ui.has_method("_hide_between_fights_countdown"):
		stack_fight_ui.call("_hide_between_fights_countdown")

	result_label.text = "Resultat: en attente"
	_update_fight_type_label()
	start_button.disabled = false
	current_fight = null
	test_hacker = null
	stack_fight_ui.run_active = false
	stack_fight_ui.current_fight = null


func _hide_embedded_start_button() -> void:
	var default_start_button := stack_fight_ui.get_node_or_null("StackFightPanel/VBoxContainer/StartFightButton")
	if default_start_button is Button:
		default_start_button.hide()


func _update_fight_type_label(wave_data: Dictionary = {}) -> void:
	if fight_type_label == null:
		return
	if wave_data.is_empty():
		fight_type_label.text = "Type de combat: en attente"
		return

	var encounter_type := str(wave_data.get("type", "NORMAL"))
	var readable_type := "ENNEMIS NORMAUX"
	if wave_data.has("boss") or encounter_type == "BOSS":
		readable_type = "BOSS"
	elif encounter_type == "ELITE":
		readable_type = "ELITE"

	fight_type_label.text = "Type de combat: %s" % readable_type


func _on_ui_encounter_started(wave_data: Dictionary) -> void:
	_update_fight_type_label(wave_data)
