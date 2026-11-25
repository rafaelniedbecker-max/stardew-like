extends Node

## Sistema de save/load usando JSON

## Pasta de saves
@export var save_folder: String = "user://saves/"

## Nome do arquivo de save atual
@export var current_save_file: String = "save_1.json"

## Slot de save ativo (1-4)
@export var active_slot: int = 1

## Auto-save a cada X minutos de jogo
@export var auto_save_interval: int = 60  # 1 hora in-game

## Tempo desde último auto-save
var _time_since_auto_save: int = 0

## ==================== SINAIS ====================
signal game_saved(slot: int, file_path: String)
signal game_loaded(slot: int, file_path: String)
signal save_failed(error: String)
signal load_failed(error: String)
signal auto_save_triggered()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Cria pasta de saves se não existir
	var dir = DirAccess.open(save_folder)
	if not dir:
		DirAccess.make_dir_recursive_absolute(save_folder)

	# Conecta ao TimeManager para auto-save
	if TimeManager:
		TimeManager.minute_ticked.connect(_on_minute_ticked)

	# Carrega save mais recente no início (opcional)
	# load_game(active_slot)

func _on_minute_ticked(new_time: int) -> void:
	_time_since_auto_save += 1
	if _time_since_auto_save >= auto_save_interval:
		_time_since_auto_save = 0
		auto_save()
		emit_signal("auto_save_triggered")

## ==================== SAVE ====================

## Salva jogo no slot especificado
func save_game(slot: int = -1) -> bool:
	if slot == -1:
		slot = active_slot

	var save_data = _collect_save_data()
	var file_path = save_folder + "save_%d.json" % slot

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		emit_signal("save_failed", "Não foi possível abrir arquivo para escrita: " + file_path)
		return false

	var json_str = JSON.stringify(save_data, "\t")
	file.store_string(json_str)
	file.close()

	current_save_file = "save_%d.json" % slot
	active_slot = slot
	emit_signal("game_saved", slot, file_path)
	print("SaveManager: Jogo salvo no slot %d" % slot)
	return true

## Auto-save (slot 0 = autosave)
func auto_save() -> void:
	var save_data = _collect_save_data()
	save_data["is_autosave"] = true
	save_data["timestamp"] = Time.get_unix_time_from_system()

	var file_path = save_folder + "autosave.json"
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("SaveManager: Auto-save realizado")

