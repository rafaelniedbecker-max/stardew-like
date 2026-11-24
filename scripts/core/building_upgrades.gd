class_name BuildingUpgrades
extends Node

## Sistema de Upgrades de Edifícios: tiers, custos, benefícios

## ==================== TIERS DE EDIFÍCIOS ====================
const BUILDING_TIERS = {
	"Coop": {
		0: {"name": "Coop", "capacity": 4, "cost": 4000, "materials": {"Wood": 300, "Stone": 100}, "features": ["Feeder", "Incubator"]},
		1: {"name": "Big Coop", "capacity": 8, "cost": 10000, "materials": {"Wood": 400, "Stone": 150}, "features": ["Feeder", "Incubator", "Auto-feed"]},
		2: {"name": "Deluxe Coop", "capacity": 12, "cost": 20000, "materials": {"Wood": 500, "Stone": 200}, "features": ["Feeder", "Incubator", "Auto-feed", "Auto-collect"]}
	},
	"Barn": {
		0: {"name": "Barn", "capacity": 4, "cost": 6000, "materials": {"Wood": 350, "Stone": 150}, "features": ["Feeder", "Heater"]},
		1: {"name": "Big Barn", "capacity": 8, "cost": 15000, "materials": {"Wood": 450, "Stone": 200}, "features": ["Feeder", "Heater", "Auto-feed", "Pregnancy"]},
		2: {"name": "Deluxe Barn", "capacity": 12, "cost": 25000, "materials": {"Wood": 550, "Stone": 250}, "features": ["Feeder", "Heater", "Auto-feed", "Auto-collect", "Pregnancy"]}
	},
	"House": {
		0: {"name": "Cabana", "rooms": 1, "cost": 0, "features": ["Bed", "TV", "Fireplace"]},
		1: {"name": "Casa", "rooms": 2, "cost": 10000, "materials": {"Wood": 450, "Stone": 100}, "features": ["Bed", "TV", "Fireplace", "Kitchen", "Fridge"]},
		2: {"name": "Mansão", "rooms": 3, "cost": 50000, "materials": {"Wood": 1000, "Stone": 300, "Hardwood": 100}, "features": ["Bed", "TV", "Fireplace", "Kitchen", "Fridge", "Cellar", "Nursery"]},
		3: {"name": "Mansão Deluxe", "rooms": 4, "cost": 100000, "materials": {"Wood": 1500, "Stone": 500, "Hardwood": 200}, "features": ["Bed", "TV", "Fireplace", "Kitchen", "Fridge", "Cellar", "Nursery", "Greenhouse Access"]}
	},
	"Shed": {
		0: {"name": "Shed", "size": "small", "cost": 15000, "materials": {"Wood": 300}, "features": ["Storage", "Keg/Preserves slots"]},
		1: {"name": "Big Shed", "size": "big", "cost": 30000, "materials": {"Wood": 500, "Stone": 100}, "features": ["More slots", "Auto-craft"]}
	},
	"Silo": {
		0: {"name": "Silo", "capacity": 240, "cost": 100, "materials": {"Stone": 100, "Clay": 10, "Copper": 5}, "features": ["Auto-hay"]}
	},
	"Well": {
		0: {"name": "Well", "cost": 1000, "materials": {"Stone": 75, "Wood": 50}, "features": ["Water refill"]}
	},
	"Stable": {
		0: {"name": "Stable", "cost": 10000, "materials": {"Hardwood": 100, "Iron": 5}, "features": ["Horse", "Fast travel"]}
	},
	"Slime Hutch": {
		0: {"name": "Slime Hutch", "capacity": 20, "cost": 10000, "materials": {"Stone": 500, "Refined Quartz": 10, "Iridium": 1}, "features": ["Slimes", "Egg press", "Water trough"]}
	},
	"Fish Pond": {
		0: {"name": "Fish Pond", "capacity": 3, "cost": 5000, "materials": {"Stone": 200, "Seaweed": 5, "Algae": 5}, "features": ["Fish", "Roe", "Capacity quests"]},
		1: {"name": "Big Fish Pond", "capacity": 5, "cost": 10000, "materials": {"Stone": 300, "Seaweed": 10, "Algae": 10}, "features": ["More fish", "Better roe"]},
		2: {"name": "Deluxe Fish Pond", "capacity": 10, "cost": 20000, "materials": {"Stone": 400, "Seaweed": 20, "Algae": 20, "Cinder Shard": 50}, "features": ["Max capacity", "Legendary fish"]}
	},
	"Greenhouse": {
		0: {"name": "Greenhouse", "cost": 0, "unlock_condition": "Community Center Pantry", "features": ["Year-round crops", "Fruit trees"]}
	},
	"Cabin": {
		0: {"name": "Cabin", "cost": 1000, "materials": {"Wood": 100, "Stone": 50}, "features": ["Multiplayer spawn"]}
	},
	"Shipping Bin": {
		0: {"name": "Shipping Bin", "cost": 0, "features": ["Sell items", "Daily summary"]}
	}
}

