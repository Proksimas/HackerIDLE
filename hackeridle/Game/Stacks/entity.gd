# entity.gd
class_name Entity extends Node


@export var max_hp: float = 100.0
@export var current_hp: float = 100.0
@export var current_shield: float = 0.0 # Bouclier temporaire

@export_range(0.0, 5.0) var penetration: float = 1.0 # Stat PEN (Attaque)
@export_range(0.0, 5.0) var encryption: float = 1.0 # Stat CRYPT (Défense)
# Facteur de réduction de Cooldown. Ex: 0.5 = 50% de temps de rechargement en moins.

var entity_name: String = "default_name"
# Le pool de scripts ORIGINAUX (les modèles maîtres, non modifiés) APRES l'apprentissage
var available_scripts: Dictionary 

#La sequence de script enregistré
var sequence_order: Array[String]
# La Séquence/Stack pour le cycle actuel. 
# Elle contient les scripts choisis dans la séquences
var stack_script_sequence: Array[StackScript] = [] 


signal s_entity_die(entity)

# Méthode appelée par l'interface utilisateur (Hacker) ou la logique IA (RobotIA)
func queue_script(script_resource: StackScript) -> void:
	# IMPORTANT: Nous créons une instance locale (duplicata) de la ressource.
	# C'est cette instance qui gérera son propre temps de rechargement (time_remaining).
	var script_instance = script_resource.duplicate(true)
	stack_script_sequence.append(script_instance)
	
func save_sequence(scripts_name: Array[String]):
	"""on enregitre la séquences des scripts. Ils seront init ensuite
	au bon moment (phase de préparation du combat)"""
	sequence_order.clear()
	for script_name: String in scripts_name:
		if available_scripts.has(script_name):
			sequence_order.append(script_name)
		else:
			push_error("On save un script qui n'est pas dans le pool de l'entité !")

func init_sequence():
	"""on duplique dans l'ordre du array pour init la sequence selon le sequence_order"""
	for script_name: String in sequence_order:
		if available_scripts.has(script_name):
			queue_script(available_scripts[script_name])
		else:
			push_error("On init un script qui n'est pas dans le pool de l'entité !")

# Méthode principale appelée par le CombatManager pour exécuter le Stack
func execute_sequence(targets: Array[Entity]) -> void:
	print(entity_name + " démarre l'exécution de sa séquence de " + str(stack_script_sequence.size()) + " scripts.")
	
	# Exécution Script par Script
	for script_instance: StackScript in stack_script_sequence:
		if current_hp <= 0:
			print(entity_name + " a été détruit et arrête l'exécution.")
			break 
			
		print(" -> Exécution de: " + script_instance.stack_script_name)
		
		
		# 1. Exécution de la logique du Script (dégâts, bouclier, utility)
		# TODO CAR TARGETS EST UN ARRAY
		script_instance.execute(self, targets[0]) 
		
		# 2. Activation du Cooldown (Latence) sur l'instance
		script_instance.start_cooldown(self)
		
	# Vider la Stack pour le prochain cycle
	stack_script_sequence.clear()
	print(entity_name + " a terminé l'exécution de sa séquence.")

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
	
	if current_hp <= 0:
		#Entité vaincue
		current_hp = 0
		s_entity_die.emit(self)
	
	print(entity_name + " prend " + str(damage) + " dégâts. HP restants: " + str(current_hp))


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
