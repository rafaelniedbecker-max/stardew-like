class_name SlimeHutch
extends Node2D

## Slime Hutch - cria slimes que produzem itens valiosos

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var egg_press: Area2D = $EggPress
@onready var slime_container: Node2D = $SlimeContainer
@onready var water_trough: Area2D = $WaterTrough

## Estado
var slimes: Array[Dictionary] = []
var max_slimes: int = 20
var has_water: bool = false
var water_level: int = 0
var max_water: int = 20
var egg_press_ready: bool = false
var egg_press_item: String = ""
var incubating_eggs: Array[Dictionary] = []

## Slimes possíveis
const SLIME_TYPES = {
	"Green": {"color": Color(0.3, 0.8, 0.3), "drops": ["(O)766", "(O)424"], "rare_drop": "(O)114", "value": 5},
	"Blue": {"color": Color(0.3, 0.5, 1.0), "drops": ["(O)388", "(O)390"], "rare_drop": "(O)440", "value": 10},
	"Red": {"color": Color(1.0, 0.3, 0.3), "drops": ["(O)430", "(O)442"], "rare_drop": "(O)116", "value": 15},
	"Purple": {"color": Color(0.6, 0.3, 1.0), "drops": ["(O)769", "(O)424"], "rare_drop": "(O)114", "value": 20},
	"Tiger": {"color": Color(1.0, 0.7, 0.2), "drops": ["(O)768", "(O)769"], "rare_drop": "(O)115", "value": 30},
	"Prismatic": {"color": Color(1.0, 1.0, 1.0), "drops": ["(O)749"], "rare_drop": "(O)749", "value": 50}
}

