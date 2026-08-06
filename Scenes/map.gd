extends Node2D

# --- Комнаты (находятся динамически) ---
var rooms = {}

# --- Персонажи ---
var characters = []

# --- Маршруты ---
var routes = {
	1: [4],
	2: [4],
	3: [4],
	4: [1, 2, 3]
}

var defense_map = {
	1: "left_door",
	2: "right_door",
	3: "vent"
}

var selected_camera := 0
var tick_timer := 0.0
var tick_interval := 4.5

func _ready():
	# Находим все комнаты и подключаем кнопки
	for child in get_children():
		if child.name.begins_with("Room"):
			var id = int(child.name.substr(4))
			if id > 0 and id <= 4:
				rooms[id] = child
				var button = child.get_node_or_null("ClickButton")
				if button and button is Button:
					button.pressed.connect(_on_room_button_pressed.bind(id))
				else:
					push_error("Room", id, " has no ClickButton or it's not a Button!")
	
	# Проверяем, что все комнаты найдены
	for id in range(1, 5):
		if not rooms.has(id):
			push_error("Room", id, " not found in Map! Please create it.")
	
	# Настраиваем персонажей
	var char_nodes = {
		"Char2011x": 8,
		"CharMyst": 5,
		"CharNMI": 3
	}
	for name in char_nodes.keys():
		var node = get_node_or_null(name)
		if node:
			characters.append({
				"node": node,
				"room": 4,
				"speed": char_nodes[name],
				"name": name
			})
		else:
			push_error("Character node '", name, "' not found in Map!")
	
	# Заглушка, если персонажей нет
	if characters.is_empty():
		push_warning("No characters found, creating dummy one.")
		var dummy = ColorRect.new()
		dummy.name = "Dummy1"
		dummy.size = Vector2(40, 40)
		dummy.color = Color.RED
		add_child(dummy)
		characters.append({"node": dummy, "room": 4, "speed": 5, "name": "Dummy"})
	
	update_positions()
	clear_highlight()

func _process(delta):
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		try_move_all()

# --- Обработка нажатия на кнопку комнаты ---
func _on_room_button_pressed(room_id):
	select_camera(room_id)

# --- Перемещение персонажей с вероятностью ---
func try_move_all():
	for character in characters:
		var roll = randi_range(1, 20)
		if roll <= character.speed:
			var current = character.room
			var possible = routes[current]
			var next_room = possible[randi() % possible.size()]
			character.room = next_room
			print(character.name, " moved from ", current, " to ", next_room)
	update_positions()
	check_attacks()

# --- Обновление позиций на карте ---
func update_positions():
	for character in characters:
		var room = rooms.get(character.room)
		if not room:
			continue
		var center = room.position + room.size / 2
		character.node.position = center - character.node.size / 2
		character.node.visible = true

# --- Выбор камеры (подсветка) ---
func select_camera(cam_id):
	clear_highlight()
	selected_camera = cam_id
	var room = rooms.get(cam_id)
	if room:
		room.modulate = Color(0.6, 0.6, 0.6)
		var has_any = false
		for character in characters:
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

# --- Проверка атак ---
func check_attacks():
	var office = get_node("/root/Office")
	if not office:
		return
	for character in characters:
		var pos = character.room
		if pos in defense_map:
			var def = defense_map[pos]
			var closed = false
			match def:
				"left_door":  closed = office.left_door_closed
				"right_door": closed = office.right_door_closed
				"vent":       closed = office.vent_closed
			if not closed:
				print("WARNING: ", character.name, " attacks through ", def, " - defense open!")
				# office.game_over()
			else:
				print("SAFE: ", character.name, " at ", def, ", defense closed.")
