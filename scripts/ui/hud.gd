extends CanvasLayer

## HUD principal: hora, energia, ouro, hotbar, tooltips

@onready var time_label: Label = $TopBar/TimeLabel
@onready var season_icon: TextureRect = $TopBar/SeasonIcon
@onready var date_label: Label = $TopBar/DateLabel
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var energy_bar: ProgressBar = $TopBar/EnergyBar
@onready var energy_label: Label = $TopBar/EnergyLabel
@onready var health_bar: ProgressBar = $TopBar/HealthBar
@onready var hotbar_container: HBoxContainer = $Hotbar/HotbarContainer
@onready var tool_tooltip: Label = $ToolTooltip
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var weather_icon: TextureRect = $TopBar/WeatherIcon
@onready var quest_tracker: VBoxContainer = $QuestTracker
@onready var notification_container: VBoxContainer = $NotificationContainer

## Referências aos slots do hotbar
var hotbar_slots: Array[Control] = []

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_setup_hotbar_slots()
	_connect_signals()
	_update_all()

func _setup_hotbar_slots() -> void:
	for i in range(12):
		var slot = hotbar_container.get_child(i) if i < hotbar_container.get_child_count() else null
		if slot:
			hotbar_slots.append(slot)
		else:
			# Cria slot dinamicamente
			slot = _create_hotbar_slot(i)
			hotbar_container.add_child(slot)
			hotbar_slots.append(slot)

func _create_hotbar_slot(index: int) -> Control:
	var slot = HBoxContainer.new()
	slot.name = "Slot_%d" % index
	slot.add_theme_constant_override("separation", 4)

	var bg = Panel.new()
	bg.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	bg.custom_minimum_size = Vector2(52, 52)

	var item_icon = TextureRect.new()
	item_icon.name = "Icon"
	item_icon.custom_minimum_size = Vector2(40, 40)
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var amount_label = Label.new()
	amount_label.name = "Amount"
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	amount_label.add_theme_font_size_override("font_size", 14)
	amount_label.add_theme_color_override("font_color", Color.WHITE)
	amount_label.add_theme_color_override("font_outline_color", Color.BLACK)
	amount_label.add_theme_constant_override("outline_size", 2)

	var selection = TextureRect.new()
	selection.name = "Selection"
	selection.custom_minimum_size = Vector2(52, 52)
	selection.visible = false

	var number_label = Label.new()
	number_label.name = "Number"
	number_label.text = str((index + 1) % 10)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	number_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	number_label.add_theme_font_size_override("font_size", 12)
	number_label.add_theme_color_override("font_color", Color.WHITE)

	bg.add_child(item_icon)
	bg.add_child(amount_label)
	bg.add_child(selection)
	bg.add_child(number_label)
	slot.add_child(bg)

	return slot

func _connect_signals() -> void:
	if GameManager:
		GameManager.gold_changed.connect(_on_gold_changed)
		GameManager.energy_changed.connect(_on_energy_changed)
		GameManager.health_changed.connect(_on_health_changed)
		GameManager.time_changed.connect(_on_time_changed)
		GameManager.day_changed.connect(_on_day_changed)
		GameManager.skill_level_up.connect(_on_skill_level_up)
		GameManager.quest_added.connect(_on_quest_added)
		GameManager.quest_completed.connect(_on_quest_completed)

	if InventoryManager:
		InventoryManager.inventory_changed.connect(_update_hotbar)
		InventoryManager.hotbar_changed.connect(_on_hotbar_slot_changed)

	if TimeManager:
		TimeManager.hour_changed.connect(_on_hour_changed)

	if QuestManager:
		QuestManager.quest_updated.connect(_update_quest_tracker)

	# Limpa tracker no início
	_clear_quest_tracker()

func _update_all() -> void:
	_update_time()
	_update_gold()
	_update_energy()
	_update_health()
	_update_hotbar()
	_update_season()
	_update_weather()

