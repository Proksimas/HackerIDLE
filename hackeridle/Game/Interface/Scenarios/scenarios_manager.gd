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
	if !OS.has_feature("editor"):
		_on_introduction_tween_finished(introduction)



# FIN DE SESSION. ON PREPARE LE REBIRTH
func _on_s_session_finished():
	"""On lance le texte de conclusion"""
	return
	print("SESSION TERMINÉE")
	#var conclusion = SCENARIO.instantiate()
	#conclusion.count = 32 #nombre de phrases dans l'introduction
	#var stylebox = StyleBoxTexture.new()
	#stylebox.texture = BLOOD_AND_FIRE
	#stylebox.modulate_color = "000000"
	#conclusion.add_theme_stylebox_override("panel", stylebox)
	#
	#conclusion.key_prefix = "conclusion_"
	#self.add_child(conclusion)
	#conclusion.s_scenario_finished.connect(_on_s_conclusion_finished.bind(conclusion))
	#conclusion.s_current_index.connect(_on_s_current_index.bind(stylebox))
	#
	#get_tree().get_root().get_node("Main/Interface").hide()
	#conclusion.launch()
	##TODO STOP LE RESTE DU CODE
	
func _on_s_current_index(index, stylebox):
	
	print(index)
	if index == 12:
		var new_tween:Tween = get_tree().create_tween()
		new_tween.tween_property(stylebox, "modulate_color", Color(1, 1, 1), 8)
		new_tween.finished.connect(self._on_tween_finished)
		new_tween.play()
		
func _on_s_conclusion_finished(conclusion_node):
	"""on initialize le rebirth"""
	print("On entamme le rebirth")
	
	
func _on_tween_finished():
	print("tween_finished")
