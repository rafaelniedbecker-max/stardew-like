class_name CraftingMenu
extends Control

## Menu de Crafting e Culinária completo com abas, busca, categorias, favoritos

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var tabs: TabContainer = $Panel/TabContainer
@onready var craft_tab: Control = $Panel/TabContainer/CraftTab
@onready var cook_tab: Control = $Panel/TabContainer/CookTab
@onready var craft_grid: GridContainer = $Panel/TabContainer/CraftTab/ScrollContainer/GridContainer
@onready var cook_grid: GridContainer = $Panel/TabContainer/CookTab/ScrollContainer/GridContainer
@onready var search_box: LineEdit = $Panel/TopBar/SearchBox
@onready var category_bar: HBoxContainer = $Panel/CategoryBar/HBoxContainer
@onready var recipe_details: Panel = $Panel/RecipeDetails
@onready var detail_icon: TextureRect = $Panel/RecipeDetails/Icon
@onready var detail_name: Label = $Panel/RecipeDetails/NameLabel
@onready var detail_desc: Label = $Panel/RecipeDetails/DescLabel
@onready var detail_ingredients: VBoxContainer = $Panel/RecipeDetails/IngredientsContainer
@onready var detail_result: HBoxContainer = $Panel/RecipeDetails/ResultContainer
@onready var craft_button: Button = $Panel/RecipeDetails/CraftButton
@onready var favorite_button: Button = $Panel/RecipeDetails/FavoriteButton
@onready var gold_label: Label = $Panel/TopBar/GoldLabel

## Estado
var mode: String = "craft"  # "craft" ou "cook"
var active_category: String = "all"
var search_text: String = ""
var selected_recipe: RecipeData = null
var available_recipes: Array[RecipeData] = []
var favorite_recipes: Array[String] = []

## Categorias de crafting
const CRAFT_CATEGORIES = [
	{"id": "all", "name": "Todos", "icon": "📦"},
	{"id": "tools", "name": "Ferramentas", "icon": "⛏️"},
	{"id": "farming", "name": "Agricultura", "icon": "🌱"},
	{"id": "mining", "name": "Mineração", "icon": "⛏️"},
	{"id": "foraging", "name": "Coleta", "icon": "🌲"},
	{"id": "fishing", "name": "Pesca", "icon": "🎣"},
	{"id": "combat", "name": "Combate", "icon": "⚔️"},
	{"id": "furniture", "name": "Móveis", "icon": "🪑"},
	{"id": "floors", "name": "Pisos", "icon": "🟫"},
	{"id": "walls", "name": "Paredes", "icon": "🧱"},
	{"id": "machines", "name": "Máquinas", "icon": "⚙️"},
	{"id": "bombs", "name": "Bombas", "icon": "💣"},
	{"id": "fertilizer", "name": "Fertilizantes", "icon": "🧪"},
	{"id": "seeds", "name": "Sementes", "icon": "🌱"},
	{"id": "totems", "name": "Totens", "icon": "🗿"},
	{"id": "rings", "name": "Anéis", "icon": "💍"},
	{"id": "other", "name": "Outros", "icon": "📦"}
]

const COOK_CATEGORIES = [
	{"id": "all", "name": "Todos", "icon": "🍳"},
	{"id": "salads", "name": "Saladas", "icon": "🥗"},
	{"id": "soups", "name": "Sopas", "icon": "🍲"},
	{"id": "mains", "name": "Pratos Principais", "icon": "🍖"},
	{"id": "desserts", "name": "Sobremesas", "icon": "🍰"},
	{"id": "drinks", "name": "Bebidas", "icon": "🥤"},
	{"id": "snacks", "name": "Lanches", "icon": "🍪"},
	{"id": "buffs", "name": "Buffs", "icon": "✨"},
	{"id": "qi", "name": "Qi Seasonal", "icon": "🧙"}
]

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	recipe_details.visible = false
	close_button.pressed.connect(hide)
	search_box.text_changed.connect(_on_search_changed)
	craft_button.pressed.connect(_on_craft_clicked)
	favorite_button.pressed.connect(_toggle_favorite)

	tabs.tab_changed.connect(_on_tab_changed)

	_setup_category_buttons()
	_load_favorites()

func _setup_category_buttons() -> void:
	# Craft categories
	var craft_cats = HBoxContainer.new()
	craft_cats.name = "CraftCategories"
	craft_cats.theme_override_constants/separation = 3

	for cat in CRAFT_CATEGORIES:
		var btn = Button.new()
		btn.text = cat.icon
		btn.tooltip_text = cat.name
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(36, 36)
		btn.pressed.connect(_on_category_selected.bind(cat.id))
		craft_cats.add_child(btn)

	category_bar.add_child(craft_cats)

	# Cook categories (inicialmente escondido)
	var cook_cats = HBoxContainer.new()
	cook_cats.name = "CookCategories"
	cook_cats.theme_override_constants/separation = 3
	cook_cats.visible = false

	for cat in COOK_CATEGORIES:
		var btn = Button.new()
		btn.text = cat.icon
		btn.tooltip_text = cat.name
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(36, 36)
		btn.pressed.connect(_on_category_selected.bind(cat.id))
		cook_cats.add_child(btn)

	category_bar.add_child(cook_cats)

	# Seleciona "Todos" por padrão
	if craft_cats.get_child_count() > 0:
		craft_cats.get_child(0).button_pressed = true

