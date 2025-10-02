extends PassiveSkill


func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	NovaNetManager.time_ia_click = data_bonus_1[ps_level - 1]

	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill"""
	super.detach(_caster)
	NovaNetManager.time_ia_click = -1
