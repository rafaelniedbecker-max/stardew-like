class_name CraftingMenu
extends Control

## Menu de Crafting e Culinária com abas, busca, filtros

@onready var craft_tab: TabButton = $Panel/TabContainer/CraftTab
@onready var cook_tab: TabButton = $Panel/TabContainer/CookTab
@onready var craft_container: GridContainer = $Panel/CraftPanel/ScrollContainer/GridContainer
@onready var cook_container: GridContainer = $Panel/CookPanel/ScrollContainer/GridContainer
@onready var search_box: LineEdit = $Panel/SearchBox
@onready var category_buttons: HBoxContainer = $Panel/CategoryBar/HBoxContainer
@onready var recipe_details: Panel = $Panel/RecipeDetails
@onready var detail_icon: TextureRect = $Panel/RecipeDetails/Icon
@onready var detail_name: Label = $Panel/RecipeDetails/NameLabel
@onready var detail_desc: Label = $Panel/RecipeDetails/DescLabel
@onready var detail_ingredients: VBoxContainer = $Panel/RecipeDetails/IngredientsContainer
@onready var detail_result: HBoxContainer = $Panel/RecipeDetails/ResultContainer
@onready var craft_button: Button = $Panel/RecipeDetails/CraftButton
@onready var close_button: Button = $Panel/CloseButton
@onready var gold_label: Label = $Panel/TopBar/GoldLabel

## Estado
var mode: String = "craft"  # "craft" ou "cook"
var active_category: String = "all"
var search_text: String = ""
var selected_recipe: RecipeData = null
var available_recipes: Array[RecipeData] = []

