class_name MultiplayerSync
extends Node

## Sistema de Sincronização Multiplayer (preparação para futuro)

## ==================== CONFIGURAÇÃO ====================
@export var max_players: int = 4
@export var sync_rate: float = 30.0  # Hz
@export var use_relay_server: bool = true

## Estado
var is_host: bool = false
var connected_players: Dictionary = {}  # peer_id -> player_data
var player_count: int = 1
var local_player_id: int = 1

## Dados sincronizados
var sync_data: Dictionary = {
	"world": {
		"time": 600,
		"day": 1,
		"season": 0,
		"year": 1,
		"weather": 0,
		"luck": 0.0
	},
	"players": {},
	"farm": {
		"crops": {},
		"animals": {},
		"buildings": {},
		"machines": {}
	},
	"npcs": {},
	"shared": {
		"gold": 0,
		"community_center": {},
		"museum": {},
		"shipping_bin": {}
	}
}

## ==================== SINAIS ====================
signal player_joined(peer_id: int, player_data: Dictionary)
signal player_left(peer_id: int)
signal host_changed(new_host_id: int)
signal sync_requested(data_type: String)
signal desync_detected(peer_id: int, data_type: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Inicializa multiplayer
	_multiplayer_init()

func _multiplayer_init() -> void:
	# Configura multiplayer
	multiplayer.poll_interval = 1000 / sync_rate

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## ==================== HOST ====================
func host_game(port: int = 8910, max_players: int = 4) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(port, max_players)
	if err != OK:
		return err

	multiplayer.multiplayer_peer = peer
	is_host = true
	local_player_id = 1
	player_count = 1

	# Inicializa dados do host
	_initialize_host_data()

	HUD.show_notification("🌐 Servidor Criado!", "Aguardando jogadores... (Porta %d)" % port, Color(0.5, 1.0, 0.5))
	return OK

func _initialize_host_data() -> void:
	sync_data.world.time = GameManager.current_time if GameManager else 600
	sync_data.world.day = GameManager.current_day if GameManager else 1
	sync_data.world.season = GameManager.current_season if GameManager else 0
	sync_data.world.year = GameManager.current_year if GameManager else 1
	sync_data.world.weather = GameManager.today_weather if GameManager else 0
	sync_data.world.luck = GameManager.daily_luck if GameManager else 0.0

	# Registra host como player 1
	var player = get_tree().get_first_node_in_group("player")
	var player_position = player.global_position if player != null else Vector2(320, 240)
	connected_players[1] = {
		"id": 1,
		"name": GameManager.player_name if GameManager else "Host",
		"position": player_position,
		"farm_level": 0,
		"ready": true
	}

	sync_data.players[1] = connected_players[1]

## ==================== CLIENT ====================
func join_game(ip: String, port: int = 8910, player_name: String = "Player") -> Error:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, port)
	if err != OK:
		return err

	multiplayer.multiplayer_peer = peer
	is_host = false
	local_player_id = -1  # Será atribuído pelo servidor

	HUD.show_notification("🌐 Conectando...", "Conectando a %s:%d" % [ip, port], Color(0.5, 0.8, 1.0))
	return OK

## ==================== CALLBACKS DE CONEXÃO ====================
func _on_peer_connected(peer_id: int) -> void:
	if is_host:
		# Novo jogador conectou
		player_count += 1
		var new_id = player_count

		connected_players[peer_id] = {
			"id": new_id,
			"name": "Player %d" % new_id,
			"position": Vector2(320, 240),
			"farm_level": 0,
			"ready": false
		}

		# Envia ID para o novo jogador
		rpc_id(peer_id, "_assign_player_id", new_id, sync_data)

		# Notifica outros jogadores
		rpc("player_joined_notification", new_id, connected_players[peer_id])

		HUD.show_message("Jogador %d entrou!" % new_id)

func _on_peer_disconnected(peer_id: int) -> void:
	if is_host and connected_players.has(peer_id):
		var player_data = connected_players[peer_id]
		connected_players.erase(peer_id)
		player_count -= 1

		# Notifica outros
		rpc("player_left_notification", player_data.id)

		HUD.show_message("Jogador %s saiu." % player_data.name)

func _on_connected_to_server() -> void:
	HUD.show_message("Conectado ao servidor! Aguardando ID...")

func _on_connection_failed() -> void:
	HUD.show_notification("❌ Falha na Conexão", "Não foi possível conectar ao servidor.", Color(1.0, 0.3, 0.3))

func _on_server_disconnected() -> void:
	if not is_host:
		HUD.show_notification("🔌 Desconectado", "Servidor desconectou.", Color(1.0, 0.5, 0.5))
		multiplayer.multiplayer_peer = null
		_return_to_main_menu()

## ==================== RPCs ====================
@rpc("any_peer", "reliable")
func _assign_player_id(new_id: int, initial_sync: Dictionary) -> void:
	local_player_id = new_id
	sync_data = initial_sync

	# Inicializa mundo local com dados do servidor
	_apply_sync_data(initial_sync)

	# Marca como pronto
	rpc_id(1, "_player_ready", local_player_id)

	HUD.show_notification("✅ Conectado!", "Seu ID: %d" % local_player_id, Color(0.5, 1.0, 0.5))

