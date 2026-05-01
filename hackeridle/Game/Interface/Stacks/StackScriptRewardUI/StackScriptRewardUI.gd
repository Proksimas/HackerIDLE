extends PanelContainer
class_name StackScriptRewardUI

enum RewardKind { SCRIPT, SLOT, CUSTOM }

signal reward_chosen(kind: RewardKind, payload: Dictionary)

@export var reward_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var reward_kind: RewardKind = RewardKind.SCRIPT
@export var script_resource: StackScript
@export var slot_increment: int = 1
@export var custom_payload: Dictionary = {}

@onready var kind_label: Label = %KindTag
@onready var title_label: Label = %TitleLabel
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var claim_button: Button = %ClaimButton

func _ready() -> void:
	_sync_from_resource()
	_refresh_ui()
	claim_button.pressed.connect(_on_claim_pressed)


func set_reward_data(data: Dictionary) -> void:
	"""Charge dynamiquement une récompense (type, nom, description, payload)."""
	reward_id = str(data.get("id", reward_id))
	reward_kind = _parse_kind(data.get("kind", reward_kind))
	display_name = str(data.get("title", display_name))
	description = str(data.get("description", description))
	script_resource = data.get("script_resource", script_resource)
	slot_increment = int(data.get("slot_increment", slot_increment))
	custom_payload = data.get("custom_payload", custom_payload)
	_refresh_ui()


func get_reward_data() -> Dictionary:
	"""Renvoie toutes les infos nécessaires pour appliquer la récompense."""
	var payload := {}
	match reward_kind:
		RewardKind.SCRIPT:
			payload = {
				"script_resource": script_resource,
				"script_name": display_name
			}
		RewardKind.SLOT:
			payload = {"slot_increment": slot_increment}
		RewardKind.CUSTOM:
			payload = custom_payload
	return {
		"id": reward_id,
		"kind": reward_kind,
		"title": display_name,
		"description": description,
		"payload": payload
	}


func _on_claim_pressed() -> void:
	reward_chosen.emit(reward_kind, get_reward_data())


func _refresh_ui() -> void:
	if display_name.strip_edges() == "" and script_resource is StackScript:
		display_name = script_resource.stack_script_name
	kind_label.text = _kind_label_text()
	title_label.text = tr(display_name) if display_name != "" else tr("$Reward")
	description_label.text = tr(description) if description != "" else tr("$NoDescription")
	claim_button.text = tr("$Obtain")


func _kind_label_text() -> String:
	match reward_kind:
		RewardKind.SCRIPT:
			return tr("$StackScript")
		RewardKind.SLOT:
			return tr("$ExtraSlot")
		RewardKind.CUSTOM:
			return tr("$Reward")
	return tr("$Reward")


func _sync_from_resource() -> void:
	if script_resource != null and script_resource is StackScript:
		if display_name.strip_edges() == "":
			display_name = script_resource.stack_script_name


func _parse_kind(value) -> RewardKind:
	if typeof(value) == TYPE_INT:
		return value
	if typeof(value) == TYPE_STRING:
		var lower := String(value).to_lower()
		if lower == "script":
			return RewardKind.SCRIPT
		if lower == "slot":
			return RewardKind.SLOT
	return reward_kind
