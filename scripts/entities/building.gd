class_name Building
extends Node2D

## Edifício colocável na fazenda

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var construction_timer: Timer = $ConstructionTimer
@onready var progress_bar: ProgressBar = $ProgressBar

## Dados do edifício
var building_data: BuildingData
var building_type: String = ""
var grid_position: Vector2i = Vector2i(0, 0)
var position_key: String = ""

## Estado
var is_under_construction: bool = false
var days_remaining: int = 0
var construction_complete: bool = false
var current_skin: int = 0
var occupants: Array[Dictionary] = []  # Animais, máquinas, etc.
var chests: Array[Dictionary] = []  # Baús do edifício
var hay_stored: int = 0
var hay_capacity: int = 0

## Animações por skin
var skin_textures: Array[Texture2D] = []

## ==================== SINAIS ====================
signal construction_finished(building: Building)
signal building_interacted(building_type: String)
signal animal_entered(animal_data: Dictionary)
signal animal_exited(animal_data: Dictionary)
signal hay_changed(amount: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)
	construction_timer.timeout.connect(_on_construction_tick)
	progress_bar.visible = false

func initialize(building_data: BuildingData, grid_pos: Vector2i, skin: int = 0) -> void:
	self.building_data = building_data
	self.building_type = building_data.internal_name
	self.grid_position = grid_pos
	self.position_key = "%d,%d" % [grid_pos.x, grid_pos.y]
	self.current_skin = skin

	global_position = WorldInit.grid_to_world(grid_pos)

	_setup_visuals()
	_setup_collision()

	# Se é construção mágica, completa instantaneamente
	if building_data.magical_construction:
		complete_construction()
	else:
		start_construction()

func _setup_visuals() -> void:
	if not building_data.texture_path:
		return

	# Carrega textura do edifício
	# building_data.texture_path ex: "Buildings/Junimo Hut"
	var tex = load("res://resources/sprites/%s.png" % building_data.texture_path)
	if tex:
		sprite.texture = tex
		# Configura frames se for spritesheet
		# TODO: Parse SourceRect, Size, etc.

	# Aplica skin se houver
	if building_data.skins.size() > current_skin:
		# TODO: Aplicar skin
		pass

	# Offset de desenho
	var offset = building_data.draw_offset
	sprite.position = Vector2(offset.x, offset.y)

func _setup_collision() -> void:
	# Área de interação baseada no tamanho
	var size = building_data.size
	var w = size.x * 32
	var h = size.y * 32
	var rect = RectangleShape2D.new()
	rect.size = Vector2(w, h)
	interaction_area.get_node_or_null("CollisionShape2D")?.queue_free()
	var col = CollisionShape2D.new()
	col.shape = rect
	interaction_area.add_child(col)

	# Z-index baseado na posição Y (para sorting correto)
	z_index = grid_position.y * 10

## ==================== CONSTRUÇÃO ====================
func start_construction() -> void:
	is_under_construction = true
	days_remaining = building_data.build_days
	construction_complete = false

	# Mostra sprite de construção (andaime)
	_show_construction_sprite()

	progress_bar.visible = true
	progress_bar.max_value = building_data.build_days
	progress_bar.value = 0

	# Timer diário (simulado - real usa GameManager day_changed)
	# Aqui apenas visual, a lógica real está no BuildingManager
	print("Building: Construção iniciada - %d dias" % days_remaining)

func _on_construction_tick() -> void:
	# Chamado diariamente pelo BuildingManager
	advance_construction(1)

func advance_construction(days: int) -> void:
	if not is_under_construction or construction_complete:
		return

	days_remaining -= days
	progress_bar.value = building_data.build_days - days_remaining

	if days_remaining <= 0:
		complete_construction()

func complete_construction() -> void:
	is_under_construction = false
	construction_complete = true
	progress_bar.visible = false

	# Mostra sprite final
	_show_final_sprite()

	# Inicializa baús
	_initialize_chests()

	# Inicializa capacidade de feno
	hay_capacity = building_data.hay_capacity

	emit_signal("construction_finished", self)
	print("Building: %s construído em %s" % [building_type, position_key])

func _show_construction_sprite() -> void:
	# TODO: Sprite de andaime
	sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)

func _show_final_sprite() -> void:
	sprite.modulate = Color.WHITE

