extends Node2D
@onready var sprite = $Sprite2D;
@export var identifier: String = "Base";
@export var upgrade_index = -1;
@export var is_movable: bool = true;
var move_tween;
var shake_tween;
var matched = false;
var key_match = false;
var coords = Vector2(0,0);
var touch_timestamp: int = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass;
	
func set_coords(column,row):
	coords = Vector2(column,row);
	
func move(target):
	move_tween = sprite.create_tween();
	move_tween.tween_property(self,"position",target, 
		0.3).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT);

func shake():
	print("shaking")
	shake_tween = create_tween();
	#shake_tween.stop();
	#var original_position = position;
	var shake_amount = 3;
	var duration = 0.05;

	shake_tween.tween_property(self, "position:x", position.x - shake_amount, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_property(self, "position:y", position.y + shake_amount, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_property(self, "position:x", position.x + shake_amount, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_property(self, "position:y", position.y - shake_amount, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_property(self, "position:x", position.x, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	shake_tween.tween_property(self, "position:y", position.y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func dim():
	sprite.modulate = Color(1,1,1,0.5);

func update_touch_timestamp():
	touch_timestamp = Time.get_ticks_msec();

func clear_touch_timestamp():
	touch_timestamp = 0;

# print friendly view
func _to_string():
	return "[" + str(coords.x) + "," + str(coords.y) + "]:" + identifier

# persist data
func save() -> void:
	var save_dict = {
		"filename": get_scene_file_path(),
		"parent": get_parent().get_path(),
		"pos_x": position.x,
		"pos_y": position.y,
		"coords_x": coords.x,
		"coords_y": coords.y,
		"identifier": identifier,
		"touch_timestamp": touch_timestamp
	}
	pass
