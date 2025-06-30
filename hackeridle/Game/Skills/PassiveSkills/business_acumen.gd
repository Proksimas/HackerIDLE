extends PassiveSkill

var conversion = [0.1, 0.2, 0.3, 0.4, 0.5]


func attach(_caster: Node, level) -> void:
	super.attach(_caster, level)
	Player.s_knowledge_to_earn.connect(_on_s_earn_knowledge_point_to_learn)
	#StatsManager.add_modifier(StatsManager.TargetModifier.GLOBAL, 
					#StatsManager.Stats.GOLD, 
					#StatsManager.ModifierType.PERCENTAGE, 
					#conversion[ps_level - 1], self.ps_name)
	#
func detach(_caster: Node)-> void:
	"""dettache les ajouts que donne le sill
	
	A SURCHARGER """
	super.detach(_caster)
	Player.s_knowledge_to_earn.disconnect(_on_s_earn_knowledge_point_to_learn)
	#var dict_to_remove = StatsManager.get_modifier_by_source_name(StatsManager.TargetModifier.GLOBAL, 
					#StatsManager.Stats.GOLD, self.ps_name)
	#if !dict_to_remove.is_empty():
		#StatsManager.remove_modifier(StatsManager.TargetModifier.GLOBAL, 
					#StatsManager.Stats.GOLD, dict_to_remove)
	#pass

func _on_s_earn_knowledge_point_to_learn(knowledge_point_to_learn):
	"""on fait le calcul qu'on va mettre dan s la gold flat"""
	var calcul = knowledge_point_to_learn * conversion[ps_level - 1]
	print(calcul)
	Player.gold += calcul
	if tree.get_root().has_node("Main/Interface"):
		tree.get_root().get_node("Main/Interface").refresh_specially_resources()
	else:
		push_error("L'interface n'est pas trouvée!")

		
	pass
