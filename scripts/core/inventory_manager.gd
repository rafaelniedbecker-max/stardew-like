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

## ==================== QUALITY OF LIFE ====================

## Auto-organiza inventário: agrupa stacks, ordena por categoria
func auto_organize() -> void:
	var items = []
	for item_id in GameManager.inventory:
		var item = DataLoader.get_item(item_id)
		var amount = GameManager.inventory[item_id]
		var max_stack = _get_max_stack(item_id)

		# Divide em stacks se necessário
		var remaining = amount
		while remaining > 0:
			var stack_size = min(remaining, max_stack)
			items.append({
				"item_id": item_id,
				"amount": stack_size,
				"category": item?.category ?? -1,
				"sort_key": item?.internal_name ?? item_id
			})
			remaining -= stack_size

	# Ordena: categoria -> nome
	items.sort_custom(func(a, b):
		if a.category != b.category:
			return a.category < b.category
		return a.sort_key < b.sort_key
	)

	# Reconstrói inventário
	GameManager.inventory.clear()
	for entry in items:
		var id = entry.item_id
		GameManager.inventory[id] = GameManager.inventory.get(id, 0) + entry.amount

	emit_signal("inventory_changed")

## Ordena por: categoria, raridade, nome
func sort_by(sort_type: String) -> void:
	match sort_type:
		"category":
			auto_organize()
		"alphabetical":
			_sort_alphabetical()
		"quantity":
			_sort_by_quantity()
		"value":
			_sort_by_value()
		"rarity":
			_sort_by_rarity()

func _sort_alphabetical() -> void:
	var items = []
	for item_id in GameManager.inventory:
		var item = DataLoader.get_item(item_id)
		items.append({"id": item_id, "name": item?.display_name ?? item_id, "amount": GameManager.inventory[item_id]})
	items.sort_custom(func(a, b): return a.name < b.name)

	GameManager.inventory.clear()
	for entry in items:
		GameManager.inventory[entry.id] = entry.amount
	emit_signal("inventory_changed")

func _sort_by_quantity() -> void:
	var items = []
	for item_id in GameManager.inventory:
		items.append({"id": item_id, "amount": GameManager.inventory[item_id]})
	items.sort_custom(func(a, b): return b.amount < a.amount)  # Descending

	GameManager.inventory.clear()
	for entry in items:
		GameManager.inventory[entry.id] = entry.amount
	emit_signal("inventory_changed")

func _sort_by_value() -> void:
	var items = []
	for item_id in GameManager.inventory:
		var item = DataLoader.get_item(item_id)
		var value = (item?.price ?? 0) * GameManager.inventory[item_id]
		items.append({"id": item_id, "value": value})
	items.sort_custom(func(a, b): return b.value < a.value)

	GameManager.inventory.clear()
	for entry in items:
		GameManager.inventory[entry.id] = GameManager.inventory[entry.id]  # Mantém quantidade
	emit_signal("inventory_changed")

func _sort_by_rarity() -> void:
	# Qualidade: Irídio > Ouro > Prata > Normal (baseado no item_id pattern)
	# Simplificado: ordena por ID numérico decrescente (IDs maiores = mais raros geralmente)
	var items = []
	for item_id in GameManager.inventory:
		var num = item_id.trim_prefix("(").trim_suffix(")").split(")")[1].to_int() if ")" in item_id else 0
		items.append({"id": item_id, "rarity": num})
	items.sort_custom(func(a, b): return b.rarity < a.rarity)

	GameManager.inventory.clear()
	for entry in items:
		GameManager.inventory[entry.id] = GameManager.inventory[entry.id]
	emit_signal("inventory_changed")

## Compacta stacks: move itens parciais para completar stacks
func compact_stacks() -> void:
	var changed = false
	var items = GameManager.inventory.duplicate()

	for item_id in items:
		var amount = items[item_id]
		var max_stack = _get_max_stack(item_id)

		if amount >= max_stack:
			continue

		# Procura outro stack do mesmo item para combinar
		# (No sistema simplificado, já é um único stack por item_id)
		# Em sistema real com múltiplos slots, procuraria slots parciais

	pass

