extends Node2D

var screenshot_scene = preload("res://scenes/Screenshot.tscn")

func take_screenshot(scene) -> PoolByteArray:
	# Add the screenshot scene instance
	var instance = screenshot_scene.instance()
	add_child(instance)
	# Add the scene to the viewport of the screenshot scene
	instance.add_scene(scene)
	yield(VisualServer, "frame_post_draw")
	var image = instance.get_node("Viewport").get_texture().get_data()
	image.flip_y()
	instance.queue_free()
	return image.save_png_to_buffer()
