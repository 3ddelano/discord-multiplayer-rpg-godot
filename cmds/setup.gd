extends Command

var buttons = {
	"setup_char_prev": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label("Prev").set_custom_id("setup_char_prev"),
	"setup_char_prev_dis": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label("Prev").set_custom_id("setup_char_prev_dis").set_disabled(true),
	"setup_char_accept": MessageButton.new().set_style(MessageButton.STYLES.SUCCESS).set_label("Select").set_custom_id("setup_char_accept"),
	"setup_char_next": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label("Next").set_custom_id("setup_char_next"),
	"setup_char_next_dis": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label("Next").set_custom_id("setup_char_next_dis").set_disabled(true),
}

func on_ready(world, bot: DiscordBot):
	world.connect("interaction_create", self, "on_interaction_create")

func on_message(world, bot: DiscordBot, message: Message, channel: Dictionary, args: Array) -> void:
	var uid = message.author.id
	var tag = message.author.username + "#" + message.author.discriminator

	var player_data = PlayersData.get_player_data(uid)
	if player_data:
		bot.reply(message, "You have already setup your character.")
		return

	var data = {
		"type": "setup_char",
		"author_id": uid,
		"last_time": OS.get_ticks_msec(),
		"author_tag": tag,

		"page_idx": 0
	}
	var msg = yield(bot.reply(message, make_character_message(data)), "completed")
	data["edit_slug"] = "/channels/%s/messages/%s" % [msg.channel_id, msg.id]
	world.interactions[msg.id] = data

func on_interaction_create(world, bot: DiscordBot, interaction: DiscordInteraction, data: Dictionary) -> void:
	var msg_id = interaction.message.id
	var custom_id = interaction.data.custom_id

	# If its not a valid confirm_delete interaction, we return
	if not data.type == "setup_char":
		return

	if custom_id == "setup_char_prev":
		world.interactions[msg_id].page_idx -= 1
		world.interactions[msg_id].last_time = OS.get_ticks_msec()
		interaction.defer_update()
		bot.edit(interaction.message, make_character_message(data))
	elif custom_id == "setup_char_next":
		world.interactions[msg_id].page_idx += 1
		world.interactions[msg_id].last_time = OS.get_ticks_msec()
		interaction.defer_update()
		bot.edit(interaction.message, make_character_message(data))
	elif custom_id =="setup_char_accept":
		#interaction.defer_update()
		var new_msg_data = make_character_message(data)
		new_msg_data.components = []
		bot._send_request(data.edit_slug, {
			"components": []
		}, HTTPClient.METHOD_PATCH)
		world.interactions[msg_id].last_time = OS.get_ticks_msec()
		var player_data = PlayersData.default_player_data.duplicate(true)
		var count = 0
		for sprite_name in Globals.player_sprites.keys():
			if count == data.page_idx:
				player_data.char = sprite_name
			count += 1
		# Save the character index, obtained from the data.page_idx to the player_data
		PlayersData.save_player_data(world.interactions[msg_id].author_id, player_data)
		interaction.reply({
			"content": "Your character was created successfully."
		})

func make_character_message(data: Dictionary) -> Dictionary:
	var random_file_name = str(randi() % 4096)
	var num_sprites = Globals.player_sprites.size()

	var embed = Embed.new().set_title("Character Creation").set_timestamp().set_footer(str(data.page_idx + 1) + "/" + str(num_sprites) + " | Requested by " + data.author_tag).set_color("#f2b210").set_description("Choose your character\n\n**Buttons**\nPrev / Next - Browse the avaialble characters\nSelect - Select the character.")

	embed.set_image("attachment://" + random_file_name + ".png")
	var bytes

	var count = 0
	for sprite_texture in Globals.player_sprites.values():
		if count == data.page_idx:
			var image = sprite_texture.get_data().get_rect(Rect2(Vector2(7, 11), Vector2(36, 32)))
			bytes = image.save_png_to_buffer()
		count += 1

	var actual_row = MessageActionRow.new()

	if data.page_idx == 0:
		actual_row.add_component(buttons.setup_char_prev_dis) # Disable previous button
	else:
		actual_row.add_component(buttons.setup_char_prev)

	actual_row.add_component(buttons.setup_char_accept)

	if data.page_idx == num_sprites - 1:
		actual_row.add_component(buttons.setup_char_next_dis) # Disable next button
	else:
		actual_row.add_component(buttons.setup_char_next)

	return {
		"embeds": [embed],
		"files": [{
			"name": random_file_name + ".png",
			"media_type": "image/png",
			"data": bytes
		}],
		"components": [actual_row],
		"attachments": []
	}

func get_usage(p: String) -> String:
	return "`%ssetup`" % p

var help = {
	"name": "setup",
	"category": "Game",
	"enabled": true,
	"description": "Setup your game character"
}
