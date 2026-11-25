extends Node

## Sistema de Pesca completo: minigame, peixes por estação/hora/clima/local, iscas, anzóis

@export var fishing_minigame_scene: PackedScene
@export var fish_data_path: String = "res://resources/data/Fish.json"  # Dados extras de peixes

## Estado
var is_fishing: bool = false
var fishing_spot: Node2D = null
var current_rod: String = ""  # "Bamboo", "Fiberglass", "Iridium"
var current_bait: String = ""  # "Bait", "Magnet", "Wild Bait"
var current_tackle: String = ""  # "Spinner", "Trap Bobber", "Cork Bobber", etc.
var fishing_level: int = 0

## Minigame
var fish_bar_position: float = 0.5  # 0.0 a 1.0
var fish_position: float = 0.5
var fish_velocity: float = 0.0
var bar_size: float = 0.15  # Tamanho da barra (aumenta com nível)
var difficulty: float = 1.0
var catch_progress: float = 0.0  # 0.0 a 1.0
var perfect_catch: bool = true
var time_fishing: float = 0.0

## Peixe atual
var hooked_fish: Dictionary = {}
var fish_quality: int = 0
var fish_size: float = 1.0

## ==================== SINAIS ====================
signal fishing_started(spot: Node2D)
signal fishing_ended(caught: bool, fish_data: Dictionary)
signal fish_hooked(fish_data: Dictionary)
signal fish_escaped(fish_data: Dictionary)
signal perfect_catch_achieved(fish_data: Dictionary)
signal level_up(new_level: int)
signal treasure_found(treasure_data: Dictionary)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Carrega cena do minigame
	if not fishing_minigame_scene:
		fishing_minigame_scene = load("res://scenes/ui/fishing_minigame.tscn")

	# Carrega dados de peixes (se arquivo existir)
	_load_fish_data()

func _load_fish_data() -> void:
	# Fish.json seria um arquivo extra com dados detalhados
	# Por enquanto usa Object.json + FishPondData.json
	pass

## ==================== INICIAR PESCA ====================
## Chamado quando player usa vara de pescar na água
func start_fishing(spot: Node2D, rod_type: String = "") -> void:
	if is_fishing:
		return

	# Determina vara equipada
	current_rod = rod_type
	if current_rod == "":
		var equipped = InventoryManager.get_equipped_tool()
		if equipped.begins_with("(T)5"):  # Fishing Rod
			var rod_level = InventoryManager.get_tool_level("FishingRod")
			current_rod = ["Bamboo", "Fiberglass", "Iridium"][rod_level]

	# Determina isca/anzol no inventário
	_determine_tackle()

	# Nível de pesca
	fishing_level = GameManager.skill_levels[3] if GameManager else 0

	# Configura barra
	bar_size = 0.1 + (fishing_level * 0.01)  # 10% base + 1% por nível
	if current_rod == "Fiberglass":
		bar_size += 0.05
	elif current_rod == "Iridium":
		bar_size += 0.1

	# Seleciona peixe
	hooked_fish = _select_fish(spot)
	if not hooked_fish:
		_show_message("Nenhum peixe mordeu...")
		return

	is_fishing = true
	fishing_spot = spot
	fish_bar_position = 0.5
	fish_position = 0.5
	fish_velocity = 0.0
	catch_progress = 0.0
	perfect_catch = true
	time_fishing = 0.0

	# Dificuldade baseada no peixe
	difficulty = hooked_fish.get("difficulty", 50) / 100.0

	# Qualidade e tamanho
	fish_quality = _determine_quality()
	fish_size = randf_range(0.8, 1.3)

	# Abre minigame
	_open_minigame()

	emit_signal("fishing_started", spot)

func _determine_tackle() -> void:
	# Verifica inventário por isca e anzol
	current_bait = ""
	current_tackle = ""

	var has_bait = InventoryManager.has_item("(O)685")  # Bait
	var has_magnet = InventoryManager.has_item("(O)702")  # Magnet
	var has_wild_bait = InventoryManager.has_item("(O)773")  # Wild Bait

	if has_wild_bait:
		current_bait = "Wild Bait"
	elif has_magnet:
		current_bait = "Magnet"
	elif has_bait:
		current_bait = "Bait"

	var has_spinner = InventoryManager.has_item("(O)690")  # Spinner
	var has_trap = InventoryManager.has_item("(O)691")  # Trap Bobber
	var has_cork = InventoryManager.has_item("(O)692")  # Cork Bobber
	var has_dressed = InventoryManager.has_item("(O)693")  # Dressed Spinner
	var has_barbed = InventoryManager.has_item("(O)694")  # Barbed Hook
	var has_treasure = InventoryManager.has_item("(O)695")  # Treasure Hunter

	if has_treasure:
		current_tackle = "Treasure Hunter"
	elif has_dressed:
		current_tackle = "Dressed Spinner"
	elif has_barbed:
		current_tackle = "Barbed Hook"
	elif has_trap:
		current_tackle = "Trap Bobber"
	elif has_cork:
		current_tackle = "Cork Bobber"
	elif has_spinner:
		current_tackle = "Spinner"

	# Consome isca (exceto Magnet)
	if current_bait != "" and current_bait != "Magnet":
		InventoryManager.remove_item(_get_bait_item_id(current_bait), 1)

