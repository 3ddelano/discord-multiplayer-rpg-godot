extends Command

func on_message(world, bot: DiscordBot, message: Message, channel: Dictionary, args: Array) -> void:
	var uid = message.author.id

	if not uid in world.current_players:
		# User is not even playing a game
		bot.reply(message, "You are not playing the game!")
		return

	# Find the game which the user is playing and remove it

	for msg_id in world.interactions.keys():
		var game_data = world.interactions[msg_id]
		if game_data.author_id == uid:
			world.games_timeout(msg_id)
			bot.reply(message, "Your game was stopped.")
			break


func get_usage(p: String) -> String:
	return "`%sstop`" % p

var help = {
	"name": "stop",
	"category": "Game",
	"aliases": ["s"],
	"enabled": true,
	"description": "Stop playing the game"
}
