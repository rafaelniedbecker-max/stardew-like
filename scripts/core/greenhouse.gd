class_name Greenhouse
extends Node

## Estufa: cultivo o ano todo, layout fixo 10x12, regadores funcionam

@export var greenhouse_scene: PackedScene

## Estado
var unlocked: bool = false
var crop_plots: Dictionary = {}  # {position_key: GreenhousePlot}
var sprinklers_active: Array = []

## Layout da estufa (10x12 tiles plantáveis no centro)
const GREENHOUSE_SIZE = Vector2i(10, 12)
const PLANTABLE_AREA = Rect2i(1, 1, 10, 12)  # Offset 1,1 para paredes

## ==================== SINAIS ====================
signal greenhouse_unlocked()
signal crop_planted(position: Vector2i, crop_id: String)
signal crop_harvested(position: Vector2i, item_id: String, amount: int, quality: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	unlocked = GameManager.get("cc_greenhouse_unlocked", false) or GameManager.get("greenhouse_unlocked", false)
	if unlocked:
		_initialize_plots()

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
				"quality_boost": 0
			}

## ==================== DESBLOQUEIO ====================
func unlock() -> void:
	if unlocked:
		return

	unlocked = true
	GameManager.set("greenhouse_unlocked", true)
	_initialize_plots()
	emit_signal("greenhouse_unlocked")
	_show_message("Estufa reparada! Agora você pode plantar o ano todo.")

## ==================== PLANTIO ====================
func can_plant_at(position: Vector2i) -> bool:
	if not unlocked:
		return false

	var key = "%d,%d" % [position.x, position.y]
	var plot = crop_plots.get(key)
	return plot and plot.crop_id == ""

func plant_crop(position: Vector2i, crop_id: String, fertilizer: String = "") -> bool:
	if not can_plant_at(position):
		return false

	var crop_data = DataLoader.get_crop(crop_id)
	if not crop_data:
		return false

	# Estufa ignora estação
	var key = "%d,%d" % [position.x, position.y]
	crop_plots[key] = {
		"position": position,
		"crop_id": crop_id,
		"growth_day": 0,
		"watered": false,
		"fertilizer": fertilizer,
		"planted_day": GameManager.current_day,
		"quality_boost": _get_fertilizer_quality_boost(fertilizer)
	}

	emit_signal("crop_planted", position, crop_id)
	return true

func _get_fertilizer_quality_boost(fertilizer: String) -> int:
	match fertilizer:
		"Basic Fertilizer": return 1
		"Quality Fertilizer": return 2
		"Deluxe Fertilizer": return 3
		"Speed-Gro": return 0
		"Deluxe Speed-Gro": return 0
		"Hyper Speed-Gro": return 0
		_: return 0

## ==================== REGA ====================
func water_position(position: Vector2i) -> bool:
	var key = "%d,%d" % [position.x, position.y]
	var plot = crop_plots.get(key)
	if not plot or plot.crop_id == "":
		return false

	plot.watered = true
	return true

func water_area(center: Vector2i, radius: int) -> int:
	var watered = 0
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var pos = Vector2i(center.x + x, center.y + y)
			if water_position(pos):
				watered += 1
	return watered

## ==================== CRESCIMENTO DIÁRIO ====================
func process_daily_growth() -> void:
	if not unlocked:
		return

	for key in crop_plots:
		var plot = crop_plots[key]
		if plot.crop_id == "":
			continue

		var crop_data = DataLoader.get_crop(plot.crop_id)
		if not crop_data:
			continue

		# Verifica rega (estufa não chove)
		if not plot.watered and crop_data.needs_watering:
			# Planta morre se não regada por 2 dias
			plot.growth_day -= 1
			if plot.growth_day < -1:
				_clear_plot(key)
				continue

		plot.growth_day += 1
		plot.watered = false  # Reseta para próximo dia

		# Verifica colheita
		var total_days = 0
		for phase in crop_data.days_in_phase:
			total_days += phase

		# Aplica fertilizante de velocidade
		var speed_mult = _get_fertilizer_speed_mult(plot.fertilizer)
		var effective_days = int(total_days / speed_mult)

		if plot.growth_day >= effective_days:
			# Pronto para colher
			plot.growth_day = effective_days  # Cap

			# Verifica regeneração
			if crop_data.regrow_days > 0:
				plot.growth_day = effective_days - crop_data.regrow_days