func _get_bait_item_id(bait: String) -> String:
	var baits = {"Bait": "(O)685", "Wild Bait": "(O)773", "Magnet": "(O)702"}
	return baits.get(bait, "")

## ==================== SELEÇÃO DE PEIXE ====================
func _select_fish(spot: Node2D) -> Dictionary:
	# Obtém parâmetros atuais
	var season = GameManager.current_season if GameManager else 0
	var time = GameManager.current_time if GameManager else 1200
	var weather = GameManager.today_weather if GameManager else 0
	var location = spot.get("location_type", "river")  # "river", "lake", "ocean", "pond", "submarine"

	# Filtra peixes disponíveis
	var available_fish = _get_available_fish(location, season, time, weather)

	if available_fish.is_empty():
		return null

	# Calcula pesos baseados em isca/anzol
	var weights = []
	var total_weight = 0.0

	for fish in available_fish:
		var weight = fish.get("base_chance", 1.0)

		# Bônus de isca
		if current_bait == "Bait":
			weight *= 1.5
		elif current_bait == "Wild Bait":
			weight *= 2.0
		elif current_bait == "Magnet":
			# Magnet só pega tesouros, não peixes
			weight = 0

		# Bônus de anzol
		if current_tackle == "Spinner":
			weight *= 1.2
		elif current_tackle == "Trap Bobber":
			weight *= 1.3  # Mais fácil de pegar
		elif current_tackle == "Cork Bobber":
			weight *= 1.1

		weights.append(weight)
		total_weight += weight

	# Seleção ponderada
	var rand_val = randf() * total_weight
	var accum = 0.0
	for i in range(weights.size()):
		accum += weights[i]
		if rand_val <= accum:
			return available_fish[i]

	return available_fish[0]  # Fallback

func _get_available_fish(location: String, season: int, time: int, weather: int) -> Array:
	# Base: peixes do FishPondData.json + Objects.json
	# Por enquanto, retorna lista hardcoded simplificada
	var all_fish = []

	# Dados base de peixes (simulando Fish.json)
	var fish_database = {
		# Peixes de rio
		"river": {
			"spring": [
				{"id": "(O)152", "name": "Sunfish", "difficulty": 20, "base_chance": 1.0, "time": "6-19", "weather": [0,1]},
				{"id": "(O)148", "name": "Shad", "difficulty": 30, "base_chance": 0.8, "time": "9-14", "weather": [1,2]},
				{"id": "(O)150", "name": "Catfish", "difficulty": 50, "base_chance": 0.3, "time": "6-24", "weather": [1,2]},
			],
			"summer": [
				{"id": "(O)152", "name": "Sunfish", "difficulty": 20, "base_chance": 1.0},
				{"id": "(O)149", "name": "Bream", "difficulty": 25, "base_chance": 0.9},
				{"id": "(O)150", "name": "Catfish", "difficulty": 50, "base_chance": 0.3, "weather": [1,2]},
			],
			"fall": [
				{"id": "(O)153", "name": "Tiger Trout", "difficulty": 40, "base_chance": 0.5, "time": "6-19"},
				{"id": "(O)150", "name": "Catfish", "difficulty": 50, "base_chance": 0.3, "weather": [1,2]},
				{"id": "(O)151", "name": "Salmon", "difficulty": 35, "base_chance": 0.6},
			],
			"winter": [
				{"id": "(O)154", "name": "Lingcod", "difficulty": 45, "base_chance": 0.4},
				{"id": "(O)150", "name": "Catfish", "difficulty": 50, "base_chance": 0.2, "weather": [1,2]},
			]
		},
		# Peixes de lago
		"lake": {
			"spring": [
				{"id": "(O)152", "name": "Sunfish", "difficulty": 20, "base_chance": 1.0},
				{"id": "(O)148", "name": "Shad", "difficulty": 30, "base_chance": 0.8},
				{"id": "(O)155", "name": "Carp", "difficulty": 35, "base_chance": 0.5},
			],
			"summer": [
				{"id": "(O)156", "name": "Bullhead", "difficulty": 30, "base_chance": 0.7},
				{"id": "(O)149", "name": "Bream", "difficulty": 25, "base_chance": 0.9},
				{"id": "(O)150", "name": "Catfish", "difficulty": 50, "base_chance": 0.3},
			],
			"fall": [
				{"id": "(O)157", "name": "Sturgeon", "difficulty": 60, "base_chance": 0.2, "time": "6-19"},
				{"id": "(O)155", "name": "Carp", "difficulty": 35, "base_chance": 0.5},
			],
			"winter": [
				{"id": "(O)154", "name": "Lingcod", "difficulty": 45, "base_chance": 0.4},
			]
		},
		# Peixes de oceano
		"ocean": {
			"spring": [
				{"id": "(O)158", "name": "Sardine", "difficulty": 15, "base_chance": 1.0},
				{"id": "(O)159", "name": "Anchovy", "difficulty": 15, "base_chance": 0.9},
				{"id": "(O)160", "name": "Tuna", "difficulty": 55, "base_chance": 0.2, "time": "6-19"},
			],
			"summer": [
				{"id": "(O)161", "name": "Red Snapper", "difficulty": 50, "base_chance": 0.3, "weather": [1,2]},
				{"id": "(O)162", "name": "Tilapia", "difficulty": 40, "base_chance": 0.4, "time": "6-14"},
				{"id": "(O)163", "name": "Dorado", "difficulty": 60, "base_chance": 0.15},
			],
			"fall": [
				{"id": "(O)164", "name": "Albacore", "difficulty": 45, "base_chance": 0.3, "time": "6-11,18-24"},
				{"id": "(O)165", "name": "Super Cucumber", "difficulty": 70, "base_chance": 0.1, "time": "18-2"},
			],
			"winter": [
				{"id": "(O)166", "name": "Squid", "difficulty": 40, "base_chance": 0.4, "time": "18-2"},
				{"id": "(O)167", "name": "Herring", "difficulty": 20, "base_chance": 0.8},
			]
		}
	}

	var season_names = ["spring", "summer", "fall", "winter"]
	var season_fish = fish_database.get(location, {}).get(season_names[season], [])

	# Filtra por hora e clima
	var result = []
	for fish in season_fish:
		# Verifica hora
		if fish.has("time"):
			var time_ok = _check_time_range(time, fish["time"])
			if not time_ok:
				continue

		# Verifica clima
		if fish.has("weather"):
			if weather not in fish["weather"]:
				continue

		result.append(fish)

	return result

