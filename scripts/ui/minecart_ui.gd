class_name MinecartUI
extends Control

## UI do Minecart: viagem rápida entre locais desbloqueados

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var locations_container: VBoxContainer = $Panel/LocationsContainer
@onready var current_location_label: Label = $Panel/TopBar/CurrentLocationLabel
@onready var cost_label: Label = $Panel/TopBar/CostLabel

## Estado
var unlocked_locations: Array[String] = []
var current_location: String = ""
var travel_cost: int = 0

## Locais do minecart
const LOCATIONS = [
	{"id": "bus_stop", "name": "Parada de Ônibus", "icon": "🚌", "cost": 0, "position": Vector2(320, 400)},
	{"id": "town", "name": "Pelican Town", "icon": "🏘️", "cost": 0, "position": Vector2(320, 400)},
	{"id": "mines", "name": "Minas", "icon": "⛏️", "cost": 0, "position": Vector2(1200, 200)},
	{"id": "quarry", "name": "Pedreira", "icon": "🪨", "cost": 0, "position": Vector2(1400, 300)},
]

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	close_button.pressed.connect(hide)

	# Carrega progresso
	_load_progress()

	# Cria botões de localização
	_create_location_buttons()

	# Conecta sinais
	if MineCart:
		MineCart.location_unlocked.connect(_on_location_unlocked)
		MineCart.travel_completed.connect(_on_travel_completed)

func _create_location_buttons() -> void:
	for loc in LOCATIONS:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 80)
		btn.flat = true

		var hbox = HBoxContainer.new()
		hbox.anchors_preset = 15
		hbox.theme_override_constants/separation = 20
		btn.add_child(hbox)

		var icon = Label.new()
		icon.text = loc.icon
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.custom_minimum_size = Vector2(60, 60)
		icon.theme_override_font_size = 32
		hbox.add_child(icon)

		var info = VBoxContainer.new()
		info.theme_override_constants/separation = 5

		var name = Label.new()
		name.text = loc.name
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name.theme_override_font_size = 18
		info.add_child(name)

		var cost = Label.new()
		cost.text = "Grátis" if loc.cost == 0 else "%dg" % loc.cost
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		cost.theme_override_font_size = 13
		cost.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		info.add_child(cost)

		hbox.add_child(info)

		# Status de desbloqueio
		var status = Label.new()
		var unlocked = unlocked_locations.has(loc.id)
		status.text = "✓ Desbloqueado" if unlocked else "🔒 Bloqueado"
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		status.theme_override_font_size = 13
		status.custom_minimum_size = Vector2(120, 0)
		if unlocked:
			status.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			status.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		hbox.add_child(status)

		btn.pressed.connect(_on_location_selected.bind(loc.id))
		btn.disabled = not unlocked_locations.has(loc.id)

		locations_container.add_child(btn)

func _load_progress() -> void:
	if MineCart:
		unlocked_locations = MineCart.get_unlocked_locations()
		current_location = MineCart.get_current_location() if MineCart.get_current_location() != "" else "bus_stop"

	_update_ui()

func _update_ui() -> void:
	# Atualiza localização atual
	var current_loc = LOCATIONS.find({"id": current_location})
	if current_loc:
		current_location_label.text = "📍 Atual: %s" % current_loc.name

	# Atualiza botões
	for i in range(locations_container.get_child_count()):
		var btn = locations_container.get_child(i)
		var loc = LOCATIONS[i]
		btn.disabled = not unlocked_locations.has(loc.id)

		var status = btn.get_node("HBoxContainer/Label[2]")  # 3rd child = status
		if status:
			var unlocked = unlocked_locations.has(LOCATIONS[locations_container.get_child_count() - i - 1].id)
			# Fix: need to find correct loc
			var idx = locations_container.get_child_count() - i - 1
			if idx >= 0 and idx < LOCATIONS.size():
				var loc2 = LOCATIONS[idx]
				var unlocked2 = unlocked_locations.has(loc2.id)
				status.text = "✓ Desbloqueado" if unlocked2 else "🔒 Bloqueado"
				status.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5) if unlocked2 else Color(0.7, 0.7, 0.7))

	# Atualiza custo (grátis no Stardew)
	cost_label.text = "💰 Custo: Grátis"

func _on_location_selected(location_id: String) -> void:
	if location_id == current_location:
		HUD.show_message("Você já está aqui!")
		return

	var loc = LOCATIONS.find({"id": location_id})
	if not loc:
		return

	# Viaja
	if MineCart:
		MineCart.travel_to(location_id)

	# Feedback visual
	UIStyle.show_toast("⛏️ Minecart", "Viajando para %s..." % loc.name, "info", 2.0)

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/minecart_travel.ogg")

	# Fecha UI
	hide()

func _on_location_unlocked(location: String) -> void:
	if not unlocked_locations.has(location):
		unlocked_locations.append(location)
		_update_ui()
		UIStyle.show_toast("⛏️ Novo Destino!", "%s desbloqueado!" % LOCATIONS.find({"id": location})?.name ?? location, "achievement")

func _on_travel_completed(location: String) -> void:
	current_location = location
	_update_ui()
	HUD.show_message("Chegou em %s!" % LOCATIONS.find({"id": location})?.name ?? location)

## ==================== PÚBLICO ====================
func open() -> void:
	visible = true
	panel.visible = true
	popup_centered()
	_load_progress()
	_update_ui()
	_get_tree().paused = true

func hide() -> void:
	visible = false
	panel.visible = false
	_get_tree().paused = false