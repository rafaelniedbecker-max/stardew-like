class_name ToolUpgradeEffects
extends Node

## Efeitos visuais de upgrade de ferramentas

## ==================== EFEITOS ====================

## Efeito de upgrade bem-sucedido na bigorna
func upgrade_success(tool_type: String, new_level: int, position: Vector2) -> void:
	var tool_names = {
		"Pickaxe": "Picareta",
		"Axe": "Machado",
		"Hoe": "Enxada",
		"WateringCan": "Regador",
		"TrashCan": "Lixeira",
		"FishingRod": "Vara de Pescar",
		"Pan": "Batedeira",
		"Shears": "Tesoura",
		"MilkPail": "Balde de Leite"
	}

	var level_names = ["Cobre", "Ferro", "Ouro", "Irídio"]
	var tool_name = tool_names.get(tool_type, tool_type)
	var level_name = level_names[new_level] if new_level < level_names.size() else "Nível %d" % (new_level + 1)

	# Partículas de upgrade
	if ParticleManager:
		ParticleManager.show_level_up(position, "%s %s!" % [tool_name, level_name])

	# Explosão de partículas metálicas
	_metal_burst(position, new_level)

	# Raio de luz
	_light_beam(position)

	# Som
	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/tool_upgrade.ogg", position)

	# Notificação
	HUD.show_notification("⚒️ Upgrade Concluído!", "%s agora é %s!" % [tool_name, level_name], Color(1.0, 0.8, 0.2))

	# Screen shake leve
	_screen_shake(0.3, 5.0)

func _metal_burst(position: Vector2, level: int) -> void:
	if not ParticleManager:
		return

	var colors = [
		Color(0.8, 0.5, 0.2),   # Cobre
		Color(0.7, 0.7, 0.8),   # Ferro
		Color(1.0, 0.85, 0.2),  # Ouro
		Color(0.6, 0.4, 1.0)    # Irídio
	]
	var color = colors[level] if level < colors.size() else Color(1.0, 1.0, 1.0)

	for i in range(3):
		var burst = GPUParticles2D.new()
		burst.amount = 30
		burst.lifetime = 1.0
		burst.explosiveness = 1.0
		burst.spread = 360
		burst.gravity = Vector2(0, 100)
		burst.initial_velocity = 150 + i * 50
		burst.scale = 0.2 + i * 0.1
		burst.color = color
		burst.color_ramp = _gradient(color, Color(1.0, 1.0, 1.0, 0.0))
		burst.emission_shape = GPUParticles2D.EMISSION_SHAPE_RING
		burst.emission_ring_radius = 10.0 + i * 5.0
		burst.one_shot = true
		burst.global_position = position
		get_tree().root.get_child(0).add_child(burst)
		burst.emitting = true

		# Delay entre bursts
		var timer = Timer.new()
		timer.wait_time = i * 0.1
		timer.one_shot = true
		timer.timeout.connect(burst.emitting.bind(true))
		burst.add_child(timer)
		timer.start()

func _light_beam(position: Vector2) -> void:
	# Cria um feixe de luz subindo
	var beam = GPUParticles2D.new()
	beam.amount = 50
	beam.lifetime = 1.5
	beam.explosiveness = 0.0
	beam.spread = 10
	beam.gravity = Vector2(0, -200)
	beam.initial_velocity = 300
	beam.scale = 0.3
	beam.scale_curve = _curve_float(0.0, 1.0, 0.0)
	beam.color = Color(1.0, 1.0, 0.8, 0.8)
	beam.color_ramp = _gradient(Color(1.0, 1.0, 0.6, 0.8), Color(1.0, 0.9, 0.3, 0.0))
	beam.emission_shape = GPUParticles2D.EMISSION_SHAPE_POINT
	beam.one_shot = true
	beam.global_position = position
	get_tree().root.get_child(0).add_child(beam)
	beam.emitting = true

	# Anel expansivo
	var ring = GPUParticles2D.new()
	ring.amount = 20
	ring.lifetime = 1.0
	ring.explosiveness = 0.0
	ring.spread = 360
	ring.gravity = Vector2(0, 0)
	ring.initial_velocity = 200
	ring.scale = 0.1
	ring.scale_curve = _curve_float(1.0, 0.0)
	ring.color = Color(1.0, 1.0, 0.8, 0.6)
	ring.emission_shape = GPUParticles2D.EMISSION_SHAPE_RING
	ring.emission_ring_radius = 20.0
	ring.one_shot = true
	ring.global_position = position
	get_tree().root.get_child(0).add_child(ring)
	ring.emitting = true

