extends Control

@onready var stack_sequence_hacker: Control = get_node_or_null("StackSequenceHacker")

func _ready() -> void:
	refresh_hacker_scripts()

func refresh_hacker_scripts() -> void:
	if Player.nb_of_rebirth <= 0:
		return
	if stack_sequence_hacker == null:
		return
	if not stack_sequence_hacker.has_method("load_hacker"):
		return
	var hacker := StackManager.create_hacker_entity()
	stack_sequence_hacker.call("load_hacker", hacker)
