extends Node2D

#state
enum {wait, move, menu, end}
var state
var menu_pop_state
var max_match_size_in_turn = 0
var turn_in_progress = false

# grid variables
@export var width:int
@export var height:int
@export var x_start:int
@export var y_start:int
@export var offset:int
@export var y_offset:int
@export var starting_moves:int
var board_size_max:int
var board_size_current:int = 0

# grid pieces
var all_pieces = []
var possible_pieces = [
	preload("res://scenes/piece_01_copper.tscn"),
	preload("res://scenes/piece_02_blue.tscn"),
	preload("res://scenes/piece_03_gold.tscn"),
	preload("res://scenes/piece_04_bag.tscn")
];
var upgrade_path = [
	preload("res://scenes/piece_01_copper.tscn"),
	preload("res://scenes/piece_02_blue.tscn"),
	preload("res://scenes/piece_03_gold.tscn"),
	preload("res://scenes/piece_04_bag.tscn"),
	preload("res://scenes/piece_05_chest.tscn"),
	preload("res://scenes/piece_06_green_chest.tscn"),
	preload("res://scenes/piece_07_red_chest.tscn"),
	preload("res://scenes/piece_08_vault.tscn")
];
const Match3Core = preload("res://scripts/match3core.gd")
const pause_menu_scene = preload("res://scenes/pause.tscn")

# touch variables
var touch_start = Vector2(0,0)
var touch_end = Vector2(0,0)
var controlling = false

# UI and moves
var current_move
var current_move_label
var moves_remaining
var moves_remaining_label

# timing
@export var common_timeout:float = 0.05

func _ready():
	# use starting moves from global settings instead of property here
	starting_moves = GlobalSettings.starting_moves
	# use common_timeout from global settings
	common_timeout = GlobalSettings.common_timeout
	state = move
	all_pieces = make_2d_array()
	# set board size
	board_size_max = width * height;
	spawn_pieces()
	# set starting score and counter
	moves_remaining = starting_moves
	current_move = 1
	current_move_label = get_parent().get_node("CanvasLayer/CurrentMoveLabel")
	moves_remaining_label = get_parent().get_node("CanvasLayer/MovesRemainingLabel")
	update_ui()

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func spawn_pieces():
	board_size_current = 0;
	for i in width:
		for j in height:
			var piece = possible_pieces[randi() % possible_pieces.size()].instantiate()
			var loops = 0
			while (match_at(i,j,piece.identifier) && loops < 100):
				piece = possible_pieces[randi() % possible_pieces.size()].instantiate()
				loops += 1
			add_child(piece)
			piece.position = grid_to_pixel(i,j)
			piece.set_coords(i,j)
			all_pieces[i][j] = piece
			board_size_current += 1

func match_at(i,j,piece_id):
	if i > 1:
		if all_pieces[i-1][j] != null && all_pieces[i-2][j]:
			if all_pieces[i-1][j].identifier == piece_id && all_pieces[i-2][j].identifier == piece_id:
				return true
	if j > 1:
		if all_pieces[i][j-1] != null && all_pieces[i][j-2]:
			if all_pieces[i][j-1].identifier == piece_id && all_pieces[i][j-2].identifier == piece_id:
				return true
	return false

func grid_to_pixel(column,row):
	return Vector2(x_start + offset * column, y_start + -offset * row)

func pixel_to_grid(pixel_x,pixel_y):
	return Vector2(round((pixel_x - x_start) / offset), round((pixel_y - y_start) / -offset))

func is_in_grid(grid_position):
	return grid_position.x >= 0 && grid_position.x < width && grid_position.y >= 0 && grid_position.y < height

