extends Command

var profile_card_scene

func on_ready(world, bot: DiscordBot) -> void:
	profile_card_scene = preload("res://scenes/ProfileCard.tscn")

func on_message(world, bot: DiscordBot, message: Message, channel: Dictionary, args: Array) -> void:
	var uid = message.author.id
	var tag = message.author.username + "#" + message.author.discriminator
	var is_others = false

	if message.mentions.size() > 0:
		var mention = message.mentions[0]
		uid = mention.id
		tag = mention.username + "#" + mention.discriminator
		is_others = true


	var player_data = PlayersData.get_player_data(uid)
	if not player_data:
		if is_others:
			bot.reply(message, tag + ", does not have a character.")
		else:
			bot.reply(message, "You do not have a character. Use `.setup` to setup.")
		return

	player_data["tag"] = tag
	var instance = profile_card_scene.instance()
	instance.set_player_data(player_data)
	var bytes = yield(world.take_screenshot(instance), "completed")
	bot.reply(message, {
		"files": [
			{
				"name": "profile.png",
				"media_type": "image/png",
				"data": bytes
			}
		]
	})



func get_usage(p: String) -> String:
	return "`%sprofile [@someone]`" % p

var help = {
	"name": "profile",
	"category": "Game",
	"enabled": true,
	"description": "View your or @someone's profile"
}
