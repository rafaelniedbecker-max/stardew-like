extends Control

## Menu de Culinária: receitas descobertas, ingredientes, qualidade

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var recipe_list: ItemList = $Panel/LeftSide/RecipeList
@onready var recipe_info: VBoxContainer = $Panel/RightSide/RecipeInfo
@onready var cook_button: Button = $Panel/RightSide/CookButton
@onready var ingredient_grid: GridContainer = $Panel/RightSide/Ingredients/IngredientGrid
@onready var search_box: LineEdit = $Panel/TopBar/SearchBox
@onready var filter_tabs: TabBar = $Panel/TopBar/FilterTabs
@onready var known_count_label: Label = $Panel/TopBar/KnownCountLabel

## Estado
var all_recipes: Array[Dictionary] = []
var filtered_recipes: Array[Dictionary] = []
var selected_recipe: Dictionary = {}
var current_filter: String = "all"  # all, cooking, baking, drinks, discovered, undiscovered

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	close_button.pressed.connect(hide)

	recipe_list.item_selected.connect(_on_recipe_selected)
	cook_button.pressed.connect(_on_cook_pressed)
	search_box.text_changed.connect(_on_search_changed)
	filter_tabs.tab_changed.connect(_on_filter_changed)

	_load_recipes()

func _load_recipes() -> void:
	all_recipes = []

	# Carrega receitas de culinária
	var cooking_data = DataLoader.get_all_recipes()
	for recipe in cooking_data:
		var r = recipe.duplicate()
		r.id = recipe.recipe_name
		r.category = "cooking"
		all_recipes.append(r)

	# Carrega receitas de artesanato que geram comida
	var crafting_data = DataLoader.get_all_crafting_recipes()
	for recipe in crafting_data:
		if recipe.get("Category", "").to_lower() in ["food", "cooking", "artisan"]:
			var r = recipe.duplicate()
			r.id = recipe.recipe_name
			r.category = "crafting"
			all_recipes.append(r)

	_apply_filters()

	# Atualiza contador
	var known = 0
	for r in all_recipes:
		if GameManager and r.id in GameManager.unlocked_cooking_recipes:
			known += 1
	known_count_label.text = "Conhecidas: %d/%d" % [known, all_recipes.size()]

func _apply_filters() -> void:
	filtered_recipes.clear()

	for recipe in all_recipes:
		var matches = true

		# Filtro de descoberta
		if current_filter == "discovered":
			matches = GameManager and recipe.id in GameManager.unlocked_cooking_recipes
		elif current_filter == "undiscovered":
			matches = not (GameManager and recipe.id in GameManager.unlocked_cooking_recipes)

		# Filtro de busca
		if matches and search_box.text != "":
			var search = search_box.text.to_lower()
			var name = recipe.get("DisplayName", recipe.get("Name", "")).to_lower()
			matches = search in name

		if matches:
			filtered_recipes.append(recipe)

	_populate_list()

func _populate_list() -> void:
	recipe_list.clear()

	for i in range(filtered_recipes.size()):
		var recipe = filtered_recipes[i]
		var name = recipe.get("DisplayName", recipe.get("Name", "Unknown"))
		var known = GameManager and recipe.id in GameManager.unlocked_cooking_recipes
		var prefix = "✓ " if known else "?? "
		recipe_list.add_item("%s%s" % [prefix, name])
		recipe_list.set_item_metadata(i, recipe.id)

		if not known:
			recipe_list.set_item_custom_fg_color(i, Color(0.5, 0.5, 0.5))

	known_count_label.text = "Conhecidas: %d/%d" % [get_known_count(), all_recipes.size()]

func get_known_count() -> int:
	var count = 0
	for r in all_recipes:
		if GameManager and r.id in GameManager.unlocked_cooking_recipes:
			count += 1
	return count

## ==================== INTERAÇÃO ====================
func _on_recipe_selected(index: int) -> void:
	if index < 0 or index >= filtered_recipes.size():
		return

	selected_recipe = filtered_recipes[index]
	_show_recipe_info(selected_recipe)

