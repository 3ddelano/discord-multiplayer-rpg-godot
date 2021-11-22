extends PanelContainer

func _ready() -> void:
	$VB/CloseBtn.connect("pressed", self, "_on_closebtn_pressed")
	$VB/MC/VB/Button.connect("pressed", self, "_on_settoken_pressed")

func reset():
	$VB/MC/VB/TokenValue.text = "Enter token here"

func _on_closebtn_pressed():
	visible = false

func _on_settoken_pressed():
	var token = $VB/MC/VB/TokenValue.text
	if token == "":
		return

	AppData.app_data.token = token
	AppData.save_app_data()
	visible = false
