@tool
extends Node

var user_path = "user://"
var editor_path = "res://Game/Saves/Data/"
var save_file_name = "save.save"
var autosave_interval_seconds: float = 60.0
var autosave_timer: Timer

signal s_data_loaded

func _ready() -> void:
	if not OS.has_feature("editor"):
		_ensure_autosave_timer()


func save_game():
	"""Fonction principale de la sauvegarde du jeu"""
	var content = {}
	var nodes_savable = get_tree().get_nodes_in_group("savable")

	content[Player.name] = Player._save_data()
	content[StatsManager.name] = StatsManager._save_data()
	content[TimeManager.name] = TimeManager._save_data()
	content[EventsManager.name] = EventsManager._save_data()
	content[NovaNetManager.name] = NovaNetManager._save_data()
	content[StackManager.name] = StackManager._save_data()
	content[SkillsManager.name] = SkillsManager._save_date()
	content[MilestoneManager.name] = MilestoneManager._save_data()

	for node in nodes_savable:
		content[node.name] = node._save_data()

	content["language"] = TranslationServer.get_locale()
	save_the_data(content)


func save_the_data(content):
	var save_path = get_save_path()
	var absolute_save_path := ProjectSettings.globalize_path(save_path)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_save_path)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		print("SAVE | ECHEC")
		return

	var file_path = save_path.path_join(save_file_name)
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_var(content)
		file.close()
		print("SAVE | OK")
	else:
		print("SAVE | ECHEC")


func load_data():
	var save_path = get_save_path()
	var file_path = save_path.path_join(save_file_name)
	var f = FileAccess.open(file_path, FileAccess.READ)
	var data = f.get_var()
	f.close()

	player_load_data(data["Player"])
	stats_manager_load_data(data["StatsManager"])
	time_manager_load_data(data["TimeManager"])
	events_manager_load_data(data["EventsManager"])
	novanet_manager_load_data(data["NovaNetManager"])
	stack_manager_load_data(data.get("StackManager", {}))
	skills_manager_load_data(data["SkillsManager"])
	milestone_manager_load_data(data.get("MilestoneManager", {}))

	var interface = get_tree().get_root().get_node("Main/Interface")
	interface._load_data(data)
	s_data_loaded.emit()


func player_load_data(content: Dictionary) -> void:
	"""Nous settons les variables du Player (gold, skill_point ...)"""
	for prop in Player.get_property_list():
		var p_name: String = prop.name
		var usage: int = int(prop.usage)
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			if content.has(p_name):
				Player.set(p_name, content[p_name])

	var skills_owned = content["skills_owned"]
	Player._init_skills_owned()

	for as_skill_data in skills_owned["active"]:
		SkillsManager.learn_as(as_skill_data["as_name"], as_skill_data)

	for ps_skill_data in skills_owned["passive"]:
		SkillsManager.learn_ps(ps_skill_data["ps_name"], ps_skill_data)

	Player.brain_xp = content["brain_xp"]
	Player.brain_xp_next = content["brain_xp_next"]


func stats_manager_load_data(content: Dictionary) -> void:
	for prop in StatsManager.get_property_list():
		var p_name: String = prop.name
		var usage: int = int(prop.usage)
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			StatsManager.set(p_name, content[p_name])


func time_manager_load_data(content: Dictionary) -> void:
	for prop in TimeManager.get_property_list():
		var p_name: String = prop.name
		var usage: int = int(prop.usage)
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			TimeManager.set(p_name, content[p_name])


func events_manager_load_data(content: Dictionary) -> void:
	EventsManager._load_data(content)


func novanet_manager_load_data(content: Dictionary) -> void:
	for prop in NovaNetManager.get_property_list():
		var p_name: String = prop.name
		var usage: int = int(prop.usage)
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			NovaNetManager.set(p_name, content[p_name])


func stack_manager_load_data(content: Dictionary) -> void:
	StackManager._load_data(content if content is Dictionary else {})


func skills_manager_load_data(content: Dictionary) -> void:
	SkillsManager._load_data(content)


func milestone_manager_load_data(content: Dictionary) -> void:
	MilestoneManager._load_data(content if content is Dictionary else {})


func get_save_path():
	"""renvoie le path user ou editeur"""
	var save_path
	if OS.has_feature("editor"):
		save_path = editor_path
	else:
		save_path = user_path
	return save_path


func check_has_save():
	var save_path = get_save_path()
	var file = FileAccess

	if file.file_exists(save_path.path_join(save_file_name)):
		return true
	else:
		return false


func clean_save():
	var save_path = get_save_path()
	var dir = DirAccess.open(save_path)
	if dir and dir.file_exists(save_file_name):
		var erreur = dir.remove(save_file_name)
		if erreur != OK:
			pass


func _notification(what):
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			self.save_game()
		NOTIFICATION_APPLICATION_PAUSED:
			save_game()


func _ensure_autosave_timer() -> void:
	if autosave_timer != null and is_instance_valid(autosave_timer):
		return
	autosave_timer = Timer.new()
	autosave_timer.name = "AutosaveTimer"
	autosave_timer.wait_time = autosave_interval_seconds
	autosave_timer.one_shot = false
	autosave_timer.autostart = true
	add_child(autosave_timer)
	if not autosave_timer.timeout.is_connected(_on_autosave_timer_timeout):
		autosave_timer.timeout.connect(_on_autosave_timer_timeout)
	autosave_timer.start()


func _on_autosave_timer_timeout() -> void:
	save_game()
