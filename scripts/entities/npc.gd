class_name NPC
extends CharacterBody2D

## NPC com agenda, diálogos, presentes, rotas

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var portrait: TextureRect = $Portrait
@onready var dialogue_bubble: Control = $DialogueBubble
@onready var dialogue_label: Label = $DialogueBubble/Label

## Dados do NPC
var npc_data: NPCData
var npc_name: String = ""

## Estado
var current_schedule: String = ""
var current_route: Array[Vector2] = []
var route_index: int = 0
var is_moving: bool = false
var move_speed: float = 80.0
var target_position: Vector2 = Vector2.ZERO
var wait_timer: float = 0.0
var current_dialogue: String = ""
var dialogue_timer: float = 0.0
var friendship: int = 0
var talked_today: bool = false
var gift_given_today: bool = false
var gift_given_this_week: int = 0
var last_gift_id: String = ""
var last_gift_reaction: String = ""

## Animações
const ANIM_IDLE = ["idle_up", "idle_right", "idle_down", "idle_left"]
const ANIM_WALK = ["walk_up", "walk_right", "walk_down", "walk_left"]
var facing_direction: int = 2

## ==================== SINAIS ====================
signal npc_interacted(npc_name: String)
signal dialogue_started(npc_name: String, dialogue: String)
signal dialogue_ended(npc_name: String)
signal gift_received(npc_name: String, item_id: String, reaction: String)
signal friendship_changed(npc_name: String, new_friendship: int)
signal schedule_changed(npc_name: String, new_schedule: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	add_to_group("npc")
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	# Esconde bolha de diálogo
	dialogue_bubble.visible = false

func initialize(npc_data: NPCData) -> void:
	self.npc_data = npc_data
	self.npc_name = npc_data.internal_name
	self.friendship = GameManager.friendships.get(npc_name, 0) if GameManager else 0

	# Carrega textura/retrato
	_setup_visuals()

	# Inicia agenda
	_update_schedule()

func _setup_visuals() -> void:
	if npc_data.texture_path != "":
		# Carrega spritesheet do NPC
		pass
	if npc_data.portrait_path != "":
		# portrait.texture = load(npc_data.portrait_path)
		pass

## ==================== AGENDA & MOVIMENTO ====================
func _physics_process(delta: float) -> void:
	if is_moving:
		_move_along_route(delta)
	else:
		_handle_wait(delta)

	_update_animation()

func _update_schedule() -> void:
	var weekday = GameManager.current_weekday if GameManager else 0
	var season = GameManager.current_season if GameManager else 0
	var day = GameManager.current_day if GameManager else 1

	# Obtém agenda para hoje
	current_schedule = npc_data.get_schedule_for_day(weekday)

	# Parse da agenda (formato Stardew: "Location X Y direction ...")
	_parse_schedule(current_schedule)

	emit_signal("schedule_changed", npc_name, current_schedule)

func _parse_schedule(schedule_str: String) -> void:
	current_route.clear()
	route_index = 0

	if schedule_str == "":
		return

	# Formato simplificado: "Town 10 5 2 1200 1400" (local x y direção hora_inicio hora_fim)
	# Implementação completa parser depois
	var parts = schedule_str.split(" ")
	# Por enquanto, fica parado no ponto inicial
	var home_pos = _get_home_position()
	current_route.append(home_pos)
	target_position = home_pos
	global_position = home_pos

func _get_home_position() -> Vector2:
	# Posição baseada na home_region
	match npc_data.home_region:
		"Town": return Vector2(300, 400)
		"Farm": return Vector2(100, 100)
		"Desert": return Vector2(500, 500)
		_: return Vector2(300, 400)

func _move_along_route(delta: float) -> void:
	if route_index >= current_route.size():
		is_moving = false
		return

	target_position = current_route[route_index]
	var direction = (target_position - global_position).normalized()
	var distance = global_position.distance_to(target_position)

	if distance < 5.0:
		route_index += 1
		if route_index >= current_route.size():
			is_moving = false
			_start_wait()
		return

	velocity = direction * move_speed
	move_and_slide()

	# Atualiza facing direction
	if abs(direction.x) > abs(direction.y):
		facing_direction = 1 if direction.x > 0 else 3
	else:
		facing_direction = 2 if direction.y > 0 else 0

func _handle_wait(delta: float) -> void:
	wait_timer -= delta
	if wait_timer <= 0:
		# Próximo ponto da rota ou fim
		if route_index < current_route.size():
			is_moving = true
		else:
			# Fim da rota - fica idle
			pass

func _start_wait(duration: float = 5.0) -> void:
	wait_timer = duration
	is_moving = false
	velocity = Vector2.ZERO

func _update_animation() -> void:
	if not animated_sprite:
		return

	var anim_name = ""
	if velocity.length() > 1.0:
		anim_name = ANIM_WALK[facing_direction]
	else:
		anim_name = ANIM_IDLE[facing_direction]

	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)

## ==================== INTERAÇÃO ====================
var _player_in_range: bool = false

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		_player_in_range = true
		_show_interaction_prompt()

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		_player_in_range = false
		_hide_interaction_prompt()

