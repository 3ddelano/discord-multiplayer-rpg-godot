extends Node2D

"""BOT VARIABLES"""
var prefix = "."
onready var started_epoch = OS.get_ticks_msec()
onready var player_scene = preload("res://scenes/Player.tscn")

export (NodePath) var players_path
export (NodePath) var spawn_point_path
export (NodePath) var discord_bot_path

onready var players_node = get_node(players_path)
onready var spawn_point = get_node(spawn_point_path)
onready var discord_bot = get_node(discord_bot_path)

onready var buttons = {
	"left": MessageButton.new().set_style(MessageButton.STYLES.PRIMARY).set_label("Left").set_custom_id("btn_left"),
	"right": MessageButton.new().set_style(MessageButton.STYLES.PRIMARY).set_label("Right").set_custom_id("btn_right"),
	"up": MessageButton.new().set_style(MessageButton.STYLES.PRIMARY).set_label("Up").set_custom_id("btn_up"),
	"down": MessageButton.new().set_style(MessageButton.STYLES.PRIMARY).set_label("Down").set_custom_id("btn_down"),
	"dis1": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label(".").set_custom_id("dis1").set_disabled(true),
	"dis2": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label(".").set_custom_id("dis2").set_disabled(true),
	"current_players": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label(".").set_custom_id("current_players").set_disabled(true),
	"delete_yes": MessageButton.new().set_style(MessageButton.STYLES.SECONDARY).set_label("Yes").set_custom_id("delete_yes"),
	"delete_no": MessageButton.new().set_style(MessageButton.STYLES.PRIMARY).set_label("No").set_custom_id("delete_no"),
}
onready var rows = {
	# For movement buttons
	"move1": MessageActionRow.new().add_component(buttons.dis1).add_component(buttons.up).add_component(buttons.dis2),
	"move2": MessageActionRow.new().add_component(buttons.left).add_component(buttons.down).add_component(buttons.right),

	# For number of active players
	"calculated": MessageActionRow.new().add_component(buttons.current_players),

	# For delete command
	"confirm_delete": MessageActionRow.new().add_component(buttons.delete_yes).add_component(buttons.delete_no)
}

var games = {}
var current_players = []
var confirm_deletes = {}

# Specifies the wait_time for the cached interaction before the buttons are removed
var wait_times = {
	"games": 30,
	"confirm_deletes": 30
}
"""Game variables"""

func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	if not event.pressed or not event.button_index == BUTTON_RIGHT:
		return

func _ready() -> void:
	var file = File.new()
	file.open("res://token.secret", File.READ)
	var token = file.get_as_text()
	file.close()

	var bot = $DiscordBot
	bot.TOKEN = token
	# warning-ignore:return_value_discarded
	bot.connect("bot_ready", self, "_on_bot_ready")
	# warning-ignore:return_value_discarded
	bot.connect("message_create", self, "_on_message_create")
	# warning-ignore:return_value_discarded
	bot.connect("interaction_create", self, "_on_interaction_create")
	bot.login()

	$InteractionClock.connect("timeout", self, "_on_interaction_clock")

func _on_bot_ready(bot: DiscordBot) -> void:
	print("Logged in as " + bot.user.username + "#" + bot.user.discriminator)
	bot.set_presence({
		"activity": {
			"type": "Game",
			"name": ".help | Godot Engine"
		}
	})

func _on_message_create(bot: DiscordBot, message: Message, channel: Dictionary) -> void:
	if message.author.bot or not message.content.begins_with(prefix):
		return

	var raw_content = message.content.lstrip(prefix)
	var tokens = []
	var r = RegEx.new()
	r.compile("\\S+") # Negated whitespace character class
	for token in r.search_all(raw_content):
		tokens.append(token.get_string())
	var cmd = tokens[0].to_lower()
	tokens.remove(0) # Remove the command name from the tokens
	var args = tokens
	handle_command(bot, message, channel, cmd, args)

