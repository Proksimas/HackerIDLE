extends Control
@onready var skill_button: TextureButton = %SkillButton

@export var skill_name: String

signal skill_button_pressed(skill_name:String)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_skill_button_pressed() -> void:
	skill_button_pressed.emit(skill_name)
	pass # Replace with function body.
