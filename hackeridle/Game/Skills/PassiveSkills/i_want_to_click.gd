extends PassiveSkill


func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	StatsManager.bonus_from_clicking["max"] = data_bonus_1[ps_level - 1]

	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill"""
	super.detach(_caster)
	StatsManager.bonus_from_clicking["max"] = StatsManager.max_base_clicking
