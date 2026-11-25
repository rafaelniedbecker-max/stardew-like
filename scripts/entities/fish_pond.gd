class_name FishPond
extends Node2D

## Fish Pond - cria peixes, produz roe, itens raros

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var fish_container: Node2D = $FishContainer
@onready var output_bin: Area2D = $OutputBin
@onready var progress_bar: ProgressBar = $ProgressBar

## Estado
var fish_type: String = ""           # Tipo de peixe populando o tanque
var fish_count: int = 0              # Quantidade atual
var max_fish: int = 3                # Capacidade base (expansível para 10)
var happiness: int = 0               # 0-100
var days_since_fed: int = 0
var has_quest: bool = false
var quest_type: String = ""
var quest_progress: int = 0
var quest_target: int = 0
var output_item: String = ""
var output_ready: bool = false
var output_quality: int = 0

## Configurações por peixe
const FISH_CONFIG = {
	# Peixes comuns
	"(O)152": {"name": "Sunfish", "color": Color(1.0, 0.6, 0.2), "base_produce": "(O)380", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)16", "quest_count": 5},
	"(O)148": {"name": "Shad", "color": Color(0.5, 0.7, 1.0), "base_produce": "(O)388", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)18", "quest_count": 3},
	"(O)150": {"name": "Catfish", "color": Color(0.4, 0.3, 0.5), "base_produce": "(O)390", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)20", "quest_count": 2},
	"(O)152": {"name": "Carp", "color": Color(0.6, 0.4, 0.2), "base_produce": "(O)388", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)22", "quest_count": 4},

	# Peixes de rio/lago
	"(O)153": {"name": "Tiger Trout", "color": Color(1.0, 0.7, 0.2), "base_produce": "(O)388", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)24", "quest_count": 2},
	"(O)151": {"name": "Salmon", "color": Color(1.0, 0.5, 0.3), "base_produce": "(O)390", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)26", "quest_count": 3},
	"(O)154": {"name": "Lingcod", "color": Color(0.4, 0.4, 0.6), "base_produce": "(O)388", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)28", "quest_count": 2},
	"(O)155": {"name": "Sturgeon", "color": Color(0.5, 0.5, 0.5), "base_produce": "(O)440", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)30", "quest_count": 1},  # Caviar!

	# Peixes de mar
	"(O)156": {"name": "Tuna", "color": Color(0.3, 0.5, 0.8), "base_produce": "(O)390", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)32", "quest_count": 2},
	"(O)157": {"name": "Sardine", "color": Color(0.7, 0.7, 0.7), "base_produce": "(O)380", "rare_produce": "(O)749", "capacity": 10, "quest_item": "(O)34", "quest_count": 10},
	"(O)158": {"name": "Red Snapper", "color": Color(1.0, 0.4, 0.4), "base_produce": "(O)390", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)36", "quest_count": 2},
	"(O)159": {"name": "Tilapia", "color": Color(0.4, 0.7, 0.4), "base_produce": "(O)388", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)38", "quest_count": 2},

	# Peixes lendários (capacidade 1, produzem itens únicos)
	"(O)160": {"name": "Legend", "color": Color(1.0, 0.9, 0.2), "base_produce": "(O)749", "rare_produce": "(O)749", "capacity": 1, "quest_item": "", "quest_count": 0},
	"(O)162": {"name": "Crimsonfish", "color": Color(1.0, 0.2, 0.3), "base_produce": "(O)749", "rare_produce": "(O)749", "capacity": 1, "quest_item": "", "quest_count": 0},
	"(O)164": {"name": "Angler", "color": Color(1.0, 0.6, 0.1), "base_produce": "(O)749", "rare_produce": "(O)749", "capacity": 1, "quest_item": "", "quest_count": 0},
	"(O)166": {"name": "Glacierfish", "color": Color(0.3, 0.7, 1.0), "base_produce": "(O)749", "rare_produce": "(O)749", "capacity": 1, "quest_item": "", "quest_count": 0},
	"(O)168": {"name": "Mutant Carp", "color": Color(0.5, 0.2, 0.5), "base_produce": "(O)749", "rare_produce": "(O)749", "capacity": 1, "quest_item": "", "quest_count": 0},

	# Outros
	"(O)149": {"name": "Bream", "color": Color(0.5, 0.7, 0.3), "base_produce": "(O)388", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)16", "quest_count": 3},
	"(O)155": {"name": "Eel", "color": Color(0.2, 0.2, 0.4), "base_produce": "(O)390", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)18", "quest_count": 2},
	"(O)146": {"name": "Pufferfish", "color": Color(1.0, 0.8, 0.3), "base_produce": "(O)388", "rare_produce": "(O)749", "capacity": 3, "quest_item": "(O)20", "quest_count": 1},
	"(O)147": {"name": "Anchovy", "color": Color(0.6, 0.6, 0.6), "base_produce": "(O)380", "rare_produce": "(O)749", "capacity": 10, "quest_item": "(O)22", "quest_count": 5},
}