func _load_favorites() -> void:
	if GameManager:
		favorite_recipes = GameManager.get("favorite_recipes", [])

func _save_favorites() -> void:
	if GameManager:
		GameManager.set("favorite_recipes", favorite_recipes)

## ==================== ABRIR MENU ====================
func open_menu(start_mode: String = "craft") -> void:
	mode = start_mode
	visible = true
	panel.visible = true
	popup_centered()
	_get_tree().paused = true

	if mode == "craft":
		tabs.get_child(0).button_pressed = true  # CraftTab
		_on_tab_changed(0)
	else:
		tabs.get_child(1).button_pressed = true  # CookTab
		_on_tab_changed(1)

	_update_gold()
	_refresh_recipes()
	_refresh_categories()
	grab_focus()

func _update_gold() -> void:
	if GameManager:
		gold_label.text = "%dg" % GameManager.gold

## ==================== TABS ====================
func _on_tab_changed(tab_idx: int) -> void:
	mode = "craft" if tab_idx == 0 else "cook"
	craft_tab.visible = (mode == "craft")
	cook_tab.visible = (mode == "cook")

	# Atualiza categorias visíveis
	var craft_cats = category_bar.get_node_or_null("CraftCategories")
	var cook_cats = category_bar.get_node_or_null("CookCategories")
	if craft_cats: craft_cats.visible = (mode == "craft")
	if cook_cats: cook_cats.visible = (mode == "cook")

	recipe_details.visible = false
	selected_recipe = null
	active_category = "all"

	# Reset category buttons
	_reset_category_buttons()
	_refresh_recipes()
	_refresh_categories()

func _reset_category_buttons() -> void:
	var cats = category_bar.get_node_or_null(mode == "craft" ? "CraftCategories" : "CookCategories")
	if cats:
		for child in cats.get_children():
			if child is Button:
				child.button_pressed = (child.get("category_id", "") == "all")

func _on_category_selected(category: String) -> void:
	active_category = category
	# Atualiza botões
	var cats = category_bar.get_node_or_null(mode == "craft" ? "CraftCategories" : "CookCategories")
	if cats:
		for child in cats.get_children():
			if child is Button:
				child.button_pressed = (child.get("category_id", "") == category)
	_refresh_recipes()

func _on_search_changed(text: String) -> void:
	search_text = text.to_lower()
	_refresh_recipes()

## ==================== RECEITAS ====================
func _refresh_recipes() -> void:
	available_recipes.clear()

	if mode == "craft":
		# Receitas de crafting
		for recipe in DataLoader.get_all_crafting_recipes():
			if not _recipe_available(recipe):
				continue

			if active_category != "all" and not _matches_craft_category(recipe, active_category):
				continue

			if search_text != "" and not _matches_search(recipe, search_text):
				continue

			available_recipes.append(recipe)
	else:
		# Receitas de culinária
		for recipe in DataLoader.get_all_cooking_recipes():
			if not _recipe_available(recipe):
				continue

			if active_category != "all" and not _matches_cook_category(recipe, active_category):
				continue

			if search_text != "" and not _matches_search(recipe, search_text):
				continue

			available_recipes.append(recipe)

	_populate_grid()

func _recipe_available(recipe: RecipeData) -> bool:
	# Verifica se receita está desbloqueada
	if GameManager:
		if mode == "craft":
			return recipe.recipe_name in GameManager.unlocked_recipes or recipe.default_unlocked
		else:
			return recipe.recipe_name in GameManager.unlocked_cooking_recipes or recipe.default_unlocked
	return recipe.default_unlocked

func _matches_craft_category(recipe: RecipeData, category: String) -> bool:
	var result_item = DataLoader.get_item(recipe.result.item_id)
	if not result_item:
		return false

	match category:
		"tools": return result_item.is_tool()
		"farming": return result_item.category in [-75, -79, -74, -76]  # Seeds/Vegetables
		"mining": return result_item.category in [-2, -3]  # Minerals/Ores
		"foraging": return result_item.category in [-81, -80]  # Forage
		"fishing": return result_item.category == -4  # Fish
		"combat": return result_item.is_weapon() or result_item.category == -1  # Weapons/Boots
		"furniture": return result_item.category == -9
		"floors": return result_item.category == -11
		"walls": return result_item.category == -12
		"machines": return "Machine" in result_item.item_type
		"bombs": return "Bomb" in result_item.item_type
		"fertilizer": return "Fertilizer" in result_item.item_type
		"seeds": return result_item.category in [-75, -79]
		"totems": return "Totem" in result_item.item_type
		"rings": return result_item.category == -5  # Rings
	return true

