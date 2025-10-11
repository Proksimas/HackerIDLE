extends Control
class_name SkillNode
@onready var skill_button: TextureButton = %SkillButton
@onready var level_skill_label: Label = %LevelSkillLabel

@export var as_associated:ActiveSkill
@export var ps_associated:PassiveSkill
@onready var border_texture: TextureRect = %BorderTexture

const BORDER_ORANGE = preload("res://Game/Graphics/Skills/Border__3_orange.png")
const BORDER_GREEN = preload("res://Game/Graphics/Skills/Border__3_green.png")
const BORDER_GREY = preload("res://Game/Graphics/Skills/Border__3_grey.png")

signal skill_button_pressed(skill_name:String, skill_type)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fill_texture()
	SkillsManager.as_learned.connect(_on_as_learned)
	SkillsManager.ps_learned.connect(_on_ps_learned)
	pass # Replace with function body.


func _on_skill_button_pressed() -> void:
	if as_associated != null:
		
		skill_button_pressed.emit(as_associated.as_name, "active_skill")
	elif ps_associated != null:
		skill_button_pressed.emit(ps_associated.ps_name, "passive_skill")
	else:
		push_error("Pas de skill associé au skillNode")
	pass # Replace with function body.


func fill_texture():
	var new_texture: Texture
	if as_associated != null:
		new_texture = as_associated.as_texture
	elif ps_associated != null:
		new_texture = ps_associated.ps_texture
	else:
		push_error("Pas de skill associé au skillNode")
		
	skill_button.texture_normal = new_texture


func refresh_level(_level_targeted, max_level):
	level_skill_label.text = "%s/%s" % [_level_targeted, max_level]
	
	#on change la border si besoin
	if _level_targeted == max_level:
		border_texture.texture = BORDER_ORANGE
	elif _level_targeted == 0:
		border_texture.texture = BORDER_GREY
	else:
		border_texture.texture = BORDER_GREEN
	
func _on_as_learned(as_skill: ActiveSkill):
	if as_associated != null and as_associated.as_name == as_skill.as_name:
		refresh_level(as_skill.as_level, len(as_skill.cost))
	pass
	
func _on_ps_learned(ps_skill: PassiveSkill):
	if ps_associated != null and ps_associated.ps_name == ps_skill.ps_name:
		refresh_level(ps_skill.ps_level, len(ps_skill.cost))
	pass
