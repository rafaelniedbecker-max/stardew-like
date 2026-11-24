class_name FurnitureManager
extends Node

## Sistema de Móveis: colocação, rotação, parede/chão, interior/exterior

@export var furniture_scenes: Dictionary = {}

## Estado
var placed_furniture: Dictionary = {}  # {key: {id, position, rotation, layer, room}}
var placement_mode: bool = false
var preview_furniture: Node2D = null
var selected_furniture_id: String = ""
var rotation: int = 0  # 0, 90, 180, 270
var current_layer: String = "floor"  # "floor", "wall", "ceiling"

## Categorias de móveis
const FURNITURE_CATEGORIES = {
	"floor": ["chair", "table", "bed", "dresser", "couch", "rug", "tv", "kitchen", "crafting", "storage", "decor"],
	"wall": ["painting", "window", "lamp", "shelf", "clock", "calendar", "decor"],
	"ceiling": ["chandelier", "lamp", "fan"]
}

## Dados de móveis (baseado em Furniture.json)
const FURNITURE_DATA = {
	# Cadeiras
	"(F)1700": {"name": "Wooden Chair", "category": "chair", "layer": "floor", "size": Vector2i(1, 1), "rotatable": true, "price": 250},
	"(F)1702": {"name": "Armchair", "category": "chair", "layer": "floor", "size": Vector2i(1, 1), "rotatable": true, "price": 500},
	"(F)1704": {"name": "Barstool", "category": "chair", "layer": "floor", "size": Vector2i(1, 1), "rotatable": true, "price": 300},

	# Mesas
	"(F)1720": {"name": "Wood Table", "category": "table", "layer": "floor", "size": Vector2i(2, 2), "rotatable": true, "price": 500},
	"(F)1722": {"name": "Dining Table", "category": "table", "layer": "floor", "size": Vector2i(3, 2), "rotatable": true, "price": 1000},
	"(F)1724": {"name": "Coffee Table", "category": "table", "layer": "floor", "size": Vector2i(2, 1), "rotatable": true, "price": 400},

	# Camas
	"(F)1740": {"name": "Single Bed", "category": "bed", "layer": "floor", "size": Vector2i(1, 2), "rotatable": true, "price": 1000},
	"(F)1742": {"name": "Double Bed", "category": "bed", "layer": "floor", "size": Vector2i(2, 2), "rotatable": true, "price": 2000},
	"(F)1744": {"name": "Crib", "category": "bed", "layer": "floor", "size": Vector2i(1, 1), "rotatable": true, "price": 500},

	# Armazenamento
	"(F)1760": {"name": "Dresser", "category": "storage", "layer": "floor", "size": Vector2i(2, 1), "rotatable": true, "price": 800},
	"(F)1762": {"name": "Cabinet", "category": "storage", "layer": "floor", "size": Vector2i(2, 2), "rotatable": true, "price": 1200},
	"(F)1764": {"name": "Bookshelf", "category": "storage", "layer": "wall", "size": Vector2i(2, 1), "rotatable": false, "price": 600},

	# Cozinha
	"(F)1780": {"name": "Stove", "category": "kitchen", "layer": "floor", "size": Vector2i(2, 1), "rotatable": true, "price": 1500},
	"(F)1782": {"name": "Fridge", "category": "kitchen", "layer": "floor", "size": Vector2i(1, 2), "rotatable": true, "price": 2000},
	"(F)1784": {"name": "Counter", "category": "kitchen", "layer": "floor", "size": Vector2i(2, 1), "rotatable": true, "price": 500},

	# Decoração chão
	"(F)1800": {"name": "Rug", "category": "rug", "layer": "floor", "size": Vector2i(2, 2), "rotatable": true, "price": 300},
	"(F)1802": {"name": "Plant Pot", "category": "decor", "layer": "floor", "size": Vector2i(1, 1), "rotatable": true, "price": 200},
	"(F)1804": {"name": "Vase", "category": "decor", "layer": "floor", "size": Vector2i(1, 1), "rotatable": true, "price": 150},

	# Parede
	"(F)1820": {"name": "Painting", "category": "painting", "layer": "wall", "size": Vector2i(1, 1), "rotatable": false, "price": 400},
	"(F)1822": {"name": "Window", "category": "window", "layer": "wall", "size": Vector2i(2, 1), "rotatable": false, "price": 500},
	"(F)1824": {"name": "Wall Lamp", "category": "lamp", "layer": "wall", "size": Vector2i(1, 1), "rotatable": false, "price": 300},
	"(F)1826": {"name": "Clock", "category": "decor", "layer": "wall", "size": Vector2i(1, 1), "rotatable": false, "price": 250},

	# Teto
	"(F)1840": {"name": "Chandelier", "category": "chandelier", "layer": "ceiling", "size": Vector2i(1, 1), "rotatable": false, "price": 1000},
}

