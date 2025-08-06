extends PanelContainer

@onready var text_label: Label = %TextLabel
@onready var infamy_value: Label = %InfamyValue
@onready var infamy_stats: Panel = %InfamyStats
@onready var infamy_effects: GridContainer = %InfamyEffects
@onready var treshold_name_label: Label = %TresholdNameLabel
@onready var text_label_container: HBoxContainer = %TextLabelContainer
@onready var breaking_news_container: HBoxContainer = %BreakingNewsContainer
@onready var news_container: PanelContainer = %NewsContainer
@onready var news_color_rect: Panel = %NewsColorRect
@onready var news_history_label: RichTextLabel = %NewsHistoryLabel
@onready var news_history: Panel = %NewsHistory
@onready var news_paper_icon: TextureButton = %NewsPaperIcon

@export var scroll_speed_pixels_per_second: float = 100.0
@export var scrolling_time: int = 2

enum NewsType {BREAKING, CHRONOLOGICAL, RANDOM, BANNER, ACHIEVEMENT}

const GENERIC = "res://Game/News/TextFiles/generic.csv"
const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")
const BREAKING_NEWS_ICON = preload("res://Game/Graphics/breaking_news_icon_2.png")
const NEWS_PAPER_ICON = preload("res://Game/Graphics/news_paper_icon.png")

var scroll_starting: bool = false
var news_size
var news_cache: Array = []

var breaking_news_passed: Array = []
var chronological_news_passed: Array = []

var nb_of_msg = {"random": 60,}

signal news_finished

func _ready() -> void:
	news_history_label.clear()
	news_size = text_label_container.size.x
	new_news()
	
	StatsManager.s_add_infamy.connect(_on_s_add_infamy)
	StatsManager.s_infamy_effect_added.connect(draw_infamy_stats)
	TimeManager.s_date.connect(_on_s_date)
	_on_s_add_infamy(StatsManager.infamy["current_value"])
	infamy_stats.hide()
	news_history.hide()
	pass


func _process(_delta: float) -> void:
	if scroll_starting:
		var move_amount = scroll_speed_pixels_per_second * _delta
		news_container.position.x -= move_amount

		if news_container.position.x <= 0 - news_container.get_minimum_size().x:
			scroll_starting = false
			news_finished.emit()
			news_container.position.x = get_viewport_rect().size.x

func swap_panel_to_bandeau(is_breaking_news: bool):
	var new_color = Color(0, 0, 0)
	if is_breaking_news:
		new_color = Color(255, 0, 0)
	
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = new_color
	news_color_rect.add_theme_stylebox_override("panel", stylebox)
	
	if is_breaking_news:
		breaking_news_container.show()
		text_label_container.hide()
	else:
		breaking_news_container.hide()
		text_label_container.show()


# Première étape : lance le défilement de la banderole générique
func start_breaking_news_sequence(news_key: String):
	# On déconnecte tous les signaux existants pour éviter les bugs
	if news_finished.is_connected(_on_news_finished):
		news_finished.disconnect(_on_news_finished)
	if news_finished.is_connected(_on_breaking_news_banner_finished):
		news_finished.disconnect(_on_breaking_news_banner_finished)
	
	swap_panel_to_bandeau(true)

	# On connecte le signal à la fin du défilement du bandeau
	self.news_finished.connect(_on_breaking_news_banner_finished.bind(news_key))
	
	news_container.position.x = get_viewport_rect().size.x
	news_container.position = Vector2(news_size, news_container.position.y)
	scroll_starting = true


# Gère le défilement du bandeau et lance le défilement de la news réelle
func _on_breaking_news_banner_finished(news_key: String):
	# On déconnecte ce signal pour ne pas le rappeler par erreur
	self.news_finished.disconnect(_on_breaking_news_banner_finished)
	# Deuxième étape : affiche la news réelle
	display_news(news_key, NewsType.BANNER)


# Gère le défilement de n'importe quelle news (breaking news ou classique)
func display_news(news_key: String, type: NewsType):
	if news_finished.is_connected(_on_news_finished):
		news_finished.disconnect(_on_news_finished)
	
	if type == NewsType.BREAKING:
		swap_panel_to_bandeau(true)
		text_label.text = tr(news_key) # Texte de la news réelle

	else:
		swap_panel_to_bandeau(false)
		text_label.text = tr(news_key)
		if type == NewsType.CHRONOLOGICAL:
			chronological_news_passed.append(news_key)
		elif type == NewsType.BANNER: #alors la Banniere vient de finri, on  affiche la news
			swap_panel_to_bandeau(true)
			breaking_news_container.hide()
			text_label_container.show()
			breaking_news_passed.append(news_key)
	# On connecte le signal pour passer à la prochaine news une fois le défilement terminé
	self.news_finished.connect(_on_news_finished)

	news_container.position.x = get_viewport_rect().size.x
	news_container.position = Vector2(news_size, news_container.position.y)
	scroll_starting = true
	refresh_news_history()


