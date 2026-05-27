extends TabContainer

@onready var bots: VBoxContainer = %Bots


const BOT_ICON = preload("res://Game/Graphics/Common_icons/bot_head.png")
const NOVANET_ICON = preload("res://Game/Graphics/App_icons/Neos/NovaNet/novanet.png")
const CYBER_FORCE = preload("res://Game/Graphics/Common_icons/cyber_force.png")
const FIGHT = preload("res://Game/Graphics/NovaSecLogo.png")
const TAB_ICON_MAX_WIDTH := 45

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_buttons()
	
	pass # Replace with function body.



func set_buttons():
	var i = 0
	for node in self.get_children():
		self.set_tab_title(i, "")
		self.set_tab_icon_max_width(i, TAB_ICON_MAX_WIDTH)
		match i:
			0:
				self.set_tab_icon(i,NOVANET_ICON)
			1:
				self.set_tab_icon(i, BOT_ICON)
			2:
				self.set_tab_icon(i, CYBER_FORCE)
			3:
				self.set_tab_icon(i, FIGHT)
		i += 1
