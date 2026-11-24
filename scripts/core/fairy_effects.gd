class_name FairyEffects
extends Node

## Efeitos de fadas/Junimos: colheita mágica, bênção de colheita, etc.

## ==================== EFEITOS ====================

## Bênção da Fada - colheita instantânea de culturas ao redor
func fairy_blessing(center: Vector2, radius: float = 128.0) -> void:
	var crops_harvested = 0
	var quality_boost = 0

	# Encontra cultivos na área
	var farm_plots = get_tree().get_nodes_in_group("farm_plots")
	for plot_node in farm_plots:
		if plot_node is Node2D:
			for child in plot_node.get_children():
				if child is Node2D and child.has_method("is_fully_grown"):
					var dist = center.distance_to(child.global_position)
					if dist <= radius:
						if child.is_fully_grown and not child.is_dead:
							# Colheita instantânea com qualidade boost
							var harvested = child.harvest()
							if harvested:
								crops_harvested += 1
								quality_boost = max(quality_boost, 1)

								# Partículas mágicas
								if ParticleManager:
									ParticleManager.show_level_up(child.global_position, "✨ Fairy Blessing!")

	# Notificação
	if crops_harvested > 0:
		HUD.show_notification("✨ Bênção da Fada!", "%d culturas colhidas instantaneamente!" % crops_harvested, Color(1.0, 0.5, 1.0))

		# Som mágico
		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/fairy_blessing.ogg", center)

		# Partículas no centro
		if ParticleManager:
			ParticleManager.spawn_area("harvest", center, 30, radius * 1.5)

## Junimos Harvest - colhe todas as culturas maduras na fazenda
func junimo_harvest_all() -> void:
	var total = 0
	var farm_plots = get_tree().get_nodes_in_group("farm_plots")
	for plot_node in farm_plots:
		if plot_node is Node2D:
			for child in plot_node.get_children():
				if child is Node2D and child.has_method("is_fully_grown"):
					if child.is_fully_grown and not child.is_dead:
						child.harvest()
						total += 1

						# Partículas de Junimo
						if ParticleManager:
							ParticleManager.spawn("harvest", child.global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16)))

	if total > 0:
		HUD.show_notification("🧙 Junimos!", "%d culturas colhidas pelos Junimos!" % total, Color(0.5, 1.0, 0.5))

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/junimo_harvest.ogg", get_tree().root.get_child(0).global_position)

		# Partículas massivas
		if ParticleManager:
			ParticleManager.spawn_area("level_up", get_tree().root.get_child(0).global_position, 50, 500)

## Efeito de crescimento acelerado (Speed-Gro visual)
func speed_gro_effect(position: Vector2) -> void:
	if ParticleManager:
		ParticleManager.spawn_area("seed", position, 12, 24.0)

	# Brilho verde nas culturas próximas
	var crops = get_tree().get_nodes_in_group("crops")
	for crop in crops:
		if crop is Node2D:
			var dist = position.distance_to(crop.global_position)
			if dist < 96:
				var tween = crop.create_tween()
				tween.tween_property(crop, "modulate", Color(0.5, 1.0, 0.5, 1.0), 0.5)
				tween.tween_property(crop, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

## Chuva de estrelas (evento raro)
func star_shower(center: Vector2) -> void:
	if ParticleManager:
		var stars = GPUParticles2D.new()
		stars.amount = 100
		stars.lifetime = 5.0
		stars.explosiveness = 1.0
		stars.spread = 360
		stars.gravity = Vector2(0, 50)
		stars.initial_velocity = 200
		stars.scale = 0.2
		stars.color = Color(1.0, 1.0, 0.6, 1.0)
		stars.color_ramp = _gradient(Color(1.0, 1.0, 0.8, 1.0), Color(1.0, 0.9, 0.3, 0.0))
		stars.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
		stars.emission_rect_extents = Vector2(1920, 100)
		stars.local_coords = false
		stars.one_shot = true
		stars.global_position = center + Vector2(0, -500)
		get_tree().root.get_child(0).add_child(stars)
		stars.emitting = true

		HUD.show_notification("🌠 Chuva de Estrelas!", "Estrelas cadentes iluminam a noite!", Color(1.0, 1.0, 0.5))

		if AudioManager:
			AudioManager.play_sfx("res://assets/sfx/star_shower.ogg")

## Aurora boreal (inverno, raro)
func aurora_borealis() -> void:
	if ParticleManager:
		var colors = [
			Color(0.3, 1.0, 0.5, 0.3),
			Color(0.5, 0.3, 1.0, 0.3),
			Color(1.0, 0.3, 0.5, 0.3)
		]

		for i in 3:
			var aurora = GPUParticles2D.new()
			aurora.amount = 50
			aurora.lifetime = 10.0
			aurora.explosiveness = 0.0
			aurora.spread = 180
			aurora.gravity = Vector2(0, -20)
			aurora.initial_velocity = 30
			aurora.scale = 0.5
			aurora.scale_curve = _curve_float(0.0, 1.0, 0.0)
			aurora.color = colors[i]
			aurora.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
			aurora.emission_rect_extents = Vector2(1920, 200)
			aurora.local_coords = false
			aurora.one_shot = true
			aurora.global_position = Vector2(0, 200 + i * 100)
			get_tree().root.get_child(0).add_child(aurora)
			aurora.emitting = true

		HUD.show_notification("🌌 Aurora Boreal!", "Luzes dançam no céu noturno!", Color(0.5, 0.7, 1.0))

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

## ==================== EVENTOS ALEATÓRIOS ====================
func check_random_events() -> void:
	if not GameManager:
		return

	# Fairy blessing (0.5% chance por noite)
	if GameManager.current_time == 2400 and randf() < 0.005:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			fairy_blessing(player.global_position)

	# Junimo harvest (se Community Center completo, 1% chance)
	if GameManager.get("cc_completed", false) and randf() < 0.01:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			junimo_harvest_all()

	# Star shower (noite de verão, 2% chance)
	if GameManager.current_season == 1 and GameManager.current_time == 2200 and randf() < 0.02:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			star_shower(player.global_position)

	# Aurora boreal (inverno, 1% chance)
	if GameManager.current_season == 3 and GameManager.current_time == 2300 and randf() < 0.01:
		aurora_borealis()