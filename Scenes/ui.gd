extends CanvasLayer

func _ready():
	# Получаем размер окна
	var screen_size = get_viewport().size
	var screen_width = screen_size.x
	var screen_height = screen_size.y
	
	# Настройки зон: ширина каждой зоны ~ 90 пикселей
	var zone_width = 90
	var zone_height = screen_height  # на всю высоту
	
	# Создаём зоны или переиспользуем существующие
	# Предполагаем, что у вас уже есть шесть узлов с именами PanLeft3, PanLeft2, PanLeft1, PanRight1, PanRight2, PanRight3
	var zones = {
		"PanLeft3": 0,
		"PanLeft2": zone_width,
		"PanLeft1": zone_width * 2,
		"PanRight1": screen_width - zone_width * 3,
		"PanRight2": screen_width - zone_width * 2,
		"PanRight3": screen_width - zone_width
	}
	
	for zone_name in zones.keys():
		var zone = get_node(zone_name)
		if zone:
			zone.position = Vector2(zones[zone_name], 0)
			zone.size = Vector2(zone_width, zone_height)
			# Делаем невидимыми
			zone.modulate.a = 0.0
