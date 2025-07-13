extends Control

var high_score_label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	high_score_label = get_node("Panel/MarginContainer/VBoxContainer/high_score_label")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass


func _on_home_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	#self.queue_free()
