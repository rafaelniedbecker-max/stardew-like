class_name FestivalMinigames
extends Node

## Minigames de Festival com UIs Aprimoradas

## ==================== BASE MINIGAME UI ====================
class MinigameUIBase:
	var panel: Panel
	var title_label: Label
	var timer_label: Label
	var counter_label: Label
	var timer: Timer
	var arena: Node2D
	var on_finish: Callable

	func create(title: String, description: String, duration: float, on_complete: Callable) -> Panel:
		var p = Panel.new()
		p.name = "MinigameUI_%s" % title
		p.anchors_preset = 15
		p.offset_left = 100
		p.offset_top = 50
		p.offset_right = -100
		p.offset_bottom = -150

		var vbox = VBoxContainer.new()
		p.add_child(vbox)

		var t = Label.new()
		t.text = title
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.theme_override_font_size = 28
		vbox.add_child(t)

		var d = Label.new()
		d.text = description
		d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		d.autowrap_mode = 1
		d.theme_override_font_size = 16
		d.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		vbox.add_child(d)

		# Timer bar
		var timer_bar = ProgressBar.new()
		timer_bar.min_value = 0
		timer_bar.max_value = duration
		timer_bar.value = duration
		timer_bar.custom_minimum_size = Vector2(300, 20)
		vbox.add_child(timer_bar)

		var timer_lbl = Label.new()
		timer_lbl.text = "Tempo: %.0fs" % duration
		timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_lbl.theme_override_font_size = 18
		vbox.add_child(timer_lbl)

		# Counter
		var counter_lbl = Label.new()
		counter_lbl.text = "0 / 0"
		counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		counter_lbl.theme_override_font_size = 24
		counter_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		vbox.add_child(counter_lbl)

		# Timer real
		var tmr = Timer.new()
		tmr.wait_time = duration
		tmr.one_shot = true
		tmr.timeout.connect(func(): _on_timeout(p, on_complete))
		p.add_child(tmr)
		tmr.start()

		# Update timer visual
		var update_timer = Timer.new()
		update_timer.wait_time = 0.1
		update_timer.one_shot = false
		update_timer.timeout.connect(func(): _update_timer_visual(timer_bar, timer_lbl, tmr, duration))
		p.add_child(update_timer)
		update_timer.start()

		return p

	static func _update_timer_visual(bar: ProgressBar, lbl: Label, tmr: Timer, max_time: float) -> void:
		var remaining = tmr.time_left
		bar.value = remaining
		lbl.text = "Tempo: %.1fs" % remaining
		if remaining < 10:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		elif remaining < 20:
			lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))

	static func _on_timeout(p: Panel, callback: Callable) -> void:
		p.queue_free()
		if callback:
			callback.call(false)

	func update_counter(current: int, target: int) -> void:
		if counter_label:
			counter_label.text = "%d / %d" % [current, target]
			if current >= target:
				counter_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))

	func finish(won: bool) -> void:
		if timer:
			timer.stop()
		if panel:
			panel.queue_free()
		if on_finish:
			on_finish.call(won)


## ==================== EGG HUNT ====================
func start_egg_hunt(festival_mgr: FestivalManager) -> void:
	var arena = Node2D.new()
	arena.name = "EggHuntArena"

	# Chão decorado
	for i in range(50):
		var grass = Sprite2D.new()
		grass.texture = _create_grass_texture()
		grass.position = Vector2(randi_range(0, 800), randi_range(0, 600))
		grass.modulate = Color(0.3, 0.5, 0.2, 0.5)
		arena.add_child(grass)

	# Ovos
	var eggs_collected = 0
	var target_eggs = 9

	for i in range(12):
		var egg = _create_egg(i, target_eggs, arena, festival_mgr)
		arena.add_child(egg)

	# UI
	var ui = MinigameUIBase.create(
		"🥚 Caça aos Ovos",
		"Encontre %d ovos escondidos antes do tempo acabar!" % target_eggs,
		50.0,
		func(won: bool): _end_egg_hunt(festival_mgr, arena, won)
	)
	ui.name = "EggHuntUI"

	# Contador customizado
	var counter = ui.get_node_or_null("VBoxContainer/Label[2]") # 3rd label
	if counter:
		counter.text = "Ovos: 0 / %d" % target_eggs

	# Armazena referências
	arena.set("eggs_collected", 0)
	arena.set("target", target_eggs)
	arena.set("ui", ui)

	get_tree().root.get_child(0).add_child(arena)
	get_tree().root.get_child(0).add_child(ui)

