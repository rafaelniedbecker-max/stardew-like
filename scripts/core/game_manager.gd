extends Node

## ==================== ESTADO GLOBAL DO JOGO ====================

## Ano atual (começa em 1)
@export var current_year: int = 1

## Estação atual: 0=Spring, 1=Summer, 2=Fall, 3=Winter
@export var current_season: int = 0

## Dia da estação (1-28)
@export var current_day: int = 1

## Dia da semana (0=Segunda, 6=Domingo)
@export var current_weekday: int = 0

## Hora atual em minutos (600 = 6:00, 1300 = 13:00, 2600 = 2:00)
@export var current_time: int = 600

## Ouro do jogador
@export var gold: int = 500

## Nome do jogador
@export var player_name: String = "Jogador"

## Energia atual (0-270 base, até 508 com upgrades)
@export var energy: float = 270.0

## Energia máxima
@export var max_energy: float = 270.0

## Saúde atual (0-100 base)
@export var health: float = 100.0

## Saúde máxima
@export var max_health: float = 100.0

## Nível de experiência: [Farming, Mining, Foraging, Fishing, Combat]
@export var skill_levels: Array[int] = [0, 0, 0, 0, 0]

## Experiência atual por habilidade
@export var skill_xp: Array[int] = [0, 0, 0, 0, 0]

## Experiência necessária para próximo nível
@export var skill_xp_for_next: Array[int] = [100, 100, 100, 100, 100]

## Profissões escolhidas por habilidade (índice: 0=rancho, 1=agricultor, etc.)
@export var professions: Dictionary = {}

## Modificadores temporários controlados pelo BuffManager.
var skill_buffs: Dictionary = {}
var attack_buff: int = 0
var defense_buff: int = 0
var speed_buff: int = 0
var max_energy_buff: int = 0
var magnetism_buff: int = 0
var luck_buff: float = 0.0
var knockback_immunity: bool = false
var debuff_immunity: bool = false

## Inventário: {item_id: quantity}
@export var inventory: Dictionary = {}

## Itens no hotbar (slots 0-11)
@export var hotbar: Array[String] = []

## Slot do hotbar selecionado (0-11)
@export var selected_hotbar_slot: int = 0

## Ferramentas equipadas e seus níveis
@export var tools: Dictionary = {
	"Pickaxe": 0,      # 0=Cobre, 1=Ferro, 2=Ouro, 3=Irídio
	"Axe": 0,
	"Hoe": 0,
	"WateringCan": 0,
	"TrashCan": 0,
	"FishingRod": 0,
	"Pan": 0,
	"Shears": 0,
	"MilkPail": 0
}

## Receitas desbloqueadas (nomes)
@export var unlocked_recipes: Array[String] = []

## Receitas de culinária desbloqueadas
@export var unlocked_cooking_recipes: Array[String] = []

## Amizade com NPCs: {npc_name: friendship_points}
@export var friendships: Dictionary = {}

## NPCs falados hoje
@export var npcs_talked_today: Array[String] = []

## Presentes dados hoje: {npc_name: item_id}
@export var gifts_given_today: Dictionary = {}

## Presentes dados esta semana: {npc_name: count}
@export var gifts_given_this_week: Dictionary = {}

## Missões ativas
@export var active_quests: Array[Dictionary] = []

## Missões completadas
@export var completed_quests: Array[String] = []

## Encomendas especiais ativas
@export var active_special_orders: Array[Dictionary] = []

## Conquistas desbloqueadas
@export var achievements: Array[String] = []

## Edifícios construídos na fazenda: Array de {type, position, days_left}
@export var farm_buildings: Array[Dictionary] = []

## Cultivos plantados: {position_key: {crop_id, growth_day, watered, ...}}
@export var farm_crops: Dictionary = {}

## Animais na fazenda
@export var farm_animals: Array[Dictionary] = []

## Máquinas colocadas
@export var placed_machines: Array[Dictionary] = []

## Objetos colocados (baús, decoração, etc.)
@export var placed_objects: Dictionary = {}

