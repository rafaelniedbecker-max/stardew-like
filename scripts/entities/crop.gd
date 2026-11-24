class_name Crop
extends Node2D

## Cultivo individual crescendo no solo

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var watered_indicator: Sprite2D = $WateredIndicator
@onready var harvest_area: Area2D = $HarvestArea

## Dados do cultivo
var crop_data: CropData
var crop_id: String = ""
var growth_day: int = 0
var current_phase: int = 0
var watered_today: bool = false
var is_dead: bool = false
var is_fully_grown: bool = false
var harvest_count: int = 0
var quality_boost: float = 0.0  # 0-1 baseado em farming level, fertilizante, etc.
var planted_by: int = 1  # Player ID (para multiplayer)
var position_key: String = ""  # "x,y" no grid da fazenda

## Fertilizante aplicado
var fertilizer_type: int = 0  # 0=none, 1=basic, 2=quality, 3=deluxe
var retaining_soil_type: int = 0  # 0=none, 1=basic, 2=quality, 3=deluxe
var speed_gro_type: int = 0  # 0=none, 1=speed-gro, 2=deluxe, 3=hyper

## ==================== SINAIS ====================
signal growth_changed(new_phase: int)
signal crop_watered()
signal crop_harvested(item_id: String, amount: int, quality: int)
signal crop_died()
signal crop_fully_grown()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	harvest_area.monitorable = true
	harvest_area.monitoring = true
	harvest_area.area_entered.connect(_on_harvest_area_entered)

func _on_harvest_area_entered(area: Area2D) -> void:
	if area.is_in_group("player") and is_fully_grown:
		# Mostra prompt de colheita
		pass

## ==================== PLANTIO ====================
func plant(crop_data: CropData, pos_key: String, fertilizer: int = 0, retaining: int = 0, speed_gro: int = 0) -> void:
	self.crop_data = crop_data
	self.crop_id = str(crop_data.id)
	self.position_key = pos_key
	self.fertilizer_type = fertilizer
	self.retaining_soil_type = retaining
	self.speed_gro_type = speed_gro
	self.growth_day = 0
	self.current_phase = 0
	self.watered_today = false
	self.is_dead = false
	self.is_fully_grown = false
	self.harvest_count = 0
	self.quality_boost = _calculate_initial_quality_boost()

	_setup_visuals()
	_update_visuals()

	# Registra no GameManager
	if GameManager:
		GameManager.farm_crops[position_key] = {
			"crop_id": crop_id,
			"growth_day": 0,
			"watered": false,
			"fertilizer": fertilizer,
			"retaining": retaining,
			"speed_gro": speed_gro,
			"quality_boost": quality_boost,
			"phase": 0,
			"harvest_count": 0,
			"dead": false
		}

func _calculate_initial_quality_boost() -> float:
	var boost = 0.0
	# Fertilizante
	match fertilizer_type:
		1: boost += 0.1   # Basic
		2: boost += 0.2   # Quality
		3: boost += 0.3   # Deluxe
	# Nível de farming
	var farming_level = GameManager.skill_levels[0] if GameManager else 0
	boost += farming_level * 0.02
	return min(1.0, boost)

func _setup_visuals() -> void:
	if not crop_data or not animated_sprite:
		return

	# Configura spritesheet
	# crop_data.texture_path = "TileSheets/crops"
	# crop_data.sprite_index = índice base
	# Cada fase usa frames consecutivos

	# Cria animações para cada fase
	var frames = animated_sprite.sprite_frames
	if not frames:
		frames = SpriteFrames.new()
		animated_sprite.sprite_frames = frames

	# Limpa animações existentes
	for anim in frames.get_animation_names():
		frames.remove_animation_library(anim)

	# Adiciona animações por fase
	for phase in range(crop_data.phase_count):
		var anim_name = "phase_%d" % phase
		frames.add_animation(anim_name)
		# Frame base + offset da fase
		var frame_idx = crop_data.sprite_index + phase
		frames.set_animation_loop(anim_name, false)
		# Nota: Na prática, carregar textura do TileSheets/crops
		# frames.set_animation_texture(anim_name, 0, texture, frame_rect)

	# Animação de morto
	frames.add_animation("dead")
	frames.set_animation_loop("dead", false)

	# Animação de colhível (brilho)
	frames.add_animation("ready")
	frames.set_animation_loop("ready", true)

