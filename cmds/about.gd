extends Command

var started_epoch

func on_ready(world, bot: DiscordBot):
	started_epoch = OS.get_ticks_msec()

func on_message(world, bot: DiscordBot, message: Message, channel: Dictionary, args: Array) -> void:
	var time_running = OS.get_ticks_msec() - started_epoch
	var embed = Embed.new().set_title("About Me").set_timestamp().set_color("#f2b210")
	embed.set_description("I am made by 3ddelano#6033 using the Godot Engine and an open-source plugin called Discord.gd.\n\n[Join Support Server](https://discord.gg/FZY9TqW)\n[Support My Creator](https://www.buymeacoffee.com/3ddelano)")
	embed.set_thumbnail(bot.user.get_display_avatar_url())
	embed.add_field("Godot Version", Engine.get_version_info().string, true)
	embed.add_field("Uptime", Globals.millis_to_string(time_running))
	bot.send(message, {
		"embeds": [embed]
	})

func get_usage(p: String) -> String:
	return "`%sabout`" % p

var help = {
	"name": "about",
	"category": "System",
	"aliases": ["info"],
	"enabled": true,
	"description": "Know a little more about me"
}
