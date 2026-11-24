class_name BuildingManager
extends Node

## Gerencia colocação, construção, upgrade e demolição de edifícios

@export var building_scene: PackedScene
@export var robin_shop_ui: PackedScene

## Edifícios colocados: {position_key: Building}
var buildings: Dictionary = {}

## Fila de construção: Array de {building, days_remaining}
var construction_queue: Array = []

## Edifício sendo movido (modo relocação)
var relocating_building: Building = null
var relocation_mode: bool = false

## Pré-visualização de colocação
var preview_building: Node2D = null
var preview_valid: bool = false
var preview_grid_pos: Vector2i = Vector2i(0, 0)

## ==================== SINAIS ====================
signal building_placed(building: Building)
signal building_removed(position: Vector2i)
signal building_relocated(old_pos: Vector2i, new_pos: Vector2i)
signal construction_started(building: Building)
signal construction_finished(building: Building)
signal cannot_place(reason: String)
signal gold_changed()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Conecta ao GameManager para avançar construção diariamente
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

	# Defer loading buildings until world is ready
	call_deferred("_load_saved_buildings_deferred")

func _load_saved_buildings_deferred() -> void:
	var container = get_tree().get_first_node_in_group("buildings_container")
	if not container:
		# Try again next frame
		call_deferred("_load_saved_buildings_deferred")
		return
	_load_saved_buildings()

func _load_saved_buildings() -> void:
	if not GameManager:
		return

	for building_data in GameManager.farm_buildings:
		var building_type = building_data.get("type", "")
		var grid_pos = Vector2i(building_data.get("position_x", 0), building_data.get("position_y", 0))
		var skin = building_data.get("skin", 0)

		var bd = DataLoader.get_building(building_type)
		if bd:
			_place_building_internal(bd, grid_pos, skin, building_data)

func _on_day_changed(day: int, season: int, year: int) -> void:
	# Avança construções em andamento
	var to_remove = []
	for i in range(construction_queue.size()):
		var item = construction_queue[i]
		item.building.advance_construction(1)
		item.days_remaining -= 1
		if item.days_remaining <= 0:
			item.building.complete_construction()
			emit_signal("construction_finished", item.building)
			to_remove.append(i)

	# Remove concluídos (iterate backwards)
	for i in to_remove.reversed():
		construction_queue.remove_at(i)

## ==================== COLOCAÇÃO ====================
## Inicia modo de colocação (chamado ao comprar na loja da Robin)
func start_placement(building_type: String, skin: int = 0) -> bool:
	var bd = DataLoader.get_building(building_type)
	if not bd:
		return false

	# Verifica se pode pagar
	if not bd.can_afford(GameManager.gold, GameManager.inventory):
		emit_signal("cannot_place", "Ouro ou materiais insuficientes")
		return false

	# Cria preview
	_create_preview(bd, skin)
	relocation_mode = false
	return true

func _create_preview(building_data: BuildingData, skin: int) -> void:
	if preview_building:
		preview_building.queue_free()

	preview_building = Node2D.new()
	preview_building.name = "BuildingPreview"

	var sprite = AnimatedSprite2D.new()
	sprite.name = "PreviewSprite"
	# Carrega textura do edifício
	var tex = load("res://resources/sprites/%s.png" % building_data.texture_path)
	if tex:
		sprite.texture = tex
	sprite.modulate = Color(1, 1, 1, 0.5)  # Semi-transparente
	preview_building.add_child(sprite)

	# Área de validação
	var area = Area2D.new()
	area.name = "ValidationArea"
	area.monitoring = true
	area.monitorable = false
	var size = building_data.size
	var rect = RectangleShape2D.new()
	rect.size = Vector2(size.x * 32, size.y * 32)
	var col = CollisionShape2D.new()
	col.shape = rect
	area.add_child(col)
	preview_building.add_child(area)

	get_tree().root.get_child(0).add_child(preview_building)

	# Input para colocação
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta: float) -> void:
	if preview_building:
		_update_preview_position()

	if relocating_building and relocation_mode:
		_update_relocation_preview()

func _update_preview_position() -> void:
	# Converte mouse para grid
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_canvas_transform()
	var world_pos = camera.affine_inverse() * mouse_pos

	var grid_pos = WorldInit.world_to_grid(world_pos)
	preview_grid_pos = grid_pos
	preview_building.global_position = WorldInit.grid_to_world(grid_pos)

	# Valida posição
	preview_valid = _can_place_at(preview_grid_pos, preview_building.get_node("ValidationArea"))

	# Atualiza cor do preview
	var sprite = preview_building.get_node("PreviewSprite")
	if preview_valid:
		sprite.modulate = Color(0, 1, 0, 0.5)  # Verde
	else:
		sprite.modulate = Color(1, 0, 0, 0.5)  # Vermelho