func _screen_shake(intensity: float, duration: float) -> void:
	var camera = get_tree().root.get_child(0).get_node_or_null("Camera2D")
	if camera:
		var original_pos = camera.position
		var tween = camera.create_tween()
		tween.set_loops(int(duration * 30))
		tween.tween_property(camera, "position:x", original_pos.x + randf_range(-intensity, intensity) * 10, 0.03)
		tween.tween_property(camera, "position:y", original_pos.y + randf_range(-intensity, intensity) * 10, 0.03)
		tween.tween_property(camera, "position", original_pos, 0.1).set_delay(duration)

## ==================== EFEITO DE CARREGAMENTO DE FERRAMENTA ====================
## Para enxada, regador, etc. (carregamento progressivo)
func charge_effect(tool_type: String, charge_level: float, position: Vector2) -> void:
	# charge_level: 0.0 a 1.0
	if not ParticleManager:
		return

	var colors = {
		"Hoe": Color(0.6, 0.4, 0.2),
		"WateringCan": Color(0.3, 0.6, 1.0),
		"Axe": Color(0.7, 0.7, 0.8),
		"Pickaxe": Color(0.6, 0.5, 0.4)
	}
	var color = colors.get(tool_type, Color(1.0, 1.0, 1.0))

	# Partículas orbitando o jogador
	var orbit = GPUParticles2D.new()
	orbit.amount = int(10 * charge_level)
	orbit.lifetime = 0.5
	orbit.explosiveness = 0.0
	orbit.spread = 360
	orbit.gravity = Vector2(0, 0)
	orbit.initial_velocity = 50
	orbit.angular_velocity = 200 * charge_level
	orbit.scale = 0.15 * charge_level
	orbit.color = color
	orbit.emission_shape = GPUParticles2D.EMISSION_SHAPE_RING
	orbit.emission_ring_radius = 30.0 + 20.0 * charge_level
	orbit.local_coords = true
	orbit.one_shot = false

	# Anexa ao jogador
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.add_child(orbit)
		orbit.global_position = position
		orbit.emitting = true

		# Remove após um tempo
		var timer = Timer.new()
		timer.wait_time = 0.5
		timer.one_shot = true
		timer.timeout.connect(orbit.queue_free.bind())
		orbit.add_child(timer)
		timer.start()

## ==================== EFEITO DE USO DE FERRAMENTA ====================
func tool_use_effect(tool_type: String, position: Vector2, power: float) -> void:
	match tool_type:
		"Hoe":
			_hoe_effect(position, power)
		"WateringCan":
			_watering_effect(position, power)
		"Axe":
			_axe_effect(position, power)
		"Pickaxe":
			_pickaxe_effect(position, power)
		"Scythe":
			_scythe_effect(position)
		"FishingRod":
			_fishing_cast_effect(position)
		_:
			_generic_tool_effect(position)

func _hoe_effect(position: Vector2, power: float) -> void:
	if ParticleManager:
		ParticleManager.spawn("dirt", position)
		if power > 0.5:
			ParticleManager.spawn_area("dirt", position, int(8 * power), 32.0)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/hoe.ogg", position, pitch_variance=0.1)

	# Rachadura no solo
	_ground_crack(position)

func _watering_effect(position: Vector2, power: float) -> void:
	if ParticleManager:
		ParticleManager.spawn("water", position)
		if power > 0.5:
			ParticleManager.spawn_area("water", position, int(12 * power), 48.0)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/water.ogg", position, pitch_variance=0.05)

	# Ondas de água
	_water_ripple(position, power)

func _axe_effect(position: Vector2, power: float) -> void:
	if ParticleManager:
		ParticleManager.spawn("cut", position)
		ParticleManager.spawn_area("cut", position, int(6 * power), 24.0)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/axe.ogg", position, pitch_variance=0.1)

	# Lascas de madeira
	_wood_chips(position, power)

