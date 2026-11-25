@tool
extends Node

## Caminho base para arquivos JSON
@export var data_path: String = "res://resources/data/"

## Cache de resources carregados
var _crop_cache: Dictionary = {}
var _item_cache: Dictionary = {}
var _npc_cache: Dictionary = {}
var _building_cache: Dictionary = {}
var _recipe_cache: Dictionary = {}
var _shop_cache: Dictionary = {}
var _farm_animal_cache: Dictionary = {}
var _fruit_tree_cache: Dictionary = {}
var _machine_cache: Dictionary = {}
var _weapon_cache: Dictionary = {}
var _tool_cache: Dictionary = {}
var _buff_cache: Dictionary = {}
var _bundle_cache: Dictionary = {}
var _location_cache: Dictionary = {}
var _fence_cache: Dictionary = {}
var _big_craftable_cache: Dictionary = {}
var _fish_pond_cache: Dictionary = {}
var _movie_cache: Dictionary = {}
var _pet_cache: Dictionary = {}
var _pants_cache: Dictionary = {}
var _shirt_cache: Dictionary = {}
var _wild_tree_cache: Dictionary = {}
var _garbage_can_cache: Dictionary = {}
var _giant_crop_cache: Dictionary = {}
var _home_renovation_cache: Dictionary = {}
var _minecart_cache: Dictionary = {}
var _museum_reward_cache: Dictionary = {}
var _power_cache: Dictionary = {}
var _location_context_cache: Dictionary = {}
var _wedding_cache: Dictionary = {}
var _makeover_outfit_cache: Dictionary = {}
var _monster_slayer_quest_cache: Dictionary = {}
var _jukebox_track_cache: Dictionary = {}
var _lost_items_shop_cache: Dictionary = {}
var _movies_reaction_cache: Dictionary = {}
var _npc_gift_tastes_cache: Dictionary = {}
var _paint_data_cache: Dictionary = {}
var _passive_festival_cache: Dictionary = {}
var _engagement_dialogue_cache: Dictionary = {}
var _incoming_phone_call_cache: Dictionary = {}
var _aquarium_fish_cache: Dictionary = {}
var _random_bundle_cache: Dictionary = {}
var _trigger_action_cache: Dictionary = {}
var _world_map_cache: Dictionary = {}
var _achievement_cache: Dictionary = {}
var _additional_farm_cache: Dictionary = {}
var _additional_language_cache: Dictionary = {}
var _additional_wallpaper_flooring_cache: Dictionary = {}
var _chair_tiles_cache: Dictionary = {}
var _floors_and_paths_cache: Dictionary = {}
var _furniture_cache: Dictionary = {}
var _hair_data_cache: Dictionary = {}
var _mail_cache: Dictionary = {}
var _secret_note_cache: Dictionary = {}
var _quest_cache: Dictionary = {}
var _tv_cooking_channel_cache: Dictionary = {}
var _tv_tip_channel_cache: Dictionary = {}

## Carrega todos os dados (chamar uma vez no início)
func load_all() -> void:
	print("DataLoader: Iniciando carregamento de todos os dados...")
	load_crops()
	load_items()
	load_npcs()
	load_buildings()
	load_recipes()
	load_shops()
	load_farm_animals()
	load_fruit_trees()
	load_machines()
	load_weapons()
	load_tools()
	load_buffs()
	load_bundles()
	load_locations()
	load_fences()
	load_big_craftables()
	load_fish_ponds()
	load_movies()
	load_pets()
	load_pants()
	load_shirts()
	load_wild_trees()
	load_garbage_cans()
	load_giant_crops()
	load_home_renovations()
	load_minecarts()
	load_museum_rewards()
	load_powers()
	load_location_contexts()
	load_weddings()
	load_makeover_outfits()
	load_monster_slayer_quests()
	load_jukebox_tracks()
	load_lost_items_shop()
	load_movies_reactions()
	load_npc_gift_tastes()
	load_paint_data()
	load_passive_festivals()
	load_engagement_dialogues()
	load_incoming_phone_calls()
	load_aquarium_fish()
	load_random_bundles()
	load_trigger_actions()
	load_world_map()
	load_achievements()
	load_additional_farms()
	load_additional_languages()
	load_additional_wallpaper_flooring()
	load_chair_tiles()
	load_floors_and_paths()
	load_furniture()
	load_hair_data()
	load_mail()
	load_secret_notes()
	load_quests()
	load_special_orders()
	load_festivals()
	load_tv_channels()
	print("DataLoader: Carregamento completo!")

