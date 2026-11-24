class_name CommunityCenterUI
extends Control

## UI do Centro Comunitário - bundles, recompensas, progresso

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var tabs: TabContainer = $Panel/TabContainer
@onready var completion_label: Label = $Panel/TopBar/CompletionLabel
@onready var junimo_note_button: Button = $Panel/TopBar/JunimoNoteButton

## Estado
var current_room: String = ""
var bundles_data: Dictionary = {}

## Salas do CC
const ROOMS = [
	{"id": "Boiler Room", "name": "Sala da Caldeira", "icon": "🔥"},
	{"id": "Pantry", "name": "Despensa", "icon": "🍞"},
	{"id": "Crafts Room", "name": "Sala de Artesanato", "icon": "🔨"},
	{"id": "Fish Tank", "name": "Tanque de Peixes", "icon": "🐟"},
	{"id": "Bulletin Board", "name": "Quadro de Avisos", "icon": "📋"},
	{"id": "Vault", "name": "Cofre", "icon": "🏦"}
]

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	close_button.pressed.connect(hide)
	tabs.tab_changed.connect(_on_tab_changed)
	junimo_note_button.pressed.connect(_show_junimo_note)

	_create_tabs()
	_load_cc_data()

func _create_tabs() -> void:
	for room in ROOMS:
		var scroll = ScrollContainer.new()
		var vbox = VBoxContainer.new()
		vbox.theme_override_constants/separation = 15
		scroll.add_child(vbox)
		tabs.add_child(scroll)
		tabs.set_tab_title(tabs.get_child_count() - 1, "%s %s" % [room.icon, room.name])

		# Armazena referência da sala
		vbox.set("room_id", room.id)

func _load_cc_data() -> void:
	if not CommunityCenter:
		return

	bundles_data = CommunityCenter.get_save_data()
	_update_completion_label()
	_populate_all_rooms()

func _populate_all_rooms() -> void:
	for i in range(tabs.get_child_count()):
		var vbox = tabs.get_child(i)
		var room_id = vbox.get("room_id", "")
		_populate_room(vbox, room_id)

func _populate_room(vbox: VBoxContainer, room_id: String) -> void:
	vbox.clear()

	if not CommunityCenter:
		return

	var bundles = CommunityCenter.get_room_bundles(room_id)
	for bundle_name in bundles:
		var bundle_data = bundles[bundle_name]
		var bundle_ui = _create_bundle_ui(bundle_name, bundle_data)
		vbox.add_child(bundle_ui)