func _get_fertilizer_speed_mult(fertilizer: String) -> float:
	match fertilizer:
		"Speed-Gro": return 1.1
		"Deluxe Speed-Gro": return 1.25
		"Hyper Speed-Gro": return 1.33
		_: return 1.0

## ==================== COLHEITA ====================
func harvest_at(position: Vector2i) -> Dictionary:
	var key = "%d,%d" % [position.x, position.y]
	var plot = crop_plots.get(key)
	if not plot or plot.crop_id == "":
		return {}

	var crop_data = DataLoader.get_crop(plot.crop_id)
	if not crop_data:
		return {}

	# Verifica se está pronto
	var total_days = 0
	for phase in crop_data.days_in_phase:
		total_days += phase
	var speed_mult = _get_fertilizer_speed_mult(plot.fertilizer)
	var effective_days = int(total_days / speed_mult)

	if plot.growth_day < effective_days:
		return {}

	# Calcula colheita
	var amount = randi_range(crop_data.harvest_min_stack, crop_data.harvest_max_stack)
	var farming_bonus = int(GameManager.get_skill_level("Farming") * crop_data.harvest_max_increase_per_farming_level)
	amount += farming_bonus

	# Chance de colheita extra
	if randf() < crop_data.extra_harvest_chance:
		amount += 1

	# Qualidade
	var quality = _calculate_harvest_quality(crop_data, plot)

	var item_id = crop_data.harvest_item_id
	var result = {
		"item_id": item_id,
		"amount": amount,
		"quality": quality
	}

	# Adiciona ao inventário
	for i in range(amount):
		InventoryManager.add_item(item_id, 1, quality)

	# XP Farming
	GameManager.add_skill_xp(0, 7 * amount)
	GameManager.increment_stat("crops_harvested", amount)

	# Verifica regeneração
	if crop_data.regrow_days > 0:
		plot.growth_day = effective_days - crop_data.regrow_days
		plot.watered = false
	else:
		_clear_plot(key)

	emit_signal("crop_harvested", position, item_id, amount, quality)
	return result

func _calculate_harvest_quality(crop_data: CropData, plot: Dictionary) -> int:
	var chance = 0.0

	# Base: nível de farming
	chance += GameManager.get_skill_level("Farming") * 0.02

	# Fertilizante de qualidade
	chance += plot.quality_boost * 0.15

	# Sorte diária
	chance += (GameManager.daily_luck + 0.1) * 0.2

	# Profissão Agricultor (level 10 farming = 1)
	if GameManager.professions.get("Farming") == 1:
		chance += 0.2

	# Mínimo de qualidade da cultura
	var min_q = crop_data.harvest_min_quality
	if min_q > 0:
		chance = max(chance, min_q * 0.3)

	if chance > 0.9:
		return 3
	elif chance > 0.6:
		return 2
	elif chance > 0.3:
		return 1
	return 0

func _clear_plot(key: String) -> void:
	if crop_plots.has(key):
		crop_plots[key] = {
			"position": crop_plots[key].position,
			"crop_id": "",
			"growth_day": 0,
			"watered": false,
			"fertilizer": "",
			"planted_day": 0,
			"quality_boost": 0
		}

## ==================== ASPERSORES ====================
func register_sprinkler(position: Vector2i, pattern: Array[Vector2i]) -> void:
	sprinklers_active.append({"position": position, "pattern": pattern})

func process_sprinklers() -> void:
	for sprinkler in sprinklers_active:
		for offset in sprinkler.pattern:
			var pos = sprinkler.position + offset
			water_position(pos)

