extends Node2D

var flashlight_on := false

var current_target_area: Area2D = null # куда светит фонарик

var flashlight_timer := 0.0
var is_charging := false 

# --- Менеджеры ---
@onready var animatronic_manager = get_parent().get_node("AnimatronicsManager")
@onready var game_manager = get_parent()

# --- Узлы ---
@onready var flashlight_area = get_parent().get_node("FlashlightArea")
@onready var flashlight_collision = flashlight_area.get_child(0)

@onready var flashlight_sound: AudioStreamPlayer2D = $FlashlightSound if has_node("FlashlightSound") else null
@onready var flashlight_sprite = get_parent().get_node("FlashlightSprite")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	current_target_area = null
	if flashlight_sound and flashlight_sound.stream:
		flashlight_sound.play()
	print("Flashlight OFF")
	
## Основной цикл
func _process(delta: float) -> void:
	# --- Управление фонариком ---
	var ctrl_pressed = Input.is_key_pressed(KEY_CTRL)
	if ctrl_pressed and not flashlight_on and not game_manager.is_game_over:
		_turn_on_flashlight()
	elif not ctrl_pressed and flashlight_on:
		_turn_off_flashlight()
	
	# --- Обновление позиции фонарика и коллижн-бокса ---
	if flashlight_on:
		var mouse_pos = get_global_mouse_position()
		flashlight_sprite.global_position = mouse_pos
		flashlight_area.global_position = mouse_pos
		flashlight_collision.disabled = false   # <-- включаем
	else:
		flashlight_collision.disabled = true    # <-- выключаем
		
		
	if is_charging and not game_manager.is_game_over:
		var required_time = animatronic_manager.get_myst_crimson_wait_time()
		if required_time > 0:
			flashlight_timer += delta
			print("Flashlight timer: ", flashlight_timer, " / ", required_time)
			if flashlight_timer >= required_time:
				animatronic_manager.gtfo_mystic()
				is_charging = false
				flashlight_timer = 0.0
				current_target_area = null
				print("MystCrimson banished!")
	else:
			flashlight_timer = 0.0
		

func _on_flashlight_area_exited(area: Area2D):
	if area == current_target_area:
		current_target_area = null
		flashlight_timer = 0.0
		game_manager.set_flashlight_active(false)
		print("Flashlight left MysticCrimson area")

func _on_flashlight_area_area_entered(area: Area2D) -> void:
	print("Area entered: ", area.name, " parent: ", area.get_parent().name)
	if not flashlight_on or game_manager.is_game_over:
		return
	if area.name == animatronic_manager.get_myst_crimson_zone():
		current_target_area = area
		is_charging = true
		flashlight_timer = 0.0
		animatronic_manager.reset_myst_crimson_timer()   # сбросить таймер атаки
		print("Flashlight hit MysticCrimson area")
	
