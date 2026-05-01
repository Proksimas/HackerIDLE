extends PanelContainer

@onready var text_label: Label = %TextLabel
@onready var infamy_value: Label = %InfamyValue
@onready var text_label_container: HBoxContainer = %TextLabelContainer
@onready var breaking_news_container: HBoxContainer = %BreakingNewsContainer
@onready var news_container: PanelContainer = %NewsContainer
@onready var news_color_rect: Panel = %NewsColorRect


@onready var news_paper_icon: TextureButton = %NewsPaperIcon
@onready var warning_icon: TextureRect = %WarningIcon
@export var scroll_speed_pixels_per_second: float = 100.0
@export var scrolling_time: int = 2

enum NewsType {BREAKING, CHRONOLOGICAL, RANDOM, BANNER, ACHIEVEMENT}

var scroll_starting: bool = false
var has_news_to_read: bool = false
var news_size
var news_cache: Array = []

var breaking_news_passed: Array = []
var chronological_news_passed: Array = []
var _breaking_banner_finished_handler: Callable

var nb_of_msg = {"random": 60,}

signal news_finished
signal show_infamy
signal s_refresh_news_history

func _ready() -> void:
	has_news_to_read = false
	warning_icon.visible = false
	await get_tree().process_frame
	_refresh_news_size()
	new_news()
	
	StatsManager.s_add_infamy.connect(_on_s_add_infamy)
	#StatsManager.s_infamy_effect_added.connect(draw_infamy_stats)
	TimeManager.s_date.connect(_on_s_date)
	_on_s_add_infamy(StatsManager.infamy["current_value"])


func _process(_delta: float) -> void:
	if scroll_starting:
		var move_amount = scroll_speed_pixels_per_second * _delta
		news_container.position.x -= move_amount

		if news_container.position.x <= 0 - news_container.get_minimum_size().x:
			scroll_starting = false
			news_finished.emit()
			news_container.position.x = get_viewport_rect().size.x

func swap_panel_to_bandeau(is_breaking_news: bool):
	var new_color = Color(0.71, 0.231, 0.741)
	if is_breaking_news:
		new_color = Color(1, 0, 0)
	
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
	_disconnect_news_finished_handlers()
	
	swap_panel_to_bandeau(true)

	# On connecte le signal à la fin du défilement du bandeau
	_breaking_banner_finished_handler = _on_breaking_news_banner_finished.bind(news_key)
	self.news_finished.connect(_breaking_banner_finished_handler)
	
	_reset_news_position()
	scroll_starting = true


# Gère le défilement du bandeau et lance le défilement de la news réelle
func _on_breaking_news_banner_finished(news_key: String):
	# On déconnecte ce signal pour ne pas le rappeler par erreur
	if _breaking_banner_finished_handler.is_valid() and news_finished.is_connected(_breaking_banner_finished_handler):
		self.news_finished.disconnect(_breaking_banner_finished_handler)
	_breaking_banner_finished_handler = Callable()
	# Deuxième étape : affiche la news réelle
	display_news(news_key, NewsType.BANNER)


# Gère le défilement de n'importe quelle news (breaking news ou classique)
func display_news(news_key: String, type: NewsType):
	_disconnect_news_finished_handlers()
	
	if type == NewsType.BREAKING:
		swap_panel_to_bandeau(true)
		text_label.text = tr(news_key) # Texte de la news réelle

	else:
		swap_panel_to_bandeau(false)
		text_label.text = tr(news_key)
		if type == NewsType.CHRONOLOGICAL:
			var chrono_entry := {"kind": "chronological", "key": news_key}
			if not _history_contains_entry(chronological_news_passed, chrono_entry):
				chronological_news_passed.append(chrono_entry)
		elif type == NewsType.BANNER: #alors la Banniere vient de finri, on  affiche la news
			swap_panel_to_bandeau(true)
			breaking_news_container.hide()
			text_label_container.show()
			var breaking_entry := {"kind": "breaking", "key": news_key}
			if not _history_contains_entry(breaking_news_passed, breaking_entry):
				breaking_news_passed.append(breaking_entry)
	# On connecte le signal pour passer à la prochaine news une fois le défilement terminé
	self.news_finished.connect(_on_news_finished)

	_reset_news_position()
	scroll_starting = true
	if type != NewsType.RANDOM:
		has_news_to_read = true
		warning_icon.visible = true
	s_refresh_news_history.emit(breaking_news_passed,chronological_news_passed)


func pick_random_sentence(key: String):
	if not nb_of_msg.has(key):
		push_error("La clé de traduction n'est pas valide.")
	var random = randi_range(1, nb_of_msg[key])
	
	return (key + "_" + str(random))