func _matches_cook_category(recipe: RecipeData, category: String) -> bool:
	var result_item = DataLoader.get_item(recipe.result.item_id)
	if not result_item:
		return false

	# Baseado no tipo de receita/buff
	var buff = recipe.get("Buff", {})
	var has_buff = buff.size() > 0

	match category:
		"salads": return "Salad" in result_item.display_name
		"soups": return "Soup" in result_item.display_name or "Stew" in result_item.display_name
		"mains": return not has_buff and not _matches_cook_category(recipe, "salads") and not _matches_cook_category(recipe, "desserts") and not _matches_cook_category(recipe, "snacks")
		"desserts": return "Cake" in result_item.display_name or "Pie" in result_item.display_name or "Cookie" in result_item.display_name or "Ice Cream" in result_item.display_name
		"drinks": return result_item.is_drink or "Juice" in result_item.display_name or "Wine" in result_item.display_name or "Beer" in result_item.display_name or "Coffee" in result_item.display_name
		"snacks": return "Snack" in result_item.item_type or "Fried" in result_item.display_name
		"buffs": return has_buff
		"qi": return "Qi" in result_item.display_name
	return true

func _matches_search(recipe: RecipeData, search: String) -> bool:
	var name = recipe.result.item.display_name if recipe.result.item else recipe.recipe_name
	return search in name.to_lower() or search in recipe.recipe_name.to_lower()

func _populate_grid() -> void:
	var grid = craft_grid if mode == "craft" else cook_grid
	grid.clear()

	for recipe in available_recipes:
		var btn = _create_recipe_button(recipe)
		grid.add_child(btn)

