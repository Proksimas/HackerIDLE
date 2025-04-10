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
	"""initialisation du shop initial"""
	_clear()
	for item_name in HackingItemsDb.hacking_items_db:
		var new_hack_item:HackItemButton = HACK_ITEM_BUTTON.instantiate()
		hack_grid.add_child(new_hack_item)
		new_hack_item.set_hacking_item(HackingItemsDb.get_item_cara(item_name))
		new_hack_item.buy_item_button.pressed.connect(_on_hack_item_button_pressed.bind(new_hack_item))
		
	pass

				
func player_bought_hacking_item(item_name,  quantity):
	
	var cost = 0

	# si le joueur a déjà l'item, on augmente son niveau
	if not Player.has_hacking_item(item_name):
		#on regarde le cout de l'item à l'unité
		cost = Calculs.total_hacking_prices(1, 1)

		if Player.knowledge_point >=  cost:
			Player.knowledge_point -= cost
			Player.add_hacking_item(HackingItemsDb.get_item_cara(item_name))
		else:
			push_warning("On ne devrait pas pouvoir acheter litem. Pas présent et pas assez de connaissance")
			
	else:
		cost = Calculs.total_hacking_prices(Player.hacking_item_bought[item_name]["level"], quantity)
		if Player.knowledge_point >=  cost:
			Player.knowledge_point -= cost
			Player.hacking_item_level_up(item_name, quantity)
		else:
			push_warning("On ne devrait pas pouvoir acheter litem, pas assez de connaissance")

		##Puis on ajuste l'ui de l'item acheté pour optimisé
	
	for hack_item:HackItemButton in hack_grid.get_children():
		if not hack_item.current_hack_item_cara.is_empty() and hack_item.current_hack_item_cara["item_name"] == item_name:
			hack_item.set_hacking_item_by_player_info()


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

	get_tree().call_group("g_hack_shop_item", "x_can_be_buy", x_upgrade_value)

func _draw() -> void:
	set_shop()
	%X1Button.pressed.emit()

func _on_hack_item_button_pressed(hack_item: HackItemButton):
	player_bought_hacking_item(hack_item.current_hack_item_cara["item_name"], hack_item.x_buy)
	get_tree().call_group("g_hack_shop_item", "x_can_be_buy", x_upgrade_value)
	
	pass

func _clear():
	for child in hack_grid.get_children():
		child.queue_free()
