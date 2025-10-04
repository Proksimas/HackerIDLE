extends PassiveSkill

func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	var number = 0 - data_bonus_1[ps_level - 1]
	EventsManager.wait_time_modificators[self.ps_name] = number

	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill"""
	super.detach(_caster)
	
	EventsManager.wait_time_modificators.erase(self.ps_name)