## Clima de amanhã: 0=Sol, 1=Chuva, 2=Tempestade, 3=Neve, 4=Chuva Verde
@export var tomorrow_weather: int = 0

## Clima hoje
@export var today_weather: int = 0

## Sorte do dia (-0.1 a 0.1)
@export var daily_luck: float = 0.0

## Festival ativo hoje (nome ou vazio)
@export var active_festival: String = ""

## Jogador está cansado (passou da meia-noite)
@export var is_exhausted: bool = false

## Jogador desmaiou (energia 0)
@export var has_fainted: bool = false

## Dinheiro perdido ao desmaiar
@export var gold_lost_fainting: int = 0

## Itens perdidos ao desmaiar nas minas
@export var items_lost_on_death: Array[Dictionary] = []

## Estatísticas
@export var stats: Dictionary = {
	"steps_taken": 0,
	"items_crafted": 0,
	"items_cooked": 0,
	"fish_caught": 0,
	"monsters_killed": 0,
	"crops_harvested": 0,
	"items_shipped": 0,
	"gold_earned": 0,
	"gold_spent": 0,
	"days_played": 0
}

## ==================== CONSTANTES ====================
const SEASON_NAMES = ["Spring", "Summer", "Fall", "Winter"]
const WEEKDAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const MAX_ENERGY_BASE = 270.0
const MAX_HEALTH_BASE = 100.0
const ENERGY_PER_LEVEL = 30.0  # Por upgrade de casa
const PASS_OUT_TIME = 2600  # 2:00 AM
const MIDNIGHT_TIME = 2400

## ==================== SINAIS ====================
signal day_changed(new_day: int, new_season: int, new_year: int)
signal season_changed(new_season: int, new_year: int)
signal year_changed(new_year: int)
signal time_changed(new_time: int)
signal weather_changed(new_weather: int)
signal hour_changed(new_hour: int)
signal minute_changed(new_minute: int)
signal gold_changed(new_gold: int)
signal energy_changed(new_energy: float)
signal health_changed(new_health: float)
signal skill_level_up(skill_index: int, new_level: int)
signal friendship_changed(npc_name: String, new_points: int)
signal inventory_changed()
signal recipe_unlocked(recipe_name: String)
signal quest_updated(quest_id: String)
signal quest_added(quest_id: String)
signal quest_completed(quest_id: String)
signal fainted(gold_lost: int, items_lost: Array)
signal exhausted()