## Coleta todos os dados para save
func _collect_save_data() -> Dictionary:
	var data = {}

	# Metadados
	data["version"] = 1
	data["timestamp"] = Time.get_unix_time_from_system()
	data["slot"] = active_slot

	# GameManager state
	if GameManager:
		data["game"] = {
			"current_year": GameManager.current_year,
			"current_season": GameManager.current_season,
			"current_day": GameManager.current_day,
			"current_weekday": GameManager.current_weekday,
			"current_time": GameManager.current_time,
			"gold": GameManager.gold,
			"energy": GameManager.energy,
			"max_energy": GameManager.max_energy,
			"health": GameManager.health,
			"max_health": GameManager.max_health,
			"skill_levels": GameManager.skill_levels,
			"skill_xp": GameManager.skill_xp,
			"professions": GameManager.professions,
			"inventory": GameManager.inventory,
			"hotbar": GameManager.hotbar,
			"selected_hotbar_slot": GameManager.selected_hotbar_slot,
			"tools": GameManager.tools,
			"unlocked_recipes": GameManager.unlocked_recipes,
			"unlocked_cooking_recipes": GameManager.unlocked_cooking_recipes,
			"friendships": GameManager.friendships,
			"npcs_talked_today": GameManager.npcs_talked_today,
			"gifts_given_today": GameManager.gifts_given_today,
			"gifts_given_this_week": GameManager.gifts_given_this_week,
			"active_quests": GameManager.active_quests,
			"completed_quests": GameManager.completed_quests,
			"active_special_orders": GameManager.active_special_orders,
			"achievements": GameManager.achievements,
			"farm_buildings": GameManager.farm_buildings,
			"farm_crops": GameManager.farm_crops,
			"farm_animals": GameManager.farm_animals,
			"placed_machines": GameManager.placed_machines,
			"placed_objects": GameManager.placed_objects,
			"tomorrow_weather": GameManager.tomorrow_weather,
			"today_weather": GameManager.today_weather,
			"daily_luck": GameManager.daily_luck,
			"active_festival": GameManager.active_festival,
			"is_exhausted": GameManager.is_exhausted,
			"has_fainted": GameManager.has_fainted,
			"gold_lost_fainting": GameManager.gold_lost_fainting,
			"items_lost_on_death": GameManager.items_lost_on_death,
			"stats": GameManager.stats,
			"deepest_mine_level": GameManager.get_data("deepest_mine_level", 0),
			"mine_elevator_unlocked": GameManager.get_data("mine_elevator_unlocked", false),
			"mine_levels_cleared": GameManager.get_data("mine_levels_cleared", {}),
			"dating_npc": GameManager.get_data("dating_npc", ""),
			"spouse": GameManager.get_data("spouse", ""),
			"spouse_room_unlocked": GameManager.get_data("spouse_room_unlocked", false),
			"children": GameManager.get_data("children", []),
			"divorced_npcs": GameManager.get_data("divorced_npcs", []),
			"qi_gems": GameManager.get_data("qi_gems", 0),
			"wizard_reputation": GameManager.get_data("wizard_reputation", 0),
			"house_upgrade_2": GameManager.get_data("house_upgrade_2", false),
			"next_item_quality_boost": GameManager.get_data("next_item_quality_boost", 0),
			"instant_grow_next": GameManager.get_data("instant_grow_next", false),
			"star_tokens": GameManager.get_data("star_tokens", 0),
			"completed_special_orders": GameManager.get_data("special_orders_completed", []),
			"collection_shipped": GameManager.get_data("collection_shipped", {}),
			"collection_fish": GameManager.get_data("collection_fish", {}),
			"collection_artifacts": GameManager.get_data("collection_artifacts", {}),
			"collection_minerals": GameManager.get_data("collection_minerals", {}),
			"collection_recipes": GameManager.get_data("collection_recipes", {}),
			"known_recipes": GameManager.get_data("known_recipes", []),
			"museum_donated": GameManager.get_data("museum_donated", {}),
			"museum_counts": GameManager.get_data("museum_counts", {}),
			"museum_rewards_claimed": GameManager.get_data("museum_rewards_claimed", []),
			"cc_greenhouse_unlocked": GameManager.get_data("cc_greenhouse_unlocked", false),
			"greenhouse_unlocked": GameManager.get_data("greenhouse_unlocked", false),
			"minecart_unlocked": GameManager.get_data("minecart_unlocked", []),
			"minecart_connected": GameManager.get_data("minecart_connected", {}),
			"pet_friendship": GameManager.get_data("pet_friendship", 0),
			"pet_name": GameManager.get_data("pet_name", ""),
			"pet_type": GameManager.get_data("pet_type", "Cat"),
			"pet_last_pet_day": GameManager.get_data("pet_last_pet_day", -1),
			"tv_last_watched_day": GameManager.get_data("tv_last_watched_day", -1),
			"tv_watched_shows": GameManager.get_data("tv_watched_shows", {}),
			"mailbox": GameManager.get_data("mailbox", []),
			"read_mails": GameManager.get_data("read_mails", []),
			"next_mail_id": GameManager.get_data("next_mail_id", 1),
			"welcome_mail_sent": GameManager.get_data("welcome_mail_sent", false),
			"player_skin": GameManager.get_data("player_skin", 0),
			"player_hair": GameManager.get_data("player_hair", 0),
			"player_hair_color": GameManager.get_data("player_hair_color", 0),
			"player_eyes": GameManager.get_data("player_eyes", 0),
			"player_pants": GameManager.get_data("player_pants", 0),
			"player_pants_color": GameManager.get_data("player_pants_color", 0),
			"player_shirt": GameManager.get_data("player_shirt", 0),
			"player_shirt_color": GameManager.get_data("player_shirt_color", 0),
			"player_shoes": GameManager.get_data("player_shoes", 0),
			"player_accessory": GameManager.get_data("player_accessory", 0),
			"player_hat": GameManager.get_data("player_hat", -1),
			"player_gender": GameManager.get_data("player_gender", 0),
			"equipped_hat": GameManager.get_data("equipped_hat", ""),
			"equipped_shirt": GameManager.get_data("equipped_shirt", ""),
			"equipped_pants": GameManager.get_data("equipped_pants", ""),
			"equipped_boots": GameManager.get_data("equipped_boots", ""),
			"equipped_ring": GameManager.get_data("equipped_ring", ""),
			"equipped_ring2": GameManager.get_data("equipped_ring2", ""),
			"pet_data": GameManager.get_data("pet_data", {})
		}

	# Player position (precisa ser capturado da cena)
	data["player"] = _get_player_state()

	# World state (NPCs, etc.)
	data["world"] = _get_world_state()

	return data

