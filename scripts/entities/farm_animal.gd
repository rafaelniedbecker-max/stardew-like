class_name FarmAnimal
extends CharacterBody2D

## Animal de fazenda com felicidade, amizade, produção

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var name_label: Label = $NameLabel
@onready var heart_particles: CPUParticles2D = $HeartParticles
@onready var status_bubble: Control = $StatusBubble
@onready var status_icon: TextureRect = $StatusBubble/Icon

## Dados do animal
var animal_data: Dictionary  # Do FarmAnimals.json
var animal_type: String = ""  # "Chicken", "Cow", "Goat", etc.
var animal_subtype: String = ""  # "White Chicken", "Brown Chicken", "Blue Chicken", etc.

## Estado
var animal_id: String = ""  # ID único
var name: String = ""
var friendship: int = 0  # 0-1000 (5 corações = 1000)
var mood: int = 0  # 0-255 (afeta produção)
var health: int = 100
var age_days: int = 0
var days_to_mature: int = 0
var is_baby: bool = true
var is_pregnant: bool = false
var pregnancy_days: int = 0

## Produção
var last_produce_day: int = -1
var produce_ready: bool = false
var produce_quality: int = 0  # 0-3
var produce_type: String = "normal"  # "normal", "deluxe", "large"

## Alimentação/Cuidados
var fed_today: bool = false
var petted_today: bool = false
var let_out_today: bool = false
var ate_grass_today: bool = false
var heater_active: bool = false

## Edifício pai
var parent_building: Building = null
var home_position: Vector2 = Vector2.ZERO

## Animações
const ANIM_IDLE = ["idle_up", "idle_right", "idle_down", "idle_left"]
const ANIM_WALK = ["walk_up", "walk_right", "walk_down", "walk_left"]
const ANIM_EAT = ["eat_up", "eat_right", "eat_down", "eat_left"]
const ANIM_SLEEP = ["sleep_up", "sleep_right", "sleep_down", "sleep_left"]
const ANIM_HAPPY = ["happy_up", "happy_right", "happy_down", "happy_left"]
var facing_direction: int = 2

## ==================== SINAIS ====================
signal animal_interacted(animal: FarmAnimal)
signal produce_ready(animal: FarmAnimal, item_id: String, quality: int)
signal friendship_changed(animal: FarmAnimal, new_friendship: int)
signal mood_changed(animal: FarmAnimal, new_mood: int)
signal animal_grew_up(animal: FarmAnimal)
signal baby_born(parent: FarmAnimal, baby: FarmAnimal)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	add_to_group("farm_animal")
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)
	name_label.visible = false

func initialize(animal_type: String, subtype: String, animal_id: String, building: Building, home_pos: Vector2) -> void:
	self.animal_type = animal_type
	self.animal_subtype = subtype
	self.animal_id = animal_id
	self.parent_building = building
	self.home_position = home_pos

	# Carrega dados do JSON
	animal_data = DataLoader.get_farm_animal(subtype)
	if not animal_data:
		animal_data = DataLoader.get_farm_animal(animal_type)

	# Nome aleatório ou padrão
	var names = animal_data.get("Names", [])
	name = names[randi() % names.size()] if names.size() > 0 else subtype

	# Estado inicial
	friendship = 0
	mood = 200
	health = 100
	age_days = 0
	days_to_mature = animal_data.get("DaysToMature", 3)
	is_baby = true
	is_pregnant = false

	_setup_visuals()
	global_position = home_pos
	name_label.text = name

	# Timer de verificação diária (simulado)
	# Real usa GameManager day_changed

func _setup_visuals() -> void:
	# Carrega textura do animal
	var tex_path = animal_data.get("Texture2D", "")
	if tex_path:
		var tex = load("res://resources/sprites/%s.png" % tex_path)
		if tex:
			animated_sprite.texture = tex
			# Configura SpriteFrames baseado nos dados
			_setup_animations()

	# Tamanho do bebê
	if is_baby:
		scale = Vector2(0.5, 0.5)

func _setup_animations() -> void:
	# Cria animações baseadas no SpriteWidth/Height
	var frames = animated_sprite.sprite_frames
	if not frames:
		frames = SpriteFrames.new()
		animated_sprite.sprite_frames = frames

	var sw = animal_data.get("SpriteWidth", 16)
	var sh = animal_data.get("SpriteHeight", 16)
	var use_double = animal_data.get("UseDoubleUniqueAnimationFrames", true)

	# TODO: Parse real da spritesheet
	# Por enquanto placeholders
	for dir_name in ["up", "right", "down", "left"]:
		for anim in ["idle", "walk", "eat", "sleep", "happy"]:
			var anim_name = "%s_%s" % [anim, dir_name]
			frames.add_animation(anim_name)
			frames.set_animation_loop(anim_name, anim != "eat" and anim != "happy")

