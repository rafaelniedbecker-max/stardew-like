class_name Player
extends CharacterBody2D

## Player controller com movimento, ferramentas, interação

@export var move_speed: float = 200.0
@export var run_speed_multiplier: float = 1.5
@export var interaction_range: float = 48.0  # 1.5 tiles
@export var tool_range: float = 32.0  # 1 tile

## Componentes
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var tool_area: Area2D = $ToolArea

## Estado
var velocity = Vector2.ZERO
var facing_direction: int = 2  # 0=up, 1=right, 2=down, 3=left
var is_using_tool: bool = false
var tool_use_timer: float = 0.0
var current_tool: String = ""
var tool_power: float = 0.0  # Para ferramentas carregáveis (enxada, regador)

## Animações por direção
const ANIM_IDLE = ["idle_up", "idle_right", "idle_down", "idle_left"]
const ANIM_WALK = ["walk_up", "walk_right", "walk_down", "walk_left"]
const ANIM_TOOL = ["tool_up", "tool_right", "tool_down", "tool_left"]
const ANIM_TOOL_CHARGE = ["tool_charge_up", "tool_charge_right", "tool_charge_down", "tool_charge_left"]
const ANIM_SWIM = ["swim_up", "swim_right", "swim_down", "swim_left"]

## ==================== SINAIS ====================
signal tool_used(tool_name: String, position: Vector2, power: float)
signal item_interacted(item_id: String)
signal npc_interacted(npc_name: String)
signal door_interacted(door_name: String)
signal sleep_triggered()
signal inventory_opened()
signal menu_opened(menu_name: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	add_to_group("player")
	_setup_areas()
	_load_save_state()

func _setup_areas() -> void:
	# Área de interação (E/Space)
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	var interaction_shape = CircleShape2D.new()
	interaction_shape.radius = interaction_range
	var old_interaction_collision = interaction_area.get_node_or_null("CollisionShape2D")
	if old_interaction_collision != null:
		old_interaction_collision.queue_free()
	var col = CollisionShape2D.new()
	col.shape = interaction_shape
	interaction_area.add_child(col)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)

	# Área de ferramenta (clique)
	tool_area.monitorable = true
	tool_area.monitoring = false  # Ativa só durante uso
	var tool_shape = CircleShape2D.new()
	tool_shape.radius = tool_range
	var old_tool_collision = tool_area.get_node_or_null("CollisionShape2D")
	if old_tool_collision != null:
		old_tool_collision.queue_free()
	var col2 = CollisionShape2D.new()
	col2.shape = tool_shape
	tool_area.add_child(col2)
	tool_area.area_entered.connect(_on_tool_area_entered)

## ==================== INPUT & MOVIMENTO ====================
func _physics_process(delta: float) -> void:
	if is_using_tool:
		_handle_tool_use(delta)
		return

	_handle_movement(delta)
	_handle_input()

	move_and_slide()

func _handle_movement(delta: float) -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed = move_speed

	# Corrida com Shift
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= run_speed_multiplier

	if input_dir != Vector2.ZERO:
		velocity = input_dir * speed
		_update_facing_direction(input_dir)
		_play_animation("walk")
	else:
		velocity = Vector2.ZERO
		_play_animation("idle")

func _update_facing_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing_direction = 1 if dir.x > 0 else 3
	else:
		facing_direction = 2 if dir.y > 0 else 0

func _handle_input() -> void:
	# Interação (E/Space)
	if Input.is_action_just_pressed("interact"):
		_try_interact()

	# Uso de ferramenta (clique esquerdo)
	if Input.is_action_just_pressed("tool_use"):
		_start_tool_use()

	# Ferramenta alternativa (clique direito)
	if Input.is_action_just_pressed("tool_alt"):
		_use_tool_alt()

	# Inventário (Tab/I)
	if Input.is_action_just_pressed("inventory"):
		emit_signal("inventory_opened")

	# Pausa (Escape)
	if Input.is_action_just_pressed("pause"):
		emit_signal("menu_opened", "pause")

	# Camera Ride (C)
	if Input.is_action_just_pressed("camera_ride"):
		if CameraRide:
			CameraRide.open_control_ui()

	# Hotbar 1-8
	for i in range(8):
		if Input.is_action_just_pressed("hotbar_%d" % (i + 1)):
			GameManager.selected_hotbar_slot = i
			_update_equipped_tool()

