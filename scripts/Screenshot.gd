tool
extends ViewportContainer

var your_custom_size = Vector2(128, 128)

func _init():
	if Engine.is_editor_hint():
		$Viewport.connect('size_changed', self, '_on_viewport_size_changed')
		change_viewport_size()

func _on_viewport_size_changed():
	change_viewport_size()

func change_viewport_size():
	set_size($Viewport.get_child(0).get_size())
	$Viewport.set_size($Viewport.get_child(0).get_size())
#	$Viewport.set_size_override(true, your_custom_size)
#	$Viewport.set_size_override_stretch(true)

func add_scene(scene):
	$Viewport.add_child(scene)
	change_viewport_size()
