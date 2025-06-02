extends Control

@onready var source_name_label: Label = %SourceNameLabel
@onready var source_des_label: Label = %SourceDesLabel
@onready var cost_label: Label = %CostLabel
@onready var upgrade_price_label: Label = %UpgradePriceLabel
@onready var buy_source_button: Button = %BuySourceButton
@onready var salary_label: Label = %SalaryLabel
@onready var gold_salary_label: Label = %GoldSalaryLabel
@onready var close_button: TextureButton = %CloseButton
@onready var bonus_label: Label = %BonusLabel
@onready var bonus_grid: GridContainer = %BonusGrid
@onready var source_texture: TextureRect = %SourceTexture
@onready var level_label: Label = %LevelLabel


var current_source_cara
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_clear()
	pass # Replace with function body.

func set_source(source_cara:Dictionary):
	_clear()
	self.show()
	current_source_cara = source_cara
	cost_label.text = tr('$Cost') 
	salary_label.text = tr('$Salary')
	bonus_label.text = tr('$Effects')
	
	source_name_label.text = source_cara['source_name']
	source_des_label.text = tr(source_cara['source_name'] + "_desc")
	source_texture.texture = load(source_cara["texture_path"])
	level_label.text = tr("$Level") + ": " + str(source_cara["level"])
	
	pass

func _center_deferred(target):
	Global.call_deferred("center", self, target)
	pass

func _on_close_button_pressed() -> void:
	self.queue_free()
	pass # Replace with function body.

func _clear():
	for child in bonus_grid.get_children():
		child.queue_free()