## ==================== CICLO DIÁRIO ====================
func new_day() -> void:
	if is_baby:
		grow_up_check()
		return

	# Reseta flags diárias
	fed_today = false
	petted_today = false
	let_out_today = false
	ate_grass_today = false

	# Verifica gravidez
	if is_pregnant:
		pregnancy_days -= 1
		if pregnancy_days <= 0:
			give_birth()

	# Calcula humor base
	_calculate_mood()

	# Tenta produzir
	try_produce()

	age_days += 1

func grow_up_check() -> void:
	age_days += 1
	if age_days >= days_to_mature:
		is_baby = false
		scale = Vector2(1, 1)
		emit_signal("animal_grew_up", self)
		print("Animal: %s cresceu!" % name)

func _calculate_mood() -> void:
	# Base mood
	var base_mood = 150

	# Bônus por amizade
	base_mood += friendship / 10

	# Penalidades
	if not fed_today:
		base_mood -= 100
	if not petted_today:
		base_mood -= 50
	if parent_building and not parent_building.allow_animal_pregnancy and is_pregnant:
		base_mood -= 30

	# Bônus por comer grama
	if ate_grass_today:
		base_mood += 50

	# Aquecedor no inverno
	if GameManager and GameManager.current_season == 3 and heater_active:
		base_mood += 50

	# Profissão Rancher (level 5 farming)
	if GameManager and GameManager.professions.get("Farming") == 0:
		base_mood += 20

	mood = clamp(base_mood, 0, 255)
	emit_signal("mood_changed", self, mood)

## ==================== PRODUÇÃO ====================
func try_produce() -> void:
	# Verifica se já produziu hoje
	if last_produce_day == GameManager.current_day:
		return

	# Verifica se adulto
	if is_baby:
		return

	# Dias para produzir
	var produce_every = animal_data.get("DaysToProduce", 1)
	if produce_every > 1 and (age_days % produce_every) != 0:
		return

	# Determina item de produção
	var produce_items = animal_data.get("ProduceItemIds", [])
	var deluxe_items = animal_data.get("DeluxeProduceItemIds", [])

	var item_id = ""
	var is_deluxe = false
	var quality = 0

	# Chance de produto deluxe baseado em amizade
	var deluxe_min_friendship = animal_data.get("DeluxeProduceMinimumFriendship", 200)
	var deluxe_chance = 0.0

	if friendship >= deluxe_min_friendship and deluxe_items.size() > 0:
		var care_divisor = animal_data.get("DeluxeProduceCareDivisor", 1200.0)
		var luck_mult = animal_data.get("DeluxeProduceLuckMultiplier", 0.0)
		deluxe_chance = (friendship / care_divisor) + (GameManager.daily_luck * luck_mult)

	if randf() < deluxe_chance:
		is_deluxe = true
		item_id = deluxe_items[0].get("ItemId", "")
	else:
		item_id = produce_items[0].get("ItemId", "")

	# Qualidade baseada em amizade + humor + profissão
	quality = _calculate_produce_quality()

	last_produce_day = GameManager.current_day
	produce_ready = true
	produce_type = "deluxe" if is_deluxe else "normal"
	produce_quality = quality

	# Mostra bolha de status
	_show_produce_bubble(item_id, quality)

	emit_signal("produce_ready", self, item_id, quality)

func _calculate_produce_quality() -> int:
	var chance = 0.0

	# Base: amizade (0-1000) / 1000 * 0.5
	chance += (friendship / 1000.0) * 0.5

	# Humor (0-255) / 255 * 0.3
	chance += (mood / 255.0) * 0.3

	# Sorte diária
	chance += (GameManager.daily_luck + 0.1) * 0.2

	# Profissão Artisan (level 10 farming choice)
	if GameManager and GameManager.professions.get("Farming") == 1:
		chance += 0.2

	# Sorte do dia
	chance += GameManager.daily_luck * 0.5

	# Determina qualidade
	if chance > 0.9:
		return 3  # Irídio
	elif chance > 0.6:
		return 2  # Ouro
	elif chance > 0.3:
		return 1  # Prata
	return 0  # Normal

