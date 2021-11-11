extends Node2D

const tile_size := 32
var player_image_resolution = 256
var half_view_size = Vector2(player_image_resolution, player_image_resolution) / 2

var dir := {
	"up": Vector2(0, -1),
	"right": Vector2(1, 0),
	"down": Vector2(0, 1),
	"left": Vector2(-1, 0)
}

var screenshot_threads = []

func take_screenshot(viewport: Viewport, view_rect := Rect2()) -> void:
	var start_epoch = OS.get_ticks_msec()
	yield(VisualServer, "frame_post_draw")
	var image: Image = viewport.get_texture().get_data()
	image.flip_y()

	if view_rect:
		print("Original image tile_size was ", image.get_size() / tile_size)
		image = image.get_rect(view_rect)
		print("New image tile_size is ", image.get_size() / tile_size)

	# warning-ignore:return_value_discarded
	image.save_png("res://screenshot.png")
	print("\nSaved screenshot took " + str(OS.get_ticks_msec() - start_epoch) + "ms")

func _exit_tree() -> void:
	for thread in screenshot_threads:
		thread.wait_to_finish()

static func merge_dir(target, patch):
	for key in patch:
		if target.has(key):
			var tv = target[key]
			if typeof(tv) == TYPE_DICTIONARY:
				merge_dir(tv, patch[key])
			else:
				target[key] = patch[key]
		else:
			target[key] = patch[key]


static func millis_to_string(millis: int) -> String:
	var days = -1
	# warning-ignore:integer_division
	days = int(millis / 86400000)
	millis -= days * 86400000

	var hours = -1
	# warning-ignore:integer_division
	hours = int(millis / 3600000)
	millis -= hours * 3600000

	var minutes = -1
	# warning-ignore:integer_division
	minutes = int(millis / 60000)
	millis -= minutes * 60000

	var seconds = -1
	# warning-ignore:integer_division
	seconds = int(millis / 1000)
	millis -= seconds * 1000

	var ret = []
	if days:
		if days == 1:
			ret.append(str(days) + " day")
		else:
			ret.append(str(days) + " days")
	if hours:
		if hours == 1:
			ret.append(str(hours) + " hour")
		else:
			ret.append(str(hours) + " hours")
	if minutes:
		if minutes == 1:
			ret.append(str(minutes) + " minute")
		else:
			ret.append(str(minutes) + " minutes")
	if seconds:
		if seconds == 1:
			ret.append(str(seconds) + " second")
		else:
			ret.append(str(seconds) + " seconds")


	return PoolStringArray(ret).join(', ')
