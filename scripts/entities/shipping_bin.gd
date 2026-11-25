class_name ShippingBin
extends Area2D

## Caixa de Entregas (Shipping Bin) com animação de venda

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var lid: Sprite2D = $Lid
@onready var particles: CPUParticles2D = $Particles
@onready var gold_label: Label = $GoldLabel
@onready var item_icon: TextureRect = $ItemIcon

## Estado
var items_sold_today: Array[Dictionary] = []
var total_gold_today: int = 0
var is_processing: bool = false
var pending_items: Array[Dictionary] = []

## ==================== SINAIS ====================
signal item_shipped(item_id: String, amount: int, quality: int, gold: int)
signal day_summary(total_items: int, total_gold: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	# Configura animações
	if sprite and sprite.sprite_frames:
		sprite.play("closed")

	gold_label.visible = false
	item_icon.visible = false

	# Carrega dados salvos
	_load_data()

	# Reseta diário
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func _on_day_changed(day: int, season: int, year: int) -> void:
	_reset_daily()

func _reset_daily() -> void:
	items_sold_today.clear()
	total_gold_today = 0
	pending_items.clear()
	_update_gold_label()

func _load_data() -> void:
	if GameManager:
		var data = GameManager.get_data("shipping_bin_data", {})
		total_gold_today = data.get("total_gold_today", 0)
		_update_gold_label()

func _save_data() -> void:
	if GameManager:
		GameManager.set_data("shipping_bin_data", {
			"total_gold_today": total_gold_today
		})

## ==================== INTERAÇÃO ====================
func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.show_interaction_prompt("E: Entregar itens", global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	if is_processing:
		return

	# Abre UI de entrega
	_open_shipping_ui()

## ==================== UI DE ENTREGA ====================
func _open_shipping_ui() -> void:
	var panel = Panel.new()
	panel.name = "ShippingBinUI"
	panel.anchors_preset = 15
	panel.offset_left = 150
	panel.offset_top = 50
	panel.offset_right = -150
	panel.offset_bottom = -50

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	# Título
	var title = Label.new()
	title.text = "📦 Caixa de Entregas"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 28
	vbox.add_child(title)

	# Ouro de hoje
	var gold_info = Label.new()
	gold_info.text = "Ouro hoje: %dg" % total_gold_today
	gold_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_info.theme_override_font_size = 18
	gold_info.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(gold_info)

	# Scroll com itens do inventário vendíveis
	var scroll = ScrollContainer.new()
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(grid)
	scroll.custom_minimum_size = Vector2(0, 300)
	vbox.add_child(scroll)

	if InventoryManager:
		var sellable_items = InventoryManager.get_sellable_items()
		for item_data in sellable_items:
			var item_id = item_data.item_id
			var amount = item_data.amount
			var quality = item_data.quality

			var item = DataLoader.get_item(item_id)
			if not item:
				continue

			var price = _calculate_sell_price(item_id, quality)
			var total = price * amount

			var btn = Button.new()
			btn.custom_minimum_size = Vector2(120, 120)
			btn.flat = true

			var item_vbox = VBoxContainer.new()
			item_vbox.anchors_preset = 15
			btn.add_child(item_vbox)

			var icon = TextureRect.new()
			icon.custom_minimum_size = Vector2(48, 48)
			if item.texture_path != "":
				icon.texture = load(item.texture_path)
			item_vbox.add_child(icon)

			var name = Label.new()
			name.text = item.display_name
			name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name.theme_override_font_size = 12
			name.autowrap_mode = 1
			item_vbox.add_child(name)

			var qty = Label.new()
			qty.text = "x%d" % amount
			qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			qty.theme_override_font_size = 11
			item_vbox.add_child(qty)

			var q_indicator = Label.new()
			var q_colors = [Color.WHITE, Color(0.75,0.75,0.75), Color(1.0,0.85,0.2), Color(0.6,0.3,1.0)]
			q_indicator.text = ["", "⭐", "⭐⭐", "⭐⭐⭐"][quality] if quality < 4 else ""
			q_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			q_indicator.theme_override_font_size = 12
			if quality > 0:
				q_indicator.add_theme_color_override("font_color", q_colors[quality])
			item_vbox.add_child(q_indicator)

			var price_label = Label.new()
			price_label.text = "%dg cada (%dg total)" % [price, total]
			price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			price_label.theme_override_font_size = 11
			price_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			item_vbox.add_child(price_label)

			btn.pressed.connect(_on_item_selected.bind(item_id, amount, quality, price, panel))
			grid.add_child(btn)

	# Botões de ação rápida
	var action_hbox = HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 10)

	var sell_all_btn = Button.new()
	sell_all_btn.text = "💰 Vender Tudo"
	sell_all_btn.custom_minimum_size = Vector2(150, 45)
	sell_all_btn.theme_override_font_size = 16
	sell_all_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	sell_all_btn.pressed.connect(_sell_all_items.bind(panel))
	action_hbox.add_child(sell_all_btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(100, 45)
	close_btn.pressed.connect(panel.queue_free.bind())
	action_hbox.add_child(close_btn)

	vbox.add_child(action_hbox)

	get_tree().root.get_child(0).add_child(panel)

func _calculate_sell_price(item_id: String, quality: int) -> int:
	var item = DataLoader.get_item(item_id)
	if not item:
		return 0

	var base_price = item.price

	# Multiplicador de qualidade
	var quality_mult = [1.0, 1.25, 1.5, 2.0][quality] if quality < 4 else 1.0

	# Profissão Artisan (level 10 farming)
	if GameManager and GameManager.professions.get("Farming") == 1:
		if item.category in ["ArtisanGoods", "Cooking", "Fish", "Forage", "Fruit", "Vegetable"]:
			quality_mult *= 1.5

	return int(base_price * quality_mult)

func _on_item_selected(item_id: String, amount: int, quality: int, price: int, panel: Panel) -> void:
	# Vende 1 unidade
	_sell_item(item_id, 1, quality, price)
	panel.queue_free()
	_open_shipping_ui()  # Reabre atualizado

func _sell_item(item_id: String, amount: int, quality: int, price: int) -> void:
	if not InventoryManager:
		return

	if InventoryManager.remove_item(item_id, amount):
		var total = price * amount
		total_gold_today += total
		GameManager.gold += total

		# Regista venda
		items_sold_today.append({
			"item_id": item_id,
			"amount": amount,
			"quality": quality,
			"price": price,
			"total": total
		})

		# Estatísticas
		if GameManager:
			GameManager.stats.items_shipped += amount
			GameManager.stats.gold_earned += total
			GameManager.emit_signal("gold_changed", GameManager.gold)

		# Animação de entrega
		_play_shipping_animation(item_id, amount, quality, total)

		# Som
		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/shipping.ogg", global_position)

		_save_data()

func _sell_all_items(panel: Panel) -> void:
	if not InventoryManager:
		return

	var sellable = InventoryManager.get_sellable_items()
	for item_data in sellable:
		var item_id = item_data.item_id
		var amount = item_data.amount
		var quality = item_data.quality
		var price = _calculate_sell_price(item_id, quality)
		_sell_item(item_id, amount, quality, price)

	panel.queue_free()
	_open_shipping_ui()

## ==================== ANIMAÇÃO ====================
func _play_shipping_animation(item_id: String, amount: int, quality: int, gold: int) -> void:
	is_processing = true

	# Abre tampa
	if lid:
		var tween = lid.create_tween()
		tween.tween_property(lid, "rotation", -PI/2, 0.3)
		tween.tween_property(lid, "rotation", 0, 0.3).set_delay(1.0)

	# Partículas
	if particles:
		particles.emitting = true
		particles.amount = amount * 5
		particles.one_shot = true

	# Ícone do item voando
	var item = DataLoader.get_item(item_id)
	if item and item_icon and item.texture_path != "":
		item_icon.texture = load(item.texture_path)
		item_icon.visible = true
		item_icon.global_position = global_position + Vector2(0, -40)

		var tween = item_icon.create_tween()
		tween.tween_property(item_icon, "global_position:y", item_icon.global_position.y - 60, 0.8)
		tween.tween_property(item_icon, "modulate:a", 0.0, 0.8)
		tween.finished.connect(func(): item_icon.visible = false)

	# Label de ouro
	gold_label.text = "+%dg" % gold
	gold_label.visible = true
	gold_label.global_position = global_position + Vector2(0, -80)
	gold_label.modulate = Color(1, 1, 1, 1)

	var tween = gold_label.create_tween()
	tween.tween_property(gold_label, "global_position:y", gold_label.global_position.y - 50, 1.0)
	tween.tween_property(gold_label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): gold_label.visible = false)

	# Espera animação terminar
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(func(): is_processing = false)
	add_child(timer)
	timer.start()

	# Atualiza label persistente
	_update_gold_label()

func _update_gold_label() -> void:
	# Label permanente mostrando total do dia
	pass

## ==================== RESUMO DO DIA ====================
func get_day_summary() -> Dictionary:
	return {
		"items_sold": items_sold_today.size(),
		"total_gold": total_gold_today,
		"details": items_sold_today.duplicate()
	}

func show_day_summary() -> void:
	var summary = get_day_summary()

	var panel = Panel.new()
	panel.name = "ShippingSummaryUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 150
	panel.offset_right = -200
	panel.offset_bottom = -150

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "📊 Resumo de Entregas - %s" % GameManager.get_date_string()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var gold_total = Label.new()
	gold_total.text = "Total: %dg" % total_gold_today
	gold_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_total.theme_override_font_size = 28
	gold_total.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(gold_total)

	var items_total = Label.new()
	items_total.text = "Itens: %d" % summary.items_sold
	items_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	items_total.theme_override_font_size = 16
	vbox.add_child(items_total)

	# Detalhes
	var scroll = ScrollContainer.new()
	var grid = GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(grid)
	scroll.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(scroll)

	for sale in items_sold_today:
		var item = DataLoader.get_item(sale.item_id)
		var name = item.display_name if item != null else sale.item_id
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		var n = Label.new()
		n.text = "%s x%d (%s)" % [name, sale.amount, ["Normal", "Prata", "Ouro", "Irídio"][sale.quality]]
		n.theme_override_font_size = 13
		hbox.add_child(n)

		var g = Label.new()
		g.text = "%dg" % sale.total
		g.theme_override_font_size = 13
		g.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		g.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(g)

		grid.add_child(hbox)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

	emit_signal("day_summary", summary.items_sold, total_gold_today)