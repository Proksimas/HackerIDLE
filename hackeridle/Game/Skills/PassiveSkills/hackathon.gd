extends PassiveSkill

var timer_id
func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	
	timer_id = self.ps_name + "_" + str(Time.get_ticks_msec())
	SkillsManager.timer_completed.connect(_on_timer_completed)
	SkillsManager.create_timer(timer_id, data_bonus_1[ps_level - 1], false)
	#StatsManager.bonus_from_clicking["max"] = data_bonus_1[ps_level - 1]

	
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill"""
	super.detach(_caster)
	if SkillsManager.timer_completed.is_connected(_on_timer_completed):
		SkillsManager.timer_completed.disconnect(_on_timer_completed)
	
	SkillsManager.cancel_timer(timer_id)

func _on_timer_completed(id_cible: String):
	# Vérifier si c'est bien NOTRE timer qui a expiré
	if id_cible == timer_id:
		#Gain du hack aléatoire
		var dict_hacks:Dictionary = Player.hacking_item_bought.duplicate()
		if dict_hacks.is_empty():
			return
			
		var lst_hacks = dict_hacks.keys()
		lst_hacks.shuffle()
		var hack = lst_hacks[0]
		Player.hacking_item_level_up(hack, 1)

		