@rpc("authority", "reliable")
func _player_ready(player_id: int) -> void:
	if is_host and connected_players.has(player_id):
		connected_players[player_id].ready = true
		connected_players[player_id].id = player_id

		# Verifica se todos prontos
		var all_ready = true
		for p in connected_players.values():
			if not p.ready:
				all_ready = false
				break

		if all_ready:
			rpc("all_players_ready")

@rpc("authority", "reliable")
func _all_players_ready() -> void:
	HUD.show_notification("🎮 Todos Prontos!", "Iniciando jogo...", Color(0.5, 1.0, 0.5))
	_start_multiplayer_game()

@rpc("any_peer", "reliable")
func _start_multiplayer_game() -> void:
	_get_tree().paused = false
	HUD.show_message("Jogo multiplayer iniciado!")

@rpc("any_peer", "reliable")
func player_joined_notification(new_id: int, player_data: Dictionary) -> void:
	connected_players[new_id] = player_data
	HUD.show_notification("👋 Jogador Entrou", "%s entrou no jogo!" % player_data.name, Color(0.5, 1.0, 0.5))

@rpc("any_peer", "reliable")
func player_left_notification(player_id: int) -> void:
	if connected_players.has(player_id):
		var name = connected_players[player_id].name
		connected_players.erase(player_id)
		HUD.show_notification("👋 Jogador Saiu", "%s saiu do jogo." % name, Color(1.0, 0.5, 0.5))

## ==================== SINCRONIZAÇÃO ====================
func _process(delta: float) -> void:
	if is_host:
		_broadcast_sync()
	else:
		_request_sync()

func _broadcast_sync() -> void:
	# Atualiza dados do mundo
	if GameManager:
		sync_data.world.time = GameManager.current_time
		sync_data.world.day = GameManager.current_day
		sync_data.world.season = GameManager.current_season
		sync_data.world.year = GameManager.current_year
		sync_data.world.weather = GameManager.today_weather
		sync_data.world.luck = GameManager.daily_luck

	# Atualiza posição do host
	var host_player = get_tree().get_first_node_in_group("player")
	if host_player:
		sync_data.players[1].position = host_player.global_position

	# Envia para todos
	rpc("receive_sync", sync_data)

@rpc("any_peer", "reliable")
func receive_sync(data: Dictionary) -> void:
	sync_data = data
	_apply_sync_data(data)

func _request_sync() -> void:
	rpc_id(1, "request_sync", local_player_id)

@rpc("authority", "reliable")
func request_sync(player_id: int) -> void:
	rpc_id(player_id, "receive_sync", sync_data)

func _apply_sync_data(data: Dictionary) -> void:
	# Aplica dados de tempo
	if GameManager and data.has("world"):
		var world = data.world
		GameManager.current_time = world.time
		GameManager.current_day = world.day
		GameManager.current_season = world.season
		GameManager.current_year = world.year
		GameManager.today_weather = world.weather
		GameManager.daily_luck = world.luck

	# Aplica posições de outros jogadores
	if data.has("players"):
		for id in data.players:
			if id != local_player_id:
				var player_data = data.players[id]
				_update_remote_player(id, player_data)

func _update_remote_player(player_id: int, data: Dictionary) -> void:
	# Atualiza sprite do jogador remoto
	var remote_player = get_tree().root.get_child(0).get_node_or_null("RemotePlayer_%d" % player_id)
	if not remote_player:
		remote_player = _create_remote_player(player_id, data.name)
	remote_player.global_position = data.position

func _create_remote_player(player_id: int, name: String) -> Node2D:
	var player = Node2D.new()
	player.name = "RemotePlayer_%d" % player_id

	var sprite = Sprite2D.new()
	sprite.texture = load("res://resources/sprites/player_remote.png") if ResourceLoader.exists("res://resources/sprites/player_remote.png") else null
	if not sprite.texture:
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.5, 0.5, 1.0))
		sprite.texture = ImageTexture.create_from_image(img)
	player.add_child(sprite)

	var label = Label.new()
	label.text = name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_override_font_size = 12
	label.position = Vector2(0, -20)
	player.add_child(label)

	get_tree().root.get_child(0).add_child(player)
	return player

## ==================== SINCRONIZAÇÃO DE AÇÕES ====================
@rpc("any_peer", "reliable")
func sync_player_action(action: String, data: Dictionary) -> void:
	# Sincroniza ações: movimento, uso de ferramenta, interação, etc.
	match action:
		"move":
			var pid = data.player_id
			var remote = get_tree().root.get_child(0).get_node_or_null("RemotePlayer_%d" % pid)
			if remote:
				remote.global_position = data.position
				remote.rotation = data.rotation
		"tool_use":
			# Sincroniza uso de ferramenta
			_sync_tool_use(data)
		"interact":
			_sync_interaction(data)
		"harvest":
			_sync_harvest(data)
		"plant":
			_sync_plant(data)
		"water":
			_sync_water(data)
		"chat":
			_show_chat_message(data.player_id, data.message)

