extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_resume_button_pressed() -> void:
	# this will need to hide/destroy itself
	pass 


func _on_settings_button_pressed() -> void:
	# bring up the settings menu after saving state
	pass

func _on_home_button_pressed() -> void:
	# save state and change scene to ui_menu
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	pass
