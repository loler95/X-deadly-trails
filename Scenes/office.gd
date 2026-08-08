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

# ===== ССЫЛКИ НА УЗЛЫ =====
@onready var power_label: Label = $UI/PowerLabel
@onready var left_door: ColorRect = $World/LeftDoor
@onready var right_door: ColorRect = $World/RightDoor
@onready var vent: ColorRect = $World/Vent
@onready var camera_layer: CanvasLayer = $CameraLayer
@onready var camera_button: Button = $UI/CameraButton
@onready var manager: AnimatronicsManager = $AnimatronicsManager

# Звуки (AudioStreamPlayer2D)
@onready var alert_sound: AudioStreamPlayer2D = $AlertSound
@onready var knock_sound: AudioStreamPlayer2D = $KnockSound
var audio_listener: AudioListener2D

# ===== ИНИЦИАЛИЗАЦИЯ =====
func _ready() -> void:
	# --- Настройка окна на один монитор ---
	var monitor_index = 0
	var screen_size = DisplayServer.screen_get_size(monitor_index)
	var screen_pos = DisplayServer.screen_get_position(monitor_index)
	DisplayServer.window_set_size(screen_size)
	DisplayServer.window_set_position(screen_pos)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	
	# --- Создаём AudioListener2D в центре экрана ---
	audio_listener = AudioListener2D.new()
	audio_listener.name = "AudioListener2D"
	add_child(audio_listener)
	var center = get_viewport().size / 2
	audio_listener.position = center
	print("AudioListener2D at: ", center)
	
	# --- Кнопка камер (переключение по наведению) ---
	camera_button.mouse_entered.connect(_toggle_camera_mode)
	
	# --- Начальное состояние дверей ---
	left_door.modulate.a = 0.3
	right_door.modulate.a = 0.3
	vent.modulate.a = 0.3
	camera_layer.visible = false
	camera_button.text = "CAM"
	
	# --- Слои ---
	$UI.layer = 1
	$CameraLayer.layer = 0
	
	# --- Добавление персонажей в менеджер ---
	var map = $CameraLayer/Map
	if map and manager:
		var char1 = map.get_node_or_null("Char2011x")
		var char2 = map.get_node_or_null("CharMyst")
		var char3 = map.get_node_or_null("CharNMI")
		if char1: manager.add_character(char1, 8, 4, "2011x")
		else: push_error("Char2011x not found in Map")
		if char2: manager.add_character(char2, 5, 4, "MystCrimson")
		else: push_error("CharMyst not found in Map")
		if char3: manager.add_character(char3, 3, 4, "NMI")
		else: push_error("CharNMI not found in Map")
		
		manager.attack_detected.connect(_on_attack_detected)
	else:
		push_error("Map or AnimatronicsManager not found!")

# ===== ОСНОВНОЙ ЦИКЛ =====
func _process(delta: float) -> void:
	var drain = power_drain
	if left_door_closed: drain += 0.25
	if right_door_closed: drain += 0.25
	if vent_closed: drain += 0.15
	if camera_mode: drain += camera_power_drain
	
	power = max(power - drain * delta, 0.0)
	power_label.text = "Power: %d%%" % int(power)
	
	if manager and not is_game_over:
		manager.process_movement(delta)

# ===== ОБРАБОТКА КЛАВИШ =====
func _input(event: InputEvent) -> void:
	if is_game_over:
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

# ===== УПРАВЛЕНИЕ ДВЕРЯМИ =====
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

# ===== РЕЖИМ КАМЕР =====
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
		var offset = 600.0
		var x_pos = audio_listener.position.x + pan * offset
		alert_sound.position.x = x_pos
		alert_sound.position.y = audio_listener.position.y
		alert_sound.play()

func play_knock(pan: float):
	if knock_sound and knock_sound.stream:
		var offset = 1000.0
		var x_pos = audio_listener.position.x + pan * offset
		knock_sound.position.x = x_pos
		knock_sound.position.y = audio_listener.position.y
		knock_sound.play()

# ===== ОБРАБОТКА АТАКИ (GAME OVER) =====
func _on_attack_detected(character_name: String, defense_type: String) -> void:
	if is_game_over:
		return
	is_game_over = true
	print("GAME OVER! ", character_name, " attacked through ", defense_type)
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
