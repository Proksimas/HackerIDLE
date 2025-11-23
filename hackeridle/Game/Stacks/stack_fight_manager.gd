# combat_manager.gd
extends Node

@onready var hacker: Entity = $Hacker
@onready var robot_ia: Entity = $RobotIA

enum CombatPhase {
	PREPARATION, # Phase Idle (Cooldown)
	HACKER_EXECUTION,
	IA_EXECUTION,
	CYCLE_END
}

var current_phase: CombatPhase = CombatPhase.PREPARATION

func _ready():
	# ... Chargement des données, des scripts, etc.
	pass

# Fonction pour démarrer un nouveau cycle de combat
func _start_cycle() -> void:
	# S'assurer que les deux entités sont prêtes et que tous les scripts sont hors Cooldown
	if !is_ready_for_next_cycle():
		# ICI : L'aspect idle entre en jeu. Le jeu attend la fin du Cooldown (Latence)
		current_phase = CombatPhase.PREPARATION
		return
		
	current_phase = CombatPhase.HACKER_EXECUTION
	# 1. Phase du Joueur
	hacker.execute_sequence(robot_ia)

	# Vérification de victoire/défaite après la phase du joueur
	if robot_ia.current_hp <= 0:
		_end_combat(true)
		return

	current_phase = CombatPhase.IA_EXECUTION
	# 2. Phase de l'IA (L'IA doit avoir son script_sequence préparé ici)
	robot_ia.execute_sequence(hacker)

	# Vérification finale
	if hacker.current_hp <= 0:
		_end_combat(false)
		return

	current_phase = CombatPhase.CYCLE_END
	# Après la vérification, la boucle redémarre (après un court délai pour la lisibilité)
	# L'exécution n'est possible que si la Latence est passée
	
# Fonction pour vérifier si tous les scripts du Hacker sont rechargés
func is_ready_for_next_cycle() -> bool:
	# Parcours tous les scripts disponibles et vérifie que time_remaining est 0
	for script in hacker.available_scripts:
		if script.time_remaining > 0.0:
			return false
	return true
	
func _physics_process(delta: float):
	# Gestion de la Latence/Cooldown pendant la phase de PREPARATION
	if current_phase == CombatPhase.PREPARATION:
		_update_cooldowns(delta)
		# Lancement automatique du cycle si prêt
		if is_ready_for_next_cycle():
			_start_cycle()

func _update_cooldowns(delta: float) -> void:
	# Met à jour le temps de rechargement de TOUS les scripts du Hacker
	for script in hacker.available_scripts:
		if script.time_remaining > 0.0:
			script.time_remaining -= delta
			if script.time_remaining < 0.0:
				script.time_remaining = 0.0
