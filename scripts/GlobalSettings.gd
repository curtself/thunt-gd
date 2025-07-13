extends Node

# persist config
const SETTINGS_FILE:String = "user://settings.json"
var starting_moves:int = 15
var common_timeout:float = 0.05
var common_timeout_label:String = "Normal"

# runtime config
var load_save:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# check if there are saved settings and apply them if so
	if FileAccess.file_exists(SETTINGS_FILE):
		load_settings()

func load_settings() -> void:
	var settings_file  = FileAccess.open(SETTINGS_FILE,FileAccess.READ)
	while settings_file.get_position() < settings_file.get_length():
		var settings_string = settings_file.get_line()
		var json = JSON.new()
		var parse_result = json.parse(settings_string)
		if !parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", settings_string, " at line ", json.get_error_line())
			continue
		var node_data = json.data
		if "starting_moves" in node_data:
			starting_moves = node_data["starting_moves"]
		if "common_timeout" in node_data:
			common_timeout = node_data["common_timeout"]
	
func save_settings() -> void:
	var settings_dict = {
		"starting_moves": starting_moves,
		"common_timeout": common_timeout
	}
	var save_file = FileAccess.open(SETTINGS_FILE,FileAccess.WRITE)
	save_file.store_line( JSON.stringify(settings_dict) )
