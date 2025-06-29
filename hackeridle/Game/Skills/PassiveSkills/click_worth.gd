extends PassiveSkill

var repeat_click = [1,2,4]

func attach(_caster: Node, level) -> void:
	""" OBLIGATOIRE lors de l'instantiation d'un skill
	Appeler lorsqu'on add le skill, cela permet de gérer ce que fait le skill:
		- les connexions à appeler
		- l'ajout des stats brut
		
		A SURCHARGER """
		
	tree = _caster.get_tree()   # on récupère la référence de l'arbre
	self.ps_level = level
	Player.s_brain_clicked.connect(_on_s_brain_clicked)
	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill
	
	A SURCHARGER """
	Player.s_brain_clicked.disconnect(_on_s_brain_clicked)
	pass
	
	
func _on_s_brain_clicked(brain_xp, knowledge):
	for loop in range(0, repeat_click[ps_level - 1]):
		var knowledge_point_to_gain = StatsManager.current_stat_calcul(\
		StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.KNOWLEDGE)
		var brain_xp_to_gain = StatsManager.current_stat_calcul(\
		StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.BRAIN_XP)
		Player.earn_knowledge_point(knowledge_point_to_gain)
		Player.earn_brain_xp(brain_xp_to_gain)
