class_name FishPond
extends Node2D

## Fish Pond - cria peixes que produzem itens e roe

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var water_surface: TextureRect = $WaterSurface
@onready var fish_container: Node2D = $FishContainer
@onready var input_slot: TextureRect = $InputSlot
@onready var output_slot: TextureRect = $OutputSlot
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var capacity_label: Label = $CapacityLabel

## Estado
var fish_type: String = ""
var fish_data: Dictionary = {}
var current_population: int = 0
var max_population: int = 3
var current_capacity: int = 3
var days_to_reproduce: int = 0
var produce_ready: bool = false
var produce_item: String = ""
var produce_amount: int = 1
var produce_quality: int = 0
var quest_active: bool = false
var quest_type: String = ""
var quest_progress: int = 0
var quest_target: int = 0

## Dados de peixes por tipo
const FISH_POND_DATA = {
	# Peixes comuns
	"(O)152": {  # Sunfish
		"name": "Sunfish",
		"color": Color(1.0, 0.6, 0.2),
		"base_produce": "(O)388",  # Roe
		"rare_produce": "(O)390",  # Aged Roe
		"capacity_quests": [
			{"target": 3, "req": {"item": "(O)16", "count": 1}},   # Wild Horseradish
			{"target": 5, "req": {"item": "(O)18", "count": 1}},   # Daffodil
			{"target": 7, "req": {"item": "(O)20", "count": 1}},   # Leek
			{"target": 10, "req": {"item": "(O)22", "count": 1}}   # Dandelion
		]
	},
	"(O)148": {  # Shad
		"name": "Shad",
		"color": Color(0.5, 0.7, 1.0),
		"base_produce": "(O)388",
		"rare_produce": "(O)390",
		"capacity_quests": [
			{"target": 3, "req": {"item": "(O)24", "count": 1}},   # Sweet Pea
			{"target": 5, "req": {"item": "(O)26", "count": 1}},   # Common Mushroom
			{"target": 7, "req": {"item": "(O)28", "count": 1}},   # Wild Plum
			{"target": 10, "req": {"item": "(O)30", "count": 1}}   # Hazelnut
		]
	},
	"(O)150": {  # Catfish
		"name": "Catfish",
		"color": Color(0.4, 0.3, 0.5),
		"base_produce": "(O)388",
		"rare_produce": "(O)390",
		"capacity_quests": [
			{"target": 3, "req": {"item": "(O)152", "count": 1}},  # Sunfish
			{"target": 5, "req": {"item": "(O)148", "count": 1}},  # Shad
			{"target": 7, "req": {"item": "(O)149", "count": 1}},  # Bream
			{"target": 10, "req": {"item": "(O)151", "count": 1}}  # Salmon
		]
	},
	# Peixes lendários (capacidade 1, sem quests)
	"(O)158": {  # Legend
		"name": "Legend",
		"color": Color(1.0, 0.8, 0.2),
		"base_produce": "(O)390",
		"rare_produce": "(O)749",
		"capacity_quests": [],
		"max_population": 1
	},
	"(O)160": {  # Crimsonfish
		"name": "Crimsonfish",
		"color": Color(1.0, 0.2, 0.2),
		"base_produce": "(O)390",
		"rare_produce": "(O)749",
		"capacity_quests": [],
		"max_population": 1
	},
	"(O)162": {  # Angler
		"name": "Angler",
		"color": Color(1.0, 0.5, 0.0),
		"base_produce": "(O)390",
		"rare_produce": "(O)749",
		"capacity_quests": [],
		"max_population": 1
	},
	"(O)164": {  # Glacierfish
		"name": "Glacierfish",
		"color": Color(0.3, 0.7, 1.0),
		"base_produce": "(O)390",
		"rare_produce": "(O)749",
		"capacity_quests": [],
		"max_population": 1
	},
	"(O)166": {  # Mutant Carp
		"name": "Mutant Carp",
		"color": Color(0.5, 1.0, 0.3),
		"base_produce": "(O)390",
		"rare_produce": "(O)749",
		"capacity_quests": [],
		"max_population": 1
	}
}