## ==================== SINAIS ====================
signal furniture_placed(furniture_id: String, position: Vector2i, rotation: int)
signal furniture_removed(furniture_id: String)
signal furniture_rotated(furniture_id: String, rotation: int)
signal placement_mode_changed(active: bool)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Carrega móveis salvos
	_load_furniture()

	# Input para rotação
	Input.set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not placement_mode:
		return

	if event.is_action_pressed("tool_alt"):  # Botão direito - rotaciona
		_rotate_preview()
	elif event.is_action_pressed("interact"):  # E - confirma
		_confirm_placement()
	elif event.is_action_pressed("pause"):  # Esc - cancela
		_cancel_placement()

## ==================== MODO COLOCAÇÃO ====================
func start_placement(furniture_id: String) -> void:
	if not FURNITURE_DATA.has(furniture_id):
		return

	selected_furniture_id = furniture_id
	var data = FURNITURE_DATA[furniture_id]
	current_layer = data.layer
	rotation = 0

	# Cria preview
	preview_furniture = _create_preview(furniture_id)
	if preview_furniture:
		get_tree().root.get_child(0).add_child(preview_furniture)

	placement_mode = true
	emit_signal("placement_mode_changed", true)

	HUD.show_message("Clique para colocar | Botão direito: Rotacionar | Esc: Cancelar")

func _create_preview(furniture_id: String) -> Node2D:
	var data = FURNITURE_DATA[furniture_id]
	var preview = Node2D.new()
	preview.name = "FurniturePreview"

	var sprite = Sprite2D.new()
	sprite.name = "Sprite"

	# Carrega textura se existir
	if data.texture_path != "" and ResourceLoader.exists(data.texture_path):
		sprite.texture = load(data.texture_path)
	else:
		# Placeholder procedural
		sprite.texture = _create_placeholder_furniture(data)

	sprite.offset = Vector2(data.size.x * 16, data.size.y * 16) / 2
	preview.add_child(sprite)

	# Área de colisão para validação
	var area = Area2D.new()
	area.name = "CollisionArea"
	area.monitoring = true
	area.monitorable = false
	area.collision_layer = 4
	area.collision_mask = 1

	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(data.size.x * 32, data.size.y * 32)
	col.shape = rect
	area.add_child(col)

	preview.add_child(area)

	# Semi-transparente
	preview.modulate = Color(1, 1, 1, 0.7)

	return preview

func _create_placeholder_furniture(data: Dictionary) -> Texture2D:
	var colors = {
		"floor": Color(0.6, 0.4, 0.3),
		"wall": Color(0.5, 0.5, 0.6),
		"ceiling": Color(0.4, 0.4, 0.5)
	}
	var color = colors.get(data.layer, Color(0.5, 0.5, 0.5))

	var img = Image.create(data.size.x * 32, data.size.y * 32, false, Image.FORMAT_RGBA8)
	img.fill(color)

	# Desenha contorno
	for x in range(data.size.x * 32):
		for y in range(data.size.y * 32):
			if x < 2 or x >= data.size.x * 32 - 2 or y < 2 or y >= data.size.y * 32 - 2:
				img.set_pixel(x, y, color.lightened(0.3))

	return ImageTexture.create_from_image(img)

func _rotate_preview() -> void:
	if not preview_furniture:
		return

	rotation = (rotation + 90) % 360
	preview_furniture.rotation_degrees = rotation

	# Troca size se necessário (para retângulos)
	var data = FURNITURE_DATA[selected_furniture_id]
	if data.size.x != data.size.y and rotation % 180 == 90:
		# Atualiza collision area
		var area = preview_furniture.get_node("CollisionArea")
		if area:
			var col = area.get_node("CollisionShape2D")
			var rect = RectangleShape2D.new()
			rect.size = Vector2(data.size.y * 32, data.size.x * 32)
			col.shape = rect