## Move item para baú se estiver perto de um
func try_store_in_nearby_chest(item_id: String, amount: int, player_pos: Vector2, range: float = 128.0) -> int:
	if not BuildingManager:
		return 0

	var stored = 0
	var remaining = amount

	for building in BuildingManager.get_all_buildings():
		if building.global_position.distance_to(player_pos) > range:
			continue

		if building.building_type in ["Chest", "BigChest", "Fridge", "ShippingBin"]:
			var chest = building.get_chest("main") or building.get_chest("0")
			if chest:
				var space = chest.capacity - _count_chest_items(chest)
				if space <= 0:
					continue

				var to_store = min(remaining, space, chest.capacity)
				# Adiciona ao baú
				var current = chest.items.get(item_id, 0)
				var can_add = min(to_store, chest.capacity - current)
				if can_add > 0:
					chest.items[item_id] = current + can_add
					stored += can_add
					remaining -= can_add
					changed = true

					if remaining <= 0:
						break

	if stored > 0 and InventoryManager:
		InventoryManager.remove_item(item_id, stored)
		emit_signal("inventory_changed")
		HUD.show_message("Guardado %d %s no baú próximo" % [stored, DataLoader.get_item(item_id)?.display_name ?? item_id])

	return stored

func _count_chest_items(chest: Dictionary) -> int:
	var count = 0
	for amt in chest.items.values():
		count += amt
	return count

## Filtra itens por categoria para UI
func get_items_by_category(category: int) -> Array[Dictionary]:
	var result = []
	for item_id in GameManager.inventory:
		var item = DataLoader.get_item(item_id)
		if item and item.category == category:
			result.append({
				"item_id": item_id,
				"amount": GameManager.inventory[item_id],
				"item": item
			})
	return result

## Busca itens por nome (para UI de busca)
func search_items(query: String) -> Array[Dictionary]:
	var result = []
	query = query.to_lower()
	for item_id in GameManager.inventory:
		var item = DataLoader.get_item(item_id)
		if item and (query in item.display_name.to_lower() or query in item.internal_name.to_lower()):
			result.append({
				"item_id": item_id,
				"amount": GameManager.inventory[item_id],
				"item": item
			})
	return result

## Obtém itens vendáveis (para shipping bin)
func get_sellable_items() -> Array[Dictionary]:
	var result = []
	for item_id in GameManager.inventory:
		var item = DataLoader.get_item(item_id)
		if item and item.price > 0 and not item.is_tool() and not item.is_weapon():
			result.append({
				"item_id": item_id,
				"amount": GameManager.inventory[item_id],
				"quality": 0,  # Simplificado
				"price": item.price
			})
	return result

## Obtém ingredientes de culinária no inventário
func get_cooking_ingredients() -> Array[Dictionary]:
	var result = []
	for item_id in GameManager.inventory:
		var item = DataLoader.get_item(item_id)
		if item and (item.category in [-75, -79, -74, -76, -4, -81, -80] or item.is_cooking_ingredient):
			result.append({
				"item_id": item_id,
				"amount": GameManager.inventory[item_id],
				"item": item
			})
	return result

## Obtém itens para grange display
func get_all_items_for_grange() -> Array[Dictionary]:
	var result = []
	for item_id in GameManager.inventory:
		var item = DataLoader.get_item(item_id)
		if item and item.price > 0:
			# Adiciona cada qualidade separadamente
			result.append({
				"item_id": item_id,
				"quality": 0,
				"amount": GameManager.inventory[item_id]
			})
	return result

## Abre modo de seleção para Seed Maker
func open_seed_maker_mode(seed_maker: Node, panel: Panel) -> void:
	_open_item_selector(panel, "seed_maker", func(item_id: String):
		seed_maker.processing_item = item_id
		seed_maker._open_ui()
		panel.queue_free()
	)

## Abre modo de seleção para Preserves Jar
func open_preserves_jar_mode(jar: Node, panel: Panel) -> void:
	_open_item_selector(panel, "preserves_jar", func(item_id: String):
		jar.processing_item = item_id
		jar.processing_quality = 0
		jar._open_ui()
		panel.queue_free()
	)

## Abre modo de seleção para presente
func open_gift_mode(npc_name: String, panel: Panel) -> void:
	_open_item_selector(panel, "gift", func(item_id: String):
		# Procura NPC e dá presente
		var npcs = get_tree().get_nodes_in_group("npc")
		for n in npcs:
			if n.npc_name == npc_name:
				n.give_gift(item_id)
				break
		panel.queue_free()
	)

