extends Node

var _name := ""
var token := ""
var secret := ""

const PLAYER_NAME_PROMPT = preload("res://resources/autoloads/PlayerNamePrompt.tscn")

func _ready():
	load_profile()

	pass

func has_profile() -> bool:
	return name != "" and token != "" and secret != ""

func load_profile():
	var cfg = ConfigFile.new()
	if cfg.load("user://player_profile.cfg") != OK:
		add_child(PLAYER_NAME_PROMPT.instantiate())
		return

	_name = cfg.get_value("player", "name", "")
	token = cfg.get_value("player", "token", "")
	secret = cfg.get_value("player", "secret", "")

func save_profile():
	var cfg = ConfigFile.new()
	cfg.set_value("player", "name", _name)
	cfg.set_value("player", "token", token)
	cfg.set_value("player", "secret", secret)
	cfg.save("user://player_profile.cfg")

func generate_profile(new_name: String):
	_name = new_name
	token = "%s-%s" % [_name.to_lower().replace(" ", "_"), str(Time.get_unix_time_from_system())]
	secret = uuid.as_string()
	save_profile()