func handle_command(bot: DiscordBot, message: Message, _channel: Dictionary, cmd: String, _args: Array):
	var uid = message.author.id
	var tag = message.author.username + "#" + message.author.discriminator

	match cmd:
		"ping":
			# Basic latency check command
			var starttime = OS.get_ticks_msec()
			var msg = yield(bot.reply(message, "Ping..."), "completed")
			var latency = str(OS.get_ticks_msec() - starttime)
			bot.edit(msg, "Pong! Latency is " + latency + "ms.")

		"help":
			# Simple help command to tell instructions
			var embed = Embed.new().set_title("Here's some helpful information").set_timestamp().set_footer("Requested by " + message.author.username + "#" + message.author.discriminator + " | Powered by Godot & Discord.gd | Creator: 3ddelano#6033").set_color("#f2b210")

			var commands = {
				"play": "Start the game",
				"stop": "Stop the game",
				"players": "Show the active players",
				"ping": "Check my latency",
				"help": "Show some helpful information",
				"about": "Know a little more about me"
			}

			var helptext = PoolStringArray([
				"**Buttons**",
				"`Left/Right/Up/Down`: Move your character",
				"`P: `: Shows the number of active users",
				"\n**Available Commands**"
			]).join("\n") + "\n"
			for cmd in commands.keys():
				helptext += "`" + prefix + cmd + "` - " + commands[cmd] + "\n"

			embed.set_description(helptext)

			bot.send(message, {
				"embeds": [embed]
			})

		"about":
			var time_running = OS.get_ticks_msec() - started_epoch
			var embed = Embed.new().set_title("About Me").set_timestamp()
			embed.set_description("I am made by 3ddelano#6033 using the Godot Engine and an open-source plugin called Discord.gd.\n\n[Join Support Server](https://discord.gg/FZY9TqW)\n[Support My Creator](https://www.buymeacoffee.com/3ddelano)").set_color("#f2b210")
			embed.set_thumbnail(bot.user.get_display_avatar_url())
			embed.add_field("Godot Version", Engine.get_version_info().string, true)
			embed.add_field("Uptime", Globals.millis_to_string(time_running))
			bot.send(message, {
				"embeds": [embed]
			})

		"play":
			# The main command to start a game

			if uid in current_players:
				# The user is already in a game
				bot.reply(message, "You are already playing the game!")
				return


			var player = player_scene.instance()
			player.name = uid

			# Load previous data if not ask to make a new character
			var player_data = Data.get_player_data(uid)
#			if not player_data:
#				bot.send(message, "You have not setup your character. Use `.setup` to setup.")
#				var new_player_data = Data.default_player_data.duplicate(true)
#				new_player_data.tag = tag
#				Data.set_player_data(uid, new_player_data)
#				return
			player.set_player_data({
				"tag": message.author.username + "#" + message.author.discriminator
			})
			player.global_position = spawn_point.global_position
			players_node.add_child(player)
			yield(get_tree(), "idle_frame")

			print("Player Joined: " + tag + " on " + bot.guilds[message.guild_id].name)
			current_players.append(uid)

			var bytes = yield(_get_player_image_bytes(uid), "completed")
			var embed = Embed.new().set_image("attachment://screenshot.png").set_title("Delano's RPG").set_description("Press the buttons to play").set_footer("Requested by " + tag).set_timestamp().set_color("#f2b210")

			var msg = yield(bot.send(message, {
				"embeds": [embed],
				"files": [{
					"name": "screenshot.png",
					"media_type": "image/png",
					"data": bytes
				}],
				"components": make_components()
			}), "completed")

			games[msg.id] = {
				"author_id": uid,
				"author_tag": tag,
				"edit_slug": "/channels/%s/messages/%s" % [msg.channel_id, msg.id],
				"last_time": OS.get_ticks_msec()
			}

		"stop":
			# Used to stop playing the game
			if not uid in current_players:
				# User is not even playing a game
				bot.reply(message, "You are not playing the game!")
				return

			# Find the game which the user is playing and remove it
			for msg_id in games.keys():
				var game_data = games[msg_id]
				if game_data["author_id"] == uid:
					_delete_game(msg_id)
					bot.reply(message, "Your game was stopped.")
					break

		"delete":
			var embed = Embed.new().set_title("Confirm Character Deletion").set_timestamp().set_description("Are you sure you want to delete your character?\n**(Your character and inventory will be lost forever)**").set_footer("Requested by " + tag)

			var msg = yield(bot.reply(message, {
				"embeds": [embed],
				"components": [rows.confirm_delete]
			}), "completed")

			confirm_deletes[msg.id] = {
				"author_id": uid,
				"edit_slug": "/channels/%s/messages/%s" % [msg.channel_id, msg.id],
				"last_time": OS.get_ticks_msec()
			}

		"players":
			var games_data = games.values()
			var players = []
			for game in games_data:
				players.append(game["author_tag"])

			var players_string = "None"
			if players.size() != 0:
				players_string = PoolStringArray(players).join(', ')
			bot.send(message, "**Current Players**: " + players_string)

