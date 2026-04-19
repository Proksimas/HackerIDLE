extends Control

class_name StackComponent

@onready var stack_name_label: Label = %StackNameLabel
@onready var texture_progress_bar: TextureProgressBar = %TextureProgressBar
@onready var turns_remaining_label: Label = %TurnsRemainingLabel

signal s_stack_component_completed

@export var temps_completion: float = 3.0
var tween: Tween

func set_component(component_name: String = "default_name") -> void:
	stack_name_label.text = component_name
	texture_progress_bar.value = 0
	texture_progress_bar.max_value = 100
	set_turns_remaining(0)


func reset_component() -> void:
	if tween != null and tween.is_valid():
		tween.kill()
	texture_progress_bar.value = 0
	set_turns_remaining(0)
	hide()


func set_turns_remaining(turns_remaining: int) -> void:
	if turns_remaining > 0:
		turns_remaining_label.text = "%s" % turns_remaining
		turns_remaining_label.show()
	else:
		turns_remaining_label.hide()


func start_component() -> void:
	# 1) Sécurité : vérifier que le noeud est bien dans l'arbre
	if !is_inside_tree():
		push_error("StackComponent n'est pas encore dans l'arbre de scène.")
		return
	# 2) Sécurité : vérifier que la barre existe bien
	if texture_progress_bar == null:
		push_error("texture_progress_bar est NULL (mauvais nom %TextureProgressBar ?)")
		return

	# 3) Reset de la valeur
	if tween != null and tween.is_valid():
		tween.kill()
	texture_progress_bar.value = 0
	tween = create_tween()
	tween.tween_property(
		texture_progress_bar,
		"value",
		texture_progress_bar.max_value, # 100
		temps_completion                # 3s
	)

	tween.finished.connect(_on_tween_finished)

func _on_tween_finished() -> void:
	s_stack_component_completed.emit()