## ==================== SINAIS ====================
signal slime_added(slime_type: String)
signal egg_hatched(slime_type: String)
signal egg_press_ready(item_id: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	egg_press.monitorable = true
	egg_press.monitoring = true
	egg_press.area_entered.connect(_on_egg_press_entered)

	water_trough.monitorable = true
	water_trough.monitoring = true
	water_trough.area_entered.connect(_on_water_trough_entered)

	_load_state()
	_spawn_slimes()

	# Conecta ao ciclo diário
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		var prompt = "E: Ver Slime Hutch (%d/%d slimes)" % [slimes.size(), max_slimes]
		if water_level < max_water:
			prompt += " | Água: %d/%d" % [water_level, max_water]
		HUD.show_interaction_prompt(prompt, global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func _on_egg_press_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if egg_press_ready:
			HUD.show_interaction_prompt("E: Coletar %s" % DataLoader.get_item(egg_press_item)?.display_name, global_position + Vector2(0, -50))
		else:
			HUD.show_interaction_prompt("E: Colocar Ovo de Slime", global_position + Vector2(0, -50))

func _on_water_trough_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if water_level < max_water:
			HUD.show_interaction_prompt("E: Encher Bebeouro (%d/%d)" % [water_level, max_water], global_position + Vector2(0, -50))
		else:
			HUD.show_interaction_prompt("Bebeouro cheio", global_position + Vector2(0, -50))

func interact() -> void:
	_open_ui()

func _on_water_trough_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if water_level < max_water:
			_refill_water()

func _refill_water() -> void:
	if water_level >= max_water:
		HUD.show_message("Bebeouro já está cheio!")
		return

	if InventoryManager.has_item("(O)342"):  # Water (ou usa regador)
		water_level = max_water
		_save_state()
		HUD.show_message("Bebeouro enchido!")

		if ParticleManager:
			ParticleManager.spawn_area("water", water_trough.global_position, 10, 16.0)

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/water_fill.ogg", global_position)
	else:
		HUD.show_message("Precisa de água ou regador!")

func _open_ui() -> void:
	var panel = Panel.new()
	panel.name = "SlimeHutchUI"
	panel.anchors_preset = 15
	panel.offset_left = 150
	panel.offset_top = 50
	panel.offset_right = -150
	panel.offset_bottom = -50

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🟢 Slime Hutch"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	# Info geral
	var info_hbox = HBoxContainer.new()
	info_hbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_hbox.theme_override_constants/separation = 20

	var slime_info = Label.new()
	slime_info.text = "Slimes: %d/%d" % [slimes.size(), max_slimes]
	slime_info.theme_override_font_size = 16
	info_hbox.add_child(slime_info)

	var water_info = Label.new()
	water_info.text = "Água: %d/%d" % [water_level, max_water]
	water_info.theme_override_font_size = 16
	water_info.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0))
	info_hbox.add_child(water_info)

	vbox.add_child(info_hbox)

	# Lista de slimes
	var slime_label = Label.new()
	slime_label.text = "Slimes no Viveiro:"
	slime_label.theme_override_font_size = 16
	vbox.add_child(slime_label)

	var scroll = ScrollContainer.new()
	var grid = GridContainer.new()
	grid.columns = 5
	grid.theme_override_constants/h_separation = 10
	grid.theme_override_constants/v_separation = 10
	scroll.add_child(grid)
	scroll.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(scroll)

	for slime in slimes:
		var btn = _create_slime_button(slime)
		grid.add_child(btn)

	# Egg Press
	var press_box = HBoxContainer.new()
	press_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
	press_box.theme_override_constants/separation = 20

	var press_title = Label.new()
	press_title.text = "🥚 Prensa de Ovos:"
	press_title.theme_override_font_size = 16
	vbox.add_child(press_title)

	if egg_press_ready:
		var item = DataLoader.get_item(egg_press_item)
		var press_btn = Button.new()
		press_btn.text = "Coletar: %s" % (item?.display_name ?? egg_press_item)
		press_btn.custom_minimum_size = Vector2(200, 50)
		press_btn.theme_override_font_size = 16
		press_btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		press_btn.pressed.connect(_collect_egg_press)
		press_box.add_child(press_btn)
	else:
		var add_btn = Button.new()
		add_btn.text = "Inserir Ovo de Slime"
		add_btn.custom_minimum_size = Vector2(200, 50)
		add_btn.theme_override_font_size = 16
		add_btn.pressed.connect(_add_egg_to_press)
		press_box.add_child(add_btn)

	vbox.add_child(press_box)

	# Ovos incubando
	if incubating_eggs:
		var inc_label = Label.new()
		inc_label.text = "Ovos Incubando: %d" % incubating_eggs.size()
		inc_label.theme_override_font_size = 16
		vbox.add_child(inc_label)

		var inc_grid = GridContainer.new()
		inc_grid.columns = 4
		inc_grid.theme_override_constants/h_separation = 10
		vbox.add_child(inc_grid)

		for egg in incubating_eggs:
			var egg_btn = _create_egg_button(egg)
			inc_grid.add_child(egg_btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _create_slime_button(slime: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	btn.flat = true

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	btn.add_child(vbox)

	var type_data = SLIME_TYPES.get(slime.type, SLIME_TYPES["Green"])

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(12, 36):
		for y in range(12, 36):
			var dx = (x - 24) / 12
			var dy = (y - 24) / 12
			if dx*dx + dy*dy < 1:
				img.set_pixel(x, y, type_data.color)
	var tex = ImageTexture.create_from_image(img)
	icon.texture = tex
	vbox.add_child(icon)

	var name = Label.new()
	name.text = slime.type
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.theme_override_font_size = 11
	name.add_theme_color_override("font_color", type_data.color)
	vbox.add_child(name)

	var gender = Label.new()
	gender.text = slime.gender == 0 ? "♂" : "♀"
	gender.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gender.theme_override_font_size = 12
	vbox.add_child(gender)

	btn.pressed.connect(_show_slime_info.bind(slime))
	return btn

func _create_egg_button(egg: Dictionary) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(70, 70)
	btn.flat = true

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	btn.add_child(vbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	var item = DataLoader.get_item(egg.type)
	if item and item.texture_path != "":
		icon.texture = load(item.texture_path)
	vbox.add_child(icon)

	var days_left = Label.new()
	days_left.text = "%d dias" % egg.days_left
	days_left.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	days_left.theme_override_font_size = 11
	vbox.add_child(days_left)

	btn.disabled = true
	return btn

func _show_slime_info(slime: Dictionary) -> void:
	var type_data = SLIME_TYPES.get(slime.type, SLIME_TYPES["Green"])
	var panel = Panel.new()
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 150
	panel.offset_right = -200
	panel.offset_bottom = -150

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🟢 %s Slime" % slime.type
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 20
	title.add_theme_color_override("font_color", type_data.color)
	vbox.add_child(title)

	var gender = Label.new()
	gender.text = "Gênero: %s" % (slime.gender == 0 ? "Macho" : "Fêmea")
	gender.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gender.theme_override_font_size = 14
	vbox.add_child(gender)

	var drops = Label.new()
	drops.text = "Produz: %s" % [DataLoader.get_item(type_data.drops[0])?.display_name ?? type_data.drops[0]]
	drops.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drops.theme_override_font_size = 13
	vbox.add_child(drops)

	var value = Label.new()
	value.text = "Valor base: %dg/dia" % type_data.value
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.theme_override_font_size = 13
	value.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(value)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _collect_egg_press() -> void:
	if not egg_press_ready:
		return

	if InventoryManager.add_item(egg_press_item, 1):
		egg_press_ready = false
		egg_press_item = ""
		_save_state()
		HUD.show_message("Coletado: %s" % DataLoader.get_item(egg_press_item)?.display_name)

		if ParticleManager:
			ParticleManager.spawn("harvest", egg_press.global_position)

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/egg_press.ogg", global_position)
	else:
		HUD.show_message("Inventário cheio!")

func _add_egg_to_press() -> void:
	if InventoryManager:
		InventoryManager.open_slime_egg_mode(self)

func add_slime_egg(egg_type: String) -> bool:
	if egg_press_ready:
		HUD.show_message("Prensa já está ocupada!")
		return false

	# Identifica tipo de slime pelo ovo
	var slime_type = _get_slime_type_from_egg(egg_type)
	if not slime_type:
		return false

	if InventoryManager.remove_item(egg_type, 1):
		egg_press_ready = true
		egg_press_item = _get_press_output(slime_type)
		_save_state()
		HUD.show_message("Ovo inserido! Pressione E para coletar quando pronto.")
		return true
	return false

func _get_slime_type_from_egg(egg_type: String) -> String:
	match egg_type:
		"(O)413": return "Green"
		"(O)414": return "Blue"
		"(O)415": return "Red"
		"(O)416": return "Purple"
		"(O)417": return "Tiger"
		"(O)418": return "Prismatic"
	return "Green"

func _get_press_output(slime_type: String) -> String:
	var outputs = {
		"Green": "(O)766",   # Resina
		"Blue": "(O)388",    # Quartzo
		"Red": "(O)430",     # Rubi
		"Purple": "(O)769",  # Seiva de Mogno
		"Tiger": "(O)768",   # Ametista
		"Prismatic": "(O)749" # Prismatic Shard
	}
	return outputs.get(slime_type, "(O)766")

## ==================== CICLO DIÁRIO ====================
func _on_day_changed(day: int, season: int, year: int) -> void:
	# Slimes produzem itens se tiver água
	if water_level > 0:
		water_level = max(0, water_level - slimes.size())
		_produce_slime_items()

	# Chance de reprodução se tiver macho e fêmea
	_try_reproduction()

	# Ovos incubando
	_update_incubating_eggs()

	_save_state()

func _produce_slime_items() -> void:
	for slime in slimes:
		var type_data = SLIME_TYPES.get(slime.type, SLIME_TYPES["Green"])
		var drop = type_data.drops.pick_random()

		# Chance de drop raro
		if randf() < 0.01 and type_data.rare_drop != "":
			drop = type_data.rare_drop

		# Adiciona ao chão do hutch (player coleta interagindo)
		# Simplificado: adiciona ao inventário se tiver espaço
		if InventoryManager:
			InventoryManager.add_item(drop, 1)

		# Partículas
		if ParticleManager:
			ParticleManager.spawn("harvest", global_position + Vector2(randf_range(-64, 64), randf_range(-64, 64)))

func _try_reproduction() -> void:
	if slimes.size() >= max_slimes:
		return

	# Conta machos e fêmeas
	var males = 0
	var females = 0
	for slime in slimes:
		if slime.gender == 0:
			males += 1
		else:
			females += 1

	if males > 0 and females > 0 and water_level > 0:
		var chance = 0.05 * min(males, females)
		if randf() < chance:
			_hatch_baby_slime()

func _hatch_baby_slime() -> void:
	var parents = slimes.filter(func(s): return s.gender == 0).pick_random()
	var mother = slimes.filter(func(s): return s.gender == 1).pick_random()

	var baby_type = parents.type
	if randf() < 0.1:
		# Mutação rara
		var types = SLIME_TYPES.keys()
		baby_type = types.pick_random()

	var baby = {
		"type": baby_type,
		"gender": randi_range(0, 1)
	}
	slimes.append(baby)

	_spawn_slime_visual(baby)

	HUD.show_notification("🟢 Novo Slime!", "Um %s slime nasceu!" % baby_type, SLIME_TYPES[baby_type].color)

	emit_signal("slime_added", baby_type)
	_save_state()

func _update_incubating_eggs() -> void:
	for egg in incubating_eggs:
		egg.days_left -= 1
		if egg.days_left <= 0:
			_hatch_egg(egg)

	incubating_eggs = incubating_eggs.filter(func(e): return e.days_left > 0)

func _hatch_egg(egg: Dictionary) -> void:
	var slime_type = _get_slime_type_from_egg(egg.type)
	var baby = {
		"type": slime_type,
		"gender": randi_range(0, 1)
	}
	slimes.append(baby)
	_spawn_slime_visual(baby)

	HUD.show_notification("🥚 Ovo Chocou!", "Um %s slime nasceu!" % slime_type, SLIME_TYPES[slime_type].color)
	emit_signal("egg_hatched", slime_type)

func add_incubating_egg(egg_type: String) -> bool:
	if incubating_eggs.size() >= 4:
		return false

	var days = _get_incubation_days(egg_type)
	incubating_eggs.append({
		"type": egg_type,
		"days_left": days
	})
	_save_state()
	return true

func _get_incubation_days(egg_type: String) -> int:
	match egg_type:
		"(O)413": return 3   # Green
		"(O)414": return 4   # Blue
		"(O)415": return 5   # Red
		"(O)416": return 6   # Purple
		"(O)417": return 7   # Tiger
		"(O)418": return 14  # Prismatic
	return 3

## ==================== SPAWN VISUAL ====================
func _spawn_slimes() -> void:
	if not slime_container:
		return

	for child in slime_container.get_children():
		child.queue_free()

	for slime in slimes:
		_spawn_slime_visual(slime)

func _spawn_slime_visual(slime: Dictionary) -> void:
	if not slime_container:
		return

	var type_data = SLIME_TYPES.get(slime.type, SLIME_TYPES["Green"])

	var slime_node = Area2D.new()
	slime_node.name = "Slime_%s" % slime.type
	slime_node.monitorable = true
	slime_node.monitoring = true
	slime_node.collision_layer = 4
	slime_node.collision_mask = 1

	var sprite = Sprite2D.new()
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var color = type_data.color
	for x in range(8, 24):
		for y in range(8, 24):
			var dx = (x - 16) / 8
			var dy = (y - 16) / 8
			if dx*dx + dy*dy < 1:
				img.set_pixel(x, y, color)
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(16, 16)
	slime_node.add_child(sprite)

	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	(col.shape as CircleShape2D).radius = 12
	slime_node.add_child(col)

	# Posição aleatória dentro do container
	slime_node.global_position = slime_container.global_position + Vector2(randf_range(-200, 200), randf_range(-100, 100))

	slime_container.add_child(slime_node)

	# AI simples - movimento aleatório
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = false
	timer.timeout.connect(_slime_wander.bind(slime_node))
	slime_node.add_child(timer)
	timer.start()

func _slime_wander(slime_node: Area2D) -> void:
	if not slime_node.is_inside_tree():
		return

	var angle = randf() * TAU
	var distance = randf_range(20, 60)
	var target = slime_node.global_position + Vector2(cos(angle), sin(angle)) * distance

	var tween = slime_node.create_tween()
	tween.tween_property(slime_node, "global_position", target, 2.0).set_trans(Tween.TRANS_SINE)

## ==================== PERSISTÊNCIA ====================
func _save_state() -> void:
	if GameManager:
		GameManager.set("slime_hutch_%s" % [name], {
			"slimes": slimes,
			"water_level": water_level,
			"egg_press_ready": egg_press_ready,
			"egg_press_item": egg_press_item,
			"incubating_eggs": incubating_eggs
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get("slime_hutch_%s" % [name], {})
		if data:
			slimes = data.get("slimes", [])
			water_level = data.get("water_level", 0)
			egg_press_ready = data.get("egg_press_ready", false)
			egg_press_item = data.get("egg_press_item", "")
			incubating_eggs = data.get("incubating_eggs", [])

			_spawn_slimes()