extends Node

const SCENARIO = preload("res://Game/Interface/Scenarios/Scenario.tscn")
const BLOOD_AND_FIRE = preload("res://Game/Graphics/Background/FullCity/blood_and_fire.png")


func _ready() -> void:
	TimeManager.s_session_finished.connect(_on_s_session_finished)

func launch_introduction(interface):
	var introduction = SCENARIO.instantiate()
	introduction.name = "introduction"
	introduction.count = 12 #nombre de phrases dans l'introduction
	introduction.key_prefix = "introduction_"
	self.add_child(introduction)
	#en cas de skip
	introduction.s_force_skip.connect(_on_s_skip_introduction_.bind(introduction, interface))
	
	 #c'est le tween finished qui lance le reste
	introduction.s_last_before_finished.connect(_on_s_last_before_finished.bind(interface, introduction))
	
	introduction.launch()
	


func _on_s_last_before_finished(interface, introduction):
	"""Utilisé pour le jeu pdt l'intro"""
	#if Player.nb_of_rebirth == 0:
	interface.inits_shops()
	var new_tween:Tween = get_tree().create_tween()
	var style_box = introduction.get_theme_stylebox("panel")
	new_tween.tween_property(style_box, "modulate_color", Color(1, 1, 1), 8)
	new_tween.finished.connect(self._on_introduction_tween_finished.bind(introduction))
	new_tween.play()

	
func _on_introduction_tween_finished(introduction_node):
	introduction_node.hide()
	get_tree().get_root().get_node("Main/Interface").show()
	TimeManager.adjust_session_minutes()
	TimeManager.reset()
	introduction_node.queue_free()


func _on_s_skip_introduction_(introduction, interface):
	interface.inits_shops()
	introduction.s_force_skip.disconnect(_on_s_skip_introduction_)
	_on_introduction_tween_finished(introduction)
	

# FIN DE SESSION. ON PREPARE LE REBIRTH
func _on_s_session_finished():
	"""On lance le texte de conclusion"""
	# TRANSITION BLACK
	var new_color_rect = ColorRect.new()
	self.add_child(new_color_rect)
	new_color_rect.custom_minimum_size = get_viewport().get_visible_rect().size
	new_color_rect.color = Color(0, 0, 0, 0)
	new_color_rect.z_index = 300
	var tween_swap = get_tree().create_tween()
	tween_swap.tween_property(new_color_rect, "color", Color(0, 0, 0, 1), 5)
	tween_swap.play()
	await tween_swap.finished
	await get_tree().create_timer(3).timeout
	new_color_rect.queue_free()
	var interface = get_tree().get_root().get_node("Main/Interface")
	interface.hide()
	interface.queue_free()
	
	
	# ON LANCE LA CONCLUSION
	# arret de tous les process ?
	
	
	var conclusion = SCENARIO.instantiate()
	conclusion.name = "conclusion"
	conclusion.count = 32 #nombre de phrases dans la conclusion
	conclusion.string_formated = {"robot_force_cyber": Global.number_to_string(Player.robots_cyber_force),
									"player_force_cyber": Global.number_to_string(Player.cyber_force)}
	var stylebox = StyleBoxTexture.new()
	stylebox.texture = BLOOD_AND_FIRE
	stylebox.modulate_color = "000000"
	conclusion.add_theme_stylebox_override("panel", stylebox)
	
	conclusion.key_prefix = "conclusion_"
	self.add_child(conclusion)
	conclusion.s_force_skip.connect(_on_skip_conlusion.bind(conclusion, tween_swap))
	conclusion.s_scenario_finished.connect(_on_s_conclusion_finished.bind(conclusion))
	conclusion.s_current_index.connect(_on_s_current_index.bind(stylebox, conclusion))
	
	conclusion.launch()
	
func _on_s_current_index(index, stylebox, conclusion):
	if index == 13: #on envoit le tween
		#on affiche le fond d'écran devasté
		conclusion.scenario_paused = true
		var new_tween:Tween = get_tree().create_tween()
		new_tween.tween_property(stylebox, "modulate_color", Color(1, 1, 1), 8)
		new_tween.play()
		await new_tween.finished
		conclusion.scenario_paused = false
		
func _on_s_conclusion_finished(conclusion_node):
	"""on initialize le rebirth"""
	conclusion_node.s_scenario_finished.disconnect(_on_s_conclusion_finished)
	conclusion_node.text_label.text = ""
	var stylebox = conclusion_node.get_theme_stylebox("panel")
	var new_tween:Tween = get_tree().create_tween()
	new_tween.tween_property(stylebox, "modulate_color", Color(0, 0, 0), 8)
	new_tween.finished.connect(self._on_rebirth_tween_finished.bind(conclusion_node))
	new_tween.play()
	


func _on_rebirth_tween_finished(conclusion_node):
	"""Le rebirth commence vraiment"""
	conclusion_node.queue_free()
	await conclusion_node.tree_exited #on attend bien que le node soit exited
	get_parent().rebirth()
	

func _on_skip_conlusion(conclusion_node, tween_swap):
	conclusion_node.s_force_skip.disconnect(_on_skip_conlusion)
	tween_swap.kill()
	_on_rebirth_tween_finished(conclusion_node)
	
