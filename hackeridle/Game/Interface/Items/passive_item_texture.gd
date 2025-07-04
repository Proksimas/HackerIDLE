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
	item_moving()
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


func item_moving():
	#on choisit aléatoirement la position
	var screen_size = DisplayServer.window_get_size()
	var random_x = randi_range(15, screen_size.x - 15)
	self.global_position = Vector2(random_x, 0)
	var random_rot = randi_range(-40,40)
	self.set_rotation_degrees(random_rot)
	
	time_to_move = randi_range(12,20)

	var tween:Tween = get_tree().create_tween()
	tween.finished.connect(_on_tween_finished)
	tween.tween_property(self, "global_position", 
						Vector2(random_x,screen_size.y), time_to_move).from(self.global_position)
	
	
	
func _on_tween_finished():
	self.queue_free()
