extends Node

const base_xp = 50
const ratio = 1.1

var players_data = {}
var PLAYERS_SAVE_FILE = "res://saves/players.save"
const default_player_data = {
	#"tag": "inserted in runtime",
	"char": "male1",
	"money": 100,
	"level": 0,
	"xp": 0,
}

func load_players_data():
	var file = File.new()
	if not file.file_exists(PLAYERS_SAVE_FILE):
		players_data = {}
		return

	file.open(PLAYERS_SAVE_FILE, File.READ)
	players_data = file.get_var()
	print("Loaded " + str(players_data.size()) + " players")

	for player_id in players_data.keys():
		players_data[player_id] = Globals.merge_dict(default_player_data, players_data[player_id])

	print(players_data)
	file.close()

func save_players_data():
	var file = File.new()
	file.open(PLAYERS_SAVE_FILE, File.WRITE)

	var to_save = players_data.duplicate(true)
	for player_id in to_save.keys():
		var save_player = Globals.diff_dict(to_save[player_id], default_player_data)
		if save_player.has("tag"):
			save_player.erase("tag")
		to_save[player_id] = save_player

	file.store_var(players_data)
	file.close()

func get_player_data(id_or_node):
	var player_id = Globals.player2id(id_or_node)

	if players_data.has(player_id):
		return players_data[player_id]
	else:
		return null

func save_player_data(id_or_node, new_player_data):
	var player_id = Globals.player2id(id_or_node)

	if new_player_data == null:
		# Incase we want to delete the player
		players_data.erase(id_or_node)
	else:
		if not players_data.has(player_id):
			# Make a new user
			players_data[player_id] = new_player_data
		else:
			# Update the current user
			players_data[player_id] = Globals.merge_dict(players_data[player_id], new_player_data)
	save_players_data()

func _ready() -> void:
	var save_dir = Directory.new()
	if not save_dir.dir_exists("res://saves/"):
		save_dir.make_dir("res://saves/")
	load_players_data()

func increase_user_xp(bot: DiscordBot, messageorchannelid, player_id: String, xp_amount: int):
	if not players_data.has(player_id):
		return

	var player_data = players_data[player_id]
	var total_xp = get_xp_for_level(player_data.level) + player_data.xp + xp_amount

	var new_level = get_level_for_xp(total_xp)
	if new_level <= player_data.level:
		players_data[player_id].xp += xp_amount
		return

	var new_xp = total_xp - get_xp_for_level(new_level)
	players_data[player_id].xp = new_xp
	players_data[player_id].level = new_level

	bot.reply(messageorchannelid, "You leveled up to :level_slider: " + str(new_level))

func get_xp_for_level(level: int) -> int:
	return int(floor(base_xp * (pow(ratio, level) - 1) / (ratio - 1)))

func get_level_for_xp(xp) -> int:
	return int(floor(log(1 + (xp * (ratio - 1) / base_xp)) / log(ratio)))
