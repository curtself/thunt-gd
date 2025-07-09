extends Control
@onready var speed_options = $VBoxContainer/HBoxContainer2/speed_options as OptionButton
@onready var player_moves = $VBoxContainer/HBoxContainer/player_moves as LineEdit
const SPEEDS : Array[String] = [
	"Slow",
	"Normal",
	"Fast"
]
var us_starting_moves:int
var us_speed:float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_moves.text = str(GlobalSettings.starting_moves)
	us_speed = GlobalSettings.common_timeout
	add_speed_options()
	speed_options.item_selected.connect(on_speed_selected)

func add_speed_options() -> void:
	for mode in SPEEDS:
		speed_options.add_item(mode)
		if mode == GlobalSettings.common_timeout_label:
			speed_options.select(speed_options.item_count-1)
	pass

func on_speed_selected(index:int) -> void:
	match index:
		0: # slow speed
			GlobalSettings.common_timeout = 0.3
			GlobalSettings.common_timeout_label = "Slow"
		1: # normal speed
			GlobalSettings.common_timeout = 0.05
			GlobalSettings.common_timeout_label = "Normal"
		2: # fast speed
			GlobalSettings.common_timeout = 0.001
			GlobalSettings.common_timeout_label = "Fast"
	print("Speed chosen as " + str(index) + " with a value of " + str(GlobalSettings.common_timeout))
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func _on_menu_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	pass # Replace with function body.

func _on_player_moves_text_changed(new_text: String) -> void:
	print("Changing starting moves to " + new_text)
	GlobalSettings.starting_moves = int(new_text)
	pass # Replace with function body.