## ==================== SINAIS ====================
signal fish_added(fish_type: String)
signal produce_ready(item_id: String, quality: int)
signal quest_completed(quest_type: String)
signal capacity_increased(new_capacity: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	output_bin.monitorable = true
	output_bin.monitoring = true
	output_bin.area_entered.connect(_on_output_entered)

	progress_bar.visible = false

	_load_state()
	_spawn_fish_visuals()

	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		var prompt = "E: Ver Tanque (%d/%d)" % [fish_count, max_fish]
		if output_ready:
			prompt += " | Pronto para coletar!"
		HUD.show_interaction_prompt(prompt, global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func _on_output_entered(area: Area2D) -> void:
	if area.is_in_group("player") and output_ready:
		var output_data = DataLoader.get_item(output_item)
		HUD.show_interaction_prompt("E: Coletar %s" % (output_data.display_name if output_data != null else output_item), output_bin.global_position + Vector2(0, -30))

func interact() -> void:
	_open_ui()

## ==================== UI ====================
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
	title.text = "🐟 Tanque de Peixes"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	if fish_type == "":
		# Tanque vazio
		var empty = Label.new()
		empty.text = "Tanque vazio. Coloque um peixe para começar!"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = 1
		empty.theme_override_font_size = 16
		vbox.add_child(empty)

		var add_btn = Button.new()
		add_btn.text = "Adicionar Peixe"
		add_btn.custom_minimum_size = Vector2(0, 50)
		add_btn.theme_override_font_size = 18
		add_btn.pressed.connect(_add_fish_ui.bind(panel))
		vbox.add_child(add_btn)

		var close_btn = Button.new()
		close_btn.text = "Fechar"
		close_btn.custom_minimum_size = Vector2(0, 40)
		close_btn.pressed.connect(panel.queue_free.bind())
		vbox.add_child(close_btn)
	else:
		# Tanque com peixes
		var config = FISH_CONFIG.get(fish_type, {})

		# Info do peixe
		var info_hbox = HBoxContainer.new()
		info_hbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
		info_hbox.add_theme_constant_override("separation", 20)

		var fish_info = Label.new()
		fish_info.text = "%s: %d/%d" % [config.get("name", "Peixe"), fish_count, max_fish]
		fish_info.theme_override_font_size = 18
		fish_info.add_theme_color_override("font_color", config.get("color", Color.WHITE))
		info_hbox.add_child(fish_info)

		var happy_info = Label.new()
		happy_info.text = "Felicidade: %d%%" % happiness
		happy_info.theme_override_font_size = 16
		happy_info.add_theme_color_override("font_color", Color(1.0, 0.5, 0.7))
		info_hbox.add_child(happy_info)

		vbox.add_child(info_hbox)

		# Peixes visuais
		var fish_label = Label.new()
		fish_label.text = "Peixes no Tanque:"
		fish_label.theme_override_font_size = 16
		vbox.add_child(fish_label)

		var scroll = ScrollContainer.new()
		var grid = GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		scroll.add_child(grid)
		scroll.custom_minimum_size = Vector2(0, 150)
		vbox.add_child(scroll)

		for i in range(fish_count):
			var btn = _create_fish_button(config)
			grid.add_child(btn)

		# Produção
		var produce_box = HBoxContainer.new()
		produce_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
		produce_box.add_theme_constant_override("separation", 20)

		var produce_title = Label.new()
		produce_title.text = "🥚 Produção:"
		produce_title.theme_override_font_size = 16
		vbox.add_child(produce_title)

		if output_ready:
			var item = DataLoader.get_item(output_item)
			var collect_btn = Button.new()
			collect_btn.text = "Coletar: %s (%s)" % [item.display_name if item != null else output_item, ["Normal", "Prata", "Ouro", "Irídio"][output_quality]]
			collect_btn.custom_minimum_size = Vector2(250, 50)
			collect_btn.theme_override_font_size = 16
			collect_btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			collect_btn.pressed.connect(_collect_output.bind(panel))
			produce_box.add_child(collect_btn)
		else:
			var produce_info = Label.new()
			var days_left = 7 - days_since_fed
			produce_info.text = "Próxima produção em %d dias" % max(0, days_left)
			produce_info.theme_override_font_size = 14
			produce_info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			produce_box.add_child(produce_info)

		vbox.add_child(produce_box)

		# Quest
		if has_quest:
			var quest = Label.new()
			var quest_data = DataLoader.get_item(quest_type)
			quest.text = "📋 Missão: Traga %d %s" % [quest_target, quest_data.display_name if quest_data != null else quest_type]
			quest.theme_override_font_size = 14
			quest.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
			quest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(quest)

			var progress = Label.new()
			progress.text = "Progresso: %d/%d" % [quest_progress, quest_target]
			progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			progress.theme_override_font_size = 13
			vbox.add_child(progress)
		else:
			# Botão para adicionar mais peixes (se não cheio)
			if fish_count < max_fish:
				var add_more = Button.new()
				add_more.text = "➕ Adicionar mais %s" % config.get("name", "peixe")
				add_more.custom_minimum_size = Vector2(0, 45)
				add_more.theme_override_font_size = 16
				add_more.pressed.connect(_add_fish_ui.bind(panel))
				vbox.add_child(add_more)

			# Botão expandir capacidade (se completou quest)
			if max_fish < 10:
				var expand = Button.new()
				expand.text = "🔧 Expandir Tanque (Complete missões)"
				expand.custom_minimum_size = Vector2(0, 40)
				expand.disabled = true
				expand.theme_override_font_size = 14
				vbox.add_child(expand)

		var close_btn = Button.new()
		close_btn.text = "Fechar"
		close_btn.custom_minimum_size = Vector2(0, 40)
		close_btn.pressed.connect(panel.queue_free.bind())
		vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _create_fish_button(config: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(60, 60)
	btn.flat = true

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	btn.add_child(vbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	var img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var color = config.get("color", Color.WHITE)
	for x in range(10, 30):
		for y in range(10, 30):
			var dx = (x - 20) / 10
			var dy = (y - 20) / 10
			if dx*dx + dy*dy < 1:
				img.set_pixel(x, y, color)
	var tex = ImageTexture.create_from_image(img)
	icon.texture = tex
	vbox.add_child(icon)

	return btn

func _add_fish_ui(panel: Panel) -> void:
	if InventoryManager:
		InventoryManager.open_fish_pond_mode(self, panel)

func add_fish(fish_id: String) -> bool:
	if fish_type != "" and fish_id != fish_type:
		HUD.show_message("Este tanque já tem %s!" % FISH_CONFIG.get(fish_type, {}).get("name", "outro peixe"))
		return false

	if fish_count >= max_fish:
		HUD.show_message("Tanque cheio! Complete missões para expandir.")
		return false

	if not InventoryManager.remove_item(fish_id, 1):
		return false

	# Primeira vez
	if fish_type == "":
		fish_type = fish_id
		fish_count = 1
		happiness = 50
		max_fish = FISH_CONFIG.get(fish_id, {}).get("capacity", 3)
		_generate_quest()
	else:
		fish_count += 1
		happiness = min(100, happiness + 10)

	_save_state()
	_spawn_fish_visuals()

	if ParticleManager:
		ParticleManager.spawn("water", global_position + Vector2(0, -32))

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/fish_add.ogg", global_position)

	HUD.show_message("%s adicionado ao tanque!" % FISH_CONFIG.get(fish_id, {}).get("name", "Peixe"))
	emit_signal("fish_added", fish_id)
	return true

func _generate_quest() -> void:
	var config = FISH_CONFIG.get(fish_type, {})
	var quest_item = config.get("quest_item", "")
	var quest_count = config.get("quest_count", 0)

	if quest_item != "" and quest_count > 0:
		has_quest = true
		quest_type = quest_item
		quest_target = quest_count
		quest_progress = 0
		_save_state()

func complete_quest_item(item_id: String, amount: int) -> void:
	if not has_quest or item_id != quest_type:
		return

	quest_progress = min(quest_target, quest_progress + amount)

	if quest_progress >= quest_target:
		_complete_quest()

	_save_state()

func _complete_quest() -> void:
	has_quest = false
	quest_type = ""
	quest_progress = 0
	quest_target = 0

	# Recompensa: expande capacidade
	if max_fish < 10:
		max_fish += 1
		emit_signal("capacity_increased", max_fish)
		HUD.show_notification("🎉 Missão Completa!", "Capacidade do tanque aumentada para %d!" % max_fish, Color(1.0, 0.9, 0.3))

		# Nova quest se ainda não no máximo
		if max_fish < 10:
			_generate_quest()
	else:
		# Tanque no máximo - recompensa especial
		HUD.show_notification("🏆 Tanque Máximo!", "Seu tanque está no nível máximo!", Color(1.0, 0.9, 0.3))

	_save_state()

func _collect_output(panel: Panel) -> void:
	if not output_ready:
		return

	if InventoryManager.add_item(output_item, 1, output_quality):
		output_ready = false
		output_item = ""
		output_quality = 0
		days_since_fed = 0

		_save_state()

		if ParticleManager:
			ParticleManager.spawn("harvest", output_bin.global_position)

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/fish_pond_collect.ogg", global_position)

		var item = DataLoader.get_item(output_item)
		var q_names = ["Normal", "Prata", "Ouro", "Irídio"]
		HUD.show_notification("🐟 Coletado!", "%s (%s)" % [item.display_name if item != null else output_item, q_names[output_quality]], Color(0.5, 1.0, 0.5))

		panel.queue_free()
		_open_ui()
	else:
		HUD.show_message("Inventário cheio!")

## ==================== CICLO DIÁRIO ====================
func _on_day_changed(day: int, season: int, year: int) -> void:
	if fish_type == "":
		return

	days_since_fed += 1

	# Felicidade diminui se não alimentado
	if days_since_fed > 2:
		happiness = max(0, happiness - 10)
	else:
		happiness = min(100, happiness + 5)

	# Produz item a cada X dias (baseado na felicidade)
	var produce_interval = max(1, 7 - (happiness / 20))
	if days_since_fed >= produce_interval:
		_produce_item()

	# Atualiza quest progress se tiver item no inventário
	if has_quest:
		var current = InventoryManager.get_item_count(quest_type)
		if current > 0:
			# Verifica se aumentou desde ontem (simplificado)
			pass

	_save_state()
	_update_visuals()

func _produce_item() -> void:
	if output_ready:
		return  # Não acumula

	var config = FISH_CONFIG.get(fish_type, {})
	var base = config.get("base_produce", "(O)380")
	var rare = config.get("rare_produce", "(O)749")

	# Chance de item raro baseada na felicidade
	var rare_chance = (happiness / 100.0) * 0.05  # Até 5%
	if randf() < rare_chance:
		output_item = rare
	else:
		output_item = base

	# Qualidade baseada na felicidade
	output_quality = _calculate_quality()
	output_ready = true
	days_since_fed = 0

	# Notificação
	if ParticleManager:
		ParticleManager.spawn("harvest", output_bin.global_position)

	var output_data = DataLoader.get_item(output_item)
	HUD.show_notification("🥚 Pronto!", "O tanque produziu %s" % (output_data.display_name if output_data != null else output_item), Color(1.0, 0.7, 0.3))

	emit_signal("produce_ready", output_item, output_quality)

func _calculate_quality() -> int:
	var chance = happiness / 100.0
	if chance > 0.9: return 3
	elif chance > 0.7: return 2
	elif chance > 0.4: return 1
	return 0

## ==================== ALIMENTAÇÃO ====================
func feed_fish(item_id: String) -> bool:
	# Peixes comem itens específicos (algas, insetos, etc.)
	var valid_food = ["(O)16", "(O)18", "(O)20", "(O)22", "(O)24", "(O)26", "(O)28", "(O)30", "(O)32", "(O)34", "(O)36", "(O)38"]
	if item_id not in valid_food:
		HUD.show_message("Peixes não comem isso!")
		return false

	if not InventoryManager.remove_item(item_id, 1):
		return false

	days_since_fed = 0
	happiness = min(100, happiness + 15)

	_save_state()
	HUD.show_message("Peixes alimentados! Felicidade: %d%%" % happiness)

	if ParticleManager:
		ParticleManager.spawn_area("seed", global_position, 8, 24.0)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/fish_eat.ogg", global_position)

	return true

## ==================== VISUAL ====================
func _spawn_fish_visuals() -> void:
	if not fish_container:
		return

	for child in fish_container.get_children():
		child.queue_free()

	if fish_type == "":
		return

	var config = FISH_CONFIG.get(fish_type, {})
	var color = config.get("color", Color.WHITE)

	for i in range(fish_count):
		var fish = Area2D.new()
		fish.name = "Fish_%d" % i
		fish.monitorable = true
		fish.monitoring = true
		fish.collision_layer = 4
		fish.collision_mask = 1

		var sprite = Sprite2D.new()
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for x in range(8, 24):
			for y in range(8, 24):
				var dx = (x - 16) / 8
				var dy = (y - 16) / 8
				if dx*dx + dy*dy < 1:
					img.set_pixel(x, y, color)
		var tex = ImageTexture.create_from_image(img)
		sprite.texture = tex
		sprite.offset = Vector2(16, 16)
		fish.add_child(sprite)

		var col = CollisionShape2D.new()
		col.shape = CircleShape2D.new()
		(col.shape as CircleShape2D).radius = 12
		fish.add_child(col)

		# Posição aleatória
		fish.global_position = fish_container.global_position + Vector2(randf_range(-150, 150), randf_range(-80, 80))
		fish_container.add_child(fish)

		# AI nadar
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
	tween.tween_property(fish, "global_position", target, 3.0).set_trans(Tween.TRANS_SINE)

func _update_visuals() -> void:
	# Atualiza barra de progresso se UI aberta
	var ui = get_tree().root.get_child(0).get_node_or_null("FishPondUI")
	if ui:
		# Reabre para atualizar
		pass

## ==================== PERSISTÊNCIA ====================
func _save_state() -> void:
	if GameManager:
		GameManager.set_data("fish_pond_%s" % [name], {
			"fish_type": fish_type,
			"fish_count": fish_count,
			"max_fish": max_fish,
			"happiness": happiness,
			"days_since_fed": days_since_fed,
			"has_quest": has_quest,
			"quest_type": quest_type,
			"quest_progress": quest_progress,
			"quest_target": quest_target,
			"output_item": output_item,
			"output_ready": output_ready,
			"output_quality": output_quality
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get_data("fish_pond_%s" % [name], {})
		if data:
			fish_type = data.get("fish_type", "")
			fish_count = data.get("fish_count", 0)
			max_fish = data.get("max_fish", 3)
			happiness = data.get("happiness", 50)
			days_since_fed = data.get("days_since_fed", 0)
			has_quest = data.get("has_quest", false)
			quest_type = data.get("quest_type", "")
			quest_progress = data.get("quest_progress", 0)
			quest_target = data.get("quest_target", 0)
			output_item = data.get("output_item", "")
			output_ready = data.get("output_ready", false)
			output_quality = data.get("output_quality", 0)

			if fish_type != "":
				_spawn_fish_visuals()