## Captura estado do player (posição, animação, etc.)
func _get_player_state() -> Dictionary:
	# Busca player na cena atual
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_save_state"):
		return player.get_save_state()
	return {
		"position": Vector2(0, 0),
		"direction": 2,
		"animation": "idle"
	}

## Captura estado do mundo (NPCs, objetos dinâmicos)
func _get_world_state() -> Dictionary:
	var world = {}
	# NPCs positions, schedules, etc.
	# Implementar conforme necessário
	return world

## ==================== LOAD ====================

## Carrega jogo do slot especificado
func load_game(slot: int = -1) -> bool:
	if slot == -1:
		slot = active_slot

	var file_path = save_folder + "save_%d.json" % slot
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		emit_signal("load_failed", "Arquivo de save não encontrado: " + file_path)
		return false

	var json_str = file.get_as_text()
	file.close()

	var parse_result = JSON.parse_string(json_str)
	if not parse_result is Dictionary:
		emit_signal("load_failed", "O arquivo de save não contém um JSON válido: " + file_path)
		return false

	var save_data = parse_result
	_apply_save_data(save_data)
	active_slot = slot
	current_save_file = "save_%d.json" % slot
	emit_signal("game_loaded", slot, file_path)
	print("SaveManager: Jogo carregado do slot %d" % slot)
	return true

## Carrega auto-save
func load_autosave() -> bool:
	var file_path = save_folder + "autosave.json"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false

	var json_str = file.get_as_text()
	file.close()

	var save_data = JSON.parse_string(json_str)
	if not save_data is Dictionary:
		return false
	_apply_save_data(save_data)
	print("SaveManager: Auto-save carregado")
	return true