func _on_news_finished():
	if news_finished.is_connected(_on_news_finished):
		news_finished.disconnect(_on_news_finished)
	s_refresh_news_history.emit(breaking_news_passed,chronological_news_passed)
	new_news()

func _on_s_date(date):
	var formatted_date_1: String = TimeManager.get_formatted_date_string(date)
	var breaking_news_has_trad = tr(formatted_date_1)
	var chronogical_news_has_trad = tr("$" + formatted_date_1)
	
	if breaking_news_has_trad != formatted_date_1:
		_queue_unique_news(NewsType.BREAKING, formatted_date_1)
	
	elif chronogical_news_has_trad != "$" + formatted_date_1:
		_queue_unique_news(NewsType.CHRONOLOGICAL, "$" + formatted_date_1)

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
	var achievement_entry := {"kind": "achievement",
								"key": "achievement_" + achievement_name,
								"date": TimeManager.get_formatted_date_string(date)}
	if not _history_contains_entry(chronological_news_passed, achievement_entry):
		chronological_news_passed.append(achievement_entry)
	s_refresh_news_history.emit(breaking_news_passed,chronological_news_passed)
	
	pass
	
#region INFAMY

func _on_s_add_infamy(_infamy_value):
	if _infamy_value >= 99 and _infamy_value < 100:
		infamy_value.text = "99"
	else:
		infamy_value.text = str(ceil(_infamy_value)) #l'affichage est arrondi au supérieur
	

func _on_infamy_icon_pressed() -> void:
	show_infamy.emit()

func _draw():
	infamy_value.text = str(StatsManager.infamy["current_value"])
	
func _on_cheat_infamy_pressed() -> void:
	StatsManager.add_infamy(5)

func _on_cheat_infamy_2_pressed() -> void:
	StatsManager.add_infamy(-5)
#endregion

func _save_data():
	return {
		"news_cache": news_cache,
		"breaking_news_passed": breaking_news_passed,
		"chronological_news_passed": chronological_news_passed
	}

func _load_data(content):
	news_cache =content["news_cache"]
	breaking_news_passed = _normalize_history_entries(content["breaking_news_passed"], "breaking")
	chronological_news_passed = _normalize_history_entries(content["chronological_news_passed"], "chronological")
	pass


func _on_news_paper_icon_pressed() -> void:
	has_news_to_read = false
	warning_icon.visible = false
	pass # Replace with function body.

func _refresh_news_size() -> void:
	news_size = text_label_container.size.x

func _reset_news_position() -> void:
	_refresh_news_size()
	news_container.position = Vector2(news_size, news_container.position.y)

func _disconnect_news_finished_handlers() -> void:
	if news_finished.is_connected(_on_news_finished):
		news_finished.disconnect(_on_news_finished)
	if _breaking_banner_finished_handler.is_valid() and news_finished.is_connected(_breaking_banner_finished_handler):
		news_finished.disconnect(_breaking_banner_finished_handler)
	_breaking_banner_finished_handler = Callable()

func _normalize_history_entries(entries: Array, fallback_kind: String) -> Array:
	var normalized: Array = []
	for entry in entries:
		if entry is Dictionary:
			if not entry.has("kind"):
				entry["kind"] = fallback_kind
			if not _history_contains_entry(normalized, entry):
				normalized.append(entry)
		else:
			var normalized_entry := {"kind": fallback_kind, "key": entry}
			if not _history_contains_entry(normalized, normalized_entry):
				normalized.append(normalized_entry)
	return normalized

func _queue_unique_news(news_type: NewsType, news_key: String) -> void:
	if _news_cache_contains(news_type, news_key):
		return
	if news_type == NewsType.BREAKING and _history_contains_key(breaking_news_passed, news_key):
		return
	if news_type == NewsType.CHRONOLOGICAL and _history_contains_key(chronological_news_passed, news_key):
		return
	news_cache.append({news_type: news_key})

func _news_cache_contains(news_type: NewsType, news_key: String) -> bool:
	for cached_news in news_cache:
		if not (cached_news is Dictionary) or cached_news.is_empty():
			continue
		if cached_news.keys()[0] == news_type and cached_news.values()[0] == news_key:
			return true
	return false

func _history_contains_key(history: Array, key: String) -> bool:
	for entry in history:
		if entry is Dictionary and entry.get("key", "") == key:
			return true
		if str(entry) == key:
			return true
	return false

func _history_contains_entry(history: Array, candidate: Dictionary) -> bool:
	for entry in history:
		if entry is Dictionary and entry == candidate:
			return true
	return false
