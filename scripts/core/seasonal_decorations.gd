class_name SeasonalDecorations
extends Node

## Sistema de Decorações Sazonais: mudanças visuais automáticas, itens sazonais

@export var decoration_scenes: Dictionary = {}

## Estado
var current_season: int = 0
var active_decorations: Array[Node2D] = []
var decoration_spots: Array[Vector2] = []

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	if GameManager:
		GameManager.season_changed.connect(_on_season_changed)
		GameManager.day_changed.connect(_on_day_changed)

	# Carrega decorações salvas
	_load_decorations()

	# Aplica decoração da estação atual
	if GameManager:
		_apply_season_decorations(GameManager.current_season)

func _on_season_changed(season: int, year: int) -> void:
	_apply_season_decorations(season)

func _on_day_changed(day: int, season: int, year: int) -> void:
	# Verifica feriados/festivais para decorações especiais
	_check_festival_decorations()

func _check_festival_decorations() -> void:
	if not GameManager or not FestivalManager:
		return

	var festival = FestivalManager.get_current_festival()
	if festival:
		_apply_festival_decorations(festival)
	else:
		# Remove decorações de festival, volta ao normal da estação
		_apply_season_decorations(GameManager.current_season)

## ==================== DECORAÇÕES POR ESTAÇÃO ====================
const SEASON_DECORATIONS = {
	0: {  # Spring
		"ground_tint": Color(0.6, 0.9, 0.6, 0.1),
		"sky_tint": Color(0.8, 0.9, 1.0),
		"ambient_color": Color(0.7, 0.9, 0.7),
		"particles": "petals",
		"music": "spring",
		"decorations": [
			{"type": "flower_patch", "chance": 0.3, "items": ["(O)591", "(O)593", "(O)595", "(O)597", "(O)599"]},  # Flores
			{"type": "tree_blossom", "chance": 0.5},  # Flores nas árvores
			{"type": "grass_tint", "color": Color(0.5, 0.8, 0.5)}
		],
		"shop_items": ["(O)472", "(O)473", "(O)474", "(O)475", "(O)476", "(O)477", "(O)591", "(O)593"]  # Sementes primavera
	},
	1: {  # Summer
		"ground_tint": Color(0.9, 0.9, 0.6, 0.1),
		"sky_tint": Color(1.0, 0.9, 0.7),
		"ambient_color": Color(1.0, 0.9, 0.7),
		"particles": "none",
		"music": "summer",
		"decorations": [
			{"type": "crop_vines", "chance": 0.4},  # Trepadeiras nas culturas
			{"type": "sunflowers", "chance": 0.3, "items": ["(O)599"]},
			{"type": "grass_tint", "color": Color(0.7, 0.8, 0.5)}
		],
		"shop_items": ["(O)478", "(O)479", "(O)480", "(O)481", "(O)482", "(O)483", "(O)599"]  # Sementes verão
	},
	2: {  # Fall
		"ground_tint": Color(0.9, 0.6, 0.3, 0.15),
		"sky_tint": Color(0.9, 0.7, 0.5),
		"ambient_color": Color(0.9, 0.6, 0.4),
		"particles": "leaves",
		"music": "fall",
		"decorations": [
			{"type": "fallen_leaves", "chance": 0.6},
			{"type": "pumpkin_patches", "chance": 0.3, "items": ["(O)276"]},
			{"type": "mushroom_clusters", "chance": 0.2, "items": ["(O)281", "(O)283"]},
			{"type": "grass_tint", "color": Color(0.8, 0.5, 0.3)}
		],
		"shop_items": ["(O)484", "(O)485", "(O)486", "(O)487", "(O)488", "(O)489", "(O)490", "(O)491", "(O)492", "(O)493", "(O)494", "(O)276"]  # Sementes outono + abóbora
	},
	3: {  # Winter
		"ground_tint": Color(0.8, 0.9, 1.0, 0.2),
		"sky_tint": Color(0.7, 0.8, 1.0),
		"ambient_color": Color(0.6, 0.7, 0.9),
		"particles": "snow",
		"music": "winter",
		"decorations": [
			{"type": "snow_drifts", "chance": 0.7},
			{"type": "ice_crystals", "chance": 0.3},
			{"type": "frozen_ponds", "chance": 0.4},
			{"type": "grass_tint", "color": Color(0.6, 0.7, 0.9)}
		],
		"shop_items": []  # Sem sementes no inverno (exceto estufa)
	}
}