func interact() -> void:
	if talked_today:
		_say_dialogue(_get_repeat_dialogue())
	else:
		_say_dialogue(_get_greeting_dialogue())
		talked_today = true
		if GameManager:
			GameManager.npcs_talked_today.append(npc_name)

	emit_signal("npc_interacted", npc_name)

func _show_interaction_prompt() -> void:
	# Mostra ícone de interação acima do NPC
	pass

func _hide_interaction_prompt() -> void:
	pass

## ==================== DIÁLOGOS ====================
func _get_greeting_dialogue() -> String:
	# Usa sistema expandido de diálogos
	var player_name = GameManager.player_name if GameManager else "Jogador"
	var hour = GameManager.current_time / 100 if GameManager else 12
	var season = GameManager.current_season if GameManager else 0
	var weather = GameManager.today_weather if GameManager else 0
	var friendship = GameManager.friendships.get(npc_name, 0) if GameManager else 0

	# Determina contexto de saudação por hora
	var greeting_context = "greeting_morning"
	if hour >= 12 and hour < 18:
		greeting_context = "greeting_afternoon"
	elif hour >= 18:
		greeting_context = "greeting_evening"

	# Tenta diálogo por amizade primeiro
	var hearts = friendship / 250
	var friendship_context = "friendship_%d" % min(hearts, 10)
	var dialogue = NPCDialogue.get_dialogue(npc_name, friendship_context, player_name, {
		"weather": weather,
		"season": season
	})

	# Se não tem diálogo específico, usa saudação por hora
	if dialogue == "" or dialogue.begins_with("Oi") or dialogue.begins_with("Oh"):
		dialogue = NPCDialogue.get_dialogue(npc_name, greeting_context, player_name, {
			"weather": weather,
			"season": season
		})

	# Adiciona diálogo sazonal às vezes
	if randf() < 0.3:
		var seasonal = NPCDialogue.get_dialogue(npc_name, "seasonal_%s" % ["spring", "summer", "fall", "winter"][season], player_name)
		if seasonal:
			dialogue += "\n\n" + seasonal

	# Adiciona diálogo de clima às vezes
	if weather != 0 and randf() < 0.2:
		var weather_ctx = ["", "weather_rain", "weather_storm", "weather_snow", "weather_rain"][weather]
		if weather_ctx:
			var w_dialogue = NPCDialogue.get_dialogue(npc_name, weather_ctx, player_name)
			if w_dialogue:
				dialogue += "\n\n" + w_dialogue

	return dialogue

func _get_repeat_dialogue() -> String:
	var player_name = GameManager.player_name if GameManager else "Jogador"
	var friendship = GameManager.friendships.get(npc_name, 0) if GameManager else 0
	var hearts = friendship / 250

	var repeat_contexts = ["friendship_%d" % min(hearts, 10), "greeting_afternoon"]
	for ctx in repeat_contexts:
		var d = NPCDialogue.get_dialogue(npc_name, ctx, player_name)
		if d and not d.begins_with("Oi"):
			return d
	return "Já conversamos, mas é sempre bom te ver!"

func _say_dialogue(text: String) -> void:
	current_dialogue = text
	dialogue_label.text = text
	dialogue_bubble.visible = true
	dialogue_timer = max(4.0, text.length() * 0.05)  # Tempo baseado no tamanho

	emit_signal("dialogue_started", npc_name, text)

	# Timer para esconder
	var timer = Timer.new()
	timer.wait_time = dialogue_timer
	timer.one_shot = true
	timer.timeout.connect(_hide_dialogue)
	add_child(timer)
	timer.start()

	# Animação de fala
	if animated_sprite and animated_sprite.sprite_frames.has_animation("talk"):
		animated_sprite.play("talk_%s" % ["up", "right", "down", "left"][facing_direction])

func _hide_dialogue() -> void:
	dialogue_bubble.visible = false
	current_dialogue = ""
	emit_signal("dialogue_ended", npc_name)

## ==================== PRESENTES ====================
func give_gift(item_id: String) -> bool:
	if gift_given_today:
		_say_dialogue("Já me deu um presente hoje!")
		return false

	if gift_given_this_week >= 2:
		_say_dialogue("Chega de presentes por esta semana!")
		return false

	# Verifica reação
	var reaction = npc_data.get_gift_reaction(item_id)
	var player_name = GameManager.player_name if GameManager else "Jogador"

	# Usa sistema expandido de diálogos
	var dialogue = NPCDialogue.get_gift_reaction(npc_name, item_id, reaction.to_lower(), player_name)

	last_gift_id = item_id
	last_gift_reaction = reaction
	gift_given_today = true
	gift_given_this_week += 1

	if GameManager:
		GameManager.gifts_given_today[npc_name] = item_id
		GameManager.gifts_given_this_week[npc_name] = gift_given_this_week

	# Calcula mudança de amizade
	var friendship_change = _calculate_friendship_change(reaction)
	friendship += friendship_change
	friendship = clamp(friendship, 0, 2749)  # Max 10 corações = 2749

	if GameManager:
		GameManager.friendships[npc_name] = friendship
		GameManager.emit_signal("friendship_changed", npc_name, friendship)

	_say_dialogue(dialogue)
	emit_signal("gift_received", npc_name, item_id, reaction)
	emit_signal("friendship_changed", npc_name, friendship)

	# Verifica eventos de coração
	_check_heart_event()

	return true

