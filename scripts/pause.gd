extends Control

signal resume_clicked
signal home_clicked
signal settings_clicked

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass

func _on_resume_button_pressed() -> void:
	# this will need to hide/destroy itself
	emit_signal("resume_clicked")

func _on_settings_button_pressed() -> void:
	# just pass control back to game script to handle saving state and changing scenes
	emit_signal("settings_clicked")

func _on_home_button_pressed() -> void:
	# save state and change scene to ui_menu
	print("not going home yet, just trying to save state...")
	emit_signal("home_clicked")
	#get_tree().change_scene_to_file("res://scenes/menu.tscn")