func _create_egg(index: int, target: int, arena: Node2D, festival_mgr: FestivalManager) -> Area2D:
	var egg = Area2D.new()
	egg.name = "Egg_%d" % index

	var sprite = Sprite2D.new()
	# Sprite procedural de ovo colorido
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var colors = [
		Color(1.0, 0.4, 0.4),  # Vermelho
		Color(0.4, 1.0, 0.4),  # Verde
		Color(0.4, 0.6, 1.0),  # Azul
		Color(1.0, 0.9, 0.3),  # Amarelo
		Color(1.0, 0.5, 1.0),  # Rosa
		Color(0.5, 1.0, 1.0)   # Ciano
	]
	var egg_color = colors[randi() % colors.size()]
	img.fill(Color(0, 0, 0, 0))
	for x in range(8, 24):
		for y in range(8, 24):
			var dx = (x - 16) / 8
			var dy = (y - 16) / 12
			if dx*dx + dy*dy < 1:
				img.set_pixel(x, y, egg_color)
			# Brilho
			if dx*dx + (dy-0.2)*(dy-0.2) < 0.1:
				img.set_pixel(x, y, egg_color.lightened(0.4))
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(16, 16)
	egg.add_child(sprite)

	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	(col.shape as CircleShape2D).radius = 16
	egg.add_child(col)

	# Posição aleatória mas acessível
	var attempts = 0
	while attempts < 10:
		var pos = Vector2(randi_range(80, 720), randi_range(80, 520))
		# Verifica não muito perto de outros ovos
		var ok = true
		for child in arena.get_children():
			if child is Area2D and child.global_position.distance_to(pos) < 60:
				ok = false
				break
		if ok:
			egg.global_position = pos
			break
		attempts += 1

	egg.area_entered.connect(func(area: Area2D): _on_egg_collected(area, index, arena, festival_mgr))
	return egg

func _on_egg_collected(area: Area2D, index: int, arena: Node2D, festival_mgr: FestivalManager) -> void:
	if not area.is_in_group("player"):
		return

	var collected = arena.get("eggs_collected", 0) + 1
	arena.set("eggs_collected", collected)

	# Partícula
	if ParticleManager:
		ParticleManager.spawn("harvest", area.global_position)

	# Som
	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/collect_egg.ogg", area.global_position)

	# Remove ovo
	area.queue_free()

	# Atualiza UI
	var ui = arena.get("ui")
	if ui:
		var counter = ui.get_node_or_null("VBoxContainer/Label[2]")
		if counter:
			counter.text = "Ovos: %d / %d" % [collected, arena.get("target", 9)]

	if collected >= arena.get("target", 9):
		_end_egg_hunt(festival_mgr, arena, true)

func _end_egg_hunt(festival_mgr: FestivalManager, arena: Node2D, won: bool) -> void:
	var ui = arena.get("ui")
	if ui:
		ui.queue_free()
	arena.queue_free()

	if won:
		if InventoryManager:
			InventoryManager.add_item("(O)453", 1)  # Straw Hat
		HUD.show_notification("🏆 Vitória!", "Você ganhou o Chapéu de Palha!", Color(1.0, 0.9, 0.3))
		if festival_mgr:
			festival_mgr.emit_signal("festival_reward_earned", {"item": "(O)453", "name": "Straw Hat"})
	else:
		if InventoryManager:
			InventoryManager.add_item("(O)454", 1)  # Chocolate Egg
		HUD.show_notification("⏰ Tempo!", "Você recebeu um ovo de chocolate.", Color(0.8, 0.8, 0.8))
		if festival_mgr:
			festival_mgr.emit_signal("festival_reward_earned", {"item": "(O)454", "name": "Chocolate Egg"})


