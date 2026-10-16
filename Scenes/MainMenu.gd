extends CanvasLayer

@onready var new_game_button = $NewGameButton
@onready var continue_button = $ContinueButton
@onready var night_select_panel = $NightSelectPanel
@onready var back_button = $NightSelectPanel/BackButton
@onready var easter_egg_button = $EasterEggButton if has_node("EasterEggButton") else null
@onready var easter_egg_sound = $EasterEggSound if has_node("EasterEggSound") else null

func _ready():
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	for i in range(1, 7):
		var btn = night_select_panel.get_node_or_null("Night%dButton" % i)
		if btn:
			btn.pressed.connect(_on_night_pressed.bind(i))
	
	if easter_egg_button:
		easter_egg_button.pressed.connect(_on_easter_egg_pressed)

func _on_new_game_pressed():
	GameData.set_night(1)
	get_tree().change_scene_to_file("res://Scenes/office.tscn")

func _on_continue_pressed():
	night_select_panel.visible = true

func _on_back_pressed():
	night_select_panel.visible = false

func _on_night_pressed(night: int):
	GameData.set_night(night)
	get_tree().change_scene_to_file("res://Scenes/office.tscn")

func _on_easter_egg_pressed():
	if easter_egg_sound and easter_egg_sound.stream:
		easter_egg_sound.play()
		print("Easter egg activated!")
