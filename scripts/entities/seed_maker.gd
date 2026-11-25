class_name SeedMaker
extends Node2D

## Seed Maker - transforma colheitas em sementes

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var input_slot: TextureRect = $InputSlot
@onready var output_slot: TextureRect = $OutputSlot

## Estado
var processing_item: String = ""
var processing_amount: int = 0
var progress: float = 0.0
var processing_time: float = 20.0  # segundos
var is_processing: bool = false
var output_item: String = ""
var output_amount: int = 0

## Receitas: item_id -> {output_id, min_amount, max_amount, chance_rare}
const RECIPES = {
	# Vegetais
	"(O)216": {"output": "(O)472", "min": 1, "max": 3, "rare": "(O)472", "rare_chance": 0.01},  # Parsnip
	"(O)218": {"output": "(O)473", "min": 1, "max": 3, "rare": "(O)473", "rare_chance": 0.01},  # Potato
	"(O)220": {"output": "(O)474", "min": 1, "max": 2, "rare": "(O)474", "rare_chance": 0.01},  # Cauliflower
	"(O)222": {"output": "(O)475", "min": 1, "max": 3, "rare": "(O)475", "rare_chance": 0.01},  # Green Bean
	"(O)224": {"output": "(O)476", "min": 1, "max": 3, "rare": "(O)476", "rare_chance": 0.01},  # Kale
	"(O)226": {"output": "(O)477", "min": 1, "max": 3, "rare": "(O)477", "rare_chance": 0.01},  # Rhubarb
	"(O)228": {"output": "(O)478", "min": 1, "max": 2, "rare": "(O)478", "rare_chance": 0.01},  # Melon
	"(O)230": {"output": "(O)479", "min": 1, "max": 3, "rare": "(O)479", "rare_chance": 0.01},  # Tomato
	"(O)232": {"output": "(O)480", "min": 1, "max": 3, "rare": "(O)480", "rare_chance": 0.01},  # Blueberry
	"(O)234": {"output": "(O)481", "min": 1, "max": 3, "rare": "(O)481", "rare_chance": 0.01},  # Hot Pepper
	"(O)236": {"output": "(O)482", "min": 1, "max": 3, "rare": "(O)482", "rare_chance": 0.01},  # Wheat
	"(O)238": {"output": "(O)483", "min": 1, "max": 3, "rare": "(O)483", "rare_chance": 0.01},  # Radish
	"(O)240": {"output": "(O)484", "min": 1, "max": 3, "rare": "(O)484", "rare_chance": 0.01},  # Red Cabbage
	"(O)242": {"output": "(O)485", "min": 1, "max": 3, "rare": "(O)485", "rare_chance": 0.01},  # Starfruit
	"(O)244": {"output": "(O)486", "min": 1, "max": 3, "rare": "(O)486", "rare_chance": 0.01},  # Corn
	"(O)246": {"output": "(O)487", "min": 1, "max": 3, "rare": "(O)487", "rare_chance": 0.01},  # Eggplant
	"(O)248": {"output": "(O)488", "min": 1, "max": 3, "rare": "(O)488", "rare_chance": 0.01},  # Artichoke
	"(O)250": {"output": "(O)489", "min": 1, "max": 3, "rare": "(O)489", "rare_chance": 0.01},  # Pumpkin
	"(O)252": {"output": "(O)490", "min": 1, "max": 3, "rare": "(O)490", "rare_chance": 0.01},  # Bok Choy
	"(O)254": {"output": "(O)491", "min": 1, "max": 3, "rare": "(O)491", "rare_chance": 0.01},  # Yam
	"(O)256": {"output": "(O)492", "min": 1, "max": 3, "rare": "(O)492", "rare_chance": 0.01},  # Cranberry
	"(O)258": {"output": "(O)493", "min": 1, "max": 3, "rare": "(O)493", "rare_chance": 0.01},  # Beet
	"(O)260": {"output": "(O)494", "min": 1, "max": 3, "rare": "(O)494", "rare_chance": 0.01},  # Cranberry (duplicate?)

	# Frutas
	"(O)428": {"output": "(O)495", "min": 1, "max": 2, "rare": "(O)495", "rare_chance": 0.005},  # Apricot
	"(O)430": {"output": "(O)496", "min": 1, "max": 2, "rare": "(O)496", "rare_chance": 0.005},  # Cherry
	"(O)432": {"output": "(O)497", "min": 1, "max": 2, "rare": "(O)497", "rare_chance": 0.005},  # Orange
	"(O)434": {"output": "(O)498", "min": 1, "max": 2, "rare": "(O)498", "rare_chance": 0.005},  # Peach
	"(O)436": {"output": "(O)499", "min": 1, "max": 2, "rare": "(O)499", "rare_chance": 0.005},  # Pomegranate
	"(O)438": {"output": "(O)500", "min": 1, "max": 2, "rare": "(O)500", "rare_chance": 0.005},  # Apple
	"(O)440": {"output": "(O)501", "min": 1, "max": 2, "rare": "(O)501", "rare_chance": 0.005},  # Mango (island)

	# Flores
	"(O)591": {"output": "(O)591", "min": 1, "max": 2, "rare": "", "rare_chance": 0},  # Tulip
	"(O)593": {"output": "(O)593", "min": 1, "max": 2, "rare": "", "rare_chance": 0},  # Jazz
	"(O)595": {"output": "(O)595", "min": 1, "max": 2, "rare": "", "rare_chance": 0},  # Poppy
	"(O)597": {"output": "(O)597", "min": 1, "max": 2, "rare": "", "rare_chance": 0},  # Spangle
	"(O)599": {"output": "(O)599", "min": 1, "max": 2, "rare": "", "rare_chance": 0},  # Sunflower
	"(O)601": {"output": "(O)601", "min": 1, "max": 2, "rare": "", "rare_chance": 0},  # Fairy Rose
	"(O)603": {"output": "(O)603", "min": 1, "max": 2, "rare": "", "rare_chance": 0},  # Blue Jazz

	# Forrageamento
	"(O)16": {"output": "(O)770", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Wild Horseradish -> Spring Seeds
	"(O)18": {"output": "(O)770", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Daffodil
	"(O)20": {"output": "(O)770", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Leek
	"(O)22": {"output": "(O)771", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Dandelion -> Summer Seeds
	"(O)24": {"output": "(O)771", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Sweet Pea
	"(O)26": {"output": "(O)772", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Common Mushroom -> Fall Seeds
	"(O)28": {"output": "(O)772", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Wild Plum
	"(O)30": {"output": "(O)772", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Hazelnut
	"(O)32": {"output": "(O)773", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Winter Root -> Winter Seeds
	"(O)34": {"output": "(O)773", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Crystal Fruit
	"(O)36": {"output": "(O)773", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Snow Yam
	"(O)38": {"output": "(O)773", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Crocus

	# Ancient Seeds (raro)
	"(O)114": {"output": "(O)114", "min": 1, "max": 3, "rare": "", "rare_chance": 0},  # Ancient Fruit
}

## ==================== SINAIS ====================
signal processing_started(item_id: String)
signal processing_finished(item_id: String, amount: int)
signal rare_seed_obtained(item_id: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	progress_bar.visible = false
	input_slot.visible = false
	output_slot.visible = false

	# Carrega estado salvo
	_load_state()

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.show_interaction_prompt("E: Usar Seed Maker", global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	_open_ui()

## ==================== UI ====================
func _open_ui() -> void:
	var panel = Panel.new()
	panel.name = "SeedMakerUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 100
	panel.offset_right = -200
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🌱 Seed Maker"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	if is_processing:
		# Mostra progresso
		var status = Label.new()
		var processing_data = DataLoader.get_item(processing_item)
		status.text = "Processando: %s (%.0f%%)" % [processing_data.display_name if processing_data != null else processing_item, progress * 100]
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.theme_override_font_size = 16
		vbox.add_child(status)

		var bar = ProgressBar.new()
		bar.value = progress * 100
		bar.max_value = 100
		bar.custom_minimum_size = Vector2(300, 20)
		vbox.add_child(bar)

		var time_left = Label.new()
		time_left.text = "Tempo: %.1fs" % (processing_time * (1.0 - progress))
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
		# Slot de entrada
		var input_label = Label.new()
		input_label.text = "Coloque um item para transformar em sementes:"
		input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		input_label.theme_override_font_size = 14
		vbox.add_child(input_label)

		var slot_hbox = HBoxContainer.new()
		slot_hbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_hbox.add_theme_constant_override("separation", 20)

		# Input slot
		var input_btn = Button.new()
		input_btn.custom_minimum_size = Vector2(80, 80)
		if processing_item != "":
			var item = DataLoader.get_item(processing_item)
			if item and item.texture_path != "":
				input_btn.icon = load(item.texture_path)
			input_btn.text = ""
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

		# Output preview
		var output_btn = Button.new()
		output_btn.custom_minimum_size = Vector2(80, 80)
		output_btn.disabled = true
		if processing_item != "" and RECIPES.has(processing_item):
			var recipe = RECIPES[processing_item]
			var out_item = DataLoader.get_item(recipe.output)
			if out_item and out_item.texture_path != "":
				output_btn.icon = load(out_item.texture_path)
			output_btn.tooltip_text = "%s (%d-%d)" % [out_item.display_name if out_item != null else recipe.output, recipe.min, recipe.max]
			if recipe.rare_chance > 0:
				output_btn.tooltip_text += "\nChance rara: %.1f%%" % (recipe.rare_chance * 100)
		slot_hbox.add_child(output_btn)

		vbox.add_child(slot_hbox)

		# Botão iniciar
		if processing_item != "":
			var start_btn = Button.new()
			start_btn.text = "▶ Iniciar Processamento"
			start_btn.custom_minimum_size = Vector2(0, 50)
			start_btn.theme_override_font_size = 18
			start_btn.pressed.connect(_start_processing.bind(panel))
			vbox.add_child(start_btn)

		# Botão remover
		if processing_item != "":
			var remove_btn = Button.new()
			remove_btn.text = "✕ Remover Item"
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
		InventoryManager.open_seed_maker_mode(self, panel)

func _start_processing(panel: Panel) -> void:
	if not processing_item or not RECIPES.has(processing_item):
		return

	if not InventoryManager.remove_item(processing_item, 1):
		return

	is_processing = true
	progress = 0.0
	processing_amount = 1
	processing_time = 20.0

	var recipe = RECIPES[processing_item]
	output_item = recipe.output

	emit_signal("processing_started", processing_item)
	_save_state()
	panel.queue_free()
	_open_ui()

func _collect_output(panel: Panel) -> void:
	if not is_processing or progress < 1.0:
		return

	# Calcula quantidade
	var recipe = RECIPES[processing_item]
	var amount = randi_range(recipe.min, recipe.max)

	# Chance rara
	if recipe.rare_chance > 0 and randf() < recipe.rare_chance:
		if recipe.rare != "":
			output_item = recipe.rare
			emit_signal("rare_seed_obtained", output_item)
			var rare_data = DataLoader.get_item(output_item)
			HUD.show_notification("✨ Semente Rara!", "Você obteve %s!" % (rare_data.display_name if rare_data != null else output_item), Color(1.0, 0.5, 1.0))

	output_amount = amount

	if InventoryManager.add_item(output_item, amount):
		is_processing = false
		processing_item = ""
		processing_amount = 0
		progress = 0.0
		output_item = ""
		output_amount = 0

		emit_signal("processing_finished", output_item, amount)
		_save_state()

		if ParticleManager:
			ParticleManager.spawn("harvest", global_position + Vector2(16, -16))

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/seed_maker.ogg", global_position)

		var output_data = DataLoader.get_item(output_item)
		HUD.show_notification("🌱 Sementes Prontas!", "%s x%d" % [output_data.display_name if output_data != null else output_item, amount], Color(0.5, 1.0, 0.5))

	panel.queue_free()
	_open_ui()
else:
	HUD.show_message("Inventário cheio!")

func _remove_input_item(panel: Panel) -> void:
	if processing_item and InventoryManager:
		InventoryManager.add_item(processing_item, 1)
	processing_item = ""
	panel.queue_free()
	_open_ui()

## ==================== PROCESSAMENTO ====================
func _process(delta: float) -> void:
	if is_processing:
		progress += delta / processing_time
		progress = min(1.0, progress)

		if progress >= 1.0:
			progress = 1.0

func _save_state() -> void:
	if GameManager:
		GameManager.set_data("seed_maker_%s" % [name], {
			"processing_item": processing_item,
			"processing_amount": processing_amount,
			"progress": progress,
			"is_processing": is_processing,
			"output_item": output_item,
			"output_amount": output_amount
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get_data("seed_maker_%s" % [name], {})
		if data:
			processing_item = data.get("processing_item", "")
			processing_amount = data.get("processing_amount", 0)
			progress = data.get("progress", 0.0)
			is_processing = data.get("is_processing", false)
			output_item = data.get("output_item", "")
			output_amount = data.get("output_amount", 0)