## ==================== GRANGE DISPLAY (FAIR) ====================
func start_grange_display(festival_mgr: FestivalManager) -> void:
	var panel = Panel.new()
	panel.name = "GrangeUI"
	panel.anchors_preset = 15
	panel.offset_left = 30
	panel.offset_top = 20
	panel.offset_right = -30
	panel.offset_bottom = -20

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Título
	var title = Label.new()
	title.text = "🏆 Feira do Vale Stardew - Exposição Grange"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 28
	vbox.add_child(title)

	# Instruções
	var instr = Label.new()
	instr.text = "Coloque até 9 itens para exibição. Será julgado por qualidade, variedade e raridade."
	instr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instr.autowrap_mode = 1
	instr.theme_override_font_size = 14
	instr.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(instr)

	# Grid 3x3
	var grid = GridContainer.new()
	grid.columns = 3
	grid.theme_override_constants/h_separation = 10
	grid.theme_override_constants/v_separation = 10
	grid.custom_minimum_size = Vector2(360, 360)

	var slots = []
	for i in range(9):
		var slot = _create_grange_slot(i)
		grid.add_child(slot)
		slots.append(slot)

	var grid_wrapper = Panel.new()
	grid_wrapper.add_child(grid)
	grid_wrapper.custom_minimum_size = Vector2(400, 400)
	vbox.add_child(grid_wrapper)

	# Info de pontuação
	var score_panel = HBoxContainer.new()
	score_panel.theme_override_constants/separation = 20

	var score_label = Label.new()
	score_label.text = "Pontuação: 0"
	score_label.theme_override_font_size = 20
	score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	score_panel.add_child(score_label)

	var star_tokens = Label.new()
	star_tokens.text = "⭐ Fichas: %d" % (GameManager.get("star_tokens", 0) if GameManager else 0)
	star_tokens.theme_override_font_size = 16
	star_tokens.add_theme_color_override("font_color", Color(0.5, 1.0, 1.0))
	score_panel.add_child(star_tokens)

	vbox.add_child(score_panel)

	# Botões
	var btn_hbox = HBoxContainer.new()
	btn_hbox.theme_override_constants/separation = 10

	var auto_btn = Button.new()
	auto_btn.text = "🎲 Preencher Auto"
	auto_btn.custom_minimum_size = Vector2(150, 40)
	auto_btn.theme_override_font_size = 16
	auto_btn.pressed.connect(func(): _auto_fill_grange(slots, score_label))
	btn_hbox.add_child(auto_btn)

	var clear_btn = Button.new()
	clear_btn.text = "🗑 Limpar"
	clear_btn.custom_minimum_size = Vector2(100, 40)
	clear_btn.theme_override_font_size = 16
	clear_btn.pressed.connect(func(): _clear_grange(slots, score_label))
	btn_hbox.add_child(clear_btn)

	var judge_btn = Button.new()
	judge_btn.text = "⚖ Julgar Exposição"
	judge_btn.custom_minimum_size = Vector2(180, 50)
	judge_btn.theme_override_font_size = 18
	judge_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	judge_btn.pressed.connect(func(): _judge_grange(slots, festival_mgr, panel))
	btn_hbox.add_child(judge_btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	btn_hbox.add_child(close_btn)

	vbox.add_child(btn_hbox)

	get_tree().root.get_child(0).add_child(panel)

	# Armazena slots
	panel.set("slots", slots)
	panel.set("score_label", score_label)

func _create_grange_slot(index: int) -> Control:
	var btn = Button.new()
	btn.name = "Slot_%d" % index
	btn.custom_minimum_size = Vector2(110, 110)
	btn.flat = true

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	btn.add_child(vbox)

	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(64, 64)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon)

	var name_label = Label.new()
	name_label.name = "Name"
	name_label.text = "Vazio"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.theme_override_font_size = 11
	name_label.autowrap_mode = 1
	vbox.add_child(name_label)

	var quality_label = Label.new()
	quality_label.name = "Quality"
	quality_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quality_label.theme_override_font_size = 10
	vbox.add_child(quality_label)

	btn.pressed.connect(func(): _on_grange_slot_clicked(index, btn))
	return btn

