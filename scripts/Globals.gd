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

var player_sprites = {
	"male1": preload("res://assets/character/george.png"),
	"male2": preload("res://assets/character/dante_1.png"),
	"male3": preload("res://assets/character/dante_0_0_0.png"),
	"female1": preload("res://assets/character/betty.png"),
	"female2": preload("res://assets/character/ada_0_0_0.png"),
}

var screenshot_threads = []

#func take_screenshot(viewport: Viewport, view_rect := Rect2()) -> void:
#	var start_epoch = OS.get_ticks_msec()
#	yield(VisualServer, "frame_post_draw")
#	var image: Image = viewport.get_texture().get_data()
#	image.flip_y()
#
#	if view_rect:
#		image = image.get_rect(view_rect)
#
#	image.save_png("res://screenshot.png")
#	print("\nSaved screenshot took " + str(OS.get_ticks_msec() - start_epoch) + "ms")

#func _exit_tree() -> void:
#	for thread in screenshot_threads:
#		thread.wait_to_finish()

static func merge_dict(target, patch) -> Dictionary:
	var ret = target.duplicate(true)
	for key in patch:
		if target.has(key):
			ret[key] = patch[key]
	return ret

# Return those key,value pairs from first that are not there in second
static func diff_dict(first, second) -> Dictionary:
	var ret = {}
	for key in first:
		if second.has(key) and first[key] == second[key]:
			continue
		ret[key] = first[key]
	return ret

static func millis_to_string(millis: int) -> String:
	var days = -1
	days = int(millis / 86400000)
	millis -= days * 86400000

	var hours = -1
	hours = int(millis / 3600000)
	millis -= hours * 3600000

	var minutes = -1
	minutes = int(millis / 60000)
	millis -= minutes * 60000

	var seconds = -1
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

static func player2id(id_or_node) -> String:
	if not typeof(id_or_node) == TYPE_STRING:
		if id_or_node is KinematicBody2D:
			id_or_node = id_or_node.name
		else:
			assert(false, id_or_node + " couldn't be resolved to a Player id.")
	return id_or_node
