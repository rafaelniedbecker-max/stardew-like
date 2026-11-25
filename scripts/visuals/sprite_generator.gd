extends RefCounted

## Gerador procedural de sprites de alta qualidade
## Gera sprites detalhados programaticamente sem assets externos

## ==================== CONFIGURAÇÕES ====================
const SPRITE_SIZE = 32
const TILE_SIZE = 16
const CHARACTER_SIZE = Vector2i(32, 48)

## Paletas de cores (estilo Stardew Valley melhorado)
const PALETTES = {
	"skin": [
		Color(1.0, 0.87, 0.77),  # Claro
		Color(0.96, 0.76, 0.63),
		Color(0.87, 0.65, 0.51),
		Color(0.73, 0.51, 0.39),
		Color(0.55, 0.35, 0.25),
		Color(0.35, 0.22, 0.16)   # Escuro
	],
	"hair": [
		Color(0.15, 0.1, 0.05),    # Preto
		Color(0.25, 0.15, 0.1),    # Castanho escuro
		Color(0.4, 0.25, 0.15),    # Castanho médio
		Color(0.55, 0.35, 0.2),    # Castanho claro
		Color(0.7, 0.5, 0.25),     # Loiro escuro
		Color(0.85, 0.7, 0.35),    # Loiro
		Color(0.95, 0.85, 0.5),    # Loiro claro
		Color(0.8, 0.3, 0.2),      # Ruivo escuro
		Color(0.95, 0.45, 0.25),   # Ruivo
		Color(0.6, 0.25, 0.3),     # Rosa
		Color(0.4, 0.2, 0.4),      # Roxo
		Color(0.2, 0.3, 0.5),      # Azul
		Color(0.3, 0.5, 0.3)       # Verde
	],
	"eye": [
		Color(0.2, 0.15, 0.1),     # Marrom escuro
		Color(0.4, 0.25, 0.15),    # Marrom
		Color(0.3, 0.5, 0.3),      # Verde
		Color(0.2, 0.4, 0.7),      # Azul
		Color(0.5, 0.3, 0.6),      # Roxo
		Color(0.1, 0.1, 0.1)       # Preto
	],
	"clothing": [
		Color(0.8, 0.2, 0.2),      # Vermelho
		Color(0.2, 0.6, 0.2),      # Verde
		Color(0.2, 0.3, 0.8),      # Azul
		Color(0.8, 0.7, 0.2),      # Amarelo
		Color(0.7, 0.4, 0.2),      # Laranja
		Color(0.6, 0.3, 0.6),      # Roxo
		Color(0.5, 0.5, 0.5),      # Cinza
		Color(0.2, 0.2, 0.2),      # Preto
		Color(0.9, 0.9, 0.9),      # Branco
		Color(0.6, 0.4, 0.3)       # Marrom
	],
	"terrain": {
		"grass": [
			Color(0.25, 0.55, 0.2),
			Color(0.3, 0.6, 0.25),
			Color(0.2, 0.5, 0.15),
			Color(0.35, 0.65, 0.3)
		],
		"dirt": [
			Color(0.45, 0.35, 0.25),
			Color(0.5, 0.4, 0.3),
			Color(0.4, 0.3, 0.2),
			Color(0.55, 0.45, 0.35)
		],
		"water": [
			Color(0.2, 0.4, 0.8),
			Color(0.25, 0.5, 0.9),
			Color(0.15, 0.35, 0.7),
			Color(0.3, 0.55, 0.95)
		],
		"stone": [
			Color(0.45, 0.45, 0.45),
			Color(0.5, 0.5, 0.5),
			Color(0.4, 0.4, 0.4),
			Color(0.55, 0.55, 0.55)
		],
		"sand": [
			Color(0.85, 0.75, 0.55),
			Color(0.9, 0.8, 0.6),
			Color(0.8, 0.7, 0.5),
			Color(0.95, 0.85, 0.65)
		]
	},
	"crops": {
		"wheat": [
			Color(0.8, 0.7, 0.3),
			Color(0.9, 0.8, 0.4),
			Color(0.7, 0.6, 0.2)
		],
		"vegetable": [
			Color(0.3, 0.6, 0.2),
			Color(0.4, 0.7, 0.3),
			Color(0.2, 0.5, 0.15)
		],
		"fruit": [
			Color(0.9, 0.3, 0.2),
			Color(1.0, 0.5, 0.2),
			Color(0.8, 0.2, 0.1)
		],
		"flower": [
			Color(1.0, 0.5, 0.7),
			Color(0.7, 0.3, 0.8),
			Color(1.0, 0.8, 0.3),
			Color(0.5, 0.8, 1.0)
		]
	}
}

## ==================== UTILITÁRIOS DE IMAGEM ====================

static func create_base_image(width: int, height: int, transparent: bool = true) -> Image:
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	if transparent:
		img.fill(Color(0, 0, 0, 0))
	else:
		img.fill(Color(0, 0, 0, 0))
	return img

static func draw_pixel(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)

static func draw_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for i in range(w):
		for j in range(h):
			draw_pixel(img, x + i, y + j, color)

static func draw_circle(img: Image, cx: int, cy: int, radius: int, color: Color, filled: bool = true) -> void:
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var dist = sqrt(x * x + y * y)
			if filled:
				if dist <= radius:
					draw_pixel(img, cx + x, cy + y, color)
			else:
				if abs(dist - radius) < 0.5:
					draw_pixel(img, cx + x, cy + y, color)

static func draw_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color, filled: bool = true) -> void:
	for x in range(-rx, rx + 1):
		for y in range(-ry, ry + 1):
			var dx = x / rx
			var dy = y / ry
			if dx * dx + dy * dy <= 1.0:
				draw_pixel(img, cx + x, cy + y, color)

