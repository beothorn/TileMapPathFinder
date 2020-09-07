extends Node2D

var speed: float = 100.0
var path : = PoolVector2Array()

func _ready():
	set_process(false)

func _process(delta: float) -> void:
	var instant_speed : = speed * delta
	var original_position = $Player.position
	if path.size() == 0:
		set_process(false)
		return
	var next = path[0]
	var distance_to_next = $Player.position.distance_to(next)
	if instant_speed >= distance_to_next:
		$Player.position = next
		original_position = $Player.position
		path.remove(0)
		
		instant_speed -= distance_to_next
		if path.size() == 0:
			return
		while path.size() > 0 and next == path[0]:
			path.remove(0)
		next = path[0]
		distance_to_next = position.distance_to(next)
		
	if distance_to_next == 0:
		return
	
	$Player.position = $Player.position.linear_interpolate(next, instant_speed / distance_to_next)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		path = $TileMapPathFinder.find_path($Player.position, event.position)
		set_process(true)