func change_piece_to_type(grid_pos: Vector2i, type_num: int):
	# Safety checks
	if grid_pos.x < 0 or grid_pos.x >= width or grid_pos.y < 0 or grid_pos.y >= height:
		print("Invalid grid position: ", grid_pos)
		return
	if type_num < 1 or type_num > upgrade_path.size():
		print("Invalid type number: ", type_num)
		return

	# Remove current piece
	var old_piece = all_pieces[grid_pos.x][grid_pos.y]
	if old_piece != null:
		old_piece.queue_free()

	# Instantiate new piece
	var piece = upgrade_path[type_num - 1].instantiate()
	add_child(piece)
	piece.position = grid_to_pixel(grid_pos.x, grid_pos.y)
	piece.set_coords(grid_pos.x, grid_pos.y)
	all_pieces[grid_pos.x][grid_pos.y] = piece

	print("Changed piece at ", grid_pos, " to type ", piece.identifier)

# this needs to run the same check as find_matches()
func test_for_matches():
	var candidates = Match3Core.get_candidate_matches_as_arrays(all_pieces, width, height, Match3Core.default_cmp)
	var match_data = Match3Core.get_most_valuable_match(candidates)
	return match_data["type"] != Match3Core.MatchType.NO_MATCH

func swap_pieces(grid_pos, direction):
	var first_piece = all_pieces[grid_pos.x][grid_pos.y]
	var other_piece = all_pieces[grid_pos.x + direction.x][grid_pos.y + direction.y]

	if first_piece != null && other_piece != null:
		# update state to prevent movement during piece match chain 
		if state != end:
			state = wait;
		
		# --- Perform temporary swap ---
		all_pieces[grid_pos.x][grid_pos.y] = other_piece
		all_pieces[grid_pos.x + direction.x][grid_pos.y + direction.y] = first_piece

		# Update piece coordinates for match checking
		var temp_coords = first_piece.coords
		first_piece.set_coords(other_piece.coords.x, other_piece.coords.y)
		other_piece.set_coords(temp_coords.x, temp_coords.y)

		# Call match detection to test if swap results in a match
		# also ensure that neither piece involved is !is_movable
		var matches_exist = first_piece.is_movable && other_piece.is_movable && test_for_matches()

		if matches_exist:
			# keep track of the turn progression
			turn_in_progress = true;
			max_match_size_in_turn = 0;
			# If valid match, commit the swap visually and logically
			first_piece.move(grid_to_pixel(grid_pos.x + direction.x, grid_pos.y + direction.y))
			other_piece.move(grid_to_pixel(grid_pos.x, grid_pos.y))
			# Update timestamps
			first_piece.update_touch_timestamp();
			other_piece.update_touch_timestamp();

			print("manual trigger for find_matches");
			await get_tree().create_timer(common_timeout).timeout;
			find_matches();
		else:
			# Invalid move; revert swap
			all_pieces[grid_pos.x][grid_pos.y] = first_piece
			all_pieces[grid_pos.x + direction.x][grid_pos.y + direction.y] = other_piece

			# Revert coords
			other_piece.set_coords(other_piece.coords.x, other_piece.coords.y)
			first_piece.set_coords(first_piece.coords.x, first_piece.coords.y)
			
			# Clear timestamps
			other_piece.clear_touch_timestamp();
			first_piece.clear_touch_timestamp();

			# we either shake the moved piece or do a swap-back
			if other_piece == null || other_piece == first_piece:
				first_piece.shake();
			else:
				first_piece.move(grid_to_pixel(grid_pos.x + direction.x, grid_pos.y + direction.y));
				other_piece.move(grid_to_pixel(grid_pos.x, grid_pos.y));
				other_piece.move(grid_to_pixel(grid_pos.x + direction.x, grid_pos.y + direction.y));
				first_piece.move(grid_to_pixel(grid_pos.x, grid_pos.y));
				first_piece.shake();
				other_piece.shake();
				
			# allow movement after indication of invalid move
			if state != end:
				state = move;

func get_direction(st,en):
	var difference = en - st
	if abs(difference.x) > abs(difference.y):
		return Vector2(sign(difference.x),0)
	elif abs(difference.y) > abs(difference.x):
		return Vector2(0,sign(difference.y))
	return Vector2(0,0)

func touch_difference(st,en):
	swap_pieces(st,get_direction(st,en))

