class_name ParticleManager
extends Node

## Gerenciador centralizado de partículas: ferramentas, clima, efeitos visuais

@export var particle_scenes: Dictionary = {}

## Pools de partículas para performance
var _particle_pools: Dictionary = {}

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_create_default_particles()

func _create_default_particles() -> void:
	# Partícula de terra (enxada)
	particle_scenes["dirt"] = _create_dirt_particles()

	# Partícula de água (regador)
	particle_scenes["water"] = _create_water_particles()

	# Partícula de semente (plantio)
	particle_scenes["seed"] = _create_seed_particles()

	# Partícula de colheita
	particle_scenes["harvest"] = _create_harvest_particles()

	# Partícula de corte (foice)
	particle_scenes["cut"] = _create_cut_particles()

	# Partícula de mineração
	particle_scenes["mine"] = _create_mine_particles()

	# Partícula de pesca (splash)
	particle_scenes["splash"] = _create_splash_particles()

	# Partícula de nível up
	particle_scenes["level_up"] = _create_level_up_particles()

	# Chuva
	particle_scenes["rain"] = _create_rain_particles()

	# Neve
	particle_scenes["snow"] = _create_snow_particles()

	# Tempestade
	particle_scenes["storm"] = _create_storm_particles()

	# Pétalas primavera
	particle_scenes["petals"] = _create_petal_particles()

	# Folhas outono
	particle_scenes["leaves"] = _create_leaf_particles()

## ==================== PARTÍCULAS PADRÃO ====================
func _create_dirt_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 15
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.spread = 45
	p.gravity = Vector2(0, 100)
	p.initial_velocity = 60
	p.angular_velocity = 5
	p.scale = 0.3
	p.scale_curve = _curve_float(1.0, 0.0)
	p.color = Color(0.4, 0.25, 0.15, 0.8)
	p.color_ramp = _gradient(Color(0.5, 0.3, 0.2, 0.8), Color(0.3, 0.2, 0.1, 0.0))
	return p

func _create_water_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 20
	p.lifetime = 0.4
	p.explosiveness = 0.8
	p.spread = 30
	p.gravity = Vector2(0, 50)
	p.initial_velocity = 40
	p.scale = 0.2
	p.scale_curve = _curve_float(1.0, 0.0)
	p.color = Color(0.2, 0.5, 1.0, 0.7)
	p.color_ramp = _gradient(Color(0.3, 0.6, 1.0, 0.7), Color(0.2, 0.4, 0.8, 0.0))
	return p

func _create_seed_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 8
	p.lifetime = 0.6
	p.explosiveness = 0.5
	p.spread = 20
	p.gravity = Vector2(0, 80)
	p.initial_velocity = 30
	p.scale = 0.25
	p.color = Color(0.3, 0.5, 0.2, 1.0)
	p.color_ramp = _gradient(Color(0.4, 0.6, 0.3, 1.0), Color(0.2, 0.4, 0.15, 0.0))
	return p

func _create_harvest_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 25
	p.lifetime = 0.8
	p.explosiveness = 1.0
	p.spread = 60
	p.gravity = Vector2(0, 120)
	p.initial_velocity = 80
	p.angular_velocity = 10
	p.scale = 0.4
	p.scale_curve = _curve_float(1.0, 0.0)
	p.color = Color(0.9, 0.7, 0.2, 1.0)
	p.color_ramp = _gradient(Color(1.0, 0.8, 0.3, 1.0), Color(0.8, 0.5, 0.1, 0.0))
	return p

func _create_cut_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 15
	p.lifetime = 0.4
	p.explosiveness = 0.9
	p.spread = 40
	p.gravity = Vector2(0, 100)
	p.initial_velocity = 70
	p.scale = 0.3
	p.color = Color(0.3, 0.6, 0.2, 0.8)
	p.color_ramp = _gradient(Color(0.4, 0.7, 0.3, 0.8), Color(0.2, 0.4, 0.1, 0.0))
	return p

