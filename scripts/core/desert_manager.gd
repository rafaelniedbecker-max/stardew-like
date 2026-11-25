extends Node

## Gerencia a área do deserto: Skull Cavern, Oasis, Sandy's shop, bus

@export var desert_scene: PackedScene
@export var bus_scene: PackedScene

## Estado
var bus_repaired: bool = false
var bus_repair_progress: int = 0
var skull_cavern_unlocked: bool = false
var current_skull_level: int = 0
var deepest_skull_level: int = 0

## Skull Cavern config
const SKULL_CAVERN_MAX_LEVEL = 9999
const SKULL_CAVERN_REWARDS = {
	5: {"item": "(O)749", "name": "Prismatic Shard"},      # Level 5
	10: {"item": "(O)114", "name": "Ancient Seed"},         # Level 10
	25: {"item": "(O)768", "name": "Galaxy Sword"},         # Level 25 (se tiver)
	50: {"item": "(O)749", "amount": 3},                   # Level 50
	100: {"item": "(O)749", "amount": 5},                  # Level 100
}

## ==================== SINAIS ====================
signal bus_repaired_signal()
signal skull_cavern_unlocked_signal()
signal entered_skull_cavern(level: int)
signal exited_skull_cavern(level: int, deepest: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_state()

	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

	# Verifica se ônibus reparado
	if bus_repaired:
		_spawn_bus()

func _on_day_changed(day: int, season: int, year: int) -> void:
	# Reseta progresso diário da skull cavern
	current_skull_level = 0

	# Verifica reparo do ônibus via Community Center
	if not bus_repaired and CommunityCenter:
		if CommunityCenter.is_room_completed("Vault"):
			_repair_bus()

func _repair_bus() -> void:
	bus_repaired = true
	bus_repair_progress = 100
	_spawn_bus()
	emit_signal("bus_repaired_signal")
	HUD.show_notification("🚌 Ônibus Reparado!", "Agora você pode ir ao Deserto!", Color(0.5, 1.0, 0.5))
	_save_state()

func _spawn_bus() -> void:
	if not bus_scene:
		return

	var bus = bus_scene.instantiate()
	bus.name = "Bus"
	bus.global_position = Vector2(320, 400)  # Perto da fazenda
	get_tree().root.get_child(0).add_child(bus)

	# Adiciona interação
	var area = bus.get_node_or_null("InteractionArea")
	if area:
		area.area_entered.connect(_on_bus_entered)
		area.area_exited.connect(_on_bus_exited)

func _on_bus_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.show_interaction_prompt("E: Ir ao Deserto (500g)", global_position + Vector2(0, -50))

func _on_bus_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact_with_bus() -> void:
	if not bus_repaired:
		HUD.show_message("O ônibus está quebrado. Complete os pacotes do Vault no Centro Comunitário.")
		return

	if GameManager.gold < 500:
		HUD.show_message("Precisa de 500g para a viagem!")
		return

	GameManager.gold -= 500
	GameManager.emit_signal("gold_changed", GameManager.gold)
	_travel_to_desert()

func _travel_to_desert() -> void:
	# Carrega cena do deserto
	if desert_scene:
		var desert = desert_scene.instantiate()
		desert.name = "Desert"
		get_tree().root.get_child(0).add_child(desert)

		# Teleporta player
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = Vector2(400, 300)  # Entrada do deserto

		HUD.show_message("Viagem para o Deserto...")

		if AudioManager:
			AudioManager.play_sfx("res://assets/sfx/bus_travel.ogg")

func enter_skull_cavern() -> void:
	if not skull_cavern_unlocked:
		HUD.show_message("A Skull Cavern está selada. Encontre a Chave do Crânio.")
		return

	current_skull_level = 1
	deepest_skull_level = max(deepest_skull_level, 1)

	emit_signal("entered_skull_cavern", 1)

	# Carrega nível da Skull Cavern
	if MineManager:
		MineManager.enter_skull_cavern(1)

	HUD.show_notification("💀 Skull Cavern", "Nível 1 - Cuidado, é perigoso!", Color(1.0, 0.4, 0.4))

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/skull_cavern_enter.ogg")

	_save_state()

func go_deeper_skull_cavern() -> void:
	current_skull_level += 1
	deepest_skull_level = max(deepest_skull_level, current_skull_level)

	# Verifica recompensas de marco
	if SKULL_CAVERN_REWARDS.has(current_skull_level):
		var reward = SKULL_CAVERN_REWARDS[current_skull_level]
		if InventoryManager:
			var amount = reward.get("amount", 1)
			InventoryManager.add_item(reward.item, amount)
		HUD.show_notification("🏆 Marco Alcançado!", "Nível %d: %s!" % [current_skull_level, reward.name], Color(1.0, 0.9, 0.3))

	# Gera próximo nível
	if MineManager:
		MineManager.generate_skull_level(current_skull_level)

	_save_state()

func exit_skull_cavern() -> void:
	emit_signal("exited_skull_cavern", current_skull_level, deepest_skull_level)
	current_skull_level = 0

	# Volta pro deserto
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector2(400, 300)

	HUD.show_message("Você saiu da Skull Cavern. Nível mais profundo: %d" % deepest_skull_level)

	_save_state()

func unlock_skull_cavern() -> void:
	skull_cavern_unlocked = true
	emit_signal("skull_cavern_unlocked")
	HUD.show_notification("💀 Skull Cavern Desbloqueada!", "A chave funcionou! A entrada está aberta.", Color(1.0, 0.5, 0.5))
	_save_state()

## ==================== OASIS SHOP ====================
func open_oasis_shop() -> void:
	# Loja da Sandy (abre 9h-23h)
	if ShopUI:
		var special_items = _get_oasis_stock()
		ShopUI.open_shop("oasis", special_items)

func _get_oasis_stock() -> Array[Dictionary]:
	# Itens especiais do Oasis
	return [
		{"item_id": "(O)428", "price": 200, "stock": 5},    # Starfruit Seeds
		{"item_id": "(O)485", "price": 400, "stock": 3},    # Starfruit
		{"item_id": "(O)114", "price": 10000, "stock": 1},  # Ancient Seed (raro)
		{"item_id": "(O)749", "price": 5000, "stock": 1},   # Prismatic Shard
		{"item_id": "(O)768", "price": 2000, "stock": 2},   # Galaxy Sword material
		{"item_id": "(O)489", "price": 150, "stock": 10},   # Cactus Fruit
		{"item_id": "(O)490", "price": 200, "stock": 5},    # Cactus Seeds
	]

## ==================== PERSISTÊNCIA ====================
func _save_state() -> void:
	if GameManager:
		GameManager.set_data("desert_data", {
			"bus_repaired": bus_repaired,
			"bus_repair_progress": bus_repair_progress,
			"skull_cavern_unlocked": skull_cavern_unlocked,
			"deepest_skull_level": deepest_skull_level
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get_data("desert_data", {})
		if data:
			bus_repaired = data.get("bus_repaired", false)
			bus_repair_progress = data.get("bus_repair_progress", 0)
			skull_cavern_unlocked = data.get("skull_cavern_unlocked", false)
			deepest_skull_level = data.get("deepest_skull_level", 0)

			if bus_repaired:
				_spawn_bus()