extends Camera2D

var max_offset := 320.0
var current_offset := 0.0
var target_offset := 0.0
var sensitivity := 0.5   # регулируйте скорость
var invert := false      # true – инвертированное управление

func _ready():
	# Курсор видим, но не выходит за пределы окна (решает проблему второго монитора)
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _input(event):
	if event is InputEventMouseMotion:
		var direction = 1.0
		if invert:
			direction = -1.0
		target_offset += event.relative.x * sensitivity * direction
		target_offset = clamp(target_offset, -max_offset, max_offset)

func _process(delta):
	current_offset = lerp(current_offset, target_offset, 10.0 * delta)
	offset.x = current_offset
