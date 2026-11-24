class_name FarmPlot
extends Node2D

## Tile individual arável na fazenda

@onready var sprite: Sprite2D = $Sprite2D
@onready var crop_container: Node2D = $CropContainer
@onready var interaction_area: Area2D = $InteractionArea
@onready var watered_overlay: Sprite2D = $WateredOverlay
@onready var fertilizer_indicator: Sprite2D = $FertilizerIndicator

## Estado
var grid_position: Vector2i = Vector2i(0, 0)
var position_key: String = ""  # "x,y"
var is_tilled: bool = false
var is_watered: bool = false
var current_crop: Crop = null
var fertilizer_type: int = 0  # 0=none, 1=basic, 2=quality, 3=deluxe
var retaining_soil_type: int = 0
var speed_gro_type: int = 0
var hoe_dirt_texture: Texture2D
var dry_dirt_texture: Texture2D
var wet_dirt_texture: Texture2D

## ==================== SINAIS ====================
signal plot_tilled(position: Vector2i)
signal plot_watered(position: Vector2i)
signal crop_planted(crop: Crop)
signal crop_harvested(item_id: String, amount: int, quality: int)
signal crop_died()
signal tool_hit(tool: String, power: float)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)

	# Cria position_key
	position_key = "%d,%d" % [grid_position.x, grid_position.y]

	# Carrega texturas (placeholders por enquanto)
	_setup_textures()

	# Verifica se já tem cultivo salvo
	_check_existing_crop()

func _setup_textures() -> void:
	# TODO: Carregar texturas reais do TileSheets
	# Por enquanto usa cores
	var dirt_tex = Texture2D.new()
	# sprite.texture = dirt_tex
	pass

func _check_existing_crop() -> void:
	if GameManager and GameManager.farm_crops.has(position_key):
		var data = GameManager.farm_crops[position_key]
		_restore_crop(data)

## ==================== ARADO (HOE) ====================
func till() -> void:
	if is_tilled:
		return

	is_tilled = true
	is_watered = false
	fertilizer_type = 0
	retaining_soil_type = 0
	speed_gro_type = 0

	_update_visuals()
	emit_signal("plot_tilled", grid_position)

	# Registra no GameManager como solo arado vazio
	if GameManager:
		GameManager.farm_crops[position_key] = {
			"crop_id": "",
			"growth_day": 0,
			"watered": false,
			"fertilizer": 0,
			"retaining": 0,
			"speed_gro": 0,
			"phase": -1,
			"tilled": true
		}

func until() -> void:
	# Enxada em solo arado remove cultivo e desarada
	if current_crop:
		current_crop.queue_free()
		current_crop = null

	is_tilled = false
	is_watered = false
	fertilizer_type = 0
	retaining_soil_type = 0
	speed_gro_type = 0

	_update_visuals()

	if GameManager:
		GameManager.farm_crops.erase(position_key)

## ==================== PLANTIO ====================
func plant_crop(crop_data: CropData, fertilizer: int = 0, retaining: int = 0, speed_gro: int = 0) -> bool:
	if not is_tilled or current_crop:
		return false

	# Verifica estação
	var current_season = GameManager.current_season if GameManager else 0
	if not crop_data.can_plant_in_season(current_season):
		# Mostra mensagem "Não pode plantar nesta estação"
		return false

	# Cria instância do cultivo
	var crop_scene = preload("res://scenes/entities/crop.tscn")
	current_crop = crop_scene.instantiate()
	current_crop.crop_data = crop_data
	current_crop.plant(crop_data, position_key, fertilizer, retaining, speed_gro)
	crop_container.add_child(current_crop)

	# Conecta sinais
	current_crop.crop_harvested.connect(_on_crop_harvested)
	current_crop.crop_died.connect(_on_crop_died)
	current_crop.crop_fully_grown.connect(_on_crop_fully_grown)

	# Atualiza estado do plot
	fertilizer_type = fertilizer
	retaining_soil_type = retaining
	speed_gro_type = speed_gro
	is_watered = false

	_update_visuals()
	emit_signal("crop_planted", current_crop)
	return true

func _restore_crop(data: Dictionary) -> void:
	var crop_id = data.get("crop_id", "")
	if crop_id == "":
		# Solo apenas arado
		is_tilled = data.get("tilled", false)
		is_watered = data.get("watered", false)
		fertilizer_type = data.get("fertilizer", 0)
		retaining_soil_type = data.get("retaining", 0)
		speed_gro_type = data.get("speed_gro", 0)
		_update_visuals()
		return

	var crop_data = DataLoader.get_crop(crop_id.to_int())
	if not crop_data:
		return

	var crop_scene = preload("res://scenes/entities/crop.tscn")
	current_crop = crop_scene.instantiate()
	current_crop.load_save_data(data)
	crop_container.add_child(current_crop)

	current_crop.crop_harvested.connect(_on_crop_harvested)
	current_crop.crop_died.connect(_on_crop_died)
	current_crop.crop_fully_grown.connect(_on_crop_fully_grown)

	fertilizer_type = data.get("fertilizer", 0)
	retaining_soil_type = data.get("retaining", 0)
	speed_gro_type = data.get("speed_gro", 0)
	is_watered = data.get("watered", false)

	_update_visuals()

