class_name MineCart
extends Node

## Sistema de Vagonetas (Minecarts): viagem rápida entre locais

@export var minecart_scene: PackedScene

## Estado
var unlocked_locations: Array = []  # Locais desbloqueados
var minecart_connected: Dictionary = {}  # {location: true}

## Locais das vagonetas (baseado no Stardew)
const LOCATIONS = {
	"Mines": {
		"display_name": "Minas",
		"description": "Entrada das minas (Andar 1)",
		"unlock_condition": "cc_boiler_room",  # Bundle Caldeira
		"position": Vector2(100, 100),
		"scene": "res://scenes/world/mine_entrance.tscn"
	},
	"Quarry": {
		"display_name": "Pedreira",
		"description": "Pedreira a oeste da cidade",
		"unlock_condition": "cc_crafts_room",  # Bundle Artesanato
		"position": Vector2(500, 500),
		"scene": "res://scenes/world/quarry.tscn"
	},
	"Town": {
		"display_name": "Cidade",
		"description": "Pelican Town - Loja do Pierre",
		"unlock_condition": "cc_fish_tank",  # Bundle Aquário
		"position": Vector2(300, 300),
		"scene": "res://scenes/world/town.tscn"
	},
	"Bus Stop": {
		"display_name": "Ponto de Ônibus",
		"description": "Ônibus para o Deserto (se reparado)",
		"unlock_condition": "cc_vault",  # Bundle Cofre
		"position": Vector2(400, 200),
		"scene": "res://scenes/world/bus_stop.tscn"
	}
}

## Rotas conectadas (bidirecional)
const ROUTES = {
	"Mines": ["Town"],
	"Quarry": ["Town"],
	"Town": ["Mines", "Quarry", "Bus Stop"],
	"Bus Stop": ["Town"]
}

