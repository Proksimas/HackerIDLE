extends PassiveSkill


func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	Player.s_brain_clicked.connect(_on_s_brain_clicked)
	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill
	
	A SURCHARGER """
	super.detach(_caster)
	Player.s_brain_clicked.disconnect(_on_s_brain_clicked)
	pass
	
	
func _on_s_brain_clicked(_brain_xp, _knowledge):
	for loop in range(0, data_bonus_1[ps_level - 1]):
		var knowledge_point_to_gain = StatsManager.current_stat_calcul(\
		StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.KNOWLEDGE)
		var brain_xp_to_gain = StatsManager.current_stat_calcul(\
		StatsManager.TargetModifier.BRAIN_CLICK, StatsManager.Stats.BRAIN_XP)
		Player.earn_knowledge_point(knowledge_point_to_gain)
		Player.earn_brain_xp(brain_xp_to_gain)