func _check_time_range(current_time: int, time_range: String) -> bool:
	# Formato: "6-19" ou "6-11,18-24"
	var ranges = time_range.split(",")
	for r in ranges:
		var parts = r.split("-")
		if parts.size() == 2:
			var start = parts[0].to_int() * 100
			var end = parts[1].to_int() * 100
			if end < start:  # Passa da meia-noite (ex: 18-2)
				if current_time >= start or current_time <= end:
					return true
			else:
				if current_time >= start and current_time <= end:
					return true
	return true  # Sem restrição

## ==================== QUALIDADE E TAMANHO ====================
func _determine_quality() -> int:
	var chance = 0.0

	# Nível de pesca
	chance += fishing_level * 0.02

	# Vara
	match current_rod:
		"Fiberglass": chance += 0.1
		"Iridium": chance += 0.2

	# Anzol
	if current_tackle == "Barbed Hook":
		chance += 0.15
	elif current_tackle == "Dressed Spinner":
		chance += 0.1

	# Sorte
	chance += GameManager.daily_luck * 0.5

	# Profissão Angler (level 10 fishing)
	if GameManager and GameManager.professions.get("Fishing") == 0:
		chance += 0.2

	# Profissão Pirate (level 10 fishing)
	if GameManager and GameManager.professions.get("Fishing") == 1:
		chance += 0.1  # Chance de tesouro

	if chance > 0.8:
		return 3  # Irídio
	elif chance > 0.5:
		return 2  # Ouro
	elif chance > 0.2:
		return 1  # Prata
	return 0  # Normal

## ==================== MINIGAME ====================
func _open_minigame() -> void:
	# Carrega cena do minigame melhorado se não definida
	if not fishing_minigame_scene:
		fishing_minigame_scene = load("res://scenes/ui/fishing_minigame.tscn")

	var minigame = fishing_minigame_scene.instantiate()
	minigame.initialize(self, hooked_fish, difficulty, bar_size)
	get_tree().root.get_child(0).add_child(minigame)

func _simulate_minigame() -> void:
	# Simulação automática baseada em habilidade
	var success_chance = 0.5 + (fishing_level * 0.03)
	if current_rod == "Fiberglass":
		success_chance += 0.1
	elif current_rod == "Iridium":
		success_chance += 0.2

	if current_tackle == "Trap Bobber":
		success_chance += 0.15

	success_chance = min(0.95, success_chance)

	if randf() < success_chance:
		_on_fish_caught(true)
	else:
		_on_fish_caught(false)

