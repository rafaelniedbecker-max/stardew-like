class_name CrabPot
extends Node2D

## Crab Pot - armadilha de caranguejo/peixe para água

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var bait_slot: TextureRect = $BaitSlot
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var output_slot: TextureRect = $OutputSlot

## Estado
var bait_type: String = ""           # Tipo de isca
var bait_quality: int = 0            # Qualidade da isca
var has_bait: bool = false
var is_processing: bool = false
var progress: float = 0.0
var processing_time: float = 1200.0  # 1200 min = 20h in-game
var output_item: String = ""
var output_ready: bool = false
var output_quality: int = 0
var water_type: String = "freshwater"  # "freshwater", "saltwater", "any"

## Configurações de isca
const BAIT_TYPES = {
	"(O)685": {"name": "Bait", "quality_boost": 0.0, "catch_rate": 1.0},           # Bait básico
	"(O)773": {"name": "Wild Bait", "quality_boost": 0.1, "catch_rate": 1.5},     # Wild Bait
	"(O)702": {"name": "Magnet", "quality_boost": 0.0, "catch_rate": 1.0, "treasure_only": true},  # Magnet
}

## Tabelas de captura por tipo de água
const FRESHWATER_CATCH = {
	# Peixes comuns
	"(O)152": {"name": "Sunfish", "chance": 20, "quality_base": 0},
	"(O)148": {"name": "Shad", "chance": 15, "quality_base": 0},
	"(O)150": {"name": "Catfish", "chance": 10, "quality_base": 0},
	"(O)149": {"name": "Bream", "chance": 15, "quality_base": 0},
	"(O)153": {"name": "Tiger Trout", "chance": 8, "quality_base": 0},
	"(O)151": {"name": "Salmon", "chance": 12, "quality_base": 0},
	"(O)154": {"name": "Lingcod", "chance": 5, "quality_base": 0},
	"(O)155": {"name": "Sturgeon", "chance": 3, "quality_base": 0},  # Caviar!
	# Lixo
	"(O)168": {"name": "Driftwood", "chance": 20, "quality_base": 0},
	"(O)169": {"name": "Broken Glasses", "chance": 10, "quality_base": 0},
	"(O)170": {"name": "Broken CD", "chance": 10, "quality_base": 0},
	"(O)171": {"name": "Soggy Newspaper", "chance": 15, "quality_base": 0},
}

const SALTWATER_CATCH = {
	# Peixes de mar
	"(O)156": {"name": "Tuna", "chance": 15, "quality_base": 0},
	"(O)157": {"name": "Sardine", "chance": 25, "quality_base": 0},
	"(O)158": {"name": "Red Snapper", "chance": 10, "quality_base": 0},
	"(O)159": {"name": "Tilapia", "chance": 20, "quality_base": 0},
	"(O)160": {"name": "Legend", "chance": 1, "quality_base": 0},  # Lendário
	# Lixo marinho
	"(O)168": {"name": "Driftwood", "chance": 20, "quality_base": 0},
	"(O)169": {"name": "Broken Glasses", "chance": 10, "quality_base": 0},
	"(O)170": {"name": "Broken CD", "chance": 10, "quality_base": 0},
	"(O)171": {"name": "Soggy Newspaper", "chance": 15, "quality_base": 0},
	"(O)172": {"name": "Seaweed", "chance": 15, "quality_base": 0},
	"(O)173": {"name": "Green Algae", "chance": 10, "quality_base": 0},
}

