@tool
extends Sprite2D

#@export var shader_material : ShaderMaterial  # Référence au ShaderMaterial
var time : float = 0.0
@export var shader_material : ShaderMaterial  # Référence au ShaderMaterial

func _ready():
	shader_material = material
	var screen_center = get_viewport().size / 2
	print(screen_center)
	if shader_material:
		pass
	

#func _input(event):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		## Lors du clic gauche, on capture la position du clic
		#var click_position = event.position
		#print(click_position)
		#_trigger_particles(click_position)  # Déclencher l'animation des particules
#
#func _trigger_particles(position: Vector2):
	## Met à jour la position du clic dans le shader
	#shader_material.set_shader_parameter("center", position)
	#shader_material.set_shader_parameter("time", time)
	#
	## Réinitialise le temps pour les animations
	#time = 0

func _process(delta: float) -> void:
	pass
