extends Node

var players_data = {}
var PLAYERS_SAVE_FILE = "res://players.save"
var default_player_data = {
	"tag": "Name#----",
	"char": 0,
	"money": 100
}

func load_players_data():
	var file = File.new()
	if not file.file_exists(PLAYERS_SAVE_FILE):
		players_data = {}
		return

	file.open(PLAYERS_SAVE_FILE, File.READ)
	players_data = file.get_var()
	file.close()

func save_players_data():
	var file = File.new()
	file.open(PLAYERS_SAVE_FILE, File.WRITE)
	file.store_var(players_data)
	file.close()

func get_player_data(id_or_node):
	if not typeof(id_or_node) == TYPE_STRING:
		if id_or_node is KinematicBody2D:
			id_or_node = id_or_node.name
		else:
			assert(false, id_or_node + " couldn't be resolved to a Player.")

	if players_data.has(id_or_node):
		return players_data[id_or_node]
	else:
		return null

func save_player():
	pass

func _ready() -> void:
	load_players_data()