## ==================== ATUALIZAÇÕES ====================
func _on_time_changed(new_time: int) -> void:
	_update_time()

func _on_hour_changed(hour: int) -> void:
	_update_time()

func _on_day_changed(day: int, season: int, year: int) -> void:
	_update_date()
	_update_season()

func _on_gold_changed(gold: int) -> void:
	_update_gold()

func _on_energy_changed(energy: float) -> void:
	_update_energy()

func _on_health_changed(health: float) -> void:
	_update_health()

func _on_hotbar_slot_changed(slot: int, item_id: String) -> void:
	_update_hotbar_slot(slot, item_id)

func _update_time() -> void:
	if TimeManager:
		time_label.text = TimeManager.time_to_string(GameManager.current_time)
	else:
		time_label.text = TimeManager.time_to_string(GameManager.current_time)

	# Atualiza cor baseada na hora
	var progress = TimeManager.get_day_progress(GameManager.current_time)
	if progress > 0.8:
		time_label.add_theme_color_override("font_color", Color.RED)
	elif progress > 0.6:
		time_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		time_label.add_theme_color_override("font_color", Color.WHITE)

func _update_date() -> void:
	date_label.text = GameManager.get_date_string()

func _update_season() -> void:
	var season_names = ["Spring", "Summer", "Fall", "Winter"]
	var season_icons = ["res://resources/sprites/ui/spring.png",
						"res://resources/sprites/ui/summer.png",
						"res://resources/sprites/ui/fall.png",
						"res://resources/sprites/ui/winter.png"]

	date_label.text = GameManager.get_date_string()

	if season_icon and GameManager.current_season < season_icons.size():
		var tex = load(season_icons[GameManager.current_season])
		if tex:
			season_icon.texture = tex

func _update_weather() -> void:
	var weather_icons = {
		0: "res://resources/sprites/ui/sunny.png",
		1: "res://resources/sprites/ui/rainy.png",
		2: "res://resources/sprites/ui/storm.png",
		3: "res://resources/sprites/ui/snow.png",
		4: "res://resources/sprites/ui/green_rain.png"
	}

	var icon_path = weather_icons.get(GameManager.today_weather)
	if icon_path and weather_icon:
		var tex = load(icon_path)
		if tex:
			weather_icon.texture = tex
			weather_icon.visible = true
		else:
			weather_icon.visible = false
	else:
		weather_icon.visible = false

func _update_gold() -> void:
	gold_label.text = "%dg" % GameManager.gold

func _update_energy() -> void:
	energy_bar.max_value = GameManager.max_energy
	energy_bar.value = GameManager.energy
	energy_label.text = "%.0f / %.0f" % [GameManager.energy, GameManager.max_energy]

	# Cor da barra baseada na energia
	if GameManager.energy / GameManager.max_energy < 0.2:
		energy_bar.add_theme_color_override("fill_color", Color.RED)
	elif GameManager.energy / GameManager.max_energy < 0.5:
		energy_bar.add_theme_color_override("fill_color", Color.YELLOW)
	else:
		energy_bar.add_theme_color_override("fill_color", Color.GREEN)

func _update_health() -> void:
	health_bar.max_value = GameManager.max_health
	health_bar.value = GameManager.health

func _update_hotbar() -> void:
	for i in range(12):
		var item_id = InventoryManager.get_hotbar_item(i)
		_update_hotbar_slot(i, item_id)

	# Atualiza seleção
	for i in range(12):
		var slot = hotbar_slots[i]
		if slot:
			var selection = slot.get_node_or_null("Panel/Selection")
			if selection:
				selection.visible = (i == GameManager.selected_hotbar_slot)