func pick_random_sentence(key: String):
	if not nb_of_msg.has(key):
		push_error("La clé de traduction n'est pas valide.")
	var random = randi_range(1, nb_of_msg[key])
	
	return (key + "_" + str(random))

func _on_news_finished():
	news_finished.disconnect(_on_news_finished)
	refresh_news_history()
	new_news()

func _on_s_date(date):
	var formatted_date_1: String = TimeManager.get_formatted_date_string(date)
	var breaking_news_has_trad = tr(formatted_date_1)
	var chronogical_news_has_trad = tr("$" + formatted_date_1)
	
	if breaking_news_has_trad != formatted_date_1:
		news_cache.append({NewsType.BREAKING: formatted_date_1})
	
	elif chronogical_news_has_trad != "$" + formatted_date_1:
		news_cache.append({NewsType.CHRONOLOGICAL: "$" + formatted_date_1})

func new_news():
	if not news_cache.is_empty():
		var next_news: Dictionary = news_cache.pop_front()
		var news_key = next_news.values()[0]
		var news_type = next_news.keys()[0]
		
		if news_type == NewsType.BREAKING:
			start_breaking_news_sequence(news_key)
		else:
			display_news(news_key, news_type)
		return
	
	display_news(pick_random_sentence("random"), NewsType.RANDOM)
	
	
func add_achievement(achievement_name, date):
	chronological_news_passed.append({"key": "achievement_" + achievement_name,
										"date": TimeManager.get_formatted_date_string(date)})
	refresh_news_history()
	
	pass
	
var news_to_show:int = 0
func refresh_news_history():
	news_history_label.text = ""
	match news_to_show:
		1:
			for elmt in breaking_news_passed:
				news_history_label.text += " [color=red]%s[/color]   %s\n" % [elmt, tr(elmt)]
		2:
			for elmt2 in chronological_news_passed:
				if elmt2 is Dictionary: #alors c'est un player achievement
					news_history_label.text += \
					"[color=green]%s[/color]   %s\n" % [elmt2["date"], tr(elmt2["key"])]
				else:
					news_history_label.text += " [color=yellow]%s[/color]   %s\n" % [elmt2.trim_prefix("$"), tr(elmt2)]

func _on_news_paper_icon_pressed() -> void:
	match news_to_show:
		0:
			news_history.visible = true
			news_paper_icon.texture_normal = BREAKING_NEWS_ICON
			news_to_show = 1
		1:
			news_paper_icon.flip_h = true
			news_to_show = 2
		2:
			news_paper_icon.texture_normal = NEWS_PAPER_ICON
			news_paper_icon.flip_h = false
			news_history.visible = false
			news_to_show = 0
			
	refresh_news_history()

#region INFAMY

func _on_s_add_infamy(_infamy_value):
	infamy_value.text = str(_infamy_value)

func _on_infamy_icon_pressed() -> void:
	infamy_stats.visible = not infamy_stats.visible

func draw_infamy_stats():
	for effect in infamy_effects.get_children():
		effect.queue_free()
	
	treshold_name_label.text = tr("$" + StatsManager.INFAMY_NAMES.get(StatsManager.get_infamy_treshold()))
	var _hack_modifiers = StatsManager.hack_modifiers
	var _translations: Array = []
	
	for stat: StatsManager.Stats in _hack_modifiers:
		if _hack_modifiers[stat].is_empty():
			continue
		
		var hack_dicts = _hack_modifiers[stat]
		var value: float
		var has_value: bool = false
		for dict in hack_dicts:
			if dict["source"].begins_with("infamy_"):
				value = dict["value"] * 100
				has_value = true
		
		if not has_value:
			push_warning("Pas de valeur trouvée, pas normal ")
			return
		
		var value_str: String
		if value > 0:
			value_str = "+%s" % str(value)
		elif value < 0:
			value_str = "-%s" % str(abs(value))
		else:
			value_str = ""
		
		_translations.append(tr("hack_" + StatsManager.STATS_NAMES.get(stat)).format({"hack_" + StatsManager.STATS_NAMES.get(stat) + "_value": value_str}))
	
	for trad in _translations:
		var bullet_label = BULLET_POINT.instantiate()
		infamy_effects.add_child(bullet_label)
		bullet_label.set_bullet_point(trad)

func _draw():
	infamy_value.text = str(StatsManager.infamy["current_value"])
	treshold_name_label.text = tr("$" + StatsManager.INFAMY_NAMES.get(StatsManager.get_infamy_treshold()))

func _on_cheat_infamy_pressed() -> void:
	StatsManager.add_infamy(5)

func _on_cheat_infamy_2_pressed() -> void:
	StatsManager.add_infamy(-5)
#endregion
