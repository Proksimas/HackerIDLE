extends PassiveSkill

func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	EventsManager.wait_time_modificators.append(data_bonus_1[ps_level - 1])

	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill"""
	super.detach(_caster)
	var value = data_bonus_1[ps_level - 1]
	var len_array = len(EventsManager.wait_time_modificators)
	EventsManager.wait_time_modificators.erase(value)
	if len_array == len(EventsManager.wait_time_modificators):
		push_error("La suppression de l'élement n'a pas fonctionné")
	pass