func _can_place_at(grid_pos: Vector2i, area: Area2D) -> bool:
	# Move área temporariamente para checar colisão
	var old_pos = area.global_position
	area.global_position = WorldInit.grid_to_world(grid_pos)

	# Verifica overlap com outros edifícios
	var overlapping = area.get_overlapping_areas()
	var valid = true

	for other in overlapping:
		if other.get_parent().is_in_group("buildings"):
			valid = false
			break

	# Verifica limites da fazenda
	var farm_plots = get_tree().get_first_node_in_group("farm_plots")
	if farm_plots:
		# Verifica se tiles estão dentro da fazenda
		var bd = DataLoader.get_building(preview_building.get_node("PreviewSprite").texture?.get_path().get_file().replace(".png", "").replace("Buildings/", ""))
		if bd:
			for x in range(bd.size.x):
				for y in range(bd.size.y):
					var check_pos = Vector2i(grid_pos.x + x, grid_pos.y + y)
					var key = "%d,%d" % [check_pos.x, check_pos.y]
					if not farm_plots.has_node(key):  # Fora da fazenda
						valid = false
						break

	area.global_position = old_pos
	return valid

## Confirma colocação (clique)
func _unhandled_input(event: InputEvent) -> void:
	if preview_building and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if preview_valid:
			_confirm_placement()
		else:
			_cancel_placement()

	if relocating_building and relocation_mode and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if preview_valid:
			_confirm_relocation()
		else:
			_cancel_relocation()

func _confirm_placement() -> void:
	var bd = DataLoader.get_building(preview_building.get_node("PreviewSprite").texture?.get_path().get_file().replace(".png", "").replace("Buildings/", ""))
	if not bd:
		return

	# Gasta recursos
	_spend_building_cost(bd)

	# Coloca edifício real
	var building = _place_building_internal(bd, preview_grid_pos, 0)
	building.building_data = bd

	# Adiciona à fila de construção se não for mágico
	if not bd.magical_construction:
		construction_queue.append({
			"building": building,
			"days_remaining": bd.build_days
		})
		emit_signal("construction_started", building)
	else:
		building.complete_construction()

	_cleanup_preview()
	emit_signal("building_placed", building)
	emit_signal("gold_changed")

func _spend_building_cost(building_data: BuildingData) -> void:
	GameManager.spend_gold(building_data.build_cost)
	for material in building_data.build_materials:
		var item_id = material.get("ItemId", "")
		var amount = material.get("Amount", 0)
		InventoryManager.remove_item(item_id, amount)

func _place_building_internal(building_data: BuildingData, grid_pos: Vector2i, skin: int, save_data: Dictionary = null) -> Building:
	var building = building_scene.instantiate()
	building.initialize(building_data, grid_pos, skin)
	building.name = building_data.internal_name + "_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	building.add_to_group("buildings")

	var container = get_tree().get_first_node_in_group("buildings_container")
	if not container:
		container = get_node_or_null("../Buildings")
	if container:
		container.add_child(building)

	buildings["%d,%d" % [grid_pos.x, grid_pos.y]] = building

	if save_data:
		building.load_save_data(save_data)

	return building

func _cleanup_preview() -> void:
	if preview_building:
		preview_building.queue_free()
		preview_building = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _cancel_placement() -> void:
	_cleanup_preview()
	emit_signal("cannot_place", "Colocação cancelada")

## ==================== RELOCAÇÃO ====================
func start_relocation(building: Building) -> void:
	relocating_building = building
	relocation_mode = true

	# Remove do grid antigo
	buildings.erase(building.position_key)

	# Cria preview do edifício existente
	_create_relocation_preview(building)

	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _create_relocation_preview(building: Building) -> void:
	preview_building = building.duplicate(true)
	preview_building.name = "RelocationPreview"
	var sprite = preview_building.get_node("AnimatedSprite2D")
	sprite.modulate = Color(1, 1, 1, 0.7)
	get_tree().root.get_child(0).add_child(preview_building)

	# Esconde original
	building.visible = false

