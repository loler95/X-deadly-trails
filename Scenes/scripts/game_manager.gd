extends Node

# ===== СИГНАЛЫ =====
signal night_started(night_number: int)
signal night_ended(won: bool)
signal time_updated(time_string: String)

# ===== ПЕРЕМЕННЫЕ НОЧИ =====
var current_night := 1
var night_duration := 360.0   # 6 минут в секундах
var time_passed := 0.0
var is_night_active := false
var game_won := false
var game_over := false

# ===== РОСТЕР (список персонажей для текущей ночи) =====
# Каждый элемент: { "name": str, "speed": int, "start_room": int }
var current_roster = []

# ===== МЕТОДЫ =====
func start_night(night: int):
	current_night = night
	time_passed = 0.0
	is_night_active = true
	game_won = false
	game_over = false
	_load_night_config(night)
	emit_signal("night_started", night)

func _load_night_config(night: int):
	match night:
		1:
			current_roster = [
				{"name": "2011x", "speed": 8, "start_room": 7},
				{"name": "MystCrimson", "speed": 5, "start_room": 7},
				{"name": "Imperfect", "speed": 3, "start_room": 7}
			]
			night_duration = 360.0   # 6 минут
		2:
			current_roster = [
				{"name": "2011x", "speed": 9, "start_room": 7},
				{"name": "MystCrimson", "speed": 6, "start_room": 7},
				{"name": "Furniss", "speed": 7, "start_room": 7},
				{"name": "NMI", "speed": 4, "start_room": 7}
			]
			night_duration = 420.0   # 7 минут
		_:
			# По умолчанию
			current_roster = [
				{"name": "2011x", "speed": 10, "start_room": 7},
				{"name": "MystCrimson", "speed": 7, "start_room": 7}
			]
			night_duration = 300.0

func process_night(delta: float):
	if not is_night_active or game_over or game_won:
		return
	time_passed += delta
	_update_time_label()
	if time_passed >= night_duration:
		_win_night()

func _update_time_label():
	var progress = time_passed / night_duration
	var game_minutes = progress * 360.0
	var hours = 12 + int(game_minutes / 60)
	var minutes = int(game_minutes) % 60
	var display_hours = hours if hours <= 12 else hours - 12
	if display_hours == 0:
		display_hours = 12
	var time_string = "%02d:%02d" % [display_hours, minutes]
	emit_signal("time_updated", time_string)

func _win_night():
	is_night_active = false
	game_won = true
	emit_signal("night_ended", true)

func lose_night():
	is_night_active = false
	game_over = true
	emit_signal("night_ended", false)

func get_current_roster():
	return current_roster

func get_night_duration():
	return night_duration
