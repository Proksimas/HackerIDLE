extends Resource
class_name ActifSkill

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
	tree = caster.get_tree()   # on récupère la référence de l'arbre
	
	
func as_finished():
	"""A surcharger"""
	
	pass
	
