# entity.gd
class_name Entity extends Node


var max_hp: float = 20
var current_hp: float = 20
var base_hacker_hp = 20
var current_shield: float = 0.0 # Bouclier temporaire
var stats : Dictionary = {"penetration": 0,
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
var self_is_dead: bool = false

var current_script_index: int = 0
var cache_targets: Array
signal s_entity_die(entity)
signal s_execute_script
signal s_sequence_completed(entity)
signal s_cast_script

func _init(is_hacker: bool, _entity_name: String = "default_name", \
			_max_hp:int = 20, stat_pen:int = 0, stat_enc:int = 0, stat_flux:int = 0):
	stats['penetration'] = float(stat_pen)
	stats['encryption'] = float(stat_enc)
	stats['flux'] = float(stat_flux)
	
	match is_hacker:
		true:
			entity_is_hacker = true
			entity_name = "hacker"
			set_hacker_max_hp()
			print("hp du hacker: %s" % max_hp)
		false:
			entity_is_hacker = false
			entity_name = _entity_name
			max_hp = _max_hp
	
	current_hp = max_hp


		
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
			
func set_hacker_max_hp():
	"""Calcule le max hp du hacker selon les stats et autres modificateurs"""
	if !self.entity_is_hacker:
		push_warning("L'entité doit etre le hacker")
		return
	
	max_hp = base_hacker_hp + (StackManager.stack_script_stats["penetration"] + \
							(StackManager.stack_script_stats["encryption"] * 1.5) + \
							(StackManager.stack_script_stats["flux"] * 0.5))
	

# LOGIQUE DE COMBAT
# Méthode principale appelée par le StackFight pour exécuter le Stack
func execute_sequence(targets: Array[Entity]) -> void:
	print(entity_name + " démarre l'exécution de sa séquence de " + str(stack_script_sequence.size()) + " scripts.")
	current_script_index = 0
	cache_targets = targets
	
	#on doit lancer la première exécution sur l'ui. lorsqu'il sera fini,
	#on execute le next_scrip
	
	prepare_next_script()

func prepare_next_script():
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
	
	#On doit lancer l'ui qui cast le script. Lorsque cela sera fini,
	#on pourra l'exécuter
	var data_before_execution ={"caster": self,
			"targets": [cache_targets]
			}
	s_cast_script.emit(current_script_index, data_before_execution) #->StackFightUi
	

func execute_next_script():
	"""Tout est bon, l'ui est ok, il faut maintenant executer le script"""
	print('execute_next_script')
	var script_instance: StackScript = stack_script_sequence[current_script_index]
	script_instance.set_caster_and_targets(self, cache_targets)
	var data_from_execution = script_instance.execute()
	CombatResolver.resolve(data_from_execution)
	#reçu par le StackFightUI
	s_execute_script.emit(current_script_index, data_from_execution)
	
	
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
		self_is_dead = true
	
	print(entity_name + " prend " + str(damage) + " dégâts. HP restants: " + str(current_hp))

func add_shield(value: float) -> void:
	if value <= 0:
		return
	current_shield = min(current_shield + value, max_hp)

func take_pierce_damage(damage: float) -> void:
	current_hp -= damage
	if current_hp <= 0:
		current_hp = 0
		s_entity_die.emit(self)
		self_is_dead = true

func heal(value: float) -> void:
	if value <= 0:
		return
	current_hp = min(current_hp + value, max_hp)


func _on_s_execute_script_ui_finished():
	"""signal reçu lorsque l'ui a bien fini d'afficher l exécution du script
	on peut passer au script suivant"""
	print("On passe au script suivant")
	current_script_index += 1
	prepare_next_script()
	
