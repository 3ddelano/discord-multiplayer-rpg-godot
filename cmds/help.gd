extends Command

class CommandSorter:
	static func sort_ascending(a, b):
		if a.category == b.category:
			# Check the name only if the categories are the same
			if a.name < b.name:
				return true
			else:
				return false
		if a.category < b.category:
			return true
		else:
			return false


func on_message(world, bot: DiscordBot, message: Message, channel: Dictionary, args: Array) -> void:

	if args.size() > 0:
		var is_cmd = world.cmds.has(args[0])
		var is_alias = world.cmd_aliases.has(args[0])
		if is_cmd or is_alias:
			# Command/Alias was found
			var cmd_name = args[0]
			if is_alias:
				cmd_name = world.cmd_aliases.get(args[0])

			var cmd = world.cmds.get(cmd_name)
			_send_indiviual_command_help(world, bot, message, cmd)
			return

		bot.reply(message, "Command `" + args[0] + "` not found.")
		return

	var embed = Embed.new().set_title("Here's some helpful information").set_timestamp().set_color("#f2b210")
	embed.set_footer("Total Cmds: " + str(world.cmds.size()) + " | Requested by " + message.author.username + "#" + message.author.discriminator + " | Powered by Discord.gd")
	embed.set_description("For extended command usage, use `%shelp <command>`\n\nPrefix is `.`\nEg. `%sabout`" % [world.prefix, world.prefix])

	var sorted = []
	for cmd in world.cmds.values():
		if not sorted.has(cmd):
			var help = cmd.help.duplicate(true)
			help['usage'] = cmd.get_usage(world.prefix)
			sorted.append(help)

	sorted.sort_custom(CommandSorter, "sort_ascending")

	var current_category = ""
	var category_cmds = {}
	for cmd in sorted:
		if not category_cmds.has(cmd.category):
			category_cmds[cmd.category] = ["`" + cmd.name + "`"]
		else:
			category_cmds[cmd.category].append("`" + cmd.name + "`")

	for category in category_cmds.keys():
		embed.add_field(category + " Category", PoolStringArray(category_cmds[category]).join(' '))

	bot.send(message, {
		"embeds": [embed]
	})

func _send_indiviual_command_help(world, bot: DiscordBot, message: Message, cmd):
	var embed = Embed.new().set_title(cmd.help.name.capitalize() + " Command").set_timestamp()
	embed.set_footer("Requested by " + message.author.username + "#" + message.author.discriminator)
	embed.set_description("**Description**\n" + cmd.help.description).set_color("#f2b210")

	if cmd.help.has("aliases") and cmd.help.aliases.size() > 0:
		embed.add_field("Aliases", "`" + world.prefix + PoolStringArray(cmd.help.aliases).join("`, `" + world.prefix) + "`")

	embed.add_field("Usage", cmd.get_usage(world.prefix))
	bot.reply(message, {"embeds": [embed]})

func get_usage(p: String) -> String:
	return "`%shelp [command]`\n\nShow all commands - `%shelp`\nShow help for specific command - `%shelp <command_name>`" % [p, p, p]

var help = {
	"name": "help",
	"category": "System",
	"enabled": true,
	"description": "Gives information about the available commands",
}