static func add_noise(img: Image, intensity: float = 0.1, seed: int = 0) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var c = img.get_pixel(x, y)
			if c.a > 0:
				var noise = (rng.randi() % 1000) / 1000.0 * 2.0 - 1.0
				var factor = 1.0 + noise * intensity
				img.set_pixel(x, y, Color(c.r * factor, c.g * factor, c.b * factor, c.a))

static func add_shading(img: Image, light_dir: Vector2 = Vector2(0.3, -0.7)) -> void:
	var width = img.get_width()
	var height = img.get_height()
	for x in range(width):
		for y in range(height):
			var c = img.get_pixel(x, y)
			if c.a > 0:
				var nx = (x - width / 2.0) / (width / 2.0)
				var ny = (y - height / 2.0) / (height / 2.0)
				var dot = nx * light_dir.x + ny * light_dir.y
				var shade = clamp(dot * 0.3 + 0.85, 0.7, 1.1)
				img.set_pixel(x, y, Color(c.r * shade, c.g * shade, c.b * shade, c.a))

static func add_outline(img: Image, color: Color = Color(0, 0, 0, 0.5), thickness: int = 1) -> void:
	var width = img.get_width()
	var height = img.get_height()
	var temp = img.duplicate()
	for x in range(width):
		for y in range(height):
			if temp.get_pixel(x, y).a > 0:
				for dx in range(-thickness, thickness + 1):
					for dy in range(-thickness, thickness + 1):
						if dx != 0 or dy != 0:
							var nx = x + dx
							var ny = y + dy
							if nx >= 0 and nx < width and ny >= 0 and ny < height:
								if temp.get_pixel(nx, ny).a == 0:
									img.set_pixel(nx, ny, color)

## ==================== GERADORES DE PERSONAGENS ====================

static func generate_character(skin_idx: int = 0, hair_idx: int = 0, hair_color_idx: int = 0, eye_idx: int = 0, shirt_idx: int = 0, shirt_color_idx: int = 0, pants_idx: int = 0, pants_color_idx: int = 0, shoe_color_idx: int = 0) -> Dictionary:
	var sprites = {}

	# Gera sprites para 4 direções × 4 animações (idle, walk, tool, tool_charge)
	var directions = ["down", "right", "up", "left"]
	var animations = ["idle", "walk", "tool", "tool_charge"]

	for dir in directions:
		for anim in animations:
			var frames = []
			var frame_count = 4 if anim == "walk" else (3 if anim.begins_with("tool") else 1)

			for frame in range(frame_count):
				var img = _draw_character_frame(dir, anim, frame, frame_count, {
					"skin": PALETTES["skin"][skin_idx % PALETTES["skin"].size()],
					"hair": PALETTES["hair"][hair_color_idx % PALETTES["hair"].size()],
					"eye": PALETTES["eye"][eye_idx % PALETTES["eye"].size()],
					"shirt": PALETTES["clothing"][shirt_color_idx % PALETTES["clothing"].size()],
					"pants": PALETTES["clothing"][pants_color_idx % PALETTES["clothing"].size()],
					"shoes": PALETTES["clothing"][shoe_color_idx % PALETTES["clothing"].size()]
				})
				frames.append(img)

			var key = "%s_%s" % [anim, dir]
			sprites[key] = frames

	return sprites

static func _draw_character_frame(direction: String, animation: String, frame: int, frame_count: int, colors: Dictionary) -> Image:
	var img = create_base_image(32, 48)
	var cx = 16
	var cy = 24  # Centro do corpo

	# Cores
	var skin_color = colors["skin"]
	var hair_color = colors["hair"]
	var eye_color = colors["eye"]
	var shirt_color = colors["shirt"]
	var pants_color = colors["pants"]
	var shoes_color = colors["shoes"]

	# Direção
	var facing_right = direction == "right"
	var facing_left = direction == "left"
	var facing_up = direction == "up"
	var facing_down = direction == "down"

	# Frame de animação
	var walk_offset = 0
	var tool_progress = frame / max(frame_count - 1, 1)

	if animation == "walk":
		walk_offset = sin(frame * PI * 2.0 / frame_count) * 2.0
	elif animation.begins_with("tool"):
		walk_offset = sin(tool_progress * PI) * 3.0

	# ===== CORPO =====
	# Pernas
	var leg_x = -2 if facing_right else (2 if facing_left else 0)
	var leg_y = 8 + walk_offset

	# Perna traseira
	var back_leg_x = leg_x + (-1 if facing_right else (1 if facing_left else 0))
	_draw_leg(img, cx + back_leg_x, cy + leg_y, pants_color, shoes_color, false, facing_right)

	# Perna frontal
	_draw_leg(img, cx + leg_x, cy + leg_y, pants_color, shoes_color, true, facing_right)

	# Torso
	_draw_torso(img, cx, cy - 4, shirt_color, skin_color, facing_right)

	# Braços
	var arm_swing = walk_offset * 1.5 if animation == "walk" else (tool_progress * 10.0 if animation.begins_with("tool") else 0)

	# Braço traseiro
	_draw_arm(img, cx - 8, cy - 6, skin_color, shirt_color, -arm_swing, false, facing_right)

	# Braço frontal (com ferramenta se tool)
	if animation.begins_with("tool"):
		_draw_arm_with_tool(img, cx + 8, cy - 6, skin_color, shirt_color, arm_swing, true, facing_right, tool_progress)
	else:
		_draw_arm(img, cx + 8, cy - 6, skin_color, shirt_color, arm_swing, true, facing_right)

	# Cabeça
	_draw_head(img, cx, cy - 16, skin_color, hair_color, eye_color, facing_right, facing_up)

	# Adicionar sombreamento
	add_shading(img)

	return img

