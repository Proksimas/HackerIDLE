extends PassiveSkill

var timer_id
func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	
	timer_id = self.ps_name + "_" + str(Time.get_ticks_msec())
	SkillsManager.timer_completed.connect(_on_timer_completed)
	SkillsManager.create_timer(timer_id, 1, false)
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
		var gold_to_earn = Player.gold * data_bonus_1[ps_level - 1] / 100
		Player.earn_gold(gold_to_earn)
		
