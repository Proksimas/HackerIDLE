extends Control

@onready var nova_net_tab: TabContainer = %NovaNetTab
@onready var bots: VBoxContainer = %Bots
@onready var implants_affecation: VBoxContainer = %ImplantsAffecation
@onready var nova_net_main: Control = %NovaNetMain
@onready var stack_fight_ui: Control = %StackFightUi

func _ready() -> void:
	nova_net_tab.current_tab = 0
	_refresh_novanet_access()
	refresh()

func on_opened() -> void:
	"""Appellee quand le joueur ouvre NovaNet depuis l'interface principale."""
	_refresh_novanet_access()
	nova_net_tab.current_tab = 0
	refresh()


func refresh():
	bots.name = tr("$Bots")
	implants_affecation.name = tr("$cyber_force")

func _refresh_novanet_access() -> void:
	var has_novanet := Player.nb_of_rebirth > 0
	# L'onglet scripts (NovaNetMain) est dispo avec NovaNet.
	nova_net_main.visible = has_novanet
	# Les fights roguelike sont dispo des l'entree dans NovaNet.
	stack_fight_ui.visible = has_novanet
	if has_novanet and nova_net_main.has_method("refresh_hacker_scripts"):
		nova_net_main.call("refresh_hacker_scripts")
	if has_novanet and stack_fight_ui.has_method("on_opened"):
		stack_fight_ui.call("on_opened")

	# Si on etait sur un onglet non accessible, on revient a l'accueil NovaNet.
	if not has_novanet and nova_net_tab.current_tab != 0:
		nova_net_tab.current_tab = 0


func _load_data(content):
	implants_affecation._load_data(content)
	_refresh_novanet_access()
	


func _on_draw() -> void:
	refresh()
	pass # Replace with function body.
