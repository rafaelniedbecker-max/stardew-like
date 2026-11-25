extends Node

## Sistema de Efeitos Climáticos Visuais: chuva, neve, tempestade, pétalas, folhas

@export var weather_root: Node2D = null

## Players de partículas por tipo
var _weather_particles: Dictionary = {}
var _current_weather: int = 0  # 0=Sol, 1=Chuva, 2=Tempestade, 3=Neve, 4=Chuva Verde
var _seasonal_effects: Dictionary = {}

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_create_weather_particles()
	_create_seasonal_effects()

	# Conecta ao GameManager
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)
		GameManager.weather_changed.connect(_on_weather_changed)

	# Aplica clima atual
	if GameManager:
		_set_weather(GameManager.today_weather)
		_set_seasonal(GameManager.current_season)

func _create_weather_particles() -> void:
	# CHUVA
	var rain = GPUParticles2D.new()
	rain.name = "Rain"
	rain.amount = 800
	rain.lifetime = 1.5
	rain.explosiveness = 0.0
	rain.spread = 5
	rain.gravity = Vector2(30, 500)
	rain.initial_velocity = 400
	rain.scale = 0.08
	rain.color = Color(0.6, 0.7, 0.9, 0.35)
	rain.color_ramp = _gradient(Color(0.6, 0.7, 0.9, 0.35), Color(0.5, 0.6, 0.8, 0.0))
	rain.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(1920, 200)
	rain.local_coords = false
	rain.one_shot = false
	_weather_particles[1] = rain

	# TEMPESTADE
	var storm = GPUParticles2D.new()
	storm.name = "Storm"
	storm.amount = 1200
	storm.lifetime = 1.0
	storm.explosiveness = 0.0
	storm.spread = 15
	storm.gravity = Vector2(100, 800)
	storm.initial_velocity = 600
	storm.scale = 0.08
	storm.color = Color(0.5, 0.55, 0.7, 0.4)
	storm.color_ramp = _gradient(Color(0.5, 0.55, 0.7, 0.4), Color(0.4, 0.45, 0.6, 0.0))
	storm.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	storm.emission_rect_extents = Vector2(1920, 200)
	storm.local_coords = false
	storm.one_shot = false
	_weather_particles[2] = storm

	# NEVE
	var snow = GPUParticles2D.new()
	snow.name = "Snow"
	snow.amount = 500
	snow.lifetime = 8.0
	snow.explosiveness = 0.0
	snow.spread = 10
	snow.gravity = Vector2(20, 100)
	snow.initial_velocity = 50
	snow.scale = 0.12
	snow.scale_curve = _curve_float(0.5, 1.0, 1.0)
	snow.color = Color(1.0, 1.0, 1.0, 0.5)
	snow.color_ramp = _gradient(Color(1.0, 1.0, 1.0, 0.5), Color(0.9, 0.9, 1.0, 0.0))
	snow.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.emission_rect_extents = Vector2(1920, 200)
	snow.local_coords = false
	snow.one_shot = false
	_weather_particles[3] = snow

	# CHUVA VERDE (Year 1+ Summer)
	var green_rain = GPUParticles2D.new()
	green_rain.name = "GreenRain"
	green_rain.amount = 600
	green_rain.lifetime = 2.0
	green_rain.explosiveness = 0.0
	green_rain.spread = 5
	green_rain.gravity = Vector2(10, 400)
	green_rain.initial_velocity = 350
	green_rain.scale = 0.1
	green_rain.color = Color(0.3, 0.9, 0.4, 0.4)
	green_rain.color_ramp = _gradient(Color(0.3, 0.9, 0.4, 0.4), Color(0.2, 0.7, 0.3, 0.0))
	green_rain.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	green_rain.emission_rect_extents = Vector2(1920, 200)
	green_rain.local_coords = false
	green_rain.one_shot = false
	_weather_particles[4] = green_rain

	# Splash de chuva no chão
	var rain_splash = GPUParticles2D.new()
	rain_splash.name = "RainSplash"
	rain_splash.amount = 200
	rain_splash.lifetime = 0.2
	rain_splash.explosiveness = 1.0
	rain_splash.spread = 360
	rain_splash.gravity = Vector2(0, 200)
	rain_splash.initial_velocity = 80
	rain_splash.scale = 0.1
	rain_splash.color = Color(0.6, 0.7, 0.9, 0.5)
	rain_splash.color_ramp = _gradient(Color(0.6, 0.7, 0.9, 0.5), Color(0.5, 0.6, 0.8, 0.0))
	rain_splash.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain_splash.emission_rect_extents = Vector2(1920, 1080)
	rain_splash.local_coords = false
	rain_splash.one_shot = false
	_weather_particles["rain_splash"] = rain_splash

