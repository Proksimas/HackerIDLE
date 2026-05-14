extends Control
class_name WatchingVideoPanel

signal publicity_prepared(publicity_kind: int)

@onready var reward_title: Label = %RewardTitle
@onready var watching_video: Label = %WatchingVideo
@onready var infamy_panel: Panel = %InfamyPanel
@onready var double_reward_panel: Panel = %DoubleRewardPanel
@onready var deploy_panel: Panel = %DeployPanel
@onready var infamy_label: Label = %InfamyLabel
@onready var double_reward_label: Label = %DoubleRewardLabel
@onready var deploy_label: Label = %DeployLabel

var pending_publicity_kind: int = AdsManager.PublicityKind.NONE


func _ready() -> void:
	_configure_clickable_panel(infamy_panel)
	_configure_clickable_panel(double_reward_panel)
	_configure_clickable_panel(deploy_panel)
	_refresh_texts()
	AdsManager.show_banner()


func _on_draw() -> void:
	_refresh_texts()


func _on_infamy_panel_gui_input(event: InputEvent) -> void:
	_handle_panel_click(infamy_panel, event, AdsManager.PublicityKind.INFAMY)


func _on_double_reward_panel_gui_input(event: InputEvent) -> void:
	_handle_panel_click(double_reward_panel, event, AdsManager.PublicityKind.DOUBLE_REWARD)
	


func _on_deploy_panel_gui_input(event: InputEvent) -> void:
	_handle_panel_click(deploy_panel, event, AdsManager.PublicityKind.DEPLOY)


func prepare_publicity_launch(publicity_kind: int) -> void:
	pending_publicity_kind = publicity_kind
	AdsManager.prepare_rewarded_publicity(publicity_kind)
	publicity_prepared.emit(publicity_kind)
	


func clear_pending_publicity() -> void:
	pending_publicity_kind = AdsManager.PublicityKind.NONE


func _refresh_texts() -> void:
	reward_title.text = tr("watching_video")
	watching_video.text = tr("watching_video_des")
	infamy_label.text = tr("video_decrease_infamy").replace("X", str(int(AdsManager.INFAMY_REDUCTION_AMOUNT)))
	double_reward_label.text = tr("video_double_reward").replace("X", str(int(AdsManager.DOUBLE_REWARD_DURATION_SECONDS)))
	deploy_label.text = tr("video_deploy_event")


func _configure_clickable_panel(panel: Control) -> void:
	_set_children_mouse_filter_ignore(panel)


func _handle_panel_click(panel: Control, event: InputEvent, publicity_kind: int) -> void:
	if not _is_left_click(event):
		return
	panel.accept_event()
	get_viewport().set_input_as_handled()
	prepare_publicity_launch(publicity_kind)
	self.queue_free()


func _is_left_click(event: InputEvent) -> bool:
	var mouse_button_event := event as InputEventMouseButton
	return mouse_button_event != null \
		and mouse_button_event.pressed \
		and mouse_button_event.button_index == MOUSE_BUTTON_LEFT


func _set_children_mouse_filter_ignore(root: Node) -> void:
	for child in root.get_children():
		var control_child := child as Control
		if control_child != null:
			control_child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_children_mouse_filter_ignore(child)


func _on_close_button_pressed() -> void:
	self.queue_free()
	pass # Replace with function body.


func _on_tree_exiting() -> void:
	AdsManager.hide_banner()
	pass # Replace with function body.
