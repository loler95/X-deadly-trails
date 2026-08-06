extends Camera2D

var max_offset: float = 350.0
var pan_speed: float = 12.0
var current_offset: float = 0.0

func _process(delta: float) -> void:
	var mouse_x = get_viewport().get_mouse_position().x
	var screen_width = get_viewport().size.x
	
	# Зоны по краям экрана
	if mouse_x < 100:
		current_offset -= pan_speed
	elif mouse_x > screen_width - 100:
		current_offset += pan_speed
	
	current_offset = clamp(current_offset, -max_offset, max_offset)
	
	# Двигаем камеру
	offset.x = current_offset