static func _draw_leg(img: Image, x: int, y: int, pants_color: Color, shoes_color: Color, front: bool, facing_right: bool) -> void:
	var w = 4 if front else 3
	var h = 10

	# Perna (calça)
	draw_rect(img, x - w/2, y, w, h - 4, pants_color)

	# Sapato
	draw_rect(img, x - w/2 - 1, y + h - 4, w + 2, 4, shoes_color)

static func _draw_torso(img: Image, x: int, y: int, shirt_color: Color, skin_color: Color, facing_right: bool) -> void:
	var w = 10
	var h = 12

	# Corpo (camisa)
	draw_rect(img, x - w/2, y, w, h, shirt_color)

	# Pescoço
	draw_rect(img, x - 2, y - 4, 4, 4, Color(1.0, 0.87, 0.77))

static func _draw_arm(img: Image, x: int, y: int, skin_color: Color, shirt_color: Color, swing: float, front: bool, facing_right: bool) -> void:
	var w = 3
	var h = 10

	# Braço
	draw_rect(img, x - w/2 + int(swing * 0.5), y, w, h, shirt_color)

	# Mão
	draw_rect(img, x - w/2 + int(swing * 0.5), y + h, 5, 4, skin_color)

static func _draw_arm_with_tool(img: Image, x: int, y: int, skin_color: Color, shirt_color: Color, swing: float, front: bool, facing_right: bool, progress: float) -> void:
	_draw_arm(img, x, y, skin_color, Color(0.6, 0.4, 0.2), swing, front, facing_right)

	# Ferramenta
	var tool_x = x + int(swing * 0.5) + (5 if facing_right else -5)
	var tool_y = y + 10 + int(sin(progress * PI) * 3)
	draw_rect(img, tool_x, tool_y, 3, 10, Color(0.5, 0.5, 0.5))

static func _draw_head(img: Image, x: int, y: int, skin_color: Color, hair_color: Color, eye_color: Color, facing_right: bool, facing_up: bool) -> void:
	var head_w = 12
	var head_h = 12

	# Cabelo (topo da cabeça)
	draw_rect(img, x - head_w/2, y - head_h/2 - 2, head_w, head_h/2 + 2, hair_color)

	# Rosto
	draw_rect(img, x - head_w/2, y - head_h/2, head_w, head_h, skin_color)

	# Olhos
	var eye_y = y - 2
	if facing_up:
		eye_y = y - 3
	elif facing_down:
		eye_y = y - 1

	var eye_x = x + (2 if facing_right else -2)
	if not facing_right and not facing_left:
		eye_x = x

	# Olho esquerdo
	draw_pixel(img, x - 3, eye_y, Color(0.1, 0.1, 0.1))
	# Olho direito
	draw_pixel(img, x + 3, eye_y, Color(0.1, 0.1, 0.1))

	# Brilho nos olhos
	draw_pixel(img, x - 2, eye_y - 1, Color(1, 1, 1, 0.5))
	draw_pixel(img, x + 4, eye_y - 1, Color(1, 1, 1, 0.5))

## ==================== GERADORES DE TILES ====================

static func generate_tileset() -> Dictionary:
	var tiles = {}

	# Gramados (com variação)
	for i in range(8):
		tiles["grass_%d" % i] = _draw_grass_tile(i)

	# Terra (seca, molhada, arada)
	for i in range(4):
		tiles["dirt_dry_%d" % i] = _draw_dirt_tile(i, false)
		tiles["dirt_wet_%d" % i] = _draw_dirt_tile(i, true)
		tiles["dirt_tilled_%d" % i] = _draw_tilled_tile(i)

	# Água (animada)
	for i in range(8):
		tiles["water_%d" % i] = _draw_water_tile(i)

	# Caminhos
	for i in range(4):
		tiles["path_%d" % i] = _draw_path_tile(i)

	# Pedras
	for i in range(4):
		tiles["stone_%d" % i] = _draw_stone_tile(i)

	# Areia
	for i in range(4):
		tiles["sand_%d" % i] = _draw_sand_tile(i)

	# Flores/decorações
	for i in range(12):
		tiles["flower_%d" % i] = _draw_flower_tile(i)

	return tiles

static func _draw_grass_tile(variant: int) -> Image:
	var img = create_base_image(TILE_SIZE, TILE_SIZE)
	var rng = RandomNumberGenerator.new()
	rng.seed = variant * 12345

	var colors = PALETTES["terrain"]["grass"]

	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var base_color = colors[rng.randi_range(0, colors.size() - 1)]
			var noise = (rng.randi() % 1000) / 1000.0 * 0.2 - 0.1
			var c = Color(
				clamp(base_color.r + noise, 0, 1),
				clamp(base_color.g + noise, 0, 1),
				clamp(base_color.b + noise, 0, 1),
				1.0
			)
			draw_pixel(img, x, y, c)

	# Adicionar detalhes (flores ocasionais)
	if variant % 3 == 0:
		for i in range(3):
			var fx = randi_range(2, 13)
			var fy = randi_range(2, 13)
			var flower_color = [Color(1,0.5,0.5), Color(1,1,0.5), Color(0.5,1,0.5), Color(1,0.5,1)].pick_random()
			draw_rect(img, fx, fy, 2, 2, flower_color)

	add_shading(img)
	return img

