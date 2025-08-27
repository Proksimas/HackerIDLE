extends Node

## Le TutorialManager est un singleton.
## Ajoutez-le à l'AutoLoad pour y accéder facilement depuis n'importe quel script.



@onready var resource_preloader: ResourcePreloader = %ResourcePreloader

const TUTORIAL_UI = preload("res://Game/Interface/Tutorial/tutorial_ui.tscn")

var tutorial_steps: Array[TutorialStep] = []
var current_step_index: int = 0
var game_paused_by_tutorial: bool = false

var tutorial_finished: bool = false
var current_tutorial_ui: TutorialUI

signal tutorial_completed

func _ready():
	set_process_input(false)
	var tutorial_steps_name = resource_preloader.get_resource_list()
	for tutorial_name in tutorial_steps_name:
		tutorial_steps.append(resource_preloader.get_resource(tutorial_name))
		
	

func start_tutorial():
	if tutorial_steps.is_empty():
		print("Aucune étape de tutoriel n'est définie.")
		return

	
	current_step_index = 0
	show_current_step()

func show_current_step():
	if current_step_index > 0:
		disconnect_step_signals(tutorial_steps[current_step_index - 1])
	
	if current_step_index >= tutorial_steps.size():
		# Toutes les étapes sont terminées
		complete_tutorial()
		return

	var current_step = tutorial_steps[current_step_index]


	var new_ui =  TUTORIAL_UI.instantiate()
	self.add_child(new_ui)
	new_ui.set_tutorial_ui(current_step.text_translation_key, current_step.pos)
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
					if !Player.s_earn_knowledge_point.is_connected(self._on_point_receive):
						Player.s_earn_knowledge_point.connect(self._on_point_receive)
				"gold":
					if !Player.s_earn_gold.is_connected(self._on_point_receive):
						Player.s_earn_gold.connect(self._on_point_receive)
				"brain_level":
					if !Player.s_earn_brain_level.is_connected(self._on_point_receive):
						Player.s_earn_brain_level.connect(self._on_point_receive)
						
						
					
		TutorialStep.ValidationType.SIGNAL:
			var target_node = get_node_or_null(step.target_node_path)
			if is_instance_valid(target_node) and not target_node.is_connected(step.target_signal_name, Callable(self, "go_to_next_step")):
				target_node.connect(step.target_signal_name, Callable(self, "go_to_next_step"))
		TutorialStep.ValidationType.CUSTOM_CHECK:
			# Ici, la validation sera manuelle. Par exemple, une fonction _process()
			# peut sonder la condition ou un autre script peut appeler go_to_next_step()
			pass

func _on_point_receive(point_receive):
	var current_step = tutorial_steps[current_step_index]
	print("on reçoit: %s %s" % [point_receive, current_step.score_variable_name])
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
			var target_node = get_node_or_null(step.target_node_path)
			if is_instance_valid(target_node) and target_node.is_connected(step.target_signal_name, Callable(self, "go_to_next_step")):
				target_node.disconnect(step.target_signal_name, Callable(self, "go_to_next_step"))
				
				

func _input(event: InputEvent):
	"""Gere le cas où on a cliqué sur l'écran pour passer"""
	var current_step = tutorial_steps[current_step_index]
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if current_step.validation_type == TutorialStep.ValidationType.INPUT:
			go_to_next_step()

func go_to_next_step():
	current_tutorial_ui.call_deferred("tutorial_step_finished")
	print("Étape ", current_step_index, " terminée.")
	current_step_index += 1
	show_current_step()

func complete_tutorial():
	#tutorial_ui.hide_step()
	if game_paused_by_tutorial:
		get_tree().paused = false
	emit_signal("tutorial_completed")
	print("Tutoriel terminé !")

func call_function_on_node(function_name: String, target_path: NodePath):
	var target_node = get_node_or_null(target_path)
	if is_instance_valid(target_node) and target_node.has_method(function_name):
		target_node.call(function_name)
	else:
		push_error("Erreur: Impossible d'appeler la fonction '", function_name, "' sur le nœud '", target_path, "'.")
