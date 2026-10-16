extends Node2D

# ===== ПЕРЕМЕННЫЕ =====
var power: float = 100.0
var power_drain: float = 0.15

var left_door_closed := false
var right_door_closed := false
var vent_closed := false

var camera_mode := false
var camera_power_drain := 0.1

var is_game_over := false
var game_won := false

# --- Время ночи (из GameData) ---
var night_duration: float
var time_passed := 0.0
var start_hour := 12

# --- Менеджеры ---
@onready var flashlight_manager = get_node("FlashlightManager")
@onready var animatronic_manager: AnimatronicsManager = $AnimatronicsManager

# ===== ССЫЛКИ НА УЗЛЫ =====
@onready var power_label: Label = $UI/PowerLabel
@onready var time_label: Label = $UI/TimeLabel
@onready var night_label: Label = $UI/NightLabel if has_node("UI/NightLabel") else null
@onready var left_door: ColorRect = $World/LeftDoor
@onready var right_door: ColorRect = $World/RightDoor
@onready var vent: ColorRect = $World/Vent
@onready var camera_layer: CanvasLayer = $CameraLayer
@onready var camera_button: Button = $UI/CameraButton

@onready var left_door_sprite: Sprite2D = $LeftDoorSprite
@onready var right_door_sprite: Sprite2D = $RightDoorSprite
@onready var vent_sprite: Sprite2D = $VentSprite

# Звуки
@onready var alert_sound: AudioStreamPlayer2D = $AlertSound if has_node("AlertSound") else null
@onready var knock_sound: AudioStreamPlayer2D = $KnockSound if has_node("KnockSound") else null

var audio_listener: AudioListener2D


# ===== ИНИЦИАЛИЗАЦИЯ =====
func _ready() -> void:
	# --- Настройка окна ---
	var monitor_index = 0
	var screen_size = DisplayServer.screen_get_size(monitor_index)
	var screen_pos = DisplayServer.screen_get_position(monitor_index)
	DisplayServer.window_set_size(screen_size)
	DisplayServer.window_set_position(screen_pos)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
	# --- Берём данные из GameData ---
	night_duration = GameData.night_duration
	time_passed = 0.0
	_update_time_label()
	if night_label:
		night_label.text = "Ночь " + str(GameData.current_night)
	
	# --- AudioListener2D ---
	audio_listener = AudioListener2D.new()
	audio_listener.name = "AudioListener2D"
	add_child(audio_listener)
	var center = get_viewport().size / 2
	audio_listener.position = center
	
	# --- Кнопка камер ---
	camera_button.mouse_entered.connect(_toggle_camera_mode)
	
	# --- Начальное состояние дверей ---
	left_door.modulate.a = 0.3
	right_door.modulate.a = 0.3
	vent.modulate.a = 0.3
	camera_layer.visible = false
	camera_button.text = "CAM"
	
	$UI.layer = 1
	$CameraLayer.layer = 0
	
	# --- Добавление персонажей (скорости из GameData) ---
	var map = $CameraLayer/Map
	if map and animatronic_manager:
		var char1 = map.get_node_or_null("Char2011x")
		var char2 = map.get_node_or_null("CharMyst")
		var char3 = map.get_node_or_null("CharImperfect")
		
		if char1:
			animatronic_manager.add_character(char1, GameData.get_speed("2011x"), 7, "2011x")
		if char2:
			animatronic_manager.add_character(char2, GameData.get_speed("MystCrimson"), 7, "MystCrimson")
		if char3:
			animatronic_manager.add_character(char3, GameData.get_speed("Imperfect"), 7, "Imperfect")
		
		animatronic_manager.attack_detected.connect(_on_attack_detected)
		animatronic_manager.myst_crimson_state_changed.connect(_on_myst_state_changed)
		
		# --- Отладочный вывод ---
		print("=== NIGHT ", GameData.current_night, " ===")
		print("2011x speed: ", GameData.get_speed("2011x"))
		print("MystCrimson speed: ", GameData.get_speed("MystCrimson"))
		print("Imperfect speed: ", GameData.get_speed("Imperfect"))
		print("Night duration: ", GameData.night_duration)
	else:
		push_error("Map or AnimatronicsManager not found!")


# ===== ОСНОВНОЙ ЦИКЛ =====
func _process(delta: float) -> void:
	if is_game_over or game_won:
		return
	
	# --- Энергия ---
	var drain = power_drain
	if left_door_closed: drain += 0.25
	if right_door_closed: drain += 0.25
	if vent_closed: drain += 0.15
	if camera_mode: drain += camera_power_drain
	if flashlight_manager.flashlight_on: drain += 0.1
	
	power = max(power - drain * delta, 0.0)
	power_label.text = "Power: %d%%" % int(power)
	
	# --- Время ---
	time_passed += delta
	_update_time_label()
	
	# --- Проверка победы ---
	if time_passed >= night_duration:
		win_game()
		return
	
	# --- Движение аниматроников ---
	if animatronic_manager and not is_game_over:
		animatronic_manager.process_movement(delta)