func _create_bundle_ui(bundle_name: String, bundle_data: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(0, 120)

	var vbox = VBoxContainer.new()
	vbox.theme_override_constants/separation = 8
	panel.add_child(vbox)

	# Header do bundle
	var header = HBoxContainer.new()
	header.theme_override_constants/separation = 10
	vbox.add_child(header)

	var title = Label.new()
	title.text = "%s" % bundle_name
	title.theme_override_font_size = 18
	title.autowrap_mode = 1
	header.add_child(title)

	# Status
	var completed = bundle_data.get("completed", false)
	var status_label = Label.new()
	if completed:
		status_label.text = "✅ COMPLETO"
		status_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		var items_done = bundle_data.get("items_donated", 0)
		var items_total = bundle_data.get("items_required", 0)
		status_label.text = "📦 %d/%d" % [items_done, items_total]
		status_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(status_label)

	# Itens necessários
	var items = bundle_data.get("items", [])
	var grid = GridContainer.new()
	grid.columns = 5
	grid.theme_override_constants/h_separation = 8
	grid.theme_override_constants/v_separation = 8
	vbox.add_child(grid)

	for item_req in items:
		var item_id = item_req.item_id
		var required = item_req.count
		var donated = item_req.get("donated", 0)

		var item = DataLoader.get_item(item_id)
		if not item:
			continue

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.flat = true
		btn.disabled = donated >= required

		var vbox_item = VBoxContainer.new()
		vbox_item.anchors_preset = 15
		btn.add_child(vbox_item)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		if item.texture_path != "":
			icon.texture = load(item.texture_path)
		grid.add_child(btn)

		var name = Label.new()
		name.text = item.display_name
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.theme_override_font_size = 10
		name.autowrap_mode = 1
		vbox_item.add_child(name)

		var qty = Label.new()
		qty.text = "%d/%d" % [donated, required]
		qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty.theme_override_font_size = 11
		if donated >= required:
			qty.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		vbox_item.add_child(qty)

		var quality = Label.new()
		if item_req.get("quality", 0) > 0:
			quality.text = "⭐" * item_req.quality
			quality.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			quality.theme_override_font_size = 12
			quality.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			vbox_item.add_child(quality)

		btn.pressed.connect(_on_item_selected.bind(item_id, bundle_name, required, donated))

	# Recompensa
	if completed:
		var reward = bundle_data.get("reward", {})
		if reward:
			var reward_box = HBoxContainer.new()
			reward_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
			reward_box.theme_override_constants/separation = 10

			var reward_icon = TextureRect.new()
			reward_icon.custom_minimum_size = Vector2(40, 40)
			var reward_item = DataLoader.get_item(reward.item_id)
			if reward_item and reward_item.texture_path != "":
				reward_icon.texture = load(reward_item.texture_path)
			reward_box.add_child(reward_icon)

			var reward_label = Label.new()
			reward_label.text = "Recompensa: %s x%d" % [reward_item?.display_name ?? reward.item_id, reward.amount]
			reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			reward_label.theme_override_font_size = 13
			reward_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			reward_box.add_child(reward_label)

			vbox.add_child(reward_box)

	return panel

func _on_item_selected(item_id: String, bundle_name: String, required: int, donated: int) -> void:
	if donated >= required:
		HUD.show_message("Este item já foi completado!")
		return

	if not InventoryManager.has_item(item_id):
		HUD.show_message("Você não tem este item!")
		return

	if InventoryManager.remove_item(item_id, 1):
		if CommunityCenter:
			CommunityCenter.donate_to_bundle(bundle_name, item_id, 1)
			_reload_room(bundle_name)
			HUD.show_message("Doado: %s!" % DataLoader.get_item(item_id)?.display_name)

			if ParticleManager:
				ParticleManager.spawn("harvest", get_tree().get_first_node_in_group("player").global_position)

			if AudioManager:
				AudioManager.play_sfx("res://assets/sfx/cc_donate.ogg")
	else:
		HUD.show_message("Erro ao doar!")

func _reload_room(room_name: String) -> void:
	# Recarrega apenas a sala afetada
	for i in range(tabs.get_child_count()):
		var vbox = tabs.get_child(i)
		if vbox.get("room_id", "") == room_name:
			_populate_room(vbox, room_name)
			break

	_update_completion_label()

func _update_completion_label() -> void:
	if not CommunityCenter:
		return

	var total = 0
	var completed = 0

	for room in ROOMS:
		var bundles = CommunityCenter.get_room_bundles(room.id)
		for bundle_name in bundles:
			var bundle_data = bundles[bundle_name]
			total += 1
			if bundle_data.get("completed", false):
				completed += 1

	var pct = total > 0 ? (completed / total * 100) : 0
	completion_label.text = "Centro Comunitário: %d%% (%d/%d bundles)" % [pct, completed, total]

func _show_junimo_note() -> void:
	# Abre nota do Junimo com dicas
	var panel = Panel.new()
	panel.name = "JunimoNoteUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 100
	panel.offset_right = -200
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "📝 Nota dos Junimos"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var tips = [
		"Os Junimos adoram frutas e vegetais frescos!",
		"Complete bundles para ganhar recompensas especiais.",
		"A caldeira precisa de minérios e geodas.",
		"A despensa quer cultivos de todas as estações.",
		"A sala de artesanato pede itens artesanais.",
		"O tanque de peixes precisa de peixes de qualidade.",
		"O quadro de avisos aceita forrageamento e itens diversos.",
		"O cofre só aceita ouro! Muito ouro!",
		"Dica: Guarde itens de qualidade prata/ouro para bundles difíceis.",
		"Os Junimos trabalham à noite enquanto você dorme."
	]

	for tip in tips:
		var lbl = Label.new()
		lbl.text = "💡 %s" % tip
		lbl.autowrap_mode = 1
		lbl.theme_override_font_size = 13
		lbl.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
		vbox.add_child(lbl)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _reload_room(room_name: String) -> void:
	# Recarrega dados
	_load_cc_data()

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