## ==================== CROPS ====================
func load_crops() -> void:
	var file = FileAccess.open(data_path + "Crops.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Crops.json não encontrado em " + data_path)
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		var data = json[key]
		var crop = CropData.new()
		crop.id = key.to_int()
		crop.internal_name = data.get("Name", "") # Precisa mapear ID para nome
		crop.seasons = data.get("Seasons", [])
		crop.days_in_phase = data.get("DaysInPhase", [])
		crop.regrow_days = data.get("RegrowDays", -1)
		crop.is_raised = data.get("IsRaised", false)
		crop.is_paddy_crop = data.get("IsPaddyCrop", false)
		crop.needs_watering = data.get("NeedsWatering", true)
		crop.harvest_item_id = str(data.get("HarvestItemId", ""))
		crop.harvest_min_stack = data.get("HarvestMinStack", 1)
		crop.harvest_max_stack = data.get("HarvestMaxStack", 1)
		crop.harvest_max_increase_per_farming_level = data.get("HarvestMaxIncreasePerFarmingLevel", 0.0)
		crop.extra_harvest_chance = data.get("ExtraHarvestChance", 0.0)
		crop.harvest_method = data.get("HarvestMethod", 0)
		crop.harvest_min_quality = data.get("HarvestMinQuality", 0)
		crop.tint_colors = _parse_colors(data.get("TintColors", []))
		crop.texture_path = data.get("Texture2D", "")
		crop.sprite_index = data.get("SpriteIndex", 0)
		crop.count_for_monoculture = data.get("CountForMonoculture", true)
		crop.count_for_polyculture = data.get("CountForPolyculture", true)
		_crop_cache[str(crop.id)] = crop

	print("DataLoader: %d cultivos carregados" % _crop_cache.size())

func get_crop(crop_id) -> CropData:
	return _crop_cache.get(str(crop_id))

func get_all_crops() -> Array[CropData]:
	var result = []
	for crop in _crop_cache.values():
		result.append(crop)
	return result

