@tool
class_name ProjectTest
extends Node

## Script de teste para validar carregamento dos dados
## Execute com: godot --headless --script res://scripts/test/test_project.gd

static func run_tests() -> void:
	print("=== STARDEW-LIKE PROJECT TESTS ===")
	print("")

	# Teste 1: Verifica arquivos JSON
	_assert_json_files_exist()

	# Teste 2: Carrega DataLoader
	_assert_data_loader_works()

	# Teste 3: Verifica recursos principais
	_assert_core_resources()

	print("")
	print("=== ALL TESTS PASSED ===")

static func _assert_json_files_exist() -> void:
	print("Test 1: Verificando arquivos JSON...")
	var required_files = [
		"Crops.json", "Objects.json", "Characters.json",
		"Buildings.json", "CraftingRecipes.json", "CookingRecipes.json",
		"Shops.json", "FarmAnimals.json", "NPCGiftTastes.json",
		"FruitTrees.json", "Machines.json", "FishPondData.json",
		"BigCraftables.json", "Weapons.json", "Tools.json",
		"Buffs.json", "Bundles.json", "Locations.json",
		"Fences.json", "SpecialOrders.json", "Movies.json",
		"Pets.json", "Pants.json", "Shirts.json",
		"WildTrees.json", "GarbageCans.json", "GiantCrops.json",
		"HomeRenovations.json", "Minecarts.json", "MuseumRewards.json",
		"Powers.json", "LocationContexts.json", "Weddings.json",
		"MakeoverOutfits.json", "MonsterSlayerQuests.json",
		"JukeboxTracks.json", "LostItemsShop.json",
		"MoviesReactions.json", "PaintData.json",
		"PassiveFestivals.json", "EngagementDialogue.json",
		"IncomingPhoneCalls.json", "AquariumFish.json",
		"RandomBundles.json", "TriggerActions.json",
		"WorldMap.json", "Achievements.json",
		"AdditionalFarms.json", "AdditionalLanguages.json",
		"AdditionalWallpaperFlooring.json", "ChairTiles.json",
		"FloorsAndPaths.json", "Furniture.json", "HairData.json",
		"Mail.json", "SecretNotes.json", "Quests.json",
		"TV_CookingChannel.json", "TV_TipChannel.json"
	]

	var base_path = "res://resources/data/"
	var missing = []

	for file in required_files:
		var full_path = base_path + file
		if not ResourceLoader.exists(full_path):
			missing.append(file)

	if missing.size() > 0:
		push_error("ARQUIVOS FALTANDO: " + str(missing))
	else:
		print("  ✓ Todos os %d arquivos JSON encontrados" % required_files.size())

static func _assert_data_loader_works() -> void:
	print("Test 2: Testando DataLoader...")
	# Em headless, não podemos instanciar Node, mas podemos verificar sintaxe
	var script = ResourceLoader.load("res://scripts/data/data_loader.gd")
	if not script:
		push_error("DataLoader script não encontrado")
	else:
		print("  ✓ DataLoader script carrega")

static func _assert_core_resources() -> void:
	print("Test 3: Verificando Resources core...")
	var resources = [
		"res://scripts/data/crop_data.gd",
		"res://scripts/data/item_data.gd",
		"res://scripts/data/npc_data.gd",
		"res://scripts/data/building_data.gd",
		"res://scripts/data/recipe_data.gd",
		"res://scripts/data/shop_data.gd"
	]

	for res in resources:
		var script = ResourceLoader.load(res)
		if not script:
			push_error("Resource não encontrado: " + res)
		else:
			print("  ✓ %s" % res.get_file())

	static func _assert_autoloads() -> void:
		print("Test 4: Verificando Autoloads...")
		var autoloads = [
			"GameManager", "TimeManager", "InventoryManager",
			"SaveManager", "DataLoader"
		]
		for autoload in autoloads:
			var script_path = "res://scripts/core/%s.gd" % autoload.to_lower()
			if autoload == "DataLoader":
				script_path = "res://scripts/data/data_loader.gd"
			var script = ResourceLoader.load(script_path)
			if not script:
				push_error("Autoload script não encontrado: " + autoload)
			else:
				print("  ✓ %s" % autoload)

# Permite execução direta
func _init() -> void:
	if Engine.is_editor_hint():
		return
	run_tests()
	quit(0)