func _create_recipe_button(recipe: RecipeData) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 80)
	btn.flat = true

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	btn.add_child(vbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	var result_item = DataLoader.get_item(recipe.result.item_id)
	if result_item and result_item.texture_path != "":
		icon.texture = load(result_item.texture_path)
	vbox.add_child(icon)

	var name = Label.new()
	name.text = result_item?.display_name ?? recipe.recipe_name
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.theme_override_font_size = 10
	name.autowrap_mode = 1
	vbox.add_child(name)

	# Favorito
	var is_fav = recipe.recipe_name in favorite_recipes
	var fav_icon = TextureRect.new()
	fav_icon.custom_minimum_size = Vector2(16, 16)
	var fav_img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	fav_img.fill(Color(0,0,0,0))
	for x in range(16):
		for y in range(16):
			if abs(x-8) + abs(y-8) < 8:
				fav_img.set_pixel(x, y, is_fav ? Color(1.0, 0.85, 0.2) : Color(0.5, 0.5, 0.5))
	fav_icon.texture = ImageTexture.create_from_image(fav_img)
	fav_icon.custom_minimum_size = Vector2(16, 16)
	vbox.add_child(fav_icon)

	btn.pressed.connect(_on_recipe_selected.bind(recipe))
	return btn

## ==================== SELEÇÃO DE RECEITA ====================
func _on_recipe_selected(recipe: RecipeData) -> void:
	selected_recipe = recipe
	_show_recipe_details(recipe)

func _show_recipe_details(recipe: RecipeData) -> void:
	recipe_details.visible = true

	var result_item = DataLoader.get_item(recipe.result.item_id)

	# Ícone
	if result_item and result_item.texture_path != "":
		detail_icon.texture = load(result_item.texture_path)
	detail_icon.visible = true

	# Nome
	detail_name.text = result_item?.display_name ?? recipe.recipe_name

	# Descrição
	detail_desc.text = recipe.description
	detail_desc.autowrap_mode = 1

	# Ingredientes
	for child in detail_ingredients.get_children():
		child.queue_free()

	var ingredients = recipe.ingredients
	for ing in ingredients:
		var item_id = ing.item_id
		var count = ing.count
		var item = DataLoader.get_item(item_id)

		var hbox = HBoxContainer.new()
		hbox.theme_override_constants/separation = 10

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		if item and item.texture_path != "":
			icon.texture = load(item.texture_path)
		hbox.add_child(icon)

		var has = InventoryManager and InventoryManager.get_item_count(item_id) >= count
		var name_lbl = Label.new()
		name_lbl.text = "%s x%d" % [item?.display_name ?? item_id, count]
		name_lbl.theme_override_font_size = 12
		if not has:
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		hbox.add_child(name_lbl)

		var have_lbl = Label.new()
		var have_count = InventoryManager ? InventoryManager.get_item_count(item_id) : 0
		have_lbl.text = "(%d)" % have_count
		have_lbl.theme_override_font_size = 11
		have_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		hbox.add_child(have_lbl)

		detail_ingredients.add_child(hbox)

	# Resultado
	for child in detail_result.get_children():
		child.queue_free()

	if result_item:
		var hbox = HBoxContainer.new()
		hbox.theme_override_constants/separation = 10

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		if result_item.texture_path != "":
			icon.texture = load(result_item.texture_path)
		hbox.add_child(icon)

		var name_lbl = Label.new()
		name_lbl.text = "%s x%d" % [result_item.display_name, recipe.result.amount]
		name_lbl.theme_override_font_size = 13
		hbox.add_child(name_lbl)

		detail_result.add_child(hbox)

	# Buff info
	var buff = recipe.get("Buff", {})
	if buff:
		for child in detail_result.get_children():
			if child is Label and child.text.begins_with("Buff:"):
				child.queue_free()

		var buff_text = []
		for key in buff:
			if key != "Duration":
				buff_text.append("%s: %s" % [key, buff[key]])

		if buff_text:
			var buff_label = Label.new()
			buff_label.text = "Buff: " + ", ".join(buff_text)
			buff_label.theme_override_font_size = 11
			buff_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			detail_result.add_child(buff_label)

	# Atualiza botões
	var can_craft = _can_craft_recipe(recipe)
	craft_button.disabled = not can_craft
	craft_button.text = "⚒ Craft" if mode == "craft" else "🍳 Cook"

	var is_fav = recipe.recipe_name in favorite_recipes
	favorite_button.text = "★ Favorito" if is_fav else "☆ Favoritar"

func _can_craft_recipe(recipe: RecipeData) -> bool:
	if not InventoryManager:
		return false

	# Verifica ingredientes
	for ing in recipe.ingredients:
		var item_id = ing.item_id
		var count = ing.count
		if InventoryManager.get_item_count(item_id) < count:
			return false
	return true

func _on_craft_clicked() -> void:
	if not selected_recipe or not _can_craft_recipe(selected_recipe):
		return

	# Consome ingredientes
	for ing in selected_recipe.ingredients:
		InventoryManager.remove_item(ing.item_id, ing.count)

	# Adiciona resultado
	var result_item = DataLoader.get_item(selected_recipe.result.item_id)
	var amount = selected_recipe.result.amount
	var quality = _calculate_craft_quality(selected_recipe)
	InventoryManager.add_item(selected_recipe.result.item_id, amount, quality)

	# Stats
	if GameManager:
		if mode == "craft":
			GameManager.stats.items_crafted += 1
		else:
			GameManager.stats.items_cooked += 1

	# Notificação
	HUD.show_notification("%s!" % ("⚒ Crafted" if mode == "craft" else "🍳 Cooked"), "%s x%d" % [result_item?.display_name ?? selected_recipe.recipe_name, amount], Color(0.5, 1.0, 0.5))

	# Partículas
	if ParticleManager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ParticleManager.show_level_up(player.global_position, "Crafted!" if mode == "craft" else "Cooked!")

	# Som
	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/%s.ogg" % ("craft" if mode == "craft" else "cook"))

	# Emite sinal
	if mode == "craft":
		GameManager.emit_signal("recipe_crafted", selected_recipe.recipe_name)
	else:
		GameManager.emit_signal("recipe_cooked", selected_recipe.recipe_name)

	_refresh_recipe(selected_recipe)

func _calculate_craft_quality(recipe: RecipeData) -> int:
	# Qualidade baseada em ingredientes + sorte
	var chance = 0.0
	chance += (GameManager.daily_luck + 0.1) * 0.3 if GameManager else 0

	# Profissão Artisan
	if GameManager and GameManager.professions.get("Farming") == 1:
		chance += 0.2

	if chance > 0.9: return 3
	elif chance > 0.6: return 2
	elif chance > 0.3: return 1
	return 0

func _toggle_favorite() -> void:
	if not selected_recipe:
		return

	if selected_recipe.recipe_name in favorite_recipes:
		favorite_recipes.erase(selected_recipe.recipe_name)
	else:
		favorite_recipes.append(selected_recipe.recipe_name)

	_save_favorites()
	_show_recipe_details(selected_recipe)
	_refresh_recipes()

func _refresh_categories() -> void:
	# Atualiza visibilidade das categorias baseado no modo
	var craft_cats = category_bar.get_node_or_null("CraftCategories")
	var cook_cats = category_bar.get_node_or_null("CookCategories")

	if craft_cats: craft_cats.visible = (mode == "craft")
	if cook_cats: cook_cats.visible = (mode == "cook")

func hide() -> void:
	visible = false
	panel.visible = false
	_get_tree().paused = false