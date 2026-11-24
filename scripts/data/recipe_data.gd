@tool
class_name RecipeData
extends Resource

## Nome da receita (chave do JSON)
@export var recipe_name: String = ""

## String bruta de ingredientes (formato Stardew: "388 2/Field/322/false/default/")
@export var raw_data: String = ""

## Ingredientes parseados: Array de {item_id, amount}
@export var ingredients: Array[Dictionary] = []

## Resultado: {item_id, count, is_big_craftable}
@export var result: Dictionary = {}

## Tipo de receita: "Crafting" ou "Cooking"
@export var recipe_type: String = "Crafting"

## Onde aparece: "Field", "Home", "Cooking"
@export var crafting_tab: String = "Home"

## True se aprendida por padrão
@export var default_unlocked: bool = false

## Condição de desbloqueio (ex: "s Farming 2", "l 2", "f Krobus 3")
@export var unlock_condition: String = ""

## Nível de habilidade necessário
@export var required_skill_level: int = 0

## Habilidade necessária: "Farming", "Mining", "Foraging", "Fishing", "Combat", "Luck"
@export var required_skill: String = ""

## Se é receita de culinária
@export var is_cooking: bool = false

## Se é big craftable (máquinas, baús, etc.)
@export var is_big_craftable: bool = false

## Se pode ser colocada no mundo
@export var can_place: bool = false

## ID do objeto big craftable resultante
@export var big_craftable_id: String = ""

## Tempo de processamento (para máquinas) em minutos
@export var processing_time: int = 0

## Parses a string bruta do Stardew
func parse_raw_data() -> void:
	ingredients = []
	var parts = raw_data.split("/")
	if parts.size() < 3:
		return

	# Parte 0: Ingredientes (ex: "388 2 390 25")
	var ingredient_str = parts[0].strip_edges()
	var ing_parts = ingredient_str.split(" ")
	for i in range(0, ing_parts.size(), 2):
		if i + 1 < ing_parts.size():
			var item_id = ing_parts[i]
			var amount = int(ing_parts[i + 1])
			ingredients.append({"item_id": item_id, "amount": amount})

	# Parte 1: Aba de crafting (Field/Home/Cooking)
	crafting_tab = parts[1] if parts.size() > 1 else "Home"

	# Parte 2: Resultado (ID do item)
	result.item_id = parts[2] if parts.size() > 2 else ""

	# Parte 3: is_big_craftable (true/false)
	result.is_big_craftable = parts[3].to_lower() == "true" if parts.size() > 3 else false
	is_big_craftable = result.is_big_craftable

	# Parte 4: Condição de desbloqueio
	if parts.size() > 4:
		unlock_condition = parts[4]
		parse_unlock_condition()

	# Parte 5: Nome localizado (opcional)
	if parts.size() > 5:
		recipe_name = parts[5]

	# Determina tipo
	is_cooking = (crafting_tab == "Cooking")
	recipe_type = "Cooking" if is_cooking else "Crafting"

	# Big craftable ID
	if is_big_craftable:
		big_craftable_id = result.item_id
		can_place = true

func parse_unlock_condition() -> void:
	required_skill = ""
	required_skill_level = 0

	if unlock_condition.begins_with("s "):
		# Skill level: "s Farming 2"
		var parts = unlock_condition.split(" ")
		if parts.size() >= 3:
			required_skill = parts[1]
			required_skill_level = int(parts[2])
	elif unlock_condition.begins_with("l "):
		# Level: "l 2" (generic level)
		required_skill_level = int(unlock_condition.split(" ")[1])
	elif unlock_condition.begins_with("f "):
		# Friendship: "f Krobus 3"
		var parts = unlock_condition.split(" ")
		if parts.size() >= 3:
			required_skill = "Friendship_" + parts[1]
			required_skill_level = int(parts[2])
	elif unlock_condition == "default":
		default_unlocked = true

## Verifica se jogador pode craftar
func can_craft(player_skills: Dictionary, player_friendships: Dictionary, player_recipes: Array[String]) -> bool:
	if recipe_name in player_recipes or default_unlocked:
		return true

	if required_skill != "" and required_skill_level > 0:
		if required_skill.begins_with("Friendship_"):
			var npc = required_skill.replace("Friendship_", "")
			var friendship = player_friendships.get(npc, 0)
			return friendship >= required_skill_level * 250  # 250 pts per heart
		else:
			var level = player_skills.get(required_skill, 0)
			return level >= required_skill_level

	return false

## Verifica se tem ingredientes no inventário
func has_ingredients(inventory: Dictionary) -> bool:
	for ing in ingredients:
		var item_id = ing.item_id
		var amount = ing.amount
		var has = inventory.get(item_id, 0)
		if has < amount:
			return false
	return true

## Consome ingredientes do inventário
func consume_ingredients(inventory: Dictionary) -> void:
	for ing in ingredients:
		var item_id = ing.item_id
		var amount = ing.amount
		inventory[item_id] = inventory.get(item_id, 0) - amount
		if inventory[item_id] <= 0:
			inventory.erase(item_id)

## Adiciona resultado ao inventário
func give_result(inventory: Dictionary) -> void:
	var item_id = result.item_id
	var count = result.get("count", 1)
	inventory[item_id] = inventory.get(item_id, 0) + count

## Obtém descrição formatada para UI
func get_ingredient_description(item_database: Dictionary) -> String:
	var parts = []
	for ing in ingredients:
		var item_id = ing.item_id
		var amount = ing.amount
		var item_name = item_database.get(item_id, {}).get_display_name() if item_database.has(item_id) else item_id
		parts.append("%dx %s" % [amount, item_name])
	return ", ".join(parts)