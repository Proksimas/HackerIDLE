extends Control

@onready var farming_xp_slider: HSlider = %FarmingXpSlider
@onready var farming_xp_bots_value: Label = %FarmingXpBotsValue
@onready var xp_bots_correspondence_label: Label = %XpBotsCorrespondenceLabel
@onready var farmin_xp_gain_label: Label = %FarminXpGainLabel
@onready var farming_xp_label: Label = %FarmingXpLabel
@onready var farming_xp_title: Label = %FarmingXpTitle
@onready var farming_description: Label = %FarmingDescription

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	farming_xp_label.text = tr("$FarmingXp")
	farming_xp_title.text = tr("$FarmingXp")
	pass # Replace with function body.


func refresh():
	farming_xp_label.text = tr("$FarmingXp")
	farming_xp_title.text = tr("$FarmingXp")
	farming_description.text = ("$FarminXpDescription")
	farming_xp_bots_value.text = Global.number_to_string(NovaNetManager.active_tasks["farming_xp"])
	farmin_xp_gain_label.text = tr("$Gain") + ": " + Global.number_to_string(NovaNetManager.gain_farming_xp()) + " xp/s"
	
	var sum = 0
	for value in NovaNetManager.coef_farming_xp.values():
		sum += value
	xp_bots_correspondence_label.text = "%s xp/s" % Global.number_to_string(sum, 0.01)

func _on_draw() -> void:
	refresh()
	pass # Replace with function body.


func _on_farming_button_pressed() -> void:
	self.show()
	pass # Replace with function body.