## Aplica dados de save ao GameManager
func _apply_save_data(data: Dictionary) -> void:
	if not GameManager:
		return

	var game_data = data.get("game", {})

	# Restaura estado básico
	GameManager.current_year = game_data.get("current_year", 1)
	GameManager.current_season = game_data.get("current_season", 0)
	GameManager.current_day = game_data.get("current_day", 1)
	GameManager.current_weekday = game_data.get("current_weekday", 0)
	GameManager.current_time = game_data.get("current_time", 600)
	GameManager.gold = game_data.get("gold", 500)
	GameManager.energy = game_data.get("energy", 270.0)
	GameManager.max_energy = game_data.get("max_energy", 270.0)
	GameManager.health = game_data.get("health", 100.0)
	GameManager.max_health = game_data.get("max_health", 100.0)
	GameManager.skill_levels = game_data.get("skill_levels", [0,0,0,0,0])
	GameManager.skill_xp = game_data.get("skill_xp", [0,0,0,0,0])
	GameManager.professions = game_data.get("professions", {})
	GameManager.inventory = game_data.get("inventory", {})
	var saved_hotbar: Array = game_data.get("hotbar", [])
	GameManager.hotbar.clear()
	GameManager.hotbar.assign(saved_hotbar)
	while GameManager.hotbar.size() < 12:
		GameManager.hotbar.append("")
	GameManager.selected_hotbar_slot = game_data.get("selected_hotbar_slot", 0)
	GameManager.tools = game_data.get("tools", {})
	GameManager.unlocked_recipes = game_data.get("unlocked_recipes", [])
	GameManager.unlocked_cooking_recipes = game_data.get("unlocked_cooking_recipes", [])
	GameManager.friendships = game_data.get("friendships", {})
	GameManager.npcs_talked_today = game_data.get("npcs_talked_today", [])
	GameManager.gifts_given_today = game_data.get("gifts_given_today", {})
	GameManager.gifts_given_this_week = game_data.get("gifts_given_this_week", {})
	GameManager.active_quests = game_data.get("active_quests", [])
	GameManager.completed_quests = game_data.get("completed_quests", [])
	GameManager.active_special_orders = game_data.get("active_special_orders", [])
	var saved_achievements = game_data.get("achievements", [])
	GameManager.achievements.clear()
	if saved_achievements is Dictionary:
		GameManager.achievements.assign(saved_achievements.keys())
	elif saved_achievements is Array:
		GameManager.achievements.assign(saved_achievements)
	GameManager.farm_buildings = game_data.get("farm_buildings", [])
	GameManager.farm_crops = game_data.get("farm_crops", {})
	GameManager.farm_animals = game_data.get("farm_animals", [])
	GameManager.placed_machines = game_data.get("placed_machines", [])
	GameManager.placed_objects = game_data.get("placed_objects", {})
	GameManager.tomorrow_weather = game_data.get("tomorrow_weather", 0)
	GameManager.today_weather = game_data.get("today_weather", 0)
	GameManager.daily_luck = game_data.get("daily_luck", 0.0)
	GameManager.active_festival = game_data.get("active_festival", "")
	GameManager.is_exhausted = game_data.get("is_exhausted", false)
	GameManager.has_fainted = game_data.get("has_fainted", false)
	GameManager.gold_lost_fainting = game_data.get("gold_lost_fainting", 0)
	GameManager.items_lost_on_death = game_data.get("items_lost_on_death", [])
	GameManager.stats = game_data.get("stats", {})

	# Dados extras
	GameManager.set_data("deepest_mine_level", game_data.get("deepest_mine_level", 0))
	GameManager.set_data("mine_elevator_unlocked", game_data.get("mine_elevator_unlocked", false))
	GameManager.set_data("mine_levels_cleared", game_data.get("mine_levels_cleared", {}))
	GameManager.set_data("dating_npc", game_data.get("dating_npc", ""))
	GameManager.set_data("spouse", game_data.get("spouse", ""))
	GameManager.set_data("spouse_room_unlocked", game_data.get("spouse_room_unlocked", false))
	GameManager.set_data("children", game_data.get("children", []))
	GameManager.set_data("divorced_npcs", game_data.get("divorced_npcs", []))
	GameManager.set_data("qi_gems", game_data.get("qi_gems", 0))
	GameManager.set_data("wizard_reputation", game_data.get("wizard_reputation", 0))
	GameManager.set_data("house_upgrade_2", game_data.get("house_upgrade_2", false))
	GameManager.set_data("next_item_quality_boost", game_data.get("next_item_quality_boost", 0))
	GameManager.set_data("instant_grow_next", game_data.get("instant_grow_next", false))
	GameManager.set_data("star_tokens", game_data.get("star_tokens", 0))
	GameManager.set_data("special_orders_completed", game_data.get("completed_special_orders", []))

	# Novos sistemas
	GameManager.set_data("collection_shipped", game_data.get("collection_shipped", {}))
	GameManager.set_data("collection_fish", game_data.get("collection_fish", {}))
	GameManager.set_data("collection_artifacts", game_data.get("collection_artifacts", {}))
	GameManager.set_data("collection_minerals", game_data.get("collection_minerals", {}))
	GameManager.set_data("collection_recipes", game_data.get("collection_recipes", {}))
	GameManager.set_data("known_recipes", game_data.get("known_recipes", []))
	GameManager.set_data("museum_donated", game_data.get("museum_donated", {}))
	GameManager.set_data("museum_counts", game_data.get("museum_counts", {}))
	GameManager.set_data("museum_rewards_claimed", game_data.get("museum_rewards_claimed", []))
	GameManager.set_data("cc_greenhouse_unlocked", game_data.get("cc_greenhouse_unlocked", false))
	GameManager.set_data("greenhouse_unlocked", game_data.get("greenhouse_unlocked", false))
	GameManager.set_data("minecart_unlocked", game_data.get("minecart_unlocked", []))
	GameManager.set_data("minecart_connected", game_data.get("minecart_connected", {}))
	GameManager.set_data("pet_friendship", game_data.get("pet_friendship", 0))
	GameManager.set_data("pet_name", game_data.get("pet_name", ""))
	GameManager.set_data("pet_type", game_data.get("pet_type", "Cat"))
	GameManager.set_data("pet_last_pet_day", game_data.get("pet_last_pet_day", -1))
	GameManager.set_data("tv_last_watched_day", game_data.get("tv_last_watched_day", -1))
	GameManager.set_data("tv_watched_shows", game_data.get("tv_watched_shows", {}))
	GameManager.set_data("mailbox", game_data.get("mailbox", []))
	GameManager.set_data("read_mails", game_data.get("read_mails", []))
	GameManager.set_data("next_mail_id", game_data.get("next_mail_id", 1))
	GameManager.set_data("welcome_mail_sent", game_data.get("welcome_mail_sent", false))
	GameManager.set_data("player_skin", game_data.get("player_skin", 0))
	GameManager.set_data("player_hair", game_data.get("player_hair", 0))
	GameManager.set_data("player_hair_color", game_data.get("player_hair_color", 0))
	GameManager.set_data("player_eyes", game_data.get("player_eyes", 0))
	GameManager.set_data("player_pants", game_data.get("player_pants", 0))
	GameManager.set_data("player_pants_color", game_data.get("player_pants_color", 0))
	GameManager.set_data("player_shirt", game_data.get("player_shirt", 0))
	GameManager.set_data("player_shirt_color", game_data.get("player_shirt_color", 0))
	GameManager.set_data("player_shoes", game_data.get("player_shoes", 0))
	GameManager.set_data("player_accessory", game_data.get("player_accessory", 0))
	GameManager.set_data("player_hat", game_data.get("player_hat", -1))
	GameManager.set_data("player_gender", game_data.get("player_gender", 0))
	GameManager.set_data("equipped_hat", game_data.get("equipped_hat", ""))
	GameManager.set_data("equipped_shirt", game_data.get("equipped_shirt", ""))
	GameManager.set_data("equipped_pants", game_data.get("equipped_pants", ""))
	GameManager.set_data("equipped_boots", game_data.get("equipped_boots", ""))
	GameManager.set_data("equipped_ring", game_data.get("equipped_ring", ""))
	GameManager.set_data("equipped_ring2", game_data.get("equipped_ring2", ""))
	GameManager.set_data("pet_data", game_data.get("pet_data", {}))

	# Emite sinais para atualizar UI
	GameManager.emit_signal("gold_changed", GameManager.gold)
	GameManager.emit_signal("energy_changed", GameManager.energy)
	GameManager.emit_signal("health_changed", GameManager.health)
	GameManager.emit_signal("time_changed", GameManager.current_time)
	GameManager.emit_signal("day_changed", GameManager.current_day, GameManager.current_season, GameManager.current_year)
	InventoryManager.emit_signal("inventory_changed")

	# Restaura player
	var player_data = data.get("player", {})
	_restore_player_state(player_data)

	# Restaura mundo
	var world_data = data.get("world", {})
	_restore_world_state(world_data)

