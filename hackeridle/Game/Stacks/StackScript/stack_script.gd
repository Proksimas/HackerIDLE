extends Resource
class_name StackScript


# Propriétés de base du Script
@export var stack_script_name: String = "Script Inconnu"
@export var cooldown_base: float = 5.0 # Temps de rechargement de base
@export_category("Valeurs")
@export var bonus_ev_perc: float = 0.0 #Ajout flat à la bonus; 1.2 = 120%

# Selon le type, le sort fait des dégats dans l'élements associé
# avec le bonus e degat associé
@export var type_and_coef : Dictionary = {"penetration": 1.0,
							"encryption": 1.0,
							"flux": 1.0}
#enum TYPE {PENETRATION, ENCRYPTION, FLUX}
#@export var type: TYPE = TYPE.PENETRATION
#const TYPE_NAME = {TYPE.PENETRATION: "Penetration",
					#TYPE.ENCRYPTION: "Encryption",
					#TYPE.FLUX: "Flux"}
					
					
# Propriétés dynamiques pour l'état
var time_remaining: float = 0.0 # Cooldown restant après exécution

# Méthode abstraite à implémenter par chaque type de Script
func execute(caster: Entity, targets: Array[Entity]) -> void:
	# Logic spécifique au Script (dégâts, bouclier, etc.)
	pass

# Méthode appelée après l'exécution pour gérer le cooldown
func start_cooldown(caster: Entity) -> void:
	# La Latence du Hacker réduit le temps réel de rechargement
	var effective_cooldown = cooldown_base
	time_remaining = max(0.1, effective_cooldown)
	
	
func calcul_effect_value():
	"""Generique pour le plus de scripts possible, va calculer la valeur de l'effet
	selon les caractéristiques. Calcul:
	 
	"""

	var robots_affected: int 
	var bonus_value: float
	for type in type_and_coef:
		if type == "penetration":
			bonus_value += linear_calcul(\
						StackManager.stack_script_stats["penetration"],
						type_and_coef[type]) 
		elif type == "encryption":
			bonus_value += linear_calcul(\
						StackManager.stack_script_stats["encryption"],
						type_and_coef[type]) 
						
		elif type == "flux":
			bonus_value += linear_calcul(\
						StackManager.stack_script_stats["flux"],
						type_and_coef[type]) 

func linear_calcul(robots_affected, perc):
	return robots_affected * perc
	