static func _draw_dirt_tile(variant: int, wet: bool) -> Image:
	var img = create_base_image(TILE_SIZE, TILE_SIZE)
	var rng = RandomNumberGenerator.new()
	rng.seed = variant * 54321 + (10000 if wet else 0)

	var colors = [
		Color(0.3, 0.2, 0.15),
		Color(0.35, 0.25, 0.18),
		Color(0.4, 0.3, 0.2)
	] if wet else [
		Color(0.5, 0.35, 0.25),
		Color(0.55, 0.4, 0.3),
		Color(0.6, 0.45, 0.35)
	]

	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var base_color = colors[rng.randi_range(0, colors.size() - 1)]
			var noise = (rng.randi() % 1000) / 1000.0 * 0.15 - 0.075
			var c = Color(
				clamp(base_color.r + noise, 0, 1),
				clamp(base_color.g + noise, 0, 1),
				clamp(base_color.b + noise, 0, 1),
				1.0
			)
			draw_pixel(img, x, y, c)

	if wet:
		# Reflexos de água
		for i in range(20):
			var x = rng.randi_range(0, 15)
			var y = rng.randi_range(0, 15)
			draw_pixel(img, x, y, Color(0.3, 0.5, 0.9, 0.6))

	add_shading(img)
	return img

static func _draw_tilled_tile(variant: int) -> Image:
	var img = _draw_dirt_tile(variant, false)

	# Linhas de arado
	for x in range(2, 14, 3):
		for y in range(TILE_SIZE):
			var c = img.get_pixel(x, y)
			if c.a > 0:
				img.set_pixel(x, y, Color(c.r * 0.7, c.g * 0.7, c.b * 0.7, c.a))

	return img

static func _draw_water_tile(frame: int) -> Image:
	var img = create_base_image(TILE_SIZE, TILE_SIZE)
	var t = frame / 8.0 * TAU

	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var dx = (x - 7.5) / 8.0
			var dy = (y - 7.5) / 8.0
			var dist = sqrt(dx*dx + dy*dy)

			var wave = sin(dist * 10.0 - t * 3.0) * 0.5
			var depth = clamp(1.0 - dist * 0.7 + wave * 0.1, 0.0, 1.0)

			var c = Color(
				0.1 * depth,
				0.3 * depth,
				0.8 * depth,
				depth
			)

			# Reflexo
			if dist < 0.3:
				var sparkle = sin((x + y) * 2.0 + t * 5.0)
				if sparkle > 0.7:
					c = Color(0.8, 0.9, 1.0, 1.0)

			draw_pixel(img, x, y, c)

	return img

static func _draw_path_tile(variant: int) -> Image:
	var img = create_base_image(TILE_SIZE, TILE_SIZE)
	var rng = RandomNumberGenerator.new()
	rng.seed = variant * 9999

	var colors = [
		Color(0.6, 0.5, 0.4),
		Color(0.65, 0.55, 0.45),
		Color(0.55, 0.45, 0.35)
	]

	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var base_color = colors[rng.randi_range(0, colors.size() - 1)]
			var noise = (rng.randi() % 1000) / 1000.0 * 0.1
			var c = Color(
				clamp(base_color.r + noise, 0, 1),
				clamp(base_color.g + noise, 0, 1),
				clamp(base_color.b + noise, 0, 1),
				1.0
			)
			draw_pixel(img, x, y, c)

	# Linhas do caminho
	for x in range(4, 12):
		draw_pixel(img, x, 4, Color(0.5, 0.4, 0.3, 0.5))
		draw_pixel(img, x, 11, Color(0.5, 0.4, 0.3, 0.5))

	return img

static func _draw_stone_tile(variant: int) -> Image:
	var img = create_base_image(TILE_SIZE, TILE_SIZE)
	var rng = RandomNumberGenerator.new()
	rng.seed = variant * 1111

	var colors = [
		Color(0.45, 0.45, 0.45),
		Color(0.5, 0.5, 0.5),
		Color(0.4, 0.4, 0.4),
		Color(0.55, 0.55, 0.55)
	]

	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var base_color = colors[rng.randi_range(0, colors.size() - 1)]
			var noise = (rng.randi() % 1000) / 1000.0 * 0.1
			var c = Color(
				clamp(base_color.r + noise, 0, 1),
				clamp(base_color.g + noise, 0, 1),
				clamp(base_color.b + noise, 0, 1),
				1.0
			)
			draw_pixel(img, x, y, c)

	# Rachaduras
	if variant > 0:
		for i in range(variant * 2):
			var x = rng.randi_range(0, 15)
			var y = rng.randi_range(0, 15)
			draw_rect(img, x, y, 1, rng.randi_range(3, 8), Color(0.2, 0.2, 0.2, 0.8))

	add_shading(img)
	return img

static func _draw_sand_tile(variant: int) -> Image:
	var img = create_base_image(TILE_SIZE, TILE_SIZE)
	var rng = RandomNumberGenerator.new()
	rng.seed = variant * 2222

	var colors = [
		Color(0.85, 0.75, 0.55),
		Color(0.9, 0.8, 0.6),
		Color(0.8, 0.7, 0.5),
		Color(0.95, 0.85, 0.65)
	]

	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var base_color = colors[rng.randi_range(0, colors.size() - 1)]
			var noise = (rng.randi() % 1000) / 1000.0 * 0.1
			var c = Color(
				clamp(base_color.r + noise, 0, 1),
				clamp(base_color.g + noise, 0, 1),
				clamp(base_color.b + noise, 0, 1),
				1.0
			)
			draw_pixel(img, x, y, c)

	# Conchas
	if variant > 1:
		for i in range(2):
			var x = rng.randi_range(2, 13)
			var y = rng.randi_range(2, 13)
			draw_rect(img, x, y, 3, 2, Color(0.9, 0.85, 0.8, 0.8))

	return img