## ==================== CALLBACKS DO MINIGAME ====================
## Chamado pelo minigame a cada frame
func update_minigame(delta: float, input_up: bool, input_down: bool) -> Dictionary:
	if not is_fishing:
		return {}

	time_fishing += delta

	# Movimento do peixe (comportamento baseado na dificuldade)
	_update_fish_behavior(delta)

	# Movimento da barra (player)
	var bar_speed = 3.0
	if current_rod == "Iridium":
		bar_speed = 4.0

	if input_up:
		fish_bar_position -= bar_speed * delta
	if input_down:
		fish_bar_position += bar_speed * delta

	fish_bar_position = clamp(fish_bar_position, 0.0, 1.0 - bar_size)

	# Verifica se peixe está na barra
	var bar_bottom = fish_bar_position
	var bar_top = fish_bar_position + bar_size
	var fish_in_bar = fish_position >= bar_bottom and fish_position <= bar_top

	if fish_in_bar:
		catch_progress += delta * 0.5  # Velocidade de captura
		if catch_progress >= 1.0:
			_on_fish_caught(true)
			return {"caught": true}
	else:
		catch_progress -= delta * 0.3  # Peixe escapa
		perfect_catch = false
		if catch_progress <= 0.0:
			_on_fish_caught(false)
			return {"escaped": true}

	return {
		"fish_position": fish_position,
		"bar_position": fish_bar_position,
		"bar_size": bar_size,
		"catch_progress": catch_progress,
		"perfect": perfect_catch
	}

func _update_fish_behavior(delta: float) -> void:
	# Peixe tem comportamento "pulante"
	var target_velocity = 0.0

	# Alterna direção periodicamente
	if randf() < 0.02:
		fish_velocity = (randf() - 0.5) * 2.0 * difficulty * 2.0

	# Aplica gravidade/arrasto
	fish_velocity *= 0.98
	fish_position += fish_velocity * delta

	# Mantém dentro dos limites
	fish_position = clamp(fish_position, 0.05, 0.95)

	# Comportamento especial por tipo de peixe
	var fish_type = hooked_fish.get("name", "")
	if "Legendary" in fish_type or "Legend" in fish_type:
		# Lendários são mais erráticos
		fish_velocity *= 1.5

func _on_fish_caught(success: bool) -> void:
	is_fishing = false

	if success:
		var fish_item_id = hooked_fish.get("id", "")
		var fish_data = {
			"item_id": fish_item_id,
			"quality": fish_quality,
			"size": fish_size,
			"perfect": perfect_catch,
			"time": time_fishing
		}

		# Adiciona ao inventário
		InventoryManager.add_item(fish_item_id, 1)

		# XP de pesca
		var base_xp = hooked_fish.get("xp", 10)
		var xp = int(base_xp * fish_size)
		if perfect_catch:
			xp = int(xp * 1.4)
		GameManager.add_skill_xp(3, xp)

		# Estatísticas
		if GameManager:
			GameManager.stats.fish_caught += 1

		# Chance de tesouro
		if current_tackle == "Treasure Hunter" and randf() < 0.2:
			_spawn_treasure()

		emit_signal("fishing_ended", true, fish_data)
		emit_signal("fish_hooked", fish_data)

		if perfect_catch:
			emit_signal("perfect_catch_achieved", fish_data)
	else:
		emit_signal("fishing_ended", false, hooked_fish)
		emit_signal("fish_escaped", hooked_fish)

	hooked_fish = null
	fishing_spot = null

func _spawn_treasure() -> void:
	# Tesouros baseados no nível e sorte
	var treasures = [
		{"item_id": "(O)382", "amount": randi_range(1, 3)},  # Copper Ore
		{"item_id": "(O)384", "amount": randi_range(1, 2)},  # Iron Ore
		{"item_id": "(O)386", "amount": 1},  # Gold Ore
		{"id": "(O)388", "amount": 1},  # Iridium Ore
		{"item_id": "(O)535", "amount": 1},  # Geode
		{"item_id": "(O)536", "amount": 1},  # Frozen Geode
		{"item_id": "(O)537", "amount": 1},  # Magma Geode
		{"item_id": "(O)100", "amount": randi_range(5, 20)},  # Gold
	]

	var treasure = treasures[randi() % treasures.size()]
	InventoryManager.add_item(treasure.item_id, treasure.amount)
	emit_signal("treasure_found", treasure)

## ==================== UTILIDADES ====================
func get_fish_data(item_id: String) -> Dictionary:
	# Retorna dados completos do peixe
	var item = DataLoader.get_item(item_id)
	if item:
		return {
			"id": item_id,
			"name": item.get_display_name(),
			"price": item.price,
			"description": item.description
		}
	return {}

func is_fishing_active() -> bool:
	return is_fishing

func _show_message(text: String) -> void:
	print("Fishing: %s" % text)
	# TODO: Toast notification