extends Control


@onready var passif_clickers: HFlowContainer = %PassifClickers
@onready var clicker_arc: AspectRatioContainer = %ClickerARC
@onready var brain_xp_bar: ProgressBar = %BrainXpBar
@onready var current_brain_level: Label = %CurrentBrainLevel
@onready var active_skills: FlowContainer = %ActiveSkills
@onready var knowledge_per_second: Label = %KnowledgePerSecond
@onready var passive_items_textures: Control = %PassiveItemsTextures
@onready var all_container: VBoxContainer = $AllContainer
@onready var clicker_button: TextureButton = %ClickerButton


#const LEARNING_CLICKER = preload("res://Game/Clickers/learning_clicker.tscn")
const CLICK_PARTICLES = preload("res://Game/Graphics/ParticlesAndShaders/click_particles.tscn")
const PASSIF_LEARNING_ITEM = preload("res://Game/Clickers/passif_learning_item.tscn")
const SKILL_ACTIVATION = preload("res://Game/Interface/Skills/skill_activation.tscn")


var clicker_scale = Vector2(10,10)
var button_cliked: bool = false
var clicker_arc_original_size
var passives_knowledge:float = 0

func _ready() -> void:
	brain_xp_bar.value = 0
	SkillsManager.as_learned.connect(add_skill_activation)
	_clear()
	clicker_arc_original_size = clicker_arc.custom_minimum_size
	current_brain_level.text = tr("$Level") + " 1"
	
	
func refresh_brain_xp_bar():
	brain_xp_bar.min_value = 0
	brain_xp_bar.max_value = Player.brain_xp_next
	brain_xp_bar.value = Player.brain_xp

func add_skill_activation(skill_to_associated:ActiveSkill):
	var skill_activation = SKILL_ACTIVATION.instantiate()
	active_skills.add_child(skill_activation)
	skill_activation.set_skill_activation(skill_to_associated)
	
func _clear():
	for child in passif_clickers.get_children():
		child.queue_free()
	for skill in active_skills.get_children():
		skill.queue_free()
		

func _on_shop_item_bought(item_name):# <-Interface
	for child: PassifLearningItem in passif_clickers.get_children():
		if child.shop_item_cara_db["item_name"] == item_name:
			child.set_refresh(Player.learning_item_bought[item_name])
			passives_knowledge = get_all_passives_knowledge()
			return
			
	#si on est là, c'est que l'item n'est pas encore existant
	var new_passif_item = PASSIF_LEARNING_ITEM.instantiate()
	passif_clickers.add_child(new_passif_item)
	new_passif_item.set_item(LearningItemsDB.get_item_cara(item_name))
	passives_knowledge = get_all_passives_knowledge()
	
	
func get_all_passives_knowledge():
	var value: float = 0
	for passive_clicker:PassifLearningItem in passif_clickers.get_children():
		value += passive_clicker.gain_learning
	return value

			

func _on_clicker_button_pressed() -> void:
	var click_particle = CLICK_PARTICLES.instantiate()
	clicker_arc.add_child(click_particle)
	click_particle.global_position = get_global_mouse_position()
	Player.brain_clicked()
	button_cliked = true
	clicker_arc.custom_minimum_size = clicker_arc.custom_minimum_size + clicker_scale
	
func _process(_delta: float) -> void:
	if button_cliked:
		var tween = get_tree().create_tween()
		tween.tween_property(clicker_arc, "custom_minimum_size", 
						clicker_arc_original_size, 1).from(clicker_arc.custom_minimum_size)
		button_cliked = false
		

func _load_data(content):
	# content = dictionnaire des learning_item_bought
	"""Doit instaurer tous les items passifs"""
	for passif_item in content:
		var new_passif_item = PASSIF_LEARNING_ITEM.instantiate()
		passif_clickers.add_child(new_passif_item)
		new_passif_item.set_item(LearningItemsDB.get_item_cara(passif_item))
	refresh_brain_xp_bar()
	pass
