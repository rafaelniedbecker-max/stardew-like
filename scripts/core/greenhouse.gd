class_name Greenhouse
extends Node

## Estufa - cultivo o ano todo, 10x12 tiles

@export var greenhouse_scene: PackedScene

## Estado
var unlocked: bool = false
var crop_plots: Dictionary = {}  # "x,y" -> crop data

## Área plantável (10x12)
const PLANTABLE_AREA = {"position": Vector2i(1, 1), "size": Vector2i(10, 12)}
const TILE_SIZE = 32

## ==================== SINAIS ====================
signal greenhouse_unlocked()
signal crop_planted(position: Vector2i, crop_id: String)
signal crop_harvested(position: Vector2i, item_id: String, amount: int, quality: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	unlocked = GameManager.get("cc_greenhouse_unlocked", false) or GameManager.get("greenhouse_unlocked", false)
	if unlocked:
		_initialize_plots()
		_load_crops()

	# Verifica desbloqueio via Community Center
	if CommunityCenter:
		CommunityCenter.room_completed.connect(_check_greenhouse_unlock)

func _check_greenhouse_unlock(room: String) -> void:
	if room == "Pantry" and not unlocked:
		var bundles = CommunityCenter.get_room_bundles("Pantry")
		var all_complete = true
		for bundle in bundles:
			if not bundle.completed:
				all_complete = false
				break
		if all_complete:
			unlock()

func unlock() -> void:
	if unlocked:
		return

	unlocked = true
	GameManager.set("greenhouse_unlocked", true)
	GameManager.set("cc_greenhouse_unlocked", true)

	_initialize_plots()
	emit_signal("greenhouse_unlocked")

	HUD.show_notification("🏠 Estufa Desbloqueada!", "Agora você pode plantar o ano todo!", Color(0.5, 1.0, 0.5))

	if ParticleManager:
		ParticleManager.show_level_up(Vector2(320, 320), "Estufa!")

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/greenhouse_unlock.ogg")

func _initialize_plots() -> void:
	# Cria plots 10x12
	for x in range(PLANTABLE_AREA.size.x):
		for y in range(PLANTABLE_AREA.size.y):
			var pos = Vector2i(PLANTABLE_AREA.position.x + x, PLANTABLE_AREA.position.y + y)
			var key = "%d,%d" % [pos.x, pos.y]
			crop_plots[key] = {
				"position": pos,
				"crop_id": "",
				"growth_day": 0,
				"watered": false,
				"fertilizer": "",
				"planted_day": 0,
				"quality_boost": 0.0,
				"speed_gro": 0,
				"retaining_soil": 0
			}

func _load_crops() -> void:
	if not GameManager:
		return

	var saved = GameManager.get("greenhouse_crops", {})
	for key in saved:
		if crop_plots.has(key):
			crop_plots[key] = saved[key]

func can_plant(position: Vector2i, crop_id: String) -> bool:
	if not unlocked:
		return false

	var key = "%d,%d" % [position.x, position.y]
	if not crop_plots.has(key):
		return false

	var plot = crop_plots[key]
	return plot.crop_id == ""

func plant_crop(position: Vector2i, crop_id: String, fertilizer: int = 0, retaining: int = 0, speed_gro: int = 0) -> bool:
	if not can_plant(position, crop_id):
		return false

	var key = "%d,%d" % [position.x, position.y]
	var crop_data = DataLoader.get_crop(crop_id.to_int())
	if not crop_data:
		return false

	# Verifica estação (estufa ignora estação!)
	# Mas verifica se é cultura válida

	crop_plots[key] = {
		"position": position,
		"crop_id": crop_id,
		"growth_day": 0,
		"watered": false,
		"fertilizer": fertilizer,
		"retaining_soil": retaining,
		"speed_gro": speed_gro,
		"planted_day": GameManager.current_day if GameManager else 1,
		"quality_boost": _calculate_quality_boost(fertilizer),
		"phase": 0,
		"harvest_count": 0,
		"is_fully_grown": false,
		"is_dead": false
	}

	_save_crops()
	emit_signal("crop_planted", position, crop_id)

	# Spawna visual
	_spawn_crop_visual(position, crop_id)

	# Consome semente
	if InventoryManager:
		InventoryManager.remove_item(crop_id, 1)

	return true

func _calculate_quality_boost(fertilizer: int) -> float:
	match fertilizer:
		1: return 0.1   # Basic Fertilizer
		2: return 0.2   # Quality Fertilizer
		3: return 0.3   # Deluxe Fertilizer
	return 0.0

func water_crop(position: Vector2i) -> bool:
	var key = "%d,%d" % [position.x, position.y]
	if not crop_plots.has(key):
		return false

	var plot = crop_plots[key]
	if plot.crop_id == "" or plot.is_fully_grown or plot.is_dead:
		return false

	plot.watered = true
	_save_crops()

	# Efeito visual
	_spawn_water_effect(position)

	return true

func harvest_crop(position: Vector2i) -> Dictionary:
	var key = "%d,%d" % [position.x, position.y]
	if not crop_plots.has(key):
		return {}

	var plot = crop_plots[key]
	if not plot.is_fully_grown or plot.crop_id == "":
		return {}

	var crop_data = DataLoader.get_crop(plot.crop_id.to_int())
	if not crop_data:
		return {}

	# Calcula qualidade e quantidade
	var quality = _calculate_harvest_quality(plot)
	var amount = _calculate_harvest_amount(crop_data, plot)
	var harvest_item = crop_data.harvest_item_id
	if harvest_item == "":
		harvest_item = plot.crop_id

	# Adiciona ao inventário
	if InventoryManager:
		InventoryManager.add_item(harvest_item, amount, quality)

	# Estatísticas
	if GameManager:
		GameManager.stats.crops_harvested += amount
		GameManager.emit_signal("crop_harvested", harvest_item, amount, quality)

	# Partículas e som
	if ParticleManager:
		ParticleManager.spawn("harvest", Vector2(position.x * TILE_SIZE, position.y * TILE_SIZE) + Vector2(16, -16))

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/harvest.ogg", Vector2(position.x * TILE_SIZE, position.y * TILE_SIZE))

	# Verifica regrow
	var result = {
		"item_id": harvest_item,
		"amount": amount,
		"quality": quality,
		"regrow": false
	}

	if crop_data.regrow_days > 0 and plot.harvest_count < crop_data.max_harvests:
		# Regrow
		plot.growth_day = crop_data.total_growth_days - crop_data.regrow_days
		plot.is_fully_grown = false
		plot.watered = false
		plot.harvest_count += 1
		plot.phase = crop_data.get_phase_at_day(plot.growth_day)
		result.regrow = true

		# Efeito visual de regrow
		_show_regrow_effect(position)

		_save_crops()
	else:
		# Remove cultura
		plot.crop_id = ""
		plot.growth_day = 0
		plot.watered = false
		plot.is_fully_grown = false
		plot.is_dead = false
		plot.harvest_count = 0
		plot.phase = 0
		_remove_crop_visual(position)

	_save_crops()
	emit_signal("crop_harvested", position, harvest_item, amount, quality)

	return result

func _calculate_harvest_quality(plot: Dictionary) -> int:
	var base_chance = 0.0

	# Fertilizante
	base_chance += plot.quality_boost

	# Nível de farming
	var farming_level = GameManager.skill_levels[0] if GameManager else 0
	base_chance += farming_level * 0.01

	# Sorte diária
	base_chance += (GameManager.daily_luck + 0.1) * 0.3 if GameManager else 0

	# Profissão Artisan
	if GameManager and GameManager.professions.get("Farming") == 1:
		base_chance += 0.2

	if base_chance > 0.9: return 3
	elif base_chance > 0.6: return 2
	elif base_chance > 0.3: return 1
	return 0

func _calculate_harvest_amount(crop_data: CropData, plot: Dictionary) -> int:
	var min_stack = crop_data.harvest_min_stack
	var max_stack = crop_data.harvest_max_stack

	# Bonus por nível de farming
	var farming_bonus = int(crop_data.harvest_max_increase_per_farming_level * (GameManager.skill_levels[0] if GameManager else 0))
	max_stack += farming_bonus

	# Chance extra
	if randf() < crop_data.extra_harvest_chance:
		max_stack += 1

	return randi_range(min_stack, max_stack)

func grow_day() -> void:
	if not unlocked:
		return

	for key in crop_plots:
		var plot = crop_plots[key]
		if plot.crop_id == "" or plot.is_dead or plot.is_fully_grown:
			continue

		# Verifica água
		var crop_data = DataLoader.get_crop(plot.crop_id.to_int())
		if not crop_data:
			continue

		if crop_data.needs_watering and not plot.watered and plot.retaining_soil == 0:
			# Morre se não regada
			plot.is_dead = true
			plot.is_fully_grown = false
			continue

		# Speed-Gro acelera
		var speed_bonus = plot.speed_gro * 0.1
		plot.growth_day += 1 + int(speed_bonus)

		# Verifica fase
		var new_phase = crop_data.get_phase_at_day(plot.growth_day)
		if new_phase != plot.phase:
			plot.phase = new_phase
			_update_crop_visual(plot.position, plot.phase)

		# Verifica se totalmente crescido
		if plot.growth_day >= crop_data.total_growth_days:
			plot.is_fully_grown = true
			plot.watered = false  # Reseta água

		# Retaining soil mantém água
		if plot.retaining_soil > 0:
			plot.watered = true

	# Salva
	_save_crops()

	# Processa estufa no ciclo diário do GameManager
	# (chamado via signal day_changed)

func _spawn_crop_visual(position: Vector2i, crop_id: String) -> void:
	# Spawna visual da cultura no mundo
	var world_pos = Vector2(position.x * TILE_SIZE, position.y * TILE_SIZE) + Vector2(16, 16)

	# Cria node visual
	var crop_node = Node2D.new()
	crop_node.name = "GreenhouseCrop_%d_%d" % [position.x, position.y]
	crop_node.global_position = world_pos

	var crop_data = DataLoader.get_crop(crop_id.to_int())
	if crop_data and crop_data.texture_path != "":
		var sprite = Sprite2D.new()
		sprite.texture = load(crop_data.texture_path)
		sprite.offset = Vector2(16, 32)
		crop_node.add_child(sprite)

	get_tree().root.get_child(0).add_child(crop_node)

func _update_crop_visual(position: Vector2i, phase: int) -> void:
	var node_name = "GreenhouseCrop_%d_%d" % [position.x, position.y]
	var node = get_tree().root.get_child(0).get_node_or_null(node_name)
	if node:
		# Atualiza sprite para nova fase
		pass

func _remove_crop_visual(position: Vector2i) -> void:
	var node_name = "GreenhouseCrop_%d_%d" % [position.x, position.y]
	var node = get_tree().root.get_child(0).get_node_or_null(node_name)
	if node:
		node.queue_free()

func _spawn_water_effect(position: Vector2i) -> void:
	if ParticleManager:
		ParticleManager.spawn("water", Vector2(position.x * TILE_SIZE, position.y * TILE_SIZE) + Vector2(16, -16))

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/water.ogg", Vector2(position.x * TILE_SIZE, position.y * TILE_SIZE))

func _show_regrow_effect(position: Vector2i) -> void:
	if ParticleManager:
		ParticleManager.spawn("seed", Vector2(position.x * TILE_SIZE, position.y * TILE_SIZE) + Vector2(16, -16))

	var label = Label.new()
	label.text = "🌱 Rebrotando!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_override_font_size = 14
	label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.global_position = Vector2(position.x * TILE_SIZE, position.y * TILE_SIZE) + Vector2(16, -32)
	get_tree().root.get_child(0).add_child(label)

	var tween = label.create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 40, 2.0)
	tween.tween_property(label, "modulate:a", 0.0, 2.0)
	tween.finished.connect(label.queue_free.bind())

func _save_crops() -> void:
	if GameManager:
		GameManager.set("greenhouse_crops", crop_plots)

## ==================== UTILIDADES ====================
func get_crop_at(position: Vector2i) -> Dictionary:
	var key = "%d,%d" % [position.x, position.y]
	return crop_plots.get(key, {})

func get_all_crops() -> Array[Dictionary]:
	var result = []
	for key in crop_plots:
		var plot = crop_plots[key]
		if plot.crop_id != "":
			plot.position = key.split(",").map(func(s): return s.to_int())
			result.append(plot.duplicate())
	return result

func get_save_data() -> Dictionary:
	return {
		"unlocked": unlocked,
		"crop_plots": crop_plots
	}

func load_save_data(data: Dictionary) -> void:
	unlocked = data.get("unlocked", false)
	crop_plots = data.get("crop_plots", {})

	if unlocked:
		_initialize_plots()
		_load_crops()