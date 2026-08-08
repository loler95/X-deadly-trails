extends CanvasLayer

@onready var restart_button = $RestartButton

func _ready():
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

func _input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		_on_restart_pressed()

func _on_restart_pressed():
	var path = "res://Scenes/office.tscn"
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		push_error("Office scene not found, reloading current")
		get_tree().reload_current_scene()