## ==================== APLICAÇÃO DE DECORAÇÕES ====================
func _apply_season_decorations(season: int) -> void:
	current_season = season

	# Remove decorações antigas
	_clear_decorations()

	var season_data = SEASON_DECORATIONS.get(season, {})

	# Aplica tint no chão
	if WorldInit:
		var ground_tint = season_data.get("ground_tint", Color(1,1,1,0))
		# Aplica via CanvasModulate ou shader no TileMap
		_apply_ground_tint(ground_tint)

	# Aplica cor do céu/ambiente
	if DayNightCycle:
		DayNightCycle._adjust_season_lighting(season)

	# Partículas sazonais
	if ParticleManager:
		var particle_type = season_data.get("particles", "none")
		if particle_type != "none":
			ParticleManager.seasonal_ambient(season)

	# Spawna decorações no mundo
	_spawn_season_decorations(season_data)

	# Atualiza lojas
	_update_shop_seasonal_items(season_data)

func _apply_festival_decorations(festival_name: String) -> void:
	var festival_decorations = {
		"Egg Festival": {
			"ground_tint": Color(1.0, 0.9, 0.7, 0.2),
			"decorations": [
				{"type": "egg_nests", "chance": 0.5, "items": ["(O)454"]},
				{"type": "bunny_decor", "chance": 0.3},
				{"type": "pastel_colors", "chance": 0.5}
			]
		},
		"Flower Dance": {
			"ground_tint": Color(1.0, 0.8, 0.9, 0.2),
			"decorations": [
				{"type": "flower_arches", "chance": 0.5},
				{"type": "ribbons", "chance": 0.4},
				{"type": "dance_floor", "position": "town_center"}
			]
		},
		"Luau": {
			"ground_tint": Color(0.9, 1.0, 0.8, 0.2),
			"decorations": [
				{"type": "tiki_torches", "chance": 0.5},
				{"type": "fruit_baskets", "chance": 0.3},
				{"type": "beach_decor", "position": "beach"}
			]
		},
		"Stardew Valley Fair": {
			"ground_tint": Color(1.0, 0.9, 0.7, 0.2),
			"decorations": [
				{"type": "booths", "position": "town_square"},
				{"type": "bunting", "chance": 0.6},
				{"type": "grange_display", "position": "center"}
			]
		},
		"Spirit's Eve": {
			"ground_tint": Color(0.3, 0.2, 0.5, 0.3),
			"decorations": [
				{"type": "jack_o_lanterns", "chance": 0.7},
				{"type": "spooky_lights", "chance": 0.5},
				{"type": "maze_entrance", "position": "town_center"}
			]
		},
		"Festival of Ice": {
			"ground_tint": Color(0.7, 0.9, 1.0, 0.3),
			"decorations": [
				{"type": "ice_sculptures", "chance": 0.5},
				{"type": "snowflakes", "chance": 0.8},
				{"type": "ice_fishing_huts", "position": "lake"}
			]
		},
		"Feast of the Winter Star": {
			"ground_tint": Color(0.8, 0.7, 1.0, 0.2),
			"decorations": [
				{"type": "christmas_lights", "chance": 0.8},
				{"type": "christmas_trees", "chance": 0.5},
				{"type": "gift_boxes", "chance": 0.4}
			]
		}
	}

	var decor = festival_decorations.get(festival_name, {})
	_apply_festival_visuals(decor)

func _apply_ground_tint(tint: Color) -> void:
	# Aplica via CanvasModulate global ou shader no TileMap
	var canvas = get_tree().root.get_child(0).get_node_or_null("SeasonTint")
	if not canvas:
		canvas = CanvasModulate.new()
		canvas.name = "SeasonTint"
		get_tree().root.get_child(0).add_child(canvas)
	canvas.color = tint

func _apply_festival_visuals(decor: Dictionary) -> void:
	var tint = decor.get("ground_tint", Color(1,1,1,0))
	_apply_ground_tint(tint)

	var decorations = decor.get("decorations", [])
	for dec in decorations:
		_spawn_festival_decoration(dec)

func _spawn_season_decorations(season_data: Dictionary) -> void:
	var decorations = season_data.get("decorations", [])
	for dec in decorations:
		_spawn_decoration_type(dec)

