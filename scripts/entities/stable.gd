class_name Stable
extends Node2D

## Estábulo - permite ter cavalo para movimento rápido

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var horse_sprite: AnimatedSprite2D = $HorseSprite

## Estado
var has_horse: bool = false
var horse_name: String = ""
var horse_color: int = 0  # 0=Marrom, 1=Branco, 2=Preto, 3=Pônei
var horse_position: Vector2 = Vector2.ZERO

## Cores de cavalo disponíveis
const HORSE_COLORS = [
	{"name": "Marrom", "color": Color(0.5, 0.3, 0.2), "price": 0},
	{"name": "Branco", "color": Color(0.9, 0.9, 0.9), "price": 50000},
	{"name": "Preto", "color": Color(0.2, 0.2, 0.2), "price": 50000},
	{"name": "Pônei", "color": Color(0.8, 0.6, 0.4), "price": 100000}
]

## ==================== SINAIS ====================
signal horse_ready(horse_name: String)
signal horse_renamed(new_name: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	if horse_sprite:
		horse_sprite.visible = false

	_load_state()

	# Spawna cavalo se tiver
	if has_horse:
		_spawn_horse()

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if has_horse:
			HUD.show_interaction_prompt("E: Montar %s" % horse_name, global_position + Vector2(0, -50))
		else:
			HUD.show_interaction_prompt("E: Comprar Cavalo (100.000g)", global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	if has_horse:
		_mount_horse()
	else:
		_buy_horse_ui()

func _buy_horse_ui() -> void:
	if GameManager.gold < 100000:
		HUD.show_message("Ouro insuficiente! Precisa de 100.000g.")
		return

	var panel = Panel.new()
	panel.name = "StableUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 100
	panel.offset_right = -200
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🐎 Estábulo - Comprar Cavalo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var gold_info = Label.new()
	gold_info.text = "Seu ouro: %dg" % GameManager.gold
	gold_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_info.theme_override_font_size = 16
	vbox.add_child(gold_info)

	var desc = Label.new()
	desc.text = "Cavalo padrão: 100.000g (Marrom)\nCores especiais disponíveis após compra."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = 1
	desc.theme_override_font_size = 13
	vbox.add_child(desc)

	# Seleção de cor
	var color_hbox = HBoxContainer.new()
	color_hbox.alignment = HORIZONTAL_ALIGNMENT_CENTER
	color_hbox.theme_override_constants/separation = 10

	for i, color_data in enumerate(HORSE_COLORS):
		if i > 0 and GameManager.gold < 100000 + color_data.price:
			continue  # Só mostra se pode comprar

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.flat = true

		var vbox_c = VBoxContainer.new()
		vbox_c.anchors_preset = 15
		btn.add_child(vbox_c)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		# Sprite procedural do cavalo
		icon.texture = _create_horse_preview(color_data.color)
		vbox_c.add_child(icon)

		var name = Label.new()
		name.text = color_data.name
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.theme_override_font_size = 12
		vbox_c.add_child(name)

		var price = Label.new()
		if i == 0:
			price.text = "Grátis"
			price.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			price.text = "%dg" % (100000 + color_data.price)
			if GameManager.gold < 100000 + color_data.price:
				price.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.theme_override_font_size = 11
		vbox_c.add_child(price)

		btn.pressed.connect(_buy_horse.bind(i, panel))
		color_hbox.add_child(btn)

	vbox.add_child(color_hbox)

	# Nome do cavalo
	var name_box = HBoxContainer.new()
	name_box.alignment = HORIZONTAL_ALIGNMENT_CENTER

	var name_label = Label.new()
	name_label.text = "Nome: "
	name_label.theme_override_font_size = 16
	name_box.add_child(name_label)

	var name_input = LineEdit.new()
	name_input.placeholder_text = "Nome do cavalo..."
	name_input.custom_minimum_size = Vector2(200, 30)
	name_box.add_child(name_input)

	vbox.add_child(name_box)

	var buy_btn = Button.new()
	buy_btn.text = "🐎 Comprar Cavalo"
	buy_btn.custom_minimum_size = Vector2(0, 50)
	buy_btn.theme_override_font_size = 18
	buy_btn.pressed.connect(_confirm_buy_horse.bind(name_input, panel))
	vbox.add_child(buy_btn)

	var close_btn = Button.new()
	close_btn.text = "Cancelar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _buy_horse(color_index: int, panel: Panel) -> void:
	# Apenas seleciona a cor, confirma no botão final
	panel.set("selected_color", color_index)

func _confirm_buy_horse(name_input: LineEdit, panel: Panel) -> void:
	var color_index = panel.get("selected_color", 0)
	var color_data = HORSE_COLORS[color_index]
	var total_cost = 100000 + color_data.price

	if GameManager.gold < total_cost:
		HUD.show_message("Ouro insuficiente!")
		return

	var name = name_input.text.strip()
	if name == "":
		name = "Cavalo"

	GameManager.gold -= total_cost
	GameManager.emit_signal("gold_changed", GameManager.gold)

	has_horse = true
	horse_name = name
	horse_color = color_index

	_save_state()
	_spawn_horse()

	panel.queue_free()
	HUD.show_notification("🐎 Cavalo Comprado!", "%s (%s) está pronto!" % [name, color_data.name], Color(0.5, 1.0, 0.5))

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/horse_buy.ogg")

func _mount_horse() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Verifica se cavalo está por perto
	var dist = player.global_position.distance_to(horse_position)
	if dist > 200:
		HUD.show_message("%s está muito longe. Chame-o com o apito." % horse_name)
		return

	# Monta no cavalo
	player.set("mounted", true)
	player.set("horse_speed", 400.0)  # Velocidade dobrada
	player.set("horse_name", horse_name)

	# Esconde sprite do cavalo
	if horse_sprite:
		horse_sprite.visible = false

	HUD.show_message("Montou em %s! Velocidade dobrada." % horse_name)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/horse_mount.ogg", global_position)

	# Timer para desmontar automaticamente ao entrar em prédio
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(func():
		var area = player.get_node_or_null("InteractionArea")
		if area:
			area.area_entered.connect(_check_dismount.bind(player))
	))
	player.add_child(timer)
	timer.start()

func _check_dismount(player: Node, area: Area2D) -> void:
	if area.get_parent().is_in_group("building"):
		_dismount_horse(player)

func _dismount_horse(player: Node) -> void:
	if player.get("mounted", false):
		player.set("mounted", false)
		player.set("horse_speed", 0.0)
		horse_sprite.visible = true
		horse_sprite.global_position = player.global_position + Vector2(-48, 0)
		horse_position = horse_sprite.global_position
		HUD.show_message("Desmontou de %s." % horse_name)

func _spawn_horse() -> void:
	if not horse_sprite:
		return

	horse_sprite.visible = true
	horse_sprite.global_position = global_position + Vector2(64, 0)
	horse_position = horse_sprite.global_position

	# Configura cor
	var color_data = HORSE_COLORS[horse_color]
	horse_sprite.modulate = color_data.color

	# Animação idle
	if horse_sprite.sprite_frames and horse_sprite.sprite_frames.has_animation("idle"):
		horse_sprite.play("idle")

	# AI simples - segue player se longe
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = false
	timer.timeout.connect(_horse_ai)
	horse_sprite.add_child(timer)
	timer.start()

func _horse_ai() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or player.get("mounted", false):
		return

	var dist = horse_sprite.global_position.distance_to(player.global_position)
	if dist > 150:
		# Move em direção ao player
		var dir = (player.global_position - horse_sprite.global_position).normalized()
		horse_sprite.global_position += dir * 100 * 2.0  # Velocidade do cavalo
		horse_position = horse_sprite.global_position

		# Atualiza animação
		if horse_sprite.sprite_frames.has_animation("walk"):
			horse_sprite.play("walk")
	elif dist < 50:
		if horse_sprite.sprite_frames.has_animation("idle"):
			horse_sprite.play("idle")

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if has_horse:
			HUD.show_interaction_prompt("E: Montar %s" % horse_name, global_position + Vector2(0, -50))
		else:
			HUD.show_interaction_prompt("E: Comprar Cavalo (100.000g)", global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func _save_state() -> void:
	if GameManager:
		GameManager.set("stable_%s" % [name], {
			"has_horse": has_horse,
			"horse_name": horse_name,
			"horse_color": horse_color,
			"horse_position": {"x": horse_position.x, "y": horse_position.y}
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get("stable_%s" % [name], {})
		if data:
			has_horse = data.get("has_horse", false)
			horse_name = data.get("horse_name", "")
			horse_color = data.get("horse_color", 0)
			var pos = data.get("horse_position", {})
			horse_position = Vector2(pos.get("x", 0), pos.get("y", 0))

			if has_horse:
				_spawn_horse()

func _create_horse_preview(color: Color) -> Texture2D:
	var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Desenha cavalo simples
	for x in range(8, 40):
		for y in range(12, 36):
			var dx = (x - 24) / 16
			var dy = (y - 24) / 12
			if dx*dx + dy*dy < 1:
				img.set_pixel(x, y, color)
			# Crina
			if x < 16 and y > 20 and y < 32:
				img.set_pixel(x, y, color.darkened(0.3))

	return ImageTexture.create_from_image(img)