# ===== ОБНОВЛЕНИЕ ЧАСОВ =====
func _update_time_label():
	var progress = time_passed / night_duration
	var game_minutes = progress * 360.0
	var hours = 12 + int(game_minutes / 60)
	var minutes = int(game_minutes) % 60
	var display_hours = hours if hours <= 12 else hours - 12
	if display_hours == 0:
		display_hours = 12
	var time_string = "%02d:%02d" % [display_hours, minutes]
	time_label.text = time_string


# ===== ВЫИГРЫШ =====
func win_game() -> void:
	if game_won or is_game_over:
		return
	game_won = true
	print("YOU WIN! Night ", GameData.current_night, " completed.")
	var path = "res://Scenes/WinScreen.tscn"
	var tree = get_tree()
	if tree:
		tree.call_deferred("change_scene_to_file", path)
	else:
		var main_loop = Engine.get_main_loop()
		if main_loop and main_loop.has_method("change_scene_to_file"):
			main_loop.call_deferred("change_scene_to_file", path)


# ===== СПРАЙТ MYSTIC CRIMSON =====
func _on_myst_state_changed(room_id: int, state: int):
	var show_sprite = (state == 2)
	var sprite: Sprite2D = null
	
	left_door_sprite.modulate.a = 0.0
	right_door_sprite.modulate.a = 0.0
	vent_sprite.modulate.a = 0.0
	
	match room_id:
		1: sprite = left_door_sprite
		2: sprite = right_door_sprite
		3: sprite = vent_sprite
	if sprite:
		sprite.modulate.a = 1.0 if show_sprite else 0.0
		var area = sprite.get_node_or_null("CollisionArea")
		if area:
			area.monitoring = show_sprite
			area.monitorable = show_sprite
		print("MystCrimson sprite in room ", room_id, " visible: ", show_sprite)


# ===== КЛАВИШИ =====
func _input(event: InputEvent) -> void:
	if is_game_over or game_won:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A: _on_left_door_pressed()
			KEY_D: _on_right_door_pressed()
			KEY_W: _on_vent_pressed()
		
		if event.keycode == KEY_SPACE or event.keycode == KEY_E:
			_toggle_camera_mode()
		
		if camera_mode:
			match event.keycode:
				KEY_1: _select_camera(1)
				KEY_2: _select_camera(2)
				KEY_3: _select_camera(3)
				KEY_4: _select_camera(4)
				KEY_5: _select_camera(5)
				KEY_6: _select_camera(6)
				KEY_7: _select_camera(7)


# ===== ДВЕРИ =====
func _on_left_door_pressed() -> void:
	left_door_closed = !left_door_closed
	left_door.modulate.a = 1.0 if left_door_closed else 0.3
	left_door.color = Color(0.1, 0.1, 0.1) if left_door_closed else Color(0.2, 0.2, 0.3)
	print("Left door:", "closed" if left_door_closed else "open")

func _on_right_door_pressed() -> void:
	right_door_closed = !right_door_closed
	right_door.modulate.a = 1.0 if right_door_closed else 0.3
	right_door.color = Color(0.1, 0.1, 0.1) if right_door_closed else Color(0.2, 0.2, 0.3)
	print("Right door:", "closed" if right_door_closed else "open")

func _on_vent_pressed() -> void:
	vent_closed = !vent_closed
	vent.modulate.a = 1.0 if vent_closed else 0.3
	vent.color = Color(0.1, 0.1, 0.1) if vent_closed else Color(0.3, 0.3, 0.3)
	print("Vent:", "closed" if vent_closed else "open")


# ===== КАМЕРЫ =====
func _toggle_camera_mode() -> void:
	camera_mode = !camera_mode
	camera_layer.visible = camera_mode
	camera_button.text = "BACK" if camera_mode else "CAM"

func _select_camera(cam_id: int) -> void:
	var map = $CameraLayer/Map
	if map and map.has_method("select_camera"):
		map.select_camera(cam_id)


# ===== ЗВУКИ =====
func play_alert(pan: float):
	if alert_sound and alert_sound.stream:
		alert_sound.position.x = audio_listener.position.x + pan * 600.0
		alert_sound.position.y = audio_listener.position.y
		alert_sound.play()

func play_knock(pan: float):
	if knock_sound and knock_sound.stream:
		knock_sound.position.x = audio_listener.position.x + pan * 600.0
		knock_sound.position.y = audio_listener.position.y
		knock_sound.play()


# ===== GAME OVER =====
func _on_attack_detected(_character_name: String, _defense_type: String) -> void:
	if is_game_over or game_won:
		return
	is_game_over = true
	print("GAME OVER! ", _character_name, " attacked through ", _defense_type)
	game_over()

func game_over() -> void:
	if not is_inside_tree():
		return
	var path = "res://Scenes/GameOver.tscn"
	var tree = get_tree()
	if tree:
		tree.call_deferred("change_scene_to_file", path)
	else:
		var main_loop = Engine.get_main_loop()
		if main_loop and main_loop.has_method("change_scene_to_file"):
			main_loop.call_deferred("change_scene_to_file", path)
		else:
			get_tree().reload_current_scene()
