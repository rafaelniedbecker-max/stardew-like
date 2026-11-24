class_name ShopUI
extends Control

## UI de Loja completa: compra, venda, estoque dinâmico, filtros

@onready var buy_tab: TabButton = $Panel/TabContainer/BuyTab
@onready var sell_tab: TabButton = $Panel/TabContainer/SellTab
@onready var buy_container: GridContainer = $Panel/BuyPanel/ScrollContainer/GridContainer
@onready var sell_container: GridContainer = $Panel/SellPanel/ScrollContainer/GridContainer
@onready var gold_label: Label = $Panel/TopBar/GoldLabel
@onready var owner_name: Label = $Panel/TopBar/OwnerName
@onready var owner_dialogue: Label = $Panel/TopBar/OwnerDialogue
@onready var owner_portrait: TextureRect = $Panel/TopBar/OwnerPortrait
@onready var filter_buttons: HBoxContainer = $Panel/FilterBar/HBoxContainer
@onready var close_button: Button = $Panel/CloseButton
@onready var item_tooltip: Control = $ItemTooltip
@onready var tooltip_name: Label = $ItemTooltip/NameLabel
@onready var tooltip_desc: Label = $ItemTooltip/DescLabel
@onready var tooltip_price: Label = $ItemTooltip/PriceLabel
@onready var tooltip_quality: Label = $ItemTooltip/QualityLabel
@onready var quantity_dialog: ConfirmationDialog = $QuantityDialog
@onready var qty_label: Label = $QuantityDialog/QtyLabel
@onready var qty_spin: SpinBox = $QuantityDialog/SpinBox
@onready var qty_total: Label = $QuantityDialog/TotalLabel
@onready var qty_buy_btn: Button = $QuantityDialog/BuyButton
@onready var qty_sell_btn: Button = $QuantityDialog/SellButton

## Estado
var current_shop: ShopData = null
var current_owner: Dictionary = null
var mode: String = "buy"  # "buy" ou "sell"
var selected_item: Dictionary = null
var selected_item_data: ItemData = null
var is_buying: bool = true
var buy_sell_callback: Callable = null
var active_filters: Array[String] = ["all"]
var player_inventory_cache: Dictionary = {}