static func _draw_flower_tile(variant: int) -> Image:
	var img = create_base_image(TILE_SIZE, TILE_SIZE)

	# Grama base
	var grass = _draw_grass_tile(variant % 8)
	for x in range(TILE_SIZE):
		for y in range(TILE_SIZE):
			var c = grass.get_pixel(x, y)
			img.set_pixel(x, y, c)

	# Flores
	var flower_types = [
		{ "color": Color(1.0, 0.4, 0.4), "shape": "tulip" },      # Vermelho
		{ "color": Color(1.0, 0.8, 0.3), "shape": "sunflower" }, # Amarelo
		{ "color": Color(0.8, 0.4, 1.0), "shape": "rose" },      # Roxo
		{ "color": Color(0.5, 0.8, 1.0), "shape": "forget" },    # Azul
		{ "color": Color(1.0, 0.6, 0.8), "shape": "cosmos" },    # Rosa
		{ "color": Color(1.0, 1.0, 0.5), "shape": "daisy" },     # Branco/Amarelo
	]

	var flower = flower_types[variant % flower_types.size()]
	var color = flower["color"]
	var cx = 8
	var cy = 10

	if flower["shape"] == "tulip":
		# Tulipa
		draw_rect(img, cx - 2, cy - 6, 4, 8, color)
		draw_rect(img, cx - 1, cy - 8, 2, 4, Color(0.3, 0.6, 0.2)) # Caule
	elif flower["shape"] == "sunflower":
		# Girassol
		draw_circle(img, cx, cy - 2, 5, color)
		draw_circle(img, cx, cy - 2, 3, Color(0.8, 0.6, 0.1))
		draw_rect(img, cx - 1, cy + 3, 2, 6, Color(0.3, 0.6, 0.2))
	elif flower["shape"] == "rose":
		# Rosa
		for i in range(3):
			draw_circle(img, cx + randi_range(-2, 2), cy - 2 + randi_range(-2, 2), 3, color)
		draw_rect(img, cx - 1, cy + 2, 2, 5, Color(0.3, 0.6, 0.2))
	elif flower["shape"] == "forget":
		# Não-me-esqueças
		for i in range(5):
			var angle = i * TAU / 5.0
			var px = cx + cos(angle) * 4
			var py = cy - 2 + sin(angle) * 4
			draw_circle(img, px, py, 2, color)
		draw_rect(img, cx - 1, cy + 2, 2, 4, Color(0.3, 0.6, 0.2))
	elif flower["shape"] == "cosmos":
		# Cosmos
		for i in range(8):
			var angle = i * TAU / 8.0
			var px = cx + cos(angle) * 5
			var py = cy - 2 + sin(angle) * 5
			draw_circle(img, px, py, 2, color)
		draw_rect(img, cx - 1, cy + 3, 2, 5, Color(0.3, 0.6, 0.2))
	elif flower["shape"] == "daisy":
		# Margarida
		draw_circle(img, cx, cy - 2, 6, Color(1, 1, 0.9))
		draw_circle(img, cx, cy - 2, 3, Color(1, 0.9, 0.3))
		draw_rect(img, cx - 1, cy + 4, 2, 4, Color(0.3, 0.6, 0.2))

	return img

## ==================== GERADORES DE CULTURAS ====================

static func generate_crop_sprites(crop_name: String) -> Dictionary:
	var sprites = {}
	var crop_data = _get_crop_data(crop_name)

	var phases = crop_data.get("phases", 5)
	var colors = crop_data.get("colors", PALETTES["crops"]["vegetable"])
	var regrows = crop_data.get("regrows", false)

	for phase in range(phases + 1): # +1 para fase "ready"
		var frame_key = "phase_%d" % phase if phase < phases else "ready"
		sprites[frame_key] = _draw_crop_phase(crop_name, phase, phases, colors, regrows)

	# Fase morta
	sprites["dead"] = _draw_dead_crop(crop_name)

	return sprites

static func _get_crop_data(name: String) -> Dictionary:
	var crops = {
		"parsnip": { "phases": 4, "colors": PALETTES["crops"]["vegetable"], "regrows": false },
		"potato": { "phases": 5, "colors": PALETTES["crops"]["vegetable"], "regrows": false },
		"cauliflower": { "phases": 5, "colors": PALETTES["crops"]["vegetable"], "regrows": false },
		"wheat": { "phases": 4, "colors": PALETTES["crops"]["wheat"], "regrows": false },
		"corn": { "phases": 5, "colors": PALETTES["crops"]["wheat"], "regrows": false },
		"tomato": { "phases": 5, "colors": PALETTES["crops"]["fruit"], "regrows": true },
		"blueberry": { "phases": 5, "colors": PALETTES["crops"]["fruit"], "regrows": true },
		"strawberry": { "phases": 4, "colors": PALETTES["crops"]["fruit"], "regrows": true },
		"melon": { "phases": 6, "colors": PALETTES["crops"]["fruit"], "regrows": false },
		"pumpkin": { "phases": 6, "colors": [Color(1.0, 0.5, 0.1), Color(1.0, 0.6, 0.2)], "regrows": false },
		"flower": { "phases": 4, "colors": PALETTES["crops"]["flower"], "regrows": true }
	}
	return crops.get(name, crops["parsnip"])

