class_name ShopUI
extends Control

## Sistema de Lojas com abas, busca, venda, compra

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var tabs: TabContainer = $Panel/TabContainer
@onready var buy_tab: ScrollContainer = $Panel/TabContainer/BuyTab/ScrollContainer/GridContainer
@onready var sell_tab: ScrollContainer = $Panel/TabContainer/SellTab/ScrollContainer/GridContainer
@onready var search_box: LineEdit = $Panel/TopBar/SearchBox
@onready var gold_label: Label = $Panel/TopBar/GoldLabel
@onready var category_buttons: HBoxContainer = $Panel/CategoryBar/HBoxContainer

## Estado
var current_shop: ShopData = null
var current_mode: String = "buy"  # "buy" ou "sell"
var search_text: String = ""
var active_category: String = "all"
var filtered_items: Array[Dictionary] = []

## ==================== SINAIS ====================
signal shop_closed()
signal item_bought(item_id: String, amount: int, price: int)
signal item_sold(item_id: String, amount: int, price: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	close_button.pressed.connect(hide)
	search_box.text_changed.connect(_on_search_changed)
	tabs.tab_changed.connect(_on_tab_changed)

	# Cria botões de categoria
	_setup_category_buttons()

func _setup_category_buttons() -> void:
	var categories = [
		{"id": "all", "name": "Todos", "icon": "📦"},
		{"id": "seeds", "name": "Sementes", "icon": "🌱"},
		{"id": "tools", "name": "Ferramentas", "icon": "⛏️"},
		{"id": "food", "name": "Comida", "icon": "🍳"},
		{"id": "artisan", "name": "Artesanato", "icon": "🫙"},
		{"id": "furniture", "name": "Móveis", "icon": "🪑"},
		{"id": "building", "name": "Edifícios", "icon": "🏠"},
		{"id": "other", "name": "Outros", "icon": "📦"}
	]

	for cat in categories:
		var btn = Button.new()
		btn.text = "%s %s" % [cat.icon, cat.name]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(100, 35)
		btn.theme_override_font_size = 14
		btn.pressed.connect(_on_category_selected.bind(cat.id))
		category_buttons.add_child(btn)

	# Seleciona "Todos" por padrão
	if category_buttons.get_child_count() > 0:
		category_buttons.get_child(0).button_pressed = true

## ==================== ABRIR LOJA ====================
func open_shop(shop_data: ShopData) -> void:
	current_shop = shop_data
	current_mode = "buy"
	visible = true
	panel.visible = true
	popup_centered()
	_get_tree().paused = true

	_update_gold()
	_refresh_items()
	grab_focus()

func _update_gold() -> void:
	if GameManager:
		gold_label.text = "%dg" % GameManager.gold

func _on_tab_changed(tab_idx: int) -> void:
	var modes = ["buy", "sell"]
	if tab_idx < modes.size():
		current_mode = modes[tab_idx]
		_refresh_items()

func _on_category_selected(category: String) -> void:
	active_category = category
	# Atualiza botões
	for i in range(category_buttons.get_child_count()):
		var btn = category_buttons.get_child(i)
		btn.button_pressed = (btn.get("category_id", "") == category)
	_refresh_items()

func _on_search_changed(text: String) -> void:
	search_text = text.to_lower()
	_refresh_items()

## ==================== FILTRAGEM E EXIBIÇÃO ====================
func _refresh_items() -> void:
	if not current_shop:
		return

	# Limpa grids
	for child in buy_tab.get_children():
		child.queue_free()
	for child in sell_tab.get_children():
		child.queue_free()

	if current_mode == "buy":
		_populate_buy_tab()
	else:
		_populate_sell_tab()

func _populate_buy_tab() -> void:
	filtered_items.clear()

	# Filtra itens da loja
	for item_entry in current_shop.items:
		var item_id = item_entry.item_id
		var item = DataLoader.get_item(item_id)
		if not item:
			continue

		# Filtro de categoria
		if active_category != "all" and not _matches_category(item, active_category):
			continue

		# Filtro de busca
		if search_text != "" and not _matches_search(item, search_text):
			continue

		# Preço da loja
		var price = item_entry.get_price(GameManager.get_data("shop_prices_multiplier", 1.0) if GameManager else 1.0)
		var stock = item_entry.get_stock()

		filtered_items.append({
			"item_id": item_id,
			"item": item,
			"price": price,
			"stock": stock,
			"unlimited": item_entry.unlimited_stock
		})

	# Cria botões
	for entry in filtered_items:
		var btn = _create_shop_item_button(entry, true)
		buy_tab.add_child(btn)

func _populate_sell_tab() -> void:
	filtered_items.clear()

	if not InventoryManager:
		return

	# Itens do inventário que podem ser vendidos
	var sellable = InventoryManager.get_sellable_items()
	for entry in sellable:
		var item_id = entry.item_id
		var item = DataLoader.get_item(item_id)
		if not item:
			continue

		# Filtro de categoria
		if active_category != "all" and not _matches_category(item, active_category):
			continue

		# Filtro de busca
		if search_text != "" and not _matches_search(item, search_text):
			continue

		var sell_price = int(item.price * 0.5)  # Preço de venda = 50% do base
		if item.quality > 0:
			var q_mult = [1.0, 1.25, 1.5, 2.0][item.quality] if item.quality < 4 else 1.0
			sell_price = int(sell_price * q_mult)

		filtered_items.append({
			"item_id": item_id,
			"item": item,
			"price": sell_price,
			"amount": entry.amount,
			"quality": entry.quality
		})

	# Cria botões
	for entry in filtered_items:
		var btn = _create_shop_item_button(entry, false)
		sell_tab.add_child(btn)

func _create_shop_item_button(entry: Dictionary, is_buy: bool) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(120, 120)
	btn.flat = true

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	btn.add_child(vbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	var item = entry.item
	if item.texture_path != "":
		icon.texture = load(item.texture_path)
	vbox.add_child(icon)

	var name = Label.new()
	name.text = item.display_name
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.theme_override_font_size = 12
	name.autowrap_mode = 1
	vbox.add_child(name)

	var qty = Label.new()
	if is_buy:
		if entry.unlimited:
			qty.text = "∞"
		else:
			qty.text = "x%d" % entry.stock
		if entry.stock <= 0 and not entry.unlimited:
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	else:
		qty.text = "x%d" % entry.amount
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty.theme_override_font_size = 11
	vbox.add_child(qty)

	var price = Label.new()
	price.text = "%dg" % entry.price
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.theme_override_font_size = 12
	price.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(price)

	if is_buy:
		btn.pressed.connect(_buy_item.bind(entry))
	else:
		btn.pressed.connect(_sell_item.bind(entry))

	return btn

func _matches_category(item: ItemData, category: String) -> bool:
	match category:
		"seeds": return item.category in [-75, -79]  # Seeds
		"tools": return item.is_tool()
		"food": return item.edibility != 0
		"artisan": return item.category in [-7, -8]  # Artisan goods
		"furniture": return item.category == -9  # Furniture
		"building": return item.category == -10  # Buildings
		"other": return true
	return true

func _matches_search(item: ItemData, search: String) -> bool:
	return search in item.display_name.to_lower() or search in item.internal_name.to_lower()

## ==================== COMPRA/VENDA ====================
func _buy_item(entry: Dictionary) -> void:
	if not InventoryManager or not GameManager:
		return

	var item_id = entry.item_id
	var price = entry.price
	var amount = 1

	# Verifica ouro
	if GameManager.gold < price:
		HUD.show_message("Ouro insuficiente! Precisa de %dg" % price)
		return

	# Verifica estoque
	if not entry.unlimited and entry.stock <= 0:
		HUD.show_message("Fora de estoque!")
		return

	# Adiciona ao inventário
	if InventoryManager.add_item(item_id, amount):
		GameManager.gold -= price
		GameManager.emit_signal("gold_changed", GameManager.gold)

		# Decrementa estoque
		if not entry.unlimited:
			entry.stock -= 1
			# Atualiza na loja original
			for shop_item in current_shop.items:
				if shop_item.item_id == item_id:
					shop_item.stock = entry.stock
					break

		emit_signal("item_bought", item_id, amount, price)

		if AudioManager:
			AudioManager.play_sfx("res://assets/sfx/buy.ogg")

		HUD.show_message("Comprado: %s por %dg" % [entry.item.display_name, price])

		_refresh_items()
		_update_gold()
	else:
		HUD.show_message("Inventário cheio!")

func _sell_item(entry: Dictionary) -> void:
	if not InventoryManager or not GameManager:
		return

	var item_id = entry.item_id
	var price = entry.price
	var amount = 1

	# Remove do inventário
	if InventoryManager.remove_item(item_id, amount):
		GameManager.gold += price
		GameManager.emit_signal("gold_changed", GameManager.gold)

		emit_signal("item_sold", item_id, amount, price)

		if AudioManager:
			AudioManager.play_sfx("res://assets/sfx/sell.ogg")

		HUD.show_message("Vendido: %s por %dg" % [entry.item.display_name, price])

		_refresh_items()
		_update_gold()
	else:
		HUD.show_message("Erro ao vender!")

## ==================== VENDA RÁPIDA (SHIFT+CLICK) ====================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		if event.shift_pressed:
			# Venda rápida no modo venda
			if current_mode == "sell":
				# Pega item sob o mouse
				pass

## ==================== PÚBLICO ====================
func hide() -> void:
	visible = false
	panel.visible = false
	_get_tree().paused = false
	emit_signal("shop_closed")