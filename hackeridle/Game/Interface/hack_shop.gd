extends Control

@onready var buttons_container: HBoxContainer = %ButtonsContainer
@onready var hack_grid: GridContainer = %HackGrid

const HACK_ITEM_BUTTON = preload("res://Game/Clickers/hack_item_button.tscn")


var x_upgrade_value: int
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_clear()
	
	for button:Button in buttons_container.get_children():
		button.pressed.connect(_on_x_button_pressed.bind(button.name))
	pass # Replace with function body.



func set_shop():
	_clear()
	for item_name in HackingItemsDb.learning_items_db:
		var new_hack_item:HackItemButton = HACK_ITEM_BUTTON.instantiate()
		hack_grid.add_child(new_hack_item)
		new_hack_item.set_item(item_name)
		new_hack_item.buy_item_button.pressed.connect(_on_hack_item_button_pressed.bind(new_hack_item))
		
	pass



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

func _draw() -> void:
	set_shop()
	%X1Button.pressed.emit()

func _on_hack_item_button_pressed(hack_item: HackItemButton):

	pass

func _clear():
	for child in hack_grid.get_children():
		child.queue_free()
