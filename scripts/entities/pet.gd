class_name Pet
extends CharacterBody2D

## Pet: gato ou cachorro, amizade, acariciar, segue jogador

@export var pet_type: String = "Cat"  # "Cat" ou "Dog"
@export var pet_name: String = ""
@export var sprite_sheet: SpriteFrames

## Estado
var friendship: int = 0  # 0-1000
var last_pet_day: int = -1
var position_offset: Vector2i = Vector2i(-1, 0)  # Posição relativa ao jogador
var state: String = "idle"  # idle, follow, sleep, eat, play
var target_position: Vector2

## Constantes
const MAX_FRIENDSHIP = 1000
const FRIENDSHIP_PER_PET = 12
const FRIENDSHIP_PER_DAY = 6  # Se não for ignorado
const PET_COOLDOWN_HOURS = 24

## Sprites por tipo
const PET_SPRITES = {
	"Cat": {
		"idle": "cat_idle",
		"walk": "cat_walk",
		"sleep": "cat_sleep",
		"pet": "cat_pet",
		"texture": "res://assets/sprites/pets/cat.png"
	},
	"Dog": {
		"idle": "dog_idle",
		"walk": "dog_walk",
		"sleep": "dog_sleep",
		"pet": "dog_pet",
		"texture": "res://assets/sprites/pets/dog.png"
	}
}

## Nomes padrão
const DEFAULT_NAMES = {
	"Cat": ["Whiskers", "Mittens", "Shadow", "Luna", "Oliver", "Simba", "Nala", "Tiger"],
	"Dog": ["Buster", "Buddy", "Max", "Bella", "Charlie", "Daisy", "Rocky", "Molly"]
}

## ==================== SINAIS ====================
signal friendship_changed(new_value: int)
signal pet_petted()
signal pet_renamed(new_name: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_setup_sprites()
	_load_pet_data()
	_setup_collision()

	# Timer para IA
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = false
	timer.timeout.connect(_ai_tick)
	add_child(timer)
	timer.start()

func _setup_sprites() -> void:
	var anim_player = AnimatedSprite2D.new()
	anim_player.name = "AnimatedSprite2D"
	add_child(anim_player)

	# Tenta carregar sprite sheet real, senão usa placeholder
	var sprite_data = PET_SPRITES.get(pet_type, PET_SPRITES["Cat"])
	if ResourceLoader.exists(sprite_data.texture):
		anim_player.sprite_frames = load(sprite_data.texture.replace(".png", ".tres"))
	else:
		# Cria placeholder procedural
		anim_player.sprite_frames = _create_placeholder_sprites(pet_type)

	anim_player.play("idle")

func _create_placeholder_sprites(type: String) -> SpriteFrames:
	var frames = SpriteFrames.new()
	var color = Color(0.6, 0.4, 0.3) if type == "Cat" else Color(0.5, 0.35, 0.2)

	# Cria animações simples coloridas
	for anim in ["idle", "walk", "sleep", "pet"]:
		frames.add_animation(anim)
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(color)
		# Desenha forma simples
		for x in range(8, 24):
			for y in range(8, 24):
				if (x - 16) * (x - 16) + (y - 16) * (y - 16) < 64:
					img.set_pixel(x, y, color.lightened(0.2))
		var tex = ImageTexture.create_from_image(img)
		frames.set_frame_texture(anim, 0, tex)
		frames.set_animation_loop(anim, true)
		frames.set_animation_speed(anim, 4)

	return frames

func _setup_collision() -> void:
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12
	collision.shape = shape
	add_child(collision)

	collision_layer = 0
	collision_mask = 0

func _load_pet_data() -> void:
	if not GameManager:
		return

	friendship = GameManager.get_data("pet_friendship", 0)
	pet_name = GameManager.get_data("pet_name", "")
	last_pet_day = GameManager.get_data("pet_last_pet_day", -1)
	pet_type = GameManager.get_data("pet_type", pet_type)

	if pet_name == "":
		pet_name = DEFAULT_NAMES[pet_type].pick_random()
		GameManager.set_data("pet_name", pet_name)

	name = pet_name  # Node name

func _ai_tick() -> void:
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var distance = global_position.distance_to(player.global_position)

	match state:
		"follow":
			_follow_player(player)
		"idle":
			if distance > 200:
				state = "follow"
			elif distance < 50 and randf() < 0.02:
				state = "sleep"
		"sleep":
			if distance < 30 or (GameManager.current_time >= 600 and GameManager.current_time < 2200):
				if randf() < 0.1:
					state = "idle"
		"eat":
			# Fica comendo por um tempo
			if randf() < 0.05:
				state = "idle"
		"play":
			if randf() < 0.03:
				state = "idle"

	_update_animation()

func _follow_player(player: Node2D) -> void:
	var direction = (player.global_position - global_position).normalized()
	var target = player.global_position + Vector2(position_offset.x * 32, position_offset.y * 32)

	velocity = direction * 80
	move_and_slide()

	# Atualiza sprite direction
	var anim = get_node("AnimatedSprite2D")
	if velocity.x < 0:
		anim.flip_h = true
	elif velocity.x > 0:
		anim.flip_h = false

func _update_animation() -> void:
	var anim = get_node("AnimatedSprite2D")
	match state:
		"follow":
			anim.play("walk")
		"sleep":
			anim.play("sleep")
		"pet":
			anim.play("pet")
		"eat":
			anim.play("sleep")  # Reusa sleep para comer
		"play":
			anim.play("walk")   # Reusa walk para brincar
		_:
			anim.play("idle")

## ==================== INTERAÇÕES ====================
func can_pet() -> bool:
	# Só pode acariciar uma vez por dia
	return last_pet_day != GameManager.current_day

func pet() -> bool:
	if not can_pet():
		_show_message("%s já foi acariciado hoje." % pet_name)
		return false

	state = "pet"
	last_pet_day = GameManager.current_day
	friendship = min(MAX_FRIENDSHIP, friendship + FRIENDSHIP_PER_PET)

	GameManager.set_data("pet_friendship", friendship)
	GameManager.set_data("pet_last_pet_day", last_pet_day)

	emit_signal("friendship_changed", friendship)
	emit_signal("pet_petted")

	# Mensagem baseada na amizade
	var msg = _get_pet_message()
	_show_message(msg)

	# Volta ao idle após animação
	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(func(): state = "idle")
	add_child(timer)
	timer.start()

	return true

func _get_pet_message() -> String:
	var hearts = friendship / 200  # 0-5 corações
	match hearts:
		0: return "%s te ignora." % pet_name
		1: return "%s permite que você o acaricie." % pet_name
		2: return "%s ronrona/abana o rabo feliz." % pet_name
		3: return "%s se esfrega em você / pula de alegria!" % pet_name
		4: return "%s te ama muito! ❤️" % pet_name
		5: return "%s é seu melhor amigo! 💕" % pet_name
		_: return "%s te adora!" % pet_name

func feed() -> void:
	if state == "eat":
		return

	state = "eat"
	friendship = min(MAX_FRIENDSHIP, friendship + 6)
	GameManager.set_data("pet_friendship", friendship)
	emit_signal("friendship_changed", friendship)
	_show_message("%s come feliz." % pet_name)

	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(func(): state = "idle")
	add_child(timer)
	timer.start()

func play_with() -> void:
	state = "play"
	friendship = min(MAX_FRIENDSHIP, friendship + 10)
	GameManager.set_data("pet_friendship", friendship)
	emit_signal("friendship_changed", friendship)
	_show_message("Você brinca com %s!" % pet_name)

	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func(): state = "idle")
	add_child(timer)
	timer.start()

