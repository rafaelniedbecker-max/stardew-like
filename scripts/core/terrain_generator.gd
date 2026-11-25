extends Node

## Generates terrain using the PBR-based tileset
## Populates TileMapLayers with realistic terrain

@export var tileset_path: String = "res://resources/tilesets/farm_tileset_real.tres"
@export var farm_width: int = 64
@export var farm_height: int = 64
@export var tile_size: int = 16  # Tileset uses 16x16, world uses 32x32
@export var enable_normal_mapping: bool = true
@export var normal_map_path: String = "res://resources/tilesets/farm_atlas_normal.png"

## Tile IDs from our tileset (matching farm_tileset_real.tres)
const TILE_IDS = {
	"grass": [0, 1, 2, 3, 4, 5, 6, 7],
	"dirt_dry": [8, 9, 10, 11],
	"dirt_wet": [12, 13, 14, 15],
	"dirt_tilled": [16, 17, 18, 19],
	"sand": [20, 21, 22, 23],
	"stone": [24, 25, 26, 27],
	"path": [28, 29, 30, 31],
	"water": [32, 33, 34, 35, 36, 37, 38, 39],
	"forest": [40, 41, 42, 43],
}

var _tileset: TileSet
var _rng: RandomNumberGenerator

func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()
	call_deferred("generate_terrain")

func generate_terrain() -> void:
	print("TerrainGenerator: Carregando tileset...")
	_tileset = load(tileset_path)
	if not _tileset:
		print("ERRO: Tileset não encontrado em ", tileset_path)
		return

	var ground_layer = get_node_or_null("../TileMap")  # Ground layer
	if not ground_layer:
		# Try to find by name
		for child in get_parent().get_children():
			if child.name == "Ground" and child is TileMapLayer:
				ground_layer = child
				break

	if not ground_layer:
		print("ERRO: Camada Ground (TileMapLayer) não encontrada")
		return

	ground_layer.tile_set = _tileset
	print("TerrainGenerator: Tileset aplicado à camada Ground")

	# Setup normal mapping material
	if enable_normal_mapping:
		_setup_normal_mapping(ground_layer)

	# Generate base terrain
	_fill_base_grass(ground_layer)
	_add_dirt_patches(ground_layer)
	_add_water_areas(ground_layer)
	_add_paths(ground_layer)
	_add_forest_edges(ground_layer)

	# Also apply to Paths layer if needed
	var paths_layer = get_node_or_null("../Paths")
	if paths_layer and paths_layer is TileMapLayer:
		paths_layer.tile_set = _tileset
		if enable_normal_mapping:
			_setup_normal_mapping(paths_layer)

	print("TerrainGenerator: Terreno gerado!")

func _setup_normal_mapping(layer: TileMapLayer) -> void:
	"""Associa o normal map ao atlas usando a API 2D nativa do Godot 4."""
	if layer.tile_set == null:
		return
	var source := layer.tile_set.get_source(0) as TileSetAtlasSource
	if source == null:
		push_error("TerrainGenerator: TileSetAtlasSource 0 não encontrada")
		return

	var normal_texture: Texture2D = load(normal_map_path)
	if normal_texture == null:
		push_warning("TerrainGenerator: Normal map não encontrado em " + normal_map_path)
		return

	var canvas_texture: CanvasTexture
	if source.texture is CanvasTexture:
		canvas_texture = source.texture as CanvasTexture
	else:
		canvas_texture = CanvasTexture.new()
		canvas_texture.diffuse_texture = source.texture

	canvas_texture.normal_texture = normal_texture
	source.texture = canvas_texture
	print("TerrainGenerator: Normal map aplicado - ", normal_map_path)

