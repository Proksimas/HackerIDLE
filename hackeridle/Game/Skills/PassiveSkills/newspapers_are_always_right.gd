extends PassiveSkill

func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	var number = data_bonus_1[ps_level - 1]
	EventsManager.add_infamy_events[self.ps_name] = number

	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill"""
	super.detach(_caster)
	EventsManager.add_infamy_events.erase(self.ps_name)
	
	pass