## ==================== ANIMAIS POR TIER ====================
const ANIMALS_BY_BUILDING = {
	"Coop": {
		0: ["Chicken", "Void Chicken"],
		1: ["Chicken", "Void Chicken", "Duck", "Dinosaur"],
		2: ["Chicken", "Void Chicken", "Duck", "Dinosaur", "Rabbit"]
	},
	"Barn": {
		0: ["Cow", "Goat"],
		1: ["Cow", "Goat", "Sheep", "Pig"],
		2: ["Cow", "Goat", "Sheep", "Pig", "Ostrich"]
	}
}

## ==================== FUNCIONALIDADES POR TIER ====================
func get_building_tier_info(building_type: String, tier: int) -> Dictionary:
	return BUILDING_TIERS.get(building_type, {}).get(tier, {})

func get_building_max_tier(building_type: String) -> int:
	return BUILDING_TIERS.get(building_type, {}).size() - 1

func get_animals_for_tier(building_type: String, tier: int) -> Array[String]:
	return ANIMALS_BY_BUILDING.get(building_type, {}).get(tier, [])

func can_upgrade(building_type: String, current_tier: int) -> bool:
	return current_tier < get_building_max_tier(building_type)

func get_upgrade_cost(building_type: String, current_tier: int) -> Dictionary:
	var next_tier = current_tier + 1
	var info = get_building_tier_info(building_type, next_tier)
	if info:
		return {
			"gold": info.cost,
			"materials": info.materials
		}
	return {}

func get_upgrade_features(building_type: String, current_tier: int, next_tier: int) -> Array[String]:
	var current_features = get_building_tier_info(building_type, current_tier).get("features", [])
	var next_features = get_building_tier_info(building_type, next_tier).get("features", [])

	var new_features = []
	for feature in next_features:
		if feature not in current_features:
			new_features.append(feature)
	return new_features

## ==================== UPGRADE DE CASA ====================
const HOUSE_UPGRADES = {
	0: {"name": "Cabana", "cost": 0, "rooms": 1, "features": ["Cama", "TV", "Lareira"]},
	1: {"name": "Casa", "cost": 10000, "materials": {"Wood": 450, "Stone": 100}, "rooms": 2, "features": ["Cama", "TV", "Lareira", "Cozinha", "Geladeira"]},
	2: {"name": "Mansão", "cost": 50000, "materials": {"Wood": 1000, "Stone": 300, "Hardwood": 100}, "rooms": 3, "features": ["Cama", "TV", "Lareira", "Cozinha", "Geladeira", "Adega", "Quarto de Bebê"]},
	3: {"name": "Mansão Deluxe", "cost": 100000, "materials": {"Wood": 1500, "Stone": 500, "Hardwood": 200}, "rooms": 4, "features": ["Cama", "TV", "Lareira", "Cozinha", "Geladeira", "Adega", "Quarto de Bebê", "Acesso Estufa"]}
}

func upgrade_house(current_level: int) -> Dictionary:
	var next = current_level + 1
	if next > 3:
		return {"success": false, "reason": "Nível máximo atingido"}

	var upgrade = HOUSE_UPGRADES[next]

	# Verifica materiais
	if upgrade.has("materials"):
		for mat in upgrade.materials:
			if not InventoryManager.has_item(mat, upgrade.materials[mat]):
				return {"success": false, "reason": "Materiais insuficientes: %s" % mat}

	# Verifica ouro
	if GameManager.gold < upgrade.cost:
		return {"success": false, "reason": "Ouro insuficiente"}

	# Aplica upgrade
	GameManager.gold -= upgrade.cost
	if upgrade.has("materials"):
		for mat in upgrade.materials:
			InventoryManager.remove_item(mat, upgrade.materials[mat])

	GameManager.emit_signal("gold_changed", GameManager.gold)
	GameManager.set("house_level", next)

	# Aplica funcionalidades
	_apply_house_features(next)

	return {"success": true, "new_level": next, "features": upgrade.features}

