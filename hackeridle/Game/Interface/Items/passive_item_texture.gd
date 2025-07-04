extends AspectRatioContainer
@onready var item_texture: TextureRect = %ItemTexture
var is_rotating = false
var rotation_direction = 1  # +1 pour droite, -1 pour gauche
var rotation_duration = 0.0
var rotation_timer = 0.0
var rotation_speed = 0.0  # radians par seconde

var time_to_move:int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1 chance sur 2 de commencer à tourner
	if randi() % 2 == 0:
		is_rotating = true
	# Choix aléatoire entre -1 (gauche) et +1 (droite)
		if randi() % 2 == 0:
			rotation_direction = 1
		else:
			rotation_direction = -1
	
	# Durée aléatoire entre 20 et 40 secondes
		rotation_duration = randf_range(20.0, 40.0)
	
	# Vitesse de rotation : ici 10 degrés/sec convertis en radians
		rotation_speed = deg_to_rad(10) * rotation_direction
	
		rotation_timer = 0.0
		set_process(true)
	else:
		set_process(false)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_rotating:
		rotation_timer += delta
		if rotation_timer >= rotation_duration:
			is_rotating = false
			set_process(false)
		else:
			rotation += rotation_speed * delta
	pass

func item_moving(_pos: Vector2, _size: Vector2) -> void:
	# Position X aléatoire dans la zone définie par _pos et _size
	var min_x = _pos.x
	var max_x = _size.x -15 # Prendre en compte la largeur de l'objet
	var random_x = randi_range(min_x, max_x)
	print("self_position: %s" % self.position)
	print("self_global_position: %s" % self.global_position)
	var start_y = _pos.y

	self.global_position = Vector2(random_x, start_y)

	# Rotation aléatoire
	self.rotation_degrees = randf_range(-40.0, 40.0)

	# Durée aléatoire pour la chute
	var time_to_move = randf_range(12.0, 20.0)

	# Position finale Y = en bas de la zone définie par _pos et _size
	# Ici, nous voulons que le bas de l'objet atteigne _pos.y + _size.y
	var end_y = _pos.y + _size.y # Ajuster pour que le bas de l'objet soit à la limite inférieure
	var end_pos = Vector2(random_x, end_y)

	# Tween propre
	var tween: Tween = get_tree().create_tween()
	tween.finished.connect(_on_tween_finished)
	tween.tween_property(self, "global_position", end_pos, time_to_move).from(self.global_position)
	
	
func _on_tween_finished():
	self.queue_free()
