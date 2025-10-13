extends Resource
class_name ActiveSkill

@export var cost: Array[int]   #son cout en skill point = le niveau
@export var as_cd: float
@export var as_during_time: float
@export var as_texture: Texture
@export var as_name: String
@export var data_bonus_1: Array
@export var data_bonus_2: Array
@export var is_offensive_skill: bool = false
@export var is_defensive_skill: bool = false
#Pour que le skill se débloque, la quantité de point investi dans sa catégorie (offensive ou def)
@export var min_cost_invested: int = 0

var as_level = 0
var tree
var as_is_active: bool = false
var as_is_on_cd:bool = false
var timer_cd: SceneTreeTimer
var timer_active: SceneTreeTimer


signal s_as_launched
signal s_as_finished
signal s_as_cd_finished
# Called when the node enters the scene tree for the first time.


func launch_as(surcharge_during_time: float = 0):
	"""A surcharger eventuellement"""
	if as_is_active or as_is_on_cd:
		return
	as_is_active = true
	if surcharge_during_time == 0:
		timer_active = tree.create_timer(self.as_during_time)
	else:
		timer_active = tree.create_timer(surcharge_during_time)
	timer_active.timeout.connect(as_finished)
	s_as_launched.emit()
	pass
	
func attach(_caster: Node, level) -> void:
	""" OBLIGATOIRE lors de l'instantiation d'un skill
	Appeler lorsqu'on add le skill, cela permet de gérer ce que fait le skill:
		- les connexions à appeler
		- l'ajout des stats brut
		
		A SURCHARGER """
	if is_defensive_skill == false and is_offensive_skill == false:
		push_error("Attention le skill doit etrer au moins offensif ou defensif")
	tree = _caster.get_tree()   # on récupère la référence de l'arbre
	self.as_level = level
	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill. Nous sommes vraiment dans 
	
	A SURCHARGER """
	pass
	

func as_finished(surcharge_cd:float = 0):
	"""Le sort a fini d'être actif. On lance le timer de on cd. la surcharge_cd est
	utilisé dans le cadre du chargement de la partie """
	as_is_active = false
	as_is_on_cd = true
	if surcharge_cd == 0: 
		timer_cd = tree.create_timer(self.as_cd)
	else:
		timer_cd = tree.create_timer(surcharge_cd)
	timer_cd.timeout.connect(as_cd_finished)
	s_as_finished.emit()
	pass
	
func as_cd_finished():
	"""Le cd est terminé"""
	s_as_cd_finished.emit()
	as_is_on_cd = false
	
