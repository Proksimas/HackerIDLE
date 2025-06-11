extends ActiveSkill


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func launch_as():
	"""A surcharger"""
	as_is_active = true
	Player.s_brain_clicked.connect(_on_s_brain_clicked)
	var timer:SceneTreeTimer = tree.create_timer(self.as_during_time)
	
	timer.timeout.connect(as_finished)
	
	pass
	
	
func _on_s_brain_clicked(brain_xp, knowledge):
	"""le cerveau a été cliqué, on fait donc les bonus associés"""
	as_is_active = false
	
	pass
	
	
func as_finished():
	"""A surcharger"""
	Player.s_brain_clicked.disconnect(_on_s_brain_clicked)
	as_is_active = false
	pass
