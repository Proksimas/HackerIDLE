@tool
extends Sprite2D

#@export var shader_material : ShaderMaterial  # Référence au ShaderMaterial
var time : float = 0.0
@export var shader_material : ShaderMaterial  # Référence au ShaderMaterial

func _ready():
	shader_material = material
	var screen_center = get_viewport().size / 2
	if shader_material:
		pass


func _process(delta: float) -> void:
	pass