# dedupe an array
func get_unique(arr: Array) -> Array:
	var seen = {}
	var result = []
	for v in arr:
		if not seen.has(v):
			seen[v] = true
			result.append(v)
	return result

# ----------------
# MATCH DETECTION
# ----------------

# match3core version
func find_matches():
	var candidates = Match3Core.get_candidate_matches_as_arrays(all_pieces, width, height, Match3Core.default_cmp)
	var match_data = Match3Core.get_most_valuable_match(candidates)
	print(match_data)

	if match_data["type"] != Match3Core.MatchType.NO_MATCH:
		var group = match_data["pieces"]
		var key_piece = match_data["key_piece"]
		var matched_pieces = []

		# Mark all pieces as matched and dim
		for piece in group:
			if piece != null:
				piece.matched = true
				piece.dim()
				matched_pieces.append(piece)

		# Mark key piece
		if key_piece != null:
			key_piece.key_match = true

		# dedupe the matched pieces to get a count for scoring
		var matched_size = get_unique(matched_pieces).size()
		print("Matched size is " + str(matched_size))
		if matched_size > max_match_size_in_turn:
			max_match_size_in_turn = matched_size

		print("manual trigger for upgrade/destroy");
		await get_tree().create_timer(common_timeout).timeout;
		upgrade_and_destroy()
	else:
		print("manual trigger for collapse")
		await get_tree().create_timer(common_timeout).timeout;
		board_scan_reset()
		collapse_colums()

func upgrade_and_destroy():
	var upgrade_happened = false;
	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece != null and piece.matched:
				var is_movable = piece.is_movable
				var upgrade_index = piece.upgrade_index

				if not piece.key_match:
					# destroy non-key pieces
					piece.queue_free()
					all_pieces[i][j] = null
					#board_size_current -= 1
				else:
					# upgrade key piece if movable
					piece.queue_free()
					if is_movable and upgrade_index + 1 < upgrade_path.size():
						var upgrade_piece = upgrade_path[upgrade_index + 1].instantiate();
						upgrade_piece.position = grid_to_pixel(i, j);
						upgrade_piece.set_coords(i, j);
						all_pieces[i][j] = upgrade_piece;
						add_child(upgrade_piece);
						upgrade_happened = true;
						#print("Upgraded piece at " + str(i) + "," + str(j) + " to " + upgrade_piece.identifier)
					else:
						# fallback if piece is not movable or max upgrade reached
						all_pieces[i][j] = null
						#board_size_current -= 1
						print("FALLBACK UNMOVABLE MAX UPGRADE -- WHAT IS HAPPENING ON BOARD????")

				# reset flags
				if all_pieces[i][j] != null:
					all_pieces[i][j].matched = false
					all_pieces[i][j].key_match = false
	if upgrade_happened:
		print("upgraded, waiting...")
		# reset before matching after the upgrade
		board_scan_reset()
		await get_tree().create_timer(common_timeout).timeout		# check for new matches on the upgraded piece
		find_matches();
	else:
		print("manual trigger for collapse")
		await get_tree().create_timer(common_timeout).timeout;
		board_scan_reset()
		collapse_colums()

func collapse_colums():
	#board_scan_reset();
	if board_size_current < board_size_max:
		#print("Collapsing columns")
		for i in width:
			for j in height:
				#if all_pieces[i][j] != null:
				#	all_pieces[i][j].clear_touch_timestamp();
				#else:
				if all_pieces[i][j] == null:
					for k in range(j+1,height):
						if all_pieces[i][k] != null:
							all_pieces[i][k].move( grid_to_pixel(i,j));
							all_pieces[i][j] = all_pieces[i][k];
							all_pieces[i][j].coords = Vector2(i,j);
							# clear temp/moving piece after assigned to landing place
							all_pieces[i][k] = null;
							break
		print("manual trigger for refill")
		await get_tree().create_timer(common_timeout).timeout;
		refill_columns()

	else:
		# APPLY SCORING HERE at end of turn
		if turn_in_progress:
			var score_diff = -1
			if max_match_size_in_turn == 4:
				score_diff = 0
			elif max_match_size_in_turn > 4:
				score_diff = 1
			moves_remaining += score_diff
			print("Turn completed. Largest match was " + str(max_match_size_in_turn) + ". Adding " + str(score_diff) + " to turns.")

			# Reset tracking
			turn_in_progress = false
			max_match_size_in_turn = 0
		#print("Collapse called but board is already full");
		current_move += 1
		print("Turn " + str(current_move))
		update_ui()
		if state != end:
			state = move;

