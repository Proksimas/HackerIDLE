extends Control

@onready var buttons_container: HBoxContainer = %ButtonsContainer


var x_upgrade_value: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	for button:Button in buttons_container.get_children():
		button.pressed.connect(_on_x_button_pressed.bind(button.name))
	pass # Replace with function body.





func _on_x_button_pressed(button_name: String):
	'''définit le *X d achat possible'''
	match button_name.trim_suffix("Button"):
		"X1":
			x_upgrade_value = 1
		"X10":
			x_upgrade_value = 10
		"X100":
			x_upgrade_value = 100
		"XMax":
			x_upgrade_value = -1  
 

	#get_tree().call_group("g_shop_item", "x_can_be_buy", x_upgrade_value)
