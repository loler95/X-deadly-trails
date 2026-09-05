extends CanvasLayer

@onready var restart_button = $RestartButton
@onready var menu_button = $MenuButton

func _ready():
	menu_button.pressed.connect(_on_menu_pressed)
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

func _input(event):
	if event is InputEventKey and event.pressed:
		_on_restart_pressed()

func _on_restart_pressed():
	get_tree().change_scene_to_file("res://Scenes/Office.tscn")
	
func _on_menu_pressed():
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
