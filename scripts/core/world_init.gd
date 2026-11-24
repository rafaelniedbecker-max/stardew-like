class_name WorldInit
extends Node

## Inicialização do mundo: farm plots, NPCs, edifícios, etc.

@export var farm_plot_scene: PackedScene
@export var npc_scene: PackedScene
@export var building_scene: PackedScene
@export var shipping_bin_scene: PackedScene

## Tamanho da grade da fazenda
@export var farm_grid_width: int = 64
@export var farm_grid_height: int = 64
@export var tile_size: int = 32

## Posição inicial da fazenda (canto superior esquerdo)
@export var farm_origin: Vector2i = Vector2i(0, 0)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Aguarda um frame para garantir que tudo está carregado
	await get_tree().process_frame
	initialize_world()

func initialize_world() -> void:
	print("WorldInit: Inicializando mundo...")
	_create_farm_plots()
	_load_saved_crops()
	_spawn_npcs()
	_spawn_buildings()
	_initialize_systems()
	print("WorldInit: Mundo inicializado!")

func _initialize_systems() -> void:
	# Inicializa sistemas que precisam de setup no mundo
	if PetManager:
		# PetManager carrega pet automaticamente no _ready
		pass

	if TVChannels:
		# TVChannels carrega dados no _ready
		pass

	if MailSystem:
		# MailSystem carrega cartas no _ready
		pass

	if CharacterCustomization:
		# Aplica aparência salva ao player
		CharacterCustomization._apply_to_player()

	if CollectionsMenu:
		# Carrega coleções
		pass

	if CommunityCenter:
		CommunityCenter._load_progress()

	if Museum:
		Museum._load_museum_data()

	if Greenhouse:
		# Greenhouse carrega no _ready
		pass

	if MineCart:
		MineCart._load_progress()
		MineCart._check_unlocks()

	if SpecialOrdersBoard:
		SpecialOrdersBoard._load_special_orders()

	if FestivalManager:
		FestivalManager._load_festival_data()

	if QuestManager:
		QuestManager._load_quests()
		QuestManager.quest_added.connect(GameManager.emit_signal.bind("quest_added"))
		QuestManager.quest_completed.connect(GameManager.emit_signal.bind("quest_completed", {}))

	if RelationshipManager:
		RelationshipManager._load_relationships()

	if BuffManager:
		BuffManager._load_buffs()

	if MineManager:
		MineManager._load_mine_data()

	if FishingManager:
		FishingManager._load_fishing_data()

	if BuildingManager:
		BuildingManager._load_buildings()

## ==================== FARM PLOTS ====================
func _create_farm_plots() -> void:
	var farm_plots_node = get_tree().get_first_node_in_group("farm_plots")
	if not farm_plots_node:
		farm_plots_node = get_node_or_null("FarmPlots")
	if not farm_plots_node:
		farm_plots_node = Node2D.new()
		farm_plots_node.name = "FarmPlots"
		farm_plots_node.add_to_group("farm_plots")
		get_tree().root.get_child(0).add_child(farm_plots_node)

	# Cria grade de plots
	for x in range(farm_grid_width):
		for y in range(farm_grid_height):
			var plot = farm_plot_scene.instantiate()
			plot.grid_position = Vector2i(farm_origin.x + x, farm_origin.y + y)
			plot.position = Vector2(x * tile_size, y * tile_size)
			farm_plots_node.add_child(plot)

	print("WorldInit: %d farm plots criados" % (farm_grid_width * farm_grid_height))

func _load_saved_crops() -> void:
	# Cultivos são restaurados automaticamente via FarmPlot._ready()
	# que verifica GameManager.farm_crops
	pass