## ==================== UI ====================
func open_greenhouse() -> void:
	if not unlocked:
		_show_message("A estufa está em ruínas. Complete os bundles da Despensa no Centro Comunitário para repará-la.")
		return

	if greenhouse_scene:
		var ui = greenhouse_scene.instantiate()
		ui.initialize(crop_plots)
		get_tree().root.get_child(0).add_child(ui)
	else:
		_show_generic_greenhouse_ui()

func _show_generic_greenhouse_ui() -> void:
	var panel = Panel.new()
	panel.name = "GreenhouseUI"
	panel.anchors_preset = 15
	panel.offset_left = 50
	panel.offset_top = 30
	panel.offset_right = -50
	panel.offset_bottom = -30

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Estufa - Cultivo o Ano Todo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	# Grid visual 10x12
	var grid = GridContainer.new()
	grid.columns = 10
	grid.theme_override_constants/h_separation = 2
	grid.theme_override_constants/v_separation = 2
	vbox.add_child(grid)

	for y in range(12):
		for x in range(10):
			var pos = Vector2i(x + 1, y + 1)
			var key = "%d,%d" % [pos.x, pos.y]
			var plot = crop_plots.get(key, {})

			var btn = Button.new()
			btn.custom_minimum_size = Vector2(40, 40)

			if plot.crop_id != "":
				var crop = DataLoader.get_crop(plot.crop_id)
				var name = crop?.internal_name ?? plot.crop_id
				var progress = plot.growth_day
				var total = 0
				if crop:
					for phase in crop.days_in_phase:
						total += phase
					total = int(total / _get_fertilizer_speed_mult(plot.fertilizer))
				btn.text = "%s\n%d/%d" % [name.left(4), progress, total]
				btn.tooltip_text = "%s - Dia %d/%d%s" % [name, progress, total, plot.watered ? " 💧" : ""]
			else:
				btn.text = "🟫"
				btn.tooltip_text = "Vazio - Clique para plantar"

			btn.pressed.connect(_on_plot_clicked.bind(pos))
			grid.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _on_plot_clicked(position: Vector2i) -> void:
	var key = "%d,%d" % [position.x, position.y]
	var plot = crop_plots.get(key, {})

	if plot.crop_id == "":
		# Abre seleção de sementes
		_show_seed_selection(position)
	else:
		# Tenta colher
		var result = harvest_at(position)
		if result:
			_show_message("Colheu %d %s (Qualidade %d)" % [result.amount, result.item_id, result.quality])

func _show_seed_selection(position: Vector2i) -> void:
	var popup = PopupMenu.new()
	var seeds = InventoryManager.get_items_by_category("Seeds")
	for item_id in seeds:
		var item = DataLoader.get_item(item_id)
		if item:
			popup.add_item("%s (x%d)" % [item.display_name, InventoryManager.get_item_count(item_id)], popup.get_item_count())
			popup.set_item_metadata(popup.get_item_count() - 1, item_id)

	popup.id_pressed.connect(_on_seed_selected.bind(position))
	popup.popup_centered()

func _on_seed_selected(position: Vector2i, idx: int) -> void:
	var popup = get_tree().root.get_child(0).get_node_or_null("PopupMenu")
	if not popup:
		return

	var item_id = popup.get_item_metadata(idx)
	if plant_crop(position, item_id):
		_show_message("Plantou %s na estufa!" % item_id)

func _show_message(text: String) -> void:
	print("Greenhouse: %s" % text)

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	var plots_data = {}
	for key, plot in crop_plots:
		plots_data[key] = plot
	return {
		"unlocked": unlocked,
		"crop_plots": plots_data
	}

func load_save_data(data: Dictionary) -> void:
	unlocked = data.get("unlocked", false)
	if unlocked:
		_initialize_plots()
		for key, plot in data.get("crop_plots", {}):
			if crop_plots.has(key):
				crop_plots[key] = plot