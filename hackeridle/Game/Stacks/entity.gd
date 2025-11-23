# entity.gd
class_name Entity extends Node


@export var max_hp: float = 100.0
@export var current_hp: float = 100.0
@export var current_shield: float = 0.0 # Bouclier temporaire

@export_range(0.0, 5.0) var penetration: float = 1.0 # Stat PEN (Attaque)
@export_range(0.0, 5.0) var encryption: float = 1.0 # Stat CRYPT (Défense)
# Facteur de réduction de Cooldown. Ex: 0.5 = 50% de temps de rechargement en moins.
@export_range(0.0, 0.9) var latency_multiplier: float = 0.0 # Stat LAT (Vitesse Idle)

## ----------------------------------------------------------------------------
## 2. GESTION DES SCRIPTS (Ressources)
## ----------------------------------------------------------------------------

# Le pool de scripts ORIGINAUX (les modèles maîtres, non modifiés)
var available_scripts: Array[StackScript] = [] 
# La Séquence/Stack pour le cycle actuel. Elle contient des INSTANCES (duplicatas) des scripts maîtres.
var script_sequence: Array[StackScript] = [] 

## ----------------------------------------------------------------------------
## 3. METHODES DE L'ENTITE
## ----------------------------------------------------------------------------

# Initialisation ou chargement des scripts disponibles
func initialize_scripts(script_pool: Array[StackScript]) -> void:
	available_scripts = script_pool.duplicate()

# Méthode appelée par l'interface utilisateur (Hacker) ou la logique IA (RobotIA)
func queue_script(script_resource: StackScript) -> void:
	# IMPORTANT: Nous créons une instance locale (duplicata) de la ressource.
	# C'est cette instance qui gérera son propre temps de rechargement (time_remaining).
	var script_instance = script_resource.duplicate(true)
	script_sequence.append(script_instance)
	
	# NOTE: Ici, vous pourriez ajouter des vérifications (limite de taille de stack, coût en Compute, etc.)

# Méthode principale appelée par le CombatManager pour exécuter le Stack
func execute_sequence(target: Entity) -> void:
	print(name + " démarre l'exécution de sa séquence de " + str(script_sequence.size()) + " scripts.")
	
	# Exécution Script par Script
	for script_instance in script_sequence:
		if current_hp <= 0:
			print(name + " a été détruit et arrête l'exécution.")
			break 
			
		print(" -> Exécution de: " + script_instance.script_name)
		
		# 1. Exécution de la logique du Script (dégâts, bouclier, utility)
		script_instance.execute(self, target) 
		
		# 2. Activation du Cooldown (Latence) sur l'instance
		script_instance.start_cooldown(self)
		
	# Vider la Stack pour le prochain cycle
	script_sequence.clear()
	print(name + " a terminé l'exécution de sa séquence.")

# Méthode pour appliquer les dégâts
func take_damage(damage: float) -> void:
	# (Logique simplifiée) Le bouclier absorbe d'abord les dégâts
	var damage_after_shield = damage

	if current_shield > 0:
		if damage <= current_shield:
			current_shield -= damage
			damage_after_shield = 0.0
		else:
			damage_after_shield = damage - current_shield
			current_shield = 0.0

	current_hp -= damage_after_shield
	
	if current_hp < 0:
		current_hp = 0
	
	print(name + " prend " + str(damage) + " dégâts. HP restants: " + str(current_hp))


# Méthode pour la gestion du temps de rechargement (utilisée par CombatManager)
func update_cooldowns(delta: float) -> void:
	# Parcours les scripts disponibles (qui ont été dupliqués lors du dernier cycle)
	# et met à jour leur temps de rechargement
	for script in available_scripts:
		if script.time_remaining > 0.0:
			script.time_remaining -= delta
			if script.time_remaining < 0.0:
				script.time_remaining = 0.0

# Méthode pour vérifier si tous les scripts sont hors Cooldown (Latence)
func is_ready_for_next_cycle() -> bool:
	for script in available_scripts:
		if script.time_remaining > 0.0:
			return false
	return true
