class_name RecipeDiscovery
extends Node

## Sistema de Descoberta de Receitas: experimentação, TV, NPCs, level up

## ==================== SINAIS ====================
signal recipe_discovered(recipe_id: String, source: String)
signal cooking_level_up(new_level: int)

## Fontes de descoberta
const DISCOVERY_SOURCES = {
	"experiment": {"name": "Experimentação", "icon": "🧪", "chance": 0.1},
	"tv_cooking": {"name": "Queen of Sauce", "icon": "📺", "chance": 1.0},
	"npc_friendship": {"name": "Amizade com NPC", "icon": "💚", "chance": 1.0},
	"level_up": {"name": "Level Up Culinária", "icon": "📈", "chance": 1.0},
	"book": {"name": "Livro de Receitas", "icon": "📚", "chance": 1.0},
	"festival": {"name": "Festival", "icon": "🎪", "chance": 1.0},
	"secret": {"name": "Nota Secreta", "icon": "🤫", "chance": 1.0}
}

## Receitas secretas (só descobríveis via experimentação/livros)
const SECRET_RECIPES = {
	"Strange Bun": {"ingredients": ["(O)305", "(O)306", "(O)330"], "source": "secret"},
	"Void Mayo": {"ingredients": ["(O)767", "(O)306"], "source": "secret"},
	"Golden Pumpkin Pie": {"ingredients": ["(O)768", "(O)305", "(O)330"], "source": "secret"},
	"Magic Rock Candy": {"ingredients": ["(O)330", "(O)769", "(O)768"], "source": "secret"},
	"Stardrop Tea": {"ingredients": ["(O)306", "(O)424", "(O)440"], "source": "secret"}
}

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	if GameManager:
		GameManager.skill_level_up.connect(_on_skill_level_up)
		GameManager.item_obtained.connect(_on_item_obtained)
		TVChannels.recipe_learned.connect(_on_tv_recipe_learned)

	# Carrega receitas descobertas
	_load_discovered_recipes()

func _load_discovered_recipes() -> void:
	if GameManager:
		# Receitas já desbloqueadas estão em GameManager.unlocked_cooking_recipes
		pass

## ==================== DESCOBERTA POR EXPERIMENTAÇÃO ====================
## Chamado quando player tenta combinar ingredientes no fogão
func try_discover_recipe(ingredients: Array[String]) -> String:
	# Ordena ingredientes para comparação
	ingredients.sort()

	# Verifica se combina com alguma receita secreta
	for recipe_name in SECRET_RECIPES:
		var recipe = SECRET_RECIPES[recipe_name]
		var req_ingredients = recipe.ingredients.duplicate()
		req_ingredients.sort()

		if req_ingredients == ingredients:
			return _discover_recipe(recipe_name, "experiment")

	return ""

func _discover_recipe(recipe_name: String, source: String) -> String:
	if GameManager and recipe_name in GameManager.unlocked_cooking_recipes:
		return ""  # Já descoberta

	# Desbloqueia
	if GameManager:
		GameManager.unlocked_cooking_recipes.append(recipe_name)
		GameManager.emit_signal("recipe_learned", recipe_name)

	# Notificação
	var source_info = DISCOVERY_SOURCES.get(source, {"name": source, "icon": "❓"})
	HUD.show_notification("🍳 Nova Receita Descoberta!", "%s\nFonte: %s %s" % [recipe_name, source_info.icon, source_info.name], Color(1.0, 0.7, 0.3))

	# Partículas
	if ParticleManager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ParticleManager.show_level_up(player.global_position, "Nova Receita!")

	# Som
	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/recipe_discover.ogg")

	emit_signal("recipe_discovered", recipe_name, source)
	return recipe_name

## ==================== DESCOBERTAS AUTOMÁTICAS ====================
func _on_skill_level_up(skill_index: int, new_level: int) -> void:
	if skill_index == 3:  # Foraging? No, cooking não tem skill própria... usa Foraging level?
		# Level up de cooking baseado em foraging ou farming?
		pass

	# Level up de Farming pode desbloquear receitas
	if skill_index == 0:  # Farming
		_unlock_farming_recipes(new_level)

func _unlock_farming_recipes(level: int) -> void:
	# Receitas desbloqueadas por nível de farming
	var farming_recipes = {
		2: ["Fried Egg", "Bread"],
		3: ["Salad", "Cheese Cauliflower"],
		4: ["Pancakes", "Cookie"],
		5: ["Rhubarb Pie", "Vegetable Medley"],
		6: ["Cranberry Candy", "Pumpkin Pie"],
		7: ["Baked Fish", "Stuffing"],
		8: ["Ice Cream", "Plum Pudding"],
		9: ["Artichoke Dip", "Chocolate Cake"],
		10: ["Pink Cake", "Complete Breakfast", "Farmer's Lunch", "Survival Burger"]
	}

	if farming_recipes.has(level):
		for recipe in farming_recipes[level]:
			_discover_recipe(recipe, "level_up")
		HUD.show_notification("🌱 Receitas de Agricultura!", "Nível %d desbloqueou %d receitas!" % [level, farming_recipes[level].size()], Color(0.5, 1.0, 0.5))

func _on_item_obtained(item_id: String, amount: int, quality: int) -> void:
	# Verifica se item é livro de receitas
	var item = DataLoader.get_item(item_id)
	if item and item.category == -8:  # Books/Recipes
		_learn_recipe_from_book(item_id)