func _apply_house_features(level: int) -> void:
	var features = HOUSE_UPGRADES[level].features

	if "Kitchen" in features or "Cozinha" in features:
		GameManager.set("has_kitchen", true)
	if "Fridge" in features or "Geladeira" in features:
		GameManager.set("has_fridge", true)
	if "Cellar" in features or "Adega" in features:
		GameManager.set("has_cellar", true)
	if "Nursery" in features or "Quarto de Bebê" in features:
		GameManager.set("has_nursery", true)
	if "Greenhouse Access" in features or "Acesso Estufa" in features:
		GameManager.set("greenhouse_unlocked", true)
		GameManager.set("cc_greenhouse_unlocked", true)

	HUD.show_notification("🏠 Casa Melhorada!", "Novo nível: %s" % HOUSE_UPGRADES[level].name, Color(1.0, 0.8, 0.2))

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/house_upgrade.ogg")

## ==================== UPGRADE DE FERRAMENTAS ====================
const TOOL_UPGRADES = {
	"Pickaxe": {
		0: {"name": "Cobre", "cost": 2000, "materials": {"Copper Bar": 5}, "power": 1, "speed": 1.0},
		1: {"name": "Ferro", "cost": 5000, "materials": {"Iron Bar": 5}, "power": 2, "speed": 1.0},
		2: {"name": "Ouro", "cost": 10000, "materials": {"Gold Bar": 5}, "power": 3, "speed": 1.2},
		3: {"name": "Irídio", "cost": 25000, "materials": {"Iridium Bar": 5}, "power": 4, "speed": 1.5}
	},
	"Axe": {
		0: {"name": "Cobre", "cost": 2000, "materials": {"Copper Bar": 5}, "power": 1},
		1: {"name": "Ferro", "cost": 5000, "materials": {"Iron Bar": 5}, "power": 2},
		2: {"name": "Ouro", "cost": 10000, "materials": {"Gold Bar": 5}, "power": 3, "speed": 1.2},
		3: {"name": "Irídio", "cost": 25000, "materials": {"Iridium Bar": 5}, "power": 4, "speed": 1.5}
	},
	"Hoe": {
		0: {"name": "Cobre", "cost": 2000, "materials": {"Copper Bar": 5}, "power": 1, "area": 1},
		1: {"name": "Ferro", "cost": 5000, "materials": {"Iron Bar": 5}, "power": 2, "area": 3},
		2: {"name": "Ouro", "cost": 10000, "materials": {"Gold Bar": 5}, "power": 3, "area": 5},
		3: {"name": "Irídio", "cost": 25000, "materials": {"Iridium Bar": 5}, "power": 4, "area": 9}
	},
	"WateringCan": {
		0: {"name": "Cobre", "cost": 2000, "materials": {"Copper Bar": 5}, "capacity": 40, "area": 1},
		1: {"name": "Ferro", "cost": 5000, "materials": {"Iron Bar": 5}, "capacity": 55, "area": 3},
		2: {"name": "Ouro", "cost": 10000, "materials": {"Gold Bar": 5}, "capacity": 70, "area": 5},
		3: {"name": "Irídio", "cost": 25000, "materials": {"Iridium Bar": 5}, "capacity": 100, "area": 9}
	},
	"TrashCan": {
		0: {"name": "Normal", "cost": 0, "recovery": 0.0},
		1: {"name": "Cobre", "cost": 2000, "materials": {"Copper Bar": 5}, "recovery": 0.15},
		2: {"name": "Ferro", "cost": 5000, "materials": {"Iron Bar": 5}, "recovery": 0.30},
		3: {"name": "Ouro", "cost": 10000, "materials": {"Gold Bar": 5}, "recovery": 0.45},
		4: {"name": "Irídio", "cost": 25000, "materials": {"Iridium Bar": 5}, "recovery": 0.60}
	},
	"FishingRod": {
		0: {"name": "Bambu", "cost": 0, "cast_distance": 1.0},
		1: {"name": "Fibra de Vidro", "cost": 1800, "materials": {}, "cast_distance": 1.5},
		2: {"name": "Irídio", "cost": 7500, "materials": {"Iridium Bar": 1}, "cast_distance": 2.0, "tackle_slot": true}
	}
}

