extends Node2D

var rooms = {}
@onready var manager: AnimatronicsManager = get_node("/root/Office/AnimatronicsManager")
var selected_camera := 0

func _ready():
	# Ищем все дочерние узлы с именами, начинающимися с "Room"
	for child in get_children():
		if child.name.begins_with("Room"):
			var id = int(child.name.substr(4))  # извлекаем номер комнаты
			if id > 0:   # принимаем любые номера (1,2,3,...)
				rooms[id] = child
				var button = child.get_node_or_null("ClickButton")
				if button and button is Button:
					button.pressed.connect(_on_room_button_pressed.bind(id))
	
	if manager:
		manager.characters_updated.connect(_update_positions)
		manager.attack_detected.connect(_on_attack_detected)
	else:
		push_error("AnimatronicsManager not found!")
	
	_update_positions()
	clear_highlight()

func _update_positions():
	if not manager:
		return
	for character in manager.characters:
		var room = rooms.get(character.room)
		if not room:
			continue
		
		# Отображение персонажей в состоянии WAITING_AT_DOOR (проём)
		if character.state == 2:  # CharState.WAITING_AT_DOOR
			character.node.visible = true  # видим для отладки
			var center = room.position + room.size / 2
			var base_pos = center - character.node.size / 2
			# Смещение в зависимости от комнаты (только для защитных 1,2,3)
			match character.room:
				1:  # левая дверь – смещаем вправо
					base_pos += Vector2(60, 0)
				2:  # правая дверь – смещаем влево
					base_pos += Vector2(-60, 0)
				3:  # вентиляция – смещаем вниз
					base_pos += Vector2(0, 60)
				# Если добавите новые защитные комнаты, пропишите смещения здесь
			character.node.position = base_pos
		else:
			# Обычное отображение в центре комнаты
			var center = room.position + room.size / 2
			character.node.position = center - character.node.size / 2
			character.node.visible = true
	
	if selected_camera != 0:
		_update_camera_info(selected_camera)

func _on_room_button_pressed(room_id):
	select_camera(room_id)

func select_camera(cam_id):
	clear_highlight()
	selected_camera = cam_id
	var room = rooms.get(cam_id)
	if room:
		room.modulate = Color(0.6, 0.6, 0.6)
		_update_camera_info(cam_id)

func _update_camera_info(cam_id):
	if not manager:
		return
	var has_any = false
	for character in manager.characters:
		if character.room == cam_id:
			has_any = true
			break
	if has_any:
		print("Camera ", cam_id, " has animatronics!")
	else:
		print("Camera ", cam_id, " empty.")

func clear_highlight():
	for id in rooms.keys():
		rooms[id].modulate = Color(1, 1, 1)

func _on_attack_detected(character_name, defense_type):
	pass  # можно добавить визуальный эффект