## ==================== SINAIS ====================
signal catch_ready(item_id: String, quality: int)
signal bait_consumed(bait_type: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	progress_bar.visible = false
	output_slot.visible = false

	_load_state()

	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		var prompt = "E: Ver Crab Pot"
		if has_bait and not is_processing:
			prompt += " (Vazio - adicione isca)"
		elif is_processing:
			prompt += " (%.0f%%)" % (progress * 100)
		elif output_ready:
			prompt += " - Pronto para coletar!"
		HUD.show_interaction_prompt(prompt, global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	_open_ui()

## ==================== UI ====================
func _open_ui() -> void:
	var panel = Panel.new()
	panel.name = "CrabPotUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 100
	panel.offset_right = -200
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🦀 Crab Pot (%s)" % (water_type == "freshwater" ? "Água Doce" : "Água Salgada")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	if not has_bait:
		# Sem isca
		var empty = Label.new()
		empty.text = "Adicione isca para começar a pescar!"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = 1
		empty.theme_override_font_size = 16
		vbox.add_child(empty)

		var add_btn = Button.new()
		add_btn.text = "Adicionar Isca"
		add_btn.custom_minimum_size = Vector2(0, 50)
		add_btn.theme_override_font_size = 18
		add_btn.pressed.connect(_add_bait_ui.bind(panel))
		vbox.add_child(add_btn)

		var close_btn = Button.new()
		close_btn.text = "Fechar"
		close_btn.custom_minimum_size = Vector2(0, 40)
		close_btn.pressed.connect(panel.queue_free.bind())
		vbox.add_child(close_btn)
	else:
		# Com isca
		var bait_data = BAIT_TYPES.get(bait_type, {})
		var bait_name = bait_data.get("name", "Isca")

		var info_hbox = HBoxContainer.new()
		info_hbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_hbox.theme_override_constants/separation = 20

		var bait_info = Label.new()
		bait_info.text = "Isca: %s (%s)" % [bait_name, ["Normal", "Prata", "Ouro", "Irídio"][bait_quality]]
		bait_info.theme_override_font_size = 16
		info_hbox.add_child(bait_info)

		var water_info = Label.new()
		water_info.text = "Tipo: %s" % (water_type == "freshwater" ? "🌊 Doce" : "🌊 Salgada")
		water_info.theme_override_font_size = 16
		info_hbox.add_child(water_info)

		vbox.add_child(info_hbox)

		if is_processing:
			var status = Label.new()
			status.text = "Pescando... %.0f%%" % (progress * 100)
			status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			status.theme_override_font_size = 18
			vbox.add_child(status)

			var bar = ProgressBar.new()
			bar.value = progress * 100
			bar.max_value = 100
			bar.custom_minimum_size = Vector2(300, 20)
			vbox.add_child(bar)

			var time_left = Label.new()
			time_left.text = "Tempo: %.1fh" % ((processing_time * (1.0 - progress)) / 60.0)
			time_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			time_left.theme_override_font_size = 14
			vbox.add_child(time_left)
		elif output_ready:
			var item = DataLoader.get_item(output_item)
			var collect_btn = Button.new()
			collect_btn.text = "Coletar: %s (%s)" % [item?.display_name ?? output_item, ["Normal", "Prata", "Ouro", "Irídio"][output_quality]]
			collect_btn.custom_minimum_size = Vector2(250, 50)
			collect_btn.theme_override_font_size = 16
			collect_btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			collect_btn.pressed.connect(_collect_output.bind(panel))
			vbox.add_child(collect_btn)
		else:
			var status = Label.new()
			status.text = "Aguardando isca ser consumida..."
			status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			status.theme_override_font_size = 16
			vbox.add_child(status)

		var remove_btn = Button.new()
		remove_btn.text = "🗑 Remover Isca"
		remove_btn.custom_minimum_size = Vector2(0, 40)
		remove_btn.pressed.connect(_remove_bait.bind(panel))
		vbox.add_child(remove_btn)

		var close_btn = Button.new()
		close_btn.text = "Fechar"
		close_btn.custom_minimum_size = Vector2(0, 40)
		close_btn.pressed.connect(panel.queue_free.bind())
		vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _add_bait_ui(panel: Panel) -> void:
	if InventoryManager:
		InventoryManager.open_crab_pot_mode(self, panel)

func add_bait(bait_id: String, quality: int = 0) -> bool:
	if has_bait:
		HUD.show_message("Já tem isca no pot!")
		return false

	if not BAIT_TYPES.has(bait_id):
		HUD.show_message("Isca inválida!")
		return false

	if not InventoryManager.remove_item(bait_id, 1):
		return false

	bait_type = bait_id
	bait_quality = quality
	has_bait = true
	is_processing = true
	progress = 0.0

	# Tempo baseado na isca
	var bait_data = BAIT_TYPES[bait_id]
	processing_time = 1200.0 / bait_data.catch_rate  # Wild Bait = mais rápido

	_save_state()
	HUD.show_message("%s colocada!" % bait_data.name)
	emit_signal("bait_consumed", bait_id)

	if ParticleManager:
		ParticleManager.spawn("water", global_position + Vector2(0, -32))

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/crab_pot_bait.ogg", global_position)

	return true

func _remove_bait(panel: Panel) -> void:
	if not has_bait:
		return

	if InventoryManager.add_item(bait_type, 1, bait_quality):
		has_bait = false
		is_processing = false
		progress = 0.0
		bait_type = ""
		bait_quality = 0
		_save_state()
		HUD.show_message("Isca removida.")
		panel.queue_free()
		_open_ui()
	else:
		HUD.show_message("Inventário cheio!")

func _collect_output(panel: Panel) -> void:
	if not output_ready:
		return

	if InventoryManager.add_item(output_item, 1, output_quality):
		output_ready = false
		output_item = ""
		output_quality = 0
		has_bait = false
		is_processing = false
		progress = 0.0
		bait_type = ""
		bait_quality = 0

		_save_state()

		if ParticleManager:
			ParticleManager.spawn("harvest", global_position + Vector2(0, -32))

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/crab_pot_collect.ogg", global_position)

		var item = DataLoader.get_item(output_item)
		var q_names = ["Normal", "Prata", "Ouro", "Irídio"]
		HUD.show_notification("🦀 Captura!", "%s (%s)" % [item?.display_name ?? output_item, q_names[output_quality]], Color(0.5, 1.0, 0.5))

		emit_signal("catch_ready", output_item, output_quality)

		panel.queue_free()
		_open_ui()
	else:
		HUD.show_message("Inventário cheio!")

## ==================== PROCESSAMENTO ====================
func _process(delta: float) -> void:
	if not is_processing:
		return

	if TimeManager:
		progress += (TimeManager.tick_rate * delta) / processing_time
	else:
		progress += delta / (processing_time / 60.0)  # Fallback

	progress = min(1.0, progress)

	if progress >= 1.0:
		_finish_processing()

func _finish_processing() -> void:
	is_processing = false
	progress = 1.0

	# Determina captura baseada no tipo de água
	var catch_table = water_type == "freshwater" ? FRESHWATER_CATCH : SALTWATER_CATCH
	var bait_data = BAIT_TYPES.get(bait_type, {})
	var quality_boost = bait_data.get("quality_boost", 0.0)

	# Magnet só pega tesouros
	if bait_data.get("treasure_only", false):
		output_item = _roll_treasure()
	else:
		output_item = _roll_catch(catch_table)

	# Calcula qualidade
	output_quality = _calculate_quality(quality_boost)
	output_ready = true

	# Notificação
	if ParticleManager:
		ParticleManager.spawn("harvest", global_position + Vector2(0, -32))

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/crab_pot_ready.ogg", global_position)

	HUD.show_notification("🦀 Captura Pronta!", "Verifique seu Crab Pot!", Color(1.0, 0.7, 0.3))

	_save_state()

func _roll_catch(table: Dictionary) -> String:
	var total_chance = 0
	for item_id in table:
		total_chance += table[item_id].chance

	var rand = randf() * total_chance
	var accum = 0.0

	for item_id in table:
		accum += table[item_id].chance
		if rand <= accum:
			return item_id

	return table.keys()[0]

func _roll_treasure() -> String:
	# Tesouros raros
	var treasures = [
		{"id": "(O)749", "chance": 1},      # Prismatic Shard
		{"id": "(O)114", "chance": 2},      # Ancient Seed
		{"id": "(O)116", "chance": 3},      # Ancient Doll
		{"id": "(O)768", "chance": 2},      # Galaxy Sword component
		{"id": "(O)440", "chance": 5},      # Diamond
		{"id": "(O)72", "chance": 10},      # Gold Bar
		{"id": "(O)384", "chance": 8},      # Iridium Ore
		{"id": "(O)378", "chance": 10},     # Gold Ore
		{"id": "(O)380", "chance": 15},     # Iron Ore
		{"id": "(O)384", "chance": 20},     # Copper Ore
		{"id": "(O)390", "chance": 15},     # Coal
	]
	var total = 0
	for t in treasures:
		total += t.chance

	var rand = randf() * total
	var accum = 0.0
	for t in treasures:
		accum += t.chance
		if rand <= accum:
			return t.id

	return "(O)390"  # Coal fallback

func _calculate_quality(boost: float) -> int:
	var chance = boost + (GameManager.daily_luck if GameManager else 0.0)

	# Sorte do dia
	if GameManager:
		chance += GameManager.daily_luck

	if chance > 0.9: return 3
	elif chance > 0.7: return 2
	elif chance > 0.4: return 1
	return 0

## ==================== CICLO DIÁRIO ====================
func _on_day_changed(day: int, season: int, year: int) -> void:
	# Reseta se não tem isca
	if not has_bait:
		is_processing = false
		progress = 0.0

	_save_state()

## ==================== PERSISTÊNCIA ====================
func _save_state() -> void:
	if GameManager:
		GameManager.set("crab_pot_%s" % [name], {
			"bait_type": bait_type,
			"bait_quality": bait_quality,
			"has_bait": has_bait,
			"is_processing": is_processing,
			"progress": progress,
			"output_item": output_item,
			"output_ready": output_ready,
			"output_quality": output_quality,
			"water_type": water_type
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get("crab_pot_%s" % [name], {})
		if data:
			bait_type = data.get("bait_type", "")
			bait_quality = data.get("bait_quality", 0)
			has_bait = data.get("has_bait", false)
			is_processing = data.get("is_processing", false)
			progress = data.get("progress", 0.0)
			output_item = data.get("output_item", "")
			output_ready = data.get("output_ready", false)
			output_quality = data.get("output_quality", 0)
			water_type = data.get("water_type", "freshwater")

func initialize(water_type_param: String = "freshwater") -> void:
	water_type = water_type_param