func _confirm_placement() -> void:
	if not preview_furniture:
		return

	var grid_pos = WorldInit.world_to_grid(preview_furniture.global_position)
	if _can_place_at(selected_furniture_id, grid_pos, rotation):
		_place_furniture(selected_furniture_id, grid_pos, rotation)
		_cancel_placement()
	else:
		HUD.show_message("Não pode colocar aqui!")

func _cancel_placement() -> void:
	if preview_furniture:
		preview_furniture.queue_free()
		preview_furniture = null

	placement_mode = false
	selected_furniture_id = ""
	rotation = 0
	emit_signal("placement_mode_changed", false)

	HUD.hide_interaction_prompt()

## ==================== VALIDAÇÃO ====================
func _can_place_at(furniture_id: String, grid_pos: Vector2i, rot: int) -> bool:
	var data = FURNITURE_DATA[furniture_id]
	var size = data.size

	# Ajusta size pela rotação
	if rot % 180 == 90:
		size = Vector2i(size.y, size.x)

	# Verifica limites do mapa
	var world = get_tree().root.get_child(0)
	var farm_plots = world.get_node_or_null("FarmPlots")
	if farm_plots:
		# Verifica se está dentro da fazenda
		for x in range(size.x):
			for y in range(size.y):
				var check_pos = Vector2i(grid_pos.x + x, grid_pos.y + y)
				var plot = farm_plots.get_node_or_null("%d,%d" % [check_pos.x, check_pos.y])
				if not plot:
					return false

	# Verifica colisão com outros móveis
	for key in placed_furniture:
		var placed = placed_furniture[key]
		var p_pos = placed.position
		var p_data = FURNITURE_DATA.get(placed.id, {})
		var p_size = p_data.get("size", Vector2i(1, 1))
		var p_rot = placed.rotation

		if p_rot % 180 == 90:
			p_size = Vector2i(p_size.y, p_size.x)

		# AABB collision
		if _rects_overlap(grid_pos, size, p_pos, p_size):
			return false

	# Verifica se é parede/teto e tem suporte
	var layer = FURNITURE_DATA[furniture_id].layer
	if layer == "wall":
		# Precisa ter parede atrás
		if not _has_wall_behind(grid_pos, size):
			return false
	elif layer == "ceiling":
		# Precisa ter teto (sempre true em interiores)
		pass

	return true

func _rects_overlap(pos1: Vector2i, size1: Vector2i, pos2: Vector2i, size2: Vector2i) -> bool:
	return (pos1.x < pos2.x + size2.x and
			pos1.x + size1.x > pos2.x and
			pos1.y < pos2.y + size2.y and
			pos1.y + size1.y > pos2.y)

func _has_wall_behind(pos: Vector2i, size: Vector2i) -> bool:
	# Verifica se há parede atrás (simplificado)
	# Em implementação real, verificaria TileMap de paredes
	return true

## ==================== COLOCAÇÃO ====================
func _place_furniture(furniture_id: String, grid_pos: Vector2i, rot: int) -> void:
	var data = FURNITURE_DATA[furniture_id]
	var key = "%s_%d_%d" % [furniture_id, grid_pos.x, grid_pos.y]

	var furniture = Node2D.new()
	furniture.name = "Furniture_%s" % key
	furniture.global_position = WorldInit.grid_to_world(grid_pos)
	furniture.rotation_degrees = rot
	furniture.z_index = grid_pos.y * 10  # Sorting por Y

	var sprite = Sprite2D.new()
	if data.texture_path != "" and ResourceLoader.exists(data.texture_path):
		sprite.texture = load(data.texture_path)
	else:
		sprite.texture = _create_placeholder_furniture(data)
	sprite.offset = Vector2(data.size.x * 16, data.size.y * 16) / 2
	if rot % 180 == 90:
		sprite.offset = Vector2(data.size.y * 16, data.size.x * 16) / 2
	furniture.add_child(sprite)

	# Área de interação
	var area = Area2D.new()
	area.name = "InteractionArea"
	area.monitoring = true
	area.monitorable = true
	area.collision_layer = 4
	area.collision_mask = 1

	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	var w = data.size.x * 32
	var h = data.size.y * 32
	if rot % 180 == 90:
		w = data.size.y * 32
		h = data.size.x * 32
	rect.size = Vector2(w, h)
	col.shape = rect
	area.add_child(col)

	area.area_entered.connect(_on_furniture_entered.bind(key))
	area.area_exited.connect(_on_furniture_exited.bind(key))
	furniture.add_child(area)

	# Adiciona ao mundo
	var world = get_tree().root.get_child(0)
	var container = world.get_node_or_null("FurnitureContainer")
	if not container:
		container = Node2D.new()
		container.name = "FurnitureContainer"
		world.add_child(container)
	container.add_child(furniture)

	# Salva
	placed_furniture[key] = {
		"id": furniture_id,
		"position": grid_pos,
		"rotation": rot,
		"layer": FURNITURE_DATA[furniture_id].layer,
		"node": furniture
	}

	_save_furniture()
	emit_signal("furniture_placed", furniture_id, grid_pos, rot)

	# Partículas
	if ParticleManager:
		ParticleManager.spawn("harvest", furniture.global_position)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/furniture_place.ogg", furniture.global_position)

	HUD.show_message("%s colocado!" % FURNITURE_DATA[furniture_id].name)

