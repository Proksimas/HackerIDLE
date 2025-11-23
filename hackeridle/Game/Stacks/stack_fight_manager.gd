extends Node

## ----------------------------------------------------------------------------
## RÉFÉRENCES ET ENUMS
## ----------------------------------------------------------------------------

# Assurez-vous que ces chemins correspondent à votre structure de scène
@onready var hacker: Entity = $Hacker
@onready var robot_ia: Entity = $RobotIA

# États de la machine de combat
enum CombatPhase {
	PREPARATION,         # État Idle/Latence : Attend que les Cooldowns soient terminés.
	HACKER_EXECUTION,    # Exécution de la séquence du joueur.
	IA_EXECUTION,        # Exécution de la séquence du Robot IA.
	RESOLUTION,          # Vérification de victoire/défaite, application des récompenses.
}

var current_phase: CombatPhase = CombatPhase.PREPARATION

## ----------------------------------------------------------------------------
## INITIALISATION ET BOUCLE PRINCIPALE
## ----------------------------------------------------------------------------

func _ready():
	# Ici, vous chargerez les scripts initiaux dans les entités
	# Exemple : hacker.initialize_scripts(load_hacker_scripts())
	transition_to(CombatPhase.PREPARATION)

func _physics_process(delta: float):
	# La seule phase active en boucle est la PREPARATION (Gestion du temps/Idle)
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
		CombatPhase.PREPARATION:
			_on_enter_preparation()
		CombatPhase.HACKER_EXECUTION:
			_on_enter_hacker_execution()
		CombatPhase.IA_EXECUTION:
			_on_enter_ia_execution()
		CombatPhase.RESOLUTION:
			_on_enter_resolution()

# --- Fonctions d'Entrée dans les États ---

func _on_enter_preparation() -> void:
	# L'état d'attente/idle. Le _physics_process gère le temps.
	print("PHASE: Préparation (Attente des Cooldowns/Input du Joueur)")
	# Mettre à jour l'interface utilisateur pour demander la nouvelle séquence au joueur ici.

func _on_enter_hacker_execution() -> void:
	print("PHASE: Exécution du Hacker")
	
	# Exécution de la séquence du Hacker contre l'IA
	hacker.execute_sequence(robot_ia)

	# Vérification si l'IA est vaincue avant qu'elle ne puisse répliquer
	if robot_ia.current_hp <= 0:
		transition_to(CombatPhase.RESOLUTION)
	else:
		transition_to(CombatPhase.IA_EXECUTION)

func _on_enter_ia_execution() -> void:
	print("PHASE: Exécution de l'IA")
	
	# 1. L'IA prépare sa séquence pour ce cycle
	_ia_logic_prepare_sequence() 
	
	# 2. Exécution de la séquence du Robot IA contre le Hacker
	robot_ia.execute_sequence(hacker)
	
	# Transition vers la résolution
	transition_to(CombatPhase.RESOLUTION)

func _on_enter_resolution() -> void:
	print("PHASE: Résolution du Cycle")
	
	# Vérification de fin de combat
	if hacker.current_hp <= 0:
		_end_combat(false) # Défaite
	elif robot_ia.current_hp <= 0:
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
	
	# Exemple très basique : l'IA joue toujours les deux premiers scripts de son pool
	if robot_ia.available_scripts.size() >= 2:
		robot_ia.queue_script(robot_ia.available_scripts[0])
		robot_ia.queue_script(robot_ia.available_scripts[1])

func _end_combat(victory: bool) -> void:
	print("--- COMBAT TERMINÉ ---")
	if victory:
		print("VICTOIRE ! Gain de Force Cyber !")
		# Logique de récompense : ajouter de la Force Cyber, passer au niveau IA suivant.
	else:
		print("DÉFAITE. Retour au Méta-Jeu.")
		# Logique de défaite : Réinitialisation.
		
	# Ici, vous pourriez arrêter le jeu, changer de scène, ou retourner à l'interface principale.