## ==================== SINAIS ====================
signal location_unlocked(location: String)
signal travel_started(from: String, to: String)
signal travel_completed(location: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_progress()
	_check_unlocks()

func _load_progress() -> void:
	if not GameManager:
		return

	unlocked_locations = GameManager.get("minecart_unlocked", [])
	minecart_connected = GameManager.get("minecart_connected", {})

	# Garante que localizações desbloqueadas estão conectadas
	for loc in unlocked_locations:
		minecart_connected[loc] = true

func _check_unlocks() -> void:
	# Verifica condições de desbloqueio baseadas no Centro Comunitário
	if CommunityCenter:
		for loc_id, data in LOCATIONS:
			if loc_id not in unlocked_locations:
				var condition = data.unlock_condition
				if _check_condition(condition):
					unlock_location(loc_id)

func _check_condition(condition: String) -> bool:
	match condition:
		"cc_boiler_room":
			return CommunityCenter.room_status.get("Boiler Room", "") == "completed"
		"cc_crafts_room":
			return CommunityCenter.room_status.get("Crafts Room", "") == "completed"
		"cc_pantry":
			return CommunityCenter.room_status.get("Pantry", "") == "completed"
		"cc_fish_tank":
			return CommunityCenter.room_status.get("Fish Tank", "") == "completed"
		"cc_bulletin_board":
			return CommunityCenter.room_status.get("Bulletin Board", "") == "completed"
		"cc_vault":
			return CommunityCenter.room_status.get("Vault", "") == "completed"
		_:
			return false

func unlock_location(location: String) -> void:
	if location in unlocked_locations:
		return

	if not LOCATIONS.has(location):
		return

	unlocked_locations.append(location)
	minecart_connected[location] = true
	GameManager.set("minecart_unlocked", unlocked_locations)
	GameManager.set("minecart_connected", minecart_connected)

	emit_signal("location_unlocked", location)
	_show_message("Vagoneta para %s reparada!" % LOCATIONS[location].display_name)

## ==================== VIAGEM ====================
func can_travel_to(from_loc: String, to_loc: String) -> bool:
	if from_loc == to_loc:
		return false

	if not minecart_connected.has(from_loc) or not minecart_connected.has(to_loc):
		return false

	# Verifica rota direta
	var routes = ROUTES.get(from_loc, [])
	return to_loc in routes

func get_available_destinations(from_loc: String) -> Array:
	var destinations = []
	var routes = ROUTES.get(from_loc, [])
	for dest in routes:
		if minecart_connected.has(dest):
			destinations.append(dest)
	return destinations

func travel(from_loc: String, to_loc: String) -> bool:
	if not can_travel_to(from_loc, to_loc):
		return false

	emit_signal("travel_started", from_loc, to_loc)

	# Teleporta jogador
	var target_scene = LOCATIONS[to_loc].scene
	var target_pos = LOCATIONS[to_loc].position

	_change_scene(target_scene, target_pos)

	emit_signal("travel_completed", to_loc)
	return true

func _change_scene(scene_path: String, spawn_pos: Vector2) -> void:
	# Carrega cena de destino
	var new_scene = load(scene_path).instantiate()
	var current_world = get_tree().root.get_child(0)

	# Remove cena antiga (mantém player, HUD, etc)
	# Em implementação real, faria transição suave
	current_world.add_child(new_scene)

	# Move player
	var player = current_world.get_node_or_null("Player")
	if player:
		player.global_position = spawn_pos
		Camera2D.make_current()  # Atualiza câmera

## ==================== UI ====================
func open_minecart_menu(current_location: String) -> void:
	if MinecartUI:
		MinecartUI.open()
		return

	if minecart_scene:
		var ui = minecart_scene.instantiate()
		ui.initialize(current_location, get_available_destinations(current_location))
		get_tree().root.get_child(0).add_child(ui)
	else:
		_show_generic_minecart_ui(current_location)

func _show_generic_minecart_ui(current_location: String) -> void:
	var panel = Panel.new()
	panel.name = "MinecartUI"
	panel.anchors_preset = 15
	panel.offset_left = 150
	panel.offset_top = 100
	panel.offset_right = -150
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Sistema de Vagonetas"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var current_data = LOCATIONS.get(current_location, {})
	var current_name = current_data.get("display_name", current_location)

	var loc_label = Label.new()
	loc_label.text = "Local atual: %s" % current_name
	loc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(loc_label)

	var destinations = get_available_destinations(current_location)

	if destinations.is_empty():
		var lbl = Label.new()
		lbl.text = "Nenhum destino disponível.\nComplete bundles no Centro Comunitário para reparar vagonetas."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(lbl)
	else:
		for dest in destinations:
			var data = LOCATIONS[dest]
			var btn = Button.new()
			btn.text = "%s - %s" % [data.display_name, data.description]
			btn.custom_minimum_size = Vector2(0, 50)
			btn.pressed.connect(_on_destination_selected.bind(dest))
			vbox.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _on_destination_selected(destination: String) -> void:
	var player = get_tree().root.get_child(0).get_node_or_null("Player")
	var current_loc = _get_player_current_location(player)

	if travel(current_loc, destination):
		pass  # UI fechada automaticamente pela troca de cena

func _get_player_current_location(player: Node) -> String:
	# Determina local baseado na cena atual ou posição
	# Simplificado: retorna "Town" como padrão
	return "Town"

func get_unlocked_locations() -> Array:
	return unlocked_locations

func get_current_location() -> String:
	# Em implementação real, determinaria pela cena atual
	return "Bus Stop"

func travel_to(location: String) -> void:
	var player = get_tree().root.get_child(0).get_node_or_null("Player")
	var current_loc = _get_player_current_location(player)
	travel(current_loc, location)

func _show_message(text: String) -> void:
	print("MineCart: %s" % text)

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"unlocked_locations": unlocked_locations,
		"minecart_connected": minecart_connected
	}

func load_save_data(data: Dictionary) -> void:
	unlocked_locations = data.get("unlocked_locations", [])
	minecart_connected = data.get("minecart_connected", {})