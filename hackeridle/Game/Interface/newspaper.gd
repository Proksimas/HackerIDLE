extends Control

@onready var pulsar_logan_label: Label = get_node_or_null("MarginContainer/VBoxContainer/HBoxContainer/PulsarLoganLabel")
@onready var pulsar_title: Label = get_node_or_null("MarginContainer/VBoxContainer/PulsarTitle")
@onready var news_history: Panel = get_node_or_null("MarginContainer/VBoxContainer/NewsHistory")

@onready var common_news: RichTextLabel = get_node_or_null("MarginContainer/VBoxContainer/NewsHistory/VBoxContainer/VBoxContainer/CommonNews")
@onready var breaking_news: RichTextLabel = get_node_or_null("MarginContainer/VBoxContainer/NewsHistory/VBoxContainer/VBoxContainer2/BreakingNews")
@onready var player_achievement: RichTextLabel = get_node_or_null("MarginContainer/VBoxContainer/NewsHistory/VBoxContainer/VBoxContainer3/PlayerAchievement")

@onready var common_news_label: Label = get_node_or_null("MarginContainer/VBoxContainer/NewsHistory/VBoxContainer/VBoxContainer/CommonNewsLabel")
@onready var breaking_news_label: Label = get_node_or_null("MarginContainer/VBoxContainer/NewsHistory/VBoxContainer/VBoxContainer2/BreakingNewsLabel")
@onready var player_achievement_label: Label = get_node_or_null("MarginContainer/VBoxContainer/NewsHistory/VBoxContainer/VBoxContainer3/PlayerAchievementLabel")


func _ready() -> void:
	_clear_news()
	if news_history != null:
		news_history.show()
	_refresh_translations()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh_translations()

func _refresh_translations() -> void:
	_set_label_translation(pulsar_title, "$PulsarTitle")
	_set_label_translation(pulsar_logan_label, "$PulsarLogan")
	_set_label_translation(common_news_label, "$CommonNews")
	_set_label_translation(breaking_news_label, "$BreakingNews")
	_set_label_translation(player_achievement_label, "$PlayerAchievement")

func _on_refresh_news_history(breaking_news_passed,chronological_news_passed):
	print("breaking_news_passed: %s \nchronological_news_passed: %s" % [breaking_news_passed,chronological_news_passed])
	_clear_news()
	common_news.text = ""
	breaking_news.text = ""
	player_achievement.text = ""
	
	for elmt in breaking_news_passed:
		var key = elmt["key"] if elmt is Dictionary else str(elmt)
		breaking_news.text += " [color=red]%s[/color]   %s\n" % [key, tr(key)]
		
	for elmt2 in chronological_news_passed:
		if elmt2 is Dictionary and elmt2.get("kind", "") == "achievement":
			player_achievement.text += \
			"[color=green]%s[/color]   %s\n" % [elmt2["date"], tr(elmt2["key"])]
		else:
			var key2 = elmt2["key"] if elmt2 is Dictionary else str(elmt2)
			common_news.text += " [color=yellow]%s[/color]   %s\n" % [key2.trim_prefix("$"), tr(key2)]
			
func _clear_news():
	if common_news != null:
		common_news.clear()
	if breaking_news != null:
		breaking_news.clear()
	if player_achievement != null:
		player_achievement.clear()

func _set_label_translation(label: Label, key: String) -> void:
	if label == null:
		push_warning("newspaper.gd: label introuvable pour la clé %s" % key)
		return
	label.text = tr(key)
