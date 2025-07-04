extends Control

func spawn_falling_particles(texture: Texture2D, position: Vector2, area_width: float = 300.0, particle_count: int = 100) -> void:
	var particles := CPUParticles2D.new()
	particles.texture = texture
	particles.amount = particle_count
	particles.lifetime = 5.0
	particles.one_shot = false
	particles.emitting = true
	particles.pre_process_time = 1.0
	particles.position = position

	# Matériau de particules (Godot 4.x)
	var material := ParticleProcessMaterial.new()

	# Gravité vers le bas
	material.gravity = Vector3(0, 100, 0)  # Godot 4 utilise Vector3 même en 2D

	# Vitesse initiale
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0

	# Emission dans une bande horizontale
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(area_width / 2.0, 0, 0)  # largeur du rectangle

	# Rotation aléatoire
	material.angle_min = -20.0
	material.angle_max = 20.0
	material.angular_velocity_min = -30.0
	material.angular_velocity_max = 30.0

	# Échelle des particules
	material.scale_min = 0.8
	material.scale_max = 1.2

	# Appliquer le matériau
	particles.process_material = material

	# Ajouter à la scène
	add_child(particles)
