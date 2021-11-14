extends KinematicBody2D

var player_data = {
	"char": "male1"
}

var dir := "down"
var _move_sprites = {
	"down": 0,
	"left": 1,
	"up": 2,
	"right": 3,
}
var _ray_rotation = {
	"down": 0,
	"left": -270,
	"up": -180,
	"right": -90,
}

func _ready() -> void:
	_update_sprite()
	# Set the initial look to down
	_update_look_dir(dir)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_down"):
		make_move("down")
	elif event.is_action_pressed("move_up"):
		make_move("up")
	elif event.is_action_pressed("move_left"):
		make_move("left")
	elif event.is_action_pressed("move_right"):
		make_move("right")

func _update_look_dir(look_dir: String) -> void:
	$Sprite.frame = _move_sprites[look_dir]
	$RayCast2D.rotation_degrees = _ray_rotation[look_dir]

func _update_sprite():
	$Sprite.texture = Globals.player_sprites[player_data.char]

func make_move(dir: String) -> void:
	_update_look_dir(dir)

	# Test move in the dir
	$RayCast2D.force_raycast_update()
	if $RayCast2D.is_colliding():
		return

	var move_dir: Vector2 = Globals.dir[dir] * Globals.tile_size
	global_translate(move_dir)

func set_player_data(new_player_data: Dictionary):
	player_data = new_player_data
	_update()

func _update():
	$Viewport/NameValue.text = str(player_data.tag)
	_update_sprite()
