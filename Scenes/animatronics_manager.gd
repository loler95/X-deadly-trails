class_name AnimatronicsManager
extends Node

# --- Данные персонажей ---
var characters = []

# --- Маршруты ---
var routes = {
	1: [4],
	2: [4],
	3: [4],
	4: [1, 2, 3]
}

# --- Соответствие комнат защите ---
var defense_map = {
	1: "left_door",
	2: "right_door",
	3: "vent"
}

# --- Состояния ---
enum CharState { IDLE, AT_CAMERA, WAITING_AT_DOOR }

var tick_timer := 0.0
var tick_interval := 0.5
var is_attacking := false

signal characters_updated()
signal attack_detected(character_name: String, defense_type: String)

func add_character(node, speed: int, start_room: int = 4, char_name: String = ""):
	characters.append({
		"node": node,
		"room": start_room,
		"speed": speed,
		"name": char_name if char_name != "" else "Unknown",
		"state": CharState.IDLE,
		"timer": 0.0,
		"wait_time": 0.0
	})
	emit_signal("characters_updated")

func process_movement(delta):
	if is_attacking:
		return
	
	var office = get_node("/root/Office")
	
	# === Мгновенная проверка для WAITING_AT_DOOR ===
	if office:
		for character in characters:
			if character.state == CharState.WAITING_AT_DOOR:
				var def = defense_map.get(character.room)
				if def:
					var closed = false
					match def:
						"left_door":  closed = office.left_door_closed
						"right_door": closed = office.right_door_closed
						"vent":       closed = office.vent_closed
					if closed:
						# Стук
						if office.has_method("play_knock"):
							var pan = 0.0
							match character.room:
								1: pan = -1.0
								2: pan = 1.0
								3: pan = 0.0
							office.play_knock(pan)
						
						character.room = 4
						character.state = CharState.IDLE
						character.timer = 0.0
						print(character.name, " immediately retreated because defense closed.")
						emit_signal("characters_updated")
	
	# === Таймеры ===
	for character in characters:
		if character.state == CharState.AT_CAMERA or character.state == CharState.WAITING_AT_DOOR:
			character.timer += delta
			if character.timer >= character.wait_time:
				_on_state_timeout(character)
	
	# === Движение IDLE ===
	tick_timer += delta
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_try_move_all()

func _on_state_timeout(character):
	var office = get_node("/root/Office")
	if not office:
		return
	
	var def = defense_map.get(character.room)
	if not def:
		return
	
	if character.state == CharState.AT_CAMERA:
		var closed = false
		match def:
			"left_door":  closed = office.left_door_closed
			"right_door": closed = office.right_door_closed
			"vent":       closed = office.vent_closed
		
		if closed:
			character.timer = 0.0
			print(character.name, " waiting at camera, door closed, resetting timer")
			return
		
		character.state = CharState.WAITING_AT_DOOR
		character.timer = 0.0
		var max_wait = 5.0
		var min_wait = 1.0
		var speed_factor = clamp(character.speed / 20.0, 0.0, 1.0)
		character.wait_time = max_wait - (max_wait - min_wait) * speed_factor
		print(character.name, " entered doorway, waiting ", character.wait_time, " sec")
		emit_signal("characters_updated")
		
		if character.name == "2011x" and office.has_method("play_alert"):
			var pan = 0.0
			match character.room:
				1: pan = -1.0
				2: pan = 1.0
				3: pan = 0.0
			office.play_alert(pan)
	
	elif character.state == CharState.WAITING_AT_DOOR:
		var closed = false
		match def:
			"left_door":  closed = office.left_door_closed
			"right_door": closed = office.right_door_closed
			"vent":       closed = office.vent_closed
		
		if closed:
			character.room = 4
			character.state = CharState.IDLE
			character.timer = 0.0
			print(character.name, " retreated because defense closed (timeout check).")
			emit_signal("characters_updated")
			return
		
		is_attacking = true
		print("WARNING: ", character.name, " attacks through ", def, " after waiting!")
		emit_signal("attack_detected", character.name, def)

func _try_move_all():
	for character in characters:
		if character.state != CharState.IDLE:
			continue
		
		var roll = randi_range(1, 20)
		if roll <= character.speed:
			var current = character.room
			var possible = routes[current]
			var next_room = possible[randi() % possible.size()]
			character.room = next_room
			print(character.name, " moved from ", current, " to ", next_room)
			
			if next_room in defense_map:
				character.state = CharState.AT_CAMERA
				character.timer = 0.0
				character.wait_time = 4.5
				print(character.name, " arrived at camera room ", next_room, ", waiting 4.5 sec")
	
	emit_signal("characters_updated")