## ==================== CHAT ====================
@rpc("any_peer", "reliable")
func send_chat_message(player_id: int, message: String) -> void:
	rpc("chat_message_received", player_id, message)

@rpc("any_peer", "reliable")
func chat_message_received(player_id: int, message: String) -> void:
	# Mostra no chat UI
	if HUD:
		var name = connected_players[player_id].name if connected_players.has(player_id) else "Player %d" % player_id
		HUD.show_message("[%s] %s" % [name, message])

## ==================== SINCRONIZAÇÃO DE FAZENDA ====================
func sync_farm_data() -> void:
	if not is_host:
		return

	var farm_data = {
		"crops": GameManager.farm_crops,
		"animals": GameManager.farm_animals,
		"buildings": GameManager.farm_buildings,
		"machines": GameManager.placed_machines
	}
	rpc("farm_data_sync", farm_data)

@rpc("any_peer", "reliable")
func farm_data_sync(data: Dictionary) -> void:
	if is_host:
		return

	GameManager.farm_crops = data.crops
	GameManager.farm_animals = data.animals
	GameManager.farm_buildings = data.buildings
	GameManager.placed_machines = data.machines

	# Recria visual
	_rebuild_farm_visual()

func _rebuild_farm_visual() -> void:
	# Recria culturas
	if WorldInit:
		WorldInit._load_saved_crops()

	# Recria edifícios
	if BuildingManager:
		BuildingManager._load_saved_buildings()

	# Recria animais
	# ...

## ==================== SINCRONIZAÇÃO DE INVENTÁRIO ====================
func sync_inventory(player_id: int) -> void:
	var inv_data = {
		"inventory": GameManager.inventory,
		"hotbar": GameManager.hotbar,
		"gold": GameManager.gold
	}
	rpc_id(player_id, "inventory_sync", inv_data)

@rpc("any_peer", "reliable")
func inventory_sync(data: Dictionary) -> void:
	GameManager.inventory = data.inventory
	GameManager.hotbar = data.hotbar
	GameManager.gold = data.gold
	GameManager.emit_signal("gold_changed", data.gold)

	if InventoryManager:
		InventoryManager.emit_signal("inventory_changed")
		InventoryManager.emit_signal("hotbar_changed")

## ==================== DESYNC DETECTION ====================
func check_desync() -> void:
	if not is_host:
		# Compara hash dos dados críticos
		var local_hash = _calculate_world_hash()
		rpc_id(1, "check_desync_hash", local_player_id, local_hash)

@rpc("authority", "reliable")
func check_desync_hash(player_id: int, hash: int) -> void:
	var server_hash = _calculate_world_hash()
	if hash != server_hash:
		rpc_id(player_id, "desync_detected", "world_data")
		# Force re-sync
		rpc_id(player_id, "receive_sync", sync_data)

@rpc("any_peer", "reliable")
func desync_detected(data_type: String) -> void:
	emit_signal("desync_detected", local_player_id, data_type)
	HUD.show_notification("⚠️ Desync Detectado!", "Re-sincronizando %s..." % data_type, Color(1.0, 0.8, 0.2))
	rpc_id(1, "request_full_sync", local_player_id)

func _calculate_world_hash() -> int:
	# Hash simples dos dados críticos
	var str = "%d%d%d%d%d" % [
		GameManager.current_time,
		GameManager.current_day,
		GameManager.gold,
		GameManager.farm_crops.size(),
		GameManager.farm_animals.size()
	]
	return str.hash()

## ==================== COMANDOS DE ADMIN (HOST) ====================
@rpc("authority", "reliable")
func kick_player(target_id: int, reason: String) -> void:
	if not is_host:
		return

	if connected_players.has(target_id):
		rpc_id(target_id, "force_disconnect", reason)
		connected_players.erase(target_id)
		player_count -= 1
		rpc("player_left_notification", target_id)

@rpc("any_peer", "reliable")
func force_disconnect(reason: String) -> void:
	HUD.show_notification("🚫 Desconectado", "Você foi expulso: %s" % reason, Color(1.0, 0.3, 0.3))
	multiplayer.multiplayer_peer = null
	_return_to_main_menu()

@rpc("authority", "reliable")
func set_time(new_time: int) -> void:
	if not is_host:
		return
	GameManager.current_time = new_time
	GameManager.emit_signal("time_changed", new_time)
	rpc("time_changed", new_time)

@rpc("authority", "reliable")
func add_gold_to_all(amount: int) -> void:
	if not is_host:
		return
	for pid in connected_players:
		rpc_id(pid, "add_gold", amount)

@rpc("any_peer", "reliable")
func add_gold(amount: int) -> void:
	GameManager.gold += amount
	GameManager.emit_signal("gold_changed", GameManager.gold)

## ==================== RETORNO AO MENU ====================
func _return_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

## ==================== PERSISTÊNCIA ====================
func get_save_data() -> Dictionary:
	return {
		"is_host": is_host,
		"connected_players": connected_players,
		"sync_data": sync_data
	}

func load_save_data(data: Dictionary) -> void:
	is_host = data.get("is_host", false)
	connected_players = data.get("connected_players", {})
	sync_data = data.get("sync_data", {})