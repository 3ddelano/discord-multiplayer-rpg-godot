extends Reference

class_name Command

func on_ready(world, bot: DiscordBot) -> void:
	pass

func on_message(world, bot: DiscordBot, message: Message, channel: Dictionary, args: Array) -> void:

	var categories = []
	for cmd in bot.cmds:
		pass

func on_interaction_create(world, bot: DiscordBot, interaction: DiscordInteraction, data: Dictionary) -> void:
	pass


func get_usage(p: String) -> String:
	return "test usage"

#var help = {
#	"name": "test_name",
#	"category": "test_category",
#	"aliases": [],
#	"enabled": true,
#	"description": "test_description",
#}
