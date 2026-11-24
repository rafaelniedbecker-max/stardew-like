class_name PreservesJar
extends Node2D

## Preserves Jar - transforma frutas em geleia, vegetais em picles

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var input_slot: TextureRect = $InputSlot
@onready var output_slot: TextureRect = $OutputSlot

## Estado
var processing_item: String = ""
var processing_quality: int = 0
var progress: float = 0.0
var processing_time: float = 4000.0  # 4000 minutos in-game = ~2.8 dias
var is_processing: bool = false
var output_item: String = ""
var output_quality: int = 0

## Receitas baseadas no tipo de item
const PRESERVES_TYPES = {
	"fruit": {"output_suffix": "Jelly", "base_price_mult": 2.0, "base_price_add": 50, "time": 4000},
	"vegetable": {"output_suffix": "Pickles", "base_price_mult": 2.0, "base_price_add": 50, "time": 4000},
	"fish": {"output_suffix": "Pickled", "base_price_mult": 1.5, "base_price_add": 25, "time": 6000},
	"forage": {"output_suffix": "Pickled", "base_price_mult": 1.5, "base_price_add": 25, "time": 4000},
}

## ==================== SINAIS ====================
signal processing_started(item_id: String)
signal processing_finished(item_id: String, quality: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	progress_bar.visible = false
	input_slot.visible = false
	output_slot.visible = false

	_load_state()

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.show_interaction_prompt("E: Usar Preserves Jar", global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	_open_ui()

## ==================== LÓGICA ====================
func _get_preserve_type(item_id: String) -> String:
	var item = DataLoader.get_item(item_id)
	if not item:
		return ""

	# Frutas (categoria -75 ou -79, ou nome contém fruit)
	if item.category in [-75, -79] or "fruit" in item.internal_name.to_lower() or item_id in [
		"(O)428", "(O)430", "(O)432", "(O)434", "(O)436", "(O)438", "(O)440", "(O)442",  # Frutas de árvore
		"(O)228", "(O)230", "(O)232", "(O)234", "(O)236", "(O)238", "(O)240",  # Frutas de planta
		"(O)242", "(O)244", "(O)246", "(O)248", "(O)250", "(O)252", "(O)254", "(O)256"
	]:
		return "fruit"

	# Vegetais
	if item.category in [-74, -76] or "veg" in item.internal_name.to_lower():
		return "vegetable"

	# Peixes
	if item.category == -4:  # Fish
		return "fish"

	# Forrageamento
	if item.category in [-81, -80] or item_id in ["(O)16", "(O)18", "(O)20", "(O)22", "(O)24", "(O)26", "(O)28", "(O)30", "(O)32", "(O)34", "(O)36", "(O)38"]:
		return "forage"

	return "vegetable"  # Default

func _get_output_item(item_id: String, preserve_type: String) -> String:
	var item = DataLoader.get_item(item_id)
	if not item:
		return ""

	var base_name = item.display_name
	var suffix = PRESERVES_TYPES[preserve_type].output_suffix

	# Procura item existente com esse nome
	var output_name = "%s %s" % [base_name, suffix]

	# Tenta achar no DataLoader
	var all_items = DataLoader.get_all_items()
	for id, data in all_items:
		if data.display_name == output_name:
			return id

	# Fallback: cria ID baseado no original
	# Geleias de frutas geralmente têm IDs sequenciais
	return item_id  # Placeholder - na prática mapearia para IDs reais

func can_process(item_id: String) -> bool:
	return _get_preserve_type(item_id) != ""

## ==================== UI ====================
func _open_ui() -> void:
	var panel = Panel.new()
	panel.name = "PreservesJarUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 100
	panel.offset_right = -200
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🫙 Preserves Jar"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	if is_processing:
		var item = DataLoader.get_item(processing_item)
		var status = Label.new()
		status.text = "Processando: %s (%.1f%%)" % [item?.display_name ?? processing_item, progress * 100]
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.theme_override_font_size = 16
		vbox.add_child(status)

		var bar = ProgressBar.new()
		bar.value = progress * 100
		bar.max_value = 100
		bar.custom_minimum_size = Vector2(300, 20)
		vbox.add_child(bar)

		var time_left = Label.new()
		time_left.text = "Tempo restante: %.1f horas" % ((processing_time * (1.0 - progress)) / 60.0)
		time_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_left.theme_override_font_size = 14
		vbox.add_child(time_left)

		var collect_btn = Button.new()
		collect_btn.text = "Coletar" if progress >= 1.0 else "Aguardando..."
		collect_btn.disabled = progress < 1.0
		collect_btn.custom_minimum_size = Vector2(0, 40)
		collect_btn.pressed.connect(_collect_output.bind(panel))
		vbox.add_child(collect_btn)
	else:
		var desc = Label.new()
		desc.text = "Coloque frutas para geleia, vegetais para picles, ou peixes/forrageados para conservas:"
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.autowrap_mode = 1
		desc.theme_override_font_size = 13
		vbox.add_child(desc)

		var slot_hbox = HBoxContainer.new()
		slot_hbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_hbox.theme_override_constants/separation = 20

		var input_btn = Button.new()
		input_btn.custom_minimum_size = Vector2(80, 80)
		if processing_item != "":
			var item = DataLoader.get_item(processing_item)
			if item and item.texture_path != "":
				input_btn.icon = load(item.texture_path)
			# Qualidade
			var q_colors = [Color.WHITE, Color(0.75,0.75,0.75), Color(1.0,0.85,0.2), Color(0.6,0.3,1.0)]
			input_btn.add_theme_color_override("font_color", q_colors[processing_quality] if processing_quality < 4 else Color.WHITE)
		else:
			input_btn.text = "+"
			input_btn.theme_override_font_size = 32
		input_btn.pressed.connect(_select_input_item.bind(panel))
		slot_hbox.add_child(input_btn)

		var arrow = Label.new()
		arrow.text = "→"
		arrow.theme_override_font_size = 32
		arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_hbox.add_child(arrow)

		var output_btn = Button.new()
		output_btn.custom_minimum_size = Vector2(80, 80)
		output_btn.disabled = true
		if processing_item != "" and can_process(processing_item):
			var ptype = _get_preserve_type(processing_item)
			var out_name = "%s %s" % [DataLoader.get_item(processing_item)?.display_name ?? processing_item, PRESERVES_TYPES[ptype].output_suffix]
			var out_item = DataLoader.get_item(_get_output_item(processing_item, ptype))
			if out_item and out_item.texture_path != "":
				output_btn.icon = load(out_item.texture_path)
			output_btn.tooltip_text = "%s\nValor base: %dg" % [out_name, _calculate_value(processing_item, processing_quality, ptype)]
		slot_hbox.add_child(output_btn)

		vbox.add_child(slot_hbox)

		if processing_item != "":
			var start_btn = Button.new()
			start_btn.text = "▶ Iniciar (%d min)" % (PRESERVES_TYPES[_get_preserve_type(processing_item)].time / 60)
			start_btn.custom_minimum_size = Vector2(0, 50)
			start_btn.theme_override_font_size = 18
			start_btn.pressed.connect(_start_processing.bind(panel))
			vbox.add_child(start_btn)

			var remove_btn = Button.new()
			remove_btn.text = "✕ Remover"
			remove_btn.custom_minimum_size = Vector2(0, 40)
			remove_btn.pressed.connect(_remove_input_item.bind(panel))
			vbox.add_child(remove_btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _select_input_item(panel: Panel) -> void:
	if InventoryManager:
		InventoryManager.open_preserves_jar_mode(self, panel)

func _start_processing(panel: Panel) -> void:
	if not processing_item or not can_process(processing_item):
		return

	if not InventoryManager.remove_item(processing_item, 1):
		return

	is_processing = true
	progress = 0.0

	var ptype = _get_preserve_type(processing_item)
	processing_time = PRESERVES_TYPES[ptype].time
	output_item = _get_output_item(processing_item, ptype)
	output_quality = processing_quality

	emit_signal("processing_started", processing_item)
	_save_state()
	panel.queue_free()
	_open_ui()

func _collect_output(panel: Panel) -> void:
	if not is_processing or progress < 1.0:
		return

	if InventoryManager.add_item(output_item, 1, output_quality):
		is_processing = false
		processing_item = ""
		processing_quality = 0
		progress = 0.0
		output_item = ""
		output_quality = 0

		emit_signal("processing_finished", output_item, output_quality)
		_save_state()

		if ParticleManager:
			ParticleManager.spawn("harvest", global_position + Vector2(16, -16))

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/preserves_jar.ogg", global_position)

		var item = DataLoader.get_item(output_item)
		HUD.show_notification("🫙 Pronto!", "%s (%s)" % [item?.display_name ?? output_item, ["Normal", "Prata", "Ouro", "Irídio"][output_quality]], QUALITY_COLORS[output_quality])

	panel.queue_free()
	_open_ui()
	else:
		HUD.show_message("Inventário cheio!")

func _remove_input_item(panel: Panel) -> void:
	if processing_item and InventoryManager:
		InventoryManager.add_item(processing_item, 1, processing_quality)
	processing_item = ""
	processing_quality = 0
	panel.queue_free()
	_open_ui()

func _calculate_value(item_id: String, quality: int, ptype: String) -> int:
	var item = DataLoader.get_item(item_id)
	if not item:
		return 0

	var base = item.price
	var mult = PRESERVES_TYPES[ptype].base_price_mult
	var add = PRESERVES_TYPES[ptype].base_price_add

	# Multiplicador de qualidade
	var q_mult = [1.0, 1.25, 1.5, 2.0][quality] if quality < 4 else 1.0

	return int((base * mult + add) * q_mult)

const QUALITY_COLORS = {
	0: Color(1.0, 1.0, 1.0),
	1: Color(0.75, 0.75, 0.75),
	2: Color(1.0, 0.85, 0.2),
	3: Color(0.6, 0.3, 1.0)
}

## ==================== PROCESSAMENTO ====================
func _process(delta: float) -> void:
	if is_processing:
		# Delta em minutos de jogo (TimeManager ticka a cada minuto)
		# Precisa converter para tempo real
		if TimeManager:
			progress += (TimeManager.tick_rate * delta) / processing_time
		progress = min(1.0, progress)

func _save_state() -> void:
	if GameManager:
		GameManager.set("preserves_jar_%s" % [name], {
			"processing_item": processing_item,
			"processing_quality": processing_quality,
			"progress": progress,
			"is_processing": is_processing,
			"output_item": output_item,
			"output_quality": output_quality
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get("preserves_jar_%s" % [name], {})
		if data:
			processing_item = data.get("processing_item", "")
			processing_quality = data.get("processing_quality", 0)
			progress = data.get("progress", 0.0)
			is_processing = data.get("is_processing", false)
			output_item = data.get("output_item", "")
			output_quality = data.get("output_quality", 0)