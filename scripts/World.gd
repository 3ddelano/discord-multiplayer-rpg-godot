extends Node2D
signal interaction_create(world, bot, interaction, data)

var prefix = "."
onready var player_scene = preload("res://scenes/Player.tscn")

export (NodePath) var players_path
export (NodePath) var spawn_point_path
export (NodePath) var discord_bot_path
export (NodePath) var screenshotter_path
onready var players_node = get_node(players_path)
onready var spawn_point = get_node(spawn_point_path)
onready var discord_bot = get_node(discord_bot_path)
onready var screenshotter = get_node(screenshotter_path)

var cmds = {}
var cmd_aliases = {}
var current_players = []
var interactions = {}

# Specifies the wait_time for the cached interaction before the buttons are removed
var wait_times = {
	"games": 60,
	"confirm_delete": 60,
	"setup_char": 60,
}

func take_screenshot(scene) -> PoolByteArray:
	return yield(screenshotter.take_screenshot(scene), "completed")

func _ready() -> void:
	var file = File.new()
	file.open("res://token.secret", File.READ)
	var token = file.get_as_text()
	file.close()

	var bot = $DiscordBot
	bot.TOKEN = token
	bot.connect("bot_ready", self, "_on_bot_ready")
	bot.connect("message_create", self, "_on_message_create")
	bot.connect("interaction_create", self, "_on_interaction_create")
	bot.login()

	$InteractionClock.connect("timeout", self, "_on_interaction_clock")
	$SaveClock.connect("timeout", self, "_on_save_clock")
	_load_commands(bot)

func _on_bot_ready(bot: DiscordBot) -> void:
	print("Logged in as " + bot.user.username + "#" + bot.user.discriminator)
	bot.set_presence({
		"activity": {
			"type": "Game",
			"name": ".help | Godot Engine"
		}
	})

func _load_commands(bot: DiscordBot) -> void:
	var cmd_path = "res://cmds/"
	var dir = Directory.new()
	if dir.open(cmd_path) != OK:
		push_error("An error occurred when trying to open cmds folder.")
		return

	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "": # End of files
			break
		elif not file.begins_with(".") and file.ends_with(".gd"): # Checks for . and ..
			var script = load("res://cmds/" + file).new()
			var meta = script.help

			# Ensure that the cmds don't have the default help values
			assert(meta.name != "test_name" and meta.category != "test_category" and meta.description != "test_description", "Must change default values for Command.help in " + file)

			if meta.enabled:
				if script.has_method("on_ready"):
					script.on_ready(self, bot)
				cmds[meta.name] = script

				if not meta.has("aliases"):
					continue

				for alias in meta.aliases:
					assert(not cmd_aliases.has(alias), "Duplicate cmd aliases found in cmd: " + file)

					cmd_aliases[alias] = meta.name

	print("Loaded " + str(cmds.size()) + " cmds")
	dir.list_dir_end()

func _on_message_create(bot: DiscordBot, message: Message, channel: Dictionary) -> void:
	if message.author.bot or not message.content.begins_with(prefix):
		return

	var raw_content = message.content.lstrip(prefix)
	var tokens = []
	var r = RegEx.new()
	r.compile("\\S+") # Negated whitespace character class
	for token in r.search_all(raw_content):
		tokens.append(token.get_string())
	var cmd_or_alias = tokens[0].to_lower()
	tokens.remove(0) # Remove the command name from the tokens
	var args = tokens
	_handle_command(bot, message, channel, cmd_or_alias, args)

func _handle_command(bot: DiscordBot, message: Message, channel: Dictionary, cmd_or_alias: String, args: Array):
	var uid = message.author.id
	var tag = message.author.username + "#" + message.author.discriminator

	var cmd = null
	if cmds.has(cmd_or_alias):
		cmd = cmds[cmd_or_alias]
	elif cmd_aliases.has(cmd_or_alias):
		cmd = cmds[cmd_aliases[cmd_or_alias]]

	if not cmd:
		return

	# Increment user xp by a little
	var player_data = PlayersData.get_player_data(uid)
	if player_data:
		PlayersData.increase_user_xp(bot, message, uid, 5)

	print("CMD: " + cmd.help.name + " by " + tag + " (" + uid + ")")
	cmd.on_message(self, bot, message, channel, args)

func remove_buttons_from_interaction(interaction: DiscordInteraction, msg = ":robot: Buttons have timed out") -> void:
	var embed = Embed.new().set_description(msg)
	var new_embeds = interaction.message.embeds + [embed]
	interaction.update({
		"content": interaction.message.content,
		"embeds": new_embeds,
		"components": []
	})

func _on_interaction_create(bot: DiscordBot, interaction: DiscordInteraction) -> void:
	if not interaction.is_button():
		return

	var msg_id = interaction.message.id
	if not interactions.has(msg_id):
		# This interaction is not cached, so remove the buttons if any
		remove_buttons_from_interaction(interaction)

	# Emit the signal to the commands
	if interactions.has(msg_id):
		emit_signal("interaction_create", self, bot, interaction, interactions[msg_id])

func _on_interaction_clock():
	for msg_id in interactions:
		var data = interactions[msg_id]
		var elapsed_s = (OS.get_ticks_msec() - data.last_time) / 1000.0
		if elapsed_s < wait_times[data.type]:
			continue

		match data.type:
			"games":
				games_timeout(msg_id)
				continue
			"confirm_delete":
				_confirm_delete_timeout(msg_id)
				continue
			"setup_char":
				_setup_char_timeout(msg_id)
				continue

func _on_save_clock():
	PlayersData.save_players_data()

func games_timeout(msg_id) -> void:
	var data = interactions[msg_id]
	var uid = data.author_id

	# Remove the buttons
	yield(discord_bot._send_request(data.edit_slug, {
		"components": []
	}, HTTPClient.METHOD_PATCH), "completed")
	var player_node = players_node.get_node(uid)
	player_node.queue_free() # Delete the player node
	current_players.erase(uid) # Update the active users
	print("Player Disconnected: " + data.author_tag)
	interactions.erase(msg_id)

func _confirm_delete_timeout(msg_id: String) -> void:
	var data = interactions[msg_id]
	discord_bot._send_request(data.edit_slug, {
		"components": []
	}, HTTPClient.METHOD_PATCH)
	interactions.erase(msg_id)

func _setup_char_timeout(msg_id: String) -> void:
	var data = interactions[msg_id]
	discord_bot._send_request(data.edit_slug, {
		"components": []
	}, HTTPClient.METHOD_PATCH)
	interactions.erase(msg_id)



