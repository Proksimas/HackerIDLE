extends Control


@onready var learning: Control = %Learning
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
	shop.show()
	pass # Replace with function body.


func _on_navigator_pressed() -> void:
	learning.show()
	learning.set_learning_clicker()
	pass # Replace with function body.
