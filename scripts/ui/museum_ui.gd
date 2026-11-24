class_name MuseumUI
extends Control

## UI do Museu - doação de artefatos e minerais

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var tabs: TabContainer = $Panel/TabContainer
@onready var donate_button: Button = $Panel/DonateButton
@onready var completion_label: Label = $Panel/TopBar/CompletionLabel
@onready var search_box: LineEdit = $Panel/TopBar/SearchBox

## Estado
var museum_data: Dictionary = {}
var current_tab: int = 0
var selected_item: String = ""

## Categorias
const CATEGORIES = [
	{"id": "minerals", "name": "Minerais", "icon": "⛏️"},
	{"id": "artifacts", "name": "Artefatos", "icon": "🏺"},
	{"id": "fossils", "name": "Fósseis", "icon": "🦴"},
	{"id": "lost_books", "name": "Livros Perdidos", "icon": "📚"}
]

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	close_button.pressed.connect(hide)
	donate_button.pressed.connect(_on_donate_pressed)
	tabs.tab_changed.connect(_on_tab_changed)
	search_box.text_changed.connect(_on_search_changed)

	_create_tabs()
	_load_museum_data()

func _create_tabs() -> void:
	for cat in CATEGORIES:
		var scroll = ScrollContainer.new()
		var grid = GridContainer.new()
		grid.columns = 10
		grid.theme_override_constants/h_separation = 5
		grid.theme_override_constants/v_separation = 5
		scroll.add_child(grid)
		tabs.add_child(scroll)
		tabs.set_tab_title(tabs.get_child_count() - 1, "%s %s" % [cat.icon, cat.name])

func _load_museum_data() -> void:
	if not Museum:
		return

	museum_data = Museum.get_save_data()
	_update_completion_label()
	_populate_all_grids()

func _populate_all_grids() -> void:
	for i in range(tabs.get_child_count()):
		var cat = CATEGORIES[i]
		var scroll = tabs.get_child(i)
		var grid = scroll.get_node_or_null("GridContainer")
		if not grid:
			continue

		_populate_grid(grid, cat.id)

func _populate_grid(grid: GridContainer, category: String) -> void:
	grid.clear()

	var items = Museum.get_items_by_category(category)
	var donated = museum_data.get("donated", {})

	for item in items:
		var item_id = item.id
		var is_donated = donated.has(item_id)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(56, 56)
		btn.flat = true
		btn.disabled = is_donated

		var vbox = VBoxContainer.new()
		vbox.anchors_preset = 15
		btn.add_child(vbox)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		if item.texture_path != "":
			icon.texture = load(item.texture_path)
		else:
			# Placeholder colorido
			var img = Image.create(40, 40, false, Image.FORMAT_RGBA8)
			img.fill(item.category == "minerals" ? Color(0.5, 0.5, 0.7) : Color(0.7, 0.5, 0.3))
			icon.texture = ImageTexture.create_from_image(img)
		vbox.add_child(icon)

		var name = Label.new()
		name.text = item.display_name
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.theme_override_font_size = 9
		name.autowrap_mode = 1
		if is_donated:
			name.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		vbox.add_child(name)

		if is_donated:
			var check = TextureRect.new()
			check.custom_minimum_size = Vector2(20, 20)
			# Checkmark procedural
			var img = Image.create(20, 20, false, Image.FORMAT_RGBA8)
			img.fill(Color(0,0,0,0))
			for x in range(20):
				for y in range(20):
					if (x == y + 5 and x < 15) or (x == 15 - y and x > 5):
						img.set_pixel(x, y, Color(0, 1, 0))
			check.texture = ImageTexture.create_from_image(img)
			vbox.add_child(check)

		btn.pressed.connect(_on_item_selected.bind(item_id, category, btn))
		grid.add_child(btn)

func _on_item_selected(item_id: String, category: String, btn: Button) -> void:
	selected_item = item_id
	# Atualiza visual de seleção
	for child in btn.get_parent().get_children():
		if child is Button:
			child.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

	# Mostra info do item
	_show_item_info(item_id)

func _show_item_info(item_id: String) -> void:
	# Atualiza painel de info (se tiver)
	pass

func _on_donate_pressed() -> void:
	if selected_item == "":
		HUD.show_message("Selecione um item para doar!")
		return

	if not InventoryManager.has_item(selected_item):
		HUD.show_message("Você não tem este item!")
		return

	if Museum.can_donate(selected_item):
		if InventoryManager.remove_item(selected_item, 1):
			Museum.donate_item(selected_item)
			_reload_data()
			HUD.show_message("Doado: %s!" % DataLoader.get_item(selected_item)?.display_name)

			if ParticleManager:
				ParticleManager.spawn("harvest", get_tree().get_first_node_in_group("player").global_position)

			if AudioManager:
				AudioManager.play_sfx("res://assets/sfx/museum_donate.ogg")
	else:
		HUD.show_message("Este item já foi doado!")

func _reload_data() -> void:
	_load_museum_data()
	selected_item = ""

func _on_tab_changed(tab_idx: int) -> void:
	current_tab = tab_idx
	selected_item = ""

func _on_search_changed(text: String) -> void:
	# Filtra itens visíveis
	var search = text.to_lower()
	var grid = tabs.get_child(current_tab).get_node_or_null("GridContainer")
	if not grid:
		return

	for child in grid.get_children():
		if child is Button:
			var name_label = child.get_node_or_null("VBoxContainer/Label")
			if name_label:
				var visible = search == "" or search in name_label.text.to_lower()
				child.visible = visible

func _update_completion_label() -> void:
	if not Museum:
		return

	var total = Museum.get_total_items()
	var donated = Museum.get_donated_count()
	var pct = total > 0 ? (donated / total * 100) : 0

	completion_label.text = "Completude: %d%% (%d/%d)" % [pct, donated, total]

## ==================== PÚBLICO ====================
func open() -> void:
	visible = true
	panel.visible = true
	popup_centered()
	_load_museum_data()
	_get_tree().paused = true

func hide() -> void:
	visible = false
	panel.visible = false
	_get_tree().paused = false