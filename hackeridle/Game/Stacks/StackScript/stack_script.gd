extends Resource
class_name StackScript


# Propriétés de base du Script
@export var stack_script_name: String = "Script Inconnu"
@export var cooldown_base: float = 5.0 # Temps de rechargement de base
@export_category("Valeurs")

#Valeur de base de degat si l'entité est un robot
@export var robot_ia_base_value: int = 1 
# Selon le type, le sort fait des dégats dans l'élements associé
# avec le bonus e degat associé
@export var type_and_coef : Dictionary = {"penetration": 1.0,
							"encryption": 1.0,
							"flux": 1.0}
							
var entity_is_hacker: bool = false
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
	
	
func calcul_effect_value(caster: Entity):
	"""Generique pour le plus de scripts possible, va calculer la valeur de l'effet
	selon les caractéristiques."""

	var bonus_value: float = 0
	for type in type_and_coef:
		if caster.entity_is_hacker:
			bonus_value += linear_calcul(\
						StackManager.stack_script_stats[type],
						type_and_coef[type]) 
		else:
			bonus_value += linear_calcul(\
						robot_ia_base_value,
						type_and_coef[type]) 
	return round(bonus_value)

func linear_calcul(robots_affected, perc):
	var value = robots_affected * perc
	print("Valeur de base: %s avec perc de %s donne %s" % [robots_affected, perc, value ])
	return value
	