func _create_seasonal_effects() -> void:
	# PÉTALAS - Primavera
	var petals = GPUParticles2D.new()
	petals.name = "Petals"
	petals.amount = 150
	petals.lifetime = 15.0
	petals.explosiveness = 0.0
	petals.spread = 45
	petals.gravity = Vector2(15, 30)
	petals.initial_velocity = 20
	petals.scale = 0.15
	petals.angular_velocity = 5
	petals.scale_curve = _curve_float(1.0, 1.0)
	petals.color = Color(1.0, 0.7, 0.8, 0.4)
	petals.color_ramp = _gradient(Color(1.0, 0.8, 0.9, 0.4), Color(0.9, 0.6, 0.7, 0.0))
	petals.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	petals.emission_rect_extents = Vector2(1920, 1080)
	petals.local_coords = false
	petals.one_shot = false
	_seasonal_effects[0] = petals  # Spring

	# VAGALUMES - Verão (noite)
	var fireflies = GPUParticles2D.new()
	fireflies.name = "Fireflies"
	fireflies.amount = 50
	fireflies.lifetime = 3.0
	fireflies.explosiveness = 0.0
	fireflies.spread = 360
	fireflies.gravity = Vector2(0, -10)
	fireflies.initial_velocity = 15
	fireflies.scale = 0.1
	fireflies.angular_velocity = 2
	fireflies.scale_curve = _curve_float(0.0, 1.0, 0.0)
	fireflies.color = Color(1.0, 1.0, 0.6, 0.8)
	fireflies.color_ramp = _gradient(Color(1.0, 1.0, 0.6, 0.8), Color(1.0, 0.8, 0.3, 0.0))
	fireflies.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(1920, 1080)
	fireflies.local_coords = false
	fireflies.one_shot = false
	_seasonal_effects["fireflies"] = fireflies

	# FOLHAS - Outono
	var leaves = GPUParticles2D.new()
	leaves.name = "Leaves"
	leaves.amount = 120
	leaves.lifetime = 12.0
	leaves.explosiveness = 0.0
	leaves.spread = 30
	leaves.gravity = Vector2(40, 60)
	leaves.initial_velocity = 30
	leaves.scale = 0.2
	leaves.angular_velocity = 8
	leaves.scale_curve = _curve_float(1.0, 1.0)
	leaves.color = Color(0.8, 0.4, 0.2, 0.4)
	leaves.color_ramp = _gradient(Color(0.9, 0.5, 0.2, 0.4), Color(0.6, 0.3, 0.1, 0.0))
	leaves.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	leaves.emission_rect_extents = Vector2(1920, 1080)
	leaves.local_coords = false
	leaves.one_shot = false
	_seasonal_effects[2] = leaves  # Fall

	# NEVE LEVE - Inverno (ambiente)
	var winter_snow = GPUParticles2D.new()
	winter_snow.name = "WinterSnow"
	winter_snow.amount = 200
	winter_snow.lifetime = 15.0
	winter_snow.explosiveness = 0.0
	winter_snow.spread = 10
	winter_snow.gravity = Vector2(10, 40)
	winter_snow.initial_velocity = 20
	winter_snow.scale = 0.1
	winter_snow.color = Color(1.0, 1.0, 1.0, 0.3)
	winter_snow.color_ramp = _gradient(Color(1.0, 1.0, 1.0, 0.3), Color(0.9, 0.9, 1.0, 0.0))
	winter_snow.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	winter_snow.emission_rect_extents = Vector2(1920, 1080)
	winter_snow.local_coords = false
	winter_snow.one_shot = false
	_seasonal_effects[3] = winter_snow  # Winter

func _gradient(from: Color, to: Color) -> Gradient:
	var g = Gradient.new()
	g.colors = PackedColorArray([from, to])
	return g

func _curve_float(start: float, mid: float, end: float) -> Curve:
	var c = Curve.new()
	c.add_point(Vector2(0.0, start))
	c.add_point(Vector2(0.5, mid))
	c.add_point(Vector2(1.0, end))
	return c

## ==================== CONTROLE DE CLIMA ====================
func _on_day_changed(day: int, season: int, year: int) -> void:
	_set_seasonal(season)
	if GameManager:
		_set_weather(GameManager.tomorrow_weather)

func _on_weather_changed(weather: int) -> void:
	_set_weather(weather)