## ==================== SINAIS ====================
signal menu_closed()
signal recipe_crafted(recipe_name: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	_setup_categories()
	close_button.pressed.connect(hide)
	craft_tab.toggled.connect(func(p): _on_tab_changed("craft") if p else null)
	cook_tab.toggled.connect(func(p): _on_tab_changed("cook") if p else null)
	search_box.text_changed.connect(_on_search_changed)
	craft_button.pressed.connect(_on_craft_clicked)

func _setup_categories() -> void:
	var categories = {
		"craft": ["all", "tools", "farming", "mining", "foraging", "fishing", "combat", "furniture", "floors", "walls", "machines", "bombs", "fertilizer", "seeds", "totems", "rings", "other"],
		"cook": ["all", "salads", "soups", "mains", "desserts", "drinks", "snacks", "buffs", "qi"]
	}

	# Será populado dinamicamente baseado nas receitas disponíveis
	pass

## ==================== ABRIR MENU ====================
func open_menu(start_mode: String = "craft") -> void:
	mode = start_mode
	visible = true

	if mode == "craft":
		craft_tab.button_pressed = true
		_on_tab_changed("craft")
	else:
		cook_tab.button_pressed = true
		_on_tab_changed("cook")

	_update_gold()
	_update_categories()
	_refresh_recipes()
	grab_focus()

func _update_gold() -> void:
	gold_label.text = "%dg" % GameManager.gold

## ==================== TABS ====================
func _on_tab_changed(new_mode: String) -> void:
	if new_mode == "cook":
		# Abre o novo menu de culinária dedicado
		if CookingMenu:
			CookingMenu.open()
			hide()
		return

	mode = new_mode
	craft_container.visible = (mode == "craft")
	cook_container.visible = (mode == "cook")
	recipe_details.visible = false
	selected_recipe = null
	_update_categories()
	_refresh_recipes()

func _update_categories() -> void:
	# Limpa botões antigos
	for child in category_buttons.get_children():
		if child is Button:
			child.queue_free()

	# Determina categorias únicas das receitas disponíveis
	var cats = {"all"}
	for recipe in _get_base_recipes():
		if mode == "craft" and not recipe.is_cooking:
			cats.add(recipe.crafting_tab.to_lower())
		elif mode == "cook" and recipe.is_cooking:
			cats.add("cooking")

	# Cria botões
	for cat in cats:
		var btn = Button.new()
		btn.text = cat.capitalize()
		btn.toggle_mode = true
		btn.button_group = category_buttons.get_node_or_null("ButtonGroup") or ButtonGroup.new()
		if not category_buttons.has_node("ButtonGroup"):
			var bg = ButtonGroup.new()
			bg.name = "ButtonGroup"
			category_buttons.add_child(bg)
		btn.pressed.connect(_on_category_pressed.bind(cat))
		category_buttons.add_child(btn)
		if cat == "all":
			btn.button_pressed = true

	active_category = "all"

func _get_base_recipes() -> Array[RecipeData]:
	if mode == "craft":
		return DataLoader.get_crafting_recipes()
	else:
		return DataLoader.get_cooking_recipes()

## ==================== BUSCA & FILTRO ====================
func _on_search_changed(text: String) -> void:
	search_text = text.to_lower()
	_refresh_recipes()

func _on_category_pressed(category: String) -> void:
	active_category = category
	_refresh_recipes()

## ==================== LISTA DE RECEITAS ====================
func _refresh_recipes() -> void:
	var container = craft_container if mode == "craft" else cook_container
	_clear_container(container)

	var recipes = _get_filtered_recipes()

	for recipe in recipes:
		_create_recipe_slot(container, recipe)

func _get_filtered_recipes() -> Array[RecipeData]:
	var all_recipes = _get_base_recipes()
	var result = []

	for recipe in all_recipes:
		# Filtro de categoria
		if active_category != "all":
			if mode == "craft" and recipe.crafting_tab.to_lower() != active_category:
				continue
			if mode == "cook" and active_category != "cooking":
				continue

		# Filtro de busca
		if search_text != "":
			if search_text not in recipe.recipe_name.to_lower():
				# Busca também em ingredientes
				var found = false
				for ing in recipe.ingredients:
					var item = DataLoader.get_item(ing.item_id)
					if item and search_text in item.get_display_name().to_lower():
						found = true
						break
				if not found:
					continue

		# Verifica se pode craftar (ingredientes + desbloqueado)
		var can_craft = InventoryManager.can_craft(recipe.recipe_name)
		var unlocked = recipe.recipe_name in GameManager.unlocked_recipes or recipe.default_unlocked
		if mode == "cook":
			unlocked = recipe.recipe_name in GameManager.unlocked_cooking_recipes or recipe.default_unlocked

		# Mostra tudo mas marca locked
		result.append(recipe)

	# Ordena: desbloqueadas e craftáveis primeiro
	result.sort_custom(Callable(self, "_sort_recipes"))
	return result

func _sort_recipes(a: RecipeData, b: RecipeData) -> int:
	var a_unlocked = a.recipe_name in GameManager.unlocked_recipes or a.default_unlocked
	var b_unlocked = b.recipe_name in GameManager.unlocked_recipes or b.default_unlocked
	if mode == "cook":
		a_unlocked = a.recipe_name in GameManager.unlocked_cooking_recipes or a.default_unlocked
		b_unlocked = b.recipe_name in GameManager.unlocked_cooking_recipes or b.default_unlocked

	var a_can = InventoryManager.can_craft(a.recipe_name)
	var b_can = InventoryManager.can_craft(b.recipe_name)

	if a_unlocked != b_unlocked:
		return -1 if a_unlocked else 1
	if a_can != b_can:
		return -1 if a_can else 1
	return -1 if a.recipe_name < b.recipe_name else 1

func _create_recipe_slot(parent: GridContainer, recipe: RecipeData) -> void:
	var slot = PanelContainer.new()
	slot.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	slot.custom_minimum_size = Vector2(140, 100)

	var vbox = VBoxContainer.new()
	slot.add_child(vbox)

	# Ícone do resultado
	var result_item = DataLoader.get_item(recipe.result.item_id)
	var hbox = HBoxContainer.new()
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)

	var name_label = Label.new()
	name_label.text = recipe.recipe_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hbox.add_child(name_label)
	vbox.add_child(hbox)

	# Status
	var status_label = Label.new()
	var unlocked = recipe.recipe_name in GameManager.unlocked_recipes or recipe.default_unlocked
	if mode == "cook":
		unlocked = recipe.recipe_name in GameManager.unlocked_cooking_recipes or recipe.default_unlocked

	if not unlocked:
		status_label.text = "🔒 %s" % recipe.unlock_condition
		status_label.add_theme_color_override("font_color", Color.GRAY)
	elif not InventoryManager.can_craft(recipe.recipe_name):
		status_label.text = "❌ Ingredientes insuficientes"
		status_label.add_theme_color_override("font_color", Color.RED)
	else:
		status_label.text = "✅ Pronto para craftar"
		status_label.add_theme_color_override("font_color", Color.GREEN)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)

	# Botão craft
	var craft_btn = Button.new()
	craft_btn.text = "Craftar"
	craft_btn.disabled = not unlocked or not InventoryManager.can_craft(recipe.recipe_name)
	craft_btn.pressed.connect(_on_recipe_selected.bind(recipe))
	vbox.add_child(craft_btn)

	# Clique no slot abre detalhes
	slot.gui_input.connect(_on_slot_gui_input.bind(recipe))
	parent.add_child(slot)