## ==================== SINAIS ====================
signal fish_added(fish_id: String)
signal capacity_increased(new_capacity: int)
signal produce_ready(item_id: String, amount: int, quality: int)
signal quest_completed(quest_type: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	progress_bar.visible = false
	input_slot.visible = false
	output_slot.visible = false
	capacity_label.visible = false

	_load_state()

	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		var prompt = "E: Ver Fish Pond"
		if fish_type != "":
			var data = FISH_POND_DATA.get(fish_type, {})
			prompt += " (%s: %d/%d)" % [data.get("name", "Peixe"), current_population, current_capacity]
			if produce_ready:
				prompt += " - Pronto para coletar!"
		HUD.show_interaction_prompt(prompt, global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	_open_ui()

func _open_ui() -> void:
	var panel = Panel.new()
	panel.name = "FishPondUI"
	panel.anchors_preset = 15
	panel.offset_left = 150
	panel.offset_top = 50
	panel.offset_right = -150
	panel.offset_bottom = -50

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	if fish_type != "":
		var data = FISH_POND_DATA.get(fish_type, {})
		title.text = "🐟 Fish Pond - %s" % data.get("name", "Peixe")
		title.add_theme_color_override("font_color", data.get("color", Color.WHITE))
	else:
		title.text = "🐟 Fish Pond (Vazio)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	if fish_type != "":
		var data = FISH_POND_DATA.get(fish_type, {})

		# População
		var pop_hbox = HBoxContainer.new()
		pop_hbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
		pop_hbox.theme_override_constants/separation = 20

		var pop_label = Label.new()
		pop_label.text = "População: %d/%d" % [current_population, current_capacity]
		pop_label.theme_override_font_size = 16
		pop_hbox.add_child(pop_label)

		if current_capacity < 10 and data.capacity_quests:
			var next_quest = data.capacity_quests.find(func(q): return q.target > current_capacity)
			if next_quest:
				var quest_info = Label.new()
				quest_info.text = "Próximo: %d (precisa: %s x%d)" % [next_quest.target, DataLoader.get_item(next_quest.req.item)?.display_name ?? next_quest.req.item, next_quest.req.count]
				quest_info.theme_override_font_size = 12
				quest_info.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
				pop_hbox.add_child(quest_info)

		vbox.add_child(pop_hbox)

		# Produção
		if produce_ready:
			var produce_box = HBoxContainer.new()
			produce_box.alignment = HORIZONTAL_ALIGNMENT_CENTER

			var item = DataLoader.get_item(produce_item)
			var produce_btn = Button.new()
			produce_btn.text = "🎁 Coletar: %s x%d (%s)" % [item?.display_name ?? produce_item, produce_amount, ["Normal", "Prata", "Ouro", "Irídio"][produce_quality]]
			produce_btn.custom_minimum_size = Vector2(300, 50)
			produce_btn.theme_override_font_size = 16
			produce_btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			produce_btn.pressed.connect(_collect_produce)
			produce_box.add_child(produce_btn)
			vbox.add_child(produce_box)
		else:
			var days_left = days_to_reproduce
			if days_left > 0:
				var prod_info = Label.new()
				prod_info.text = "Próxima produção em %d dia(s)" % days_left
				prod_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				prod_info.theme_override_font_size = 13
				prod_info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
				vbox.add_child(prod_info)

		# Capacidade atual
		var cap_label = Label.new()
		cap_label.text = "Capacidade atual: %d" % current_capacity
		cap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap_label.theme_override_font_size = 13
		vbox.add_child(cap_label)

		# Missão de capacidade ativa
		if quest_active:
			var quest_box = HBoxContainer.new()
			quest_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
			quest_box.theme_override_constants/separation = 10

			var quest_label = Label.new()
			quest_label.text = "📋 Missão: Entregar %s x%d (%d/%d)" % [
				DataLoader.get_item(quest_type)?.display_name ?? quest_type,
				quest_target,
				quest_progress,
				quest_target
			]
			quest_label.theme_override_font_size = 13
			quest_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.8))
			quest_box.add_child(quest_label)

			if quest_progress >= quest_target:
				var complete_btn = Button.new()
				complete_btn.text = "✅ Completar Missão"
				complete_btn.custom_minimum_size = Vector2(150, 40)
				complete_btn.theme_override_font_size = 14
				complete_btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
				complete_btn.pressed.connect(_complete_capacity_quest)
				quest_box.add_child(complete_btn)

			vbox.add_child(quest_box)

		# Adicionar peixe se não estiver cheio
		if current_population < current_capacity:
			var add_btn = Button.new()
			add_btn.text = "➕ Adicionar Peixe"
			add_btn.custom_minimum_size = Vector2(0, 40)
			add_btn.theme_override_font_size = 16
			add_btn.pressed.connect(_add_fish_mode)
			vbox.add_child(add_btn)

		# Botão remover peixe
		if current_population > 0:
			var remove_btn = Button.new()
			remove_btn.text = "➖ Remover Peixe"
			remove_btn.custom_minimum_size = Vector2(0, 40)
			remove_btn.theme_override_font_size = 16
			remove_btn.pressed.connect(_remove_fish_mode)
			vbox.add_child(remove_btn)
	else:
		var desc = Label.new()
		desc.text = "Adicione um peixe para começar a criar."
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.autowrap_mode = 1
		desc.theme_override_font_size = 14
		vbox.add_child(desc)

		var add_btn = Button.new()
		add_btn.text = "➕ Adicionar Peixe"
		add_btn.custom_minimum_size = Vector2(0, 50)
		add_btn.theme_override_font_size = 18
		add_btn.pressed.connect(_add_fish_mode)
		vbox.add_child(add_btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _collect_produce() -> void:
	if not produce_ready:
		return

	if InventoryManager.add_item(produce_item, produce_amount, produce_quality):
		produce_ready = false
		produce_item = ""
		produce_amount = 1
		produce_quality = 0
		days_to_reproduce = _get_reproduction_days()

		_save_state()

		if ParticleManager:
			ParticleManager.spawn("harvest", global_position + Vector2(0, -32))

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/fish_pond_collect.ogg", global_position)

		var item = DataLoader.get_item(produce_item)
		HUD.show_notification("🐟 Coleta!", "%s x%d (%s)" % [item?.display_name ?? produce_item, produce_amount, ["Normal", "Prata", "Ouro", "Irídio"][produce_quality]], Color(0.4, 0.8, 1.0))
	else:
		HUD.show_message("Inventário cheio!")

func _add_fish_mode() -> void:
	if InventoryManager:
		InventoryManager.open_fish_pond_mode(self)

func add_fish(fish_id: String) -> bool:
	if fish_type != "" and fish_id != fish_type:
		HUD.show_message("Este viveiro já tem %s!" % FISH_POND_DATA.get(fish_type, {}).get("name", "peixe"))
		return false

	if current_population >= current_capacity:
		HUD.show_message("Viveiro cheio! Complete missões para expandir.")
		return false

	if not FISH_POND_DATA.has(fish_id):
		HUD.show_message("Este peixe não pode ser criado no viveiro!")
		return false

	if InventoryManager.remove_item(fish_id, 1):
		fish_type = fish_id
		current_population = 1
		days_to_reproduce = _get_reproduction_days()

		var data = FISH_POND_DATA.get(fish_id, {})
		max_population = data.get("max_population", 10)

		_save_state()
		_spawn_fish_visual()

		emit_signal("fish_added", fish_id)
		HUD.show_message("%s adicionado ao viveiro!" % FISH_POND_DATA.get(fish_id, {}).get("name", "Peixe"))
		return true
	return false

func _remove_fish_mode() -> void:
	if InventoryManager:
		InventoryManager.open_fish_pond_remove_mode(self)

func remove_fish() -> bool:
	if fish_type == "" or current_population == 0:
		return false

	if InventoryManager.add_item(fish_type, 1):
		current_population -= 1
		if current_population == 0:
			fish_type = ""
			_remove_fish_visual()
		_save_state()
		HUD.show_message("Peixe removido do viveiro.")
		return true
	return false

## ==================== CICLO DIÁRIO ====================
func _on_day_changed(day: int, season: int, year: int) -> void:
	if fish_type == "":
		return

	# Reprodução
	if current_population < current_capacity and current_population > 0:
		days_to_reproduce -= 1
		if days_to_reproduce <= 0:
			_reproduce()

	# Produção de roe
	_produce_roe()

	# Verifica missões de capacidade
	_check_capacity_quests()

	_save_state()

func _get_reproduction_days() -> int:
	var data = FISH_POND_DATA.get(fish_type, {})
	var base_days = data.get("reproduction_days", 2)
	# Mais peixes = reprodução mais rápida
	return max(1, base_days - (current_population / 3))

func _reproduce() -> void:
	if current_population >= current_capacity:
		return

	var new_fish = min(2, current_capacity - current_population)
	current_population += new_fish

	days_to_reproduce = _get_reproduction_days()

	HUD.show_notification("🐟 Reprodução!", "%d %s nasceram!" % [new_fish, FISH_POND_DATA.get(fish_type, {}).get("name", "peixe")], Color(0.4, 1.0, 0.7))

	if ParticleManager:
		ParticleManager.spawn_area("harvest", global_position, new_fish * 3, 48.0)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/fish_reproduce.ogg", global_position)

	_spawn_fish_visual()

func _produce_roe() -> void:
	var data = FISH_POND_DATA.get(fish_type, {})
	if not data:
		return

	# Chance base de produção baseada na população
	var produce_chance = 0.2 * (current_population / current_capacity)
	if randf() < produce_chance:
		var is_rare = randf() < 0.05
		produce_item = is_rare ? data.rare_produce : data.base_produce
		produce_amount = randi_range(1, current_population)
		produce_quality = _calculate_roe_quality()
		produce_ready = true

		# Atualiza visual
		output_slot.visible = true
		var item = DataLoader.get_item(produce_item)
		if item and item.texture_path != "":
			output_slot.texture = load(item.texture_path)

		HUD.show_notification("🐟 Produção Pronta!", "%s disponível!" % (DataLoader.get_item(produce_item)?.display_name ?? produce_item), Color(0.4, 0.8, 1.0))

func _calculate_roe_quality() -> int:
	# Qualidade baseada na população e sorte
	var chance = (current_population / 10.0) * 0.5
	chance += (GameManager.daily_luck + 0.1) * 0.5

	if chance > 0.9: return 3
	elif chance > 0.6: return 2
	elif chance > 0.3: return 1
	return 0

func _check_capacity_quests() -> void:
	var data = FISH_POND_DATA.get(fish_type, {})
	if not data.capacity_quests:
		return

	if current_capacity >= 10:
		return

	if quest_active:
		return

	# Verifica próxima quest
	for quest in data.capacity_quests:
		if quest.target > current_capacity and quest.target <= current_capacity + 1:
			_start_capacity_quest(quest)
			break

func _start_capacity_quest(quest: Dictionary) -> void:
	quest_active = true
	quest_type = quest.req.item
	quest_target = quest.req.count
	quest_progress = 0

	HUD.show_notification("📋 Nova Missão!", "Traga %s x%d para expandir o viveiro!" % [DataLoader.get_item(quest_type)?.display_name ?? quest_type, quest_target], Color(1.0, 0.8, 0.3))

	emit_signal("quest_completed", "capacity_quest_started")

func _complete_capacity_quest() -> void:
	if not quest_active:
		return

	if InventoryManager.get_item_count(quest_type) < quest_target:
		HUD.show_message("Itens insuficientes!")
		return

	if InventoryManager.remove_item(quest_type, quest_target):
		quest_active = false
		current_capacity = current_capacity + 2  # Aumenta capacidade
		if current_capacity > 10:
			current_capacity = 10

		quest_progress = 0
		quest_type = ""
		quest_target = 0

		_save_state()

		HUD.show_notification("🏆 Missão Completa!", "Capacidade do viveiro aumentada para %d!" % current_capacity, Color(0.5, 1.0, 0.5))

		if ParticleManager:
			ParticleManager.show_level_up(global_position, "Capacidade +2!")

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/quest_complete.ogg", global_position)

		emit_signal("capacity_increased", current_capacity)

## ==================== VISUAL ====================
func _spawn_fish_visual() -> void:
	if not fish_container:
		return

	for child in fish_container.get_children():
		child.queue_free()

	var data = FISH_POND_DATA.get(fish_type, {})
	var color = data.get("color", Color(0.5, 0.7, 1.0))

	for i in range(current_population):
		var fish = _create_fish_visual(color)
		fish_container.add_child(fish)

		# Posiciona aleatoriamente
		fish.global_position = fish_container.global_position + Vector2(randf_range(-150, 150), randf_range(-80, 80))

		# AI de natação
		_setup_fish_ai(fish)

func _create_fish_visual(color: Color) -> Area2D:
	var fish = Area2D.new()
	fish.name = "PondFish"

	var sprite = Sprite2D.new()
	var img = Image.create(32, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(4, 28):
		for y in range(4, 12):
			var dx = (x - 16) / 12
			var dy = (y - 8) / 4
			if dx*dx + dy*dy < 1:
				img.set_pixel(x, y, color)
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(16, 8)
	fish.add_child(sprite)

	var col = CollisionShape2D.new()
	col.shape = RectangleShape2D.new()
	(col.shape as RectangleShape2D).size = Vector2(28, 12)
	fish.add_child(col)

	return fish

func _setup_fish_ai(fish: Area2D) -> void:
	var timer = Timer.new()
	timer.wait_time = randf_range(2.0, 5.0)
	timer.one_shot = false
	timer.timeout.connect(_fish_swim.bind(fish))
	fish.add_child(timer)
	timer.start()

func _fish_swim(fish: Area2D) -> void:
	if not fish.is_inside_tree():
		return

	var angle = randf() * TAU
	var distance = randf_range(30, 80)
	var target = fish.global_position + Vector2(cos(angle), sin(angle)) * distance

	var tween = fish.create_tween()
	tween.tween_property(fish, "global_position", target, randf_range(2.0, 4.0)).set_trans(Tween.TRANS_SINE)

func _remove_fish_visual() -> void:
	if fish_container:
		for child in fish_container.get_children():
			child.queue_free()

## ==================== PERSISTÊNCIA ====================
func _save_state() -> void:
	if GameManager:
		GameManager.set("fish_pond_%s" % [name], {
			"fish_type": fish_type,
			"current_population": current_population,
			"current_capacity": current_capacity,
			"max_population": max_population,
			"days_to_reproduce": days_to_reproduce,
			"produce_ready": produce_ready,
			"produce_item": produce_item,
			"produce_amount": produce_amount,
			"produce_quality": produce_quality,
			"quest_active": quest_active,
			"quest_type": quest_type,
			"quest_progress": quest_progress,
			"quest_target": quest_target
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get("fish_pond_%s" % [name], {})
		if data:
			fish_type = data.get("fish_type", "")
			current_population = data.get("current_population", 0)
			current_capacity = data.get("current_capacity", 3)
			max_population = data.get("max_population", 10)
			days_to_reproduce = data.get("days_to_reproduce", 0)
			produce_ready = data.get("produce_ready", false)
			produce_item = data.get("produce_item", "")
			produce_amount = data.get("produce_amount", 1)
			produce_quality = data.get("produce_quality", 0)
			quest_active = data.get("quest_active", false)
			quest_type = data.get("quest_type", "")
			quest_progress = data.get("quest_progress", 0)
			quest_target = data.get("quest_target", 0)

			if fish_type != "":
				_spawn_fish_visual()