## ==================== CRESCIMENTO ====================
## Chamado diariamente pelo GameManager
func grow_day(watered: bool) -> void:
	if is_dead or is_fully_grown:
		return

	self.watered_today = watered

	# Verifica se precisa de água e não foi regada
	if crop_data.needs_watering and not watered and not _has_retaining_soil():
		_die()
		return

	# Cresce
	growth_day += 1
	current_phase = crop_data.get_phase_at_day(growth_day)

	# Verifica se totalmente crescido
	if growth_day >= crop_data.total_growth_days:
		is_fully_grown = true
		_on_fully_grown()
	else:
		_update_visuals()
		emit_signal("growth_changed", current_phase)

	# Atualiza GameManager
	if GameManager:
		var data = GameManager.farm_crops.get(position_key, {})
		data["growth_day"] = growth_day
		data["watered"] = watered
		data["phase"] = current_phase
		data["dead"] = is_dead
		GameManager.farm_crops[position_key] = data

func _has_retaining_soil() -> bool:
	return retaining_soil_type > 0

func _die() -> void:
	is_dead = true
	animated_sprite.play("dead")
	watered_indicator.visible = false
	emit_signal("crop_died")

	# Remove do GameManager
	if GameManager:
		GameManager.farm_crops.erase(position_key)

func _on_fully_grown() -> void:
	is_fully_grown = true
	animated_sprite.play("ready")
	watered_indicator.visible = false
	emit_signal("crop_fully_grown")

## ==================== REGA ====================
func water() -> void:
	if is_dead or is_fully_grown:
		return

	watered_today = true
	watered_indicator.visible = true
	emit_signal("crop_watered")

	if GameManager:
		var data = GameManager.farm_crops.get(position_key, {})
		data["watered"] = true
		GameManager.farm_crops[position_key] = data

## ==================== COLHEITA ====================
## Retorna array de {item_id, amount, quality}
func harvest() -> Array[Dictionary]:
	if not is_fully_grown or is_dead:
		return []

	var results = []

	# Calcula quantidade
	var min_stack = crop_data.harvest_min_stack
	var max_stack = crop_data.harvest_max_stack
	var base_amount = randi_range(min_stack, max_stack)

	# Bônus de nível farming
	var farming_level = GameManager.skill_levels[0] if GameManager else 0
	var extra_chance = crop_data.extra_harvest_chance + farming_level * crop_data.harvest_max_increase_per_farming_level
	if randf() < extra_chance:
		base_amount += 1

	# Qualidade
	var quality = _determine_quality()

	results.append({
		"item_id": crop_data.harvest_item_id,
		"amount": base_amount,
		"quality": quality
	})

	# Verifica rebrota
	if crop_data.can_regrow():
		# Reseta para fase de rebrota
		growth_day = crop_data.total_growth_days - crop_data.regrow_days
		current_phase = crop_data.get_phase_at_day(growth_day)
		is_fully_grown = false
		watered_today = false
		watered_indicator.visible = false
		_update_visuals()
		harvest_count += 1

		if GameManager:
			var data = GameManager.farm_crops.get(position_key, {})
			data["growth_day"] = growth_day
			data["watered"] = false
			data["phase"] = current_phase
			data["harvest_count"] = harvest_count
			GameManager.farm_crops[position_key] = data
	else:
		# Remove completamente
		queue_free()
		if GameManager:
			GameManager.farm_crops.erase(position_key)

	# Estatísticas
	if GameManager:
		GameManager.stats.crops_harvested += 1

	for r in results:
		emit_signal("crop_harvested", r.item_id, r.amount, r.quality)

	return results

func _determine_quality() -> int:
	# 0=Normal, 1=Prata, 2=Ouro, 3=Irídio
	var base_chance = quality_boost
	var farming_level = GameManager.skill_levels[0] if GameManager else 0

	# Profissão Agricultor (rancho level 10 choice)
	if GameManager and GameManager.professions.get("Farming") == 1:  # Artisan
		base_chance += 0.2

	var rand = randf()
	if rand < base_chance * 0.1:
		return 3  # Irídio
	elif rand < base_chance * 0.3:
		return 2  # Ouro
	elif rand < base_chance * 0.6:
		return 1  # Prata
	return 0  # Normal