## ==================== SINAIS ====================
signal shop_closed()
signal item_bought(item_id: String, quantity: int, total_price: int)
signal item_sold(item_id: String, quantity: int, total_price: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	_setup_filters()
	close_button.pressed.connect(hide)
	buy_tab.toggled.connect(func(pressed): _on_tab_changed("buy") if pressed else null)
	sell_tab.toggled.connect(func(pressed): _on_tab_changed("sell") if pressed else null)
	qty_buy_btn.pressed.connect(_on_confirm_quantity)
	qty_sell_btn.pressed.connect(_on_confirm_quantity)
	quantity_dialog.confirmed.connect(_on_confirm_quantity)
	quantity_dialog.canceled.connect(_on_quantity_canceled)

func _setup_filters() -> void:
	var categories = ["all", "seeds", "crops", "animal", "artisan", "minerals", "cooking", "tools", "weapons", "furniture", "bait", "tackle"]
	for cat in categories:
		var btn = Button.new()
		btn.text = cat.capitalize()
		btn.toggle_mode = true
		btn.button_group = filter_buttons.get_node_or_null("ButtonGroup") or ButtonGroup.new()
		if not filter_buttons.has_node("ButtonGroup"):
			var bg = ButtonGroup.new()
			bg.name = "ButtonGroup"
			filter_buttons.add_child(bg)
		btn.pressed.connect(_on_filter_pressed.bind(cat))
		filter_buttons.add_child(btn)
		if cat == "all":
			btn.button_pressed = true

## ==================== ABRIR LOJA ====================
func open_shop(shop_data: ShopData, owner_data: Dictionary = null, buy_callback: Callable = null, sell_callback: Callable = null) -> void:
	current_shop = shop_data
	current_owner = owner_data
	buy_sell_callback = buy_callback

	# Configura dono
	if owner_data:
		owner_name.text = owner_data.get("Name", "Shop")
		owner_dialogue.text = shop_data.get_owner_dialogue()
		if owner_data.has("Portrait"):
			owner_portrait.texture = owner_data["Portrait"]
	else:
		owner_name.text = shop_data.get_shop_name()
		owner_dialogue.text = shop_data.get_owner_dialogue()

	# Atualiza ouro
	_update_gold()

	# Popula abas
	_populate_buy_tab()
	_populate_sell_tab()

	# Mostra
	visible = true
	buy_tab.button_pressed = true
	_on_tab_changed("buy")
	get_viewport().gui_get_focus_owner()?.release_focus()
	grab_focus()

func _update_gold() -> void:
	gold_label.text = "%dg" % GameManager.gold

## ==================== ABA COMPRAR ====================
func _populate_buy_tab() -> void:
	_clear_container(buy_container)

	if not current_shop:
		return

	var available_items = current_shop.get_available_items(DataLoader._item_cache, {
		"shop_purchases": GameManager.get("shop_purchases", {})
	})

	var filtered = _filter_items(available_items, active_filters)

	for item_info in filtered:
		var item_id = item_info.get("ItemId", "")
		var item_data = DataLoader.get_item(item_id)
		if not item_data:
			continue

		var price = current_shop.get_item_price(item_info, item_data)
		var stock = item_info.get("AvailableStock", -1)
		var is_recipe = item_info.get("IsRecipe", false)

		_create_shop_slot(buy_container, item_data, price, stock, is_recipe, true)

func _create_shop_slot(parent: GridContainer, item: ItemData, price: int, stock: int, is_recipe: bool, can_buy: bool) -> void:
	var slot = PanelContainer.new()
	slot.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	slot.custom_minimum_size = Vector2(160, 100)

	var vbox = VBoxContainer.new()
	slot.add_child(vbox)

	# Ícone + nome
	var hbox = HBoxContainer.new()
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# TODO: Carregar textura real do item
	hbox.add_child(icon)

	var name_label = Label.new()
	name_label.text = item.get_display_name()
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_label)
	vbox.add_child(hbox)

	# Preço
	var price_hbox = HBoxContainer.new()
	var gold_icon = TextureRect.new()
	gold_icon.custom_minimum_size = Vector2(16, 16)
	# gold_icon.texture = load("res://resources/sprites/ui/gold.png")
	price_hbox.add_child(gold_icon)

	var price_label = Label.new()
	price_label.text = "%dg" % price
	price_label.add_theme_color_override("font_color", Color.GOLD)
	price_hbox.add_child(price_label)

	# Estoque
	if stock > 0:
		var stock_label = Label.new()
		stock_label.text = "Estoque: %d" % stock
		stock_label.add_theme_color_override("font_color", Color.YELLOW)
		price_hbox.add_child(stock_label)
	elif stock == 0:
		var stock_label = Label.new()
		stock_label.text = "Esgotado"
		stock_label.add_theme_color_override("font_color", Color.RED)
		price_hbox.add_child(stock_label)

	vbox.add_child(price_hbox)

	# Tag de receita
	if is_recipe:
		var recipe_tag = Label.new()
		recipe_tag.text = "[RECEITA]"
		recipe_tag.add_theme_color_override("font_color", Color.CYAN)
		recipe_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(recipe_tag)

	# Botão comprar
	var buy_btn = Button.new()
	buy_btn.text = "Comprar"
	buy_btn.disabled = not can_buy or (stock == 0) or (price > GameManager.gold)
	buy_btn.pressed.connect(_on_buy_clicked.bind(item, price, stock, is_recipe))
	vbox.add_child(buy_btn)

	# Tooltip
	slot.gui_input.connect(_on_slot_gui_input.bind(item, price, stock, is_recipe))
	parent.add_child(slot)

func _on_buy_clicked(item: ItemData, price: int, stock: int, is_recipe: bool) -> void:
	if price > GameManager.gold:
		_show_message("Ouro insuficiente!")
		return

	selected_item = {"item": item, "price": price, "stock": stock, "is_recipe": is_recipe}
	selected_item_data = item
	is_buying = true

	qty_spin.min_value = 1
	qty_spin.max_value = 999 if stock == -1 else stock
	qty_spin.value = 1
	qty_label.text = "Comprar: %s" % item.get_display_name()
	qty_buy_btn.visible = true
	qty_sell_btn.visible = false
	_update_quantity_total()
	quantity_dialog.popup_centered()

