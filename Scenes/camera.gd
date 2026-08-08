extends Camera2D

var max_offset := 320.0
var current_offset := 0.0
var target_offset := 0.0
var sensitivity := 0.5
var invert := false

func _ready():
	# Ограничиваем курсор окном
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