func collect_produce() -> Dictionary:
	if not produce_ready:
		return {}

	var item_id = produce_type == "deluxe" ?
		animal_data.get("DeluxeProduceItemIds", [{}])[0].get("ItemId", "") :
		animal_data.get("ProduceItemIds", [{}])[0].get("ItemId", "")

	var result = {
		"item_id": item_id,
		"quality": produce_quality,
		"type": produce_type
	}

	# Animação e feedback visual
	_play_animation("happy")

	# Partículas baseadas no tipo
	if ParticleManager:
		if produce_type == "deluxe":
			ParticleManager.show_level_up(global_position, "Produto Deluxe!")
		else:
			ParticleManager.spawn("harvest", global_position)

	# Texto flutuante com qualidade
	var quality_names = ["Normal", "Prata", "Ouro", "Irídio"]
	var quality_colors = [Color.WHITE, Color(0.75, 0.75, 0.75), Color(1.0, 0.85, 0.2), Color(0.6, 0.3, 1.0)]
	var q_color = quality_colors[produce_quality] if produce_quality < quality_colors.size() else Color.WHITE
	_show_floating_text("+%s (%s)" % [item_id, quality_names[produce_quality]], q_color)

	# Som de coleta
	if AudioManager:
		var sfx = "res://assets/sfx/collect_produce.ogg"
		if ResourceLoader.exists(sfx):
			AudioManager.play_sfx_at_position(sfx, global_position)

	produce_ready = false
	status_bubble.visible = false

	return result

func _show_produce_bubble(item_id: String, quality: int) -> void:
	var item = DataLoader.get_item(item_id)
	if item:
		status_icon.texture = null  # TODO: textura do item
		status_bubble.visible = true

## ==================== INTERAÇÕES ====================
var _player_nearby: bool = false

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		_player_nearby = true
		name_label.visible = true
		if produce_ready:
			HUD.show_interaction_prompt("E: Coletar (%s)" % name, global_position + Vector2(0, -40))
		else:
			HUD.show_interaction_prompt("E: Interagir (%s)" % name, global_position + Vector2(0, -40))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		_player_nearby = false
		name_label.visible = false
		HUD.hide_interaction_prompt()

func interact(action: String = "pet") -> void:
	match action:
		"pet":
			pet()
		"feed":
			feed()
		"play":
			play_with()
		"collect":
			return collect_produce()
		"let_out":
			let_out()
		"grab":
			grab()
	return null

func play_with() -> void:
	# Brincar com animal - aumenta amizade e humor, mas só se não foi acariciado
	if petted_today:
		_show_message("%s está cansado de brincar." % name)
		return

	petted_today = true  # Conta como interação do dia
	_change_friendship(10)
	_change_mood(20)

	# Animação feliz
	_play_animation("happy")
	heart_particles.emitting = true
	heart_particles.one_shot = true
	heart_particles.amount = 15

	if ParticleManager:
		ParticleManager.spawn_area("harvest", global_position, 15, 40.0)

	_show_status_icon("🎮", Color(0.6, 0.8, 1.0))
	_show_floating_text("🎮 Brincou! +10 ❤️ +20 😊", Color(0.6, 0.8, 1.0))

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/play_animal.ogg", global_position)

	# Chance de produzir item extra se muito feliz
	if friendship > 800 and mood > 200 and randf() < 0.1:
		_try_extra_produce()

	print("Animal: Brincou com %s" % name)

func pet() -> void:
	if petted_today:
		_show_message("%s já foi acariciado hoje." % name)
		_show_status_icon("❌", Color(1, 0.3, 0.3))
		return

	petted_today = true
	var base_friendship = 12
	var bonus = 0

	# Animação feliz com duração
	_play_animation("happy")
	heart_particles.emitting = true
	heart_particles.one_shot = true
	heart_particles.amount = 10

	# Partículas de coração
	if ParticleManager:
		ParticleManager.spawn_area("harvest", global_position, 12, 32.0)

	# Feedback visual
	_show_status_icon("❤️", Color(1.0, 0.4, 0.6))
	_show_floating_text("+%d ❤️" % base_friendship, Color(1.0, 0.5, 0.8))

	# Bônus por humor alto
	if mood > 200:
		bonus += 6
		_show_floating_text("Humor alto! +6 ❤️", Color(1.0, 0.8, 0.3))

	# Bônus por amizade alta (animal confia mais)
	if friendship > 500:
		bonus += 3
		_show_floating_text("Confiança! +3 ❤️", Color(0.5, 0.8, 1.0))

	_change_friendship(base_friendship + bonus)

	# Som de carinho
	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/pet_animal.ogg", global_position)

	# Chance de reação especial
	if randf() < 0.1:
		_special_reaction("pet")

	print("Animal: Acariciou %s (amizade: %d, bônus: %d)" % [name, friendship, bonus])

