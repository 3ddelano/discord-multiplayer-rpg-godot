extends Viewport

func _ready() -> void:
	$AdminSidebar.connect("settoken_pressed", self, "_sidebar_settoken_pressed")

func _sidebar_settoken_pressed():
	$SetTokenWindow.visible = true
	$SetTokenWindow.reset()
