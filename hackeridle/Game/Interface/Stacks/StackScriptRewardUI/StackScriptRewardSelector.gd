extends Control
class_name StackScriptRewardSelector

signal reward_selected(selected_data: Dictionary)
signal selection_cancelled

@export var reward_card_scene: PackedScene = preload("res://Game/Interface/Stacks/StackScriptRewardUI/StackScriptRewardUI.tscn")

@onready var cards_container: VBoxContainer = %CardsContainer
@onready var title_label: Label = %TitleLabel
@onready var overlay: ColorRect = %Overlay

@export var pause_game_during_selection: bool = true

var _previous_pause_state: bool = false
var _closed: bool = false


func _ready() -> void:
	_clear_cards()
	_set_modal_pause(true)
	
	
	############ TEST ######################
	var test_reward_data = {
		"id": "syn_flood_reward",
		"kind": "script",                      # ou RewardKind.SCRIPT
		"title": "Syn Flood",
		"description": "blabla.",
		"script_resource": load("res://Game/Stacks/StackScript/syn_flood.tres"),
	# optionnel pour les autres types :
	# "slot_increment": 1,
	# "custom_payload": {"foo": "bar"}
}
	_add_card(test_reward_data)

func show_rewards(rewards: Array[Dictionary], title: String = "Choisis ta récompense") -> void:
	title_label.text = title
	_clear_cards()
	for reward_data in rewards:
		_add_card(reward_data)


func _add_card(reward_data: Dictionary) -> void:
	if reward_card_scene == null:
		push_error("reward_card_scene n'est pas défini.")
		return
	var card = reward_card_scene.instantiate()
	if not card is StackScriptRewardUI:
		push_error("La scène de carte doit être un StackScriptRewardUI.")
		card.queue_free()
		return
	cards_container.add_child(card)
	card.set_reward_data(reward_data)
	card.reward_chosen.connect(_on_card_chosen.bind(card))


func _clear_cards() -> void:
	for child in cards_container.get_children():
		child.queue_free()


func _on_card_chosen(_kind, data: Dictionary, card: StackScriptRewardUI) -> void:
	if _closed:
		return
	_closed = true
	_disable_other_cards(card)
	reward_selected.emit(data)
	_close_selector()


func _disable_other_cards(selected_card: StackScriptRewardUI) -> void:
	for child in cards_container.get_children():
		if child is StackScriptRewardUI and child != selected_card:
			child.claim_button.disabled = true

func _close_selector() -> void:
	_set_modal_pause(false)
	queue_free()

func _draw() -> void:
	title_label.text = tr("$ChoseReward")

func _set_modal_pause(enable: bool) -> void:
	# Utilise get_tree().paused pour geler les autres process ; ce nœud reste actif.
	if not pause_game_during_selection:
		return
	if enable:
		_previous_pause_state = get_tree().paused
		get_tree().paused = true
		if overlay:
			overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		get_tree().paused = _previous_pause_state
