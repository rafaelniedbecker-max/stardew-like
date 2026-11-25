class_name JunimoHut
extends Node2D

## Junimo Hut - Junimos colhem culturas automaticamente

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var junimo_container: Node2D = $JunimoContainer
@onready var progress_bar: ProgressBar = $ProgressBar

## Estado
var junimos: Array[Dictionary] = []
var max_junimos: int = 3
var harvest_radius: int = 8  # tiles
var is_active: bool = false
var last_harvest_day: int = -1

## Área de cobertura (círculo ao redor da hut)
const HARVEST_RADIUS = 17  # tiles (17x17 area = ~289 tiles)

## ==================== SINAIS ====================
signal junimo_added()
signal crop_harvested(position: Vector2i, item_id: String, amount: int, quality: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	progress_bar.visible = false

	_load_state()

	# Spawna Junimos se ativo
	if is_active and junimos.size() > 0:
		_spawn_junimos()

	# Conecta ao ciclo diário
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if is_active:
			HUD.show_interaction_prompt("E: Ver Junimo Hut (%d Junimos)" % junimos.size(), global_position + Vector2(0, -50))
		else:
			HUD.show_interaction_prompt("E: Colocar Estrela Junimo para ativar", global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	if is_active:
		_open_ui()
	else:
		_try_activate()

func _try_activate() -> void:
	if InventoryManager.has_item("(O)768"):  # Junimo Star (Golden Pumpkin ou item específico)
		if InventoryManager.remove_item("(O)768", 1):
			_activate_hut()
		else:
			HUD.show_message("Você precisa de uma Estrela Junimo!")
	else:
		HUD.show_message("Você precisa de uma Estrela Junimo para ativar a cabana!")

func _activate_hut() -> void:
	is_active = true
	# Spawna 3 Junimos
	for i in range(max_junimos):
		junimos.append({
			"id": "junimo_%d" % i,
			"color": i,  # 0=verde, 1=amarelo, 2=laranja, 3=vermelho, 4=azul, 5=roxo
			"state": "idle",
			"target": null
		})

	_spawn_junimos()
	_save_state()

	HUD.show_notification("🧙 Junimos Ativados!", "Os Junimos vão colher suas culturas automaticamente!", Color(0.5, 1.0, 0.5))

	if ParticleManager:
		ParticleManager.show_level_up(global_position, "Junimos!")

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/junimo_activate.ogg", global_position)

func _open_ui() -> void:
	var panel = Panel.new()
	panel.name = "JunimoHutUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 150
	panel.offset_right = -200
	panel.offset_bottom = -150

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🧙 Junimo Hut"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var status = Label.new()
	if is_active:
		status.text = "Status: Ativo (%d Junimos trabalhando)" % junimos.size()
		status.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		status.text = "Status: Inativo (precisa de Estrela Junimo)"
		status.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.theme_override_font_size = 16
	vbox.add_child(status)

	if is_active:
		# Lista Junimos
		var junimo_label = Label.new()
		junimo_label.text = "Junimos:"
		junimo_label.theme_override_font_size = 16
		vbox.add_child(junimo_label)

		var grid = GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 10)
		vbox.add_child(grid)

		for junimo in junimos:
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(80, 80)
			btn.flat = true

			var vbox_j = VBoxContainer.new()
			vbox_j.anchors_preset = 15
			btn.add_child(vbox_j)

			var icon = TextureRect.new()
			icon.custom_minimum_size = Vector2(48, 48)
			var colors = [Color(0.3, 0.8, 0.3), Color(1.0, 0.9, 0.2), Color(1.0, 0.6, 0.2), Color(1.0, 0.3, 0.3), Color(0.3, 0.6, 1.0), Color(0.7, 0.3, 1.0)]
			var color = colors[junimo.color % colors.size()]
			var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			for x in range(12, 36):
				for y in range(12, 36):
					var dx = (x - 24) / 12
					var dy = (y - 24) / 12
					if dx*dx + dy*dy < 1:
						img.set_pixel(x, y, color)
			var tex = ImageTexture.create_from_image(img)
			icon.texture = tex
			vbox_j.add_child(icon)

			var name = Label.new()
			name.text = "Junimo %d" % (junimo.id.get_slice("_", 1).to_int() + 1)
			name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name.theme_override_font_size = 12
			vbox_j.add_child(name)

			var state = Label.new()
			state.text = junimo.state.capitalize()
			state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			state.theme_override_font_size = 11
			vbox_j.add_child(state)

			grid.add_child(btn)

		# Raio de ação
		var radius_info = Label.new()
		radius_info.text = "Raio de colheita: %d tiles (%d tiles²)" % [HARVEST_RADIUS, (HARVEST_RADIUS * 2 + 1) * (HARVEST_RADIUS * 2 + 1)]
		radius_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		radius_info.theme_override_font_size = 12
		radius_info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		vbox.add_child(radius_info)

		# Culturas colhidas hoje
		if GameManager:
			var today_harvest = GameManager.get_data("junimo_harvest_today_%s" % [name], 0)
			var harvest_info = Label.new()
			harvest_info.text = "Colhidas hoje: %d" % today_harvest
			harvest_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			harvest_info.theme_override_font_size = 14
			harvest_info.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			vbox.add_child(harvest_info)

else:
		var activate_info = Label.new()
		activate_info.text = "Coloque uma Estrela Junimo para ativar.\n(Obtida no Centro Comunitário ou eventos)"
		activate_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		activate_info.autowrap_mode = 1
		activate_info.theme_override_font_size = 14
		vbox.add_child(activate_info)

var close_btn = Button.new()
close_btn.text = "Fechar"
close_btn.custom_minimum_size = Vector2(0, 40)
close_btn.pressed.connect(panel.queue_free.bind())
vbox.add_child(close_btn)

get_tree().root.get_child(0).add_child(panel)

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if is_active:
			HUD.show_interaction_prompt("E: Ver Junimo Hut", global_position + Vector2(0, -50))
		else:
			HUD.show_interaction_prompt("E: Ativar (precisa Estrela Junimo)", global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

## ==================== CICLO DIÁRIO ====================
func _on_day_changed(day: int, season: int, year: int) -> void:
	if not is_active:
		return

	# Junimos colhem culturas maduras no raio
	_harvest_crops()

	# Reset contador diário
	if GameManager:
		GameManager.set_data("junimo_harvest_today_%s" % [name], 0)

	_save_state()

func _harvest_crops() -> void:
	var total_harvested = 0
	var center_pos = global_position

	# Verifica todos os farm plots no raio
	var farm_plots = get_tree().get_nodes_in_group("farm_plots")
	for plot_node in farm_plots:
		if not plot_node is Node2D:
			continue

		for child in plot_node.get_children():
			if not child is Node2D:
				continue

			# Verifica se tem script de crop
			if not child.has_method("is_fully_grown"):
				continue

			var dist = center_pos.distance_to(child.global_position)
			if dist > HARVEST_RADIUS * TILE_SIZE:
				continue

			if child.is_fully_grown and not child.is_dead:
				# Colhe!
				var harvested = child.harvest()
				if harvested:
					total_harvested += 1

					# Junimo visual vai até a cultura
					_spawn_junimo_harvest_animation(child.global_position)

	# Atualiza contador
	if GameManager and total_harvested > 0:
		var current = GameManager.get_data("junimo_harvest_today_%s" % [name], 0)
		GameManager.set_data("junimo_harvest_today_%s" % [name], current + total_harvested)

		HUD.show_notification("🧙 Junimos!", "%d culturas colhidas automaticamente!" % total_harvested, Color(0.5, 1.0, 0.5))

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/junimo_harvest.ogg", global_position)

		if ParticleManager:
			ParticleManager.spawn_area("harvest", global_position, total_harvested * 2, HARVEST_RADIUS * TILE_SIZE)

func _spawn_junimo_harvest_animation(position: Vector2) -> void:
	if ParticleManager:
		ParticleManager.spawn("harvest", position)

	# Spawna Junimo visual temporário indo até a cultura
	var junimo = _create_junimo_visual()
	junimo.global_position = global_position
	get_tree().root.get_child(0).add_child(junimo)

	var tween = junimo.create_tween()
	tween.tween_property(junimo, "global_position", position, 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(junimo, "modulate:a", 0.0, 0.5).set_delay(1.5)
	tween.finished.connect(junimo.queue_free.bind())

func _create_junimo_visual() -> Node2D:
	var junimo = Node2D.new()
	var colors = [Color(0.3, 0.8, 0.3), Color(1.0, 0.9, 0.2), Color(1.0, 0.6, 0.2), Color(1.0, 0.3, 0.3), Color(0.3, 0.6, 1.0), Color(0.7, 0.3, 1.0)]
	var color = colors.pick_random()

	var sprite = Sprite2D.new()
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(6, 18):
		for y in range(6, 18):
			var dx = (x - 12) / 6
			var dy = (y - 12) / 6
			if dx*dx + dy*dy < 1:
				img.set_pixel(x, y, color)
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(12, 12)
	junimo.add_child(sprite)

	return junimo

func _spawn_junimos() -> void:
	if not junimo_container:
		return

	for child in junimo_container.get_children():
		child.queue_free()

	for i in range(junimos.size()):
		var junimo = junimos[i]
		var junimo_node = _create_junimo_visual(junimo.color)
		junimo_node.name = junimo.id
		junimo_node.global_position = junimo_container.global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		junimo_container.add_child(junimo_node)

		# AI - movimento aleatório perto da hut
		var timer = Timer.new()
		timer.wait_time = randf_range(3.0, 6.0)
		timer.one_shot = false
		timer.timeout.connect(_junimo_wander.bind(junimo_node))
		junimo_node.add_child(timer)
		timer.start()

func _create_junimo_visual(color_index: int) -> Node2D:
	var colors = [Color(0.3, 0.8, 0.3), Color(1.0, 0.9, 0.2), Color(1.0, 0.6, 0.2), Color(1.0, 0.3, 0.3), Color(0.3, 0.6, 1.0), Color(0.7, 0.3, 1.0)]
	var color = colors[color_index % colors.size()]

	var junimo = Node2D.new()

	var sprite = Sprite2D.new()
	var img = Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for x in range(6, 18):
		for y in range(6, 18):
			var dx = (x - 12) / 6
			var dy = (y - 12) / 6
			if dx*dx + dy*dy < 1:
				img.set_pixel(x, y, color)
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(12, 12)
	junimo.add_child(sprite)

	return junimo

func _junimo_wander(junimo: Node2D) -> void:
	if not junimo.is_inside_tree():
		return

	var angle = randf() * TAU
	var distance = randf_range(20, 60)
	var target = junimo.global_position + Vector2(cos(angle), sin(angle)) * distance

	var tween = junimo.create_tween()
	tween.tween_property(junimo, "global_position", target, 2.0).set_trans(Tween.TRANS_SINE)

func _save_state() -> void:
	if GameManager:
		GameManager.set_data("junimo_hut_%s" % [name], {
			"is_active": is_active,
			"junimos": junimos
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get_data("junimo_hut_%s" % [name], {})
		if data:
			is_active = data.get("is_active", false)
			junimos = data.get("junimos", [])

			if is_active:
				_spawn_junimos()