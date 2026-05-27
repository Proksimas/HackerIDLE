extends TabContainer

const TAB_INVENTORY := 0
const TAB_BOTS := 1
const TAB_CYBER_FORCE := 2
const TAB_FIGHT := 3

const TAB_TITLE_KEYS := [
	"$inventory",
	"$bot",
	"$cyber_force",
	"$fight",
]

@onready var tab_buttons: Array[Button] = [
	%InventoryTabButton,
	%BotsTabButton,
	%CyberForceTabButton,
	%FightTabButton,
]
@onready var tab_title_labels: Array[Label] = [
	%InventoryTabTitle,
	%BotsTabTitle,
	%CyberForceTabTitle,
	%FightTabTitle,
]


func _ready() -> void:
	set_buttons()


func set_buttons() -> void:
	tabs_visible = false
	_clear_native_tabs()
	refresh_buttons()
	_update_tab_buttons_state()
	if not tab_changed.is_connected(_on_tab_changed):
		tab_changed.connect(_on_tab_changed)


func refresh_buttons() -> void:
	for i in range(min(tab_title_labels.size(), TAB_TITLE_KEYS.size())):
		tab_title_labels[i].text = tr(TAB_TITLE_KEYS[i])


func _clear_native_tabs() -> void:
	for i in range(get_tab_count()):
		set_tab_title(i, "")
		set_tab_icon(i, null)


func _select_tab(tab_index: int) -> void:
	current_tab = tab_index
	_update_tab_buttons_state()


func _on_inventory_tab_button_pressed() -> void:
	_select_tab(TAB_INVENTORY)


func _on_bots_tab_button_pressed() -> void:
	_select_tab(TAB_BOTS)


func _on_cyber_force_tab_button_pressed() -> void:
	_select_tab(TAB_CYBER_FORCE)


func _on_fight_tab_button_pressed() -> void:
	_select_tab(TAB_FIGHT)


func _on_tab_changed(_tab_index: int) -> void:
	_update_tab_buttons_state()


func _update_tab_buttons_state() -> void:
	for i in range(tab_buttons.size()):
		tab_buttons[i].modulate = Color.WHITE if i == current_tab else Color(0.65, 0.65, 0.65, 1.0)
