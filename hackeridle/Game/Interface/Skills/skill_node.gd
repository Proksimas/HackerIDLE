extends Control
class_name SkillNode
@onready var level_skill_label: Label = %LevelSkillLabel
@onready var skill_texture: TextureRect = %SkillTexture

@export var as_associated:ActiveSkill
@export var ps_associated:PassiveSkill
@onready var border_texture: TextureRect = %BorderTexture

const BORDER_ORANGE = preload("res://Game/Graphics/Skills/Border__3_orange.png")
const BORDER_GREEN = preload("res://Game/Graphics/Skills/Border__3_green.png")
const BORDER_GREY = preload("res://Game/Graphics/Skills/Border__3_grey.png")

#on gère ici si le skill peut etre cklické ou non
var is_lock: bool = false

signal skill_button_pressed(skill_name:String, skill_type)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fill_texture()
	SkillsManager.as_learned.connect(_on_as_learned)
	SkillsManager.ps_learned.connect(_on_ps_learned)
	init()
	pass # Replace with function body.

func init() -> void:
	if as_associated != null:
		refresh_level(as_associated.as_level, len(as_associated.cost))
	else:
		refresh_level(ps_associated.ps_level, len(ps_associated.cost))

func fill_texture():
	var new_texture: Texture
	if as_associated != null:
		new_texture = as_associated.as_texture
	elif ps_associated != null:
		new_texture = ps_associated.ps_texture
	else:
		push_error("Pas de skill associé au skillNode")
		
	skill_texture.texture = new_texture


func refresh_level(_level_targeted, max_level):
	level_skill_label.text = "%s/%s" % [_level_targeted, max_level]
	
	#on change la border si besoin
	if _level_targeted == max_level:
		border_texture.texture = BORDER_GREEN
	elif _level_targeted == 0:
		border_texture.texture = BORDER_GREY
	else:
		border_texture.texture = BORDER_ORANGE
		
func show_hide_level(_type_received, min_cost_received):
	"""appelé via un groupe, permet de voir si selon l'investissement en offensives
	ou defensiv skill, ce dernier peut afficher le level et etre clickable"""
	var min_cost: int = 0
	var skill_type: String
	if self.as_associated != null:
		min_cost = as_associated.min_cost_invested
		if as_associated.is_offensive_skill:
			skill_type = "offensive"
		elif as_associated.is_defensive_skill:
			skill_type = "defensive"
		elif as_associated.is_novanet_skill:
			skill_type = "novanet"
	else:
		min_cost = ps_associated.min_cost_invested
		if ps_associated.is_offensive_skill:
			skill_type = "offensive"
		elif ps_associated.is_defensive_skill:
			skill_type = "defensive"
		elif ps_associated.is_novanet_skill:
			skill_type = "novanet"
			
	if (skill_type == "offensive" and _type_received == "offensive") or \
	(skill_type == "defensive" and _type_received == "defensive") or \
	(skill_type == "novanet" and _type_received == "novanet"):
		if min_cost <= min_cost_received:
			level_skill_label.show()
			is_lock = false
		else:
			level_skill_label.hide()
			is_lock = true

	
func _on_as_learned(as_skill: ActiveSkill):
	if as_associated != null and as_associated.as_name == as_skill.as_name:
		refresh_level(as_skill.as_level, len(as_skill.cost))
	pass
	
func _on_ps_learned(ps_skill: PassiveSkill):
	if ps_associated != null and ps_associated.ps_name == ps_skill.ps_name:
		refresh_level(ps_skill.ps_level, len(ps_skill.cost))
	pass


func _on_border_texture_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and \
		event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if as_associated != null:
			
			skill_button_pressed.emit(as_associated.as_name, "active_skill")
		elif ps_associated != null:
			skill_button_pressed.emit(ps_associated.ps_name, "passive_skill")
		else:
			push_error("Pas de skill associé au skillNode")
		pass # Replace with function body.