func _remove_buttons_from_interaction(interaction: DiscordInteraction, msg = ":robot: Buttons have timed out") -> void:
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
	var custom_id = interaction.data.custom_id


	# Handle the yes / no confirm buttons
	if custom_id == "delete_yes" or custom_id == "delete_no":
		# If the interactions is not cached in confirm_deletes
		if not confirm_deletes.has(msg_id):
			_remove_buttons_from_interaction(interaction)
			return
		if custom_id == "delete_yes":
			print("delete player data")
			pass # delete the player data
		else:
			interaction.message.embeds[0]["description"] = "Character deletion was cancelled."
			interaction.update({
				"embeds": interaction.message.embeds,
				"components": []
			})
		return

	# Remove buttons if the interaction is not cached by any of the interaction Dictionaries
	if not games.has(msg_id):
		_remove_buttons_from_interaction(interaction)
		return

	var game_data = games[msg_id]

	# Check to see the author is the game author
	if not interaction.member.user.id == game_data["author_id"]:
		interaction.reply({
			"ephemeral": true,
			"content": "Not allowed. You are not the player of the game."
		})
		return

	var player_node: KinematicBody2D = players_node.get_node(game_data["author_id"])

	match custom_id:
		"btn_left":
			player_node.make_move("left")
		"btn_right":
			player_node.make_move("right")
		"btn_up":
			player_node.make_move("up")
		"btn_down":
			player_node.make_move("down")

	var new_msg_data = yield(make_game_embed(player_node), "completed")
	interaction.defer_update()
	game_data.last_time = OS.get_ticks_msec()
	yield(bot.edit(interaction.message, new_msg_data), "completed")
	return

func make_game_embed(player_node: KinematicBody2D):
	var random_file_name = str(randi() % 4096)

	var bytes = yield(_get_player_image_bytes(player_node), "completed")
	var embed = Embed.new().set_title("Delano's RPG").set_description("Press the buttons to play").set_image("attachment://"+random_file_name+".png").set_footer("Requested by " + player_node.player_data.tag).set_timestamp().set_color("#f2b210")

	return {
		"files": [{
			"name": random_file_name+".png",
			"media_type": "image/png",
			"data": bytes
		}],
		"attachments": [],
		"components": make_components(),
		"embeds": [embed]
	}

func make_components():
	for component in rows.calculated.components:
		if component.custom_id == "current_players":
			component.set_label("P: " + str(current_players.size()))
	return [rows.move1, rows.move2, rows.calculated]

func _get_player_image_bytes(player_id_or_node) -> PoolByteArray:
	var player: KinematicBody2D
	if typeof(player_id_or_node) == TYPE_STRING:
		player = players_node.get_node(player_id_or_node)
	else:
		player = player_id_or_node

	var view_rect := Rect2(player.get_global_transform_with_canvas().origin - Globals.half_view_size, Globals.half_view_size * 2)

	yield(VisualServer, "frame_post_draw")
	var image: Image = get_viewport().get_texture().get_data()
	image.flip_y()
	image = image.get_rect(view_rect)
	return image.save_png_to_buffer()

func _on_interaction_clock():
	# Loop through each of the cached interactions and remove the button if
	for msg_id in confirm_deletes:
		var elapsed_s = (OS.get_ticks_msec() - confirm_deletes[msg_id].last_time) / 1000.0
		if elapsed_s >= wait_times.confirm_deletes:
			_delete_confirm_delete(msg_id)

	for msg_id in games:
		var elapsed_s = (OS.get_ticks_msec() - games[msg_id].last_time) / 1000.0
		if elapsed_s >= wait_times.games:
			_delete_game(msg_id)

func _delete_game(msg_id: String) -> void:
	var game_data = games[msg_id]
	var uid = game_data["author_id"]
	var player_node = players_node.get_node(uid)
	player_node.queue_free()
	current_players.erase(uid)
	discord_bot._send_request(game_data["edit_slug"], {
		"components": []
	}, HTTPClient.METHOD_PATCH)
	print("Player Disconnected: " + game_data["author_tag"])
	games.erase(msg_id)

func _delete_confirm_delete(msg_id: String) -> void:
	var data = confirm_deletes[msg_id]
	discord_bot._send_request(data["edit_slug"], {
		"components": []
	}, HTTPClient.METHOD_PATCH)
	confirm_deletes.erase(msg_id)