func _create_mine_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 20
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.spread = 50
	p.gravity = Vector2(0, 150)
	p.initial_velocity = 100
	p.angular_velocity = 15
	p.scale = 0.35
	p.color = Color(0.5, 0.45, 0.4, 0.9)
	p.color_ramp = _gradient(Color(0.6, 0.55, 0.5, 0.9), Color(0.3, 0.25, 0.2, 0.0))
	return p

func _create_splash_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 12
	p.lifetime = 0.3
	p.explosiveness = 0.7
	p.spread = 35
	p.gravity = Vector2(0, 80)
	p.initial_velocity = 50
	p.scale = 0.25
	p.color = Color(0.4, 0.7, 1.0, 0.8)
	p.color_ramp = _gradient(Color(0.5, 0.8, 1.0, 0.8), Color(0.2, 0.5, 0.8, 0.0))
	return p

func _create_level_up_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 30
	p.lifetime = 1.5
	p.explosiveness = 0.5
	p.spread = 360
	p.gravity = Vector2(0, -50)
	p.initial_velocity = 30
	p.angular_velocity = 5
	p.scale = 0.5
	p.scale_curve = _curve_float(0.0, 1.0, 1.0, 0.0)
	p.color = Color(1.0, 0.9, 0.3, 1.0)
	p.color_ramp = _gradient(Color(1.0, 1.0, 0.5, 1.0), Color(1.0, 0.8, 0.0, 0.0))
	p.emission_shape = GPUParticles2D.EMISSION_SHAPE_RING
	p.emission_ring_radius = 20
	return p

func _create_rain_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 500
	p.lifetime = 2.0
	p.explosiveness = 0.0
	p.spread = 5
	p.gravity = Vector2(0, 400)
	p.initial_velocity = 200
	p.scale = 0.1
	p.scale_curve = _curve_float(1.0, 1.0)
	p.color = Color(0.6, 0.7, 0.9, 0.4)
	p.color_ramp = _gradient(Color(0.6, 0.7, 0.9, 0.4), Color(0.5, 0.6, 0.8, 0.0))
	p.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1920, 100)
	p.emission_rect_height = 50
	p.local_coords = false
	p.one_shot = false
	return p

func _create_snow_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 300
	p.lifetime = 5.0
	p.explosiveness = 0.0
	p.spread = 10
	p.gravity = Vector2(20, 80)
	p.initial_velocity = 30
	p.scale = 0.15
	p.scale_curve = _curve_float(1.0, 1.0)
	p.color = Color(1.0, 1.0, 1.0, 0.6)
	p.color_ramp = _gradient(Color(1.0, 1.0, 1.0, 0.6), Color(0.9, 0.9, 1.0, 0.0))
	p.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1920, 100)
	p.local_coords = false
	p.one_shot = false
	return p

func _create_storm_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 800
	p.lifetime = 1.5
	p.explosiveness = 0.0
	p.spread = 15
	p.gravity = Vector2(50, 500)
	p.initial_velocity = 300
	p.scale = 0.1
	p.color = Color(0.5, 0.55, 0.7, 0.5)
	p.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1920, 100)
	p.local_coords = false
	p.one_shot = false
	return p

func _create_petal_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 100
	p.lifetime = 8.0
	p.explosiveness = 0.0
	p.spread = 45
	p.gravity = Vector2(10, 20)
	p.initial_velocity = 15
	p.scale = 0.2
	p.angular_velocity = 2
	p.color = Color(1.0, 0.7, 0.8, 0.5)
	p.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1920, 1080)
	p.local_coords = false
	p.one_shot = false
	return p

func _create_leaf_particles() -> GPUParticles2D:
	var p = GPUParticles2D.new()
	p.amount = 80
	p.lifetime = 10.0
	p.explosiveness = 0.0
	p.spread = 30
	p.gravity = Vector2(30, 40)
	p.initial_velocity = 20
	p.scale = 0.25
	p.angular_velocity = 3
	p.color = Color(0.8, 0.4, 0.2, 0.5)
	p.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1920, 1080)
	p.local_coords = false
	p.one_shot = false
	return p

