extends Node2D

# --- Переменные ---
var power: float = 100.0
var power_drain: float = 0.3

var left_door_closed := false
var right_door_closed := false
var vent_closed := false

var camera_mode := false
var camera_power_drain := 0.3


# --- Ссылки на узлы ---
@onready var power_label: Label = $UI/PowerLabel
@onready var left_door: ColorRect = $World/LeftDoor
@onready var right_door: ColorRect = $World/RightDoor
@onready var vent: ColorRect = $World/Vent
@onready var camera_layer: CanvasLayer = $CameraLayer
@onready var camera_button: Button = $UI/CameraButton

func _ready() -> void:
	# Подключаем наведение на кнопку - переключение режима
	camera_button.mouse_entered.connect(_toggle_camera_mode)
	
	# Начальное состояние
	left_door.modulate.a = 0.3
	right_door.modulate.a = 0.3
	vent.modulate.a = 0.3
	camera_layer.visible = false
	camera_button.text = "CAM"
	
	# Устанавливаем слои, чтобы UI был поверх камер
	$UI.layer = 1
	$CameraLayer.layer = 0

func _process(delta: float) -> void:
	var drain = power_drain
	if left_door_closed: drain += 0.25
	if right_door_closed: drain += 0.25
	if vent_closed: drain += 0.15
	if camera_mode: drain += camera_power_drain
	
	power = max(power - drain * delta, 0.0)
	power_label.text = "Power: %d%%" % int(power)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A:
				_on_left_door_pressed()
			KEY_D:
				_on_right_door_pressed()
			KEY_W:
				_on_vent_pressed()
		
		if event.keycode == KEY_SPACE or event.keycode == KEY_E:
			_toggle_camera_mode()
		
		if camera_mode:
			match event.keycode:
				KEY_1:
					_select_camera(1)
				KEY_2:
					_select_camera(2)
				KEY_3:
					_select_camera(3)
				KEY_4:
					_select_camera(4)

# --- Функции управления дверями и вентиляцией ---
func _on_left_door_pressed() -> void:
	left_door_closed = !left_door_closed
	left_door.modulate.a = 1.0 if left_door_closed else 0.3
	left_door.color = Color(0.1, 0.1, 0.1) if left_door_closed else Color(0.2, 0.2, 0.3)
	print("Left door: ", "closed" if left_door_closed else "open")

func _on_right_door_pressed() -> void:
	right_door_closed = !right_door_closed
	right_door.modulate.a = 1.0 if right_door_closed else 0.3
	right_door.color = Color(0.1, 0.1, 0.1) if right_door_closed else Color(0.2, 0.2, 0.3)
	print("Right door: ", "closed" if right_door_closed else "open")

func _on_vent_pressed() -> void:
	vent_closed = !vent_closed
	vent.modulate.a = 1.0 if vent_closed else 0.3
	vent.color = Color(0.1, 0.1, 0.1) if vent_closed else Color(0.3, 0.3, 0.3)
	print("Vent: ", "closed" if vent_closed else "open")

# --- Режим камер ---
func _toggle_camera_mode() -> void:
	camera_mode = !camera_mode
	camera_layer.visible = camera_mode
	camera_button.text = "BACK" if camera_mode else "CAM"
	print("Camera mode: ", "ON" if camera_mode else "OFF")

func _select_camera(cam_id: int):
	print("Selected camera: ", cam_id)
	var map = $CameraLayer/Map
	if map and map.has_method("select_camera"):
		map.select_camera(cam_id)
