extends VBoxContainer
@onready var farming_xp_label: Label = %FarmingXpLabel
@onready var farming_xp_slider: HSlider = %FarmingXpSlider
@onready var farming_xp_bots_value: Label = %FarmingXpBotsValue
@onready var exploit_research_label: Label = %ExploitResearchLabel
@onready var exploit_research_slider: HSlider = %ExploitResearchSlider
@onready var exploit_research_bots_value: Label = %ExploitResearchBotsValue
@onready var farming_xp_container: HBoxContainer = %FarmingXpContainer
@onready var exploit_research_container: HBoxContainer = %ExploitResearchContainer
@onready var nbr_of_bots_value: Label = %NbrOfBotsValue
@onready var sales_container: HBoxContainer = %SalesContainer
@onready var sales_slider: HSlider = %SalesSlider
@onready var sales_bots_value: Label = %SalesBotsValue
@onready var invest_title: Label = %InvestTitle

@onready var farming_xp_grid_container: Control = %FarmingXpGridContainer
@onready var exploit_research_grid: Control = %ExploitResearchGrid
@onready var sales_grid_container: VBoxContainer = %SalesGridContainer

var containers_data: Array = []
var containers: Array = []

func _ready() -> void:
	if Player.has_signal("s_earn_cyber_force") and not Player.s_earn_cyber_force.is_connected(_on_s_cyber_force_changed):
		Player.s_earn_cyber_force.connect(_on_s_cyber_force_changed)

	containers = [farming_xp_container, exploit_research_container, sales_container]
	for container: BoxContainer in containers:
		var data := {"slider": null, "value_name": null, "value_label": null}

		for child in container.get_children():
			if child is HSlider:
				data["slider"] = child
			elif child is Label:
				data["value_label"] = child
				match child.name:
					"FarmingXpBotsValue":
						data["value_name"] = "farming_xp"
					"ExploitResearchBotsValue":
						data["value_name"] = "research"
					"SalesBotsValue":
						data["value_name"] = "sales_task"
					_:
						pass

		if data["slider"] != null:
			containers_data.append(data)
			if not data["slider"].value_changed.is_connected(_on_slider_changed):
				data["slider"].value_changed.connect(_on_slider_changed.bind(data["slider"]))

	_update_sliders_max()
	_update_value_labels()

func _on_slider_changed(_changed_value: float, slider: HSlider) -> void:
	var total_implants := int(Player.cyber_force)
	var sum := 0
	for data in containers_data:
		sum += int(data["slider"].value)
		NovaNetManager.active_tasks[data["value_name"]] = int(data["slider"].value)

	if sum > total_implants:
		var overflow := sum - total_implants
		slider.value = max(slider.value - overflow, slider.min_value)

	_update_sliders_max()
	_update_value_labels()
	refresh_sub_container()

func refresh_sub_container() -> void:
	farming_xp_grid_container.refresh()
	exploit_research_grid.refresh()

func _update_sliders_max() -> void:
	var total_implants := int(Player.cyber_force)

	for data_i in containers_data:
		var slider_i: HSlider = data_i["slider"]

		var sum_others := 0
		for data_j in containers_data:
			if data_j != data_i:
				sum_others += int(data_j["slider"].value)

		var new_max: int = max(int(slider_i.min_value), total_implants - sum_others)
		slider_i.max_value = new_max

func _update_value_labels() -> void:
	nbr_of_bots_value.text = Global.number_to_string(int(Player.cyber_force))
	for data in containers_data:
		var label: Label = data.get("value_label", null)
		if label != null:
			label.text = str(NovaNetManager.active_tasks[data["value_name"]])

func _update_value_slider() -> void:
	for data in containers_data:
		var slider: Slider = data.get("slider", null)
		if slider != null:
			slider.max_value = int(Player.cyber_force)
			slider.value = NovaNetManager.active_tasks[data["value_name"]]

func _on_s_cyber_force_changed(_value = 0) -> void:
	_update_sliders_max()
	_update_value_labels()

func _load_data(content):
	"""Ajuste l'UI avec les donnees chargees."""
	var tasks = content["active_tasks"]

	for data in containers_data:
		var slider: HSlider = data["slider"]
		slider.max_value = int(Player.cyber_force)
		slider.value = int(tasks[data["value_name"]])

	_update_sliders_max()
	_update_value_labels()
	return
