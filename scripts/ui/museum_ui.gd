extends Control

## UI do Museu: doação, coleções, recompensas

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var tabs: TabContainer = $Panel/TabContainer
@onready var donate_button: Button = $Panel/DonateButton
@onready var progress_label: Label = $Panel/TopBar/ProgressLabel
@onready var search_box: LineEdit = $Panel/TopBar/SearchBox

## Estado
var museum_data: Dictionary = {}
var current_tab: int = 0
var selected_item: String = ""

## Categorias
const CATEGORIES = [
	{"id": "minerals", "name": "Minerais", "icon": "⛏️", "items": []},
	{"id": "artifacts", "name": "Artefatos", "icon": "🏺", "items": []},
	{"id": "fossils", "name": "Fósseis", "icon": "🦴", "items": []},
	{"id": "lost_books", "name": "Livros Perdidos", "icon": "📚", "items": []}
]

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	close_button.pressed.connect(hide)
	tabs.tab_changed.connect(_on_tab_changed)
	search_box.text_changed.connect(_on_search_changed)
	donate_button.pressed.connect(_on_donate_pressed)
	donate_button.disabled = true

	_create_tabs()
	_load_museum_data()

	# Conecta ao Museum
	if Museum:
		Museum.item_donated.connect(_on_item_donated)
		Museum.milestone_reached.connect(_on_milestone_reached)

func _create_tabs() -> void:
	for cat in CATEGORIES:
		var scroll = ScrollContainer.new()
		var grid = GridContainer.new()
		grid.columns = 10
		grid.add_theme_constant_override("h_separation", 5)
		grid.add_theme_constant_override("v_separation", 5)
		scroll.add_child(grid)
		tabs.add_child(scroll)
		tabs.set_tab_title(tabs.get_child_count() - 1, "%s %s" % [cat.icon, cat.name])

func _load_museum_data() -> void:
	if not Museum:
		return

	museum_data = Museum.get_save_data()
	_populate_all_grids()
	_update_progress_label()

func _populate_all_grids() -> void:
	for i in range(CATEGORIES.size()):
		var cat = CATEGORIES[i]
		var grid = tabs.get_child(i).get_node("GridContainer")
		for child in grid.get_children():
			child.queue_free()

		var items = Museum.get_items_by_category(cat.id)
		for item in items:
			var btn = _create_item_button(item, cat.id)
			grid.add_child(btn)

		# Preenche slots vazios
		var total_slots = Museum.get_category_total(cat.id)
		for j in range(items.size(), total_slots):
			var empty = _create_empty_slot()
			grid.add_child(empty)

func _create_item_button(item: Dictionary, category: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(56, 56)
	btn.flat = true

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	btn.add_child(vbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if item.texture_path != "":
		icon.texture = load(item.texture_path)
	vbox.add_child(icon)

	var name = Label.new()
	name.text = item.display_name
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.theme_override_font_size = 9
	name.autowrap_mode = 1
	vbox.add_child(name)

	var donated = Museum.is_donated(item.id)
	if donated:
		btn.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	btn.disabled = donated
	btn.pressed.connect(_on_item_selected.bind(item.id, category))

	return btn

func _create_empty_slot() -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(56, 56)
	btn.flat = true
	btn.disabled = true

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	btn.add_child(vbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	vbox.add_child(icon)

	var q = Label.new()
	q.text = "?"
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.theme_override_font_size = 14
	q.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	vbox.add_child(q)

	return btn

func _on_tab_changed(tab_idx: int) -> void:
	current_tab = tab_idx
	selected_item = ""

func _on_search_changed(text: String) -> void:
	# Filtra itens visíveis
	pass

func _on_item_selected(item_id: String, category: String) -> void:
	selected_item = item_id
	var item = DataLoader.get_item(item_id)
	if not item:
		return

	donate_button.disabled = false
	donate_button.text = "🎁 Doar %s" % item.display_name
	donate_button.tooltip_text = item.description
	donate_button.pressed.connect(_confirm_donate.bind(item_id))

func _confirm_donate(item_id: String) -> void:
	if not InventoryManager:
		return

	if InventoryManager.remove_item(item_id, 1):
		if Museum.donate_item(item_id):
			var item_data = DataLoader.get_item(item_id)
			HUD.show_notification("🏛️ Doado!", "%s adicionado ao museu!" % (item_data.display_name if item_data != null else item_id), Color(0.5, 1.0, 0.5))

			if ParticleManager:
				ParticleManager.show_level_up(get_tree().root.get_child(0).global_position, "Doado!")

			if AudioManager:
				AudioManager.play_sfx("res://assets/sfx/museum_donate.ogg")
		else:
			HUD.show_message("Erro ao doar!")
	else:
		HUD.show_message("Item não encontrado no inventário!")

func _on_donate_pressed() -> void:
	if selected_item != "":
		_confirm_donate(selected_item)

func _on_item_donated(item_id: String) -> void:
	_populate_all_grids()
	_update_progress_label()
	donate_button.disabled = true
	donate_button.text = "🎁 Doar"

func _on_milestone_reached(count: int) -> void:
	var rewards = Museum.get_milestone_rewards(count)
	if rewards:
		var reward_text = rewards.join(", ")
		UIStyle.show_toast("🏆 Marco do Museu!", "%d itens doados! Recompensa: %s" % [count, reward_text], "achievement", 6.0)

	_update_progress_label()

func _update_progress_label() -> void:
	if Museum:
		var total = Museum.get_total_items()
		var donated = Museum.get_donated_count()
		var pct = (donated / total * 100) if total > 0 else 0
		progress_label.text = "Progresso: %d/%d (%.1f%%)" % [donated, total, pct]

## ==================== PÚBLICO ====================
func open() -> void:
	visible = true
	panel.visible = true
	panel.position = (get_viewport_rect().size - panel.size) * 0.5
	_load_museum_data()
	get_tree().paused = true

@warning_ignore("native_method_override")
func hide() -> void:
	visible = false
	panel.visible = false
	get_tree().paused = false