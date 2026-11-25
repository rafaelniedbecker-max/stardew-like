extends Control

## Menu de Coleções: Itens Enviados, Peixes, Artefatos, Minerais, Receitas, Conquistas

@onready var tabs: TabContainer = $Panel/TabBar
@onready var close_button: Button = $Panel/CloseButton
@onready var completion_label: Label = $Panel/TopBar/CompletionLabel
@onready var search_box: LineEdit = $Panel/TopBar/SearchBox

## Estado
var collections_data: Dictionary = {}
var current_tab: int = 0

## Categorias de coleção
const COLLECTION_CATEGORIES = [
	{"id": "shipped", "name": "Enviados", "icon": "📦", "data_source": "shipped_items"},
	{"id": "fish", "name": "Peixes", "icon": "🐟", "data_source": "fish_caught"},
	{"id": "artifacts", "name": "Artefatos", "icon": "🏺", "data_source": "artifacts_found"},
	{"id": "minerals", "name": "Minerais", "icon": "⛏️", "data_source": "minerals_found"},
	{"id": "recipes", "name": "Receitas", "icon": "🍳", "data_source": "recipes_learned"},
	{"id": "achievements", "name": "Conquistas", "icon": "🏆", "data_source": "achievements_unlocked"}
]

## ==================== SINAIS ====================
signal collection_updated(category: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# If loaded as autoload without scene, UI nodes will be null
	if not close_button or not tabs or not search_box:
		# Running as manager only, skip UI setup
		_load_collections_data()
		return

	visible = false
	close_button.pressed.connect(hide)
	tabs.tab_changed.connect(_on_tab_changed)
	search_box.text_changed.connect(_on_search_changed)

	# Cria tabs
	_create_tabs()

	_load_collections_data()

func _create_tabs() -> void:
	for cat in COLLECTION_CATEGORIES:
		var scroll = ScrollContainer.new()
		var grid = GridContainer.new()
		grid.columns = 10
		grid.add_theme_constant_override("h_separation", 5)
		grid.add_theme_constant_override("v_separation", 5)
		scroll.add_child(grid)
		tabs.add_child(scroll)
		tabs.set_tab_title(tabs.get_child_count() - 1, "%s %s" % [cat.icon, cat.name])

		# Armazena referência ao grid
		grid.name = "Grid_%s" % cat.id

func _load_collections_data() -> void:
	if not GameManager:
		return

	collections_data = {
		"shipped_items": GameManager.get_data("collection_shipped", {}),
		"fish_caught": GameManager.get_data("collection_fish", {}),
		"artifacts_found": GameManager.get_data("collection_artifacts", {}),
		"minerals_found": GameManager.get_data("collection_minerals", {}),
		"recipes_learned": GameManager.get_data("collection_recipes", {}),
		"achievements_unlocked": GameManager.get_data("achievements", [])
	}

	_update_completion_label()
	_populate_all_grids()

func _populate_all_grids() -> void:
	for cat in COLLECTION_CATEGORIES:
		var grid = tabs.get_child(tabs.get_tab_idx_from_name(cat.id)).get_node("Grid_%s" % cat.id)
		_populate_grid(grid, cat)

func _populate_grid(grid: GridContainer, category: Dictionary) -> void:
	grid.clear()
	var data = collections_data.get(category.data_source, {})
	var all_items = _get_all_items_for_category(category.id)

	for item_id in all_items:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(50, 50)
		btn.tooltip_text = item_id

		var item_data = DataLoader.get_item(item_id)
		if item_data:
			btn.tooltip_text = "%s\n%s" % [item_data.display_name, item_data.description.left(100)]

		var is_collected = false
		var count = 0

		if category.id == "achievements":
			is_collected = item_id in data
		else:
			is_collected = data.has(item_id)
			count = data.get(item_id, 0)

		if is_collected:
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0, 1, 0))
			if category.id != "achievements" and count > 1:
				btn.text = "✓\n%d" % count
			else:
				btn.text = "✓"
		else:
			btn.text = "?"
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

		grid.add_child(btn)

func _get_all_items_for_category(category: String) -> Array:
	var result = []

	match category:
		"shipped":
			# Todos itens que podem ser enviados
			for item in DataLoader.get_all_items():
				if not item.exclude_from_shipping_collection:
					result.append("(O)%d" % item.id)
		"fish":
			for item in DataLoader.get_all_items():
				if item.item_type.to_lower() == "fish" and not item.exclude_from_fishing_collection:
					result.append("(O)%d" % item.id)
		"artifacts":
			for item in DataLoader.get_all_items():
				if item.item_type.to_lower() in ["arch", "artifact", "artifacts"]:
					result.append("(O)%d" % item.id)
		"minerals":
			for item in DataLoader.get_all_items():
				if item.item_type.to_lower() in ["mineral", "minerals"]:
					result.append("(O)%d" % item.id)
		"recipes":
			for recipe in DataLoader.get_all_recipes():
				result.append(recipe.recipe_name)
		"achievements":
			result = ["Grandpa's Evaluation", "Perfection", "Master Angler", "Master Farmer", "Master Miner",
					 "Master Forager", "Master Fighter", "Full Museum", "Full Catalog", "Full Recipes",
					 "All Friends", "All Skills 10", "Cryptic Book", "Legendary Fish", "All Crafting"]
		_:
			pass

	result.sort()
	return result

