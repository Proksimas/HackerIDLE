extends Node

class_name StackFight
## --	--------------------------------------------------------------------------
## RÉFÉRENCES ET ENUMS
## ----------------------------------------------------------------------------

# Assurez-vous que ces chemins correspondent à votre structure de scène
var hacker: Entity
var robots_ia: Array[Entity]

# États de la machine de combat
enum CombatPhase {
	ENTERING_FIGHT,
	PREPARATION,         # État Idle/Latence : Attend que les Cooldowns soient terminés.
	HACKER_EXECUTION,    # Exécution de la séquence du joueur.
	IA_EXECUTION,        # Exécution de la séquence du Robot IA.
	RESOLUTION,          # Vérification de victoire/défaite, application des récompenses.
}

var current_phase: CombatPhase = CombatPhase.PREPARATION
var current_turn: int = 0
var current_stack_fight_ui
var combat_ended: bool = false
signal s_fight_started(hack, array_robots)
signal s_combat_ended(victory: bool)

func start_fight(_hacker: Entity, _robots: Array[Entity], stack_fight_ui):
	combat_ended = false
	hacker = _hacker
	robots_ia = _robots
	current_stack_fight_ui = stack_fight_ui
	s_fight_started.emit(hacker, robots_ia)
	

func transition_to(new_phase: CombatPhase) -> void:
	if combat_ended:
		return
	current_phase = new_phase
	
	match current_phase:
		CombatPhase.ENTERING_FIGHT:
			_on_enter_entering_fight()
		CombatPhase.PREPARATION:
			_on_enter_preparation()
		CombatPhase.HACKER_EXECUTION:
			_on_enter_hacker_execution()
		CombatPhase.IA_EXECUTION:
			_on_enter_ia_execution()
		CombatPhase.RESOLUTION:
			_on_enter_resolution()

# --- Fonctions d'Entrée dans les États ---
func _on_enter_entering_fight() -> void:
	"""Phase juste apres la création du fight. on est dans une forme de 
	pré préparation (en gros, avant de rentrer dans la logique du fight)"""
	var hacker_die_callable := Callable(self, "_on_hacker_died")
	if not hacker.s_entity_die.is_connected(hacker_die_callable):
		hacker.s_entity_die.connect(hacker_die_callable)
	for robot in robots_ia:
		var robot_die_callable := Callable(self, "_on_robot_died")
		if not robot.s_entity_die.is_connected(robot_die_callable):
			robot.s_entity_die.connect(robot_die_callable)
	current_turn = 0
	transition_to(CombatPhase.PREPARATION)
	
func _on_enter_preparation() -> void:
	"""La phase de préparation avant chaque lancement de séquence.
	Correspond à un tour de jeu"""
	# L'état d'attente/idle. Le _physics_process gère le temps.
	# Mettre à jour l'interface utilisateur pour demander la nouvelle séquence au joueur ici.
	# Connexion des signaux
	current_turn += 1
	hacker.tick_all_script_cooldowns()
	hacker.init_sequence()
	for robot in robots_ia:
		robot.tick_all_script_cooldowns()
		robot.init_sequence()

	if current_stack_fight_ui != null and current_stack_fight_ui.has_method("refresh_stack_components_cooldowns"):
		current_stack_fight_ui.refresh_stack_components_cooldowns()
	
	transition_to(CombatPhase.HACKER_EXECUTION)


func _on_enter_hacker_execution() -> void:
	"""Phase du hacker. Il déroule toute sa séquence. """
	
	# Exécution de la séquence du Hacker contre l'IA
	entity_connexions(hacker)
	hacker.execute_sequence(robots_ia)

func entity_connexions(entity: Entity):
	"""On connecte les signaux de l'entité, vers le stack_fight_ui"""
	var cast_callable := Callable(current_stack_fight_ui, "_on_s_cast_script")
	var execute_callable := Callable(current_stack_fight_ui, "_on_execute_script")
	var execute_finished_callable := Callable(entity, "_on_s_execute_script_ui_finished")
	var sequence_completed_callable := Callable(self, "_on_sequence_completed")
	var send_log_callable := Callable(self, "_on_s_send_log")

	if not entity.s_cast_script.is_connected(cast_callable):
		entity.s_cast_script.connect(cast_callable)
	if not entity.s_execute_script.is_connected(execute_callable):
		entity.s_execute_script.connect(execute_callable)
	if not current_stack_fight_ui.s_execute_script_ui_finished.is_connected(execute_finished_callable):
		current_stack_fight_ui.s_execute_script_ui_finished.connect(execute_finished_callable)
	if not entity.s_sequence_completed.is_connected(sequence_completed_callable):
		entity.s_sequence_completed.connect(sequence_completed_callable)
	if not entity.s_send_log.is_connected(send_log_callable):
		entity.s_send_log.connect(send_log_callable)