func _update_relocation_preview() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_canvas_transform()
	var world_pos = camera.affine_inverse() * mouse_pos
	var grid_pos = WorldInit.world_to_grid(world_pos)
	preview_grid_pos = grid_pos
	preview_building.global_position = WorldInit.grid_to_world(grid_pos)

	# Valida
	var area = preview_building.get_node_or_null("InteractionArea")
	preview_valid = area and _can_place_at(grid_pos, area)

	var sprite = preview_building.get_node("AnimatedSprite2D")
	sprite.modulate = Color(0, 1, 0, 0.7) if preview_valid else Color(1, 0, 0, 0.7)

func _confirm_relocation() -> void:
	var old_key = relocating_building.position_key
	var old_pos = relocating_building.grid_position

	# Atualiza posição
	relocating_building.grid_position = preview_grid_pos
	relocating_building.position_key = "%d,%d" % [preview_grid_pos.x, preview_grid_pos.y]
	relocating_building.global_position = WorldInit.grid_to_world(preview_grid_pos)
	relocating_building.visible = true

	# Re-adiciona ao dicionário
	buildings[relocating_building.position_key] = relocating_building

	_cleanup_preview()
	relocation_mode = false
	relocating_building = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	emit_signal("building_relocated", old_pos, preview_grid_pos)

func _cancel_relocation() -> void:
	# Restaura posição original
	relocating_building.visible = true
	relocating_building.global_position = WorldInit.grid_to_world(relocating_building.grid_position)
	buildings[relocating_building.position_key] = relocating_building

	_cleanup_preview()
	relocation_mode = false
	relocating_building = null
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

## ==================== DEMOLIÇÃO ====================
func demolish_building(grid_pos: Vector2i) -> bool:
	var key = "%d,%d" % [grid_pos.x, grid_pos.y]
	var building = buildings.get(key)
	if not building:
		return false

	# Verifica se tem animais/feno
	if building.occupants.size() > 0:
		emit_signal("cannot_place", "Edifício tem animais dentro")
		return false
	if building.hay_stored > 0:
		emit_signal("cannot_place", "Edifício tem feno armazenado")
		return false

	# Remove
	building.queue_free()
	buildings.erase(key)
	emit_signal("building_removed", grid_pos)
	return true

## ==================== UPGRADE ====================
func upgrade_building(grid_pos: Vector2i, new_type: String) -> bool:
	var key = "%d,%d" % [grid_pos.x, grid_pos.y]
	var building = buildings.get(key)
	if not building or building.is_under_construction:
		return false

	var new_data = DataLoader.get_building(new_type)
	if not new_data:
		return false

	# Verifica custo
	if not new_data.can_afford(GameManager.gold, GameManager.inventory):
		return false

	_spend_building_cost(new_data)

	# Substitui edifício
	var skin = building.current_skin
	var occupants = building.occupants
	var chests = building.chests
	var hay = building.hay_stored

	building.queue_free()
	buildings.erase(key)

	var new_building = _place_building_internal(new_data, grid_pos, skin)
	new_building.occupants = occupants
	new_building.chests = chests
	new_building.hay_stored = hay

	if new_data.magical_construction:
		new_building.complete_construction()
	else:
		construction_queue.append({
			"building": new_building,
			"days_remaining": new_data.build_days
		})

	emit_signal("gold_changed")
	return true

## ==================== UTILIDADES ====================
func get_building_at(grid_pos: Vector2i) -> Building:
	return buildings.get("%d,%d" % [grid_pos.x, grid_pos.y])

func get_all_buildings() -> Array[Building]:
	var result = []
	for b in buildings.values():
		result.append(b)
	return result

func get_buildings_by_type(building_type: String) -> Array[Building]:
	var result = []
	for b in buildings.values():
		if b.building_type == building_type:
			result.append(b)
	return result

func get_total_hay_capacity() -> int:
	var total = 0
	for b in buildings.values():
		total += b.hay_capacity
	return total

func get_total_hay_stored() -> int:
	var total = 0
	for b in buildings.values():
		total += b.hay_stored
	return total

func can_afford_building(building_type: String) -> bool:
	var bd = DataLoader.get_building(building_type)
	return bd and bd.can_afford(GameManager.gold, GameManager.inventory)

func get_building_cost_text(building_type: String) -> String:
	var bd = DataLoader.get_building(building_type)
	return bd.get_cost_description() if bd else "Desconhecido"

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Array:
	var data = []
	for building in buildings.values():
		data.append(building.get_save_data())
	return data