## ==================== VISUAL ====================
func _update_visuals() -> void:
	if not animated_sprite:
		return

	if is_dead:
		animated_sprite.play("dead")
		animated_sprite.modulate = Color(0.3, 0.2, 0.1, 1.0)
		watered_indicator.visible = false
		return

	if is_fully_grown:
		animated_sprite.play("ready")
		# Efeito de brilho sutil
		var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.005)
		animated_sprite.modulate = Color(1.0, 1.0, 1.0, pulse)
	else:
		var anim_name = "phase_%d" % current_phase
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)
		animated_sprite.modulate = Color.WHITE

	# Aplica tint se houver
	if crop_data.tint_colors.size() > 0:
		var tint = crop_data.tint_colors[randi() % crop_data.tint_colors.size()]
		animated_sprite.modulate = animated_sprite.modulate * tint

	# Indicador de água
	watered_indicator.visible = watered_today and not is_fully_grown
	if watered_indicator.visible:
		watered_indicator.modulate = Color(0.3, 0.6, 1.0, 0.7 + 0.3 * sin(Time.get_ticks_msec() * 0.003))

	# Indicador de fertilizante
	_show_fertilizer_indicator()

func _show_fertilizer_indicator() -> void:
	var indicator = get_node_or_null("FertilizerIndicator")
	if fertilizer_type > 0:
		if not indicator:
			indicator = Sprite2D.new()
			indicator.name = "FertilizerIndicator"
			indicator.position = Vector2(-20, -40)
			indicator.z_index = 5
			add_child(indicator)

		var fert_colors = {
			1: Color(0.5, 0.35, 0.2),   # Basic - marrom
			2: Color(0.7, 0.5, 0.9),    # Quality - roxo
			3: Color(1.0, 0.8, 0.2)     # Deluxe - dourado
		}
		indicator.modulate = fert_colors.get(fertilizer_type, Color.WHITE)
		indicator.visible = true
	elif indicator:
		indicator.visible = false

	# Indicador de speed-gro
	var speed_indicator = get_node_or_null("SpeedGroIndicator")
	if speed_gro_type > 0:
		if not speed_indicator:
			speed_indicator = Sprite2D.new()
			speed_indicator.name = "SpeedGroIndicator"
			speed_indicator.position = Vector2(20, -40)
			speed_indicator.z_index = 5
			add_child(speed_indicator)

		var speed_colors = {
			1: Color(0.4, 0.8, 0.4),    # Speed-Gro - verde
			2: Color(0.2, 1.0, 0.4),    # Deluxe - verde brilhante
			3: Color(0.0, 1.0, 1.0)     # Hyper - ciano
		}
		speed_indicator.modulate = speed_colors.get(speed_gro_type, Color.GREEN)
		speed_indicator.visible = true
	elif speed_indicator:
		speed_indicator.visible = false

## ==================== EFEITOS DE CRESCIMENTO ====================
func _on_fully_grown() -> void:
	# Partículas de "pronto para colher"
	if ParticleManager:
		ParticleManager.spawn("harvest", global_position + Vector2(16, -16))

	# Som de crescimento final
	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/crop_ready.ogg", global_position)

	emit_signal("crop_fully_grown")

func _die() -> void:
	is_dead = true

	# Partículas de morte
	if ParticleManager:
		ParticleManager.spawn_area("cut", global_position, 8, 16.0)

	# Som de morte
	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/crop_die.ogg", global_position)

	emit_signal("crop_died")
	_update_visuals()