func _calculate_friendship_change(reaction: String) -> int:
	# Base friendship points por reação
	var base = {
		"Love": 80,
		"Like": 45,
		"Neutral": 0,
		"Dislike": -20,
		"Hate": -40
	}

	var change = base.get(reaction, 0)

	# Modificadores
	# Aniversário: x3 (exceto Hate)
	if GameManager and npc_data.is_birthday_today(GameManager.current_season, GameManager.current_day):
		if reaction != "Hate":
			change *= 3

	# Profissão: Rancher (level 5 farming) dá +50% para animais
	# TODO: Implementar

	return change

func _get_gift_reaction_dialogue(reaction: String) -> String:
	# Fallback se NPCDialogue não estiver disponível
	var player_name = GameManager.player_name if GameManager else "Jogador"
	match reaction:
		"Love": return "{player}, isso é incrível! ❤️".format({"player": player_name})
		"Like": return "Obrigado, {player}! Vou gostar disso.".format({"player": player_name})
		"Neutral": return "Oh, para mim? Obrigado, {player}.".format({"player": player_name})
		"Dislike": return "Hum... obrigado, acho. {player}.".format({"player": player_name})
		"Hate": return "O que você estava pensando? Eu odeio isso, {player}!".format({"player": player_name})
	return "Obrigado."

func _check_heart_event() -> void:
	var hearts = friendship / 250
	var old_hearts = (friendship - _calculate_friendship_change(last_gift_reaction)) / 250

	# Verifica se cruzou threshold de coração
	if hearts > old_hearts and hearts in [2, 4, 6, 8, 10]:
		_trigger_heart_event(hearts)

func _trigger_heart_event(hearts: int) -> void:
	var situation = "heart_event_%d" % hearts
	var choice_dialogue = NPCDialogue.get_choice_dialogue(npc_name, situation)
	if not choice_dialogue.is_empty():
		_show_choice_dialogue(choice_dialogue)

func _show_choice_dialogue(dialogue_data: Dictionary) -> void:
	# Cria UI de escolhas
	var panel = Panel.new()
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 150
	panel.offset_right = -200
	panel.offset_bottom = -150

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var text = Label.new()
	text.text = dialogue_data.text
	text.autowrap_mode = 1
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.theme_override_font_size = 18
	vbox.add_child(text)

	for choice in dialogue_data.choices:
		var btn = Button.new()
		btn.text = choice.text
		btn.custom_minimum_size = Vector2(0, 40)
		btn.theme_override_font_size = 16
		btn.pressed.connect(_on_choice_selected.bind(choice, panel))
		vbox.add_child(btn)

	get_tree().root.get_child(0).add_child(panel)

func _on_choice_selected(choice: Dictionary, panel: Panel) -> void:
	var player_name = GameManager.player_name if GameManager else "Jogador"
	var response = choice.response.format({"player": player_name})
	_say_dialogue(response)

	if choice.has("affection"):
		friendship += choice.affection
		friendship = clamp(friendship, 0, 2749)
		if GameManager:
			GameManager.friendships[npc_name] = friendship
			GameManager.emit_signal("friendship_changed", npc_name, friendship)

	if choice.has("action") and choice.action == "gift" and InventoryManager:
		InventoryManager.open_gift_mode(npc_name, panel)
		return

	panel.queue_free()

## ==================== CICLO DIÁRIO ====================
func new_day() -> void:
	talked_today = false
	gift_given_today = false
	_update_schedule()

	# Reseta presentes semanais na segunda-feira
	if GameManager and GameManager.current_weekday == 0:
		gift_given_this_week = 0

## ==================== AMIZADE ====================
func _get_friendship_level() -> int:
	# 0-249 = 0 corações, 250-499 = 1, etc.
	return friendship / 250

func get_friendship_hearts() -> float:
	return friendship / 250.0

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"name": npc_name,
		"position": global_position,
		"friendship": friendship,
		"talked_today": talked_today,
		"gift_given_today": gift_given_today,
		"gift_given_this_week": gift_given_this_week,
		"last_gift_id": last_gift_id,
		"last_gift_reaction": last_gift_reaction,
		"schedule": current_schedule,
		"route_index": route_index,
		"facing_direction": facing_direction
	}

func load_save_data(data: Dictionary) -> void:
	global_position = data.get("position", global_position)
	friendship = data.get("friendship", 0)
	talked_today = data.get("talked_today", false)
	gift_given_today = data.get("gift_given_today", false)
	gift_given_this_week = data.get("gift_given_this_week", 0)
	last_gift_id = data.get("last_gift_id", "")
	last_gift_reaction = data.get("last_gift_reaction", "")
	current_schedule = data.get("schedule", "")
	route_index = data.get("route_index", 0)
	facing_direction = data.get("facing_direction", 2)

	_update_schedule()