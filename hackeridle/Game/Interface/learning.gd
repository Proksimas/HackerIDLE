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
@onready var bonus_click_multiplicator_label: Label = %BonusClickMultiplicatorLabel
@onready var bonus_click_multiplator_timer: Timer = %BonusClickMultiplatorTimer
@onready var exploits_panel: Panel = %ExploitsPanel


#const LEARNING_CLICKER = preload("res://Game/Clickers/learning_clicker.tscn")
const CLICK_PARTICLES = preload("res://Game/Graphics/ParticlesAndShaders/click_particles.tscn")
const PASSIF_LEARNING_ITEM = preload("res://Game/Clickers/passif_learning_item.tscn")
const SKILL_ACTIVATION = preload("res://Game/Interface/Skills/skill_activation.tscn")
const FLOATING_TEXT = preload("res://Game/Interface/Specials/floating_text.tscn")
const VIOLET_NEON = Color(0.878, 0.424, 0.973)
const BLUE_NEON =  Color(0.22, 0.996, 0.996) #38fefe

var clicker_scale = Vector2(10,10)
var button_cliked: bool = false
var clicker_arc_original_size
var passives_knowledge:float = 0

# VARIATION DU BRAIN GLOW
var min_outline_size:float = 10
var max_outline_size:float = 20
var min_glow_size:float = 30
var max_glow_size:float = 50
var min_glow_fallof: float = 2
var max_glow_fallof: float = 3

signal s_direct_player_brain_clicked

func _ready() -> void:
	Player.s_brain_xp_to_earn.connect(_on_s_brain_xp_to_earn)
	start_random_tween()
	brain_xp_bar.value = 0
	SkillsManager.as_learned.connect(add_skill_activation)
	_clear()
	clicker_arc_original_size = clicker_arc.custom_minimum_size
	current_brain_level.text = tr("$Level") + " 1"
	
	
func refresh_brain_xp_bar():
	brain_xp_bar.min_value = 0
	brain_xp_bar.max_value = Player.brain_xp_next
	brain_xp_bar.value = Player.brain_xp
	if Player.nb_of_rebirth >= 1:
		exploits_panel.show()
	else:
		exploits_panel.hide()

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
	
	
func get_all_passives_knowledge():
	var value: float = 0
	for passive_clicker:PassifLearningItem in passif_clickers.get_children():
		value += passive_clicker.gain_learning
	return snapped(value, 0.1)


func _on_clicker_button_pressed() -> void:
	var click_particle = CLICK_PARTICLES.instantiate()
	clicker_arc.add_child(click_particle)
	click_particle.global_position = get_global_mouse_position()
	Player.brain_clicked()
	direct_player_brain_clicked()
	button_cliked = true
	clicker_arc.custom_minimum_size = clicker_arc.custom_minimum_size + clicker_scale
	
var _window_ms := 1100  # taille de la fenêtre mobile
var max_from_click = 14 #on atteind le * 2 quand on a ce nombre de click dans 
var _recent_clicks: Array = []  # Stocke les click du joueur
var _max = StatsManager.bonus_from_clicking["max"]
var _min = StatsManager.bonus_from_clicking["min"]
func direct_player_brain_clicked():
	"""Ici on n'a QUE les click du PLayer sur le cerveau"""
	var now:= Time.get_ticks_msec()
	_recent_clicks.append([now])
	_recent_clicks = _recent_clicks.filter(func(e): return now - e[0] <= _window_ms)
	

	
func _process(_delta: float) -> void:

	if button_cliked:
		var tween = get_tree().create_tween()
		tween.tween_property(clicker_arc, "custom_minimum_size", 
						clicker_arc_original_size, 1).from(clicker_arc.custom_minimum_size)
		button_cliked = false
		

var current_tween: Tween
func start_random_tween():
	# Arrête le Tween précédent s'il existe
	if current_tween and current_tween.is_valid():
		current_tween.kill()

	if clicker_button.material == null:
		return
	# Créer un nouveau Tween
	current_tween = create_tween()
	var shader_material = clicker_button.material
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	# Définir la durée de la prochaine transition aléatoire
	var duration = rng.randf_range(1.0, 3.0) # Par exemple, une durée entre 1 et 3 secondes

	# Générer de nouvelles valeurs aléatoires pour chaque propriété
	var new_outline_size = rng.randf_range(min_outline_size, max_outline_size)
	var new_glow_size = rng.randf_range(min_glow_size, max_glow_size)
	var new_glow_fallof = rng.randf_range(min_glow_fallof, max_glow_fallof)
	# Animer chaque propriété du shader vers sa nouvelle valeur aléatoire
	current_tween.tween_property(shader_material,"shader_parameter/outline_size", new_outline_size, duration)
	current_tween.tween_property(shader_material, "shader_parameter/glow_size", new_glow_size, duration)
	current_tween.tween_property(shader_material, "shader_parameter/glow_falloff", new_glow_fallof, duration)

	# Appeler cette fonction à nouveau lorsque toutes les animations sont terminées
	current_tween.finished.connect(start_random_tween)


func _draw():
	current_brain_level.text = tr("$Level") + " " + str(Player.brain_level)
	if Player.nb_of_rebirth >= 1:
		exploits_panel.show()
	else:
		exploits_panel.hide()

func _load_data(_content):
	return

func _on_bonus_click_multiplator_timer_timeout() -> void:
	_max = StatsManager.bonus_from_clicking["max"]
	_min = StatsManager.bonus_from_clicking["min"]
	var coef = (_max - _min) / max_from_click 
	StatsManager.bonus_from_clicking["current_bonus"] = snapped((len(_recent_clicks) * coef) + _min, 0.01 )
	#print(snapped(StatsManager.bonus_from_clicking["current_bonus"], 0.1))
	bonus_click_multiplicator_label.text = "x " + \
			str(snapped(StatsManager.bonus_from_clicking["current_bonus"], 0.1))
	_recent_clicks.clear()
	pass # Replace with function body.

func _on_s_brain_xp_to_earn(_xp_from_click):
	#var new_xp_label = FLOATING_TEXT.instantiate()
	#self.add_child(new_xp_label)
	#new_xp_label.setup("+ " + str(snapped(_xp_from_click,0.1)), brain_xp_bar.global_position, BLUE_NEON)
	pass