func _on_grange_slot_clicked(index: int, slot: Button) -> void:
	# Abre inventário para selecionar item
	if InventoryManager:
		InventoryManager.open_grange_mode(index, slot)

func _auto_fill_grange(slots: Array, score_label: Label) -> void:
	# Preenche com melhores itens do inventário
	if not InventoryManager:
		return

	var items = InventoryManager.get_all_items_for_grange()
	items.sort_custom(_compare_grange_value.bind())

	for i in range(min(9, items.size())):
		_set_grange_slot(slots[i], items[i])

	_update_grange_score(slots, score_label)

func _clear_grange(slots: Array, score_label: Label) -> void:
	for slot in slots:
		var icon = slot.get_node_or_null("Icon")
		var name = slot.get_node_or_null("Name")
		var qual = slot.get_node_or_null("Quality")
		if icon: icon.texture = null
		if name: name.text = "Vazio"
		if qual: qual.text = ""
		slot.set("item_id", "")
		slot.set("quality", 0)
	_update_grange_score(slots, score_label)

func _set_grange_slot(slot: Button, item_data: Dictionary) -> void:
	var icon = slot.get_node_or_null("Icon")
	var name = slot.get_node_or_null("Name")
	var qual = slot.get_node_or_null("Quality")

	var item_id = item_data.item_id
	var quality = item_data.quality
	var amount = item_data.amount

	var item = DataLoader.get_item(item_id)
	if item:
		if icon and item.texture_path != "":
			icon.texture = load(item.texture_path)
		if name:
			name.text = item.display_name
		if qual:
			var q_names = ["Normal", "Prata", "Ouro", "Irídio"]
			var q_colors = [Color.WHITE, Color(0.75,0.75,0.75), Color(1.0,0.85,0.2), Color(0.6,0.3,1.0)]
			qual.text = q_names[quality] if quality < q_names.size() else ""
			qual.add_theme_color_override("font_color", q_colors[quality] if quality < q_colors.size() else Color.WHITE)

	slot.set("item_id", item_id)
	slot.set("quality", quality)
	slot.set("amount", amount)

func _update_grange_score(slots: Array, score_label: Label) -> void:
	var score = 0
	for slot in slots:
		var item_id = slot.get("item_id", "")
		if item_id != "":
			var quality = slot.get("quality", 0)
			var amount = slot.get("amount", 1)
			score += (quality + 1) * 10 * amount  # Base score
	score_label.text = "Pontuação: %d" % score

func _compare_grange_value(a: Dictionary, b: Dictionary) -> int:
	# Ordena por valor de grange (qualidade * raridade)
	var score_a = (a.quality + 1) * (DataLoader.get_item(a.item_id)?.price ?? 10)
	var score_b = (b.quality + 1) * (DataLoader.get_item(b.item_id)?.price ?? 10)
	return score_b - score_a

func _judge_grange(slots: Array, festival_mgr: FestivalManager, panel: Panel) -> void:
	var score = 0
	var items = []

	for slot in slots:
		var item_id = slot.get("item_id", "")
		if item_id != "":
			var quality = slot.get("quality", 0)
			var amount = slot.get("amount", 1)
			items.append({"id": item_id, "quality": quality, "amount": amount})
			score += (quality + 1) * 10 * amount

	# Bônus por variedade
	var unique_items = items.size()
	score += unique_items * 15

	# Bônus por qualidade alta
	for item in items:
		if item.quality >= 2:
			score += (item.quality - 1) * 20

	# Recompensa em Star Tokens
	var tokens = max(1, score / 10)
	if GameManager:
		var current = GameManager.get("star_tokens", 0)
		GameManager.set("star_tokens", current + tokens)

	# Mensagem
	var place = "Participação"
	if score >= 100: place = "1º Lugar 🥇"
	elif score >= 70: place = "2º Lugar 🥈"
	elif score >= 40: place = "3º Lugar 🥉"

	HUD.show_notification("🏆 Resultado da Feira!", "%s - %d pontos\n+%d ⭐ Fichas" % [place, score, tokens], Color(1.0, 0.9, 0.3))

	if festival_mgr:
		festival_mgr.emit_signal("festival_reward_earned", {"star_tokens": tokens, "place": place})

	panel.queue_free()


