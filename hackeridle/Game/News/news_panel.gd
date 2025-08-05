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

enum NewsType {BREAKING, CHRONOLOGICAL, RANDOM, BANDEAU}

const GENERIC = "res://Game/News/TextFiles/generic.csv"
const BULLET_POINT = preload("res://Game/Interface/Specials/bullet_point.tscn")
const BREAKING_NEWS_ICON = preload("res://Game/Graphics/breaking_news_icon_2.png")
const NEWS_PAPER_ICON = preload("res://Game/Graphics/news_paper_icon.png")

var scroll_starting: bool = false
var news_size
var news_cache: Array = [] # [ {news_type}: news_key

var breaking_news_passed: Array = []  #[dates]

var chronological_news_passed: Array = []

var nb_of_msg = {"introduction": 2,   # key_de_la_traduction : nb of message associés
				"random": 1
}

signal news_finished

func _ready() -> void:
	news_history_label.clear()
	news_size = text_label_container.size.x
	#display_news(pick_random_sentence("introduction"), NewsType.RANDOM)
	new_news()
	
	StatsManager.s_add_infamy.connect(_on_s_add_infamy)
	StatsManager.s_infamy_effect_added.connect(draw_infamy_stats)
	TimeManager.s_date.connect(_on_s_date)  
	_on_s_add_infamy(StatsManager.infamy["current_value"])
	infamy_stats.hide()
	news_history.hide()
	pass # Replace with function body.


func _process(_delta: float) -> void:
	if scroll_starting:
		# Calculer le déplacement basé sur le temps écoulé (_delta)
		var move_amount = scroll_speed_pixels_per_second * _delta
		# Déplacer le texte vers la gauche
		news_container.position.x -= move_amount

		if news_container.position.x <= 0 - news_container.get_minimum_size().x:
			scroll_starting = false
			news_finished.emit()
			news_container.position.x = get_viewport_rect().size.x
	
func swap_panel_to_bandeau():
	var new_color = Color(255,0,0)
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = new_color
	news_color_rect.remove_theme_stylebox_override("panel")
	news_color_rect.add_theme_stylebox_override("panel", stylebox)
	text_label_container.hide()
	breaking_news_container.show()
	
func display_news(news_key: String, type: NewsType):
	if type == NewsType.BREAKING: 
		swap_panel_to_bandeau()
		self.news_finished.connect(_on_news_finished.bind(news_key, NewsType.BANDEAU))
	elif type == NewsType.BANDEAU:
		swap_panel_to_bandeau()
		self.news_finished.connect(_on_news_finished.bind(news_key, NewsType.BREAKING))
	else:
		var new_color = Color(0,0,0)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = new_color
		news_color_rect.remove_theme_stylebox_override("panel")
		news_color_rect.add_theme_stylebox_override("panel", stylebox)
		text_label_container.show()
		breaking_news_container.hide()
		self.news_finished.connect(_on_news_finished.bind(news_key, type))
		
	text_label.text = tr(news_key)
	news_container.position.x = get_viewport_rect().size.x
	news_container.position = Vector2(news_size, news_container.position.y)
	scroll_starting = true

		
	
func pick_random_sentence(key: String):
	if !nb_of_msg.has(key):
		push_error("La clé de traduction n'est pas valide.")
	var random =randi_range(1, nb_of_msg[key])
	
	return (key + "_" + str(random))
	
func _on_news_finished(_news_key:String, _news_type: NewsType):
	self.news_finished.disconnect(_on_news_finished)
	refresh_news_history()
	# ATTENTION Quand on reçoit le type BANDEAU, cad que le bandeau est terminé
	# On doit donc display la breaking news, en envoyant BANDEAU
	if _news_type == NewsType.BANDEAU:
		#on display la news
		display_news(_news_key, NewsType.BANDEAU)
	else:
		new_news()
	pass
	


func _on_s_date(date):
	var formatted_date_1: String = TimeManager.get_formatted_date_string(date)
	var breaking_news_has_trad = tr(formatted_date_1)
	var chronogical_news_has_trad = tr("$" + formatted_date_1)
	
	if breaking_news_has_trad != formatted_date_1: # il y a une traduction d'une breaking news
		#breaking_news_cache.append("breaking_news_template")
		
		news_cache.append({NewsType.BREAKING: formatted_date_1})
		
	elif chronogical_news_has_trad != "$" + formatted_date_1:
		news_cache.append({NewsType.CHRONOLOGICAL: "$" + formatted_date_1})
		


func new_news():
	if !news_cache.is_empty():
		#	TODO mais traité en priorité
		var next_news:Dictionary = news_cache.pop_front()
		match next_news.keys()[0]:
			NewsType.BREAKING:
				display_news(next_news.values()[0], NewsType.BREAKING)
				breaking_news_passed.append(next_news.values()[0])
			NewsType.CHRONOLOGICAL:
				display_news(next_news.values()[0], NewsType.CHRONOLOGICAL)
				chronological_news_passed.append(next_news.values()[0])
		
		return
	#toutes les news importantes sont passées. On lance donc une news random
	display_news(pick_random_sentence("random"), NewsType.RANDOM)

			
var news_to_show:int = 0 
func refresh_news_history():
	news_history_label.text = ""
	match news_to_show:
		2:
			for elmt in breaking_news_passed:
				news_history_label.text += " [color=yellow]%s[/color]    %s\n" % [elmt, tr(elmt)]
		1:
			for elmt2 in chronological_news_passed:
				news_history_label.text += " [color=yellow]%s[/color]    %s\n" % [elmt2.trim_prefix("$"), tr(elmt2)]



func _on_news_paper_icon_pressed() -> void:
	match news_to_show:
		0: #on affiche les news classiques, e ton prépare le bouton du beaking news
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


## On gère l'infamie

	
func _on_s_add_infamy(_infamy_value):
	infamy_value.text = str(_infamy_value)
	

func _on_infamy_icon_pressed() -> void:
	infamy_stats.visible = !infamy_stats.visible
	pass # Replace with function body.

func draw_infamy_stats():
	"""Dessine les caractéristiques liées à l'infamie actuelle"""
	for effect in infamy_effects.get_children():
		effect.queue_free()
		
	treshold_name_label.text = tr("$" + StatsManager.INFAMY_NAMES.get(StatsManager.get_infamy_treshold()))
	var _hack_modifiers = StatsManager.hack_modifiers
	var _translations:Array = []
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
				
		if has_value == false:
			push_warning("Pas valeur trouvée, pas normal ")
			return
		
		var value_str: String
		if value > 0:
			value_str = "+%s" % str(value)
		elif value < 0:
			value_str = "-%s" % str(abs(value))
		else:
			value_str = ""
		_translations.append(tr("hack_" + StatsManager.STATS_NAMES.get(stat)).\
				format({"hack_" + StatsManager.STATS_NAMES.get(stat) + "_value": value_str}))
	
	for trad in _translations:
		var bullet_label = BULLET_POINT.instantiate()
		infamy_effects.add_child(bullet_label)
		bullet_label.set_bullet_point(trad)

	#

func _draw():
	infamy_value.text = str(StatsManager.infamy["current_value"])
	treshold_name_label.text = tr("$" + StatsManager.INFAMY_NAMES.get(StatsManager.get_infamy_treshold()))

func _on_cheat_infamy_pressed() -> void:
	StatsManager.add_infamy(5)
	pass # Replace with function body.


func _on_cheat_infamy_2_pressed() -> void:
	StatsManager.add_infamy(-5)
	pass # Replace with function body.
#endregion
