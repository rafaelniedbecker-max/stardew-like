class_name DayNightCycle
extends Node

## Ciclo Dia/Noite com iluminação dinâmica, sombras, cores

@export var light_canvas: CanvasModulate = null
@export var shadow_canvas: CanvasModulate = nil
@export var sun_light: DirectionalLight2D = nil
@export var ambient_light: WorldEnvironment = nil

## Configuração de cores por hora
const TIME_COLORS = {
	# Madrugada (4-6h)
	400: Color(0.3, 0.2, 0.4, 1.0),   # Azul escuro
	500: Color(0.4, 0.3, 0.5, 1.0),
	600: Color(0.8, 0.5, 0.3, 1.0),   # Nascer do sol - laranja

	# Manhã (7-11h)
	700: Color(0.95, 0.85, 0.7, 1.0),
	800: Color(1.0, 0.95, 0.85, 1.0),
	900: Color(1.0, 1.0, 0.95, 1.0),
	1000: Color(1.0, 1.0, 1.0, 1.0),
	1100: Color(1.0, 1.0, 1.0, 1.0),

	# Meio-dia (12-13h)
	1200: Color(1.0, 1.0, 1.0, 1.0),  # Branco puro
	1300: Color(1.0, 1.0, 1.0, 1.0),

	# Tarde (14-17h)
	1400: Color(1.0, 1.0, 0.98, 1.0),
	1500: Color(1.0, 0.98, 0.95, 1.0),
	1600: Color(1.0, 0.95, 0.85, 1.0),
	1700: Color(1.0, 0.9, 0.75, 1.0),

	# Pôr do sol (18-20h)
	1800: Color(1.0, 0.7, 0.5, 1.0),   # Laranja forte
	1900: Color(0.9, 0.5, 0.3, 1.0),   # Vermelho/laranja
	2000: Color(0.6, 0.3, 0.4, 1.0),   # Roxo/azul escuro

	# Noite (21-3h)
	2100: Color(0.3, 0.2, 0.4, 1.0),
	2200: Color(0.2, 0.15, 0.35, 1.0),
	2300: Color(0.15, 0.1, 0.3, 1.0),
	2400: Color(0.1, 0.08, 0.25, 1.0),
	2500: Color(0.1, 0.08, 0.25, 1.0),
	2600: Color(0.1, 0.08, 0.25, 1.0),
	2700: Color(0.15, 0.1, 0.3, 1.0),
	2800: Color(0.2, 0.15, 0.35, 1.0)
}

## Intensidade da luz direcional (sol/lua)
const LIGHT_INTENSITY = {
	600: 0.3, 700: 0.5, 800: 0.7, 900: 0.9, 1000: 1.0,
	1100: 1.0, 1200: 1.0, 1300: 1.0, 1400: 0.9, 1500: 0.8,
	1600: 0.6, 1700: 0.4, 1800: 0.2, 1900: 0.1, 2000: 0.05,
	2100: 0.03, 2200: 0.02, 2300: 0.02, 2400: 0.02,
	2500: 0.02, 2600: 0.02, 2700: 0.02, 2800: 0.03,
	2900: 0.05, 3000: 0.1, 3100: 0.15, 3200: 0.2, 3300: 0.25,
	3400: 0.3, 3500: 0.35, 3600: 0.4, 3700: 0.45, 3800: 0.5,
	3900: 0.55, 4000: 0.6, 4100: 0.65, 4200: 0.7, 4300: 0.8,
	4400: 0.9, 4500: 1.0
}

## Cor da luz direcional
const LIGHT_COLOR = {
	600: Color(1.0, 0.6, 0.3),  # Nascer - laranja
	700: Color(1.0, 0.8, 0.5),
	800: Color(1.0, 0.95, 0.8),
	900: Color(1.0, 1.0, 0.95),
	1200: Color(1.0, 1.0, 1.0),  # Meio-dia - branco
	1700: Color(1.0, 0.9, 0.7),
	1800: Color(1.0, 0.6, 0.3),  # Pôr do sol
	1900: Color(1.0, 0.4, 0.2),
	2000: Color(0.6, 0.4, 0.6),
	2200: Color(0.4, 0.4, 0.6),  # Noite - azul lua
	2400: Color(0.3, 0.3, 0.5),
	200: Color(0.3, 0.3, 0.5),
	400: Color(0.4, 0.4, 0.6),
	500: Color(0.5, 0.4, 0.6)
}

var _current_time: int = 600
var _tween: Tween = null
var _is_night: bool = false

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_setup_lighting_nodes()

	if TimeManager:
		TimeManager.minute_changed.connect(_on_minute_changed)
		TimeManager.hour_changed.connect(_on_hour_changed)

	# Aplica iluminação inicial
	if GameManager:
		_on_minute_changed(GameManager.current_time)

func _setup_lighting_nodes() -> void:
	# CanvasModulate principal
	if not light_canvas:
		light_canvas = CanvasModulate.new()
		light_canvas.name = "DayNightModulate"
		get_tree().root.get_child(0).add_child(light_canvas)

	# DirectionalLight2D para sombras
	if not sun_light:
		sun_light = DirectionalLight2D.new()
		sun_light.name = "SunLight"
		sun_light.enabled = true
		sun_light.light_energy = 1.0
		sun_light.light_color = Color(1.0, 1.0, 0.9)
		sun_light.shadow_enabled = true
		sun_light.shadow_max_distance = 2000
		sun_light.shadow_normal_bias = 0.5
		sun_light.light_angular_distance = 0.5
		get_tree().root.get_child(0).add_child(sun_light)

	# WorldEnvironment para sky/ambient
	if not ambient_light:
		ambient_light = WorldEnvironment.new()
		ambient_light.name = "WorldEnv"
		ambient_light.environment = Environment.new()
		ambient_light.environment.background_mode = Environment.BACKGROUND_CANVAS
		ambient_light.environment.ambient_light_color = Color(0.3, 0.3, 0.4)
		ambient_light.environment.ambient_light_energy = 0.5
		get_tree().root.get_child(0).add_child(ambient_light)