## ==================== NPCs ====================
func _spawn_npcs() -> void:
	var npc_data_list = DataLoader.get_all_npcs()
	var npc_container = get_node_or_null("NPCs")
	if not npc_container:
		npc_container = Node2D.new()
		npc_container.name = "NPCs"
		get_tree().root.get_child(0).add_child(npc_container)

	for npc_data in npc_data_list:
		# Só spawna NPCs que têm agenda para hoje
		var weekday = GameManager.current_weekday if GameManager else 0
		var schedule = npc_data.get_schedule_for_day(weekday)
		if schedule == "":
			continue

		var npc = npc_scene.instantiate()
		npc.initialize(npc_data)
		npc.name = npc_data.internal_name
		npc_container.add_child(npc)

		# Posiciona na posição inicial da agenda
		var home_pos = _get_npc_home_position(npc_data)
		npc.global_position = home_pos

	print("WorldInit: %d NPCs spawnados" % npc_container.get_child_count())

func _get_npc_home_position(npc_data: NPCData) -> Vector2:
	# Posições baseadas na home_region
	match npc_data.home_region:
		"Town":
			return Vector2(320, 400) + Vector2(randi_range(-50, 50), randi_range(-50, 50))
		"Farm":
			return Vector2(160, 160) + Vector2(randi_range(-30, 30), randi_range(-30, 30))
		"Desert":
			return Vector2(800, 800)
		_:
			return Vector2(320, 400)

## ==================== EDIFÍCIOS ====================
func _spawn_buildings() -> void:
	var building_container = get_node_or_null("Buildings")
	if not building_container:
		building_container = Node2D.new()
		building_container.name = "Buildings"
		get_tree().root.get_child(0).add_child(building_container)

	# Spawna edifícios salvos
	if GameManager:
		for building_data in GameManager.farm_buildings:
			_spawn_building(building_data)

	# Edifícios fixos iniciais (casa, celeiro, etc.)
	_spawn_initial_buildings(building_container)

func _spawn_initial_buildings(container: Node2D) -> void:
	# Casa do jogador
	var house_data = DataLoader.get_building("House")
	if house_data:
		_create_building_instance(house_data, Vector2i(5, 5), container)

	# Celeiro inicial
	var barn_data = DataLoader.get_building("Barn")
	if barn_data:
		_create_building_instance(barn_data, Vector2i(15, 10), container)

	# Galinheiro inicial
	var coop_data = DataLoader.get_building("Coop")
	if coop_data:
		_create_building_instance(coop_data, Vector2i(15, 15), container)

	# Caixa de Entregas (Shipping Bin)
	if shipping_bin_scene:
		var bin = shipping_bin_scene.instantiate()
		bin.name = "ShippingBin"
		bin.global_position = Vector2(10 * tile_size, 5 * tile_size)
		container.add_child(bin)
		bin.add_to_group("shipping_bin")

func _create_building_instance(building_data: BuildingData, grid_pos: Vector2i, container: Node2D) -> void:
	var building = building_scene.instantiate() if building_scene else Node2D.new()
	building.name = building_data.internal_name
	building.global_position = Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)
	container.add_child(building)

	# Configura sprite do edifício
	# TODO: Carregar textura real

func _spawn_building(data: Dictionary) -> void:
	# Restaura edifício salvo
	var building_type = data.get("type", "")
	var position = Vector2(data.get("position_x", 0), data.get("position_y", 0))
	var building_data = DataLoader.get_building(building_type)
	if building_data:
		var container = get_node_or_null("Buildings")
		_create_building_instance(building_data, Vector2i(position.x / tile_size, position.y / tile_size), container)

## ==================== UTILIDADES ====================
static func world_to_grid(world_pos: Vector2, tile_size: int = 32) -> Vector2i:
	return Vector2i(int(world_pos.x / tile_size), int(world_pos.y / tile_size))

static func grid_to_world(grid_pos: Vector2i, tile_size: int = 32) -> Vector2:
	return Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)

static func get_adjacent_tiles(center: Vector2i, radius: int = 1) -> Array[Vector2i]:
	var tiles = []
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x == 0 and y == 0:
				continue
			tiles.append(Vector2i(center.x + x, center.y + y))
	return tiles