func _try_interact() -> void:
	# Verifica áreas sobrepostas na interaction_area
	var areas = interaction_area.get_overlapping_areas()
	var bodies = interaction_area.get_overlapping_bodies()

	# Prioridade: NPCs > Farm Plots > Objetos > Portas > Itens no chão
	for area in areas:
		if area.is_in_group("npc"):
			emit_signal("npc_interacted", area.get_parent().name)
			return

		# Interação com farm plots (plantio/colheita)
		var parent = area.get_parent()
		if parent is FarmPlot:
			_interact_with_farm_plot(parent)
			return

		if area.is_in_group("door"):
			emit_signal("door_interacted", area.name)
			return
		if area.is_in_group("item"):
			emit_signal("item_interacted", area.get_parent().get("item_id", ""))
			return
		if area.is_in_group("bed"):
			emit_signal("sleep_triggered")
			return

	for body in bodies:
		if body.is_in_group("npc"):
			emit_signal("npc_interacted", body.name)
			return

func _interact_with_farm_plot(plot: FarmPlot) -> void:
	"""Interage com farm plot: plantar semente ou colher cultivo."""
	# Se já tem cultivo pronto, colhe
	if plot.current_crop and plot.current_crop.is_fully_grown:
		plot.current_crop.harvest()
		return

	# Se não tem cultivo e está arado, tenta plantar semente do hotbar
	if not plot.current_crop and plot.is_tilled:
		var selected_item = InventoryManager.get_selected_item()
		if selected_item != "":
			# Verifica se é semente
			var item_data = DataLoader.get_item(selected_item)
			if item_data and item_data.item_type == "Seed":
				# Extrai crop_id da semente (ex: "(O)472" -> 472)
				var crop_id = selected_item.replace("(O)", "").to_int()
				var crop_data = DataLoader.get_crop(crop_id)
				if crop_data:
					# Consome semente
					if InventoryManager.remove_item(selected_item, 1):
						plot.plant_crop(crop_data)
						return

	# Se tem cultivo mas não está pronto, mostra status
	if plot.current_crop:
		var days_left = plot.current_crop.get_days_until_harvest()
		HUD.show_message("Cultivo crescendo... %d dias restantes" % days_left)

## ==================== FERRAMENTAS ====================
func _update_equipped_tool() -> void:
	var item_id = InventoryManager.get_selected_item()
	if item_id != "":
		var item = DataLoader.get_item(item_id)
		if item and item.is_tool():
			current_tool = item_id
			# Extrai nome da ferramenta do ID (ex: "(T)0" -> "Hoe")
			var tool_names = ["Pickaxe", "Axe", "Hoe", "WateringCan", "Scythe", "FishingRod", "Pan", "Shears", "MilkPail"]
			var tool_index = item_id.replace("(T)", "").to_int()
			if tool_index < tool_names.size():
				current_tool = tool_names[tool_index]
			return
	current_tool = ""

func _start_tool_use() -> void:
	if current_tool == "":
		return

	# Verifica energia
	var energy_cost = _get_tool_energy_cost(current_tool)
	if GameManager.energy < energy_cost:
		# Mostra aviso "Não tem energia"
		return

	is_using_tool = true
	tool_use_timer = 0.0
	tool_power = 0.0
	tool_area.monitoring = true
	velocity = Vector2.ZERO

	# Ferramentas carregáveis
	if current_tool in ["Hoe", "WateringCan", "Pickaxe", "Axe"]:
		_play_animation("tool_charge")
	else:
		_play_animation("tool")
		_execute_tool_use(1.0)

func _handle_tool_use(delta: float) -> void:
	tool_use_timer += delta

	# Carrega ferramenta (segurar botão)
	if current_tool in ["Hoe", "WateringCan", "Pickaxe", "Axe"]:
		if Input.is_action_pressed("tool_use"):
			tool_power = min(1.0, tool_use_timer / 1.0)  # 1 seg para carga max
			_play_animation("tool_charge")
		else:
			# Soltou botão - executa
			_execute_tool_use(tool_power)
			_finish_tool_use()
	else:
		# Ferramentas instantâneas
		if tool_use_timer > 0.3:  # Tempo de animação
			_finish_tool_use()

func _execute_tool_use(power: float) -> void:
	var pos = global_position + _get_tool_offset()
	emit_signal("tool_used", current_tool, pos, power)

	# Consome energia
	var energy_cost = _get_tool_energy_cost(current_tool) * max(0.5, power)
	GameManager.consume_energy(energy_cost)

	# Efeito visual/sonoro
	_play_tool_effect(current_tool, pos, power)

func _finish_tool_use() -> void:
	is_using_tool = false
	tool_use_timer = 0.0
	tool_power = 0.0
	tool_area.monitoring = false
	_play_animation("idle")

func _use_tool_alt() -> void:
	# Ação alternativa da ferramenta (ex: regador vazio -> beber)
	if current_tool == "WateringCan":
		# Verifica se vazio, bebe água
		pass