## ==================== UTILIDADES ====================
func _curve_float(start: float, end: float, mid: float = -1.0, mid_pos: float = 0.5) -> Curve:
	var c = Curve.new()
	c.add_point(Vector2(0.0, start))
	if mid >= 0.0:
		c.add_point(Vector2(mid_pos, mid))
	c.add_point(Vector2(1.0, end))
	return c

func _gradient(from: Color, to: Color) -> Gradient:
	var g = Gradient.new()
	var colors = PackedColorArray([from, to])
	g.colors = colors
	return g

## ==================== SPAWN PARTÍCULAS ====================
## Spawna partícula única na posição
func spawn(particle_type: String, position: Vector2, parent: Node = null, rotation: float = 0.0) -> GPUParticles2D:
	var template = particle_scenes.get(particle_type)
	if not template:
		Logger.warn("Partícula não encontrada: %s" % particle_type)
		return null

	var instance = template.duplicate() as GPUParticles2D
	instance.rotation = rotation
	instance.global_position = position
	instance.one_shot = true
	instance.emitting = true

	var target = parent if parent else get_tree().root.get_child(0)
	target.add_child(instance)

	# Auto-remove após terminar
	instance.finished.connect(instance.queue_free.bind())

	return instance

## Spawna múltiplas (para área)
func spawn_area(particle_type: String, position: Vector2, count: int, radius: float = 32.0, parent: Node = null) -> void:
	for i in range(count):
		var angle = randf() * TAU
		var dist = randf() * radius
		var pos = position + Vector2(cos(angle), sin(angle)) * dist
		spawn(particle_type, pos, parent)

## Efeitos de ferramentas
func tool_hit_hoe(position: Vector2) -> void:
	spawn("dirt", position)

func tool_hit_watering(position: Vector2) -> void:
	spawn("water", position)

func tool_hit_axe(position: Vector2) -> void:
	spawn("cut", position)

func tool_hit_pickaxe(position: Vector2) -> void:
	spawn("mine", position)

func tool_hit_scythe(position: Vector2) -> void:
	spawn("cut", position)

## Ações de farming
func plant_seed(position: Vector2) -> void:
	spawn("seed", position)

func harvest_crop(position: Vector2) -> void:
	spawn("harvest", position)

## Clima
func start_weather(weather_type: String) -> void:
	var weather_particles = {
		"Rain": "rain",
		"Storm": "storm",
		"Snow": "snow"
	}
	var p_type = weather_particles.get(weather_type)
	if p_type and particle_scenes.has(p_type):
		var template = particle_scenes[p_type]
		var instance = template.duplicate() as GPUParticles2D
		instance.name = "Weather_%s" % weather_type
		instance.local_coords = false
		instance.emitting = true
		get_tree().root.get_child(0).add_child(instance)

func stop_weather(weather_type: String) -> void:
	var name = "Weather_%s" % weather_type
	var existing = get_tree().root.get_child(0).get_node_or_null(name)
	if existing:
		existing.emitting = false
		existing.queue_free()

func seasonal_ambient(season: int) -> void:
	# 0=Spring, 1=Summer, 2=Fall, 3=Winter
	match season:
		0: start_weather("petals")
		2: start_weather("leaves")
		3: start_weather("snow")
		_: stop_all_seasonal()

func stop_all_seasonal() -> void:
	for name in ["petals", "leaves"]:
		var existing = get_tree().root.get_child(0).get_node_or_null("Weather_%s" % name)
		if existing:
			existing.emitting = false
			existing.queue_free()

## Nível up
func show_level_up(position: Vector2, skill_name: String) -> void:
	spawn("level_up", position)
	# Texto flutuante
	var label = Label.new()
	label.text = "%s Nível UP!" % skill_name
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1, 1, 0.3))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 2)
	label.global_position = position
	get_tree().root.get_child(0).add_child(label)

	var tween = label.create_tween()
	tween.tween_property(label, "global_position:y", position.y - 60, 1.5)
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.finished.connect(label.queue_free.bind())

## ==================== LIMPEZA ====================
func clear_all() -> void:
	var root = get_tree().root.get_child(0)
	for child in root.get_children():
		if child is GPUParticles2D:
			child.queue_free()