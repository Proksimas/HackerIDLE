extends Resource
class_name StackScript


# Propriétés de base du Script
@export var stack_script_name: String = "Script Inconnu"
@export var turn_cooldown_base: int = 5# Temps de rechargement de base
@export_category("Valeurs")

#Valeur de base de degat si l'entité est un robot

# Selon le type, le sort fait des dégats dans l'élements associé
# avec le bonus e degat associé
# La clé est le multiplacteur? mettre à 0 = * 0% , 0.5 = *0.5
@export var type_and_coef : Dictionary = {"penetration": 0.0,
							"encryption": 0.0,
							"flux": 0.0}
							
# temps en s de l'éxécution du script (temps de cast)
@export var execution_time: float = 3.0
							
var entity_is_hacker: bool = false
#enum TYPE {PENETRATION, ENCRYPTION, FLUX}
#@export var type: TYPE = TYPE.PENETRATION
#const TYPE_NAME = {TYPE.PENETRATION: "Penetration",
					#TYPE.ENCRYPTION: "Encryption",
					#TYPE.FLUX: "Flux"}
			
var turn_remaining: float = 0 # turn restant après exécution

var caster: Entity
var targets: Array[Entity]

func set_caster_and_targets(_caster: Entity, _targets: Array[Entity]) -> void:
	caster = _caster
	targets = _targets
	
# Méthode abstraite à implémenter par chaque type de Script
#func execute(caster: Entity, targets: Array[Entity]) -> void:
	## Logic spécifique au Script (dégâts, bouclier, etc.)
	#pass
func execute() -> Dictionary:
	"""Logic spécifique au Script (dégâts, bouclier, etc.)
	Return un dictionnaire avec tous les effets de l'éxécution
	(pv retirés, target etc...)
	
	dict = {"caster": caster,
			"targets": [targets[0]],
			"action_type": "Damage",
			"effects":
				{"value": damages, 
				"type": "HP"}
			}
	"""
	var dict = {}
	return dict

# Méthode appelée après l'exécution pour gérer le cooldown
func start_cooldown(_caster: Entity) -> void:
	# La Latence du Hacker réduit le temps réel de rechargement
	var effective_cooldown = turn_cooldown_base
	turn_remaining = max(0, effective_cooldown)
	
	
func calcul_effect_value(_caster: Entity):
	"""Generique pour le plus de scripts possible, va calculer la valeur de l'effet
	selon les caractéristiques."""

	var bonus_value: float = 0
	for type in type_and_coef:
		if _caster.entity_is_hacker:
			bonus_value += linear_calcul(\
						StackManager.stack_script_stats[type],
						type_and_coef[type], type) 
		else:
			bonus_value += linear_calcul(\
						_caster.stats[type], 
						type_and_coef[type], type) 
	return round(bonus_value)

func linear_calcul(robots_affected, perc, _type):
	var value = robots_affected * perc
	#print("Valeur de base de %s: %s avec perc de %s donne %s" % [type, robots_affected, perc, value ])
	
	return value
	