func _set_weather(weather_type: int) -> void:
	# Para clima anterior
	if _current_weather != 0 and _weather_particles.has(_current_weather):
		var prev = _weather_particles[_current_weather]
		if prev.get_parent():
			prev.emitting = false
			prev.queue_free()

	# Para splash de chuva se não for chuva/tempestade
	if weather_type not in [1, 2] and _weather_particles.has("rain_splash"):
		var splash = _weather_particles["rain_splash"]
		if splash.get_parent():
			splash.emitting = false
			splash.queue_free()

	_current_weather = weather_type

	# Inicia novo clima
	if weather_type == 0:
		return  # Sol - sem partículas

	var particles = _weather_particles.get(weather_type)
	if not particles:
		return

	# Re-instancia para poder ter múltiplos
	var instance = particles.duplicate() as GPUParticles2D
	instance.name = "Weather_%s" % ["Rain", "Storm", "Snow", "GreenRain"][weather_type - 1]

	# Adiciona à cena (precisa de weather_root ou root do mundo)
	var target = weather_root if weather_root else get_tree().root.get_child(0)
	target.add_child(instance)
	instance.emitting = true

	# Splash extra para chuva/tempestade
	if weather_type in [1, 2] and _weather_particles.has("rain_splash"):
		var splash = _weather_particles["rain_splash"].duplicate() as GPUParticles2D
		splash.name = "RainSplash"
		target.add_child(splash)
		splash.emitting = true

	# Ajusta iluminação
	_adjust_lighting(weather_type)

func _set_seasonal(season: int) -> void:
	# Para efeito anterior
	for key in _seasonal_effects:
		var effect = _seasonal_effects[key]
		if effect.get_parent():
			effect.emitting = false
			effect.queue_free()

	# Efeito da estação
	if _seasonal_effects.has(season):
		var effect = _seasonal_effects[season].duplicate() as GPUParticles2D
		effect.name = "Seasonal_%s" % ["Petals", "Summer", "Leaves", "WinterSnow"][season]
		var target = weather_root if weather_root else get_tree().root.get_child(0)
		target.add_child(effect)
		effect.emitting = true

	# Vagalumes no verão à noite
	if season == 1 and _seasonal_effects.has("fireflies"):
		# Será ativado/desativado pelo ciclo dia/noite
		pass

	# Ajusta cor ambiente da estação
	_adjust_season_lighting(season)

func _adjust_lighting(weather: int) -> void:
	# Escurece/ilumina baseado no clima
	var canvas = get_tree().root.get_child(0).get_node_or_null("CanvasModulate")
	if not canvas:
		canvas = CanvasModulate.new()
		canvas.name = "CanvasModulate"
		get_tree().root.get_child(0).add_child(canvas)

	match weather:
		1: canvas.color = Color(0.7, 0.7, 0.85, 1.0)  # Chuva
		2: canvas.color = Color(0.5, 0.5, 0.65, 1.0)  # Tempestade
		3: canvas.color = Color(0.85, 0.85, 0.95, 1.0)  # Neve
		4: canvas.color = Color(0.7, 0.85, 0.7, 1.0)  # Chuva verde
		_: canvas.color = Color(1.0, 1.0, 1.0, 1.0)  # Normal

func _adjust_season_lighting(season: int) -> void:
	var canvas = get_tree().root.get_child(0).get_node_or_null("CanvasModulate")
	if not canvas:
		return

	# Tints sutis por estação
	match season:
		0: canvas.color = canvas.color.lerp(Color(1.0, 1.0, 0.95, 1.0), 0.3)  # Primavera - quente
		1: canvas.color = canvas.color.lerp(Color(1.0, 0.98, 0.9, 1.0), 0.3)  # Verão - amarelo quente
		2: canvas.color = canvas.color.lerp(Color(1.0, 0.9, 0.8, 1.0), 0.3)  # Outono - laranja
		3: canvas.color = canvas.color.lerp(Color(0.95, 0.95, 1.0, 1.0), 0.3)  # Inverno - azulado

## ==================== CICLO DIA/NOITE (Vagalumes) ====================
func on_hour_changed(hour: int) -> void:
	# Ativa vagalumes no verão à noite (19h-5h)
	if GameManager and GameManager.current_season == 1 and _seasonal_effects.has("fireflies"):
		var fireflies = _seasonal_effects["fireflies"]
		var is_night = hour >= 19 or hour < 5

		if is_night and not fireflies.get_parent():
			var instance = fireflies.duplicate() as GPUParticles2D
			instance.name = "Fireflies_Night"
			var target = weather_root if weather_root else get_tree().root.get_child(0)
			target.add_child(instance)
			instance.emitting = true
		elif not is_night and fireflies.get_parent():
			fireflies.get_parent().queue_free()

## ==================== LIMPEZA ====================
func clear_all() -> void:
	for key in _weather_particles:
		var p = _weather_particles[key]
		if p.get_parent():
			p.queue_free()
	for key in _seasonal_effects:
		var p = _seasonal_effects[key]
		if p.get_parent():
			p.queue_free()