static func _draw_crop_phase(name: String, phase: int, total_phases: int, colors: Array, regrows: bool) -> Image:
	var img = create_base_image(32, 32)
	var progress = phase / float(total_phases)

	var crop_colors = colors
	var base_color = crop_colors[0]
	var accent_color = crop_colors[1] if crop_colors.size() > 1 else crop_colors[0]

	if phase == 0:
		# Recém plantado - terra revolvida + broto
		var dirt = _draw_dirt_tile(0, false)
		for x in range(32):
			for y in range(32):
				img.set_pixel(x, y, dirt.get_pixel(x, y))

		# Broto pequeno
		draw_rect(img, 14, 20, 4, 4, Color(0.3, 0.7, 0.3))
		draw_rect(img, 15, 18, 2, 4, Color(0.2, 0.6, 0.2))

	elif phase < total_phases - 1:
		# Crescendo
		var h = 6 + int(progress * 18)
		var w = 8 + int(progress * 10)

		# Folhas
		for i in range(h):
			var leaf_w = int(w * (1.0 - i / float(h)) * 0.8)
			draw_rect(img, 16 - leaf_w/2, 32 - 6 - i, leaf_w, 2, colors[0])

		# Caule central
		draw_rect(img, 15, 32 - h - 2, 2, h + 2, accent_color)

	else:
		# Pronto para colher
		var crop_data = _get_crop_data(name)

		if name == "wheat" or name == "corn":
			# Grãos
			for i in range(12):
				var angle = i * TAU / 12.0
				var x = 16 + cos(angle) * 10
				var y = 16 + sin(angle) * 8
				draw_rect(img, x - 1, y - 3, 3, 5, Color(0.9, 0.8, 0.3))

		elif name == "tomato" or name == "strawberry":
			# Frutas vermelhas
			for i in range(6):
				var angle = i * TAU / 6.0
				var x = 16 + cos(angle) * 8
				var y = 16 + sin(angle) * 8
				draw_circle(img, x, y, 4, Color(0.9, 0.2, 0.2))

		elif name == "blueberry":
			# Mirtilos
			for i in range(10):
				var x = 16 + randi_range(-10, 10)
				var y = 16 + randi_range(-10, 10)
				draw_circle(img, x, y, 3, Color(0.3, 0.4, 0.9))

		elif name == "pumpkin":
			# Abóbora grande
			draw_circle(img, 16, 18, 12, Color(1.0, 0.55, 0.1))
			draw_rect(img, 15, 6, 2, 8, Color(0.3, 0.6, 0.2)) # Caule

		elif name == "flower":
			# Flor
			for i in range(8):
				var angle = i * TAU / 8.0
				var x = 16 + cos(angle) * 8
				var y = 16 + sin(angle) * 8
				draw_circle(img, x, y, 4, colors[i % colors.size()])
			draw_circle(img, 16, 16, 3, Color(1.0, 0.9, 0.3))

	add_shading(img)
	return img

static func _draw_dead_crop(name: String) -> Image:
	var img = create_base_image(32, 32)

	# Terra seca
	var dirt = _draw_dirt_tile(0, false)
	for x in range(32):
		for y in range(32):
			img.set_pixel(x, y, dirt.get_pixel(x, y))

	# Planta morta (marrom)
	draw_rect(img, 14, 16, 4, 10, Color(0.4, 0.25, 0.15))
	draw_rect(img, 13, 20, 6, 2, Color(0.35, 0.2, 0.1))
	draw_rect(img, 12, 22, 8, 2, Color(0.35, 0.2, 0.1))

	# Partículas de poeira
	for i in range(5):
		var x = randi_range(10, 22)
		var y = randi_range(20, 30)
		draw_rect(img, x, y, 1, 1, Color(0.5, 0.4, 0.3, 0.6))

	return img

## ==================== GERADORES DE ANIMAIS ====================

static func generate_animal_sprites(animal_type: String) -> Dictionary:
	var sprites = {}
	var animal_data = _get_animal_data(animal_type)
	var colors = animal_data["colors"]
	var size = animal_data["size"]

	var directions = ["down", "right", "up", "left"]
	var states = ["idle", "walk", "eat", "sleep", "happy"]

	for dir in directions:
		for state in states:
			var frames = []
			var frame_count = 4 if state == "walk" else (2 if state == "eat" else 1)

			for frame in range(frame_count):
				var img = _draw_animal_frame(animal_type, dir, state, frame, frame_count, colors, size)
				frames.append(img)

			sprites["%s_%s" % [state, dir]] = frames

	return sprites

static func _get_animal_data(type: String) -> Dictionary:
	return {
		"chicken": { "colors": [Color(1,1,1), Color(0.9,0.8,0.7)], "size": Vector2i(24, 20) },
		"cow": { "colors": [Color(0.9,0.9,0.9), Color(0.3,0.3,0.3)], "size": Vector2i(48, 36) },
		"goat": { "colors": [Color(0.8,0.7,0.6), Color(0.5,0.4,0.3)], "size": Vector2i(40, 32) },
		"sheep": { "colors": [Color(0.95,0.95,0.9), Color(0.8,0.8,0.7)], "size": Vector2i(40, 36) },
		"pig": { "colors": [Color(1.0, 0.7, 0.75), Color(0.9, 0.5, 0.5)], "size": Vector2i(44, 28) },
		"rabbit": { "colors": [Color(0.9,0.9,0.9), Color(0.6,0.5,0.5)], "size": Vector2i(28, 24) },
		"duck": { "colors": [Color(1,1,0.8), Color(1,0.9,0.5)], "size": Vector2i(28, 24) },
		"dinosaur": { "colors": [Color(0.3, 0.6, 0.3), Color(0.2, 0.5, 0.2)], "size": Vector2i(56, 40) }
	}.get(type, { "colors": [Color(1,1,1)], "size": Vector2i(32, 24) })

static func _draw_animal_frame(type: String, direction: String, state: String, frame: int, frame_count: int, colors: Array, size: Vector2i) -> Image:
	var img = create_base_image(size.x, size.y)
	var cx = size.x / 2
	var cy = size.y / 2
	var main_color = colors[0]
	var accent_color = colors[1] if colors.size() > 1 else colors[0]

	var facing_right = direction == "right"
	var facing_left = direction == "left"

	var walk_offset = sin(frame * PI * 2.0 / frame_count) * 2.0 if state == "walk" else 0

	if type == "chicken" or type == "duck":
		_draw_bird(img, cx, cy, main_color, accent_color, state, walk_offset, facing_right)
	elif type == "cow" or type == "goat":
		_draw_quadruped(img, cx, cy, main_color, accent_color, state, walk_offset, facing_right, type == "cow")
	elif type == "sheep":
		_draw_sheep(img, cx, cy, main_color, accent_color, state, walk_offset, facing_right)
	elif type == "pig":
		_draw_pig(img, cx, cy, main_color, accent_color, state, walk_offset, facing_right)
	else:
		_draw_generic_animal(img, cx, cy, main_color, accent_color, state, walk_offset, facing_right)

	return img

