extends VBoxContainer
@onready var farming_xp_label: Label = %FarmingXpLabel
@onready var farming_xp_slider: HSlider = %FarmingXpSlider
@onready var farming_xp_bots_value: Label = %FarmingXpBotsValue

@onready var exploit_research_label: Label = %ExploitResearchLabel
@onready var exploit_research_slider: HSlider = %ExploitResearchSlider
@onready var exploit_research_bots_value: Label = %ExploitResearchBotsValue

@onready var farming_xp_container: HBoxContainer = $HBoxContainer2/FarmingXpContainer
@onready var exploit_research_container: HBoxContainer = $HBoxContainer3/ExploitResearchContainer

var containers_data: Array = []

func _ready() -> void:
	var containers = [farming_xp_container, exploit_research_container]

	for container: BoxContainer in containers:
		var data := {"slider": null, "value_label": null}

		for child in container.get_children():
			if child is HSlider:
				data["slider"] = child
			elif child is Label:
				data["value_label"] = child

		# On ne conserve que les containers qui ont un slider
		if data["slider"] != null:
			containers_data.append(data)
			# Connecte le signal du slider (on passe le slider en 2e arg via bind)
			data["slider"].value_changed.connect(_on_slider_changed.bind(data["slider"]))

	# init des max et labels au démarrage
	_update_sliders_max()
	_update_value_labels()


func _on_slider_changed(changed_value: float, slider: HSlider) -> void:
	var total_bots := Player.bots
	var sum := 0
	for data in containers_data:
		sum += int(data["slider"].value)

	# Si on dépasse le total → on réduit le slider courant
	if sum > total_bots:
		var overflow := sum - total_bots
		slider.value = max(slider.value - overflow, slider.min_value)

	# Recalcule les bornes max et les labels
	_update_sliders_max()
	_update_value_labels()


func _update_sliders_max() -> void:
	var total_bots := Player.bots

	for data_i in containers_data:
		var slider_i: HSlider = data_i["slider"]

		# Somme des autres sliders
		var sum_others := 0
		for data_j in containers_data:
			if data_j != data_i:
				sum_others += int(data_j["slider"].value)

		# Max possible pour ce slider = total - ce que les autres consomment
		var new_max: int = max(slider_i.min_value, total_bots - sum_others)
		# Évite les oscillations si la valeur dépasse le nouveau max
		slider_i.max_value = new_max
		if slider_i.value > new_max:
			slider_i.value = new_max


func _update_value_labels() -> void:
	for data in containers_data:
		var label: Label = data.get("value_label", null)
		if label != null:
			label.text = str(int(data["slider"].value))
