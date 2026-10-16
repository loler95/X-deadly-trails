extends Node

var current_night := 1

# --- Конфигурация ночей ---
# speed = 0 → персонаж не появляется в эту ночь
var night_configs = {
	1: {"2011x": 20, "MystCrimson": 0,  "Imperfect": 0},
	2: {"2011x": 0,  "MystCrimson": 20, "Imperfect": 0},
	3: {"2011x": 0,  "MystCrimson": 0,  "Imperfect": 20},
	4: {"2011x": 10, "MystCrimson": 6,  "Imperfect": 5},
	5: {"2011x": 13, "MystCrimson": 8,  "Imperfect": 7},
	6: {"2011x": 16, "MystCrimson": 11, "Imperfect": 9},
}

var night_duration := 360.0   # 6 минут

func get_speed(char_name: String) -> int:
	var cfg = night_configs.get(current_night, {})
	return cfg.get(char_name, 0)

func set_night(n: int) -> void:
	current_night = clamp(n, 1, 6)
	print("Night set to: ", current_night)
	print("Speeds: ", night_configs[current_night])