## ==================== ATUALIZAÇÃO POR MINUTO ====================
func _on_minute_changed(new_time: int) -> void:
	_current_time = new_time
	_update_lighting()

func _on_hour_changed(hour: int) -> void:
	_check_night_transition(hour)

	# Atualiza WeatherEffects para vagalumes
	if WeatherEffects:
		WeatherEffects.on_hour_changed(hour)

func _update_lighting() -> void:
	var time = _current_time

	# Interpola cor baseada nos keyframes
	var modulate_color = _interpolate_color(time, TIME_COLORS)
	var light_intensity = _interpolate_float(time, LIGHT_INTENSITY)
	var light_color = _interpolate_color(time, LIGHT_COLOR)

	# Aplica CanvasModulate
	if light_canvas:
		light_canvas.color = modulate_color

	# Aplica luz direcional (sol/lua)
	if sun_light:
		sun_light.light_energy = light_intensity
		sun_light.light_color = light_color

		# Rotaciona sol baseado na hora
		var angle = _time_to_sun_angle(time)
		sun_light.rotation = angle

		# Sombra só de dia
		sun_light.shadow_enabled = (time >= 500 and time <= 2000)

	# Ajusta ambient light
	if ambient_light and ambient_light.environment:
		var ambient_energy = clamp(light_intensity * 0.5 + 0.2, 0.1, 1.0)
		ambient_light.environment.ambient_light_energy = ambient_energy
		ambient_light.environment.ambient_light_color = modulate_color.lerp(Color(0.2, 0.2, 0.3), 0.5)

func _interpolate_color(time: int, color_map: Dictionary) -> Color:
	var keys = color_map.keys()
	keys.sort()

	var prev_key = keys[0]
	var next_key = keys[-1]

	for i in range(keys.size() - 1):
		if time >= keys[i] and time < keys[i + 1]:
			prev_key = keys[i]
			next_key = keys[i + 1]
			break

	var c1 = color_map[prev_key]
	var c2 = color_map[next_key]

	var t = 0.0
	if next_key != prev_key:
		t = (time - prev_key) / (next_key - prev_key)

	return c1.lerp(c2, t)

func _interpolate_float(time: int, float_map: Dictionary) -> float:
	var keys = float_map.keys()
	keys.sort()

	var prev_key = keys[0]
	var next_key = keys[-1]

	for i in range(keys.size() - 1):
		if time >= keys[i] and time < keys[i + 1]:
			prev_key = keys[i]
			next_key = keys[i + 1]
			break

	var v1 = float_map[prev_key]
	var v2 = float_map[next_key]

	var t = 0.0
	if next_key != prev_key:
		t = (time - prev_key) / (next_key - prev_key)

	return lerp(v1, v2, t)

func _time_to_sun_angle(time: int) -> float:
	# 6:00 = -90° (leste), 12:00 = 0° (cima), 18:00 = 90° (oeste), 0:00 = -90° (abaixo)
	var hour_float = time / 100.0
	var angle = (hour_float - 12.0) * (PI / 12.0) - PI / 2.0
	return angle

func _check_night_transition(hour: int) -> void:
	var was_night = _is_night
	_is_night = (hour >= 20 or hour < 6)

	if was_night != _is_night:
		if _is_night:
			_on_night_start()
		else:
			_on_day_start()

func _on_night_start() -> void:
	print("DayNightCycle: Noite iniciada")
	# Ativa luzes da fazenda, vagalumes, etc.
	if GameManager:
		GameManager.emit_signal("night_started")

	# Liga luzes dos edifícios
	_activate_building_lights(true)

func _on_day_start() -> void:
	print("DayNightCycle: Dia iniciado")
	if GameManager:
		GameManager.emit_signal("day_started")

	_activate_building_lights(false)

func _activate_building_lights(on: bool) -> void:
	var buildings = get_tree().get_nodes_in_group("buildings")
	for b in buildings:
		if b.has_method("set_lights"):
			b.set_lights(on)

## ==================== UTILIDADES ====================
func get_time_of_day_name() -> String:
	var h = _current_time / 100
	if h >= 5 and h < 7: return "Nascer do Sol"
	if h >= 7 and h < 12: return "Manhã"
	if h >= 12 and h < 14: return "Meio-dia"
	if h >= 14 and h < 18: return "Tarde"
	if h >= 18 and h < 20: return "Pôr do Sol"
	return "Noite"

func is_night() -> bool:
	return _is_night

func get_light_level() -> float:
	# Retorna 0.0 (escuro) a 1.0 (claro)
	if _current_time >= 500 and _current_time <= 1900:
		return 1.0
	elif _current_time >= 400 and _current_time < 500:
		return 0.3
	elif _current_time >= 1900 and _current_time < 2100:
		return 0.3
	return 0.1

## ==================== DEBUG ====================
func _debug_set_time(time: int) -> void:
	_current_time = time
	_update_lighting()