func _on_tab_changed(tab_idx: int) -> void:
	current_tab = tab_idx

func _on_search_changed(text: String) -> void:
	# Filtra grids
	var cat = COLLECTION_CATEGORIES[current_tab]
	var grid = tabs.get_child(current_tab).get_node("Grid_%s" % cat.id)
	var search = text.to_lower()

	for child in grid.get_children():
		if child is Button:
			var tooltip = child.tooltip_text.to_lower()
			child.visible = search == "" or search in tooltip

func _update_completion_label() -> void:
	var total = 0
	var collected = 0

	for cat in COLLECTION_CATEGORIES:
		var data = collections_data.get(cat.data_source, {})
		var all_items = _get_all_items_for_category(cat.id)

		for item in all_items:
			total += 1
			if cat.id == "achievements":
				if item in data:
					collected += 1
			else:
				if data.has(item):
					collected += 1

	var pct = (collected / total * 100.0) if total > 0 else 0.0
	completion_label.text = "Coleção: %d/%d (%.1f%%)" % [collected, total, pct]

## ==================== REGISTRO DE COLETA ====================
func register_shipped(item_id: String, amount: int = 1) -> void:
	var data = collections_data.get("shipped_items", {})
	data[item_id] = data.get(item_id, 0) + amount
	collections_data["shipped_items"] = data
	GameManager.set_data("collection_shipped", data)
	_update_completion_label()
	_refresh_current_grid()

func register_fish_caught(item_id: String, size: float = 0, quality: int = 0) -> void:
	var data = collections_data.get("fish_caught", {})
	if not data.has(item_id):
		data[item_id] = {"count": 0, "max_size": 0, "best_quality": 0}
	data[item_id].count += 1
	data[item_id].max_size = max(data[item_id].max_size, size)
	data[item_id].best_quality = max(data[item_id].best_quality, quality)
	collections_data["fish_caught"] = data
	GameManager.set_data("collection_fish", data)
	_update_completion_label()
	_refresh_current_grid()

func register_artifact_found(item_id: String) -> void:
	var data = collections_data.get("artifacts_found", {})
	data[item_id] = true
	collections_data["artifacts_found"] = data
	GameManager.set_data("collection_artifacts", data)
	_update_completion_label()
	_refresh_current_grid()

func register_mineral_found(item_id: String) -> void:
	var data = collections_data.get("minerals_found", {})
	data[item_id] = true
	collections_data["minerals_found"] = data
	GameManager.set_data("collection_minerals", data)
	_update_completion_label()
	_refresh_current_grid()

func register_recipe_learned(recipe_name: String) -> void:
	var data = collections_data.get("recipes_learned", {})
	data[recipe_name] = true
	collections_data["recipes_learned"] = data
	GameManager.set_data("collection_recipes", data)
	_update_completion_label()
	_refresh_current_grid()

func register_achievement(achievement: String) -> void:
	var data = collections_data.get("achievements_unlocked", [])
	if achievement not in data:
		data.append(achievement)
		collections_data["achievements_unlocked"] = data
		GameManager.set_data("achievements", data)
		_update_completion_label()
		_refresh_current_grid()

func _refresh_current_grid() -> void:
	var cat = COLLECTION_CATEGORIES[current_tab]
	var grid = tabs.get_child(current_tab).get_node("Grid_%s" % cat.id)
	_populate_grid(grid, cat)

## ==================== ABRIR MENU ====================
func open_collections() -> void:
	# If UI nodes don't exist, instantiate the scene
	if not close_button or not tabs:
		var scene = load("res://scenes/ui/collections_menu.tscn")
		if scene:
			var instance = scene.instantiate()
			get_tree().root.get_child(0).add_child(instance)
			instance.open_collections()
		return

	visible = true
	_load_collections_data()
	grab_focus()

@warning_ignore("native_method_override")
func hide() -> void:
	visible = false

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"collections_data": collections_data
	}

func load_save_data(data: Dictionary) -> void:
	collections_data = data.get("collections_data", {})
	_update_completion_label()
	_populate_all_grids()