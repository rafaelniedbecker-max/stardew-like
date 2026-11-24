class_name Ladder
extends Area2D

## Escada da mina (subida/descida)

@export var direction: String = "down"  # "up" ou "down"
@export var target_level: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 4
	collision_mask = 1
	area_entered.connect(_on_player_entered)

func initialize(dir: String, level: int) -> void:
	direction = dir
	target_level = level

	# Configura visual
	if sprite:
		sprite.modulate = Color(0.4, 0.3, 0.2) if direction == "down" else Color(0.3, 0.5, 0.7)
		sprite.texture = _create_ladder_texture()

func _create_ladder_texture() -> Texture2D:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var color = Color(0.4, 0.3, 0.2) if direction == "down" else Color(0.3, 0.5, 0.7)

	# Desenha escada simples
	for x in range(6, 26):
		for y in range(32):
			if y % 4 < 2:
				img.set_pixel(x, y, color)

	return ImageTexture.create_from_image(img)

## ==================== INTERAÇÃO ====================
func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		_use_ladder()

func _use_ladder() -> void:
	if MineManager:
		if direction == "down":
			MineManager.go_down()
		else:
			MineManager.go_up()