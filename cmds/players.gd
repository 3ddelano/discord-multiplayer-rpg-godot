extends Command

func on_message(world, bot: DiscordBot, message: Message, channel: Dictionary, args: Array) -> void:
	var players = []
	for game in world.interactions.values():
		if game.type == "games":
			players.append(game["author_tag"])

	var players_string = "None"
	if players.size() != 0:
		players_string = PoolStringArray(players).join(', ')
	bot.reply(message, "**Active Players (" + str(players.size()) + ")**: " + players_string)


func get_usage(p: String) -> String:
	return "`%splayers`" % p

var help = {
	"name": "players",
	"category": "Game",
	"enabled": true,
	"description": "Shows the active players"
}