func _update_quantity_total() -> void:
	var qty = int(qty_spin.value)
	var total = 0
	if is_buying:
		total = selected_item["price"] * qty
		qty_total.text = "Total: %dg" % total
		qty_buy_btn.disabled = total > GameManager.gold
	else:
		total = _get_sell_price(selected_item_data, qty)
		qty_total.text = "Total: %dg" % total

func _get_sell_price(item: ItemData, qty: int, quality: int = 0) -> int:
	var base_price = item.price
	var mult = 1.0
	match quality:
		1: mult = 1.25
		2: mult = 1.5
		3: mult = 2.0
	return inti(base_price * mult * qty)

## ==================== ABA VENDER ====================
func _populate_sell_tab() -> void:
	_clear_container(sell_container)

	# Cache do inventário
	player_inventory_cache = GameManager.inventory.duplicate(true)

	var filtered = _filter_inventory_items(player_inventory_cache, active_filters)

	for item_id in filtered:
		var count = player_inventory_cache[item_id]
		var item_data = DataLoader.get_item(item_id)
		if not item_data:
			continue

		var sell_price = _get_sell_price(item_data, 1)
		_create_shop_slot(sell_container, item_data, sell_price, count, false, false, true)

func _create_shop_slot(parent: GridContainer, item: ItemData, price: int, stock: int, is_recipe: bool, can_buy: bool, is_sell_mode: bool = false) -> void:
	var slot = PanelContainer.new()
	slot.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	slot.custom_minimum_size = Vector2(160, 100)

	var vbox = VBoxContainer.new()
	slot.add_child(vbox)

	var hbox = HBoxContainer.new()
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)

	var name_label = Label.new()
	name_label.text = "%s x%d" % [item.get_display_name(), stock]
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hbox.add_child(name_label)
	vbox.add_child(hbox)

	var price_hbox = HBoxContainer.new()
	var gold_icon = TextureRect.new()
	gold_icon.custom_minimum_size = Vector2(16, 16)
	price_hbox.add_child(gold_icon)

	var price_label = Label.new()
	price_label.text = "Vender: %dg cada" % price
	price_hbox.add_child(price_label)
	vbox.add_child(price_hbox)

	var sell_btn = Button.new()
	sell_btn.text = "Vender"
	sell_btn.pressed.connect(_on_sell_clicked.bind(item, price, stock))
	vbox.add_child(sell_btn)

	slot.gui_input.connect(_on_slot_gui_input.bind(item, price, stock, false))
	parent.add_child(slot)

func _on_sell_clicked(item: ItemData, price: int, stock: int) -> void:
	selected_item = {"item": item, "price": price, "stock": stock}
	selected_item_data = item
	is_buying = false

	qty_spin.min_value = 1
	qty_spin.max_value = stock
	qty_spin.value = 1
	qty_label.text = "Vender: %s" % item.get_display_name()
	qty_buy_btn.visible = false
	qty_sell_btn.visible = true
	_update_quantity_total()
	quantity_dialog.popup_centered()

## ==================== FILTROS ====================
func _on_filter_pressed(category: String) -> void:
	if category == "all":
		active_filters = ["all"]
	else:
		active_filters = [category] if "all" not in active_filters else active_filters
		# Remove "all" se outro selecionado
		if "all" in active_filters and active_filters.size() > 1:
			active_filters.erase("all")

	# Atualiza botões
	for child in filter_buttons.get_children():
		if child is Button:
			child.button_pressed = child.text.to_lower() in active_filters

	_refresh_current_tab()

func _filter_items(items: Array, filters: Array) -> Array:
	if "all" in filters:
		return items
	var result = []
	for item in items:
		var item_id = item.get("ItemId", "")
		var item_data = DataLoader.get_item(item_id)
		if item_data and _item_matches_filter(item_data, filters):
			result.append(item)
	return result

func _filter_inventory_items(inventory: Dictionary, filters: Array) -> Array:
	var result = []
	for item_id in inventory:
		var item_data = DataLoader.get_item(item_id)
		if item_data and (_item_matches_filter(item_data, filters) or "all" in filters):
			result.append(item_id)
	return result