# Sinais para managers
signal item_obtained(item_id: String, amount: int, quality: int)
signal monster_killed(monster_type: String, level: int)
signal fish_caught(fish_id: String, size: float, quality: int, location: String)
signal crop_harvested(crop_id: String, amount: int, quality: int)
signal recipe_learned(recipe_id: String)
signal building_built(building_type: String, position: Vector2i)
signal crafting_done(recipe_id: String, amount: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Carrega todos os dados do jogo (JSON -> Resources)
	if DataLoader:
		DataLoader.load_all()

	# Carrega dados salvos se existirem
	_load_default_data()

func _load_default_data() -> void:
	# Receitas iniciais
	unlocked_recipes = [
		"Chest", "Furnace", "Campfire", "Wood Fence", "Gate",
		"Sprinkler", "Scarecrow", "Mayonnaise Machine", "Keg",
		"Preserves Jar", "Cheese Press", "Loom", "Oil Maker"
	]

	# Itens iniciais no inventário
	inventory = {
		"(O)472": 15,  # Parsnip Seeds
		"(O)473": 10,  # Potato Seeds
		"(O)474": 5,   # Cauliflower Seeds
		"(T)0": 1,     # Hoe
		"(T)1": 1,     # Axe
		"(T)2": 1,     # Pickaxe
		"(T)3": 1,     # Watering Can
		"(T)4": 1,     # Scythe
	}

	# Hotbar inicial
	hotbar = [
		"(T)0", "(T)1", "(T)2", "(T)3",  # Ferramentas
		"(O)472", "(O)473", "(O)474", "",  # Sementes
		"", "", "", ""
	]

## ==================== TEMPO E DATA ====================

## Avança o tempo em minutos
func advance_time(minutes: int) -> void:
	var old_time: int = current_time
	var old_hour: int = old_time / 100

	# current_time usa HHMM; normalize os 60 minutos de cada hora.
	var total_minutes: int = (old_time / 100) * 60 + (old_time % 100) + minutes
	current_time = (total_minutes / 60) * 100 + (total_minutes % 60)

	# O dia termina às 2:00, quando o desmaio e o processamento diário ocorrem.
	if old_time < PASS_OUT_TIME and current_time >= PASS_OUT_TIME:
		_check_midnight()
		_faint()

	emit_signal("minute_changed", current_time)
	var new_hour: int = current_time / 100
	if old_hour != new_hour:
		emit_signal("hour_changed", new_hour)
	emit_signal("time_changed", current_time)

func _check_midnight() -> void:
	# Nova dia
	current_day += 1
	current_weekday = (current_weekday + 1) % 7
	current_time = 600  # 6:00 AM
	is_exhausted = false
	has_fainted = false
	npcs_talked_today.clear()
	gifts_given_today.clear()

	# Regenera energia e saúde
	energy = max_energy
	health = max_health

	# Verifica mudança de estação
	if current_day > 28:
		current_day = 1
		current_season = (current_season + 1) % 4
		if current_season == 0:
			current_year += 1
			emit_signal("year_changed", current_year)
		emit_signal("season_changed", current_season, current_year)

	emit_signal("day_changed", current_day, current_season, current_year)
	stats.days_played += 1

	# Gera clima do próximo dia
	_generate_weather()

	# Processa cultivos (crescimento, rega)
	_process_crops_daily()

	# Processa animais
	_process_animals_daily()

	# Processa máquinas
	_process_machines_daily()

	# Reseta encomendas especiais se necessário
	_process_special_orders_daily()

	# Processa sistemas novos
	_process_new_systems_daily()

## Gera clima aleatório para amanhã
func _generate_weather() -> void:
	today_weather = tomorrow_weather
	emit_signal("weather_changed", today_weather)

	# Lógica simplificada de clima
	var rand = randf()
	if current_season == 0:  # Spring
		if rand < 0.18: tomorrow_weather = 1  # Chuva
		elif rand < 0.20: tomorrow_weather = 2  # Tempestade
		else: tomorrow_weather = 0
	elif current_season == 1:  # Summer
		if rand < 0.12: tomorrow_weather = 1
		elif rand < 0.13: tomorrow_weather = 2
		else: tomorrow_weather = 0
	elif current_season == 2:  # Fall
		if rand < 0.15: tomorrow_weather = 1
		elif rand < 0.16: tomorrow_weather = 2
		else: tomorrow_weather = 0
	else:  # Winter
		if rand < 0.20: tomorrow_weather = 3  # Neve
		elif rand < 0.22: tomorrow_weather = 1  # Chuva (raro)
		else: tomorrow_weather = 0

	# Sorte do dia
	daily_luck = (randf() - 0.5) * 0.2

	# Verifica festivais
	_check_festival()

func _check_festival() -> void:
	# Festivais fixos do Stardew
	var festivals = {
		# Spring
		"Spring_13": "Egg Festival",
		"Spring_24": "Flower Dance",
		# Summer
		"Summer_11": "Luau",
		"Summer_28": "Moonlight Jellies",
		# Fall
		"Fall_16": "Stardew Valley Fair",
		"Fall_27": "Spirit's Eve",
		# Winter
		"Winter_8": "Festival of Ice",
		"Winter_25": "Feast of the Winter Star"
	}

	var key = "%s_%d" % [SEASON_NAMES[current_season], current_day]
	active_festival = festivals.get(key, "")

## Desmaio às 2:00 AM
func _faint() -> void:
	has_fainted = true
	gold_lost_fainting = int(gold * 0.1)  # Perde 10% do ouro
	gold -= gold_lost_fainting
	energy = max_energy * 0.5  # Acorda com 50% energia
	health = max_health * 0.5
	emit_signal("fainted", gold_lost_fainting, items_lost_on_death)

## Retorna string formatada da data
func get_date_string() -> String:
	return "%s %d, Year %d" % [SEASON_NAMES[current_season], current_day, current_year]

## Retorna string formatada da hora
func get_time_string() -> String:
	var hours = current_time / 100
	var mins = current_time % 100
	var period = "AM"
	if hours >= 12:
		period = "PM"
		if hours > 12:
			hours -= 12
	if hours == 0:
		hours = 12
	return "%02d:%02d %s" % [hours, mins, period]

## Retorna nome da estação
func get_season_name() -> String:
	return SEASON_NAMES[current_season]

## Retorna nome do dia da semana
func get_weekday_name() -> String:
	return WEEKDAY_NAMES[current_weekday]

## ==================== OURO ====================
func add_gold(amount: int) -> void:
	gold += amount
	if amount > 0:
		stats.gold_earned += amount
	else:
		stats.gold_spent += abs(amount)
	emit_signal("gold_changed", gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		stats.gold_spent += amount
		emit_signal("gold_changed", gold)
		return true
	return false

## ==================== ENERGIA/SAÚDE ====================
func consume_energy(amount: float) -> void:
	energy = max(0.0, energy - amount)
	emit_signal("energy_changed", energy)

	if energy <= 0:
		_pass_out_from_exhaustion()

func restore_energy(amount: float) -> void:
	energy = min(max_energy, energy + amount)
	emit_signal("energy_changed", energy)

func _pass_out_from_exhaustion() -> void:
	is_exhausted = true
	# Teleporta para casa, perde ouro
	gold_lost_fainting = int(gold * 0.1)
	gold -= gold_lost_fainting
	energy = max_energy * 0.25
	emit_signal("exhausted")
	emit_signal("gold_changed", gold)

func take_damage(amount: float) -> void:
	health = max(0.0, health - amount)
	emit_signal("health_changed", health)
	if health <= 0:
		_faint()

func heal(amount: float) -> void:
	health = min(max_health, health + amount)
	emit_signal("health_changed", health)

## ==================== HABILIDADES ====================
const SKILL_NAMES = ["Farming", "Mining", "Foraging", "Fishing", "Combat"]
const XP_PER_LEVEL = [100, 380, 770, 1300, 2150, 3300, 4800, 6900, 10000, 15000]

func add_skill_xp(skill_index: int, amount: int) -> void:
	if skill_index < 0 or skill_index >= 5:
		return

	skill_xp[skill_index] += amount

	# Verifica level up
	while skill_levels[skill_index] < 10:
		var current_level = skill_levels[skill_index]
		var xp_needed = XP_PER_LEVEL[current_level] if current_level < XP_PER_LEVEL.size() else 15000 * (current_level - 9)
		if skill_xp[skill_index] >= xp_needed:
			skill_xp[skill_index] -= xp_needed
			skill_levels[skill_index] += 1
			emit_signal("skill_level_up", skill_index, skill_levels[skill_index])
			_on_skill_level_up(skill_index, skill_levels[skill_index])
		else:
			break

func _on_skill_level_up(skill_index: int, new_level: int) -> void:
	# Desbloqueia receitas por nível
	var unlocks = {
		0: {  # Farming
			1: ["Basic Fertilizer", "Scarecrow", "Sprinkler"],
			2: ["Mayonnaise Machine", "Stone Fence", "Quality Sprinkler"],
			3: ["Bee House", "Speed-Gro"],
			4: ["Preserves Jar", "Iron Fence", "Basic Retaining Soil"],
			5: ["Cheese Press", "Quality Fertilizer"],
			6: ["Loom", "Hardwood Fence", "Quality Retaining Soil"],
			7: ["Oil Maker", "Keg"],
			8: ["Dehydrator", "Iridium Sprinkler", "Deluxe Fertilizer"],
			9: ["Seed Maker", "Auto-Petter"]
		},
		1: {  # Mining
			1: ["Cherry Bomb"],
			2: ["Staircase", "Transmute (Fe)"],
			3: ["Bomb"],
			4: ["Transmute (Au)"],
			5: ["Mega Bomb"],
			6: ["Crystalarium"],
			7: ["Explosive Ammo"],
			8: ["Heavy Furnace"],
			9: ["Mini-Forge"]
		},
		2: {  # Foraging
			1: ["Wild Seeds (Sp)", "Field Snack"],
			2: ["Tapper"],
			3: ["Wild Seeds (Su)"],
			4: ["Wild Seeds (Fa)", "Lightning Rod", "Mushroom Log"],
			5: ["Wild Seeds (Wi)"],
			6: ["Deluxe Worm Bin"],
			7: ["Tree Fertilizer", "Mystic Tree Seed"],
			8: ["Warp Totem: Farm"],
			9: ["Warp Totem: Beach"]
		},
		3: {  # Fishing
			1: ["Bait", "Cork Bobber"],
			2: ["Recycling Machine", "Trap Bobber"],
			3: ["Worm Bin", "Dressed Spinner"],
			4: ["Spinner", "Barbed Hook"],
			5: ["Dressed Spinner"],
			6: ["Bait Maker", "Fish Smoker"],
			7: ["Treasure Hunter"],
			8: ["Master Fisher"],
			9: ["Auto-Hook"]
		},
		4: {  # Combat
			1: ["Sturdy Ring"],
			2: ["Life Elixir"],
			3: ["Oil of Garlic"],
			4: ["Warrior Ring"],
			5: ["Slime Egg-Press"],
			6: ["Explosive Ammo"],
			7: ["Phoenix Ring"],
			8: ["Slime Incubator"],
			9: ["Mini-Forge"]
		}
	}

	if unlocks.has(skill_index) and unlocks[skill_index].has(new_level):
		for recipe in unlocks[skill_index][new_level]:
			if recipe not in unlocked_recipes:
				unlocked_recipes.append(recipe)
				emit_signal("recipe_unlocked", recipe)

## ==================== PROCESSAMENTO DIÁRIO ====================
func _process_crops_daily() -> void:
	var farm_plots: Node = get_tree().get_first_node_in_group("farm_plots")
	if farm_plots:
		for plot in farm_plots.get_children():
			if plot.has_method("new_day"):
				plot.new_day()

func _process_animals_daily() -> void:
	_call_autoload_method("BuildingManager", "process_animals_daily")

func _call_autoload_method(autoload_name: String, method_name: String) -> void:
	# Resolve o singleton em runtime, evitando conflito entre class_name e autoload.
	var system: Node = get_tree().root.get_node_or_null(autoload_name)
	if system != null and system.has_method(method_name):
		system.call(method_name)

func _process_machines_daily() -> void:
	# Processa máquinas colocadas
	for machine in placed_machines:
		if machine.process_time > 0:
			machine.process_time -= 1
			if machine.process_time <= 0:
				# Produz output
				_complete_machine_process(machine)

func _complete_machine_process(machine: Dictionary) -> void:
	var output = machine.get("output", {})
	if not output.is_empty():
		InventoryManager.add_item(output.get("item_id", ""), output.get("amount", 1), output.get("quality", 0))

func _process_special_orders_daily() -> void:
	_call_autoload_method("SpecialOrdersBoard", "on_day_changed")

func _process_new_systems_daily() -> void:
	_call_autoload_method("PetManager", "process_daily")
	_call_autoload_method("MailSystem", "_check_daily_mail")
	_call_autoload_method("Greenhouse", "grow_day")
	_call_autoload_method("MineCart", "_check_unlocks")
	# BuffManager, QuestManager, BuildingManager e festivais já reagem ao
	# sinal day_changed; não processe esses sistemas uma segunda vez.

## ==================== AMIZADE ====================
func add_friendship(npc: String, amount: int) -> void:
	var old = friendships.get(npc, 0)
	var new_val = clamp(old + amount, 0, 3000)  # Max 12+ corações
	friendships[npc] = new_val
	emit_signal("friendship_changed", npc, new_val)

func get_friendship_hearts(npc: String) -> int:
	return friendships.get(npc, 0) / 250

## ==================== RECEITAS ====================
func learn_recipe(recipe_name: String) -> void:
	if recipe_name not in unlocked_recipes and recipe_name not in unlocked_cooking_recipes:
		var recipe = DataLoader.get_recipe(recipe_name)
		if recipe and recipe.is_cooking:
			unlocked_cooking_recipes.append(recipe_name)
		else:
			unlocked_recipes.append(recipe_name)
		emit_signal("recipe_unlocked", recipe_name)

func has_recipe(recipe_name: String) -> bool:
	return recipe_name in unlocked_recipes or recipe_name in unlocked_cooking_recipes

## ==================== FERRAMENTAS ====================
func upgrade_tool(tool_name: String) -> bool:
	if tools.has(tool_name) and tools[tool_name] < 3:
		tools[tool_name] += 1
		return true
	return false

func get_tool_level(tool_name: String) -> int:
	return tools.get(tool_name, 0)

## ==================== ESTATÍSTICAS ====================
func increment_stat(stat: String, amount: int = 1) -> void:
	if stats.has(stat):
		stats[stat] += amount

func get_total_skill_level() -> int:
	var total = 0
	for lvl in skill_levels:
		total += lvl
	return total

func get_max_skill_level() -> int:
	var max_lvl = 0
	for lvl in skill_levels:
		if lvl > max_lvl:
			max_lvl = lvl
	return max_lvl

## ==================== PERSISTÊNCIA (GET/SET GENÉRICOS) ====================
## Estado dinâmico usado pelos sistemas extras. Não sobrescreve Object.get/set.
var _extra_data: Dictionary = {}

func set_data(key: String, value: Variant) -> void:
	_extra_data[key] = value

func get_data(key: String, default: Variant = null) -> Variant:
	return _extra_data.get(key, default)

func has_data(key: String) -> bool:
	return _extra_data.has(key)

## ==================== DESBLOQUEIOS ====================
func unlock_feature(feature: String) -> void:
	if feature not in achievements:
		achievements.append(feature)

func is_unlocked(feature: String) -> bool:
	return feature in achievements

## ==================== VERIFICAÇÕES ====================
func has_building_type(building_type: String) -> bool:
	for b in farm_buildings:
		if b.get("type", "") == building_type:
			return true
	return false

func get_skill_level(skill: String) -> int:
	var idx = SKILL_NAMES.find(skill)
	return skill_levels[idx] if idx >= 0 else 0

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"current_year": current_year,
		"current_season": current_season,
		"current_day": current_day,
		"current_weekday": current_weekday,
		"current_time": current_time,
		"gold": gold,
		"energy": energy,
		"max_energy": max_energy,
		"health": health,
		"max_health": max_health,
		"skill_levels": skill_levels,
		"skill_xp": skill_xp,
		"professions": professions,
		"inventory": inventory,
		"hotbar": hotbar,
		"selected_hotbar_slot": selected_hotbar_slot,
		"tools": tools,
		"unlocked_recipes": unlocked_recipes,
		"unlocked_cooking_recipes": unlocked_cooking_recipes,
		"friendships": friendships,
		"npcs_talked_today": npcs_talked_today,
		"gifts_given_today": gifts_given_today,
		"gifts_given_this_week": gifts_given_this_week,
		"completed_quests": completed_quests,
		"achievements": achievements,
		"farm_buildings": farm_buildings,
		"farm_crops": farm_crops,
		"farm_animals": farm_animals,
		"placed_machines": placed_machines,
		"placed_objects": placed_objects,
		"today_weather": today_weather,
		"tomorrow_weather": tomorrow_weather,
		"daily_luck": daily_luck,
		"active_festival": active_festival,
		"stats": stats,
		"deepest_mine_level": get_data("deepest_mine_level", 0),
		"mine_elevator_unlocked": get_data("mine_elevator_unlocked", false),
		"mine_levels_cleared": get_data("mine_levels_cleared", {}),
		"dating_npc": get_data("dating_npc", ""),
		"spouse": get_data("spouse", ""),
		"spouse_room_unlocked": get_data("spouse_room_unlocked", false),
		"children": get_data("children", []),
		"divorced_npcs": get_data("divorced_npcs", []),
		"qi_gems": get_data("qi_gems", 0),
		"wizard_reputation": get_data("wizard_reputation", 0),
		"house_upgrade_2": get_data("house_upgrade_2", false),
		"next_item_quality_boost": get_data("next_item_quality_boost", 0),
		"instant_grow_next": get_data("instant_grow_next", false),
		"star_tokens": get_data("star_tokens", 0),
		"completed_special_orders": get_data("special_orders_completed", [])
	}

func load_save_data(data: Dictionary) -> void:
	current_year = data.get("current_year", 1)
	current_season = data.get("current_season", 0)
	current_day = data.get("current_day", 1)
	current_weekday = data.get("current_weekday", 0)
	current_time = data.get("current_time", 600)
	gold = data.get("gold", 500)
	energy = data.get("energy", 270.0)
	max_energy = data.get("max_energy", 270.0)
	health = data.get("health", 100.0)
	max_health = data.get("max_health", 100.0)
	skill_levels = data.get("skill_levels", [0,0,0,0,0])
	skill_xp = data.get("skill_xp", [0,0,0,0,0])
	professions = data.get("professions", {})
	inventory = data.get("inventory", {})
	hotbar = data.get("hotbar", [])
	selected_hotbar_slot = data.get("selected_hotbar_slot", 0)
	tools = data.get("tools", {"Pickaxe":0,"Axe":0,"Hoe":0,"WateringCan":0,"TrashCan":0,"FishingRod":0,"Pan":0,"Shears":0,"MilkPail":0})
	unlocked_recipes = data.get("unlocked_recipes", [])
	unlocked_cooking_recipes = data.get("unlocked_cooking_recipes", [])
	friendships = data.get("friendships", {})
	npcs_talked_today = data.get("npcs_talked_today", [])
	gifts_given_today = data.get("gifts_given_today", {})
	gifts_given_this_week = data.get("gifts_given_this_week", {})
	completed_quests = data.get("completed_quests", [])
	achievements = data.get("achievements", [])
	farm_buildings = data.get("farm_buildings", [])
	farm_crops = data.get("farm_crops", {})
	farm_animals = data.get("farm_animals", [])
	placed_machines = data.get("placed_machines", [])
	placed_objects = data.get("placed_objects", {})
	today_weather = data.get("today_weather", 0)
	tomorrow_weather = data.get("tomorrow_weather", 0)
	daily_luck = data.get("daily_luck", 0.0)
	active_festival = data.get("active_festival", "")
	stats = data.get("stats", {"steps_taken":0,"items_crafted":0,"items_cooked":0,"fish_caught":0,"monsters_killed":0,"crops_harvested":0,"items_shipped":0,"gold_earned":0,"gold_spent":0,"days_played":0})

	# Dados extras
	set_data("deepest_mine_level", data.get("deepest_mine_level", 0))
	set_data("mine_elevator_unlocked", data.get("mine_elevator_unlocked", false))
	set_data("mine_levels_cleared", data.get("mine_levels_cleared", {}))
	set_data("dating_npc", data.get("dating_npc", ""))
	set_data("spouse", data.get("spouse", ""))
	set_data("spouse_room_unlocked", data.get("spouse_room_unlocked", false))
	set_data("children", data.get("children", []))
	set_data("divorced_npcs", data.get("divorced_npcs", []))
	set_data("qi_gems", data.get("qi_gems", 0))
	set_data("wizard_reputation", data.get("wizard_reputation", 0))
	set_data("house_upgrade_2", data.get("house_upgrade_2", false))
	set_data("next_item_quality_boost", data.get("next_item_quality_boost", 0))
	set_data("instant_grow_next", data.get("instant_grow_next", false))
	set_data("star_tokens", data.get("star_tokens", 0))
	set_data("special_orders_completed", data.get("completed_special_orders", []))