extends Panel

@onready var nb_of_rebirth_title: Label = %NbOfRebirthTitle
@onready var nb_of_rebirth_spin_box: SpinBox = %NbOfRebirthSpinBox
@onready var cheat_event_spin_box: SpinBox = %CheatEventSpinBox


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !self.visible:
		$Timer.paused = true
	else:
		$Timer.paused = false
	pass



func _on_nb_of_rebirth_spin_box_value_changed(value: float) -> void:
	Player.nb_of_rebirth = value
	pass # Replace with function body.


func _on_draw() -> void:
	print("cheat_on_draw")
	nb_of_rebirth_spin_box.value = Player.nb_of_rebirth
	pass # Replace with function body.


func _on_timer_timeout() -> void:
	_on_draw()
	pass # Replace with function body.


func _on_finish_button_pressed() -> void:
	TimeManager.game_seconds += 70 * TimeManager.DAYS_PER_YEAR * TimeManager.SECONDS_PER_DAY


func _on_jail_button_pressed() -> void:
	self.hide()
	StatsManager.s_go_to_jail.emit()
	pass # Replace with function body.


func _on_cheat_event_button_pressed() -> void:
	self.hide()
	cheat_event_spin_box.apply()
	EventsManager.create_event_and_ui(int(cheat_event_spin_box.value))

	pass # Replace with function body.
