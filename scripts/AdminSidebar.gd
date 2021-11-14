extends PanelContainer

var is_animating = false
var is_open = true
onready var tween = $Tween
onready var open_pos = get_position()

func _ready() -> void:
	tween.connect("tween_completed", self, "_on_tween_completed")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_sidebar"):
		toggle_sidebar()

func toggle_sidebar():
	if is_animating:
		return
	is_animating = true

	print('toggling---')
	if is_open:
		print("closing")
		tween.interpolate_property(self, "rect_position", get_position(), open_pos + Vector2(get_size().x, 0), 0.2, Tween.TRANS_EXPO, Tween.EASE_IN)
	else:
		print("opening")
		tween.interpolate_property(self, "rect_position", get_position(), open_pos, 0.2, Tween.TRANS_EXPO, Tween.EASE_IN)

	tween.start()


func _on_tween_completed(object, key):
	print('------------------------')
	is_open = !is_open
	is_animating = false