## ==================== FISHING CONTEST ====================
func start_fishing_contest(festival_mgr: FestivalManager) -> void:
	# Usa o minigame de pesca existente com timer
	HUD.show_notification("🎣 Concurso de Pesca!", "Pegue o maior peixe em 2 minutos!", Color(0.4, 0.8, 1.0))

	var timer = Timer.new()
	timer.wait_time = 120.0
	timer.one_shot = true
	timer.timeout.connect(func(): _end_fishing_contest(festival_mgr))
	get_tree().root.get_child(0).add_child(timer)
	timer.start()

	# UI de tempo
	var ui = MinigameUIBase.create(
		"🎣 Concurso de Pesca",
		"Pegue o maior peixe possível em 2 minutos!",
		120.0,
		func(won: bool): _end_fishing_contest(festival_mgr)
	)
	ui.name = "FishingContestUI"

	# Inicia pesca normal
	if FishingManager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			FishingManager.start_fishing(player, "")

func _end_fishing_contest(festival_mgr: FestivalManager) -> void:
	var ui = get_tree().root.get_child(0).get_node_or_null("FishingContestUI")
	if ui:
		ui.queue_free()

	# Verifica maior peixe pego (simplificado)
	var caught_fish = GameManager.get("contest_fish", {})
	var best_size = caught_fish.get("size", 0.0)
	var best_quality = caught_fish.get("quality", 0)

	var tokens = int(best_size * 10) + best_quality * 5 + 10
	if GameManager:
		var current = GameManager.get("star_tokens", 0)
		GameManager.set("star_tokens", current + tokens)

	HUD.show_notification("🏁 Concurso Terminou!", "Seu melhor: %.2fm (Qualidade: %s)\n+%d ⭐" % [
		best_size, ["Normal", "Prata", "Ouro", "Irídio"][best_quality], tokens
	], Color(0.4, 1.0, 0.7))

	if festival_mgr:
		festival_mgr.emit_signal("festival_reward_earned", {"star_tokens": tokens})


## ==================== SLINGSHOT GAME ====================
func start_slingshot_game(festival_mgr: FestivalManager) -> void:
	HUD.show_notification("🎯 Estilingue!", "Acerte os alvos móveis!", Color(1.0, 0.5, 0.3))

	var arena = Node2D.new()
	arena.name = "SlingshotArena"

	# Alvos
	for i in range(10):
		var target = _create_moving_target(i, arena)
		arena.add_child(target)

	# UI
	var ui = MinigameUIBase.create(
		"🎯 Estilingue da Feira",
		"Acerte 15 alvos em 60 segundos!",
		60.0,
		func(won: bool): _end_slingshot_game(festival_mgr, arena, won)
	)
	ui.name = "SlingshotUI"

	arena.set("targets_hit", 0)
	arena.set("ui", ui)

	get_tree().root.get_child(0).add_child(arena)
	get_tree().root.get_child(0).add_child(ui)

func _create_moving_target(index: int, arena: Node2D) -> Area2D:
	var target = Area2D.new()
	target.name = "Target_%d" % index

	var sprite = Sprite2D.new()
	var img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Alvo circular
	for x in range(20):
		for y in range(20):
			var dx = x - 10
			var dy = y - 10
			if dx*dx + dy*dy < 100:
				var ring = int(sqrt(dx*dx + dy*dy) / 2)
				img.set_pixel(x, y, Color(1.0, 1.0 - ring*0.2, 0.0) if ring % 2 == 0 else Color.WHITE)
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(20, 20)
	target.add_child(sprite)

	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	(col.shape as CircleShape2D).radius = 20
	target.add_child(col)

	target.global_position = Vector2(randi_range(100, 700), randi_range(100, 500))

	# Movimento
	var tween = target.create_tween()
	tween.set_loops()
	tween.tween_property(target, "global_position:x", randi_range(100, 700), randf_range(2, 5))
	tween.tween_property(target, "global_position:y", randi_range(100, 500), randf_range(2, 5))

	target.area_entered.connect(func(area: Area2D): _on_target_hit(area, target, arena))

	return target