static func _draw_bird(img: Image, cx: int, cy: int, main: Color, accent: Color, state: String, walk: float, right: bool) -> void:
	var body_w = 16
	var body_h = 12

	# Corpo
	draw_rect(img, cx - body_w/2, cy - body_h/2, body_w, body_h, main)

	# Cabeça
	var head_x = cx + (10 if right else -10) + int(walk * 0.5)
	var head_y = cy - 10
	draw_rect(img, head_x - 5, head_y - 5, 10, 10, main)

	# Bico
	var beak_x = head_x + (5 if right else -5)
	draw_rect(img, beak_x, head_y, 4, 3, Color(1.0, 0.6, 0.2))

	# Olho
	draw_pixel(img, head_x + (2 if right else -2), head_y - 1, Color(0.1, 0.1, 0.1))

	# Asa
	var wing_y = cy + (-2 if state == "eat" else 0)
	draw_rect(img, cx + (-6 if right else 2), wing_y, 8, 4, main.lightened(0.1))

	# Perna(s)
	if state == "walk":
		var leg_offset = sin(walk * 2.0) * 3
		draw_rect(img, cx - 3, cy + 6 + leg_offset, 2, 8, Color(1.0, 0.7, 0.3))
		draw_rect(img, cx + 1, cy + 6 - leg_offset, 2, 8, Color(1.0, 0.7, 0.3))
	else:
		draw_rect(img, cx - 3, cy + 6, 2, 8, Color(1.0, 0.7, 0.3))
		draw_rect(img, cx + 1, cy + 6, 2, 8, Color(1.0, 0.7, 0.3))

static func _draw_quadruped(img: Image, cx: int, cy: int, main: Color, accent: Color, state: String, walk: float, right: bool, is_cow: bool) -> void:
	var body_w = 28
	var body_h = 16
	var leg_h = 10

	# Corpo
	draw_rect(img, cx - 14, cy - 8, 28, 16, main)

	# Cabeça
	var head_x = cx + (18 if right else -18)
	var head_y = cy - 6
	draw_rect(img, head_x - 8, head_y - 6, 16, 12, main)

	# Orelhas
	draw_rect(img, head_x - 6, head_y - 10, 4, 6, main)
	draw_rect(img, head_x + 2, head_y - 10, 4, 6, main)

	# Chifres (vaca)
	if is_cow:
		draw_rect(img, head_x - 5, head_y - 14, 2, 8, Color(0.9, 0.9, 0.9))
		draw_rect(img, head_x + 3, head_y - 14, 2, 8, Color(0.9, 0.9, 0.9))

	# Focinho
	draw_rect(img, head_x + 6, head_y + 1, 4, 4, Color(0.9, 0.7, 0.7))

	# Olhos
	draw_pixel(img, head_x - 2, head_y - 1, Color(0.1, 0.1, 0.1))
	draw_pixel(img, head_x + 4, head_y - 1, Color(0.1, 0.1, 0.1))

	# Chifres/barba (cabra)
	if not is_cow:
		draw_rect(img, head_x + 8, head_y + 2, 2, 6, Color(0.7, 0.6, 0.5)) # Barba

	# Corpo principal
	draw_rect(img, cx - 14, cy - 8, 28, 16, main)

	# Manchas (vaca)
	if is_cow:
		for i in range(4):
			var sx = cx - 12 + randi_range(0, 24)
			var sy = cy - 6 + randi_range(0, 12)
			draw_rect(img, sx, sy, randi_range(3, 8), randi_range(2, 5), accent)

	# Uber (vaca)
	if is_cow:
		draw_rect(img, cx - 4, cy + 8, 8, 4, Color(0.9, 0.8, 0.7))

	# Pernas
	var walk_cycle = sin(0) # Será passado como parâmetro
	# Pernas traseiras
	draw_rect(img, cx - 10, cy + 8, 4, 10, Color(0.3, 0.2, 0.15))
	draw_rect(img, cx + 6, cy + 8, 4, 10, Color(0.3, 0.2, 0.15))
	# Pernas dianteiras
	draw_rect(img, cx - 12, cy + 8, 4, 10, Color(0.3, 0.2, 0.15))
	draw_rect(img, cx + 8, cy + 8, 4, 10, Color(0.3, 0.2, 0.15))

	# Cascos
	draw_rect(img, cx - 13, cy + 18, 6, 3, Color(0.2, 0.15, 0.1))
	draw_rect(img, cx + 7, cy + 18, 6, 3, Color(0.2, 0.15, 0.1))
	draw_rect(img, cx - 13, cy + 18, 6, 3, Color(0.2, 0.15, 0.1))
	draw_rect(img, cx + 7, cy + 18, 6, 3, Color(0.2, 0.15, 0.1))

	# Rabo
	draw_rect(img, cx + 14, cy - 2, 6, 12, main)
	draw_rect(img, cx + 18, cy, 4, 4, Color(0.5, 0.4, 0.3)) # Ponta do rabo