func _on_slot_gui_input(event: InputEvent, recipe: RecipeData) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_recipe_selected(recipe)

func _on_recipe_selected(recipe: RecipeData) -> void:
	selected_recipe = recipe
	_show_recipe_details(recipe)

func _show_recipe_details(recipe: RecipeData) -> void:
	recipe_details.visible = true
	detail_name.text = recipe.recipe_name
	detail_desc.text = "Categoria: %s\nAba: %s" % [recipe.recipe_type, recipe.crafting_tab]

	# Limpa ingredientes anteriores
	for child in detail_ingredients.get_children():
		child.queue_free()

	# Adiciona ingredientes
	for ing in recipe.ingredients:
		var item = DataLoader.get_item(ing.item_id)
		var have = InventoryManager.get_item_count(ing.item_id)
		var hbox = HBoxContainer.new()

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		hbox.add_child(icon)

		var name = Label.new()
		name.text = "%s x%d" % [item.get_display_name() if item else ing.item_id, ing.amount]
		if have < ing.amount:
			name.add_theme_color_override("font_color", Color.RED)
		hbox.add_child(name)

		var have_label = Label.new()
		have_label.text = "(%d)" % have
		have_label.add_theme_color_override("font_color", have >= ing.amount ? Color.GREEN : Color.RED)
		hbox.add_child(have_label)

		detail_ingredients.add_child(hbox)

	# Resultado
	for child in detail_result.get_children():
		child.queue_free()

	if result_item:
		var res_icon = TextureRect.new()
		res_icon.custom_minimum_size = Vector2(32, 32)
		detail_result.add_child(res_icon)

		var res_name = Label.new()
		res_name.text = "%s x%s" % [result_item.get_display_name(), recipe.result.get("count", 1)]
		detail_result.add_child(res_name)

	# Botão craftar
	craft_button.disabled = not InventoryManager.can_craft(recipe.recipe_name)
	craft_button.text = mode == "cook" ? "Cozinhar" : "Craftar"

func _on_craft_clicked() -> void:
	if not selected_recipe:
		return

	var success = false
	if mode == "cook":
		success = InventoryManager.cook(selected_recipe.recipe_name)
	else:
		success = InventoryManager.craft(selected_recipe.recipe_name)

	if success:
		emit_signal("recipe_crafted", selected_recipe.recipe_name)
		_refresh_recipes()
		_show_recipe_details(selected_recipe)
		_update_gold()

func _clear_container(container: GridContainer) -> void:
	for child in container.get_children():
		child.queue_free()

func hide() -> void:
	visible = false
	emit_signal("menu_closed")