## ==================== ITEMS ====================
func load_items() -> void:
	var file = FileAccess.open(data_path + "Objects.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Objects.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		var data = json[key]
		var item = ItemData.new()
		item.id = key.to_int()
		item.internal_name = data.get("Name", "")
		item.display_name = data.get("DisplayName", "")
		item.description = data.get("Description", "")
		item.item_type = data.get("Type", "Basic")
		item.category = data.get("Category", -999)
		item.price = data.get("Price", 0)
		item.sprite_index = data.get("SpriteIndex", 0)
		item.color_overlay_from_next_index = data.get("ColorOverlayFromNextIndex", false)
		item.edibility = data.get("Edibility", 0)
		item.is_drink = data.get("IsDrink", false)
		item.can_be_given_as_gift = data.get("CanBeGivenAsGift", true)
		item.can_be_trashed = data.get("CanBeTrashed", true)
		item.exclude_from_fishing_collection = data.get("ExcludeFromFishingCollection", false)
		item.exclude_from_shipping_collection = data.get("ExcludeFromShippingCollection", false)
		item.exclude_from_random_sale = data.get("ExcludeFromRandomSale", false)
		_item_cache[str(item.id)] = item

	print("DataLoader: %d itens carregados" % _item_cache.size())

func get_item(item_id) -> ItemData:
	var key: String = str(item_id)
	var item: ItemData = _item_cache.get(key)
	if item == null and key.begins_with("(O)"):
		item = _item_cache.get(key.substr(3))
	return item

func get_all_items() -> Array[ItemData]:
	var result = []
	for item in _item_cache.values():
		result.append(item)
	return result

## ==================== NPCs ====================
func load_npcs() -> void:
	var file = FileAccess.open(data_path + "Characters.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Characters.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		var data = json[key]
		var npc = NPCData.new()
		npc.internal_name = key
		npc.display_name = data.get("DisplayName", "")
		npc.birth_season = data.get("BirthSeason", 0)
		npc.birth_day = data.get("BirthDay", 1)
		npc.home_region = data.get("HomeRegion", "Town")
		npc.gender = data.get("Gender", 0)
		npc.age = data.get("Age", 3)
		npc.manner = data.get("Manner", 2)
		npc.social_anxiety = data.get("SocialAnxiety", 0)
		npc.optimism = data.get("Optimism", 2)
		npc.is_dark_skinned = data.get("IsDarkSkinned", false)
		npc.can_be_romanced = data.get("CanBeRomanced", false)
		npc.love_interest = data.get("LoveInterest", "")
		npc.calendar = data.get("Calendar", 0)
		npc.social_tab = data.get("SocialTab", 0)
		npc.can_receive_gifts = data.get("CanReceiveGifts", true)
		npc.can_greet_nearby_characters = data.get("CanGreetNearbyCharacters", true)
		npc.perfection_score = data.get("PerfectionScore", true)
		npc.end_slide_show = data.get("EndSlideShow", 0)
		npc.spouse_gift_jealousy_friendship_change = data.get("SpouseGiftJealousyFriendshipChange", -30)
		npc.spouse_room = data.get("SpouseRoom", {})
		npc.spouse_patio = data.get("SpousePatio", {})
		npc.spouse_floors = data.get("SpouseFloors", [])
		npc.spouse_wallpapers = data.get("SpouseWallpapers", [])
		_npc_cache[key] = npc

	print("DataLoader: %d NPCs carregados" % _npc_cache.size())

func get_npc(name: String) -> NPCData:
	return _npc_cache.get(name)

func get_all_npcs() -> Array[NPCData]:
	var result = []
	for npc in _npc_cache.values():
		result.append(npc)
	return result

## Carrega gostos de presentes dos NPCs
func load_npc_gift_tastes() -> void:
	var file = FileAccess.open(data_path + "NPCGiftTastes.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: NPCGiftTastes.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	# Armazena universal tastes
	_npc_gift_tastes_cache["Universal_Love"] = json.get("Universal_Love", "")
	_npc_gift_tastes_cache["Universal_Like"] = json.get("Universal_Like", "")
	_npc_gift_tastes_cache["Universal_Neutral"] = json.get("Universal_Neutral", "")
	_npc_gift_tastes_cache["Universal_Dislike"] = json.get("Universal_Dislike", "")
	_npc_gift_tastes_cache["Universal_Hate"] = json.get("Universal_Hate", "")

	# Armazena gostos pessoais + diálogos
	for key in json:
		if key.begins_with("Universal_"):
			continue
		_npc_gift_tastes_cache[key] = json[key]

	# Aplica aos NPCs carregados
	for npc_name in _npc_cache:
		var npc = _npc_cache[npc_name]
		if _npc_gift_tastes_cache.has(npc_name):
			npc.gift_tastes = _npc_gift_tastes_cache

	print("DataLoader: Gostos de presentes carregados")

func get_gift_taste_data(npc_name: String) -> String:
	return _npc_gift_tastes_cache.get(npc_name, "")

## ==================== BUILDINGS ====================
func load_buildings() -> void:
	var file = FileAccess.open(data_path + "Buildings.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Buildings.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		var data = json[key]
		var building = BuildingData.new()
		building.internal_name = key
		building.display_name = data.get("Name", "")
		building.description = data.get("Description", "")
		building.texture_path = data.get("Texture2D", "")
		building.skins = data.get("Skins", [])
		building.draw_shadow = data.get("DrawShadow", true)
		var sign = data.get("UpgradeSignTile", "-1, -1").split(",")
		building.upgrade_sign_tile = Vector2i(sign[0].strip_edges().to_int(), sign[1].strip_edges().to_int())
		building.upgrade_sign_height = data.get("UpgradeSignHeight", 0.0)
		var sz = data.get("Size", {})
		building.size = Vector2i(sz.get("X", 3), sz.get("Y", 2))
		building.fade_when_behind = data.get("FadeWhenBehind", true)
		var src = data.get("SourceRect", {})
		building.source_rect = Rect2i(src.get("X", 0), src.get("Y", 0), src.get("Width", 0), src.get("Height", 0))
		var so = data.get("SeasonOffset", {})
		building.season_offset = Vector2i(so.get("X", 0), so.get("Y", 0))
		var doff = data.get("DrawOffset", "0, 0").split(",")
		building.draw_offset = Vector2i(doff[0].strip_edges().to_int(), doff[1].strip_edges().to_int())
		building.sort_tile_offset = data.get("SortTileOffset", 0.0)
		building.building_type = data.get("BuildingType", "")
		building.builder = data.get("Builder", "Robin")
		building.build_days = data.get("BuildDays", 2)
		building.build_cost = data.get("BuildCost", 0)
		building.build_materials = data.get("BuildMaterials", [])
		building.magical_construction = data.get("MagicalConstruction", false)
		var bmdo = data.get("BuildMenuDrawOffset", {})
		building.build_menu_draw_offset = Vector2i(bmdo.get("X", 0), bmdo.get("Y", 0))
		var hd = data.get("HumanDoor", {})
		building.human_door = Vector2i(hd.get("X", -1), hd.get("Y", -1))
		building.animal_door = data.get("AnimalDoor", {})
		building.animal_door_open_duration = data.get("AnimalDoorOpenDuration", 0.0)
		building.animal_door_close_duration = data.get("AnimalDoorCloseDuration", 0.0)
		building.max_occupants = data.get("MaxOccupants", 0)
		building.valid_occupant_types = data.get("ValidOccupantTypes", [])
		building.allow_animal_pregnancy = data.get("AllowAnimalPregnancy", false)
		building.hay_capacity = data.get("HayCapacity", 0)
		building.chests = data.get("Chests", [])
		building.additional_tile_property_radius = data.get("AdditionalTilePropertyRadius", 0)
		building.allows_flooring_underneath = data.get("AllowsFlooringUnderneath", true)
		_building_cache[key] = building

	print("DataLoader: %d edifícios carregados" % _building_cache.size())

func get_building(name: String) -> BuildingData:
	return _building_cache.get(name)

func get_all_buildings() -> Array[BuildingData]:
	var result = []
	for b in _building_cache.values():
		result.append(b)
	return result

## ==================== RECIPES ====================
func load_recipes() -> void:
	# Crafting Recipes
	var file = FileAccess.open(data_path + "CraftingRecipes.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		for key in json:
			var recipe = RecipeData.new()
			recipe.recipe_name = key
			recipe.raw_data = json[key]
			recipe.parse_raw_data()
			_recipe_cache[key] = recipe
		print("DataLoader: %d receitas de crafting carregadas" % _recipe_cache.size())

	# Cooking Recipes
	file = FileAccess.open(data_path + "CookingRecipes.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		for key in json:
			var recipe = RecipeData.new()
			recipe.recipe_name = key
			recipe.raw_data = json[key]
			recipe.parse_raw_data()
			_recipe_cache[key] = recipe
		print("DataLoader: %d receitas de culinária carregadas" % _recipe_cache.size())

func get_recipe(name: String) -> RecipeData:
	return _recipe_cache.get(name)

func get_all_recipes() -> Array[RecipeData]:
	var result = []
	for r in _recipe_cache.values():
		result.append(r)
	return result

func get_crafting_recipes() -> Array[RecipeData]:
	var result = []
	for r in _recipe_cache.values():
		if not r.is_cooking:
			result.append(r)
	return result

func get_cooking_recipes() -> Array[RecipeData]:
	var result = []
	for r in _recipe_cache.values():
		if r.is_cooking:
			result.append(r)
	return result

## ==================== SHOPS ====================
func load_shops() -> void:
	var file = FileAccess.open(data_path + "Shops.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Shops.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		var data = json[key]
		var shop = ShopData.new()
		shop.shop_id = key
		shop.currency = data.get("Currency", 0)
		shop.price_modifier_mode = data.get("PriceModifierMode", 0)
		shop.owners = data.get("Owners", [])
		shop.items = data.get("Items", [])
		shop.salable_item_tags = data.get("SalableItemTags", [])
		_shop_cache[key] = shop

	print("DataLoader: %d lojas carregadas" % _shop_cache.size())

func get_shop(shop_id: String) -> ShopData:
	return _shop_cache.get(shop_id)

func get_all_shops() -> Array[ShopData]:
	var result = []
	for s in _shop_cache.values():
		result.append(s)
	return result

## ==================== FARM ANIMALS ====================
func load_farm_animals() -> void:
	var file = FileAccess.open(data_path + "FarmAnimals.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: FarmAnimals.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		var data = json[key]
		# FarmAnimalData seria uma classe similar
		_farm_animal_cache[key] = data

	print("DataLoader: %d animais de fazenda carregados" % _farm_animal_cache.size())

func get_farm_animal(name: String) -> Dictionary:
	return _farm_animal_cache.get(name, {})

## ==================== PLACEHOLDERS PARA OUTROS DADOS ====================
# Estes métodos seguem o mesmo padrão - implementar conforme necessário

## ==================== FRUIT TREES ====================
func load_fruit_trees() -> void:
	var file = FileAccess.open(data_path + "FruitTrees.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: FruitTrees.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		var data = json[key]
		_fruit_tree_cache[key] = data

	print("DataLoader: %d árvores frutíferas carregadas" % _fruit_tree_cache.size())

func get_fruit_tree(name: String) -> Dictionary:
	return _fruit_tree_cache.get(name, {})

func get_all_fruit_trees() -> Array[Dictionary]:
	var result = []
	for ft in _fruit_tree_cache.values():
		result.append(ft)
	return result

## ==================== QUESTS ====================
func load_quests() -> void:
	var file = FileAccess.open(data_path + "Quests.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Quests.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		var data = json[key]
		data.id = key
		_quest_cache[key] = data

	print("DataLoader: %d quests carregadas" % _quest_cache.size())

func get_quest(quest_id: String) -> Dictionary:
	return _quest_cache.get(quest_id)

func get_all_quests() -> Array[Dictionary]:
	var result = []
	for q in _quest_cache.values():
		result.append(q)
	return result

## ==================== SPECIAL ORDERS ====================
var _special_orders_cache: Array = []

func load_special_orders() -> void:
	var file = FileAccess.open(data_path + "SpecialOrders.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: SpecialOrders.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	_special_orders_cache = []
	for order in json:
		_special_orders_cache.append(order)

	print("DataLoader: %d special orders carregados" % _special_orders_cache.size())

func get_special_orders() -> Array[Dictionary]:
	return _special_orders_cache

func generate_weekly_special_orders(board_type: String, player_level: int) -> Array[Dictionary]:
	# Filtra pedidos do tipo do quadro e nível do jogador
	var result = []
	for order in _special_orders_cache:
		if order.get("BoardType", "qi") == board_type:
			var req_level = order.get("RequiredLevel", 0)
			if player_level >= req_level:
				result.append(order)
	# Embaralha e pega alguns
	result.shuffle()
	return result.slice(0, 3)

## ==================== FESTIVALS ====================
var _festival_cache: Dictionary = {}

func load_festivals() -> void:
	var file = FileAccess.open(data_path + "Festivals.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Festivals.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	_festival_cache = json
	print("DataLoader: Festivais carregados")

func get_festival(key: String) -> Dictionary:
	return _festival_cache.get(key, {})

## ==================== MACHINES ====================
func load_machines() -> void:
	var file = FileAccess.open(data_path + "Machines.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Machines.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		_machine_cache[key] = json[key]

	print("DataLoader: %d máquinas carregadas" % _machine_cache.size())

func get_machine(name: String) -> Dictionary:
	return _machine_cache.get(name, {})

## ==================== WEAPONS ====================
func load_weapons() -> void:
	var file = FileAccess.open(data_path + "Weapons.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Weapons.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		_weapon_cache[key] = json[key]

	print("DataLoader: %d armas carregadas" % _weapon_cache.size())

func get_weapon(name: String) -> Dictionary:
	return _weapon_cache.get(name, {})

## ==================== TOOLS ====================
func load_tools() -> void:
	var file = FileAccess.open(data_path + "Tools.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Tools.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		_tool_cache[key] = json[key]

	print("DataLoader: %d ferramentas carregadas" % _tool_cache.size())

func get_tool(name: String) -> Dictionary:
	return _tool_cache.get(name, {})

## ==================== BUFFS ====================
func load_buffs() -> void:
	var file = FileAccess.open(data_path + "Buffs.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Buffs.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		_buff_cache[key] = json[key]

	print("DataLoader: %d buffs carregados" % _buff_cache.size())

func get_buff(name: String) -> Dictionary:
	return _buff_cache.get(name, {})

## ==================== BUNDLES (COMMUNITY CENTER) ====================
func load_bundles() -> void:
	var file = FileAccess.open(data_path + "Bundles.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Bundles.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	for key in json:
		_bundle_cache[key] = json[key]

	print("DataLoader: %d bundles carregados" % _bundle_cache.size())

func get_bundle(name: String) -> Dictionary:
	return _bundle_cache.get(name, {})

## ==================== PLACEHOLDERS RESTANTES ====================
func load_locations() -> void: pass
func load_fences() -> void: pass
func load_big_craftables() -> void: pass
func load_fish_ponds() -> void: pass
func load_movies() -> void: pass

func load_pets() -> void:
	var file = FileAccess.open(data_path + "Pets.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Pets.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	_pet_cache = json
	print("DataLoader: %d pets carregados" % _pet_cache.size())

func get_pet(pet_id: String) -> Dictionary:
	return _pet_cache.get(pet_id, {})

func get_all_pets() -> Array[Dictionary]:
	var result = []
	for pet in _pet_cache.values():
		result.append(pet)
	return result

func load_pants() -> void: pass
func load_shirts() -> void: pass
func load_wild_trees() -> void: pass
func load_garbage_cans() -> void: pass
func load_giant_crops() -> void: pass
func load_home_renovations() -> void: pass
func load_minecarts() -> void: pass
func load_museum_rewards() -> void: pass
func load_powers() -> void: pass
func load_location_contexts() -> void: pass
func load_weddings() -> void: pass
func load_makeover_outfits() -> void: pass
func load_monster_slayer_quests() -> void: pass
func load_jukebox_tracks() -> void: pass
func load_lost_items_shop() -> void: pass
func load_movies_reactions() -> void: pass
func load_paint_data() -> void: pass
func load_passive_festivals() -> void: pass
func load_engagement_dialogues() -> void: pass
func load_incoming_phone_calls() -> void: pass
func load_aquarium_fish() -> void: pass
func load_random_bundles() -> void: pass
func load_trigger_actions() -> void: pass
func load_world_map() -> void: pass
func load_achievements() -> void: pass
func load_additional_farms() -> void: pass
func load_additional_languages() -> void: pass
func load_additional_wallpaper_flooring() -> void: pass
func load_chair_tiles() -> void: pass
func load_floors_and_paths() -> void: pass
func load_furniture() -> void: pass
func load_hair_data() -> void: pass
## ==================== MAIL ====================
func load_mail() -> void:
	var file = FileAccess.open(data_path + "Mail.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: Mail.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	_mail_cache = json
	print("DataLoader: %d cartas carregadas" % _mail_cache.size())

func get_mail(key: String) -> Dictionary:
	return _mail_cache.get(key, {})

## ==================== SECRET NOTES ====================
func load_secret_notes() -> void:
	var file = FileAccess.open(data_path + "SecretNotes.json", FileAccess.READ)
	if not file:
		push_error("DataLoader: SecretNotes.json não encontrado")
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	_secret_note_cache = json
	print("DataLoader: %d notas secretas carregadas" % _secret_note_cache.size())

func get_secret_note(note_id: int) -> Dictionary:
	return _secret_note_cache.get(str(note_id), {})

## ==================== TV CHANNELS ====================
func load_tv_channels() -> void:
	# TV cooking channel
	var file = FileAccess.open(data_path + "TV_CookingChannel.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		_tv_cooking_channel_cache = json
		print("DataLoader: TV Cooking Channel carregado")

	# TV tip channel
	file = FileAccess.open(data_path + "TV_TipChannel.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		_tv_tip_channel_cache = json
		print("DataLoader: TV Tip Channel carregado")

func get_tv_cooking_episode(key: String) -> Dictionary:
	return _tv_cooking_channel_cache.get(key, {})

func get_tv_tip_channel(key: String) -> Dictionary:
	return _tv_tip_channel_cache.get(key, {})

func _parse_colors(arr: Array) -> Array[Color]:
	var result = []
	for c in arr:
		if c is String:
			var html = c.strip_edges()
			if html.begins_with("#"):
				result.append(Color.from_string(html, Color.WHITE))
			else:
				result.append(Color.WHITE)
		elif c is Dictionary:
			result.append(Color(c.get("R", 1), c.get("G", 1), c.get("B", 1), c.get("A", 1)))
	return result

## ==================== UTILITY ====================
func save_as_resources() -> void:
	"""Salva todos os caches como arquivos .tres para uso no Editor"""
	var absolute_path = ProjectSettings.globalize_path(data_path)
	DirAccess.make_dir_recursive_absolute(absolute_path)

	# Salva crops
	for crop in _crop_cache.values():
		ResourceSaver.save(crop, data_path + "crops/crop_%s.tres" % crop.id)

	# Salva items
	for item in _item_cache.values():
		ResourceSaver.save(item, data_path + "items/item_%s.tres" % item.id)

	# Salva NPCs
	for npc in _npc_cache.values():
		ResourceSaver.save(npc, data_path + "npcs/npc_%s.tres" % npc.internal_name)

	# Salva buildings
	for building in _building_cache.values():
		ResourceSaver.save(building, data_path + "buildings/building_%s.tres" % building.internal_name)

	# Salva recipes
	for recipe in _recipe_cache.values():
		ResourceSaver.save(recipe, data_path + "recipes/recipe_%s.tres" % recipe.recipe_name)

	# Salva shops
	for shop in _shop_cache.values():
		ResourceSaver.save(shop, data_path + "shops/shop_%s.tres" % shop.shop_id)

	print("DataLoader: Resources salvos em super.tres")