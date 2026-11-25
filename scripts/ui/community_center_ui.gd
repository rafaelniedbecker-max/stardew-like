extends Control

## UI do Centro Comunitário: bundles, salas, recompensas

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var tabs: TabContainer = $Panel/TabContainer
@onready var progress_bar: ProgressBar = $Panel/TopBar/ProgressBar
@onready var progress_label: Label = $Panel/TopBar/ProgressLabel
@onready var junimo_note: Label = $Panel/JunimoNote

## Estado
var current_room: String = ""
var bundles_data: Dictionary = {}

## Salas
const ROOMS = [
	{"id": "boiler_room", "name": "Caldeira", "icon": "🔥", "bundles": []},
	{"id": "crafts_room", "name": "Oficina", "icon": "🔨", "bundles": []},
	{"id": "pantry", "name": "Despensa", "icon": "🍎", "bundles": []},
	{"id": "fish_tank", "name": "Tanque de Peixes", "icon": "🐟", "bundles": []},
	{"id": "bulletin_board", "name": "Quadro de Avisos", "icon": "📋", "bundles": []},
	{"id": "vault", "name": "Cofre", "icon": "💰", "bundles": []}
]

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	close_button.pressed.connect(hide)

	_create_tabs()
	_load_cc_data()

	if CommunityCenter:
		CommunityCenter.bundle_completed.connect(_on_bundle_completed)
		CommunityCenter.room_completed.connect(_on_room_completed)
		CommunityCenter.cc_completed.connect(_on_cc_completed)

func _create_tabs() -> void:
	for room in ROOMS:
		var scroll = ScrollContainer.new()
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 10)
		scroll.add_child(vbox)
		tabs.add_child(scroll)
		tabs.set_tab_title(tabs.get_child_count() - 1, "%s %s" % [room.icon, room.name])

		# Guarda referência
		tabs.get_child(tabs.get_child_count() - 1).set("room_id", room.id)

func _load_cc_data() -> void:
	if not CommunityCenter:
		return

	bundles_data = CommunityCenter.get_save_data()
	_populate_all_rooms()
	_update_progress()

func _populate_all_rooms() -> void:
	for i in range(tabs.get_child_count()):
		var tab = tabs.get_child(i)
		var room_id = tab.get("room_id")
		var vbox = tab.get_node("VBoxContainer")

		for child in vbox.get_children():
			child.queue_free()

		if not CommunityCenter:
			continue

		var room_bundles = CommunityCenter.get_room_bundles(room_id)
		for bundle_name in room_bundles:
	var bundle_data = room_bundles[bundle_name]
			var bundle_ui = _create_bundle_ui(bundle_name, bundle_data)
			vbox.add_child(bundle_ui)

func _create_bundle_ui(bundle_name: String, bundle_data: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 120)

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Header
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)

	var title = Label.new()
	title.text = bundle_name
	title.theme_override_font_size = 18
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	header.add_child(title)

	var status = Label.new()
	var completed = CommunityCenter.is_bundle_completed(bundle_name)
	if completed:
		status.text = "✅ COMPLETO"
		status.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		status.text = "🔄 EM ANDAMENTO"
		status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.theme_override_font_size = 14
	header.add_child(status)

	vbox.add_child(header)

	# Itens necessários
	var items_container = VBoxContainer.new()
	items_container.add_theme_constant_override("separation", 5)

	var required_items = bundle_data.get("items", [])
	for item_req in required_items:
		var item_id = item_req.get("item_id", "")
		var amount = item_req.get("amount", 1)
		var quality = item_req.get("quality", 0)

		var item = DataLoader.get_item(item_id)
		var has_amount = InventoryManager.get_item_count(item_id) >= amount if InventoryManager else 0

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		if item and item.texture_path != "":
			icon.texture = load(item.texture_path)
		hbox.add_child(icon)

		var name = Label.new()
		name.text = "%s x%d" % [item.display_name if item != null else item_id, amount]
		name.theme_override_font_size = 14
		if not has_amount:
			name.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		hbox.add_child(name)

		var q_indicator = Label.new()
		if quality > 0:
			var q_names = ["", "⭐", "⭐⭐", "⭐⭐⭐"]
			q_indicator.text = q_names[quality] if quality < 4 else ""
			q_indicator.theme_override_font_size = 12
			hbox.add_child(q_indicator)

		items_container.add_child(hbox)

	vbox.add_child(items_container)

	# Barra de progresso
	if not completed:
		var progress = ProgressBar.new()
		progress.max_value = required_items.size()
		var completed_count = _count_completed_items(bundle_name)
		progress.value = completed_count
		vbox.add_child(progress)

		var progress_label = Label.new()
		progress_label.text = "%d/%d itens" % [completed_count, required_items.size()]
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		progress_label.theme_override_font_size = 12
		progress_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		vbox.add_child(progress_label)

	# Botão doar (se não completo)
	if not completed:
		var donate_btn = Button.new()
		donate_btn.text = "🎁 Doar Itens"
		donate_btn.custom_minimum_size = Vector2(0, 40)
		donate_btn.theme_override_font_size = 14
		donate_btn.pressed.connect(_open_donate_ui.bind(bundle_name))
		vbox.add_child(donate_btn)
	else:
		var complete_label = Label.new()
		complete_label.text = "✨ BUNDLE COMPLETO! Recompensa: %s" % bundle_data.get("reward", "???")
		complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		complete_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		complete_label.theme_override_font_size = 13
		vbox.add_child(complete_label)

	return panel

