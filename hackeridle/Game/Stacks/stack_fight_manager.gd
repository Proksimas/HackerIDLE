extends Node

class_name StackFightManager
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
## ----------------------------------------------------------------------------
## INITIALISATION ET BOUCLE PRINCIPALE
## ----------------------------------------------------------------------------

	
func new_fight(_hacker: Entity, robots: Array[Entity]):
	hacker = _hacker
	robots_ia = robots
	transition_to(CombatPhase.ENTERING_FIGHT)

func _physics_process(delta: float):
	match current_phase:
		CombatPhase.PREPARATION:
			# Mise à jour des cooldowns (Latence) pour le Hacker
			hacker.update_cooldowns(delta)
			
			# Condition de transition : Si le Hacker est prêt (tous ses scripts sont rechargés)
			if hacker.is_ready_for_next_cycle():
				# NOTE: Ici vous pouvez aussi vérifier si le Hacker a bien préparé sa stack.
				if hacker.script_sequence.size() > 0:
					transition_to(CombatPhase.HACKER_EXECUTION)
				else:
					# Empêche la boucle de tourner si la stack est vide (le joueur doit la remplir)
					pass 
		
		# Les autres phases sont gérées par les fonctions de transition instantanées
		_:
			pass

## ----------------------------------------------------------------------------
## MACHINE À ÉTATS : LOGIQUE DE TRANSITION
## ----------------------------------------------------------------------------

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
	print("PHASE: Entering fight")
	hacker.s_entity_die.connect(_on_hacker_died)
	for robot in robots_ia:
		robot.s_entity_die.connect(_on_robot_died)
	transition_to(CombatPhase.PREPARATION)
	
func _on_enter_preparation() -> void:
	# L'état d'attente/idle. Le _physics_process gère le temps.
	print("PHASE: Préparation (Attente des Cooldowns/Input du Joueur)")
	# Mettre à jour l'interface utilisateur pour demander la nouvelle séquence au joueur ici.
	# Connexion des signaux
	print("PV du hacker: %s" % hacker.current_hp)
	hacker.init_sequence()
	for robot in robots_ia:
		print("PV du %s: %s" % [robot.entity_name, robot.current_hp])
		robot.init_sequence()
	
	transition_to(CombatPhase.HACKER_EXECUTION)


func _on_enter_hacker_execution() -> void:
	print("PHASE: Exécution du Hacker")
	
	# Exécution de la séquence du Hacker contre l'IA
	hacker.execute_sequence(robots_ia)

	# Vérification si l'IA est vaincue avant qu'elle ne puisse répliquer
	# TODO CAR ROBOTS IA EST UNE LISTE

	if robots_ia.is_empty():
		transition_to(CombatPhase.RESOLUTION)
	else:
		transition_to(CombatPhase.IA_EXECUTION)

func _on_enter_ia_execution() -> void:
	print("PHASE: Exécution de l'IA")
	
	# 1. L'IA prépare sa séquence pour ce cycle
	_ia_logic_prepare_sequence() 
	
	# 2. Exécution de la séquence du Robot IA contre le Hacker
	for robot_ia in robots_ia:
		robot_ia.execute_sequence([hacker])
	
	# Transition vers la résolution
	transition_to(CombatPhase.RESOLUTION)

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


func _on_hacker_died(hacker:Entity):
	print("Le hacker est dead")
	_end_combat(false) # Défaite
	
func _on_robot_died(_robot:Entity):
	print("%s est dead" % _robot.entity_name)
	for robot in robots_ia:
		if robot == _robot:
			robots_ia.erase(robot)
			
