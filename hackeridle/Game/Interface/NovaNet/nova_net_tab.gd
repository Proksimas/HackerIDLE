extends TabContainer

const TAB_TITLE_KEYS := ["NovaNet", "$Bots", "$cyber_force", "Stacks"]

@onready var tab_buttons: Array[VBoxContainer] = [
	%NovaNetTabButton0,
	%NovaNetTabButton1,
	%NovaNetTabButton2,
	%NovaNetTabButton3,
]
@onready var tab_title_labels: Array[Label] = [
	%NovaNetTabTitle0,
	%NovaNetTabTitle1,
	%NovaNetTabTitle2,
	%NovaNetTabTitle3,
]


func _ready() -> void:
	set_buttons()


func set_buttons() -> void:
	tabs_visible = false
	_clear_native_tabs()
	_ensure_tab_button_connections()
	refresh_buttons()
	_update_tab_buttons_state()
	if not tab_changed.is_connected(_on_tab_changed):
		tab_changed.connect(_on_tab_changed)


func refresh_buttons() -> void:
	for i in range(min(tab_title_labels.size(), TAB_TITLE_KEYS.size())):
		match i:
			0:
				tab_title_labels[i].text = tr("$inventory")
			1:
				tab_title_labels[i].text = tr("$bot")
			2:
				tab_title_labels[i].text = tr("$cyber_force")
			3:
				tab_title_labels[i].text = tr("$fight")



func _clear_native_tabs() -> void:
	for i in range(get_tab_count()):
		set_tab_title(i, "")
		set_tab_icon(i, null)


func _ensure_tab_button_connections() -> void:
	var callbacks := [
		_on_nova_net_tab_button_0_gui_input,
		_on_nova_net_tab_button_1_gui_input,
		_on_nova_net_tab_button_2_gui_input,
		_on_nova_net_tab_button_3_gui_input,
	]
	for i in range(min(tab_buttons.size(), callbacks.size())):
		if not tab_buttons[i].gui_input.is_connected(callbacks[i]):
			tab_buttons[i].gui_input.connect(callbacks[i])


func _on_nova_net_tab_button_0_gui_input(event: InputEvent) -> void:
	_on_tab_button_gui_input(event, 0)


func _on_nova_net_tab_button_1_gui_input(event: InputEvent) -> void:
	_on_tab_button_gui_input(event, 1)


func _on_nova_net_tab_button_2_gui_input(event: InputEvent) -> void:
	_on_tab_button_gui_input(event, 2)


func _on_nova_net_tab_button_3_gui_input(event: InputEvent) -> void:
	_on_tab_button_gui_input(event, 3)


func _on_tab_button_gui_input(event: InputEvent, tab_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		current_tab = tab_index
		_update_tab_buttons_state()


func _on_tab_changed(_tab_index: int) -> void:
	_update_tab_buttons_state()


func _update_tab_buttons_state() -> void:
	for i in range(tab_buttons.size()):
		tab_buttons[i].modulate = Color.WHITE if i == current_tab else Color(0.65, 0.65, 0.65, 1.0)