func _count_completed_items(bundle_name: String) -> int:
	if not CommunityCenter:
		return 0
	var bundle = CommunityCenter.get_bundle_instance(bundle_name)
	if bundle:
		var count = 0
		for obj in bundle.objectives:
			if obj.current >= obj.required:
				count += 1
		return count
	return 0

func _open_donate_ui(bundle_name: String) -> void:
	if not CommunityCenter or not InventoryManager:
		return

	var panel = Panel.new()
	panel.name = "DonateUI_%s" % bundle_name
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 100
	panel.offset_right = -200
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🎁 Doar para: %s" % bundle_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 20
	vbox.add_child(title)

	var bundle = CommunityCenter.get_bundle_instance(bundle_name)
	if not bundle:
		return

	var scroll = ScrollContainer.new()
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(grid)
	scroll.custom_minimum_size = Vector2(0, 300)
	vbox.add_child(scroll)

	for obj in bundle.objectives:
		if obj.current >= obj.required:
			continue

		var needed = obj.required - obj.current
		var item_id = obj.target_item_id
		var item = DataLoader.get_item(item_id)
		if not item:
			continue

		var have = InventoryManager.get_item_count(item_id)
		if have <= 0:
			continue

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 100)
		btn.flat = true

		var vbox_i = VBoxContainer.new()
		vbox_i.anchors_preset = 15
		btn.add_child(vbox_i)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		if item.texture_path != "":
			icon.texture = load(item.texture_path)
		vbox_i.add_child(icon)

		var name = Label.new()
		name.text = item.display_name
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.theme_override_font_size = 12
		name.autowrap_mode = 1
		vbox_i.add_child(name)

		var qty = Label.new()
		qty.text = "Tem: %d | Precisa: %d" % [have, needed]
		qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty.theme_override_font_size = 11
		if have >= needed:
			qty.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			qty.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		vbox_i.add_child(qty)

		btn.pressed.connect(_donate_item.bind(bundle_name, item_id, panel))
		grid.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Cancelar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _donate_item(bundle_name: String, item_id: String, panel: Panel) -> void:
	if CommunityCenter.complete_bundle_item(bundle_name, item_id, 1):
		UIStyle.show_toast("🎁 Doado!", "Item doado ao bundle!", "success")
		panel.queue_free()
		_populate_all_rooms()
		_update_progress()
	else:
		UIStyle.show_toast("❌ Erro", "Não foi possível doar", "danger")

func _on_bundle_completed(bundle_key: String) -> void:
	_populate_all_rooms()
	_update_progress()
	UIStyle.show_toast("🎉 Bundle Completo!", "%s finalizado!" % bundle_key, "achievement", 5.0)

	# Partículas
	if ParticleManager:
		ParticleManager.show_level_up(get_tree().root.get_child(0).global_position, "Bundle Completo!")

func _on_room_completed(room_id: String) -> void:
	var room_names = {"boiler_room": "Caldeira", "crafts_room": "Oficina", "pantry": "Despensa", "fish_tank": "Tanque de Peixes", "bulletin_board": "Quadro de Avisos", "vault": "Cofre"}
	UIStyle.show_toast("🏆 Sala Completa!", "%s restaurada!" % room_names.get(room_id, room_id), "achievement", 6.0)

	# Desbloqueia próxima sala
	_populate_all_rooms()
	_update_progress()

func _on_cc_completed() -> void:
	UIStyle.show_toast("🏆 Centro Comunitário Completo!", "Todos os bundles finalizados! Junimo Hut desbloqueado!", "achievement", 8.0)

	if ParticleManager:
		ParticleManager.show_level_up(get_tree().root.get_child(0).global_position, "CC Completo!")

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/cc_complete.ogg")

func _update_progress() -> void:
	if not CommunityCenter:
		return

	var total_bundles = 0
	var completed_bundles = 0

	for room in ROOMS:
		var bundles = CommunityCenter.get_room_bundles(room.id)
		for bundle_name in bundles:
	var _ = bundles[bundle_name]
			total_bundles += 1
			if CommunityCenter.is_bundle_completed(bundle_name):
				completed_bundles += 1

	progress_bar.max_value = total_bundles
	progress_bar.value = completed_bundles
	progress_label.text = "Bundles: %d/%d (%.0f%%)" % [completed_bundles, total_bundles, (completed_bundles / total_bundles * 100) if total_bundles > 0 else 0]

	# Nota do Junimo
	if junimo_note:
		if completed_bundles == total_bundles and total_bundles > 0:
			junimo_note.text = "🎉 Os Junimos estão felizes! O Centro Comunitário foi restaurado!"
			junimo_note.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			junimo_note.text = "🧙 Os Junimos aguardam suas doações... (%d/%d bundles)" % [completed_bundles, total_bundles]
			junimo_note.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

## ==================== PÚBLICO ====================
func open() -> void:
	visible = true
	panel.visible = true
	popup_centered()
	_load_cc_data()
	_get_tree().paused = true

func hide() -> void:
	visible = false
	panel.visible = false
	_get_tree().paused = false