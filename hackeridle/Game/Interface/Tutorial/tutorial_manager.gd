extends Node

## Le TutorialManager est un singleton.
## Ajoutez-le à l'AutoLoad pour y accéder facilement depuis n'importe quel script.



@onready var resource_preloader: ResourcePreloader = %ResourcePreloader

const TUTORIAL_UI = preload("res://Game/Interface/Tutorial/tutorial_ui.tscn")

var tutorial_steps: Array[TutorialStep] = []
var current_step_index: int = 0
var game_paused_by_tutorial: bool = false

var tutorial_finished: bool = false


signal tutorial_completed

func _ready():
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
	if current_step_index >= tutorial_steps.size():
		# Toutes les étapes sont terminées
		complete_tutorial()
		return

	var current_step = tutorial_steps[current_step_index]

	## --- Étape 1 : Gérer la logique de l'étape précédente ---
	#if current_step_index > 0:
		#var previous_step = tutorial_steps[current_step_index - 1]
		#disconnect_step_signals(previous_step)
		#
		## Appelle la fonction de fin d'étape si elle est définie
		#if not previous_step.on_step_end_function.is_empty():
			#call_function_on_node(previous_step.on_step_end_function, previous_step.custom_check_target)
			#
			


	var new_ui =  TUTORIAL_UI.instantiate()
	self.add_child(new_ui)
	new_ui.set_tutorial_ui(current_step.text_translation_key, current_step.pos)
	# Reste à connecter le signal de finished

	# --- Étape 3 : Gérer la pause du jeu ---
	if current_step.pause_game:
		get_tree().paused = true
		game_paused_by_tutorial = true
	else:
		get_tree().paused = false
		game_paused_by_tutorial = false


	return
	# --- Étape 4 : Écouter les événements de validation ---
	connect_step_signals(current_step)

	# --- Étape 5 : Appeler la fonction de début d'étape si elle est définie ---
	if not current_step.on_step_start_function.is_empty():
		call_function_on_node(current_step.on_step_start_function, current_step.custom_check_target)

func connect_step_signals(step: TutorialStep):
	match step.validation_type:
		TutorialStep.ValidationType.INPUT:
			set_process_input(true)
		TutorialStep.ValidationType.SCORE:
			# Assurez-vous d'avoir un nœud qui émet un signal de mise à jour du score
			var score_manager = get_node_or_null("/root/ScoreManager")
			if is_instance_valid(score_manager):
				score_manager.connect("score_updated", Callable(self, "_on_score_updated"))
		TutorialStep.ValidationType.SIGNAL:
			var target_node = get_node_or_null(step.target_node_path)
			if is_instance_valid(target_node) and not target_node.is_connected(step.target_signal_name, Callable(self, "go_to_next_step")):
				target_node.connect(step.target_signal_name, Callable(self, "go_to_next_step"))
		TutorialStep.ValidationType.CUSTOM_CHECK:
			# Ici, la validation sera manuelle. Par exemple, une fonction _process()
			# peut sonder la condition ou un autre script peut appeler go_to_next_step()
			pass

func disconnect_step_signals(step: TutorialStep):
	match step.validation_type:
		TutorialStep.ValidationType.INPUT:
			set_process_input(false)
		TutorialStep.ValidationType.SCORE:
			var score_manager = get_node_or_null("/root/ScoreManager")
			if is_instance_valid(score_manager) and score_manager.is_connected("score_updated", Callable(self, "_on_score_updated")):
				score_manager.disconnect("score_updated", Callable(self, "_on_score_updated"))
		TutorialStep.ValidationType.SIGNAL:
			var target_node = get_node_or_null(step.target_node_path)
			if is_instance_valid(target_node) and target_node.is_connected(step.target_signal_name, Callable(self, "go_to_next_step")):
				target_node.disconnect(step.target_signal_name, Callable(self, "go_to_next_step"))
				
				

func _input(event: InputEvent):
	var current_step = tutorial_steps[current_step_index]
	if current_step.validation_type == TutorialStep.ValidationType.INPUT and event.is_action_pressed(current_step.input_action):
		go_to_next_step()

func _on_score_updated(variable_name: String, value: int):
	var current_step = tutorial_steps[current_step_index]
	if current_step.validation_type == TutorialStep.ValidationType.SCORE and current_step.score_variable_name == variable_name and value >= current_step.required_score_value:
		go_to_next_step()

func go_to_next_step():
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
