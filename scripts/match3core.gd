extends Node

enum MatchType {
	NO_MATCH,		# 0
	MATCH_3,		# 1
	MATCH_4,		# 2
	MATCH_5,		# 3
	MATCH_T,		# 4
	MATCH_L			# 5
}

## Converts x,y to flat index
static func xy_to_index(x: int, y: int, len_x: int) -> int:
	return y * len_x + x

## Converts flat index to x,y
static func index_to_xy(index: int, len_x: int) -> Vector2i:
	return Vector2i(index % len_x, index / len_x)

## Compares two pieces by identifier. also checks is_movable property
static func default_cmp(a, b) -> bool:
	return a != null and b != null and a.is_movable && b.is_movable and a.identifier == b.identifier

## Removes duplicates while preserving order
static func _remove_duplicates(arr: Array) -> Array:
	var seen = {}
	var result = []
	for v in arr:
		if not seen.has(v):
			seen[v] = true
			result.append(v)
	return result

## Returns candidate matches as sequences of matching pieces
static func get_candidate_matches_as_arrays(pieces, len_x, len_y, cmp_func) -> Array:
	var matches = []

	# Horizontal
	for j in len_y:
		var run = []
		for i in len_x:
			var piece = pieces[i][j]
			if run.size() == 0:
				run.append(piece)
			elif cmp_func.call(piece, run[0]):
				run.append(piece)
			else:
				if run.size() >= 3:
					matches.append(run.duplicate())
				run = [piece]
		if run.size() >= 3:
			matches.append(run.duplicate())

	# Vertical
	for i in len_x:
		var run = []
		for j in len_y:
			var piece = pieces[i][j]
			if run.size() == 0:
				run.append(piece)
			elif cmp_func.call(piece, run[0]):
				run.append(piece)
			else:
				if run.size() >= 3:
					matches.append(run.duplicate())
				run = [piece]
		if run.size() >= 3:
			matches.append(run.duplicate())

	return matches

## Finds N-length match
static func find_match_N(n, matches) -> Array:
	for m in matches:
		if m.size() >= n:
			return m
	return []

## Checks for T shape among horizontal and vertical sequences
static func find_match_T(sequence_h: Array, sequence_v: Array) -> Array:
	for mh in sequence_h:
		for mv in sequence_v:
			for hi in mh:
				if mv.has(hi):
					var combined = mh.duplicate()
					combined.append_array(mv)
					return _remove_duplicates(combined)
	return []

## Checks for L shape among horizontal and vertical sequences
static func find_match_L_BACKUP(sequence_h: Array, sequence_v: Array) -> Array:
	for mh in sequence_h:
		for mv in sequence_v:
			for hi in mh:
				for vi in mv:
					if hi == vi:
						continue
					var hx = hi.coords.x
					var hy = hi.coords.y
					var vx = vi.coords.x
					var vy = vi.coords.y
					if hx == vx or hy == vy:
						var combined = mh.duplicate()
						combined.append_array(mv)
						return _remove_duplicates(combined)
	return []

## Checks for L shape among horizontal and vertical sequences
static func find_match_L(sequence_h: Array, sequence_v: Array) -> Array:
	for mh in sequence_h:
		for mv in sequence_v:
			# Ensure both sequences have at least one piece
			if mh.size() == 0 or mv.size() == 0:
				continue
			# Check identifiers match before combining
			if mh[0].identifier != mv[0].identifier:
				continue
			for hi in mh:
				for vi in mv:
					if hi == vi:
						continue
					var hx = hi.coords.x
					var hy = hi.coords.y
					var vx = vi.coords.x
					var vy = vi.coords.y
					if hx == vx or hy == vy:
						var combined = mh.duplicate()
						combined.append_array(mv)
						return _remove_duplicates(combined)
	return []

## Returns the most valuable match with its type
static func get_most_valuable_match(matches: Array) -> Dictionary:
	var h_matches = []
	var v_matches = []
	for m in matches:
		if m.size() < 3:
			continue
		if abs(m[0].coords.x - m[1].coords.x) == 1:
			h_matches.append(m)
		elif abs(m[0].coords.y - m[1].coords.y) == 1:
			v_matches.append(m)

	var match_5 = find_match_N(5, matches)
	if not match_5.is_empty():
		return {"type": MatchType.MATCH_5, "pieces": match_5, "key_piece": match_5[int(match_5.size() / 2)]}

	var match_T = find_match_T(h_matches, v_matches)
	if not match_T.is_empty():
		return {
			"type": MatchType.MATCH_T, 
			"pieces": match_T, 
			"key_piece": get_key_piece_T(match_T)
		}

	var match_L = find_match_L(h_matches, v_matches)
	if not match_L.is_empty():
		return {"type": MatchType.MATCH_L, "pieces": match_L, "key_piece": match_L[int(match_L.size() / 2)]}

	var match_4 = find_match_N(4, matches)
	if not match_4.is_empty():
		return {
			"type": MatchType.MATCH_4, 
			"pieces": match_4, 
			#"key_piece": match_4[int(match_4.size() / 2)]
			"key_piece": get_key_piece(match_4)
		}

	var match_3 = find_match_N(3, matches)
	if not match_3.is_empty():
		return {
			"type": MatchType.MATCH_3, 
			"pieces": match_3, 
			#"key_piece": match_3[int(match_3.size() / 2)]
			"key_piece": get_key_piece(match_3)
		}

	return {"type": MatchType.NO_MATCH, "pieces": [], "key_piece": null}

# helper function to select the correct key piece
static func get_key_piece(pieces: Array):
	# Prioritize player-touched pieces
	for piece in pieces:
		if piece.touch_timestamp > 0:
			return piece
	# Fallback: return middle piece
	if pieces.size()==3:
		return pieces[1]
		
	return pieces[int(pieces.size() / 2)]
	
# helper to T shapes that can handle a 'bumpy' T shape
static func get_key_piece_T(pieces: Array):
	if pieces.size() == 6:
		# Prioritize player-touched pieces
		for piece in pieces:
			if piece.touch_timestamp > 0:
				return piece

	# Fallback: return interset point
	var x_set = {}
	var y_set = {}
	for piece in pieces:
		var xsk:String = str(piece.coords.x)
		var ysk:String = str(piece.coords.y)
		if x_set.get(xsk) == null:
			x_set[xsk] = 1
		else:
			x_set[xsk] = x_set[xsk]+1
			#x_set[piece.coords.x] += 1
			
		if y_set.get(ysk) == null:
			y_set[ysk] = 1
		else:
			y_set[ysk] = y_set[ysk]+1
			#y_set[piece.coords.y] += 1
	
	#print( x_set )
	#print( y_set )
	
	var xk = x_set.keys()
	var yk = y_set.keys()
	# custom descending sort by the number of times the x/y coords appear in the match
	xk.sort_custom(func(a,b): return x_set.get(a)>x_set.get(b))
	yk.sort_custom(func(a,b): return y_set.get(a)>y_set.get(b))
	#print( xk )
	#print( yk )
	var key_coords = Vector2(float(xk.front()),float(yk.front()))
	#print("Found most " + str(key_coords))
	for piece in pieces:
		if piece.coords == key_coords:
			#print("key using custom sort: " + piece.to_string())
			return piece

	# fall back to return middle of array
	return pieces[int(pieces.size() / 2)]