## ==================== REGA ====================
func water() -> void:
	if not is_tilled or is_watered:
		return

	is_watered = true
	_update_visuals()
	emit_signal("plot_watered", grid_position)

	if current_crop:
		current_crop.water()

	if GameManager:
		var crop_data = GameManager.farm_crops.get(position_key, {})
		crop_data["watered"] = true
		GameManager.farm_crops[position_key] = crop_data

## ==================== FERRAMENTAS ====================
func on_tool_hit(tool: String, power: float) -> void:
	emit_signal("tool_hit", tool, power)

	match tool:
		"Hoe":
			if not is_tilled:
				till()
			elif current_crop and current_crop.is_dead:
				# Remove cultivo morto
				current_crop.queue_free()
				current_crop = null
				until()
			elif not current_crop:
				# Solo arado vazio -> desarada
				until()
		"WateringCan":
			if is_tilled and not is_watered:
				water()
		"Pickaxe", "Axe":
			# Destrói cultivo e desarada
			if current_crop:
				current_crop.queue_free()
				current_crop = null
			until()
		"Scythe":
			if current_crop and current_crop.is_fully_grown:
				current_crop.harvest()
		_:
			pass

	# Repassa para cultivo se existir
	if current_crop:
		current_crop.on_tool_hit(tool, power)

## ==================== CICLO DIÁRIO ====================
## Chamado pelo GameManager na virada do dia
func new_day() -> void:
	var was_watered = is_watered
	is_watered = false

	# Solo retenção de água mantém umidade
	if retaining_soil_type > 0 and was_watered:
		var chance = [0.0, 0.33, 0.66, 1.0][retaining_soil_type]
		if randf() < chance:
			is_watered = true

	_update_visuals()

	# Cresce cultivo
	if current_crop:
		current_crop.grow_day(is_watered)

	# Atualiza GameManager
	if GameManager:
		var data = GameManager.farm_crops.get(position_key, {})
		data["watered"] = is_watered
		GameManager.farm_crops[position_key] = data

## ==================== CALLBACKS CULTIVO ====================
func _on_crop_harvested(item_id: String, amount: int, quality: int) -> void:
	emit_signal("crop_harvested", item_id, amount, quality)

	# Verifica se cultivo rebrotou
	if not current_crop or current_crop.is_dead:
		current_crop = null
		fertilizer_type = 0
		retaining_soil_type = 0
		speed_gro_type = 0
		_update_visuals()

func _on_crop_died() -> void:
	emit_signal("crop_died")
	current_crop = null
	fertilizer_type = 0
	retaining_soil_type = 0
	speed_gro_type = 0
	_update_visuals()

func _on_crop_fully_grown() -> void:
	# Cultivo pronto para colheita
	pass

## ==================== VISUAL ====================
func _update_visuals() -> void:
	# Sprite do solo
	if is_tilled:
		if is_watered:
			sprite.texture = wet_dirt_texture
			sprite.modulate = Color.WHITE
		else:
			sprite.texture = dry_dirt_texture
			sprite.modulate = Color.WHITE
	else:
		sprite.texture = null  # Grama normal (gerenciado pelo TileMap)

	# Overlay de água
	watered_overlay.visible = is_tilled and is_watered

	# Indicador de fertilizante
	if fertilizer_type > 0:
		fertilizer_indicator.visible = true
		# Muda cor/sprite baseado no tipo
	else:
		fertilizer_indicator.visible = false

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		# Highlight do plot
		sprite.modulate = Color.YELLOW

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		sprite.modulate = Color.WHITE

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	var data = {
		"grid_position": grid_position,
		"is_tilled": is_tilled,
		"is_watered": is_watered,
		"fertilizer_type": fertilizer_type,
		"retaining_soil_type": retaining_soil_type,
		"speed_gro_type": speed_gro_type
	}

	if current_crop:
		data["crop"] = current_crop.get_save_data()

	return data

func load_save_data(data: Dictionary) -> void:
	grid_position = data.get("grid_position", Vector2i(0, 0))
	position_key = "%d,%d" % [grid_position.x, grid_position.y]
	is_tilled = data.get("is_tilled", false)
	is_watered = data.get("is_watered", false)
	fertilizer_type = data.get("fertilizer_type", 0)
	retaining_soil_type = data.get("retaining_soil_type", 0)
	speed_gro_type = data.get("speed_gro_type", 0)

	if data.has("crop"):
		var crop_data = data["crop"]
		# Será restaurado via _restore_crop no _ready
		GameManager.farm_crops[position_key] = crop_data

	_update_visuals()