extends Node

const SCENARIO = preload("res://Game/Interface/Scenarios/Scenario.tscn")
const BLOOD_AND_FIRE = preload("res://Game/Graphics/Background/FullCity/blood_and_fire.png")

func _ready() -> void:
	TimeManager.s_session_finished.connect(_on_s_session_finished)

func launch_introduction(interface):
	var introduction = SCENARIO.instantiate()
	introduction.count = 12 #nombre de phrases dans l'introduction
	introduction.key_prefix = "introduction_"
	self.add_child(introduction)
	#en cas de skip
	introduction.s_scenario_finished.connect(_on_s_introduction_finished.bind(introduction))
	 #c'est le tween finished qui lance le reste
	introduction.s_last_before_finished.connect(_on_s_last_before_finished.bind(interface, introduction))
	introduction.launch()
	


func _on_s_last_before_finished(interface, introduction):
	"""Utilisé pour le jeu pdt l'intro"""
	interface.inits_shops()
	var new_tween:Tween = get_tree().create_tween()
	var style_box = introduction.get_theme_stylebox("panel")
	new_tween.tween_property(style_box, "modulate_color", Color(1, 1, 1), 8)
	new_tween.finished.connect(self._on_introduction_tween_finished.bind(introduction))
	new_tween.play()

	
func _on_introduction_tween_finished(introduction_node):
	introduction_node.hide()
	get_tree().get_root().get_node("Main/Interface").show()
	TimeManager.reset()
	introduction_node.queue_free()

func _on_s_introduction_finished(introduction):
	
	if OS.has_feature("editor"):
		_on_introduction_tween_finished(introduction)



# FIN DE SESSION. ON PREPARE LE REBIRTH
func _on_s_session_finished():
	"""On lance le texte de conclusion"""
	print("SESSION TERMINÉE")
	
	# TRANSITION BLACK
	var new_color_rect = ColorRect.new()
	self.add_child(new_color_rect)
	new_color_rect.custom_minimum_size = get_viewport().get_visible_rect().size
	new_color_rect.color = Color(1, 1, 1)
	new_color_rect.z_index = 300
	var tween_swap = get_tree().create_tween()
	tween_swap.tween_property(new_color_rect, "color", Color(0, 0, 0), 5)
	tween_swap.play()
	await tween_swap.finished
	await get_tree().create_timer(3).timeout
	new_color_rect.queue_free()
	
	# ON LANCE LA CONCLUSION
	var conclusion = SCENARIO.instantiate()
	conclusion.count = 32 #nombre de phrases dans la conclusion
	var stylebox = StyleBoxTexture.new()
	stylebox.texture = BLOOD_AND_FIRE
	stylebox.modulate_color = "000000"
	conclusion.add_theme_stylebox_override("panel", stylebox)
	
	conclusion.key_prefix = "conclusion_"
	self.add_child(conclusion)
	conclusion.s_scenario_finished.connect(_on_s_conclusion_finished.bind(conclusion))
	conclusion.s_current_index.connect(_on_s_current_index.bind(stylebox, conclusion))
	
	get_tree().get_root().get_node("Main/Interface").hide()
	conclusion.launch()
	##TODO STOP LE RESTE DU CODE
	
func _on_s_current_index(index, stylebox, conclusion):
	print(index)
	if index == 11: #on envoit le tween
		conclusion.scenario_paused = true
		var new_tween:Tween = get_tree().create_tween()
		new_tween.tween_property(stylebox, "modulate_color", Color(1, 1, 1), 8)
		new_tween.play()
		await new_tween.finished
		conclusion.scenario_paused = false
		
func _on_s_conclusion_finished(conclusion_node):
	"""on initialize le rebirth"""
	print("On entamme le rebirth")
	conclusion_node.text_label.text = ""
	var stylebox = conclusion_node.get_theme_stylebox("panel")
	var new_tween:Tween = get_tree().create_tween()
	new_tween.tween_property(stylebox, "modulate_color", Color(0, 0, 0), 8)
	new_tween.finished.connect(self._on_rebirth_tween_finished.bind(conclusion_node))
	new_tween.play()

func _on_rebirth_tween_finished(conclusion_node):
	conclusion_node.queue_free()
	return
