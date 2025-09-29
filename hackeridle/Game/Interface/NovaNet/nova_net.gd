extends Control

@onready var nova_net_tab: TabContainer = %NovaNetTab
@onready var bots: VBoxContainer = %Bots
@onready var bots_affecation: VBoxContainer = %BotsAffecation



func refresh():
	bots.name = tr("$Bots")
	bots_affecation.name = tr("$BotsAffecation")


func _load_data(content):
	bots_affecation._load_data(content)
	


func _on_draw() -> void:
	bots.show()
	refresh()
	pass # Replace with function body.