func _item_matches_filter(item: ItemData, filters: Array) -> bool:
	for f in filters:
		match f:
			"seeds": if item.is_seed(): return true
			"crops": if item.item_type in ["Vegetable", "Fruit", "Flower"]: return true
			"animal": if item.item_type in ["AnimalProduct", "Egg", "Milk"]: return true
			"artisan": if item.item_type in ["ArtisanGoods", "Wine", "Jelly", "Cheese"]: return true
			"minerals": if item.category in [-2, -12, -14, -16, -18, -20, -22]: return true
			"cooking": if item.is_cooking_ingredient: return true
			"tools": if item.is_tool(): return true
			"weapons": if item.is_weapon(): return true
			"furniture": if item.is_furniture(): return true
			"bait": if "bait" in item.internal_name.to_lower(): return true
			"tackle": if "tackle" in item.internal_name.to_lower() or "bobber" in item.internal_name.to_lower(): return true
	return false

func _refresh_current_tab() -> void:
	if mode == "buy":
		_populate_buy_tab()
	else:
		_populate_sell_tab()

## ==================== TABS ====================
func _on_tab_changed(new_mode: String) -> void:
	mode = new_mode
	buy_container.visible = (mode == "buy")
	sell_container.visible = (mode == "sell")
	_refresh_current_tab()

## ==================== TOOLTIP ====================
func _on_slot_gui_input(event: InputEvent, item: ItemData, price: int, stock: int, is_recipe: bool) -> void:
	if event is InputEventMouseMotion:
		_show_tooltip(item, price, stock, is_recipe, event.global_position)
	elif event is InputEventMouseButton and not event.pressed:
		_hide_tooltip()

func _show_tooltip(item: ItemData, price: int, stock: int, is_recipe: bool, pos: Vector2) -> void:
	tooltip_name.text = item.get_display_name()
	if is_recipe:
		tooltip_name.text += " [Receita]"
	tooltip_desc.text = item.description.replace("[LocalizedText ", "").replace("]", "")
	tooltip_price.text = "%dg" % price
	if stock > 0:
		tooltip_price.text += " | Estoque: %d" % stock
	elif stock == 0:
		tooltip_price.text += " | ESGOTADO"

	var quality_text = ""
	match item.max_quality:
		3: quality_text = "Normal → Prata → Ouro → Irídio"
		2: quality_text = "Normal → Prata → Ouro"
		1: quality_text = "Normal → Prata"
		0: quality_text = "Apenas Normal"
	tooltip_quality.text = "Qualidade: %s" % quality_text

	item_tooltip.global_position = pos + Vector2(20, 20)
	item_tooltip.visible = true

func _hide_tooltip() -> void:
	item_tooltip.visible = false

## ==================== QUANTIDADE ====================
func _on_confirm_quantity() -> void:
	var qty = int(qty_spin.value)
	if qty <= 0:
		return

	if is_buying:
		var item_id = selected_item["item"].internal_name
		var price = selected_item["price"]
		var total = price * qty

		if GameManager.spend_gold(total):
			InventoryManager.add_item("(%s)%s" % [selected_item["item"].internal_name], qty)
			# Registra compra
			var purchases = GameManager.get("shop_purchases", {})
			var shop_purchases = purchases.get(current_shop.shop_id, {})
			shop_purchases[selected_item["item"].internal_name] = shop_purchases.get(selected_item["item"].internal_name, 0) + qty
			purchases[current_shop.shop_id] = shop_purchases
			GameManager.set("shop_purchases", purchases)

			emit_signal("item_bought", item_id, qty, total)
			_populate_buy_tab()
			_update_gold()
	else:
		var item_id = selected_item_data.internal_name
		var price = _get_sell_price(selected_item_data, qty)
		InventoryManager.remove_item(item_id, qty)
		GameManager.add_gold(price)
		emit_signal("item_sold", item_id, qty, price)
		_populate_sell_tab()
		_update_gold()

	quantity_dialog.hide()

func _on_quantity_canceled() -> void:
	quantity_dialog.hide()

func _clear_container(container: GridContainer) -> void:
	for child in container.get_children():
		child.queue_free()

func _show_message(text: String) -> void:
	# TODO: Implementar sistema de mensagens toast
	print("SHOP: %s" % text)

## ==================== FECHAR ====================
func hide() -> void:
	visible = false
	_hide_tooltip()
	emit_signal("shop_closed")