func _show_recipe_info(recipe: Dictionary) -> void:
	# Limpa info anterior
	for child in recipe_info.get_children():
		child.queue_free()
	for child in ingredient_grid.get_children():
		child.queue_free()

	var known = GameManager and recipe.id in GameManager.unlocked_cooking_recipes

	# Nome
	var name_label = Label.new()
	name_label.text = recipe.get("DisplayName", recipe.get("Name", "Unknown"))
	name_label.theme_override_font_size = 24
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_info.add_child(name_label)

	# Status descoberta
	var status_label = Label.new()
	if known:
		status_label.text = "🔓 Descoberta"
		status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	else:
		status_label.text = "🔒 Desconhecida"
		status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_info.add_child(status_label)

	# Descrição
	var desc = recipe.get("Description", "")
	if desc != "":
		var desc_label = Label.new()
		desc_label.text = desc
		desc_label.autowrap_mode = 1
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.theme_override_font_size = 14
		recipe_info.add_child(desc_label)

	# Ingredientes
	var ingredients = recipe.get("Ingredients", [])
	if ingredients:
		var ing_title = Label.new()
		ing_title.text = "Ingredientes:"
		ing_title.theme_override_font_size = 16
		recipe_info.add_child(ing_title)

		for ing in ingredients:
			var ing_id = ing.get("ItemId", "")
			var amount = ing.get("Count", 1)
			var item = DataLoader.get_item(ing_id)
			var item_name = item.display_name if item != null else ing_id

			var has_amount = InventoryManager and InventoryManager.get_item_count(ing_id) >= amount

			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 10)

			var icon = TextureRect.new()
			icon.custom_minimum_size = Vector2(32, 32)
			if item and item.texture_path != "":
				icon.texture = load(item.texture_path)
			hbox.add_child(icon)

			var name_lbl = Label.new()
			name_lbl.text = "%s x%d" % [item_name, amount]
			name_lbl.theme_override_font_size = 14
			if not has_amount:
				name_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			hbox.add_child(name_lbl)

			var have_lbl = Label.new()
			var have_count = InventoryManager.get_item_count(ing_id) if InventoryManager else 0
			have_lbl.text = "(%d)" % have_count
			have_lbl.theme_override_font_size = 12
			have_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			hbox.add_child(have_lbl)

			ingredient_grid.add_child(hbox)

	# Resultado
	var result_id = recipe.get("ResultItemId", recipe.get("Result", ""))
	var result_amount = recipe.get("ResultCount", 1)
	var result_item = DataLoader.get_item(result_id)
	if result_item:
		var result_title = Label.new()
		result_title.text = "Resultado:"
		result_title.theme_override_font_size = 16
		recipe_info.add_child(result_title)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		if result_item.texture_path != "":
			icon.texture = load(result_item.texture_path)
		hbox.add_child(icon)

		var name_lbl = Label.new()
		name_lbl.text = "%s x%d" % [result_item.display_name, result_amount]
		name_lbl.theme_override_font_size = 14
		hbox.add_child(name_lbl)

		# Buff info se tiver
		var buff = recipe.get("Buff", {})
		if buff:
			var buff_text = []
			for key in buff:
				if key != "Duration":
					buff_text.append("%s: %s" % [key, buff[key]])
			if buff_text:
				var buff_lbl = Label.new()
				buff_lbl.text = "Buff: " + ", ".join(buff_text)
				buff_lbl.theme_override_font_size = 12
				buff_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
				recipe_info.add_child(buff_lbl)

		recipe_info.add_child(hbox)

	# Atualiza botão cozinhar
	var can_cook = known and _check_ingredients(recipe)
	cook_button.disabled = not can_cook
	cook_button.text = "🍳 Cozinhar" if can_cook else "❌ Ingredientes insuficientes"

func _check_ingredients(recipe: Dictionary) -> bool:
	if not InventoryManager:
		return false

	var ingredients = recipe.get("Ingredients", [])
	for ing in ingredients:
		var ing_id = ing.get("ItemId", "")
		var amount = ing.get("Count", 1)
		if InventoryManager.get_item_count(ing_id) < amount:
			return false
	return true

func _on_cook_pressed() -> void:
	if not selected_recipe or not InventoryManager:
		return

	# Remove ingredientes
	var ingredients = selected_recipe.get("Ingredients", [])
	for ing in ingredients:
		var ing_id = ing.get("ItemId", "")
		var amount = ing.get("Count", 1)
		InventoryManager.remove_item(ing_id, amount)

	# Adiciona resultado
	var result_id = selected_recipe.get("ResultItemId", selected_recipe.get("Result", ""))
	var result_amount = selected_recipe.get("ResultCount", 1)
	var quality = _calculate_quality(selected_recipe)
	InventoryManager.add_item(result_id, result_amount, quality)

	# Experiência de culinária
	if GameManager:
		GameManager.add_skill_xp(3, 10)  # Foraging? No, cooking não tem skill própria
		GameManager.stats.items_cooked += 1

	# Notificação
	var result_item = DataLoader.get_item(result_id)
	HUD.show_notification("🍳 Cozinhado!", "%s x%d" % [result_item.display_name if result_item != null else result_id, result_amount], Color(1.0, 0.7, 0.3))

	# Partículas
	if ParticleManager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ParticleManager.show_level_up(player.global_position, "Cozinhado!")

	# Som
	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/cook.ogg")

	_refresh_recipe(selected_recipe)

func _calculate_quality(recipe: Dictionary) -> int:
	# Qualidade baseada em ingredientes + sorte + profissão
	var base_quality = 0
	var ingredients = recipe.get("Ingredients", [])

	for ing in ingredients:
		var ing_id = ing.get("ItemId", "")
		# Em implementação real, verifica qualidade média dos ingredientes no inventário
		pass

	var chance = 0.0
	chance += GameManager.daily_luck * 0.5 if GameManager else 0

	# Profissão Artisan (level 10 farming)
	if GameManager and GameManager.professions.get("Farming") == 1:
		chance += 0.2

	if chance > 0.9: return 3
	elif chance > 0.6: return 2
	elif chance > 0.3: return 1
	return 0

func _refresh_recipe(recipe: Dictionary) -> void:
	# Re-seleciona para atualizar contadores
	var idx = filtered_recipes.find(recipe)
	if idx >= 0:
		_on_recipe_selected(idx)

func _on_search_changed(text: String) -> void:
	_apply_filters()

func _on_filter_changed(tab_idx: int) -> void:
	var filters = ["all", "discovered", "undiscovered", "cooking", "baking", "drinks"]
	if tab_idx < filters.size():
		current_filter = filters[tab_idx]
		_apply_filters()

## ==================== PÚBLICO ====================
func open() -> void:
	visible = true
	panel.visible = true
	panel.position = (get_viewport_rect().size - panel.size) * 0.5
	_load_recipes()
	get_tree().paused = true

@warning_ignore("native_method_override")
func hide() -> void:
	visible = false
	panel.visible = false
	get_tree().paused = false