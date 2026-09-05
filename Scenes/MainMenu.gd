extends CanvasLayer

@onready var new_game_button = $NewGameButton
@onready var continue_button = $ContinueButton
@onready var easter_egg_button = $EasterEggButton
@onready var easter_egg_sound = $EasterEggSound

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	easter_egg_button.pressed.connect(_on_easter_egg_pressed)

func _on_new_game_pressed():
	get_tree().change_scene_to_file("res://Scenes/Office.tscn")

func _on_continue_pressed():
	get_tree().change_scene_to_file("res://Scenes/Office.tscn")

func _on_easter_egg_pressed():
	# Воспроизводим звук
	if easter_egg_sound and easter_egg_sound.stream:
		easter_egg_sound.play()
		print("Easter egg activated!")
	else:
		print("No sound loaded for easter egg")