func rename(new_name: String) -> void:
	if new_name.strip() == "":
		return
	pet_name = new_name.strip()
	name = pet_name
	GameManager.set_data("pet_name", pet_name)
	emit_signal("pet_renamed", pet_name)
	_show_message("Nome alterado para %s!" % pet_name)

## ==================== PROCESSAMENTO DIÁRIO ====================
func process_daily() -> void:
	# Decaimento de amizade se ignorado por muitos dias
	var days_since_pet = GameManager.current_day - last_pet_day
	if days_since_pet > 2:
		friendship = max(0, friendship - FRIENDSHIP_PER_DAY * (days_since_pet - 2))
		GameManager.set_data("pet_friendship", friendship)
		emit_signal("friendship_changed", friendship)

	# Mensagem matinal
	if GameManager.current_time == 600:
		_morning_greeting()

func _morning_greeting() -> void:
	var hearts = friendship / 200
	var messages = {
		0: ["%s te observa dormindo.", "%s está sentado na cama."],
		1: ["%s te cumprimenta com um miado/latido.", "%s esfrega na sua perna."],
		2: ["%s ronrona/abana rabo ao te ver.", "%s traz um brinquedo."],
		3: ["%s pula na cama para te acordar!", "%s lambe sua mão."],
		4: ["%s dormiu aos seus pés a noite toda. ❤️", "%s te espera na porta."],
		5: ["%s é a melhor parte do seu dia! 💕", "Você acorda com %s no travesseiro. 💕"]
	}
	var msgs = messages.get(hearts, messages[0])
	_show_message(msgs.pick_random())

## ==================== GETTERS ====================
func get_friendship_hearts() -> int:
	return friendship / 200

func get_friendship_percentage() -> float:
	return friendship / MAX_FRIENDSHIP

func get_status_text() -> String:
	var hearts = get_friendship_hearts()
	var heart_str = "❤️" * hearts + "🤍" * (5 - hearts)
	return "%s: %s (%d/1000)" % [pet_name, heart_str, friendship]

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"pet_type": pet_type,
		"pet_name": pet_name,
		"friendship": friendship,
		"last_pet_day": last_pet_day,
		"position_offset": {"x": position_offset.x, "y": position_offset.y}
	}

func load_save_data(data: Dictionary) -> void:
	pet_type = data.get("pet_type", pet_type)
	pet_name = data.get("pet_name", pet_name)
	friendship = data.get("friendship", 0)
	last_pet_day = data.get("last_pet_day", -1)
	var pos = data.get("position_offset", {})
	position_offset = Vector2i(pos.get("x", -1), pos.get("y", 0))
	name = pet_name
	_setup_sprites()

func _show_message(text: String) -> void:
	print("Pet: %s" % text)
	if GameManager and GameManager.hud:
		GameManager.hud.show_message(text)