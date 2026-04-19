extends Control

@onready var pulsar_logan_label: Label = %PulsarLoganLabel
@onready var pulsar_title: Label = %PulsarTitle
@onready var news_history: Panel = %NewsHistory

@onready var common_news: RichTextLabel = %CommonNews
@onready var breaking_news: RichTextLabel = %BreakingNews
@onready var player_achievement: RichTextLabel = %PlayerAchievement

@onready var common_news_label: Label = %CommonNewsLabel
@onready var breaking_news_label: Label = %BreakingNewsLabel
@onready var player_achievement_label: Label = %PlayerAchievementLabel


func _ready() -> void:
	_clear_news()
	news_history.show()
	pulsar_title.text = tr("$PulsarTitle")
	pulsar_logan_label.text = tr("$PulsarLogan")

func _on_refresh_news_history(breaking_news_passed,chronological_news_passed):
	print("breaking_news_passed: %s \nchronological_news_passed: %s" % [breaking_news_passed,chronological_news_passed])
	_clear_news()
	common_news.text = ""
	breaking_news.text = ""
	player_achievement.text = ""
	
	for elmt in breaking_news_passed:
		common_news.text += " [color=red]%s[/color]   %s\n" % [elmt, tr(elmt)]
		
	for elmt2 in chronological_news_passed:
		if elmt2 is Dictionary: #alors c'est un player achievement
			player_achievement.text += \
			"[color=green]%s[/color]   %s\n" % [elmt2["date"], tr(elmt2["key"])]
		else:
			breaking_news.text += " [color=yellow]%s[/color]   %s\n" % [elmt2.trim_prefix("$"), tr(elmt2)]
			
func _clear_news():
	common_news.clear()
	breaking_news.clear()
	player_achievement.clear()

func _on_draw() -> void:
	common_news_label.text = tr("$CommonNews")
	breaking_news_label.text = tr("$BreakingNews")
	player_achievement_label.text = tr("$PlayerAchievement")
	pass # Replace with function body.