# clear any touch timestamps and reset current board count
func board_scan_reset():
	board_size_current = 0;
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				board_size_current += 1
				all_pieces[i][j].clear_touch_timestamp();

func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# get random piece
				var piece = possible_pieces[randi() % possible_pieces.size()].instantiate();
				var loops = 0;
				while (match_at(i,j,piece.identifier) && loops < 100):
					#print("Found an existing match...");
					piece = possible_pieces[randi() % possible_pieces.size()].instantiate();
					loops += 1;
				#print("Creating piece at " + str(i) + "," + str(j));
				add_child(piece);
				piece.position = grid_to_pixel(i,j) - Vector2(0,y_offset);
				piece.move(grid_to_pixel(i,j));
				piece.set_coords(i,j);
				all_pieces[i][j] = piece;
				board_size_current += 1
	print("manual trigger for find_matches")
	await get_tree().create_timer(common_timeout).timeout;
	find_matches()

func touch_input():
	# normal game input
	if Input.is_action_just_pressed("ui_touch"):
		var mp = get_global_mouse_position()
		if is_in_grid(pixel_to_grid(mp.x,mp.y)):
			touch_start = pixel_to_grid(mp.x,mp.y)
			controlling = true
	if Input.is_action_just_released("ui_touch"):
		var mp = get_global_mouse_position()
		if is_in_grid(pixel_to_grid(mp.x,mp.y)):
			touch_end = pixel_to_grid(mp.x,mp.y)
			if controlling:
				controlling = false
				touch_difference(touch_start,touch_end)

	# dev stuff
	if Input.is_action_just_released("ui_devclick"):
		var mp = get_global_mouse_position()
		var grid_clicked = pixel_to_grid(mp.x,mp.y)
		print("Dev clicked on " + str(grid_clicked))
		# Check for number keys 1-8 (KEY_1 = 49 in Godot 4)
		for i in range(1, 9):
			if Input.is_key_pressed(KEY_0 + i):
				print("Number key " + str(i) + " held while dev clicking.")
				
				# Change piece at clicked coords to the specified type
				change_piece_to_type(grid_clicked, i)

func menu_check() -> void:
	if Input.is_action_just_pressed("ui_player_menu"):
		if state != menu:
			menu_open()
		else:
			menu_close()

func menu_open() -> void:
	# store state and open menu
	print("open menu")
	menu_pop_state = state
	state = menu
	var pause_menu = pause_menu_scene.instantiate();
	get_tree().get_root().add_child(pause_menu)
	pause_menu.connect("resume_clicked",_on_resume_clicked)

func menu_close() -> void:
	# restore state and close menu
	print("close menu")
	state = menu_pop_state
	menu_pop_state = null
	for node in get_tree().get_nodes_in_group("PauseMenu"):
		node.queue_free()

func _on_resume_clicked() -> void:
	menu_close()

func update_ui():
	if current_move_label != null:
		current_move_label.text = "Turn " + str(current_move)
	if moves_remaining_label != null:
		var moves_suffix = " turns left";
		if moves_remaining == 0:
			end_game();
		else:
			if moves_remaining == 1:
				moves_suffix = " turn left"
			moves_remaining_label.text = str(moves_remaining) + moves_suffix

func end_game():
	print("Game over");
	current_move_label.text = "Total: " + str(current_move)
	moves_remaining_label.text = "GAME OVER  "
	state = end;

func _process(_delta):
	if state == move:
		touch_input()
		
	menu_check()
