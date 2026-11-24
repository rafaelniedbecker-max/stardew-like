class_name InventoryManager
extends Node

## Gerencia inventário, hotbar, crafting e ferramentas

## Capacidade máxima do inventário (slots)
@export var max_inventory_slots: int = 36

## Capacidade do hotbar
@export var hotbar_size: int = 12

## Tamanho máximo de stack por item (padrão, pode variar por item)
@export var default_max_stack: int = 999

## ==================== SINAIS ====================
signal inventory_changed()
signal hotbar_changed(slot: int, item_id: String)
signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)
signal tool_upgraded(tool_name: String, new_level: int)
signal recipe_crafted(recipe_name: String)
signal recipe_cooked(recipe_name: String)
signal cannot_carry_more(item_id: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Sincroniza com GameManager
	_sync_with_game_manager()

func _sync_with_game_manager() -> void:
	if GameManager:
		# Garante que inventário do GameManager é válido
		if GameManager.inventory == null:
			GameManager.inventory = {}
		if GameManager.hotbar.size() == 0:
			GameManager.hotbar = Array(hotbar_size).fill("")

## ==================== INVENTÁRIO PRINCIPAL ====================

## Obtém quantidade de um item no inventário
func get_item_count(item_id: String) -> int:
	return GameManager.inventory.get(item_id, 0)

## Adiciona item ao inventário
## Retorna quantidade efetivamente adicionada
func add_item(item_id: String, amount: int = 1) -> int:
	var max_stack = _get_max_stack(item_id)
	var current = GameManager.inventory.get(item_id, 0)
	var can_add = max_stack - current

	if can_add <= 0:
		emit_signal("cannot_carry_more", item_id)
		return 0

	var actual_add = min(amount, can_add)
	GameManager.inventory[item_id] = current + actual_add

	# Se excedeu, tenta criar novo stack
	if actual_add < amount:
		var remaining = amount - actual_add
		# Procura slot vazio ou cria novo
		# (simplificado: apenas retorna o que coube)
		pass

	emit_signal("inventory_changed")
	emit_signal("item_added", item_id, actual_add)
	return actual_add

## Remove item do inventário
## Retorna true se conseguiu remover tudo
func remove_item(item_id: String, amount: int = 1) -> bool:
	var current = GameManager.inventory.get(item_id, 0)
	if current < amount:
		return false

	var new_amount = current - amount
	if new_amount <= 0:
		GameManager.inventory.erase(item_id)
	else:
		GameManager.inventory[item_id] = new_amount

	emit_signal("inventory_changed")
	emit_signal("item_removed", item_id, amount)
	return true

## Verifica se tem item (quantidade suficiente)
func has_item(item_id: String, amount: int = 1) -> bool:
	return GameManager.inventory.get(item_id, 0) >= amount

## Verifica se tem espaço para item
func has_space_for(item_id: String, amount: int = 1) -> bool:
	var current = GameManager.inventory.get(item_id, 0)
	var max_stack = _get_max_stack(item_id)
	if current + amount <= max_stack:
		return true

	# Verifica slots vazios
	var used_slots = _count_used_slots()
	return used_slots < max_inventory_slots

## Obtém lista de todos os itens no inventário
func get_all_items() -> Array[Dictionary]:
	var result = []
	for item_id in GameManager.inventory:
		result.append({
			"item_id": item_id,
			"amount": GameManager.inventory[item_id],
			"max_stack": _get_max_stack(item_id)
		})
	return result

## Conta slots usados
func _count_used_slots() -> int:
	var count = 0
	for item_id in GameManager.inventory:
		var amount = GameManager.inventory[item_id]
		var max_stack = _get_max_stack(item_id)
		count += ceil(amount / max_stack)
	return count

## Obtém max stack de um item (consulta DataLoader)
func _get_max_stack(item_id: String) -> int:
	if DataLoader and DataLoader.get_item(item_id):
		# Itens têm stack padrão 999, exceto ferramentas/armas = 1
		var item = DataLoader.get_item(item_id)
		if item.is_tool() or item.is_weapon():
			return 1
		return default_max_stack
	return default_max_stack

## ==================== HOTBAR ====================

## Obtém item no slot do hotbar
func get_hotbar_item(slot: int) -> String:
	if slot >= 0 and slot < GameManager.hotbar.size():
		return GameManager.hotbar[slot]
	return ""

## Define item no slot do hotbar
func set_hotbar_item(slot: int, item_id: String) -> void:
	if slot >= 0 and slot < GameManager.hotbar.size():
		GameManager.hotbar[slot] = item_id
		emit_signal("hotbar_changed", slot, item_id)

## Troca dois slots do hotbar
func swap_hotbar_slots(slot_a: int, slot_b: int) -> void:
	if slot_a >= 0 and slot_a < GameManager.hotbar.size() and \
	   slot_b >= 0 and slot_b < GameManager.hotbar.size():
		var temp = GameManager.hotbar[slot_a]
		GameManager.hotbar[slot_a] = GameManager.hotbar[slot_b]
		GameManager.hotbar[slot_b] = temp
		emit_signal("hotbar_changed", slot_a, GameManager.hotbar[slot_a])
		emit_signal("hotbar_changed", slot_b, GameManager.hotbar[slot_b])

## Seleciona slot do hotbar
func select_hotbar_slot(slot: int) -> void:
	if slot >= 0 and slot < GameManager.hotbar.size():
		GameManager.selected_hotbar_slot = slot

## Obtém item atualmente selecionado
func get_selected_item() -> String:
	return get_hotbar_item(GameManager.selected_hotbar_slot)

## Move item do inventário para hotbar
func move_to_hotbar(item_id: String, slot: int) -> bool:
	if not has_item(item_id):
		return false
	if slot < 0 or slot >= hotbar_size:
		return false

	# Remove 1 do inventário (ou move stack inteiro se for ferramenta)
	var is_tool = DataLoader.get_item(item_id)?.is_tool() ?? false
	var amount = 1 if is_tool else GameManager.inventory[item_id]

	if remove_item(item_id, amount):
		set_hotbar_item(slot, item_id)
		return true
	return false

## Move item do hotbar para inventário
func move_from_hotbar(slot: int) -> bool:
	var item_id = get_hotbar_item(slot)
	if item_id == "":
		return false

	var is_tool = DataLoader.get_item(item_id)?.is_tool() ?? false
	var amount = 1 if is_tool else GameManager.inventory.get(item_id, 0)

	# Se stack cheio no inventário, não move
	if not has_space_for(item_id, amount):
		return false

	if add_item(item_id, amount):
		set_hotbar_item(slot, "")
		return true
	return false

## ==================== FERRAMENTAS ====================

## Obtém nível da ferramenta (0-3)
func get_tool_level(tool_name: String) -> int:
	return GameManager.tools.get(tool_name, 0)

## Upgrade de ferramenta
func upgrade_tool(tool_name: String) -> bool:
	var current = get_tool_level(tool_name)
	if current >= 3:  # Máximo Irídio
		return false

	GameManager.tools[tool_name] = current + 1
	emit_signal("tool_upgraded", tool_name, current + 1)
	return true

## Verifica se pode usar ferramenta (nível mínimo)
func can_use_tool(tool_name: String, required_level: int) -> bool:
	return get_tool_level(tool_name) >= required_level

## Obtém ferramenta equipada atualmente (baseado no hotbar)
func get_equipped_tool() -> String:
	var item_id = get_selected_item()
	if item_id != "" and DataLoader.get_item(item_id)?.is_tool():
		return item_id
	return ""

## ==================== CRAFTING ====================

## Verifica se pode craftar receita
func can_craft(recipe_name: String) -> bool:
	var recipe = DataLoader.get_recipe(recipe_name)
	if not recipe:
		return false

	# Verifica se receita desbloqueada
	if recipe_name not in GameManager.unlocked_recipes and not recipe.default_unlocked:
		return false

	# Verifica ingredientes
	return recipe.has_ingredients(GameManager.inventory)

## Crafta receita
func craft(recipe_name: String) -> bool:
	var recipe = DataLoader.get_recipe(recipe_name)
	if not recipe or not can_craft(recipe_name):
		return false

	recipe.consume_ingredients(GameManager.inventory)
	recipe.give_result(GameManager.inventory)

	GameManager.stats.items_crafted += 1
	emit_signal("inventory_changed")
	emit_signal("recipe_crafted", recipe_name)
	return true

## Obtém receitas disponíveis para crafting (filtradas por aba)
func get_available_recipes(tab: String = "") -> Array[RecipeData]:
	var result = []
	for recipe in DataLoader.get_crafting_recipes():
		if tab == "" or recipe.crafting_tab == tab:
			if can_craft(recipe.recipe_name):
				result.append(recipe)
	return result

## Obtém receitas por categoria
func get_recipes_by_category(category: String) -> Array[RecipeData]:
	var result = []
	for recipe in DataLoader.get_all_recipes():
		# Categoria baseada no tipo de resultado
		var result_item = DataLoader.get_item(recipe.result.item_id)
		if result_item and result_item.item_type == category:
			result.append(recipe)
	return result

## ==================== CULINÁRIA ====================

## Verifica se pode cozinhar receita
func can_cook(recipe_name: String) -> bool:
	var recipe = DataLoader.get_recipe(recipe_name)
	if not recipe or not recipe.is_cooking:
		return false

	if recipe_name not in GameManager.unlocked_cooking_recipes and not recipe.default_unlocked:
		return false

	return recipe.has_ingredients(GameManager.inventory)

## Cozinha receita
func cook(recipe_name: String) -> bool:
	var recipe = DataLoader.get_recipe(recipe_name)
	if not recipe or not can_cook(recipe_name):
		return false

	recipe.consume_ingredients(GameManager.inventory)
	recipe.give_result(GameManager.inventory)

	GameManager.stats.items_cooked += 1
	emit_signal("inventory_changed")
	emit_signal("recipe_cooked", recipe_name)
	return true

## Obtém receitas de culinária disponíveis
func get_available_cooking_recipes() -> Array[RecipeData]:
	var result = []
	for recipe in DataLoader.get_cooking_recipes():
		if can_cook(recipe.recipe_name):
			result.append(recipe)
	return result

## ==================== UTILIDADES ====================

## Limpa inventário (debug)
func clear_inventory() -> void:
	GameManager.inventory.clear()
	emit_signal("inventory_changed")

## Preenche inventário com item (debug)
func fill_with(item_id: String, amount: int = 999) -> void:
	GameManager.inventory[item_id] = amount
	emit_signal("inventory_changed")

## Ordena inventário (alfabético por ID)
func sort_inventory() -> void:
	var sorted = {}
	var keys = GameManager.inventory.keys()
	keys.sort()
	for k in keys:
		sorted[k] = GameManager.inventory[k]
	GameManager.inventory = sorted
	emit_signal("inventory_changed")

## Obtém peso total do inventário (para UI)
func get_inventory_weight() -> float:
	var weight = 0.0
	for item_id in GameManager.inventory:
		var item = DataLoader.get_item(item_id)
		# Peso simplificado: 1 por stack
		weight += 1.0
	return weight

## Verifica se inventário está cheio
func is_full() -> bool:
	return _count_used_slots() >= max_inventory_slots