## Abre modo de seleção para Grange
func open_grange_mode(slot_index: int, slot_button: Button) -> void:
	_open_item_selector(get_tree().root.get_child(0), "grange", func(item_id: String):
		# Define item no slot
		var item = DataLoader.get_item(item_id)
		if item:
			slot_button.set("item_id", item_id)
			slot_button.set("quality", 0)
			slot_button.set("amount", 1)
			# Atualiza visual
			var icon = slot_button.get_node_or_null("Icon")
			if icon and item.texture_path != "":
				icon.texture = load(item.texture_path)
			var name = slot_button.get_node_or_null("Name")
			if name:
				name.text = item.display_name
			var qual = slot_button.get_node_or_null("Quality")
			if qual:
				qual.text = ""
			# Atualiza pontuação
			if FestivalMinigames:
				FestivalMinigames._update_grange_score(FestivalMinigames._get_current_slots(), FestivalMinigames._get_current_score_label())
	)

## Seletor genérico de itens
func _open_item_selector(parent: Node, mode: String, callback: Callable) -> void:
	var panel = Panel.new()
	panel.name = "ItemSelector_%s" % mode
	panel.anchors_preset = 15
	panel.offset_left = 100
	panel.offset_top = 50
	panel.offset_right = -100
	panel.offset_bottom = -50

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	var titles = {
		"seed_maker": "🌱 Escolher Item para Seed Maker",
		"preserves_jar": "🫙 Escolher Item para Preserves Jar",
		"gift": "🎁 Escolher Presente",
		"grange": "🏆 Escolher Item para Exposição"
	}
	title.text = titles.get(mode, "Escolher Item")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 20
	vbox.add_child(title)

	var search = LineEdit.new()
	search.placeholder_text = "Buscar..."
	search.text_changed.connect(func(text): _filter_selector_grid(grid, text))
	vbox.add_child(search)

	var scroll = ScrollContainer.new()
	var grid = GridContainer.new()
	grid.columns = 8
	grid.theme_override_constants/h_separation = 5
	grid.theme_override_constants/v_separation = 5
	scroll.add_child(grid)
	scroll.custom_minimum_size = Vector2(0, 300)
	vbox.add_child(scroll)

	# Filtra itens baseado no modo
	var items = _get_selector_items(mode)
	_populate_selector_grid(grid, items, callback)

	var close_btn = Button.new()
	close_btn.text = "Cancelar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	parent.add_child(panel)

func _get_selector_items(mode: String) -> Array[Dictionary]:
	var result = []

	for item_id in GameManager.inventory:
		var item = DataLoader.get_item(item_id)
		if not item:
			continue

		var allowed = false
		match mode:
			"seed_maker":
				allowed = item.category in [-75, -79, -74, -76]  # Frutas/vegetais
			"preserves_jar":
				allowed = item.category in [-75, -79, -74, -76, -4, -81, -80]  # Frutas, veg, peixes, forrageados
			"gift":
				allowed = true  # Qualquer item
			"grange":
				allowed = item.price > 0
			_: allowed = true

		if allowed:
			result.append({
				"item_id": item_id,
				"amount": GameManager.inventory[item_id],
				"item": item
			})

	return result

func _populate_selector_grid(grid: GridContainer, items: Array[Dictionary], callback: Callable) -> void:
	for child in grid.get_children():
		child.queue_free()

	for entry in items:
		var item_id = entry.item_id
		var amount = entry.amount
		var item = entry.item

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(70, 70)
		btn.flat = true

		var vbox = VBoxContainer.new()
		vbox.anchors_preset = 15
		btn.add_child(vbox)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		if item.texture_path != "":
			icon.texture = load(item.texture_path)
		vbox.add_child(icon)

		var name = Label.new()
		name.text = item.display_name
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.theme_override_font_size = 10
		name.autowrap_mode = 1
		vbox.add_child(name)

		var qty = Label.new()
		qty.text = "x%d" % amount
		qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty.theme_override_font_size = 9
		vbox.add_child(qty)

		btn.pressed.connect(callback.bind(item_id))
		grid.add_child(btn)

func _filter_selector_grid(grid: GridContainer, text: String) -> void:
	text = text.to_lower()
	for child in grid.get_children():
		if child is Button:
			var name_label = child.get_node_or_null("VBoxContainer/Label")
			if name_label:
				var visible = text == "" or text in name_label.text.to_lower()
				child.visible = visible