func _update_hotbar_slot(slot_index: int, item_id: String) -> void:
	if slot_index >= hotbar_slots.size():
		return

	var slot = hotbar_slots[slot_index]
	var panel = slot.get_node_or_null("Panel")
	if not panel:
		return

	var icon = panel.get_node_or_null("Icon")
	var amount = panel.get_node_or_null("Amount")

	if item_id == "":
		if icon:
			icon.texture = null
		if amount:
			amount.text = ""
		return

	var item = DataLoader.get_item(item_id)
	if item:
		if icon:
			# TODO: Carregar textura real do item
			# icon.texture = load(item.custom_texture) se tiver
			pass
		if amount:
			var count = InventoryManager.get_item_count(item_id)
			if count > 1:
				amount.text = str(count)
			else:
				amount.text = ""

## ==================== TOOLTIPS & PROMPTS ====================
func show_tool_tooltip(text: String, position: Vector2) -> void:
	tool_tooltip.text = text
	tool_tooltip.global_position = position
	tool_tooltip.visible = true

func hide_tool_tooltip() -> void:
	tool_tooltip.visible = false

func show_interaction_prompt(text: String, position: Vector2) -> void:
	interaction_prompt.text = text
	interaction_prompt.global_position = position
	interaction_prompt.visible = true

func hide_interaction_prompt() -> void:
	interaction_prompt.visible = false

## ==================== ANIMAÇÕES ====================
func animate_gold_change(amount: int) -> void:
	# Animação de ouro ganho/gasto
	var tween = create_tween()
	tween.tween_property(gold_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(gold_label, "scale", Vector2(1.0, 1.0), 0.1)

	if amount > 0:
		gold_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		gold_label.add_theme_color_override("font_color", Color.RED)

	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(func(): gold_label.add_theme_color_override("font_color", Color.WHITE))
	add_child(timer)
	timer.start()

func animate_energy_flash() -> void:
	# Pisca barra de energia quando baixa
	var tween = create_tween()
	tween.tween_property(energy_bar, "modulate", Color.RED, 0.1)
	tween.tween_property(energy_bar, "modulate", Color.WHITE, 0.1)
	tween.set_loops(3)

## ==================== QUEST TRACKER ====================
func _update_quest_tracker() -> void:
	if not quest_tracker or not QuestManager:
		return

	_clear_quest_tracker()

	var active_quests = QuestManager.get_active_quests()
	for i in range(active_quests.size()):
		var quest = active_quests[i]
		if i >= 3:  # Máximo 3 quests rastreadas
			break

		var quest_entry = _create_quest_entry(quest)
		quest_tracker.add_child(quest_entry)

func _create_quest_entry(quest: Dictionary) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 5)

	# Ícone da quest
	var icon = Label.new()
	icon.text = "📋"
	icon.custom_minimum_size = Vector2(30, 30)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.theme_override_font_size = 20
	hbox.add_child(icon)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var title = Label.new()
	title.text = quest.get("title", "Missão")
	title.theme_override_font_size = 14
	title.autowrap_mode = 1
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = quest.get("description", "")
	desc.theme_override_font_size = 12
	desc.autowrap_mode = 1
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc)

	# Progresso se houver
	var progress = quest.get("progress", 0)
	var target = quest.get("target", 1)
	if target > 0:
		var progress_bar = ProgressBar.new()
		progress_bar.max_value = target
		progress_bar.value = progress
		progress_bar.custom_minimum_size = Vector2(200, 10)
		vbox.add_child(progress_bar)

		var progress_label = Label.new()
		progress_label.text = "%d/%d" % [progress, target]
		progress_label.theme_override_font_size = 10
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vbox.add_child(progress_label)

	hbox.add_child(vbox)
	return hbox

func _clear_quest_tracker() -> void:
	if quest_tracker:
		for child in quest_tracker.get_children():
			child.queue_free()

func _on_quest_added(quest_id: String) -> void:
	_update_quest_tracker()

func _on_quest_completed(quest_id: String) -> void:
	_update_quest_tracker()
	show_notification("✅ Missão Concluída!", "Quest completed: %s" % quest_id, Color(0.4, 1.0, 0.4))

