extends Command

var buttons = {
	"delete_yes": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label("Yes").set_custom_id("delete_yes"),
	"delete_no": MessageButton.new().set_style(MessageButton.STYLES.PRIMARY).set_label("No").set_custom_id("delete_no"),
}

var rows = {
	"confirm_delete": MessageActionRow.new().add_component(buttons.delete_yes).add_component(buttons.delete_no)
}

func on_ready(world, bot: DiscordBot):
	world.connect("interaction_create", self, "on_interaction_create")

func on_message(world, bot: DiscordBot, message: Message, channel: Dictionary, args: Array) -> void:
	var uid = message.author.id
	var tag = message.author.username + "#" + message.author.discriminator

	var player_data = PlayersData.get_player_data(uid)
	if not player_data:
		bot.reply(message, "You do not have any character to delete.")
		return

	var embed = Embed.new().set_title("Confirm Character Deletion").set_timestamp().set_description("Are you sure you want to delete your character?\n**(Your character and inventory will be lost forever)**").set_footer("Requested by " + tag).set_color("#f2b210")

	var msg = yield(bot.reply(message, {
		"embeds": [embed],
		"components": [rows.confirm_delete]
	}), "completed")

	world.interactions[msg.id] = {
		"type": "confirm_delete",
		"author_id": uid,
		"edit_slug": "/channels/%s/messages/%s" % [msg.channel_id, msg.id],
		"last_time": OS.get_ticks_msec(),

		"author_tag": tag
	}

func on_interaction_create(world, bot: DiscordBot, interaction: DiscordInteraction, data: Dictionary) -> void:
	var msg_id = interaction.message.id
	var custom_id = interaction.data.custom_id

	# If its not a valid confirm_delete interaction, we return
	if not data.type == "confirm_delete":
		return

	if not (custom_id == "delete_yes" or custom_id == "delete_no"):
		return

	if custom_id == "delete_yes":
		PlayersData.save_player_data(data.author_id, null)
		# Check if user is playing a game, if yes then stop it
		if data.author_id in world.current_players:
			for game_msg_id in world.interactions:
				var game_data = world.interactions[game_msg_id]
				if game_data.type == "games" and game_data.author_id == data.author_id:
					world.games_timeout(game_msg_id)
					break
		interaction.message.embeds[0]["description"] = "Character deleted successfully."
	else:
		interaction.message.embeds[0]["description"] = "Character deletion was cancelled."

	interaction.update({
		"embeds": interaction.message.embeds,
		"components": []
	})
	world.interactions.erase(msg_id)
	return

func get_usage(p: String) -> String:
	return "`%sdelete`" % p

var help = {
	"name": "delete",
	"category": "Game",
	"enabled": true,
	"description": "Delete your game character"
}