func entity_deconnexion(entity: Entity):
	"""Deconnexion"""
	var cast_callable := Callable(current_stack_fight_ui, "_on_s_cast_script")
	var execute_callable := Callable(current_stack_fight_ui, "_on_execute_script")
	var execute_finished_callable := Callable(entity, "_on_s_execute_script_ui_finished")
	var sequence_completed_callable := Callable(self, "_on_sequence_completed")
	var send_log_callable := Callable(self, "_on_s_send_log")

	if entity.s_cast_script.is_connected(cast_callable):
		entity.s_cast_script.disconnect(cast_callable)
	if entity.s_execute_script.is_connected(execute_callable):
		entity.s_execute_script.disconnect(execute_callable)
	if current_stack_fight_ui.s_execute_script_ui_finished.is_connected(execute_finished_callable):
		current_stack_fight_ui.s_execute_script_ui_finished.disconnect(execute_finished_callable)
	if entity.s_sequence_completed.is_connected(sequence_completed_callable):
		entity.s_sequence_completed.disconnect(sequence_completed_callable)
	if entity.s_send_log.is_connected(send_log_callable):
		entity.s_send_log.disconnect(send_log_callable)
var current_ia_index: int = 0
func _on_enter_ia_execution() -> void:
	current_ia_index = 0
	# 1. L'IA prépare sa séquence pour ce cycle
	_ia_logic_prepare_sequence() 
	next_ia_execution()

func next_ia_execution():
	if combat_ended:
		return
	var ia = robots_ia[current_ia_index]
	current_ia_index += 1
	entity_connexions(ia)
	ia.execute_sequence([hacker])
	
	

func _on_enter_resolution() -> void:
	
	# Vérification de fin de combat
	if hacker.current_hp <= 0:
		_end_combat(false) # Défaite
	elif robots_ia.is_empty():
		_end_combat(true)  # Victoire
	else:
		# Le combat continue, on revient à l'état Idle pour la prochaine séquence
		transition_to(CombatPhase.PREPARATION)

## ----------------------------------------------------------------------------
## LOGIQUE IA ET FIN DE COMBAT
## ----------------------------------------------------------------------------

# Fonction placeholder pour la logique de l'IA
func _ia_logic_prepare_sequence() -> void:
	# L'IA doit ici remplir sa propre stack (robot_ia.queue_script())
	# C'est ici que vous définirez les 'patterns' de l'IA contre les stats du joueur
	print("  [IA Logic] Le robot IA prépare sa contre-attaque...")
	

func _end_combat(victory: bool) -> void:
	if combat_ended:
		return
	combat_ended = true
	var hacker_die_callable := Callable(self, "_on_hacker_died")
	if hacker != null and hacker.s_entity_die.is_connected(hacker_die_callable):
		hacker.s_entity_die.disconnect(hacker_die_callable)
	var robot_die_callable := Callable(self, "_on_robot_died")
	for robot in robots_ia:
		if robot != null and robot.s_entity_die.is_connected(robot_die_callable):
			robot.s_entity_die.disconnect(robot_die_callable)
	entity_deconnexion(hacker)
	robots_ia.all(entity_deconnexion)

	# Ici, vous pourriez arrêter le jeu, changer de scène, ou retourner à l'interface principale.
	# TODO phase des recompenses
	s_combat_ended.emit(victory)
	self.queue_free()

# SIGNAUX
func _on_fight_ui_phase_finished(phase: String):
	if combat_ended:
		return
	match phase:
		"fight_start":
			transition_to(CombatPhase.ENTERING_FIGHT)

func _on_sequence_completed(entity: Entity):
	if combat_ended:
		return
	entity_deconnexion(entity)
	if entity.entity_is_hacker:
		if robots_ia.is_empty():
			transition_to(CombatPhase.RESOLUTION)
		else:
			transition_to(CombatPhase.IA_EXECUTION)
	else:
		if current_ia_index >= len(robots_ia):
			transition_to(CombatPhase.RESOLUTION)
		else:
			next_ia_execution()
		
		

func _on_hacker_died(_hacker:Entity):
	if combat_ended:
		return
	current_stack_fight_ui.fight_logs.add_log({"action_type": "Death",
												"caster": _hacker}
												)
	call_deferred("_end_combat", false)
	
func _on_robot_died(_robot:Entity):
	if combat_ended:
		return
	current_stack_fight_ui.fight_logs.add_log({"action_type": "Death",
												"caster": _robot}
												)
	for robot in robots_ia:
		if robot == _robot:
			robots_ia.erase(robot)
			break
	if robots_ia.is_empty():
		call_deferred("_end_combat", true)
			
func _on_s_send_log(logs):
	"""on reçoit spécialement un log, qu'on envoie directement au fight.logs"""
	if combat_ended:
		return
	current_stack_fight_ui.fight_logs.add_log(logs)
