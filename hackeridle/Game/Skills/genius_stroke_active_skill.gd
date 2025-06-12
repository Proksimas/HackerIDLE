extends ActiveSkill

var increase_knowledge_and_xp = [1,2,4]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func attach(caster: Node, level) -> void:
	""" OBLIGATOIRE lors de l'instantiation d'un skill
	Appeler lorsqu'on add le skill, cela permet de gérer ce que fait le skill:
		- les connexions à appeler
		- l'ajout des stats brut
		
		A SURCHARGER EVENTUELLEMENT"""
		
	tree = caster.get_tree()   # on récupère la référence de l'arbre
	self.as_level = level
	Player.s_brain_clicked.connect(_on_s_brain_clicked)
	
	
func _on_s_brain_clicked(brain_xp, knowledge):
	"""le cerveau a été cliqué, on fait donc les bonus associés"""
	# ATTENTION le knowledge reçu ici a déjà été reçu par le joueur.
	#
	#as_is_active = false
	if !as_is_active or as_is_on_cd:
		return
		
	var bonus_knowledge = (knowledge * increase_knowledge_and_xp[as_level -1 ])
	var bonus_xp = (brain_xp * increase_knowledge_and_xp[as_level -1 ])
	Player.knowledge_point += bonus_knowledge
	Player.brain_xp += bonus_xp
	pass
	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill
	A SURCHARGER """
	
	Player.s_brain_clicked.disconnect(_on_s_brain_clicked)
	pass
	
