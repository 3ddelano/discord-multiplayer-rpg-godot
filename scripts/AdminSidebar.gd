extends PanelContainer

signal settoken_pressed

var is_animating = false
var is_open = true
onready var tween = $Tween

func _ready() -> void:
	tween.connect("tween_completed", self, "_on_tween_completed")

	$MC/VB/SetTokenButton.connect("pressed", self, "_on_settoken_pressed")

func _on_settoken_pressed():
	emit_signal("settoken_pressed")

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_sidebar"):
		toggle_sidebar()

func toggle_sidebar():
	if is_animating:
		return
	is_animating = true

	var open_pos = Vector2(OS.get_window_safe_area().end.x, 0) - Vector2(get_size().x,0)
	if is_open:
		tween.interpolate_property(self, "rect_position", get_position(), open_pos + Vector2(get_size().x, 0), 0.2, Tween.TRANS_EXPO, Tween.EASE_IN)
	else:
		tween.interpolate_property(self, "rect_position", get_position(), open_pos, 0.2, Tween.TRANS_EXPO, Tween.EASE_IN)

	tween.start()


func _on_tween_completed(object, key):
	is_open = !is_open
	is_animating = false