func _spawn_festival_decoration(dec: Dictionary) -> void:
	var dec_type = dec.get("type", "")
	var chance = dec.get("chance", 1.0)
	var position = dec.get("position", "")

	if randf() > chance:
		return

	match dec_type:
		"egg_nests":
			_spawn_egg_nests()
		"bunny_decor":
			_spawn_bunny_decor()
		"pastel_colors":
			_apply_pastel_tint()
		"flower_arches":
			_spawn_flower_arches()
		"ribbons":
			_spawn_ribbons()
		"dance_floor":
			_spawn_dance_floor(position)
		"tiki_torches":
			_spawn_tiki_torches()
		"fruit_baskets":
			_spawn_fruit_baskets()
		"beach_decor":
			_spawn_beach_decor()
		"booths":
			_spawn_festival_booths()
		"bunting":
			_spawn_bunting()
		"grange_display":
			_spawn_grange_display()
		"jack_o_lanterns":
			_spawn_jack_o_lanterns()
		"spooky_lights":
			_spawn_spooky_lights()
		"maze_entrance":
			_spawn_maze_entrance()
		"ice_sculptures":
			_spawn_ice_sculptures()
		"snowflakes":
			_spawn_snowflakes()
		"ice_fishing_huts":
			_spawn_ice_fishing_huts()
		"christmas_lights":
			_spawn_christmas_lights()
		"christmas_trees":
			_spawn_christmas_trees()
		"gift_boxes":
			_spawn_gift_boxes()

func _spawn_decoration_type(dec: Dictionary) -> void:
	var dec_type = dec.get("type", "")
	var chance = dec.get("chance", 1.0)
	var items = dec.get("items", [])

	if randf() > chance:
		return

	match dec_type:
		"flower_patch":
			_spawn_flower_patches(items)
		"tree_blossom":
			_apply_tree_blossom()
		"grass_tint":
			_apply_grass_tint(dec.color)
		"crop_vines":
			_apply_crop_vines()
		"sunflowers":
			_spawn_sunflowers(items)
		"fallen_leaves":
			_spawn_fallen_leaves()
		"pumpkin_patches":
			_spawn_pumpkin_patches(items)
		"mushroom_clusters":
			_spawn_mushroom_clusters(items)
		"snow_drifts":
			_spawn_snow_drifts()
		"ice_crystals":
			_spawn_ice_crystals()
		"frozen_ponds":
			_spawn_frozen_ponds()

# ==================== IMPLEMENTAÇÕES ESPECÍFICAS ====================
func _spawn_flower_patches(items: Array) -> void:
	# Spawna flores aleatórias na fazenda
	for i in range(randi_range(5, 15)):
		var pos = Vector2(randi_range(100, 1000), randi_range(100, 800))
		var item_id = items.pick_random()
		var item = DataLoader.get_item(item_id)
		if item and item.texture_path != "":
			var sprite = Sprite2D.new()
			sprite.texture = load(item.texture_path)
			sprite.global_position = pos
			sprite.z_index = -5
			get_tree().root.get_child(0).add_child(sprite)
			sprite.add_to_group("seasonal_decoration")

func _apply_tree_blossom() -> void:
	# Adiciona flores nas árvores
	for tree in get_tree().get_nodes_in_group("trees"):
		if tree.has_method("set_blossom"):
			tree.set_blossom(true)

func _apply_grass_tint(color: Color) -> void:
	# Aplica tint na grama via shader ou modulate
	var grass = get_tree().root.get_child(0).get_node_or_null("GrassLayer")
	if grass:
		grass.modulate = color

func _apply_crop_vines() -> void:
	# Adiciona trepadeiras nas culturas
	for crop in get_tree().get_nodes_in_group("crops"):
		if crop.has_method("add_vines"):
			crop.add_vines()

func _spawn_sunflowers(items: Array) -> void:
	for i in range(randi_range(3, 8)):
		var pos = Vector2(randi_range(200, 1200), randi_range(200, 800))
		var item_id = items.pick_random()
		_spawn_decoration_item(pos, item_id)

func _spawn_fallen_leaves() -> void:
	if ParticleManager:
		ParticleManager.seasonal_ambient(2)  # Fall = folhas

func _spawn_pumpkin_patches(items: Array) -> void:
	for i in range(randi_range(2, 6)):
		var pos = Vector2(randi_range(100, 1000), randi_range(100, 800))
		var item_id = items.pick_random()
		_spawn_decoration_item(pos, item_id)

func _spawn_mushroom_clusters(items: Array) -> void:
	for i in range(randi_range(3, 10)):
		var pos = Vector2(randi_range(100, 1000), randi_range(100, 800))
		var item_id = items.pick_random()
		_spawn_decoration_item(pos, item_id)