func _on_target_hit(area: Area2D, target: Area2D, arena: Node2D) -> void:
	if not area.is_in_group("player_tool"):
		return

	var hit = arena.get("targets_hit", 0) + 1
	arena.set("targets_hit", hit)

	# Partícula
	if ParticleManager:
		ParticleManager.spawn("harvest", target.global_position)

	# Som
	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/target_hit.ogg", target.global_position)

	# Remove alvo e cria novo
	target.queue_free()
	var new_target = _create_moving_target(randi(), arena)
	arena.add_child(new_target)

	# Atualiza UI
	var ui = arena.get("ui")
	if ui:
		var counter = ui.get_node_or_null("VBoxContainer/Label[2]")
		if counter:
			counter.text = "Acertos: %d / 15" % hit

	if hit >= 15:
		_end_slingshot_game(festival_mgr, arena, true)

func _end_slingshot_game(festival_mgr: FestivalManager, arena: Node2D, won: bool) -> void:
	var ui = arena.get("ui")
	if ui: ui.queue_free()
	arena.queue_free()

	var tokens = won ? 50 : (arena.get("targets_hit", 0) * 3)
	if GameManager:
		var current = GameManager.get("star_tokens", 0)
		GameManager.set("star_tokens", current + tokens)

	if won:
		HUD.show_notification("🎯 Perfeito!", "Todos os alvos acertados!\n+%d ⭐" % tokens, Color(1.0, 0.9, 0.3))
	else:
		HUD.show_notification("🎯 Fim de Jogo", "Acertos: %d\n+%d ⭐" % [arena.get("targets_hit", 0), tokens], Color(0.8, 0.8, 0.8))

	if festival_mgr:
		festival_mgr.emit_signal("festival_reward_earned", {"star_tokens": tokens})


## ==================== MAZE (SPIRIT'S EVE) ====================
func start_maze(festival_mgr: FestivalManager) -> void:
	HUD.show_notification("👻 Labirinto Assombrado!", "Enchaçe o final antes da meia-noite!", Color(0.7, 0.3, 1.0))

	var maze = Node2D.new()
	maze.name = "SpiritMaze"

	# Gera labirinto procedural simples
	_generate_maze(maze)

	# UI
	var ui = MinigameUIBase.create(
		"👻 Labirinto dos Espíritos",
		"Navegue até o centro e pegue a Abóbora Dourada!",
		300.0,  # 5 minutos
		func(won: bool): _end_maze(festival_mgr, maze, won)
	)
	ui.name = "MazeUI"

	get_tree().root.get_child(0).add_child(maze)
	get_tree().root.get_child(0).add_child(ui)

	# Player entra no labirinto
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector2(100, 100)