static func _draw_sheep(img: Image, cx: int, cy: int, main: Color, accent: Color, state: String, walk: float, right: bool) -> void:
	# Corpo fofo (lã)
	for i in range(3):
		draw_circle(img, cx + randi_range(-10, 10), cy + randi_range(-6, 6), 12, main.lightened(0.1))

	# Cabeça
	draw_rect(img, cx - 8, cy - 20, 16, 12, Color(0.4, 0.3, 0.2))
	draw_rect(img, cx - 4, cy - 16, 8, 4, Color(0.9, 0.8, 0.7)) # Focinho

	# Olhos
	draw_pixel(img, cx - 4, cy - 12, Color(0.1, 0.1, 0.1))
	draw_pixel(img, cx + 4, cy - 12, Color(0.1, 0.1, 0.1))

	# Orelhas
	draw_rect(img, cx - 10, cy - 24, 4, 8, Color(0.4, 0.3, 0.2))
	draw_rect(img, cx + 6, cy - 24, 4, 8, Color(0.4, 0.3, 0.2))

	# Pernas finas
	draw_rect(img, cx - 6, cy + 10, 3, 10, Color(0.3, 0.2, 0.15))
	draw_rect(img, cx - 2, cy + 10, 3, 10, Color(0.3, 0.2, 0.15))
	draw_rect(img, cx + 2, cy + 10, 3, 10, Color(0.3, 0.2, 0.15))
	draw_rect(img, cx + 6, cy + 10, 3, 10, Color(0.3, 0.2, 0.15))

static func _draw_pig(img: Image, cx: int, cy: int, main: Color, accent: Color, state: String, walk: float, right: bool) -> void:
	# Corpo redondo
	draw_circle(img, cx, cy, 18, main)

	# Focinho grande
	draw_rect(img, cx - 8, cy + 4, 16, 8, Color(1.0, 0.7, 0.7))
	draw_circle(img, cx, cy + 8, 4, Color(0.9, 0.5, 0.5)) # Nariz

	# Olhos
	draw_pixel(img, cx - 5, cy - 4, Color(0.1, 0.1, 0.1))
	draw_pixel(img, cx + 5, cy - 4, Color(0.1, 0.1, 0.1))

	# Orelhas caídas
	draw_rect(img, cx - 14, cy - 14, 6, 10, main)
	draw_rect(img, cx + 8, cy - 14, 6, 10, main)

	# Rabo espiral
	for i in range(3):
		var angle = i * 2.0
		var x = cx + 18 + cos(angle) * 4
		var y = cy + 4 + sin(angle) * 4
		draw_circle(img, x, y, 3 - i, main)

	# Pernas curtas
	draw_rect(img, cx - 10, cy + 16, 4, 8, Color(0.3, 0.2, 0.15))
	draw_rect(img, cx + 6, cy + 16, 4, 8, Color(0.3, 0.2, 0.15))

static func _draw_generic_animal(img: Image, cx: int, cy: int, main: Color, accent: Color, state: String, walk: float, right: bool) -> void:
	draw_circle(img, cx, cy, 16, main)
	draw_rect(img, cx - 4, cy - 8, 8, 8, main) # Cabeça
	draw_pixel(img, cx - 3, cy - 4, Color(0.1, 0.1, 0.1))
	draw_pixel(img, cx + 3, cy - 4, Color(0.1, 0.1, 0.1))
	draw_rect(img, cx - 8, cy + 8, 4, 10, Color(0.3, 0.2, 0.15))
	draw_rect(img, cx + 4, cy + 8, 4, 10, Color(0.3, 0.2, 0.15))

## ==================== EXPORTAÇÃO PARA GODOT ====================

static func save_sprites_as_tres(sprites: Dictionary, path: String) -> void:
	var sprite_frames = SpriteFrames.new()

	for anim_name in sprites:
		var frames = sprites[anim_name]
		sprite_frames.add_animation(anim_name)
		for i in range(frames.size()):
			var frame_img = frames[i]
			var texture = ImageTexture.create_from_image(frame_img)
			sprite_frames.set_frame_texture(anim_name, i, texture)
			sprite_frames.set_frame_duration(anim_name, i, 0.15)
		sprite_frames.set_animation_loop(anim_name, true)

	ResourceSaver.save(sprite_frames, path)

static func generate_all_assets() -> void:
	# Gera todos os assets do jogo
	print("Gerando assets visuais...")

	# Personagens
	var player_sprites = generate_character()
	save_sprites_as_tres(player_sprites, "res://resources/sprites/player_sprites.tres")

	# NPCs (cada um com aparência única)
	var npcs = ["abigail", "alex", "elliott", "emily", "haley", "harvey", "leah", "maru", "penny", "sam", "sebastian", "shane"]
	for npc in npcs:
		var skin = randi_range(0, 5)
		var hair = randi_range(0, 12)
		var hair_c = randi_range(0, 12)
		var eye = randi_range(0, 5)
		var shirt = randi_range(0, 15)
		var shirt_c = randi_range(0, 15)
		var pants = randi_range(0, 15)
		var pants_c = randi_range(0, 15)
		var shoe_c = randi_range(0, 15)

		var npc_sprites = generate_character(skin, hair, hair_c, eye, shirt, shirt_c, pants, pants_c, shoe_c)
		save_sprites_as_tres(npc_sprites, "res://resources/sprites/npc_%s_sprites.tres" % npc)

	# Tiles
	var tiles = generate_tileset()
	# Salva como TileSet resource

	# Culturas
	var crops = ["parsnip", "potato", "cauliflower", "wheat", "corn", "tomato", "blueberry", "strawberry", "melon", "pumpkin", "flower"]
	for crop in crops:
		var crop_sprites = generate_crop_sprites(crop)
		save_sprites_as_tres(crop_sprites, "res://resources/sprites/crop_%s.tres" % crop)

	# Animais
	var animals = ["chicken", "cow", "goat", "sheep", "pig", "rabbit", "duck", "dinosaur"]
	for animal in animals:
		var animal_sprites = generate_animal_sprites(animal)
		save_sprites_as_tres(animal_sprites, "res://resources/sprites/animal_%s.tres" % animal)

	print("Todos os assets gerados com sucesso!")