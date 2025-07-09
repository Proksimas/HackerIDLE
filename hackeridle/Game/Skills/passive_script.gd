extends Resource
class_name PassiveSkill

@export var cost: Array[int]  #son cout en skill point = le niveau
@export var ps_texture: Texture
@export var ps_name: String
@export var data_bonus_1: Array
@export var data_bonus_2: Array

var ps_level = 0
var tree

	
func attach(_caster: Node, level) -> void:
	""" OBLIGATOIRE lors de l'instantiation d'un skill
	Appeler lorsqu'on add le skill, cela permet de gérer ce que fait le skill:
		- les connexions à appeler
		- l'ajout des stats brut
		
		A SURCHARGER """
		
	tree = _caster.get_tree()   # on récupère la référence de l'arbre
	self.ps_level = level
	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill
	
	A SURCHARGER """
	pass
	
