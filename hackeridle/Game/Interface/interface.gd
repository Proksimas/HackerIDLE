extends CanvasLayer

@onready var connaissance: Control = %Connaissance
@onready var hack: Control = %Hack
@onready var shop: Control = %Shop
@onready var main_tab: TabContainer = %MainTab
@onready var navigator: TextureButton = %Navigator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_shopping_pressed() -> void:
	close_main_tab()
	shop.show()
	pass # Replace with function body.


func _on_navigator_pressed() -> void:
	close_main_tab()
	connaissance.show()
	pass # Replace with function body.

func close_main_tab():
	for child in main_tab.get_children():
		child.hide()

pass