## ==================== BAÚS ====================
func _initialize_chests() -> void:
	for chest_data in building_data.chests:
		var chest = {
			"id": chest_data.get("Id", ""),
			"type": chest_data.get("Type", 0),
			"items": {},
			"capacity": 36
		}
		chests.append(chest)

func get_chest(chest_id: String) -> Dictionary:
	for chest in chests:
		if chest.id == chest_id:
			return chest
	return null

func add_item_to_chest(chest_id: String, item_id: String, amount: int) -> bool:
	var chest = get_chest(chest_id)
	if not chest:
		return false

	var current = chest.items.get(item_id, 0)
	var max_stack = 999  # TODO: DataLoader.get_item(item_id).max_stack
	if current + amount > max_stack:
		amount = max_stack - current
	if amount <= 0:
		return false

	chest.items[item_id] = current + amount
	return true

func remove_item_from_chest(chest_id: String, item_id: String, amount: int) -> bool:
	var chest = get_chest(chest_id)
	if not chest:
		return false

	var current = chest.items.get(item_id, 0)
	if current < amount:
		return false

	chest.items[item_id] = current - amount
	if chest.items[item_id] <= 0:
		chest.items.erase(item_id)
	return true

## ==================== FENO ====================
func add_hay(amount: int) -> int:
	var space = hay_capacity - hay_stored
	var added = min(amount, space)
	hay_stored += added
	emit_signal("hay_changed", hay_stored)
	return added

func remove_hay(amount: int) -> int:
	var removed = min(amount, hay_stored)
	hay_stored -= removed
	emit_signal("hay_changed", hay_stored)
	return removed

func get_hay_space() -> int:
	return hay_capacity - hay_stored

## ==================== OCUPANTES (ANIMAIS) ====================
func can_add_occupant(occupant_type: String) -> bool:
	if building_data.max_occupants > 0 and occupants.size() >= building_data.max_occupants:
		return false
	if building_data.valid_occupant_types.size() > 0:
		return occupant_type in building_data.valid_occupant_types
	return true

func add_occupant(occupant_data: Dictionary) -> bool:
	if not can_add_occupant(occupant_data.get("type", "")):
		return false
	occupants.append(occupant_data)
	emit_signal("animal_entered", occupant_data)
	return true

func remove_occupant(occupant_id: String) -> bool:
	for i in range(occupants.size()):
		if occupants[i].get("id") == occupant_id:
			var data = occupants[i]
			occupants.remove_at(i)
			emit_signal("animal_exited", data)
			return true
	return false

## ==================== INTERAÇÃO ====================
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		# Mostra prompt se for edifício interativo (baú, etc.)
		if chests.size() > 0 or hay_capacity > 0:
			HUD.show_interaction_prompt("E: Entrar", global_position + Vector2(0, -50))

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	emit_signal("building_interacted", building_type)
	# Abre menu do edifício (baú, feno, animais, etc.)
	_open_building_menu()

func _open_building_menu() -> void:
	# TODO: Implementar UI específica por tipo de edifício
	print("Building: Abrindo menu de %s" % building_type)

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"type": building_type,
		"grid_position": grid_position,
		"skin": current_skin,
		"is_under_construction": is_under_construction,
		"days_remaining": days_remaining,
		"construction_complete": construction_complete,
		"occupants": occupants,
		"chests": chests,
		"hay_stored": hay_stored,
		"hay_capacity": hay_capacity
	}

func load_save_data(data: Dictionary) -> void:
	building_type = data.get("type", "")
	grid_position = data.get("grid_position", Vector2i(0, 0))
	position_key = "%d,%d" % [grid_position.x, grid_position.y]
	current_skin = data.get("skin", 0)
	is_under_construction = data.get("is_under_construction", false)
	days_remaining = data.get("days_remaining", 0)
	construction_complete = data.get("construction_complete", true)
	occupants = data.get("occupants", [])
	chests = data.get("chests", [])
	hay_stored = data.get("hay_stored", 0)
	hay_capacity = data.get("hay_capacity", 0)

	building_data = DataLoader.get_building(building_type)
	global_position = WorldInit.grid_to_world(grid_position)

	_setup_visuals()
	_setup_collision()

	if is_under_construction:
		start_construction()
		# Avança construção pelos dias já passados
		var days_done = building_data.build_days - days_remaining
		if days_done > 0:
			advance_construction(days_done)
	else:
		complete_construction()