func _learn_recipe_from_book(book_id: String) -> void:
	# Mapeia livros para receitas
	var book_recipes = {
		"(O)680": "Salmon Dinner",  # The Art of Cooking
		"(O)681": "Fish Taco",
		"(O)682": "Escargot",
		"(O)683": "Caviar",
		"(O)684": "Lobster Bisque",
		"(O)685": "Super Meal",
		"(O)686": "Crab Cakes",
		"(O)687": "Maple Bar",
		"(O)688": "Pink Cake",
		"(O)689": "Complete Breakfast"
	}

	if book_recipes.has(book_id):
		_discover_recipe(book_recipes[book_id], "book")
		HUD.show_notification("📚 Livro de Receitas!", "Aprendeu: %s" % book_recipes[book_id], Color(0.5, 0.8, 1.0))

func _on_tv_recipe_learned(recipe_name: String) -> void:
	_discover_recipe(recipe_name, "tv_cooking")

## ==================== DESCOBERTAS VIA NPC ====================
func unlock_npc_recipe(npc_name: String, friendship_level: int) -> void:
	# Receitas dadas por NPCs em certos níveis de amizade
	var npc_recipes = {
		"Abigail": {7: "Chocolate Cake", 9: "Spicy Eel"},
		"Emily": {5: "Cloth", 9: "Diamond"},
		"Caroline": {5: "Parsnip Soup", 7: "Fish Taco"},
		"Clint": {5: "Cherry Bomb", 7: "Explosive Ammo"},
		"Gus": {3: "Fish Taco", 7: "Crab Cakes", 9: "Lobster Bisque"},
		"Marnie": {5: "Cream", 7: "Cheese"},
		"Robin": {5: "Wood Fence", 7: "Hardwood Fence"},
		"Wizard": {5: "Magic Rock Candy", 7: "Warp Totem: Desert"},
		"Krobus": {5: "Void Mayo", 7: "Solar Essence"},
		"Dwarf": {5: "Cherry Bomb", 7: "Mega Bomb"},
		"Evelyn": {5: "Cookie", 7: "Chocolate Cake"},
		"George": {5: "Leek Soup", 7: "Fried Mushroom"},
		"Jas": {5: "Pink Cake", 7: "Fairy Dust"},
		"Leo": {5: "Mango Sticky Rice", 7: "Tropical Curry"},
		"Linne": {5: "Seafoam Pudding", 7: "Mermaid's Pendant"},
		"Morris": {5: "Joja Cola", 7: "Blue Jazz"},
		"Pierre": {5: "Parsnip Seeds", 7: "Quality Fertilizer"},
		"Sandy": {5: "Coconut", 7: "Pineapple"},
		"Willy": {5: "Trout Soup", 7: "Spicy Eel"}
	}

	if npc_recipes.has(npc_name):
		var recipes = npc_recipes[npc_name]
		if recipes.has(friendship_level):
			_discover_recipe(recipes[friendship_level], "npc_friendship")
			HUD.show_notification("💚 Receita de %s!" % npc_name, "Aprendeu: %s" % recipes[friendship_level], Color(1.0, 0.5, 0.7))

## ==================== DESCOBERTAS VIA FESTIVAL ====================
func unlock_festival_recipe(festival_name: String) -> void:
	var festival_recipes = {
		"Egg Festival": "Egg Hunt Prize",
		"Flower Dance": "Flower Salad",
		"Luau": "Luau Soup",
		"Stardew Valley Fair": "Fair Prize",
		"Spirit's Eve": "Pumpkin Pie",
		"Festival of Ice": "Ice Cream",
		"Feast of the Winter Star": "Cookie"
	}

	if festival_recipes.has(festival_name):
		_discover_recipe(festival_recipes[festival_name], "festival")

## ==================== EXPERIMENTAÇÃO AVANÇADA ====================
## Tenta descobrir receita combinando ingredientes (sistema de "tentativa e erro")
func experiment_combination(ingredients: Array[String]) -> Dictionary:
	var result = {
		"discovered": false,
		"recipe": "",
		"byproduct": "",
		"quality": 0
	}

	# Verifica receitas secretas
	var discovered = try_discover_recipe(ingredients)
	if discovered != "":
		result.discovered = true
		result.recipe = discovered
		result.quality = randi_range(0, 2)  # Normal a Ouro
		return result

	# Chance de subproduto (failed experiment)
	if randf() < 0.05:
		result.byproduct = "(O)390"  # Failed experiment = basic item
		result.quality = 0

	return result

## ==================== LIVROS DE RECEITAS ====================
func get_recipe_book_list() -> Array[Dictionary]:
	var books = []
	for book_id in [
		"(O)680", "(O)681", "(O)682", "(O)683", "(O)684",
		"(O)685", "(O)686", "(O)687", "(O)688", "(O)689"
	]:
		var item = DataLoader.get_item(book_id)
		if item:
			books.append({
				"id": book_id,
				"name": item.display_name,
				"description": item.description,
			 "price": item.price
			})
	return books

## ==================== PERSISTÊNCIA ====================
func get_save_data() -> Dictionary:
	return {
		"discovered_recipes": GameManager.unlocked_cooking_recipes if GameManager else []
	}

func load_save_data(data: Dictionary) -> void:
	if GameManager:
		GameManager.unlocked_cooking_recipes = data.get("discovered_recipes", [])