func feed(hay_from_building: bool = true) -> void:
	if fed_today:
		_show_message("%s já comeu hoje." % name)
		_show_status_icon("❌", Color(1, 0.3, 0.3))
		return

	# Verifica feno no edifício
	if hay_from_building and parent_building:
		if parent_building.hay_stored <= 0:
			_show_message("Sem feno no silo!")
			_show_status_icon("🚫", Color(1, 0.3, 0.3))
			return
		parent_building.remove_hay(1)

	fed_today = true
	_change_friendship(6)

	# Animação de comer
	_play_animation("eat")

	# Partículas de comida
	if ParticleManager:
		ParticleManager.spawn_area("seed", global_position + Vector2(0, -20), 8, 24.0)

	# Feedback visual
	_show_status_icon("🌾", Color(0.8, 1.0, 0.4))
	_show_floating_text("🌾 Alimentado! +6 ❤️", Color(0.8, 1.0, 0.5))

	# Chance de comer grama se fora (bônus de humor)
	if let_out_today and randf() < 0.3:
		ate_grass_today = true
		_change_friendship(10)
		_change_mood(15)  # Comer grama melhora humor
		_show_floating_text("🌿 Comeu grama! +10 ❤️ +15 😊", Color(0.5, 1.0, 0.5))
		_show_status_icon("🌿", Color(0.5, 1.0, 0.5))

	# Som de comer
	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/eat.ogg", global_position)

	# Chance de reação especial
	if randf() < 0.15:
		_special_reaction("feed")

	print("Animal: Alimentou %s" % name)

func let_out() -> void:
	if let_out_today:
		return

	let_out_today = true
	# Move para fora do edifício
	# TODO: Lógica de movimento para pasto
	print("Animal: %s saiu para o pasto" % name)

func grab() -> void:
	# Pegar animal (para mover)
	print("Animal: Pegou %s" % name)

func _change_friendship(amount: int) -> void:
	friendship = clamp(friendship + amount, 0, 1000)
	emit_signal("friendship_changed", self, friendship)

func _change_mood(amount: int) -> void:
	mood = clamp(mood + amount, 0, 255)
	emit_signal("mood_changed", self, mood)

func _try_extra_produce() -> void:
	# Chance de produzir item extra de alta qualidade
	var extra_items = {
		"Chicken": "(O)306",  # Egg
		"Cow": "(O)436",      # Milk
		"Goat": "(O)438",     # Goat Milk
		"Sheep": "(O)440",    # Wool
		"Pig": "(O)422"       # Truffle
	}

	var item_id = extra_items.get(animal_type)
	if item_id and InventoryManager:
		InventoryManager.add_item(item_id, 1)
		_show_floating_text("✨ Item extra!", Color(1.0, 0.9, 0.3))
		print("Animal: %s produziu item extra!" % name)

## ==================== REPRODUÇÃO ====================
func can_get_pregnant() -> bool:
	var data = animal_data
	return data.get("CanGetPregnant", false) and !is_baby and !is_pregnant and friendship > 300

func try_pregnancy() -> bool:
	if not can_get_pregnant():
		return false

	# Verifica se edifício permite
	if parent_building and not parent_building.allow_animal_pregnancy:
		return false

	# Chance baseada em amizade e humor
	var chance = (friendship / 1000.0) * 0.05 * (mood / 255.0)
	if randf() < chance:
		is_pregnant = true
		pregnancy_days = data.get("IncubationTime", 7)  # Usa incubação como gestação
		print("Animal: %s está prenhe!" % name)
		return true
	return false

func give_birth() -> void:
	is_pregnant = false
	var baby_type = animal_data.get("BabyTexture", "").replace("Baby", "").strip_edges()
	if baby_type == "":
		baby_type = animal_subtype

	# Cria bebê
	var baby = FarmAnimal.new()
	baby.initialize(animal_type, baby_type, "%s_baby_%d" % [animal_id, randi()], parent_building, home_position + Vector2(randi_range(-20, 20), randi_range(-20, 20)))
	get_parent().add_child(baby)

	parent_building.add_occupant({
		"id": baby.animal_id,
		"type": animal_type,
		"subtype": baby_type
	})

	emit_signal("baby_born", self, baby)
	print("Animal: %s nasceu!" % baby.name)

## ==================== ANIMAÇÕES ====================
func _play_animation(base: String) -> void:
	var anim_name = "%s_%s" % [base, ["up", "right", "down", "left"][facing_direction]]
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)

