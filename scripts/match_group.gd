# MatchGroup.gd
extends Object
class_name MatchGroup;

var pieces: Array
var key_piece;
# these are auto-keys
var touch_start;
var touch_end;
enum shape { match3_h, match3_v, match_t, match_l, 
	match_lt, match4_h, match4_v, match5_h, match5_v
};

func _init(st,en):
	pieces = []
	if st != null:
		touch_start = st;
	if en != null:
		touch_end = en;

func add_piece(piece):
	pieces.append(piece)

# dedupe an array
func get_unique(arr: Array) -> Array:
	var seen = {}
	var result = []
	for v in arr:
		if not seen.has(v):
			seen[v] = true
			result.append(v)
	return result

func determine_key_piece():
	if pieces.size() == 0:
		key_piece = null
		return

	# Sort pieces by grid position for consistent logic
	# We'll use coords.x and coords.y
	# First, find if pieces form a line horizontally or vertically
	var all_x = []
	var all_y = []
	for p in pieces:
		all_x.append(p.coords.x)
		all_y.append(p.coords.y)
	all_x.sort()
	all_y.sort()

	var unique_x = all_x.duplicate()
	unique_x = get_unique(unique_x)
	var unique_y = all_y.duplicate()
	unique_y = get_unique(unique_y)

	if unique_y.size() == 1:
		# Horizontal line
		key_piece = get_horizontal_key_piece();
	elif unique_x.size() == 1:
		# Vertical line
		key_piece = get_vertical_key_piece()
	else:
		# Likely an L or T shape — detect and pick intersection
		key_piece = get_l_t_key_piece()

func get_horizontal_key_piece():
	# First see if there is a touch timestamp to indicate a user action
	pieces.sort_custom(Callable(self,"_sort_by_touch_timestamp"));
	var is_user_touch = false;
	for x in pieces.size():
		#print("Piece: " + str(pieces[x].coords) + ", t: " + str(pieces[x].touch_timestamp));
		if touch_start != null && pieces[x].coords.x == touch_start.x && pieces[x].coords.y == touch_start.y:
			return pieces[x];
		if touch_end != null && pieces[x].coords.x == touch_end.x && pieces[x].coords.y == touch_end.y:
			return pieces[x];
		if( pieces[x].touch_timestamp > 0):
			is_user_touch = true;
	if is_user_touch:
		# For user touch always pick the piece that was moved in the match
		return pieces[0];
	else:
		# For CASCADING horizontal line, pick middle piece left->right by x
		pieces.sort_custom(Callable(self, "_sort_by_x"))
		#print("Match sorted by X ======");
		#for x in pieces.size():
			#print("Piece: " + str(pieces[x].coords) + ", t: " + str(pieces[x].touch_timestamp));
		var mid_index = pieces.size() / 2
		#print("Mid-index chosen as " + str(mid_index) + " from size " + str(pieces.size()))
		if pieces.size() == 4:
			# Pick second piece for 4-piece matches (index 1)
			return pieces[1]
		else:
			return pieces[mid_index]

func get_vertical_key_piece():
	# First see if there is a touch timestamp to indicate a user action
	pieces.sort_custom(Callable(self,"_sort_by_touch_timestamp"));
	var is_user_touch = false;
	for y in pieces.size():
		if touch_start != null && pieces[y].coords.x == touch_start.x && pieces[y].coords.y == touch_start.y:
			return pieces[y];
		if touch_end != null && pieces[y].coords.x == touch_end.x && pieces[y].coords.y == touch_end.y:
			return pieces[y];
		#print("Piece: " + str(pieces[y].coords) + ", t: " + str(pieces[y].touch_timestamp));
		if( pieces[y].touch_timestamp > 0):
			is_user_touch = true;
	if is_user_touch:
		# For user touch always pick the piece that was moved in the match
		return pieces[0];
	else:
		# For CASCADING vertical line, pick middle piece top->bottom by y
		pieces.sort_custom(Callable(self, "_sort_by_y"))
		#print("Match sorted by Y ======");
		#for y in pieces.size():
		#	print("Piece: " + str(pieces[y].coords) + ", t: " + str(pieces[y].touch_timestamp));

		var mid_index = pieces.size() / 2
		#print("Mid-index chosen as " + str(mid_index) + " from size " + str(pieces.size()))
		if pieces.size() == 4:
			# Pick second piece for 4-piece matches (index 1)
			return pieces[1]
		else:
			return pieces[mid_index]

func get_l_t_key_piece():
	# For L or T shape, pick the intersection point
	# The intersection is piece that shares both x and y coordinates of other pieces
	# Build maps of coords -> pieces
	var by_x = {}
	var by_y = {}
	for p in pieces:
		by_x[p.coords.x] = by_x.get(p.coords.x, []) + [p]
		by_y[p.coords.y] = by_y.get(p.coords.y, []) + [p]

	# Find piece(s) where coords.x is in multiple pieces and coords.y is in multiple pieces
	for p in pieces:
		if by_x[p.coords.x].size() > 1 and by_y[p.coords.y].size() > 1:
			return p  # intersection piece found

	# Fallback: if no intersection found, pick most recent touched piece (by timestamp)
	pieces.sort_custom(Callable(self, "_sort_by_touch_timestamp"))
	return pieces[0]

# Sorting helpers

func _sort_by_x(a, b):
	return a.coords.x < b.coords.x

func _sort_by_y(a, b):
	return a.coords.y < b.coords.y

func _sort_by_touch_timestamp(a, b):
	return b.touch_timestamp < a.touch_timestamp  # descending

func mark_matches():
	for p in pieces:
		p.matched = true
		p.dim()
	if key_piece != null:
		key_piece.key_match = true

func _to_string():
	var s = "[MatchGroup: "
	s += "key_piece=" + (str(key_piece.coords) if key_piece != null else "null")
	s += ", pieces=["
	for p in pieces:
		s += str(p.coords) + ","
	s = s.rstrip(",")
	s += "]]"
	return s
