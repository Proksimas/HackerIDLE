extends Control

@onready var hack_item_progress_bar: ProgressBar = %HackItemProgressBar
@onready var seconds_left: Label = %SecondsLeft
@onready var buy_item_button: Button = %BuyItemButton
@onready var buy_title: Label = %BuyTitle
@onready var nbof_buy: Label = %NbofBuy
@onready var hack_item_price_label: Label = %HackItemPriceLabel
@onready var hack_item_cd: Label = %HackItemCD

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func set_item(item_name):
	var hack_items_cara = HackingItemsDb.get_item_cara(item_name)
	hack_item_cd.text = hack_items_cara
	
	pass