func _generate_maze(maze: Node2D) -> void:
	# Labirinto simples baseado em grid
	var cell_size = 64
	var cols = 15
	var rows = 12

	# Paredes
	for x in range(cols):
		for y in range(rows):
			if randf() < 0.3 or x == 0 or y == 0 or x == cols-1 or y == rows-1:
				var wall = StaticBody2D.new()
				var sprite = Sprite2D.new()
				var img = Image.create(cell_size, cell_size, false, Image.FORMAT_RGBA8)
				img.fill(Color(0.2, 0.1, 0.3))
				sprite.texture = ImageTexture.create_from_image(img)
				wall.add_child(sprite)

				var col = CollisionShape2D.new()
				col.shape = RectangleShape2D.new()
				(col.shape as RectangleShape2D).size = Vector2(cell_size, cell_size)
				wall.add_child(col)

				wall.global_position = Vector2(x * cell_size, y * cell_size)
				maze.add_child(wall)

	# Objetivo no centro
	var goal = Area2D.new()
	goal.name = "GoldenPumpkin"
	var sprite = Sprite2D.new()
	var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0,0,0,0))
	for x in range(12, 36):
		for y in range(12, 36):
			if (x-24)*(x-24) + (y-24)*(y-24) < 144:
				img.set_pixel(x, y, Color(1.0, 0.6, 0.0))
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.offset = Vector2(24, 24)
	goal.add_child(sprite)

	var col = CollisionShape2D.new()
	col.shape = CircleShape2D.new()
	(col.shape as CircleShape2D).radius = 24
	goal.add_child(col)

	goal.global_position = Vector2((cols/2) * cell_size, (rows/2) * cell_size)
	goal.area_entered.connect(func(area): _on_goal_reached(area, maze))
	maze.add_child(goal)

func _on_goal_reached(area: Area2D, maze: Node2D) -> void:
	if not area.is_in_group("player"):
		return

	var ui = get_tree().root.get_child(0).get_node_or_null("MazeUI")
	if ui: ui.queue_free()

	if InventoryManager:
		InventoryManager.add_item("(O)768", 1)  # Golden Pumpkin

	HUD.show_notification("🎃 Sucesso!", "Você encontrou a Abóbora Dourada!", Color(1.0, 0.6, 0.0))

	maze.queue_free()

	# Emite sinal
	if FestivalManager:
		FestivalManager.emit_signal("festival_reward_earned", {"item": "(O)768", "name": "Golden Pumpkin"})


## ==================== ICE FISHING ====================
func start_ice_fishing(festival_mgr: FestivalManager) -> void:
	# Similar ao fishing contest mas no gelo
	start_fishing_contest(festival_mgr)


