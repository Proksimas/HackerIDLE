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
var as_is_on_cd:bool = false
var timer_cd: SceneTreeTimer

signal s_as_launched
signal s_as_finished
signal s_as_cd_finished
# Called when the node enters the scene tree for the first time.


func launch_as():
	"""A surcharger eventuellement"""
	if as_is_active or as_is_on_cd:
		return
	as_is_active = true
	
	var timer_active: SceneTreeTimer = tree.create_timer(self.as_during_time)
	timer_active.timeout.connect(as_finished)
	s_as_launched.emit()
	pass
	
func attach(_caster: Node, level) -> void:
	""" OBLIGATOIRE lors de l'instantiation d'un skill
	Appeler lorsqu'on add le skill, cela permet de gérer ce que fait le skill:
		- les connexions à appeler
		- l'ajout des stats brut
		
		A SURCHARGER """
		
	tree = _caster.get_tree()   # on récupère la référence de l'arbre
	self.as_level = level
	
func detach(caster: Node)-> void:
	"""dettache les ajouts que donne le sill
	
	A SURCHARGER """
	pass
	

func as_finished():
	"""Le sort a fini d'être actif. On lance le timer de on cd A surcharger"""
	as_is_active = false
	as_is_on_cd = true
	timer_cd = tree.create_timer(self.as_cd)
	timer_cd.timeout.connect(as_cd_finished)
	s_as_finished.emit()
	pass
	
func as_cd_finished():
	"""Le cd est terminé"""
	s_as_cd_finished.emit()
	as_is_on_cd = false
	