func _on_furniture_entered(area: Area2D, key: String) -> void:
	if area.is_in_group("player"):
		HUD.show_interaction_prompt("E: Interagir | Botão direito: Rotacionar | Shift+E: Remover", area.global_position + Vector2(0, -50))

func _on_furniture_exited(area: Area2D, key: String) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact_with_furniture(key: String) -> void:
	var furniture = placed_furniture.get(key)
	if not furniture:
		return

	var node = furniture.node
	var data = FURNITURE_DATA.get(furniture.id, {})

	# Abre se for armazenamento
	if data.category in ["storage", "kitchen", "crafting"]:
		_open_furniture_storage(key)
	# Gira se rotacionável
	elif data.rotatable:
		_rotate_furniture(key)
	# Interação genérica
	else:
		HUD.show_message(data.name)

func _rotate_furniture(key: String) -> void:
	var furniture = placed_furniture.get(key)
	if not furniture:
		return

	var data = FURNITURE_DATA.get(furniture.id, {})
	if not data.rotatable:
		HUD.show_message("Este móvel não pode ser rotacionado.")
		return

	# Nova rotação
	var new_rot = (furniture.rotation + 90) % 360
	furniture.rotation = new_rot
	furniture.node.rotation_degrees = new_rot

	# Atualiza collision area
	var area = furniture.node.get_node("InteractionArea")
	if area:
		var col = area.get_node("CollisionShape2D")
		var rect = RectangleShape2D.new()
		var size = data.size
		if new_rot % 180 == 90:
			size = Vector2i(size.y, size.x)
		rect.size = Vector2(size.x * 32, size.y * 32)
		col.shape = rect

	_save_furniture()
	emit_signal("furniture_rotated", furniture.id, new_rot)
	HUD.show_message("Rotacionado!")

func _open_furniture_storage(key: String) -> void:
	# Abre UI de baú/geladeira/etc.
	if InventoryManager:
		InventoryManager.open_furniture_storage(key)

func remove_furniture(key: String) -> void:
	var furniture = placed_furniture.get(key)
	if not furniture:
		return

	# Devolve item ao inventário
	if InventoryManager.add_item(furniture.id, 1):
		furniture.node.queue_free()
		placed_furniture.erase(key)
		_save_furniture()
		emit_signal("furniture_removed", furniture.id)
		HUD.show_message("Móvel removido e devolvido ao inventário!")

		if ParticleManager:
			ParticleManager.spawn("cut", furniture.node.global_position)
	else:
		HUD.show_message("Inventário cheio!")

## ==================== PERSISTÊNCIA ====================
func _save_furniture() -> void:
	if GameManager:
		var data = {}
		for key in placed_furniture:
			var f = placed_furniture[key]
			data[key] = {
				"id": f.id,
				"position": {"x": f.position.x, "y": f.position.y},
				"rotation": f.rotation,
				"layer": f.layer
			}
		GameManager.set("placed_furniture", data)

func _load_furniture() -> void:
	if not GameManager:
		return

	var data = GameManager.get("placed_furniture", {})
	for key in data:
		var f = data[key]
		var grid_pos = Vector2i(f.position.x, f.position.y)
		_place_furniture(f.id, grid_pos, f.rotation)