extends Panel

@onready var nb_of_rebirth_title: Label = %NbOfRebirthTitle
@onready var nb_of_rebirth_spin_box: SpinBox = %NbOfRebirthSpinBox
@onready var cheat_event_spin_box: SpinBox = %CheatEventSpinBox
@onready var brain_value: Label = %BrainValue
@onready var goldn_value: Label = %GoldnValue
@onready var sp_value: Label = %SPValue
@onready var exploit_value: Label = %ExploitValue


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventsManager.s_event_created.connect(self._on_s_event_created)
	
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
	"""ON AFFICHE LES VALEURS DU JEU ATM"""
	var interface = Global.get_interface()
	nb_of_rebirth_spin_box.value = Player.nb_of_rebirth
	brain_value.text = Global.number_to_string(Player.knowledge_point)
	goldn_value.text =  Global.number_to_string(Player.gold)
	sp_value.text = Global.number_to_string(Player.skill_point)
	exploit_value.text = Global.number_to_string(Player.exploit_point)
	
	
	if Player.nb_of_rebirth >= 1:
		interface.nova_net_box.get_parent().show()
	else: interface. nova_net_box.get_parent().hide()
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
	cheat_event_spin_box.apply()
	EventsManager.create_event_and_ui(int(cheat_event_spin_box.value))

	pass # Replace with function body.

var cache_gain: int = 0
func _on_gain_spin_box_value_changed(value: float) -> void:
	cache_gain = value
	get_tree().call_group("g_gain_value", "set_gain_button", value)
	pass # Replace with function body.


func _on_plus_brain_button_pressed() -> void:
	Player.earn_knowledge_point(cache_gain)
func _on_moins_brain_button_pressed() -> void:
	Player.earn_knowledge_point(0-cache_gain)
func _on_plus_gold_button_pressed() -> void:
	Player.earn_gold(cache_gain)
func _on_moins_gold_button_pressed() -> void:
	Player.earn_gold(0-cache_gain)
func _on_plus_sp_button_pressed() -> void:
	Player.skill_point += cache_gain
func _on_moins_sp_button_pressed() -> void:
	Player.skill_point -= cache_gain

func _on_s_event_created():
	self.hide()

func _on_plus_exploit_button_pressed() -> void:
	Player.exploit_point += cache_gain
func _on_moins_exploit_button_pressed() -> void:
	Player.exploit_point -= cache_gain
