extends CharacterBody2D

## Monstro básico com IA simples, combate, drops

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $DetectionArea

## Tipo e stats
var monster_type: String = ""
var level: int = 1
var health: float = 100.0
var max_health: float = 100.0
var attack_damage: float = 10.0
var move_speed: float = 60.0
var detection_range: float = 200.0
var attack_range: float = 32.0
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

## IA
var player: Node2D = null
var is_aggro: bool = false
var patrol_target: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0
var is_attacking: bool = false

## Drops
var drops: Array[Dictionary] = []

## Animações
const ANIM_IDLE = ["idle_up", "idle_right", "idle_down", "idle_left"]
const ANIM_WALK = ["walk_up", "walk_right", "walk_down", "walk_left"]
const ANIM_ATTACK = ["attack_up", "attack_right", "attack_down", "attack_left"]
const ANIM_HURT = "hurt"
const ANIM_DIE = "die"

var facing_direction: int = 2  # 0=up, 1=right, 2=down, 3=left

## Sinais
signal monster_died(monster: Node2D, drops: Array)
signal player_hit(damage: float)
signal aggro_changed(is_aggro: bool)

func initialize(type: String, lvl: int) -> void:
	monster_type = type
	level = lvl

	# Configura stats baseado no tipo
	_setup_stats()
	_setup_visuals()
	_setup_drops()

func _setup_stats() -> void:
	match monster_type:
		"Green Slime":
			max_health = 30 + level * 5
			attack_damage = 5 + level * 2
			move_speed = 40.0
			detection_range = 150.0
		"Rock Crab":
			max_health = 50 + level * 8
			attack_damage = 8 + level * 3
			move_speed = 30.0
			detection_range = 120.0
		"Bug":
			max_health = 20 + level * 3
			attack_damage = 3 + level * 1
			move_speed = 80.0
			detection_range = 180.0
		"Dust Spirit":
			max_health = 40 + level * 6
			attack_damage = 6 + level * 2
			move_speed = 50.0
			detection_range = 200.0
		"Bat":
			max_health = 25 + level * 4
			attack_damage = 4 + level * 2
			move_speed = 100.0
			detection_range = 250.0
		"Ice Slime":
			max_health = 45 + level * 7
			attack_damage = 7 + level * 3
			move_speed = 45.0
			detection_range = 150.0
		"Frost Bat":
			max_health = 35 + level * 5
			attack_damage = 6 + level * 2
			move_speed = 90.0
			detection_range = 200.0
		"Ice Golem":
			max_health = 100 + level * 15
			attack_damage = 15 + level * 5
			move_speed = 25.0
			detection_range = 180.0
		"Shadow Shaman":
			max_health = 60 + level * 10
			attack_damage = 10 + level * 4
			move_speed = 60.0
			detection_range = 250.0
		"Lava Slime":
			max_health = 70 + level * 12
			attack_damage = 12 + level * 4
			move_speed = 50.0
			detection_range = 160.0
		"Fire Bat":
			max_health = 45 + level * 6
			attack_damage = 8 + level * 3
			move_speed = 110.0
			detection_range = 220.0
		"Iridium Bat":
			max_health = 80 + level * 10
			attack_damage = 14 + level * 4
			move_speed = 120.0
			detection_range = 280.0
		"Serpent":
			max_health = 120 + level * 20
			attack_damage = 20 + level * 6
			move_speed = 70.0
			detection_range = 300.0
		_:
			max_health = 50 + level * 5
			attack_damage = 8 + level * 2
			move_speed = 60.0
			detection_range = 200.0

	health = max_health

func _setup_visuals() -> void:
	# Carrega spritesheet baseado no tipo
	# Por enquanto, usa cor placeholder
	if animated_sprite:
		animated_sprite.modulate = _get_monster_color()

func _get_monster_color() -> Color:
	match monster_type:
		"Green Slime", "Ice Slime", "Lava Slime": return Color(0.2, 0.8, 0.2)
		"Rock Crab": return Color(0.6, 0.4, 0.2)
		"Bug": return Color(0.8, 0.8, 0.2)
		"Dust Spirit": return Color(0.5, 0.5, 0.8)
		"Bat", "Frost Bat", "Fire Bat", "Iridium Bat": return Color(0.3, 0.3, 0.5)
		"Ice Golem": return Color(0.7, 0.9, 1.0)
		"Shadow Shaman": return Color(0.2, 0.1, 0.3)
		"Serpent": return Color(0.8, 0.2, 0.2)
		_: return Color(0.5, 0.5, 0.5)

func _setup_drops() -> void:
	# Drops baseados no tipo
	match monster_type:
		"Green Slime":
			drops = [
				{"item_id": "(O)766", "chance": 0.8, "min": 1, "max": 3},  # Slime
				{"item_id": "(O)337", "chance": 0.1, "min": 1, "max": 1},  # Iridium (raro)
			]
		"Rock Crab":
			drops = [
				{"item_id": "(O)378", "chance": 0.6, "min": 1, "max": 2},  # Copper
				{"item_id": "(O)390", "chance": 0.3, "min": 1, "max": 1},  # Stone
			]
		"Bug":
			drops = [
				{"item_id": "(O)768", "chance": 0.7, "min": 1, "max": 2},  # Bug Meat
			]
		"Bat":
			drops = [
				{"item_id": "(O)767", "chance": 0.5, "min": 1, "max": 2},  # Bat Wing
			]
		_:
			drops = [
				{"item_id": "(O)766", "chance": 0.5, "min": 1, "max": 2},  # Slime genérico
			]

