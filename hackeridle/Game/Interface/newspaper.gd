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
		if not is_node_ready():
			return
		_refresh_translations()

func _refresh_translations() -> void:
	_set_label_translation(pulsar_title, "$PulsarTitle")
	_set_label_translation(pulsar_logan_label, "$PulsarLogan")
	_set_label_translation(common_news_label, "$CommonNews")
	_set_label_translation(breaking_news_label, "$BreakingNews")
	_set_label_translation(player_achievement_label, "$PlayerAchievement")

func _on_refresh_news_history(breaking_news_passed,chronological_news_passed):
	_clear_news()
	_set_rich_text(common_news, "")
	_set_rich_text(breaking_news, "")
	_set_rich_text(player_achievement, "")
	
	for elmt in breaking_news_passed:
		_append_rich_text(breaking_news, _format_breaking_line(elmt))
		
	for elmt2 in chronological_news_passed:
		if elmt2 is Dictionary and elmt2.get("kind", "") == "achievement":
			_append_rich_text(player_achievement, _format_achievement_line(elmt2))
		else:
			_append_rich_text(common_news, _format_chronological_line(elmt2))
			
func _clear_news():
	if common_news != null:
		common_news.clear()
	if breaking_news != null:
		breaking_news.clear()
	if player_achievement != null:
		player_achievement.clear()

func _set_label_translation(label: Label, key: String) -> void:
	if label == null:
		return
	label.text = tr(key)

func _on_draw() -> void:
	# Kept for existing scene signal connection.
	pass

func _set_rich_text(target: RichTextLabel, value: String) -> void:
	if target == null:
		return
	target.text = value

func _append_rich_text(target: RichTextLabel, line: String) -> void:
	if target == null:
		return
	target.text += line

func _entry_key(entry) -> String:
	return entry["key"] if entry is Dictionary else str(entry)

func _format_breaking_line(entry) -> String:
	var key := _entry_key(entry)
	return " [color=red]%s[/color]   %s\n" % [key, tr(key)]

func _format_chronological_line(entry) -> String:
	var key := _entry_key(entry)
	return " [color=yellow]%s[/color]   %s\n" % [key.trim_prefix("$"), tr(key)]

func _format_achievement_line(entry: Dictionary) -> String:
	return "[color=green]%s[/color]   %s\n" % [entry["date"], tr(entry["key"])]
