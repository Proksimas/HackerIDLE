extends GridContainer

@onready var farming_xp_slider: HSlider = %FarmingXpSlider
@onready var farming_xp_bots_value: Label = %FarmingXpBotsValue
@onready var xp_bots_correspondence_label: Label = %XpBotsCorrespondenceLabel
@onready var farmin_xp_gain_label: Label = %FarminXpGainLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func refresh():
	farming_xp_bots_value.text = str(NovaNetManager.active_tasks["farming_xp"])
	xp_bots_correspondence_label.text = "%s xp/s" % NovaNetManager.coef_farming_xp
	farmin_xp_gain_label.text = tr("$Gain") + ": " + str(NovaNetManager.gain_farming_xp()) + " xp/s"

func _on_draw() -> void:
	refresh()
	pass # Replace with function body.
