extends Node

export(NodePath) var base_tile_map
export(int) var time_limit_in_millis = 600

signal path_finder_timeout

var tile_map: TileMap
var discarded: Array

func _ready():
	print(base_tile_map)
	tile_map = get_node(base_tile_map)

func find_path(initial_pos: Vector2, target_position: Vector2) -> PoolVector2Array:
	var start: Vector2 = _get_tile(initial_pos)
	var end: Vector2 = _get_tile(target_position)
	_reset_queue()
	discarded = []
	
	var starting_node = {
		"pos": start,
		"parent": null,
		"g": 0,
		"h": start.distance_to(end),
		"predicted": 0 + start.distance_to(end)
	}
	
	_insert(starting_node)
	
	var start_time = OS.get_ticks_msec()
	
	while(not _empty()):
		var current_time = OS.get_ticks_msec()
		if current_time - start_time > time_limit_in_millis:
			emit_signal("path_finder_timeout")
			return PoolVector2Array()
		var current_node = _del_min()
		if end.x == current_node.pos.x and end.y == current_node.pos.y:
			var new_path : PoolVector2Array = PoolVector2Array()
			while(current_node.parent):
				new_path.insert(0, current_node.pos)
				current_node = current_node.parent
			new_path.insert(0, current_node.pos)
			return new_path
			
		var new_possible_paths = _expand(current_node, end, tile_map)
		for i in new_possible_paths:
			_insert(i)
		discarded.append(current_node)
	
	return PoolVector2Array()

func _get_tile(position: Vector2) -> Vector2:
	var tile_pos_x : int = int(floor(position.x / tile_map.cell_size.x)) * tile_map.cell_size.x
	var tile_pos_y : int = int(floor(position.y / tile_map.cell_size.y)) * tile_map.cell_size.y
	return Vector2(tile_pos_x, tile_pos_y)

func _expand(
	node, 
	end_goal_pos: Vector2, 
	allowed_tiles: TileMap
) -> Array:
	var new_nodes = Array()
	
	var up = create_new_node(
		node, 
		Vector2(node.pos.x, node.pos.y - allowed_tiles.cell_size.y), 
		end_goal_pos, 
		allowed_tiles.cell_size.x, 
		allowed_tiles.cell_size.y
	)
	
	var down = create_new_node(
		node, 
		Vector2(node.pos.x, node.pos.y + allowed_tiles.cell_size.y), 
		end_goal_pos, 
		allowed_tiles.cell_size.x, 
		allowed_tiles.cell_size.y
	)
	
	var left = create_new_node(
		node, 
		Vector2(node.pos.x - allowed_tiles.cell_size.x, node.pos.y), 
		end_goal_pos, 
		allowed_tiles.cell_size.x, 
		allowed_tiles.cell_size.y
	)
	
	var right = create_new_node(
		node, 
		Vector2(node.pos.x + allowed_tiles.cell_size.x, node.pos.y), 
		end_goal_pos, 
		allowed_tiles.cell_size.x, 
		allowed_tiles.cell_size.y
	)
	
	if _is_allowed(up, allowed_tiles):
		new_nodes.append(up)
	if _is_allowed(down, allowed_tiles):
		new_nodes.append(down)
	if _is_allowed(left, allowed_tiles):
		new_nodes.append(left)
	if _is_allowed(right, allowed_tiles):
		new_nodes.append(right)
	
	return new_nodes
	
func _is_allowed(node, allowed_tiles: TileMap) -> bool:
	var tile_value = allowed_tiles.get_cell(
		node.pos.x / allowed_tiles.cell_size.x, 
		node.pos.y / allowed_tiles.cell_size.y
	) 
	if tile_value == -1:
		return false
		
	return _not_calculated_yet(node.pos)

func _not_calculated_yet(new_node) -> bool:
	for node in heaplist:
		if node.pos.x == new_node.x and node.pos.y == new_node.y:
			return false
	for node in discarded:
		if node.pos.x == new_node.x and node.pos.y == new_node.y:
			return false
	
	return true

func _nnode(
	parent, 
	new_total_travelled: float, 
	new_heuristic: float, 
	new_pos: Vector2
):
	return {
		"pos": new_pos,
		"parent": parent,
		"g": new_total_travelled,
		"h": new_heuristic,
		"predicted": new_total_travelled + new_heuristic
	}

func create_new_node(
	parent, 
	new_pos: Vector2, 
	end_goal_pos: Vector2,
	cell_size_x,
	cell_size_y
):
	var new_total_travelled = parent.g + new_pos.distance_to(parent.pos)
	var new_heuristic = new_pos.distance_to(end_goal_pos)
	return _nnode(
		parent, 
		new_total_travelled, 
		new_heuristic, 
		new_pos
	)

# Priority Queue ===============================================================

var heaplist : Array

func _reset_queue():
	heaplist = []

func _perc_up(i):
	while floor(i / 2) >= 0:
		if heaplist[i].predicted < heaplist[floor(i / 2)].predicted:
			var tmp = heaplist[floor(i / 2)]
			heaplist[floor(i / 2)] = heaplist[i]
			heaplist[i] = tmp
		else:
			return
		i = floor(i / 2)

func _insert(k):
	heaplist.append(k)
	_perc_up(heaplist.size() - 1)

func _perc_down(i):
	while (i * 2) + 1 < heaplist.size():
		var mc = _min_child(i)
		if heaplist[i].predicted > heaplist[mc].predicted:
			var tmp = heaplist[i]
			heaplist[i] = heaplist[mc]
			heaplist[mc] = tmp
		i = mc

func _min_child(i):
	if (i * 2) + 2 >= heaplist.size():
		return (i * 2) + 1
	else:
		if heaplist[(i * 2) + 1].predicted < heaplist[(i * 2) + 2].predicted:
			return (i * 2) + 1
		else:
			return (i * 2) + 2

func _del_min():
	var retval = heaplist.pop_front()
	if heaplist.size() == 0:
		return retval
	heaplist.append(heaplist.pop_back())
	_perc_down(0)
	return retval

func _empty():
	return heaplist.empty()