func _pickaxe_effect(position: Vector2, power: float) -> void:
	if ParticleManager:
		ParticleManager.spawn("mine", position)
		if power > 0.7:
			ParticleManager.spawn_area("mine", position, int(10 * power), 32.0)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/pickaxe.ogg", position, pitch_variance=0.1)

	# Faíscas
	_sparks(position, power)

func _scythe_effect(position: Vector2) -> void:
	if ParticleManager:
		ParticleManager.spawn("cut", position)
		ParticleManager.spawn_area("harvest", position, 8, 48.0)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/scythe.ogg", position)

	# Grama voando
	_grass_fly(position)

func _fishing_cast_effect(position: Vector2) -> void:
	if ParticleManager:
		ParticleManager.spawn("splash", position)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/cast.ogg", position)

	# Splash na água
	_water_splash(position)

func _generic_tool_effect(position: Vector2) -> void:
	if ParticleManager:
		ParticleManager.spawn("harvest", position)

## ==================== EFEITOS AUXILIARES ====================
func _ground_crack(position: Vector2) -> void:
	# Linha de rachadura no chão
	var crack = GPUParticles2D.new()
	crack.amount = 15
	crack.lifetime = 0.8
	crack.explosiveness = 0.5
	crack.spread = 180
	crack.gravity = Vector2(0, 50)
	crack.initial_velocity = 80
	crack.scale = 0.15
	crack.color = Color(0.3, 0.2, 0.1, 0.8)
	crack.emission_shape = GPUParticles2D.EMISSION_SHAPE_LINE
	crack.one_shot = true
	crack.global_position = position
	get_tree().root.get_child(0).add_child(crack)
	crack.emitting = true

func _water_ripple(position: Vector2, power: float) -> void:
	var ripple = GPUParticles2D.new()
	ripple.amount = int(20 * power)
	ripple.lifetime = 1.0
	ripple.explosiveness = 0.0
	ripple.spread = 360
	ripple.gravity = Vector2(0, 0)
	ripple.initial_velocity = 100
	ripple.scale = 0.2
	ripple.scale_curve = _curve_float(0.0, 1.0, 0.0)
	ripple.color = Color(0.3, 0.6, 1.0, 0.6)
	ripple.emission_shape = GPUParticles2D.EMISSION_SHAPE_RING
	ripple.emission_ring_radius = 10.0
	ripple.one_shot = true
	ripple.global_position = position
	get_tree().root.get_child(0).add_child(ripple)
	ripple.emitting = true

func _wood_chips(position: Vector2, power: float) -> void:
	if ParticleManager:
		ParticleManager.spawn_area("cut", position, int(10 * power), 32.0)

	# Lascas maiores
	var chips = GPUParticles2D.new()
	chips.amount = int(8 * power)
	chips.lifetime = 1.5
	chips.explosiveness = 1.0
	chips.spread = 120
	chips.gravity = Vector2(0, 200)
	chips.initial_velocity = 100
	chips.scale = 0.2
	chips.color = Color(0.5, 0.35, 0.2, 1.0)
	chips.emission_shape = GPUParticles2D.EMISSION_SHAPE_POINT
	chips.one_shot = true
	chips.global_position = position
	get_tree().root.get_child(0).add_child(chips)
	chips.emitting = true

func _sparks(position: Vector2, power: float) -> void:
	var sparks = GPUParticles2D.new()
	sparks.amount = int(15 * power)
	sparks.lifetime = 0.5
	sparks.explosiveness = 1.0
	sparks.spread = 360
	sparks.gravity = Vector2(0, 300)
	sparks.initial_velocity = 150
	sparks.scale = 0.1
	sparks.color = Color(1.0, 0.8, 0.3, 1.0)
	sparks.color_ramp = _gradient(Color(1.0, 1.0, 0.5, 1.0), Color(1.0, 0.5, 0.0, 0.0))
	sparks.emission_shape = GPUParticles2D.EMISSION_SHAPE_POINT
	sparks.one_shot = true
	sparks.global_position = position
	get_tree().root.get_child(0).add_child(sparks)
	sparks.emitting = true

func _grass_fly(position: Vector2) -> void:
	if ParticleManager:
		ParticleManager.spawn_area("harvest", position, 12, 64.0)

func _water_splash(position: Vector2) -> void:
	if ParticleManager:
		ParticleManager.spawn("splash", position)

## ==================== UTILIDADES ====================
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