func _spawn_snow_drifts() -> void:
	if ParticleManager:
		ParticleManager.seasonal_ambient(3)  # Winter = neve

func _spawn_ice_crystals() -> void:
	# Spawna cristais de gelo nas bordas
	for i in range(randi_range(10, 30)):
		var pos = Vector2(randi_range(0, 1280), randi_range(0, 100))
		var sprite = Sprite2D.new()
		var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color(0,0,0,0))
		for x in range(16):
			for y in range(16):
				if randf() < 0.3:
					img.set_pixel(x, y, Color(0.7, 0.9, 1.0, 0.8))
		sprite.texture = ImageTexture.create_from_image(img)
		sprite.global_position = pos
		get_tree().root.get_child(0).add_child(sprite)
		sprite.add_to_group("seasonal_decoration")

func _spawn_frozen_ponds() -> void:
	# Congela água nos lagos
	for water in get_tree().get_nodes_in_group("water"):
		if water.has_method("freeze"):
			water.freeze()

# ==================== DECORAÇÕES DE FESTIVAL ====================
func _spawn_egg_nests() -> void:
	for i in range(randi_range(5, 12)):
		var pos = Vector2(randi_range(200, 1000), randi_range(200, 600))
		_spawn_decoration_item(pos, "(O)454")  # Chocolate Egg

func _spawn_bunny_decor() -> void:
	# Coelhos decorativos
	for i in range(randi_range(2, 5)):
		var pos = Vector2(randi_range(200, 1000), randi_range(200, 600))
		var sprite = Sprite2D.new()
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(Color(0,0,0,0))
		for x in range(8, 24):
			for y in range(8, 24):
				if (x-16)*(x-16) + (y-16)*(y-16) < 64:
					img.set_pixel(x, y, Color(1.0, 0.9, 0.9))
		sprite.texture = ImageTexture.create_from_image(img)
		sprite.global_position = Vector2(randi_range(200, 1000), randi_range(200, 600))
		get_tree().root.get_child(0).add_child(sprite)
		sprite.add_to_group("seasonal_decoration")

func _apply_pastel_tint() -> void:
	var canvas = get_tree().root.get_child(0).get_node_or_null("SeasonTint")
	if canvas:
		canvas.color = canvas.color.lerp(Color(1.0, 0.9, 0.9, 1.0), 0.3)

# ... (outras funções de spawn específicas)

func _spawn_decoration_item(position: Vector2, item_id: String) -> void:
	var item = DataLoader.get_item(item_id)
	if not item or not item.texture_path:
		return

	var sprite = Sprite2D.new()
	sprite.texture = load(item.texture_path)
	sprite.global_position = position
	sprite.z_index = -2
	get_tree().root.get_child(0).add_child(sprite)
	sprite.add_to_group("seasonal_decoration")

## ==================== LOJAS SAZONAIS ====================
func _update_shop_seasonal_items(season_data: Dictionary) -> void:
	if not ShopUI:
		return

	var items = season_data.get("shop_items", [])
	# Atualiza estoque da loja do Pierre
	if ShopUI:
		ShopUI.update_seasonal_stock(items)

## ==================== LIMPEZA ====================
func _clear_decorations() -> void:
	var decorations = get_tree().get_nodes_in_group("seasonal_decoration")
	for dec in decorations:
		dec.queue_free()

	# Reseta tint
	var canvas = get_tree().root.get_child(0).get_node_or_null("SeasonTint")
	if canvas:
		canvas.color = Color(1, 1, 1, 0)

	# Reseta árvores
	for tree in get_tree().get_nodes_in_group("trees"):
		if tree.has_method("set_blossom"):
			tree.set_blossom(false)

	# Reseta culturas
	for crop in get_tree().get_nodes_in_group("crops"):
		if crop.has_method("remove_vines"):
			crop.remove_vines()

	# Descongela água
	for water in get_tree().get_nodes_in_group("water"):
		if water.has_method("unfreeze"):
			water.unfreeze()

## ==================== PERSISTÊNCIA ====================
func _load_decorations() -> void:
	if GameManager:
		var data = GameManager.get_data("seasonal_decorations", {})
		# Restaura decorações colocadas pelo player
		pass

func get_save_data() -> Dictionary:
	return {
		"placed_decorations": []  # Lista de decorações colocadas pelo player
	}

func load_save_data(data: Dictionary) -> void:
	# Restaura decorações do player
	pass