func _fill_base_grass(layer: TileMapLayer) -> void:
	"""Fill entire farm with varied grass tiles."""
	for x in range(farm_width):
		for y in range(farm_height):
			# Use pseudo-random but deterministic selection
			_rng.seed = (x * 1000 + y) * 12345
			var tile_idx = _rng.randi_range(0, TILE_IDS["grass"].size() - 1)
			var tile_id = TILE_IDS["grass"][tile_idx]
			layer.set_cell(Vector2i(x, y), 0, Vector2i(tile_id % 32, tile_id // 32), 0)

func _add_dirt_patches(layer: TileMapLayer) -> void:
	"""Add dirt patches (farmable areas, worn paths)."""
	_rng.seed = 42

	# Main farmable area (center-ish)
	var farm_center_x = farm_width // 2
	var farm_center_y = farm_height // 2
	var farm_radius_x = 20
	var farm_radius_y = 15

	for x in range(farm_center_x - farm_radius_x, farm_center_x + farm_radius_x):
		for y in range(farm_center_y - farm_radius_y, farm_center_y + farm_radius_y):
			if x < 0 or x >= farm_width or y < 0 or y >= farm_height:
				continue

			var dx = (x - farm_center_x) / farm_radius_x
			var dy = (y - farm_center_y) / farm_radius_y
			var dist = sqrt(dx * dx + dy * dy)

			# Add noise for organic shape
			_rng.seed = x * 1000 + y + 10000
			var noise = _rng.randi_range(-1000, 1000) / 1000.0 * 0.3
			dist += noise

			if dist < 0.7:
				# Mix of dry dirt and tilled dirt
				if _rng.randi_range(0, 100) < 30:
					_set_dirt_tile(layer, x, y, true)  # tilled
				else:
					_set_dirt_tile(layer, x, y, false)  # dry

	# Add some random dirt patches around
	for i in range(15):
		_rng.seed = i * 555 + 999
		var px = _rng.randi_range(5, farm_width - 5)
		var py = _rng.randi_range(5, farm_height - 5)
		var radius = _rng.randi_range(3, 8)

		for x in range(px - radius, px + radius):
			for y in range(py - radius, py + radius):
				if x < 0 or x >= farm_width or y < 0 or y >= farm_height:
					continue
				var d = sqrt((x - px) * (x - px) + (y - py) * (y - py))
				if d < radius:
					_set_dirt_tile(layer, x, y, _rng.randi_range(0, 1) == 0)

func _set_dirt_tile(layer: TileMapLayer, x: int, y: int, tilled: bool) -> void:
	_rng.seed = x * 1000 + y + 20000
	var tile_array = TILE_IDS["dirt_tilled"] if tilled else TILE_IDS["dirt_dry"]
	var tile_idx = _rng.randi_range(0, tile_array.size() - 1)
	var tile_id = tile_array[tile_idx]
	layer.set_cell(Vector2i(x, y), 0, Vector2i(tile_id % 32, tile_id // 32), 0)

func _add_water_areas(layer: TileMapLayer) -> void:
	"""Add water bodies (pond, river)."""
	_rng.seed = 12345

	# Pond in bottom-right
	var pond_x = farm_width - 12
	var pond_y = farm_height - 10
	var pond_w = 10
	var pond_h = 8

	for x in range(pond_x, pond_x + pond_w):
		for y in range(pond_y, pond_y + pond_h):
			if x >= farm_width or y >= farm_height:
				continue
			# Organic pond shape
			var cx = pond_x + pond_w / 2.0
			var cy = pond_y + pond_h / 2.0
			var dx = (x - cx) / (pond_w / 2.0)
			var dy = (y - cy) / (pond_h / 2.0)
			var dist = sqrt(dx * dx + dy * dy)
			_rng.seed = x * 1000 + y + 30000
			dist += _rng.randi_range(-1000, 1000) / 1000.0 * 0.2

			if dist < 1.0:
				# Water tile (animated - use first frame for now)
				_rng.seed = x * 1000 + y + 40000
				var tile_idx = _rng.randi_range(0, TILE_IDS["water"].size() - 1)
				var tile_id = TILE_IDS["water"][tile_idx]
				layer.set_cell(Vector2i(x, y), 0, Vector2i(tile_id % 32, tile_id // 32), 0)

	# Small river across top
	for x in range(5, farm_width - 5):
		var y = 3 + int(sin(x * 0.3) * 2)
		if y >= 0 and y < farm_height:
			var tile_id = TILE_IDS["water"][0]
			layer.set_cell(Vector2i(x, y), 0, Vector2i(tile_id % 32, tile_id // 32), 0)
			if y + 1 < farm_height:
				layer.set_cell(Vector2i(x, y + 1), 0, Vector2i(tile_id % 32, tile_id // 32), 0)

func _add_paths(layer: TileMapLayer) -> void:
	"""Add worn dirt paths between key locations."""
	# Path from house (5,5) to farm center
	_draw_path(layer, Vector2i(5, 5), Vector2i(farm_width // 2, farm_height // 2))
	# Path from house to shipping bin area
	_draw_path(layer, Vector2i(5, 5), Vector2i(10, 5))
	# Path to barn
	_draw_path(layer, Vector2i(5, 5), Vector2i(15, 10))
	# Path to coop
	_draw_path(layer, Vector2i(5, 5), Vector2i(15, 15))

func _draw_path(layer: TileMapLayer, start: Vector2i, end: Vector2i) -> void:
	"""Draw a path using Bresenham-like algorithm with some wobble."""
	var x = start.x
	var y = start.y
	var dx = abs(end.x - start.x)
	var dy = abs(end.y - start.y)
	var sx = 1 if start.x < end.x else -1
	var sy = 1 if start.y < end.y else -1
	var err = dx - dy

	_rng.seed = start.x * 1000 + start.y + 50000

	while true:
		if x >= 0 and x < farm_width and y >= 0 and y < farm_height:
			# Path with some width
			for px in range(-1, 2):
				for py in range(-1, 2):
					var tx = x + px
					var ty = y + py
					if tx >= 0 and tx < farm_width and ty >= 0 and ty < farm_height:
						_rng.seed = tx * 1000 + ty + 60000
						if _rng.randi_range(0, 100) < 70:  # 70% chance for path tile
							var tile_idx = _rng.randi_range(0, TILE_IDS["path"].size() - 1)
							var tile_id = TILE_IDS["path"][tile_idx]
							layer.set_cell(Vector2i(tx, ty), 0, Vector2i(tile_id % 32, tile_id // 32), 0)

		if x == end.x and y == end.y:
			break

		var e2 = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy

func _add_forest_edges(layer: TileMapLayer) -> void:
	"""Add forest floor tiles at map edges (north and west)."""
	# North edge (top)
	for x in range(farm_width):
		for y in range(3):
			if y < farm_height:
				_rng.seed = x * 1000 + y + 70000
				if _rng.randi_range(0, 100) < 80:
					var tile_idx = _rng.randi_range(0, TILE_IDS["forest"].size() - 1)
					var tile_id = TILE_IDS["forest"][tile_idx]
					layer.set_cell(Vector2i(x, y), 0, Vector2i(tile_id % 32, tile_id // 32), 0)

	# West edge (left)
	for y in range(farm_height):
		for x in range(3):
			if x < farm_width:
				_rng.seed = x * 1000 + y + 80000
				if _rng.randi_range(0, 100) < 80:
					var tile_idx = _rng.randi_range(0, TILE_IDS["forest"].size() - 1)
					var tile_id = TILE_IDS["forest"][tile_idx]
					layer.set_cell(Vector2i(x, y), 0, Vector2i(tile_id % 32, tile_id // 32), 0)

## ==================== UTILITÁRIOS PÚBLICOS ====================

static func get_tile_atlas_coords(tile_id: int) -> Vector2i:
	"""Convert tile ID to atlas coordinates (32 columns)."""
	return Vector2i(tile_id % 32, tile_id // 32)

static func set_terrain_cell(layer: TileMapLayer, pos: Vector2i, terrain: String, variant: int = 0) -> void:
	"""Set a terrain tile at position."""
	if terrain not in TILE_IDS:
		return
	var tiles = TILE_IDS[terrain]
	var idx = clamp(variant, 0, tiles.size() - 1)
	var tile_id = tiles[idx]
	layer.set_cell(pos, 0, get_tile_atlas_coords(tile_id), 0)