## Restaura player na cena
func _restore_player_state(data: Dictionary) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("load_save_state"):
		player.load_save_state(data)

## Restaura estado do mundo
func _restore_world_state(data: Dictionary) -> void:
	# NPCs, cultivos crescendo, máquinas processando, etc.
	pass

## ==================== UTILIDADES ====================

## Lista saves disponíveis
func list_saves() -> Array[Dictionary]:
	var saves = []
	var dir = DirAccess.open(save_folder)
	if not dir:
		return saves

	dir.list_dir_begin() # TODOConverter3To4 fill missing arguments https://github.com/godotengine/godot/pull/40547
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json") and file_name.begins_with("save_"):
			var file_path = save_folder + file_name
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var json_str = file.get_as_text()
				file.close()
				var data = JSON.parse_string(json_str)
				if data is Dictionary:
					var game = data.get("game", {})
					saves.append({
						"slot": data.get("slot", 0),
						"file": file_name,
						"date": game.get("current_day", 1),
						"season": game.get("current_season", 0),
						"year": game.get("current_year", 1),
						"time": game.get("current_time", 600),
						"gold": game.get("gold", 0),
						"playtime": game.get("stats", {}).get("days_played", 0),
						"timestamp": data.get("timestamp", 0)
					})
		file_name = dir.get_next()
	dir.list_dir_end()

	# Ordena por timestamp (mais recente primeiro)
	saves.sort_custom(Callable(self, "_sort_by_timestamp_desc"))
	return saves

func _sort_by_timestamp_desc(a: Dictionary, b: Dictionary) -> int:
	return -1 if a["timestamp"] > b["timestamp"] else 1

## Deleta save
func delete_save(slot: int) -> bool:
	var file_path = save_folder + "save_%d.json" % slot
	var dir = DirAccess.open(save_folder)
	if dir and dir.file_exists(file_path):
		dir.remove(file_path)
		return true
	return false

## Obtém info do save sem carregar
func get_save_info(slot: int) -> Dictionary:
	var file_path = save_folder + "save_%d.json" % slot
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}

	var json_str = file.get_as_text()
	file.close()
	var data = JSON.parse_string(json_str)
	if data is Dictionary:
		return data.get("game", {})
	return {}

## Exporta save para arquivo (backup)
func export_save(slot: int, export_path: String) -> bool:
	var src = save_folder + "save_%d.json" % slot
	var dir = DirAccess.open(save_folder)
	if not dir or not dir.file_exists(src):
		return false

	var dst_dir = DirAccess.open(export_path.get_base_dir())
	if not dst_dir:
		DirAccess.make_dir_recursive_absolute(export_path.get_base_dir())

	return dir.copy(src, export_path)

## Importa save de arquivo
func import_save(import_path: String, slot: int) -> bool:
	var dir = DirAccess.open(save_folder)
	if not dir:
		return false

	var dst = save_folder + "save_%d.json" % slot
	return dir.copy(import_path, dst)