func _physics_process(delta: float) -> void:
	if health <= 0:
		return

	# Atualiza timers
	if attack_timer > 0:
		attack_timer -= delta

	if patrol_timer > 0:
		patrol_timer -= delta

	# IA
	if not is_attacking:
		_update_ai(delta)

	move_and_slide()
	_update_animation()

func _update_ai(delta: float) -> void:
	# Encontra player
	if not player:
		player = get_tree().get_first_node_in_group("player")

	if not player:
		_patrol(delta)
		return

	var dist_to_player = global_position.distance_to(player.global_position)

	# Detecção de aggro
	if not is_aggro and dist_to_player < detection_range:
		is_aggro = true
		emit_signal("aggro_changed", true)
	elif is_aggro and dist_to_player > detection_range * 1.5:
		is_aggro = false
		emit_signal("aggro_changed", false)

	if is_aggro:
		if dist_to_player <= attack_range:
			# Ataca
			velocity = Vector2.ZERO
			if attack_timer <= 0:
				_attack()
		else:
			# Persegue
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * move_speed
			_update_facing(direction)
	else:
		_patrol(delta)

func _patrol(delta: float) -> void:
	if patrol_timer <= 0:
		# Novo ponto de patrulha
		patrol_target = global_position + Vector2(
			randf_range(-100, 100),
			randf_range(-100, 100)
		)
		patrol_timer = randf_range(2.0, 5.0)

	var direction = (patrol_target - global_position).normalized()
	if global_position.distance_to(patrol_target) > 10.0:
		velocity = direction * move_speed * 0.5  # Mais lento patrulhando
		_update_facing(direction)
	else:
		velocity = Vector2.ZERO

func _update_facing(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		facing_direction = 1 if direction.x > 0 else 3
	else:
		facing_direction = 2 if direction.y > 0 else 0

func _attack() -> void:
	is_attacking = true
	attack_timer = attack_cooldown
	velocity = Vector2.ZERO

	# Animação de ataque
	if animated_sprite:
		animated_sprite.play(ANIM_ATTACK[facing_direction])

	# Dano ao player após delay
	await get_tree().create_timer(0.3).timeout

	if player and global_position.distance_to(player.global_position) <= attack_range * 1.2:
		emit_signal("player_hit", attack_damage)
		# Aplica dano ao player
		if GameManager:
			GameManager.health -= attack_damage
			GameManager.emit_signal("health_changed", GameManager.health)

	# Efeito visual de ataque
	if ParticleManager:
		ParticleManager.spawn_hit_effect(player.global_position)

	await get_tree().create_timer(0.3).timeout
	is_attacking = false

func _update_animation() -> void:
	if not animated_sprite:
		return

	var anim_name = ""
	if is_attacking:
		anim_name = ANIM_ATTACK[facing_direction]
	elif velocity.length() > 1.0:
		anim_name = ANIM_WALK[facing_direction]
	else:
		anim_name = ANIM_IDLE[facing_direction]

	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)

func take_damage(amount: float, knockback_direction: Vector2 = Vector2.ZERO) -> void:
	if health <= 0:
		return

	health -= amount

	# Efeito de dano
	if animated_sprite:
		animated_sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		animated_sprite.modulate = _get_monster_color()

	# Knockback
	if knockback_direction != Vector2.ZERO:
		velocity = knockback_direction * 200.0

	# Número de dano flutuante
	if VisualManager:
		VisualManager.show_damage_number(global_position, int(amount), "damage")

	# Som de hit
	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/monster_hit.ogg")

	if health <= 0:
		_die()

func _die() -> void:
	# Drop de itens
	var dropped_items = []
	for drop in drops:
		if randf() < drop.chance:
			var amount = randi_range(drop.min, drop.max)
			dropped_items.append({"item_id": drop.item_id, "amount": amount})

			# Adiciona ao inventário do player
			if InventoryManager:
				InventoryManager.add_item(drop.item_id, amount)

	# XP de combate
	if GameManager:
		var xp = 10 + level * 2
		GameManager.add_skill_xp(4, xp)  # Combat skill

	# Efeito de morte
	if ParticleManager:
		ParticleManager.spawn_death_effect(global_position)

	# Som de morte
	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/monster_die.ogg")

	emit_signal("monster_died", self, dropped_items)

	# Remove monstros da lista do MineManager
	if MineManager:
		MineManager.level_monsters.erase(self)

	queue_free()

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"type": monster_type,
		"level": level,
		"health": health,
		"position": global_position,
		"is_aggro": is_aggro
	}

func load_save_data(data: Dictionary) -> void:
	monster_type = data.get("type", "")
	level = data.get("level", 1)
	health = data.get("health", max_health)
	global_position = data.get("position", Vector2.ZERO)
	is_aggro = data.get("is_aggro", false)

	_setup_stats()
	_setup_visuals()