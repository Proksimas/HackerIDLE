extends Resource
class_name ActiveSkill

@export var cost:Array   #son cout en skill point = le niveau
@export var as_cd: float
@export var as_during_time: float
@export var as_texture: Texture
@export var as_name: String

var as_level = 0
var tree
var as_is_active: bool = false

signal s_as_finished
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func launch_as():
	"""A surcharger"""
	
	pass
	
func attach(caster: Node, level) -> void:
	""" OBLIGATOIRE lors de l'instantiation d'un skill
	Appeler lorsqu'on add le skill, cela permet de gérer ce que fait le skill:
		- les connexions à appeler
		- l'ajout des stats brut
		
		A SURCHARGER EVENTUELLEMENT"""
		
	tree = caster.get_tree()   # on récupère la référence de l'arbre
	self.as_level = level
	
func detach(caster: Node)-> void:
	"""dettache les ajouts que donne le sill
	
	A SURCHARGER """
	pass
	

func as_finished():
	"""A surcharger"""
	as_is_active = false
	s_as_finished.emit()
	pass