## ==================== NOTIFICAÇÕES ====================
func show_notification(title: String, message: String, color: Color = Color.WHITE, duration: float = 4.0) -> void:
	if not notification_container:
		return

	var panel = Panel.new()
	panel.add_theme_stylebox_override("panel", _create_notification_stylebox(color))

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var title_label = Label.new()
	title_label.text = title
	title_label.theme_override_font_size = 16
	title_label.add_theme_color_override("font_color", color)
	vbox.add_child(title_label)

	var msg_label = Label.new()
	msg_label.text = message
	msg_label.theme_override_font_size = 13
	msg_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(msg_label)

	notification_container.add_child(panel)

	# Animação de entrada
	panel.modulate = Color(1, 1, 1, 0)
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3)

	# Auto-remove
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_fade_out_notification.bind(panel))
	panel.add_child(timer)
	timer.start()

func _fade_out_notification(panel: Panel) -> void:
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.finished.connect(panel.queue_free.bind())

func _create_notification_stylebox(color: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	sb.border_color = color
	sb.border_width_bottom = 3
	sb.border_width_top = 1
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

## ==================== SKILL LEVEL UP ====================
func _on_skill_level_up(skill_index: int, new_level: int) -> void:
	var skill_names = ["Agricultura", "Mineração", "Coleta", "Pesca", "Combate"]
	var skill_icons = ["🌾", "⛏️", "🌲", "🎣", "⚔️"]

	var skill_name = skill_names[skill_index] if skill_index < skill_names.size() else "Habilidade"
	var icon = skill_icons[skill_index] if skill_index < skill_icons.size() else "⭐"

	# Notificação grande no centro
	var panel = Panel.new()
	panel.anchors_preset = 15
	panel.offset_left = -200
	panel.offset_top = -100
	panel.offset_right = 200
	panel.offset_bottom = 100
	panel.add_theme_stylebox_override("panel", _create_notification_stylebox(Color(1.0, 0.9, 0.3)))

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.theme_override_font_size = 48
	vbox.add_child(icon_label)

	var level_label = Label.new()
	level_label.text = "%s\nNível %d!" % [skill_name, new_level]
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.theme_override_font_size = 28
	level_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	vbox.add_child(level_label)

	# Desbloqueios
	var unlocks = _get_skill_unlocks(skill_index, new_level)
	if unlocks:
		var unlock_label = Label.new()
		unlock_label.text = "Desbloqueado: %s" % unlocks
		unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlock_label.theme_override_font_size = 14
		unlock_label.autowrap_mode = 1
		vbox.add_child(unlock_label)

	get_tree().root.get_child(0).add_child(panel)

	# Animação
	panel.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.5, 0.5)
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.4).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK)

	# Partículas
	if ParticleManager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ParticleManager.show_level_up(player.global_position, skill_name)

	# Remove após delay
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(_fade_out_notification.bind(panel))
	panel.add_child(timer)
	timer.start()

	# Som de level up
	_play_level_up_sound()

func _get_skill_unlocks(skill_index: int, level: int) -> String:
	# Retorna desbloqueios por nível (simplificado)
	var unlocks = {
		0: {5: "Sprinkler Básico", 10: "Sprinkler Qualidade"},
		1: {5: "Bombas", 10: "Elevador Mina"},
		2: {5: "Tapete de Grama", 10: "Semente de Árvore"},
		3: {5: "Isca", 10: "Vara de Irídio"},
		4: {5: "Anel de Combate", 10: "Espada Lendária"}
	}
	return unlocks.get(skill_index, {}).get(level, "")

func _play_level_up_sound() -> void:
	var player = AudioStreamPlayer.new()
	player.stream = load("res://assets/sfx/level_up.ogg") if ResourceLoader.exists("res://assets/sfx/level_up.ogg") else null
	if player.stream:
		player.bus = "SFX"
		player.play()
	player.finished.connect(player.queue_free.bind())
	get_tree().root.get_child(0).add_child(player)