## ==================== GIFT EXCHANGE (WINTER) ====================
func start_gift_exchange(festival_mgr: FestivalManager) -> void:
	HUD.show_notification("🎁 Troca de Presentes!", "Dê um presente para um habitante aleatório!", Color(1.0, 0.4, 0.7))

	# Seleciona NPC aleatório
	var npcs = DataLoader.get_all_npcs()
	var recipient = npcs.pick_random()

	var panel = Panel.new()
	panel.name = "GiftExchangeUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 150
	panel.offset_right = -200
	panel.offset_bottom = -150

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🎁 Troca de Presentes de Inverno"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Você tirou %s! Escolha um presente para dar." % recipient.display_name
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = 1
	desc.theme_override_font_size = 16
	vbox.add_child(desc)

	# Gosto do NPC
	var prefs = VBoxContainer.new()
	prefs.theme_override_constants/separation = 5

	var love_label = Label.new()
	love_label.text = "❤️ Ama: %s" % recipient.loved_gifts.slice(0, 3).join(", ")
	love_label.theme_override_font_size = 13
	love_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.7))
	prefs.add_child(love_label)

	var like_label = Label.new()
	like_label.text = "💚 Gosta: %s" % recipient.liked_gifts.slice(0, 3).join(", ")
	like_label.theme_override_font_size = 13
	like_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	prefs.add_child(like_label)

	vbox.add_child(prefs)

	# Botão para abrir inventário
	var gift_btn = Button.new()
	gift_btn.text = "🎁 Escolher Presente do Inventário"
	gift_btn.custom_minimum_size = Vector2(0, 50)
	gift_btn.theme_override_font_size = 18
	gift_btn.pressed.connect(func(): _open_gift_select(panel, recipient))
	vbox.add_child(gift_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.custom_minimum_size = Vector2(0, 40)
	cancel_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(cancel_btn)

	get_tree().root.get_child(0).add_child(panel)

func _open_gift_select(panel: Panel, recipient: NPCData) -> void:
	if InventoryManager:
		InventoryManager.open_gift_mode(recipient.internal_name, panel)
	panel.queue_free()


## ==================== POTLUCK (LUAU) ====================
func start_potluck(festival_mgr: FestivalManager) -> void:
	HUD.show_notification("🍲 Luau - Potluck!", "Contribua com um ingrediente para a sopa comunitária!", Color(1.0, 0.5, 0.3))

	var panel = Panel.new()
	panel.name = "PotluckUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 100
	panel.offset_right = -200
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🍲 Luau - Sopa Comunitária"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Todos os habitantes contribuem. A qualidade da sopa depende dos ingredientes!\nItens amados pelos NPCs dão bônus extra."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = 1
	desc.theme_override_font_size = 14
	vbox.add_child(desc)

	# Lista ingredientes no inventário com dicas
	var scroll = ScrollContainer.new()
	var grid = GridContainer.new()
	grid.columns = 2
	grid.theme_override_constants/h_separation = 10
	grid.theme_override_constants/v_separation = 5
	scroll.add_child(grid)
	scroll.custom_minimum_size = Vector2(400, 300)
	vbox.add_child(scroll)

	if InventoryManager:
		var items = InventoryManager.get_cooking_ingredients()
		for item_data in items:
			var item_id = item_data.item_id
			var item = DataLoader.get_item(item_id)
			if not item:
				continue

			var btn = Button.new()
			btn.custom_minimum_size = Vector2(0, 50)
			btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

			var hbox = HBoxContainer.new()
			btn.add_child(hbox)

			var icon = TextureRect.new()
			icon.custom_minimum_size = Vector2(40, 40)
			if item.texture_path != "":
				icon.texture = load(item.texture_path)
			hbox.add_child(icon)

			var info = VBoxContainer.new()
			var name = Label.new()
			name.text = item.display_name
			name.theme_override_font_size = 14
			info.add_child(name)

			# Verifica se NPCs amam
			var lovers = 0
			for npc in DataLoader.get_all_npcs():
				if item_id in npc.loved_gifts:
					lovers += 1
			if lovers > 0:
				var bonus = Label.new()
				bonus.text = "❤️ Amado por %d habitante(s)" % lovers
				bonus.theme_override_font_size = 11
				bonus.add_theme_color_override("font_color", Color(1.0, 0.5, 0.7))
				info.add_child(bonus)

			hbox.add_child(info)
			btn.add_child(hbox)

			btn.pressed.connect(func(): _submit_potluck_item(panel, item_id, festival_mgr))
			grid.add_child(btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.custom_minimum_size = Vector2(0, 40)
	cancel_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(cancel_btn)

	get_tree().root.get_child(0).add_child(panel)

func _submit_potluck_item(panel: Panel, item_id: String, festival_mgr: FestivalManager) -> void:
	if not InventoryManager:
		return

	if InventoryManager.remove_item(item_id, 1):
		# Calcula qualidade da contribuição
		var quality = 0
		var lovers = 0
		for npc in DataLoader.get_all_npcs():
			if item_id in npc.loved_gifts:
				lovers += 1
			elif item_id in npc.liked_gifts:
				lovers += 0.5

		if lovers >= 3: quality = 3
		elif lovers >= 1: quality = 2
		elif lovers > 0: quality = 1

		var base_friendship = 20 + lovers * 10
		if GameManager:
			for npc in DataLoader.get_all_npcs():
				if item_id in npc.loved_gifts or item_id in npc.liked_gifts:
					var fname = npc.internal_name
					var current = GameManager.friendships.get(fname, 0)
					GameManager.friendships[fname] = min(2749, current + base_friendship)
					GameManager.emit_signal("friendship_changed", fname, GameManager.friendships[fname])

		HUD.show_notification("🍲 Contribuição Aceita!", "Sopa ganhou qualidade %s!\n+%d amizade com todos" % [["Normal", "Prata", "Ouro", "Irídio"][quality], base_friendship], Color(0.5, 1.0, 0.5))

		if festival_mgr:
			festival_mgr.emit_signal("festival_reward_earned", {"friendship_bonus": base_friendship})

	panel.queue_free()