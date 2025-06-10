extends Resource
class_name ActiveSkill

@export var cost: int   #son cout en skill point
@export var as_cd: float
@export var as_during_time: float
@export var as_texture: Texture
@export var as_name: String

var tree
var as_is_active: bool = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func can_cast():
	if !as_is_active:
		attach(Player)
		return true
	else:
		return false
		
	pass

func launch_as():
	"""A surcharger"""
	
	pass
	
func attach(caster: Node) -> void:
	""" OBLIGATOIRE lors de l'instantiation d'un skill
	Appeler lorsqu'on add le skill, cela permet de gérer ce que fait le skill:
		- les connexions à appeler
		- l'ajout des stats brut
		
		A SURCHARGER"""
		
	tree = caster.get_tree()   # on récupère la référence de l'arbre
	
func detach(caster: Node)-> void:
	"""dettache les ajouts que donne le sill
	
	A SURCHARGER """
	pass
	
