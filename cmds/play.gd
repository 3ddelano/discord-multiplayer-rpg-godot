extends Command

var buttons = {
	"left": MessageButton.new().set_style(MessageButton.STYLES.PRIMARY).set_label("Left").set_custom_id("btn_left"),
	"right": MessageButton.new().set_style(MessageButton.STYLES.PRIMARY).set_label("Right").set_custom_id("btn_right"),
	"up": MessageButton.new().set_style(MessageButton.STYLES.PRIMARY).set_label("Up").set_custom_id("btn_up"),
	"down": MessageButton.new().set_style(MessageButton.STYLES.PRIMARY).set_label("Down").set_custom_id("btn_down"),
	"dis1": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label(".").set_custom_id("dis1").set_disabled(true),
	"dis2": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label(".").set_custom_id("dis2").set_disabled(true),
	"current_players": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label(".").set_custom_id("current_players").set_disabled(true),
}

var rows = {
	# For movement buttons
	"move1": MessageActionRow.new().add_component(buttons.dis1).add_component(buttons.up).add_component(buttons.dis2),
	"move2": MessageActionRow.new().add_component(buttons.left).add_component(buttons.down).add_component(buttons.right),

	# For number of active players
	"calculated": MessageActionRow.new().add_component(buttons.current_players),
}

func on_ready(world, bot: DiscordBot):
	world.connect("interaction_create", self, "on_interaction_create")

func on_message(world, bot: DiscordBot, message: Message, channel: Dictionary, args: Array) -> void:
	var uid = message.author.id
	var tag = message.author.username + "#" + message.author.discriminator

	if uid in world.current_players:
		# The user is already in a game
		bot.reply(message, "You are already playing the game!")
		return

	var player = world.player_scene.instance()
	player.name = uid

	# Load previous data if not ask to make a new character
	var player_data = Data.get_player_data(uid)
	if not player_data:
		bot.reply(message, "You have not setup your character. Use `.setup` to setup.")
		return

	player_data["tag"] = tag
	player.set_player_data(player_data)
	player.global_position = world.spawn_point.global_position
	world.players_node.add_child(player)
	yield(world.get_tree(), "idle_frame")

	print("Player Joined: " + tag + " (" + uid + ")")
	world.current_players.append(uid)

	var bytes = yield(_get_player_image_bytes(world, uid), "completed")
	var embed = Embed.new().set_image("attachment://screenshot.png").set_title("Delano's RPG").set_description("Press the buttons to play").set_footer("Requested by " + tag).set_timestamp().set_color("#f2b210")

	var msg = yield(bot.send(message, {
		"embeds": [embed],
		"files": [{
			"name": "screenshot.png",
			"media_type": "image/png",
			"data": bytes
		}],
		"components": _make_game_components(world)
	}), "completed")
	world.interactions[msg.id] = {
		"type": "games",
		"author_id": uid,
		"edit_slug": "/channels/%s/messages/%s" % [msg.channel_id, msg.id],
		"last_time": OS.get_ticks_msec(),

		"author_tag": tag
	}

func on_interaction_create(world, bot: DiscordBot, interaction: DiscordInteraction, data: Dictionary) -> void:
	var msg_id = interaction.message.id
	var custom_id = interaction.data.custom_id

	# If its not a valid games interaction, we return
	if not data.type == "games":
		return

	# Check to see the author is the game author
	if not interaction.member.user.id == data.author_id:
		interaction.reply({
			"ephemeral": true,
			"content": "Not allowed. You are not the player of the game."
		})
		return

	var player_node: KinematicBody2D = world.players_node.get_node(data.author_id)

	match custom_id:
		"btn_left":
			player_node.make_move("left")
		"btn_right":
			player_node.make_move("right")
		"btn_up":
			player_node.make_move("up")
		"btn_down":
			player_node.make_move("down")

	var new_msg_data = yield(_make_game_embed(world, player_node), "completed")
	interaction.defer_update()
	world.interactions[msg_id].last_time = OS.get_ticks_msec()
	yield(bot.edit(interaction.message, new_msg_data), "completed")
	return

func _get_player_image_bytes(world, player_id_or_node) -> PoolByteArray:
	var player: KinematicBody2D
	if typeof(player_id_or_node) == TYPE_STRING:
		player = world.players_node.get_node(player_id_or_node)
	else:
		player = player_id_or_node

	var view_rect := Rect2(player.get_global_transform_with_canvas().origin - Globals.half_view_size, Globals.half_view_size * 2)

	yield(VisualServer, "frame_post_draw")
	var image: Image = world.get_viewport().get_texture().get_data()
	image.flip_y()
	image = image.get_rect(view_rect)
	return image.save_png_to_buffer()

func _make_game_components(world):
	for component in rows.calculated.components:
		if component.custom_id == "current_players":
			component.set_label("P: " + str(world.current_players.size()))
	return [rows.move1, rows.move2, rows.calculated]

func _make_game_embed(world, player_node: KinematicBody2D):
	var random_file_name = str(randi() % 4096)

	var bytes = yield(_get_player_image_bytes(world, player_node), "completed")
	var embed = Embed.new().set_title("Delano's RPG").set_description("Press the buttons to play").set_image("attachment://" + random_file_name + ".png").set_footer("Requested by " + player_node.player_data.tag).set_timestamp().set_color("#f2b210")

	return {
		"files": [{
			"name": random_file_name+".png",
			"media_type": "image/png",
			"data": bytes
		}],
		"attachments": [],
		"components": _make_game_components(world),
		"embeds": [embed]
	}

func get_usage(p: String) -> String:
	return "`%splay`" % p

var help = {
	"name": "play",
	"category": "Game",
	"aliases": ["p"],
	"enabled": true,
	"description": "Play the game"
}
