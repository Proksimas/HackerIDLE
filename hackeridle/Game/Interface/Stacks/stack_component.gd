extends Control

class_name StackComponent

@onready var stack_name_label: Label = %StackNameLabel
@onready var texture_progress_bar: TextureProgressBar = %TextureProgressBar

signal s_stack_component_completed()
var temps_completion = 3
var component_starting: bool = false

func _ready() -> void:
	component_starting = false
		
func _process(delta: float) -> void:
	print(component_starting)
	if component_starting:
		texture_progress_bar.value += delta
		if texture_progress_bar.value >= texture_progress_bar.max_value:
			s_stack_component_completed.emit()
			component_starting = false
	
	
func set_component(component_name: String = "default_name"):
	"""Le max_value correspon au nombre de seconde avant d'atteindre cette valeur"""
	stack_name_label.text = component_name
	texture_progress_bar.value = 0 
	#l mx_value peut correspondre au temps d'incantation du component
	texture_progress_bar.max_value = 3


func start_component():
	print("On lance le component")
	texture_progress_bar.value = 0
	component_starting = true
	#timer.start()
	#var tween = get_tree().create_tween()
	#tween.tween_property(texture_progress_bar, "value", 3, temps_completion)
	#tween.finished.connect(_on_tween_finished)
	#tween.play()
	#print("tween played")
	#pass

#func _on_tween_finished():
	#print("tween finished")
	#s_stack_component_completed.emit()
