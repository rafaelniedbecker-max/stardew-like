class_name TravelingCart
extends Node

## Carrinho Viajante - aparece Sexta e Domingo na Cindersap Forest

@export var cart_scene: PackedScene

## Estado
var is_active: bool = false
var current_stock: Array[Dictionary] = []
var cart_instance: Node2D = null

## Itens especiais (raros, sazonais, etc.)
const SPECIAL_ITEMS = {
	# Sementes raras
	"rare_seeds": ["(O)114", "(O)485", "(O)489", "(O)494"],  # Ancient, Starfruit, Pumpkin, Cranberry

	# Artefatos
	"artifacts": ["(O)100", "(O)102", "(O)104", "(O)106", "(O)108", "(O)110", "(O)112"],

	# Minerais
	"minerals": ["(O)80", "(O)82", "(O)84", "(O)86", "(O)88"],  # Diamante, Prismatic, etc.

	# Itens de cozinha
	"cooking": ["(O)208", "(O)210", "(O)212", "(O)214"],

	# Móveis raros
	"furniture": ["(O)1200", "(O)1202", "(O)1204", "(O)1206"],

	# Chapéus/roupas
	"hats": ["(O)380", "(O)382", "(O)384", "(O)386"],
}

## ==================== SINAIS ====================
signal cart_arrived()
signal cart_left()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

	# Verifica se hoje tem carrinho
	_check_cart_today()

func _on_day_changed(day: int, season: int, year: int) -> void:
	_check_cart_today()

func _check_cart_today() -> void:
	if not GameManager:
		return

	# Sexta (5) e Domingo (0)
	var weekday = GameManager.current_weekday
	var should_be_active = (weekday == 5 or weekday == 0)

	if should_be_active and not is_active:
		_spawn_cart()
	elif not should_be_active and is_active:
		_despawn_cart()

func _spawn_cart() -> void:
	is_active = true

	# Gera estoque aleatório
	_generate_stock()

	# Spawna o carrinho na Cindersap Forest (posição fixa)
	if cart_scene:
		cart_instance = cart_scene.instantiate()
		cart_instance.name = "TravelingCart"
		cart_instance.global_position = Vector2(1200, 400)  # Posição aproximada
		get_tree().root.get_child(0).add_child(cart_instance)

		# Preenche visual
		_fill_cart_visual()

	emit_signal("cart_arrived")
	HUD.show_notification("🛒 Carrinho Viajante!", "O carrinho chegou na Cindersap Forest! (Aberto 6h-20h)", Color(0.5, 1.0, 0.8))

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/cart_arrive.ogg")

func _despawn_cart() -> void:
	is_active = false

	if cart_instance:
		cart_instance.queue_free()
		cart_instance = null

	emit_signal("cart_left")

func _generate_stock() -> void:
	current_stock.clear()

	# Sempre tem 10 slots
	var slots = 10

	# 1-2 sementes raras
	var rare_seeds_count = randi_range(1, 2)
	for i in range(rare_seeds_count):
		var item = SPECIAL_ITEMS["rare_seeds"].pick_random()
		_add_stock_item(item, 1, randi_range(1, 3))

	# 1-2 artefatos
	var artifact_count = randi_range(1, 2)
	for i in range(artifact_count):
		var item = SPECIAL_ITEMS["artifacts"].pick_random()
		_add_stock_item(item, 1, randi_range(1, 2))

	# 1 mineral
	var item = SPECIAL_ITEMS["minerals"].pick_random()
	_add_stock_item(item, 1, 1)

	# Preenche resto com itens aleatórios do jogo
	var all_items = DataLoader.get_all_items()
	var fill_count = slots - current_stock.size()
	for i in range(fill_count):
		var random_item = all_items.pick_random()
		if random_item.category in [-75, -79, -74, -76, -4, -81, -80]:  # Frutas, veg, peixes, forrageados
			_add_stock_item(random_item.id, randi_range(1, 5), randi_range(1, 10))

	# Embaralha
	current_stock.shuffle()

func _add_stock_item(item_id: String, base_price_mult: int = 1, max_quantity: int = 1) -> void:
	var item = DataLoader.get_item(item_id)
	if not item:
		return

	var price = int(item.price * base_price_mult * randf_range(1.0, 2.5))
	var quantity = randi_range(1, max_quantity)

	current_stock.append({
		"item_id": item_id,
		"price": price,
		"quantity": quantity,
		"max_quantity": quantity
	})

func _fill_cart_visual() -> void:
	if not cart_instance:
		return

	# Encontra container de slots no carrinho
	var slots_container = cart_instance.get_node_or_null("SlotsContainer")
	if not slots_container:
		return

	for child in slots_container.get_children():
		child.queue_free()

	for i, stock in enumerate(current_stock):
		if i >= slots_container.get_child_count():
			break

		var slot = _create_stock_slot(stock)
		slots_container.add_child(slot)

func _create_stock_slot(stock: Dictionary) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 100)
	btn.flat = true

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	btn.add_child(vbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	var item = DataLoader.get_item(stock.item_id)
	if item and item.texture_path != "":
		icon.texture = load(item.texture_path)
	vbox.add_child(icon)

	var name = Label.new()
	name.text = item?.display_name ?? stock.item_id
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.theme_override_font_size = 11
	name.autowrap_mode = 1
	vbox.add_child(name)

	var qty = Label.new()
	qty.text = "x%d" % stock.quantity
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty.theme_override_font_size = 10
	vbox.add_child(qty)

	var price = Label.new()
	price.text = "%dg" % stock.price
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.theme_override_font_size = 12
	price.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	vbox.add_child(price)

	btn.pressed.connect(_buy_item.bind(stock, btn))
	return btn

func _buy_item(stock: Dictionary, btn: Button) -> void:
	if stock.quantity <= 0:
		return

	if GameManager.gold < stock.price:
		HUD.show_message("Ouro insuficiente! Precisa de %dg" % stock.price)
		return

	GameManager.gold -= stock.price
	GameManager.emit_signal("gold_changed", GameManager.gold)

	if InventoryManager.add_item(stock.item_id, 1):
		stock.quantity -= 1

		if stock.quantity <= 0:
			stock.quantity = 0
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		if AudioManager:
			AudioManager.play_sfx("res://assets/sfx/buy.ogg")

		HUD.show_message("Comprado: %s por %dg" % [DataLoader.get_item(stock.item_id)?.display_name ?? stock.item_id, stock.price])

		# Atualiza visual
		var qty_label = btn.get_node_or_null("VBoxContainer/Label[1]")
		if qty_label:
			qty_label.text = "x%d" % stock.quantity
	else:
		GameManager.gold += stock.price  # Reembolsa
		HUD.show_message("Inventário cheio!")

## ==================== VERIFICAÇÃO DE HORÁRIO ====================
func is_open() -> bool:
	if not is_active:
		return false

	# Aberto 6h-20h
	if GameManager:
		return GameManager.current_time >= 600 and GameManager.current_time <= 2000
	return false

## ==================== PERSISTÊNCIA ====================
func get_save_data() -> Dictionary:
	return {
		"is_active": is_active,
		"current_stock": current_stock
	}

func load_save_data(data: Dictionary) -> void:
	is_active = data.get("is_active", false)
	current_stock = data.get("current_stock", [])

	if is_active:
		_spawn_cart()