## ==================== REGROWTH ====================
func harvest() -> void:
	if not is_fully_grown:
		return

	# Calcula qualidade e quantidade
	var quality = _calculate_harvest_quality()
	var amount = _calculate_harvest_amount()

	# Item de colheita
	var harvest_item = crop_data.harvest_item_id
	if harvest_item == "":
		harvest_item = crop_id

	# Adiciona ao inventário
	if InventoryManager:
		InventoryManager.add_item(harvest_item, amount, quality)

	# Estatísticas
	if GameManager:
		GameManager.stats.crops_harvested += amount
		GameManager.emit_signal("crop_harvested", harvest_item, amount, quality)

	# Notificação visual
	HUD.show_notification("🌾 Colhido!", "%s x%d (%s)" % [
		DataLoader.get_item(harvest_item)?.display_name ?? harvest_item,
		amount,
		["Normal", "Prata", "Ouro", "Irídio"][quality]
	], QUALITY_COLORS[quality])

	# Partículas de colheita
	if ParticleManager:
		ParticleManager.spawn("harvest", global_position + Vector2(16, -16))

	# Som de colheita
	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/harvest.ogg", global_position)

	harvest_count += 1

	# Verifica regrow
	if crop_data.regrow_days > 0 and harvest_count < crop_data.max_harvests:
		# Volta para fase de regrow
		is_fully_grown = false
		growth_day = crop_data.total_growth_days - crop_data.regrow_days
		current_phase = crop_data.get_phase_at_day(growth_day)

		# Efeito visual de regrow
		_show_regrow_effect()

		# Atualiza GameManager
		if GameManager:
			var data = GameManager.farm_crops.get(position_key, {})
			data["growth_day"] = growth_day
			data["phase"] = current_phase
			data["harvest_count"] = harvest_count
			GameManager.farm_crops[position_key] = data
	else:
		# Remove cultivo
		queue_free()
		if GameManager:
			GameManager.farm_crops.erase(position_key)

	emit_signal("crop_harvested", harvest_item, amount, quality)

func _show_regrow_effect() -> void:
	# Partículas de regrow
	if ParticleManager:
		ParticleManager.spawn("seed", global_position + Vector2(16, -16))
		ParticleManager.spawn_area("water", global_position, 6, 20.0)

	# Texto flutuante
	var label = Label.new()
	label.text = "🌱 Rebrotando em %d dias!" % crop_data.regrow_days
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_override_font_size = 14
	label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.global_position = global_position + Vector2(16, -32)
	get_tree().root.get_child(0).add_child(label)

	var tween = label.create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 40, 2.0)
	tween.tween_property(label, "modulate:a", 0.0, 2.0)
	tween.finished.connect(label.queue_free.bind())

	# Som de regrow
	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/regrow.ogg", global_position)

const QUALITY_COLORS = {
	0: Color(1.0, 1.0, 1.0),    # Normal
	1: Color(0.75, 0.75, 0.75), # Prata
	2: Color(1.0, 0.85, 0.2),   # Ouro
	3: Color(0.6, 0.3, 1.0)     # Irídio
}

## ==================== FERRAMENTAS ====================
func on_tool_hit(tool: String, power: float) -> void:
	match tool:
		"Pickaxe", "Axe":
			# Destrói cultivo
			_die()
		"Hoe":
			# Se solo vazio, permite replantar
			if is_dead:
				queue_free()
				if GameManager:
					GameManager.farm_crops.erase(position_key)
		"Scythe":
			# Colhe se pronto
			if is_fully_grown:
				harvest()

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"crop_id": crop_id,
		"growth_day": growth_day,
		"current_phase": current_phase,
		"watered_today": watered_today,
		"is_dead": is_dead,
		"is_fully_grown": is_fully_grown,
		"harvest_count": harvest_count,
		"quality_boost": quality_boost,
		"fertilizer_type": fertilizer_type,
		"retaining_soil_type": retaining_soil_type,
		"speed_gro_type": speed_gro_type,
		"position_key": position_key,
		"planted_by": planted_by
	}

func load_save_data(data: Dictionary) -> void:
	crop_id = data.get("crop_id", "")
	growth_day = data.get("growth_day", 0)
	current_phase = data.get("current_phase", 0)
	watered_today = data.get("watered_today", false)
	is_dead = data.get("is_dead", false)
	is_fully_grown = data.get("is_fully_grown", false)
	harvest_count = data.get("harvest_count", 0)
	quality_boost = data.get("quality_boost", 0.0)
	fertilizer_type = data.get("fertilizer_type", 0)
	retaining_soil_type = data.get("retaining_soil_type", 0)
	speed_gro_type = data.get("speed_gro_type", 0)
	position_key = data.get("position_key", "")
	planted_by = data.get("planted_by", 1)

	# Recarrega crop_data do DataLoader
	if DataLoader:
		crop_data = DataLoader.get_crop(crop_id.to_int())

	_setup_visuals()
	_update_visuals()