func _get_tool_offset() -> Vector2:
	var offsets = {
		0: Vector2(0, -16),   # Up
		1: Vector2(16, 0),    # Right
		2: Vector2(0, 16),    # Down
		3: Vector2(-16, 0)    # Left
	}
	return offsets.get(facing_direction, Vector2.ZERO)

func _get_tool_energy_cost(tool: String) -> float:
	var costs = {
		"Hoe": 2.0,
		"WateringCan": 2.0,
		"Pickaxe": 2.0,
		"Axe": 2.0,
		"Scythe": 1.0,
		"FishingRod": 3.0,
		"Shears": 1.0,
		"MilkPail": 1.0,
		"Pan": 0.0
	}
	return costs.get(tool, 2.0)

func _play_tool_effect(tool: String, pos: Vector2, power: float) -> void:
	# Partículas baseadas na ferramenta
	if ParticleManager:
		match tool:
			"Hoe":
				ParticleManager.spawn_dirt_particles(pos, power)
			"WateringCan":
				ParticleManager.spawn_water_particles(pos, power)
			"Pickaxe":
				ParticleManager.spawn_rock_particles(pos, power)
			"Axe":
				ParticleManager.spawn_wood_particles(pos, power)
			"Scythe":
				ParticleManager.spawn_grass_particles(pos, power)

	# Som
	if AudioManager:
		var sound_map = {
			"Hoe": "hoe_dirt",
			"WateringCan": "water_splash",
			"Pickaxe": "pickaxe_stone",
			"Axe": "axe_chop",
			"Scythe": "scythe_cut"
		}
		var sound = sound_map.get(tool, "tool_use")
		AudioManager.play_sfx("res://assets/sfx/%s.ogg" % sound)

	# Screen shake leve para ferramentas pesadas
	if tool in ["Pickaxe", "Axe"] and power > 0.5:
		if CameraEffects:
			CameraEffects.shake(2.0 * power, 0.2)

## ==================== ANIMAÇÕES ====================
func _play_animation(base_name: String) -> void:
	var anim_map = {
		"idle": ANIM_IDLE,
		"walk": ANIM_WALK,
		"tool": ANIM_TOOL,
		"tool_charge": ANIM_TOOL_CHARGE
	}

	var anims = anim_map.get(base_name, ANIM_IDLE)
	var anim_name = anims[facing_direction]

	if animated_sprite and animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	else:
		# Fallback para animação padrão
		var fallback = "idle_down"
		if animated_sprite and animated_sprite.sprite_frames.has_animation(fallback):
			animated_sprite.play(fallback)

## ==================== ÁREAS ====================
var _interactable_objects: Array[Node] = []

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		_interactable_objects.append(area.get_parent())

func _on_interaction_area_exited(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		_interactable_objects.erase(area.get_parent())

func _on_tool_area_entered(area: Area2D) -> void:
	# Atingido pela ferramenta
	var parent = area.get_parent()

	# Farm plots (enxada, regador)
	if parent is FarmPlot:
		parent.on_tool_hit(current_tool, tool_power)
		return

	if area.is_in_group("crop"):
		var crop = parent
		if crop.has_method("on_tool_hit"):
			crop.on_tool_hit(current_tool, tool_power)
	elif area.is_in_group("terrain"):
		var terrain = parent
		if terrain.has_method("on_tool_hit"):
			terrain.on_tool_hit(current_tool, tool_power)
	elif area.is_in_group("object"):
		var obj = parent
		if obj.has_method("on_tool_hit"):
			obj.on_tool_hit(current_tool, tool_power)

## ==================== SAVE/LOAD ====================
func get_save_state() -> Dictionary:
	return {
		"position": global_position,
		"direction": facing_direction,
		"animation": animated_sprite.animation if animated_sprite else "idle_down"
	}

func load_save_state(data: Dictionary) -> void:
	if data.has("position"):
		global_position = data["position"]
	if data.has("direction"):
		facing_direction = data["direction"]
		_play_animation("idle")

func _load_save_state() -> void:
	# Será chamado pelo SaveManager após load
	pass

## ==================== UTILIDADES ====================
func get_facing_vector() -> Vector2:
	var dirs = [
		Vector2(0, -1),   # Up
		Vector2(1, 0),    # Right
		Vector2(0, 1),    # Down
		Vector2(-1, 0)    # Left
	]
	return dirs[facing_direction]

func get_interaction_target() -> Node:
	# Retorna o objeto mais próximo na frente do player
	var best = null
	var best_dist = interaction_range

	for obj in _interactable_objects:
		var dist = global_position.distance_to(obj.global_position)
		if dist < best_dist:
			best_dist = dist
			best = obj

	return best