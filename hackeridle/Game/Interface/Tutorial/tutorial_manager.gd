extends Node

@onready var resource_preloader: ResourcePreloader = %ResourcePreloader
@onready var delay_input: Timer = %DelayInput


const TUTORIAL_UI = preload("res://Game/Interface/Tutorial/tutorial_ui.tscn")

var tutorial_steps: Array[TutorialStep] = []
var current_step_index: int = 0
var game_paused_by_tutorial: bool = false

var tutorial_finished: bool = false
var current_tutorial_ui: TutorialUI
var input_paused: bool = false

signal tutorial_completed

func _ready():
	set_process_input(false)
	var tutorial_steps_name = resource_preloader.get_resource_list()
	for tutorial_name in tutorial_steps_name:
		var res:TutorialStep = resource_preloader.get_resource(tutorial_name)
		res.text_translation_key =  tutorial_name 
		tutorial_steps.append(res)
		
	

func start_tutorial():
	if tutorial_steps.is_empty():
		print("Aucune étape de tutoriel n'est définie.")
		return 
	
	current_step_index = 0
	show_current_step()

func show_current_step():

	if current_step_index >= tutorial_steps.size():
		# Toutes les étapes sont terminées
		complete_tutorial()
		return

	var current_step = tutorial_steps[current_step_index]
	print(current_step.text_translation_key)
	
	
	var new_ui =  TUTORIAL_UI.instantiate()
	self.add_child(new_ui)
	new_ui.set_tutorial_ui(current_step.text_translation_key, current_step.pos, current_step.get_show_arrows())
	current_tutorial_ui = new_ui
	# Reste à connecter le signal de finished

	# --- Étape 3 : Gérer la pause du jeu ---
	if current_step.pause_game:
		get_tree().paused = true
		game_paused_by_tutorial = true
	else:
		get_tree().paused = false
		game_paused_by_tutorial = false

	
	connect_step_signals(current_step)


func connect_step_signals(step: TutorialStep):
	match step.validation_type:
		TutorialStep.ValidationType.INPUT: #input = next_step
			set_process_input(true)
		TutorialStep.ValidationType.SCORE:
			# Assurez-vous d'avoir un nœud qui émet un signal de mise à jour du score
			match step.score_variable_name:
				"knowledge":
					if Player.knowledge_point >= step.required_score_value:
						go_to_next_step()
						
					elif !Player.s_earn_knowledge_point.is_connected(self._on_point_receive):
						Player.s_earn_knowledge_point.connect(self._on_point_receive)
						
				"gold":
					if Player.gold >= step.required_score_value:
						go_to_next_step()
					elif !Player.s_earn_gold.is_connected(self._on_point_receive):
						Player.s_earn_gold.connect(self._on_point_receive)
						
				"brain_level":
					if Player.brain_level >= step.required_score_value:
						go_to_next_step()
					elif !Player.s_earn_brain_level.is_connected(self._on_point_receive):
						Player.s_earn_brain_level.connect(self._on_point_receive)
						
		TutorialStep.ValidationType.SIGNAL:
			var target_node = get_tree().get_root().get_node_or_null(step.target_node_path)
			if is_instance_valid(target_node):
				if !target_node.is_connected(step.target_signal_name, go_to_next_step):
					print("connexion de %s" % step.target_node_path)
					target_node.connect(step.target_signal_name, go_to_next_step)
				else:
					push_error("Probleme de connexion")
			else:
				push_error("Le target_node n'est pas valide. Vérifier le chemin absolu")
				
		TutorialStep.ValidationType.GROUP:
			#On connecte le signal des membres du groupe, et on attend de voir leur émission
			var node = get_tree().get_nodes_in_group(step.group_call_name)[0]

			if !node.is_connected(step.group_call_signal, go_to_next_step):
				node.connect(step.group_call_signal, go_to_next_step)
					
		TutorialStep.ValidationType.CUSTOM_CHECK:
			# Ici, la validation sera manuelle. Par exemple, une fonction _process()
			# peut sonder la condition ou un autre script peut appeler go_to_next_step()
			pass

func _on_point_receive(point_receive):
	var current_step = tutorial_steps[current_step_index]
	#print("on reçoit: %s %s" % [point_receive, current_step.score_variable_name])
	if point_receive >= current_step.required_score_value:
		go_to_next_step()


func disconnect_step_signals(step: TutorialStep):
	match step.validation_type:
		TutorialStep.ValidationType.INPUT:
			set_process_input(false)
		TutorialStep.ValidationType.SCORE:
			match step.score_variable_name:
				"knowledge":
					if Player.s_earn_knowledge_point.is_connected(self._on_point_receive):
						Player.s_earn_knowledge_point.disconnect(self._on_point_receive)
				"gold":
					if Player.s_earn_gold.is_connected(self._on_point_receive):
						Player.s_earn_gold.disconnect(self._on_point_receive)
						
				"brain_level":
					if Player.s_earn_brain_level.is_connected(self._on_point_receive):
						Player.s_earn_brain_level.disconnect(self._on_point_receive)


		TutorialStep.ValidationType.SIGNAL:
			var target_node = get_tree().get_root().get_node_or_null(step.target_node_path)
			if is_instance_valid(target_node):
				if target_node.is_connected(step.target_signal_name, go_to_next_step):
					target_node.disconnect(step.target_signal_name, go_to_next_step)
					
		TutorialStep.ValidationType.GROUP:
			#On connecte le signal des membres du groupe, et on attend de voir leur émission
			var node = get_tree().get_nodes_in_group(step.group_call_name)[0]

			if node.is_connected(step.group_call_signal, go_to_next_step):
				node.disconnect(step.group_call_signal, go_to_next_step)

func _input(event: InputEvent):
	"""Gere le cas où on a cliqué sur l'écran pour passer"""
	if input_paused: #on se permet de mettre un delay entre les inputs
		return
	var current_step = tutorial_steps[current_step_index]
	
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if current_step.validation_type == TutorialStep.ValidationType.INPUT:
			go_to_next_step()

func go_to_next_step():
	if current_step_index > 0:
		disconnect_step_signals(tutorial_steps[current_step_index])
		
	current_tutorial_ui.call_deferred("tutorial_step_finished")
	print("Étape ", current_step_index + 1, " terminée.")
	current_step_index += 1
	input_paused = true
	delay_input.start()
	show_current_step()

func complete_tutorial():
	#tutorial_ui.hide_step()
	if game_paused_by_tutorial:
		get_tree().paused = false
	tutorial_completed.emit()
	tutorial_finished = true
	print("Tutoriel terminé !")
	
func reset_tutorial():
	if current_tutorial_ui != null:
		current_tutorial_ui.hide()
		current_tutorial_ui.call_deferred("queue_free")
	current_step_index = 0



func _on_delay_input_timeout() -> void:
	input_paused = false
	pass # Replace with function body.