func _physics_process(delta: float) -> void:
	# Movimento simples pelo pasto
	if let_out_today and not is_baby and randf() < 0.01:
		_wander()

	# Atualiza facing direction baseado no movimento
	if velocity.length() > 1:
		_update_facing_from_velocity()

	move_and_slide()

func _wander() -> void:
	var angle = randf() * TAU
	velocity = Vector2(cos(angle), sin(angle)) * 50

func _update_facing_from_velocity() -> void:
	if abs(velocity.x) > abs(velocity.y):
		facing_direction = 1 if velocity.x > 0 else 3
	else:
		facing_direction = 2 if velocity.y > 0 else 0

	_play_animation("walk")

## ==================== MENSAGENS ====================
func _show_message(text: String) -> void:
	status_bubble.visible = true
	# TODO: Mostrar texto na bolha
	print("Animal: %s" % text)

func _show_floating_text(text: String, color: Color = Color.WHITE) -> void:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_override_font_size = 16
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.global_position = global_position + Vector2(0, -40)
	get_tree().root.get_child(0).add_child(label)

	var tween = label.create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 40, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(label.queue_free.bind())

func _show_status_icon(icon: String, color: Color) -> void:
	if not status_bubble or not status_icon:
		return

	# Cria label temporário no lugar do ícone
	var label = Label.new()
	label.text = icon
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.theme_override_font_size = 24
	status_bubble.add_child(label)

	status_bubble.visible = true

	var tween = status_bubble.create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_property(status_bubble, "position:y", status_bubble.position.y - 20, 1.5)
	tween.finished.connect(func():
		label.queue_free()
		status_bubble.visible = false
	)

func _special_reaction(action: String) -> void:
	var reactions = {
		"pet": [
			func(): _play_animation("happy"),
			func(): _show_floating_text("*ronronando*", Color(1, 0.8, 0.9)),
			func(): _show_floating_text("*abana rabo*", Color(1, 0.8, 0.9))
		],
		"feed": [
			func(): _show_floating_text("*come feliz*", Color(0.8, 1, 0.6)),
			func(): _show_floating_text("Mmm!", Color(0.9, 1, 0.5))
		]
	}

	var action_reactions = reactions.get(action, [])
	if action_reactions:
		action_reactions.pick_random().call()

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"animal_type": animal_type,
		"animal_subtype": animal_subtype,
		"animal_id": animal_id,
		"name": name,
		"friendship": friendship,
		"mood": mood,
		"health": health,
		"age_days": age_days,
		"days_to_mature": days_to_mature,
		"is_baby": is_baby,
		"is_pregnant": is_pregnant,
		"pregnancy_days": pregnancy_days,
		"last_produce_day": last_produce_day,
		"produce_ready": produce_ready,
		"produce_quality": produce_quality,
		"produce_type": produce_type,
		"fed_today": fed_today,
		"petted_today": petted_today,
		"let_out_today": let_out_today,
		"ate_grass_today": ate_grass_today,
		"position": global_position,
		"home_position": home_position,
		"parent_building_key": parent_building.position_key if parent_building else ""
	}

func load_save_data(data: Dictionary) -> void:
	animal_type = data.get("animal_type", "")
	animal_subtype = data.get("animal_subtype", "")
	animal_id = data.get("animal_id", "")
	name = data.get("name", "")
	friendship = data.get("friendship", 0)
	mood = data.get("mood", 200)
	health = data.get("health", 100)
	age_days = data.get("age_days", 0)
	days_to_mature = data.get("days_to_mature", 3)
	is_baby = data.get("is_baby", true)
	is_pregnant = data.get("is_pregnant", false)
	pregnancy_days = data.get("pregnancy_days", 0)
	last_produce_day = data.get("last_produce_day", -1)
	produce_ready = data.get("produce_ready", false)
	produce_quality = data.get("produce_quality", 0)
	produce_type = data.get("produce_type", "normal")
	fed_today = data.get("fed_today", false)
	petted_today = data.get("petted_today", false)
	let_out_today = data.get("let_out_today", false)
	ate_grass_today = data.get("ate_grass_today", false)
	global_position = data.get("position", Vector2.ZERO)
	home_position = data.get("home_position", Vector2.ZERO)

	# Reconecta com edifício pai
	var building_key = data.get("parent_building_key", "")
	if building_key:
		parent_building = BuildingManager.get_building_at(WorldInit.world_to_grid(Vector2(building_key.split(",")[0].to_int(), building_key.split(",")[1].to_int())))

	initialize(animal_type, animal_subtype, animal_id, parent_building, home_position)
	# Reaplica estado salvo
	friendship = data.get("friendship", 0)
	# ... outros campos