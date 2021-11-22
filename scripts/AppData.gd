extends Node

var app_data = {}
var SAVE_PATH = "user://saves/appdata.save"
const default_app_data = {
	"token": "",
}

func load_app_data():
	var file = File.new()
	if not file.file_exists(SAVE_PATH):
		app_data = default_app_data.duplicate(true)
		return

	file.open(SAVE_PATH, File.READ)
	app_data = file.get_var()
	print("Loaded app data")
	file.close()

func save_app_data():
	var file = File.new()
	file.open(SAVE_PATH, File.WRITE)

	var to_save = app_data.duplicate(true)
	file.store_var(app_data)
	file.close()

func _ready() -> void:
	load_app_data()
