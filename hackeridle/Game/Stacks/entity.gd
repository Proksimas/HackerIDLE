# entity.gd
class_name Entity extends Node


@export var max_hp: float = 100.0
@export var current_hp: float = 100.0
@export var current_shield: float = 0.0 # Bouclier temporaire

@export var stats : Dictionary = {"penetration": 0,
							"encryption": 0,
							"flux": 0}

# Facteur de réduction de Cooldown. Ex: 0.5 = 50% de temps de rechargement en moins.

var entity_name: String = "default_name"
# Le pool de scripts ORIGINAUX (les modèles maîtres, non modifiés) APRES l'apprentissage
var available_scripts: Dictionary 
#La sequence de script enregistrée 
var sequence_order: Array[String]
# La Séquence/Stack pour le cycle actuel. 
# Elle contient les scripts choisis dans la séquences
var stack_script_sequence: Array[StackScript] = [] 
var entity_is_hacker: bool = false

var current_script_index: int = 0
var cache_targets: Array
signal s_entity_die(entity)
signal s_execute_script
signal s_sequence_completed(entity)

func _init(is_hacker: bool, _entity_name: String = "default_name", \
					stat_pen:int = 0, stat_enc:int = 0, stat_flux:int = 0):
	match is_hacker:
		true:
			entity_is_hacker = true
			entity_name = "hacker"
		false:
			entity_is_hacker = false
			entity_name = _entity_name
			
	stats['penetration'] = stat_pen
	stats['encryption'] = stat_enc
	stats['flux'] = stat_flux

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
	stack_script_sequence.clear()
	for script_name: String in sequence_order:
		if available_scripts.has(script_name):
			queue_script(available_scripts[script_name])
		else:
			push_error("On init un script qui n'est pas dans le pool de l'entité !")

# LOGIQUE DE COMBAT
# Méthode principale appelée par le CombatManager pour exécuter le Stack
func execute_sequence(targets: Array[Entity]) -> void:
	print(entity_name + " démarre l'exécution de sa séquence de " + str(stack_script_sequence.size()) + " scripts.")
	current_script_index = 0
	cache_targets = targets
	execute_next_script()

func execute_next_script():
	print("name: %s" % entity_name)
	if current_script_index >= stack_script_sequence.size():
		print(entity_name + " : Séquence terminée.\n")
		# Émettre un signal vers le CombatManager pour indiquer la fin de la Phase
		s_sequence_completed.emit(self)
		return

	var script_instance: StackScript = stack_script_sequence[current_script_index]
	print("Taille des targets: %s" % len(cache_targets))
	if current_hp <= 0:
		print(entity_name + " a été détruit et arrête l'exécution.")
		s_sequence_completed.emit(self)
		return
	elif cache_targets.is_empty():
		print("Toutes les targets sont mortes, on arrete")
		s_sequence_completed.emit(self)
		return
	print(" -> Exécution de: " + script_instance.stack_script_name)

	script_instance.set_caster_and_targets(self, cache_targets)
	var data_from_execution = script_instance.execute()
	print(data_from_execution)
	#reçu par le StackFightUI
	s_execute_script.emit(data_from_execution)

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


func _on_s_execute_script_ui_finished():
	"""signal reçu lorsque l'ui a bien fini d'afficher l exécution du script
	on peut passer au script suivant"""
	print("On passe au script suivant")
	current_script_index += 1
	execute_next_script()
	
