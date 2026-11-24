@tool
class_name ShopData
extends Resource

## ID da loja (chave do JSON)
@export var shop_id: String = ""

## Moeda: 0=Ouro, 1=Qi Gems, etc.
@export var currency: int = 0

## Modo de modificador de preço
@export var price_modifier_mode: int = 0

## Donos da loja (NPCs)
@export var owners: Array[Dictionary] = []

## Itens vendidos
@export var items: Array[Dictionary] = []

## Tags de itens vendíveis (para lojas dinâmicas)
@export var salable_item_tags: Array[String] = []

## Horário de funcionamento
@export var open_time: int = 900    # 9:00 AM
@export var close_time: int = 1700  # 5:00 PM

## Dias da semana aberto (0=Seg, 6=Dom, -1=Todos)
@export var open_days: Array[int] = [-1]

## Estações aberto (-1=Todos)
@export var open_seasons: Array[int] = [-1]

## Condição de disponibilidade (string de condição Stardew)
@export var availability_condition: String = ""

## Retorna nome da loja para UI
func get_shop_name() -> String:
	if owners.size() > 0:
		return owners[0].get("Name", shop_id)
	return shop_id

## Retorna diálogo do dono
func get_owner_dialogue() -> String:
	if owners.size() > 0:
		var dialogues = owners[0].get("Dialogues", [])
		if dialogues.size() > 0:
			var d = dialogues[0]
			if d.has("Dialogue"):
				return d["Dialogue"]
			if d.has("RandomDialogue"):
				var rand = d["RandomDialogue"]
				if rand is Array and rand.size() > 0:
					return rand[randi() % rand.size()]
	return ""

## Verifica se loja está aberta agora
func is_open(current_time: int, current_weekday: int, current_season: int) -> bool:
	# Verifica horário
	if current_time < open_time or current_time > close_time:
		return false

	# Verifica dia da semana
	if -1 not in open_days and current_weekday not in open_days:
		return false

	# Verifica estação
	if -1 not in open_seasons and current_season not in open_seasons:
		return false

	# TODO: Verificar availability_condition
	return true

## Obtém itens disponíveis para compra (filtrando estoque)
func get_available_items(item_database: Dictionary, player_data: Dictionary) -> Array[Dictionary]:
	var available = []
	for item in items:
		var stock = item.get("AvailableStock", -1)
		var limit = item.get("AvailableStockLimit", 0)

		# -1 = estoque infinito
		if stock == -1:
			available.append(item.duplicate(true))
			continue

		# Verifica limite diário
		if limit > 0:
			var bought_today = player_data.get("shop_purchases", {}).get(shop_id, {}).get(item.get("Id", ""), 0)
			if bought_today >= limit:
				continue

		available.append(item.duplicate(true))

	return available

## Obtém preço do item
func get_item_price(item: Dictionary, item_data: Dictionary) -> int:
	var price = item.get("Price", -1)
	if price == -1 and item_data != null:
		price = item_data.price
	return price

## Processa compra
func process_purchase(item: Dictionary, quantity: int, player_gold: int, player_inventory: Dictionary) -> Dictionary:
	var item_id = item.get("ItemId", "")
	var price = get_item_price(item, null)
	var total_cost = price * quantity

	if player_gold < total_cost:
		return {"success": false, "reason": "Not enough gold"}

	# Adiciona ao inventário
	player_inventory[item_id] = player_inventory.get(item_id, 0) + quantity

	# Registra compra
	var purchases = player_data.get("shop_purchases", {})
	var shop_purchases = purchases.get(shop_id, {})
	shop_purchases[item.get("Id", "")] = shop_purchases.get(item.get("Id", ""), 0) + quantity
	purchases[shop_id] = shop_purchases
	player_data["shop_purchases"] = purchases

	return {
		"success": true,
		"cost": total_cost,
		"item_id": item_id,
		"quantity": quantity
	}