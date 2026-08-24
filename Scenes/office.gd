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
var flashlight_on := false
var flashlight_timer := 0.0

# ===== ССЫЛКИ НА УЗЛЫ =====
@onready var power_label: Label = $UI/PowerLabel
@onready var left_door: ColorRect = $World/LeftDoor
@onready var right_door: ColorRect = $World/RightDoor
@onready var vent: ColorRect = $World/Vent
@onready var camera_layer: CanvasLayer = $CameraLayer
@onready var camera_button: Button = $UI/CameraButton
@onready var manager: AnimatronicsManager = $AnimatronicsManager

@onready var left_door_sprite: Sprite2D = $LeftDoorSprite
@onready var right_door_sprite: Sprite2D = $RightDoorSprite
@onready var vent_sprite: Sprite2D = $VentSprite

# Узлы фонарика
@onready var flashlight_area: Area2D = $FlashlightArea
@onready var flashlight_collision: CollisionShape2D = $FlashlightArea/CollisionShape2D

# Звуки
@onready var alert_sound: AudioStreamPlayer2D = $AlertSound if has_node("AlertSound") else null
@onready var knock_sound: AudioStreamPlayer2D = $KnockSound if has_node("KnockSound") else null
@onready var flashlight_sound: AudioStreamPlayer2D = $FlashlightSound if has_node("FlashlightSound") else null
@onready var flashlight_sprite: Sprite2D = $FlashlightSprite if has_node("FlashlightSprite") else null

var audio_listener: AudioListener2D
var current_target_area: Area2D = null

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
	
	# --- AudioListener2D ---
	audio_listener = AudioListener2D.new()
	audio_listener.name = "AudioListener2D"
	add_child(audio_listener)
	var center = get_viewport().size / 2
	audio_listener.position = center
	
	# --- Создаём спрайт фонарика, если нет ---
	if not flashlight_sprite:
		flashlight_sprite = Sprite2D.new()
		flashlight_sprite.name = "FlashlightSprite"
		var image = Image.create(200, 200, false, Image.FORMAT_RGBA8)
		image.fill(Color(0, 0, 0, 0))
		for x in 200:
			for y in 200:
				var dist = Vector2(x, y).distance_to(Vector2(100, 100))
				if dist < 100:
					var alpha = 1.0 - (dist / 100.0)
					image.set_pixel(x, y, Color(1, 0.9, 0.6, alpha * 0.5))
		flashlight_sprite.texture = ImageTexture.create_from_image(image)
		flashlight_sprite.centered = true
		add_child(flashlight_sprite)
	flashlight_sprite.modulate.a = 0
	
	# --- Настройка коллижн-бокса фонарика (исправлено) ---
	flashlight_collision.disabled = true   # <-- правильно
	flashlight_area.area_entered.connect(_on_flashlight_area_entered)
	flashlight_area.area_exited.connect(_on_flashlight_area_exited)
	
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
	
	# --- Добавление персонажей ---
	var map = $CameraLayer/Map
	if map and manager:
		var char1 = map.get_node_or_null("Char2011x")
		var char2 = map.get_node_or_null("CharMyst")
		var char3 = map.get_node_or_null("CharNMI")
		if char1: manager.add_character(char1, 8, 7, "2011x")
		if char2: manager.add_character(char2, 5, 7, "MystCrimson")
		if char3: manager.add_character(char3, 3, 7, "NMI")
		manager.attack_detected.connect(_on_attack_detected)
		manager.myst_crimson_state_changed.connect(_on_myst_state_changed)
	else:
		push_error("Map or AnimatronicsManager not found!")

# ===== КОЛЛИЖН-БОКС ФОНАРИКА =====
func _on_flashlight_area_entered(area: Area2D):
	print("Area entered: ", area.name, " parent: ", area.get_parent().name)
	if not flashlight_on or is_game_over:
		return
	if area.name == "CollisionArea":
		current_target_area = area
		manager.set_flashlight_active(true)
		manager.reset_myst_crimson_timer()
		print("Flashlight hit MysticCrimson area")

func _on_flashlight_area_exited(area: Area2D):
	if area == current_target_area:
		current_target_area = null
		flashlight_timer = 0.0
		manager.set_flashlight_active(false)
		print("Flashlight left MysticCrimson area")

# ===== ОСНОВНОЙ ЦИКЛ =====
func _process(delta: float) -> void:
	# --- Энергия ---
	var drain = power_drain
	if left_door_closed: drain += 0.25
	if right_door_closed: drain += 0.25
	if vent_closed: drain += 0.15
	if camera_mode: drain += camera_power_drain
	if flashlight_on: drain += 0.1
	
	power = max(power - drain * delta, 0.0)
	power_label.text = "Power: %d%%" % int(power)
	
	# --- Управление фонариком ---
	var ctrl_pressed = Input.is_key_pressed(KEY_CTRL)
	if ctrl_pressed and not flashlight_on and not is_game_over:
		_turn_on_flashlight()
	elif not ctrl_pressed and flashlight_on:
		_turn_off_flashlight()
	
	# --- Обновление позиции фонарика и коллижн-бокса ---
	if flashlight_on:
		var mouse_pos = get_global_mouse_position()
		flashlight_sprite.global_position = mouse_pos
		flashlight_area.global_position = mouse_pos
		flashlight_collision.disabled = false   # <-- включаем
		print("Flashlight pos: ", flashlight_area.global_position)
	else:
		flashlight_collision.disabled = true    # <-- выключаем
		flashlight_timer = 0.0
		manager.set_flashlight_active(false)
	
	# --- Накопление времени, если светим на проём ---
	if flashlight_on and current_target_area and manager and not is_game_over:
		var required_time = manager.get_myst_crimson_wait_time()
		if required_time > 0:
			flashlight_timer += delta
			print("Flashlight timer: ", flashlight_timer, " / ", required_time)
			if flashlight_timer >= required_time:
				manager.flashlight_check()
				flashlight_timer = 0.0
				current_target_area = null
				manager.set_flashlight_active(false)
				print("MystCrimson banished!")
		else:
			flashlight_timer = 0.0
	
	# --- Движение аниматроников ---
	if manager and not is_game_over:
		manager.process_movement(delta)



# ===== ФОНАРИК =====
func _turn_on_flashlight():
	flashlight_on = true
	flashlight_sprite.modulate.a = 1.0
	if flashlight_sound and flashlight_sound.stream:
		flashlight_sound.play()
	print("Flashlight ON")

func _turn_off_flashlight():
	flashlight_on = false
	flashlight_sprite.modulate.a = 0
	flashlight_collision.disabled = true   # <-- выключаем
	flashlight_timer = 0.0
	current_target_area = null
	manager.set_flashlight_active(false)
	if flashlight_sound and flashlight_sound.stream:
		flashlight_sound.play()
	print("Flashlight OFF")

# ===== СПРАЙТ MYSTIC CRIMSON =====
func _on_myst_state_changed(room_id: int, state: int):
	var show_sprite = (state == 2)  # WAITING_AT_DOOR
	var sprite: Sprite2D = null
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