func upgrade_tool(tool_name: String, current_level: int) -> Dictionary:
	var next = current_level + 1
	var tool_data = TOOL_UPGRADES.get(tool_name, {})
	var upgrade = tool_data.get(next, {})

	if not upgrade:
		return {"success": false, "reason": "Nível máximo atingido"}

	# Verifica custo
	if GameManager.gold < upgrade.cost:
		return {"success": false, "reason": "Ouro insuficiente"}

	# Verifica materiais
	if upgrade.has("materials"):
		for mat in upgrade.materials:
			var count = upgrade.materials[mat]
			if not InventoryManager.has_item(mat, count):
				return {"success": false, "reason": "Materiais insuficientes: %s x%d" % [mat, count]}

	# Aplica
	GameManager.gold -= upgrade.cost
	if upgrade.has("materials"):
		for mat in upgrade.materials:
			InventoryManager.remove_item(mat, upgrade.materials[mat])

	GameManager.tools[tool_name] = next
	GameManager.emit_signal("gold_changed", GameManager.gold)
	GameManager.emit_signal("tool_upgraded", tool_name, next)

	HUD.show_notification("⚒️ Ferramenta Melhorada!", "%s agora é %s!" % [tool_name, upgrade.name], Color(1.0, 0.8, 0.2))

	if ToolUpgradeEffects:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ToolUpgradeEffects.upgrade_success(tool_name, next, player.global_position)

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/tool_upgrade.ogg")

	return {"success": true, "new_level": next, "name": upgrade.name}

## ==================== UPGRADE DE MOCHILA ====================
const BACKPACK_UPGRADES = [
	{"slots": 12, "cost": 0},      # Inicial
	{"slots": 24, "cost": 2000},   # Upgrade 1
	{"slots": 36, "cost": 10000}   # Upgrade 2 (máximo)
]

func upgrade_backpack(current_slots: int) -> Dictionary:
	var current_idx = BACKPACK_UPGRADES.find({"slots": current_slots})
	if current_idx == -1 or current_idx >= BACKPACK_UPGRADES.size() - 1:
		return {"success": false, "reason": "Mochila já no máximo"}

	var next = BACKPACK_UPGRADES[current_idx + 1]
	var cost = next.cost

	if GameManager.gold < cost:
		return {"success": false, "reason": "Ouro insuficiente"}

	GameManager.gold -= cost
	GameManager.emit_signal("gold_changed", GameManager.gold)

	# Aplica upgrade
	InventoryManager.max_inventory_slots = next.slots
	GameManager.set("backpack_slots", next.slots)

	HUD.show_notification("🎒 Mochila Melhorada!", "Capacidade aumentada para %d slots!" % next.slots, Color(0.5, 1.0, 0.5))

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/backpack_upgrade.ogg")

	return {"success": true, "new_slots": next.slots}

## ==================== CUSTOS DE CONSTRUÇÃO ====================
func get_building_construction_cost(building_type: String, tier: int = 0) -> Dictionary:
	var info = BUILDING_TIERS.get(building_type, {}).get(tier, {})
	if not info:
		return {}

	return {
		"gold": info.get("cost", 0),
		"materials": info.get("materials", {})
	}

func can_afford_building(building_type: String, tier: int = 0) -> bool:
	var cost = get_building_construction_cost(building_type, tier)

	if GameManager.gold < cost.gold:
		return false

	for mat in cost.materials:
		if not InventoryManager.has_item(mat, cost.materials[mat]):
			return false

	return true

func pay_building_cost(building_type: String, tier: int = 0) -> bool:
	var cost = get_building_construction_cost(building_type, tier)

	if not can_afford_building(building_type, tier):
		return false

	GameManager.gold -= cost.gold
	for mat in cost.materials:
		InventoryManager.remove_item(mat, cost.materials[mat])

	GameManager.emit_signal("gold_changed", GameManager.gold)
	return true