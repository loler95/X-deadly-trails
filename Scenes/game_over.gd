extends CanvasLayer

@onready var restart_button = $RestartButton if has_node("RestartButton") else null
@onready var menu_button = $MenuButton if has_node("MenuButton") else null

func _ready():
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			_on_restart_pressed()

func _on_restart_pressed():
	get_tree().change_scene_to_file("res://Scenes/office.tscn")

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
