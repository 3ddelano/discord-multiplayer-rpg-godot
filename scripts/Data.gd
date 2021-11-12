extends Node

var players_data = {}
var PLAYERS_SAVE_FILE = "res://saves/players.save"
var default_player_data = {
	"char": "male1",
	"money": 100
}

func load_players_data():
	var file = File.new()
	if not file.file_exists(PLAYERS_SAVE_FILE):
		players_data = {}
		return

	file.open(PLAYERS_SAVE_FILE, File.READ)
	players_data = file.get_var()
	print("Loaded " + str(players_data.size()) + " players")
	print(players_data)
	file.close()

func save_players_data():
	var file = File.new()
	file.open(PLAYERS_SAVE_FILE, File.WRITE)
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
		players_data.erase(id_or_node)
	else:
		players_data[player_id] = new_player_data
	save_players_data()

func _ready() -> void:
	var save_dir = Directory.new()
	if not save_dir.dir_exists("res://saves/"):
		save_dir.make_dir("res://saves/")
	load_players_data()
