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
signal s_fight_started(hack, array_robots)

func start_fight(_hacker: Entity, _robots: Array[Entity], stack_fight_ui):
	hacker = _hacker
	robots_ia = _robots
	current_stack_fight_ui = stack_fight_ui
	s_fight_started.emit(hacker, robots_ia)
	

func transition_to(new_phase: CombatPhase) -> void:
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
	print("PHASE: Entering fight")
	hacker.s_entity_die.connect(_on_hacker_died)
	for robot in robots_ia:
		robot.s_entity_die.connect(_on_robot_died)
	current_turn = 0
	transition_to(CombatPhase.PREPARATION)
	
func _on_enter_preparation() -> void:
	"""La phase de préparation avant chaque lancement de séquence.
	Correspond à un tour de jeu"""
	# L'état d'attente/idle. Le _physics_process gère le temps.
	print("PHASE: Préparation (Attente des Cooldowns")
	# Mettre à jour l'interface utilisateur pour demander la nouvelle séquence au joueur ici.
	# Connexion des signaux
	print("PV du hacker: %s" % hacker.current_hp)
	current_turn += 1
	hacker.init_sequence()
	for robot in robots_ia:
		print("PV du %s: %s" % [robot.entity_name, robot.current_hp])
		robot.init_sequence()
	
	transition_to(CombatPhase.HACKER_EXECUTION)


func _on_enter_hacker_execution() -> void:
	"""Phase du hacker. Il déroule toute sa séquence. """
	print("PHASE: Exécution du Hacker")
	
	# Exécution de la séquence du Hacker contre l'IA
	entity_connexions(hacker)
	hacker.execute_sequence(robots_ia)


		
func entity_connexions(entity: Entity):
	"""On connecte les signaux de l'entité, vers le stack_fight_ui"""
	entity.s_execute_script.connect(current_stack_fight_ui._on_execute_script)
	current_stack_fight_ui.s_execute_script_ui_finished.connect(entity._on_s_execute_script_ui_finished)
	entity.s_sequence_completed.connect(_on_sequence_completed)

func entity_deconnexion(entity: Entity):
	"""Deconnexion"""
	if entity.s_execute_script.is_connected(current_stack_fight_ui._on_execute_script):
		entity.s_execute_script.disconnect(current_stack_fight_ui._on_execute_script)
	if current_stack_fight_ui.s_execute_script_ui_finished.is_connected(entity._on_s_execute_script_ui_finished):
		current_stack_fight_ui.s_execute_script_ui_finished.disconnect(entity._on_s_execute_script_ui_finished)
	if entity.s_sequence_completed.is_connected(_on_sequence_completed):
		entity.s_sequence_completed.disconnect(_on_sequence_completed)

var current_ia_index: int = 0
func _on_enter_ia_execution() -> void:
	print("PHASE: Exécution de l'IA")
	current_ia_index = 0
	# 1. L'IA prépare sa séquence pour ce cycle
	_ia_logic_prepare_sequence() 
	next_ia_execution()
	## 2. Exécution de la séquence du Robot IA contre le Hacker
	#for robot_ia in robots_ia:
		#entity_connexions(robot_ia)
		#robot_ia.execute_sequence([hacker])
	#
	# Transition vers la résolution
	#transition_to(CombatPhase.RESOLUTION)
func next_ia_execution():
	var ia = robots_ia[current_ia_index]
	entity_connexions(ia)
	ia.execute_sequence([hacker])
	current_ia_index += 1
	

func _on_enter_resolution() -> void:
	print("PHASE: Résolution du Cycle")
	print("PV du hacker: %s" % hacker.current_hp)
	
	for robot in robots_ia:
		print("PV du %s: %s" % [robot.entity_name, robot.current_hp])
	# Vérification de fin de combat
	if hacker.current_hp <= 0:
		_end_combat(false) # Défaite
	elif robots_ia.is_empty():
		_end_combat(true)  # Victoire
	else:
		# Le combat continue, on revient à l'état Idle pour la prochaine séquence
		print("Le combat n'est pas fini")
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
	print("--- COMBAT TERMINÉ ---")
	if victory:
		print("VICTOIRE ! Gain de Force Cyber !")
		# Logique de récompense : ajouter de la Force Cyber, passer au niveau IA suivant.
	else:
		print("DÉFAITE. Retour au Méta-Jeu.")
		# Logique de défaite : Réinitialisation.
		
	# Ici, vous pourriez arrêter le jeu, changer de scène, ou retourner à l'interface principale.
	# TODO phase des recompenses
	
	self.queue_free()

# SIGNAUX
func _on_fight_ui_phase_finished(phase: String):
	match phase:
		"fight_start":
			transition_to(CombatPhase.ENTERING_FIGHT)

func _on_sequence_completed(entity: Entity):
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
		
		print("faut aller au second robot")
		

func _on_hacker_died(hacker:Entity):
	print("Le hacker est dead")
	_end_combat(false) # Défaite
	
func _on_robot_died(_robot:Entity):
	print("%s est dead" % _robot.entity_name)
	for robot in robots_ia:
		if robot == _robot:
			robots_ia.erase(robot)
			
