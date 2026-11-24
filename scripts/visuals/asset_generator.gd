class_name AssetGenerator
extends RefCounted

## Script para gerar todos os assets visuais do jogo de uma vez
## Execute uma vez para gerar todos os .tres

## ==================== GERAÇÃO COMPLETA ====================

static func generate_all_assets() -> void:
	print("=== INICIANDO GERAÇÃO DE TODOS OS ASSETS ===")

	# 1. Player
	print("Gerando player...")
	var player_sprites = SpriteGenerator.generate_character(
		0, 0, 0, 0, 0, 0, 0, 0, 0  # Valores padrão
	)
	SpriteGenerator.save_sprites_as_tres(player_sprites, "res://resources/sprites/player_sprites.tres")

	# 2. NPCs principais (12 personagens)
	var npcs = [
		{"name": "abigail", "skin": 2, "hair": 6, "hair_c": 7, "eye": 2, "shirt": 3, "shirt_c": 8, "pants": 2, "pants_c": 5, "shoe_c": 4},
		{"name": "alex", "skin": 1, "hair": 2, "hair_c": 1, "eye": 0, "shirt": 0, "shirt_c": 0, "pants": 1, "pants_c": 1, "shoe_c": 2},
		{"name": "elliott", "skin": 1, "hair": 3, "hair_c": 6, "eye": 3, "shirt": 2, "shirt_c": 6, "pants": 3, "pants_c": 4, "shoe_c": 3},
		{"name": "emily", "skin": 0, "hair": 7, "hair_c": 8, "eye": 2, "shirt": 4, "shirt_c": 4, "pants": 4, "pants_c": 6, "shoe_c": 5},
		{"name": "haley", "skin": 0, "hair": 5, "hair_c": 6, "eye": 3, "shirt": 1, "shirt_c": 1, "pants": 0, "pants_c": 0, "shoe_c": 1},
		{"name": "harvey", "skin": 1, "hair": 2, "hair_c": 2, "eye": 1, "shirt": 3, "shirt_c": 3, "pants": 2, "pants_c": 2, "shoe_c": 2},
		{"name": "leah", "skin": 2, "hair": 4, "hair_c": 9, "eye": 2, "shirt": 5, "shirt_c": 5, "pants": 5, "pants_c": 7, "shoe_c": 6},
		{"name": "maru", "skin": 1, "hair": 1, "hair_c": 1, "eye": 1, "shirt": 4, "shirt_c": 7, "pants": 3, "pants_c": 3, "shoe_c": 4},
		{"name": "penny", "skin": 1, "hair": 4, "hair_c": 4, "eye": 2, "shirt": 2, "shirt_c": 2, "pants": 1, "pants_c": 1, "shoe_c": 2},
		{"name": "sam", "skin": 0, "hair": 1, "hair_c": 5, "eye": 0, "shirt": 0, "shirt_c": 4, "pants": 0, "pants_c": 4, "shoe_c": 0},
		{"name": "sebastian", "skin": 2, "hair": 0, "hair_c": 0, "eye": 5, "shirt": 6, "shirt_c": 6, "pants": 6, "pants_c": 6, "shoe_c": 6},
		{"name": "shane", "skin": 1, "hair": 2, "hair_c": 2, "eye": 1, "shirt": 3, "shirt_c": 2, "pants": 2, "pants_c": 2, "shoe_c": 2}
	}

	for npc in npcs:
		print("Gerando NPC: %s" % npc["name"])
		var sprites = SpriteGenerator.generate_character(
			npc["skin"], npc["hair"], npc["hair_c"], npc["eye"],
			npc["shirt"], npc["shirt_c"], npc["pants"], npc["pants_c"], npc["shoe_c"]
		)
		SpriteGenerator.save_sprites_as_tres(sprites, "res://resources/sprites/npc_%s_sprites.tres" % npc["name"])

	# 3. Tileset detalhado
	print("Gerando tileset detalhado...")
	_generate_detailed_tileset()

	# 4. Culturas (11 tipos)
	var crops = ["parsnip", "potato", "cauliflower", "wheat", "corn", "tomato", "blueberry", "strawberry", "melon", "pumpkin", "flower"]
	for crop in crops:
		print("Gerando cultura: %s" % crop)
		var sprites = SpriteGenerator.generate_crop_sprites(crop)
		SpriteGenerator.save_sprites_as_tres(sprites, "res://resources/sprites/crop_%s.tres" % crop)

	# 5. Animais (8 tipos)
	var animals = ["chicken", "cow", "goat", "sheep", "pig", "rabbit", "duck", "dinosaur"]
	for animal in animals:
		print("Gerando animal: %s" % animal)
		var sprites = SpriteGenerator.generate_animal_sprites(animal)
		SpriteGenerator.save_sprites_as_tres(sprites, "res://resources/sprites/animal_%s.tres" % animal)

	# 5. NPCs adicionais (villagers extras)
	var extra_npcs = ["caroline", "clint", "demetrius", "dwarf", "evelyn", "george", "gus", "jas", "jodi", "kent", "krobus", "leah", "lewis", "linus", "marnie", "pam", "pierre", "robin", "sandy", "vincent", "willy", "wizard"]
	for npc in extra_npcs:
		print("Gerando NPC extra: %s" % npc)
		var skin = randi_range(0, 5)
		var hair = randi_range(0, 12)
		var hair_c = randi_range(0, 12)
		var eye = randi_range(0, 5)
		var shirt = randi_range(0, 15)
		var shirt_c = randi_range(0, 15)
		var pants = randi_range(0, 15)
		var pants_c = randi_range(0, 15)
		var shoe_c = randi_range(0, 15)

		var sprites = SpriteGenerator.generate_character(skin, hair, hair_c, eye, shirt, shirt_c, pants, pants_c, shoe_c)
		SpriteGenerator.save_sprites_as_tres(sprites, "res://resources/sprites/npc_%s_sprites.tres" % npc)

	# 6. Móveis/decorações
	_generate_furniture_sprites()

	# 7. Ferramentas
	_generate_tool_sprites()

	# 8. Itens de inventário
	_generate_item_icons()

	print("=== TODOS OS ASSETS GERADOS COM SUCESSO! ===")

static func _generate_detailed_tileset() -> void:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)

	# Gera textura atlas grande
	var tiles = SpriteGenerator.generate_tileset()
	var atlas_size = 512
	var atlas = Image.create(atlas_size, atlas_size, false, Image.FORMAT_RGBA8)
	atlas.fill(Color(0, 0, 0, 0))

	var tile_idx = 0
	var cols = atlas_size / 16

	for tile_name in tiles:
		var tile_img = tiles[tile_name]
		var col = tile_idx % cols
		var row = tile_idx / cols
		var x = col * 16
		var y = row * 16

		# Copia para atlas
		for tx in range(16):
			for ty in range(16):
				var c = tile_img.get_pixel(tx, ty)
				if c.a > 0:
					atlas.set_pixel(x + tx, y + ty, c)

		# Cria tile no TileSet
		var tile_id = tileset.create_tile(0)
		tileset.set_tile_texture(tile_id, 0, ImageTexture.create_from_image(tile_img))
		tileset.set_tile_name(tile_id, tile_name)

		tile_idx += 1

	# Salva atlas
	var atlas_tex = ImageTexture.create_from_image(atlas)
	ResourceSaver.save(atlas_tex, "res://resources/tilesets/farm_atlas.png")
	tileset.set_tile_texture(0, 0, load("res://resources/tilesets/farm_atlas.png"))

	ResourceSaver.save(tileset, "res://resources/tilesets/farm_tileset_detailed.tres")
	print("Tileset detalhado salvo!")

static func _generate_furniture_sprites() -> void:
	var furniture = {
		"chair": { "colors": [Color(0.5, 0.35, 0.2), Color(0.4, 0.25, 0.15)], "size": Vector2i(32, 32) },
		"table": { "colors": [Color(0.5, 0.35, 0.2), Color(0.4, 0.25, 0.15)], "size": Vector2i(48, 32) },
		"bed": { "colors": [Color(0.6, 0.4, 0.3), Color(0.9, 0.8, 0.7)], "size": Vector2i(64, 48) },
		"chest": { "colors": [Color(0.5, 0.35, 0.2), Color(0.8, 0.7, 0.6)], "size": Vector2i(32, 24) },
		"fridge": { "colors": [Color(0.9, 0.9, 0.9), Color(0.7, 0.7, 0.7)], "size": Vector2i(32, 48) },
		"tv": { "colors": [Color(0.1, 0.1, 0.1), Color(0.3, 0.3, 0.3)], "size": Vector2i(32, 24) },
		"sofa": { "colors": [Color(0.5, 0.3, 0.2), Color(0.7, 0.6, 0.5)], "size": Vector2i(64, 32) },
		"bookcase": { "colors": [Color(0.4, 0.3, 0.2), Color(0.6, 0.5, 0.4)], "size": Vector2i(48, 64) },
		"dresser": { "colors": [Color(0.5, 0.35, 0.2), Color(0.6, 0.4, 0.3)], "size": Vector2i(48, 40) },
		"desk": { "colors": [Color(0.45, 0.3, 0.2), Color(0.55, 0.4, 0.3)], "size": Vector2i(48, 32) },
		"lamp": { "colors": [Color(0.3, 0.3, 0.3), Color(1.0, 0.9, 0.7)], "size": Vector2i(16, 32) },
		"rug": { "colors": [Color(0.8, 0.4, 0.3), Color(0.9, 0.6, 0.4)], "size": Vector2i(48, 32) },
		"painting": { "colors": [Color(0.8, 0.7, 0.6), Color(0.9, 0.8, 0.7)], "size": Vector2i(32, 32) },
		"plant": { "colors": [Color(0.3, 0.6, 0.2), Color(0.2, 0.5, 0.15)], "size": Vector2i(24, 32) },
		"vase": { "colors": [Color(0.7, 0.5, 0.4), Color(0.8, 0.6, 0.5)], "size": Vector2i(16, 24) },
		"clock": { "colors": [Color(0.3, 0.3, 0.3), Color(1.0, 1.0, 1.0)], "size": Vector2i(24, 24) }
	}

	for name in furniture:
		var data = furniture[name]
		var sprites = {}
		var img = _draw_furniture(name, data["colors"], data["size"])
		sprites["default"] = [img]
		SpriteGenerator.save_sprites_as_tres(sprites, "res://resources/sprites/furniture_%s.tres" % name)

static func _draw_furniture(name: String, colors: Array, size: Vector2i) -> Image:
	var img = SpriteGenerator.create_base_image(size.x, size.y)
	var cx = size.x / 2
	var cy = size.y / 2
	var main = colors[0]
	var accent = colors[1] if colors.size() > 1 else colors[0]

	match name:
		"chair":
			# Assento
			draw_rect(img, size.x/2 - 10, cy + 5, 20, 6, colors[0])
			# Encosto
			draw_rect(img, size.x/2 - 12, cy - 10, 24, 18, colors[0])
			# Pernas
			for x in [-12, 10]:
				draw_rect(img, cx + x, cy + 10, 3, 10, Color(0.3, 0.2, 0.15))
		"table":
			# Tampo
			draw_rect(img, size.x/2 - 16, cy - 4, 32, 8, colors[0])
			# Pernas
			for x in [-14, 12]:
				for y in [cy + 4, cy + 20]:
					draw_rect(img, cx + x - 2, cy + 8, 4, 16, Color(0.3, 0.25, 0.15))
		"bed":
			# Colchão
			draw_rect(img, size.x/2 - 24, cy - 10, 48, 20, Color(0.9, 0.85, 0.8))
			# Travesseiro
			draw_rect(img, size.x/2 - 20, cy - 18, 24, 8, Color(1, 1, 0.9))
			# Cabeceira
			draw_rect(img, size.x/2 - 24, cy - 22, 48, 10, colors[0])
			# Pés
			for x in [-20, 20]:
				draw_rect(img, cx + x - 3, cy + 10, 6, 8, Color(0.3, 0.25, 0.15))
		"chest":
			# Base
			draw_rect(img, cx - 12, cy, 24, 16, colors[0])
			# Tampa
			draw_rect(img, cx - 14, cy - 8, 28, 10, colors[1])
			# Fecho
			draw_rect(img, cx - 2, cy - 4, 4, 4, Color(0.8, 0.7, 0.2))
		"fridge":
			# Corpo
			draw_rect(img, cx - 12, cy - 24, 24, 48, colors[0])
			# Porta freezer
			draw_rect(img, cx - 10, cy - 20, 20, 18, colors[1])
			# Porta geladeira
			draw_rect(img, cx - 10, cy + 2, 20, 24, colors[1])
			# Puxadores
			draw_rect(img, cx + 8, cy - 10, 2, 6, Color(0.8, 0.7, 0.3))
			draw_rect(img, cx + 8, cy + 10, 2, 6, Color(0.8, 0.7, 0.3))
		"tv":
			# Tela
			draw_rect(img, cx - 14, cy - 10, 28, 18, Color(0.05, 0.05, 0.1))
			# Moldura
			draw_rect(img, cx - 16, cy - 12, 32, 22, colors[0])
			# Base
			draw_rect(img, cx - 4, cy + 6, 8, 4, colors[0])
		"sofa":
			# Assento
			draw_rect(img, cx - 24, cy + 4, 48, 12, colors[0])
			# Encosto
			draw_rect(img, cx - 24, cy - 10, 48, 16, colors[0])
			# Braços
			draw_rect(img, cx - 26, cy - 2, 6, 18, colors[0])
			draw_rect(img, cx + 20, cy - 2, 6, 18, colors[0])
			# Almofadas
			for i in range(2):
				draw_rect(img, cx - 20 + i * 22, cy - 2, 16, 10, Color(0.9, 0.85, 0.8))
		"bed": # duplicado para garantir
			_draw_furniture("bed", [Color(0.6, 0.4, 0.3), Color(0.9, 0.8, 0.7)], Vector2i(64, 48))
		"bookcase":
			# Estrutura
			draw_rect(img, cx - 20, cy - 32, 40, 64, colors[0])
			# Prateleiras
			for i in range(5):
				draw_rect(img, cx - 18, cy - 28 + i * 13, 36, 2, colors[1])
			# Livros
			for i in range(5):
				for j in range(6):
					var x = cx - 16 + j * 6
					var y = cy - 26 + i * 13
					var book_color = [Color(0.7,0.2,0.2), Color(0.2,0.5,0.7), Color(0.7,0.6,0.2), Color(0.6,0.3,0.7), Color(0.8,0.7,0.2)].pick_random()
					draw_rect(img, x, cy - 26 + i * 13, 4, 10, book_color)
		"dresser":
			draw_rect(img, cx - 20, cy - 16, 40, 32, colors[0])
			# Gavetas
			for i in range(3):
				draw_rect(img, cx - 18, cy - 14 + i * 10, 36, 8, colors[1])
				draw_rect(img, cx + 6, cy - 10 + i * 10, 4, 4, Color(0.8, 0.7, 0.3))
		"desk":
			draw_rect(img, cx - 20, cy - 4, 40, 8, colors[0])
			for x in [-18, 16]:
				draw_rect(img, cx + x - 2, cy + 4, 4, 16, Color(0.3, 0.25, 0.15))
			# Gaveta
			draw_rect(img, cx - 8, cy + 4, 16, 6, colors[1])
			draw_rect(img, cx, cy + 5, 3, 3, Color(0.8, 0.7, 0.3))
		"lamp":
			# Base
			draw_rect(img, cx - 4, cy + 10, 8, 4, colors[0])
			# Haste
			draw_rect(img, cx - 1, cy - 20, 2, 30, Color(0.4, 0.4, 0.4))
			# Cúpula
			draw_rect(img, cx - 10, cy - 22, 20, 10, Color(1.0, 0.95, 0.8))
			# Luz
			draw_circle(img, cx, cy - 18, 8, Color(1.0, 0.95, 0.7, 0.5))
		"rug":
			for x in range(size.x):
				for y in range(size.y):
					var dx = (x - 24) / 24.0
					var dy = (y - 16) / 16.0
					if dx*dx + dy*dy < 1:
						var c = colors[0].lerp(colors[1], abs(sin(x * 0.3) * cos(y * 0.3)))
						draw_pixel(img, x, y, c)
		"painting":
			# Moldura
			draw_rect(img, cx - 14, cy - 14, 28, 28, Color(0.4, 0.3, 0.2))
			# Tela
			draw_rect(img, cx - 12, cy - 12, 24, 24, Color(0.8, 0.7, 0.6))
			# Arte procedural
			for i in range(10):
				var x = cx - 10 + randi_range(0, 20)
				var y = cy - 10 + randi_range(0, 20)
				var c = [Color(0.8,0.3,0.2), Color(0.3,0.6,0.2), Color(0.2,0.4,0.8), Color(0.9,0.8,0.2), Color(0.7,0.3,0.7)].pick_random()
				draw_rect(img, x, y, randi_range(2, 8), randi_range(2, 8), c)
		"plant":
			# Vaso
			draw_rect(img, cx - 8, cy + 4, 16, 12, Color(0.5, 0.35, 0.2))
			# Terra
			draw_rect(img, cx - 6, cy + 2, 12, 4, Color(0.3, 0.2, 0.1))
			# Folhas
			for i in range(8):
				var angle = i * TAU / 8.0
				var lx = cx + cos(angle) * randf_range(8, 14)
				var ly = cy + sin(angle) * randf_range(6, 12)
				draw_circle(img, lx, ly, randi_range(3, 6), Color(0.3, 0.7, 0.3))
			# Flores
			if randf() < 0.3:
				for i in range(3):
					var angle = i * TAU / 3.0
					var x = cx + cos(angle) * 10
					var y = cy - 8 + sin(angle) * 5
					draw_circle(img, x, y, 3, [Color(1,0.5,0.5), Color(1,1,0.5), Color(0.5,1,0.5)].pick_random())
		"vase":
			draw_rect(img, cx - 6, cy + 4, 12, 16, colors[0])
			draw_rect(img, cx - 8, cy + 2, 16, 4, colors[1])
			draw_rect(img, cx - 6, cy - 2, 12, 4, colors[0])
		"clock":
			# Moldura
			draw_circle(img, cx, cy, 12, colors[0])
			draw_circle(img, cx, cy, 10, colors[1])
			# Marcadores
			for i in range(12):
				var angle = i * TAU / 12.0 - PI/2
				var rx = cx + cos(angle) * 8
				var ry = cy + sin(angle) * 8
				draw_rect(img, rx - 1, ry - 3, 2, 6, colors[0])
			# Ponteiros
			draw_rect(img, cx - 1, cy - 8, 2, 8, colors[0]) # Hora
			draw_rect(img, cx - 1, cy - 10, 2, 10, colors[0]) # Minuto
	}

static func _generate_tool_sprites() -> void:
	var tools = {
		"hoe": { "head_color": Color(0.5, 0.35, 0.2), "handle_color": Color(0.4, 0.25, 0.15) },
		"watering_can": { "head_color": Color(0.3, 0.5, 0.8), "handle_color": Color(0.4, 0.25, 0.15) },
		"axe": { "head_color": Color(0.6, 0.6, 0.6), "handle_color": Color(0.4, 0.25, 0.15) },
		"pickaxe": { "head_color": Color(0.5, 0.5, 0.5), "handle_color": Color(0.4, 0.25, 0.15) },
		"hoe_copper": { "head_color": Color(0.8, 0.5, 0.2), "handle_color": Color(0.4, 0.25, 0.15) },
		"hoe_iron": { "head_color": Color(0.7, 0.7, 0.7), "handle_color": Color(0.4, 0.25, 0.15) },
		"hoe_gold": { "head_color": Color(1.0, 0.85, 0.2), "handle_color": Color(0.4, 0.25, 0.15) },
		"hoe_iridium": { "head_color": Color(0.6, 0.3, 1.0), "handle_color": Color(0.4, 0.25, 0.15) },
		"watering_can_copper": { "head_color": Color(0.8, 0.5, 0.2), "handle_color": Color(0.4, 0.25, 0.15) },
		"watering_can_iron": { "head_color": Color(0.7, 0.7, 0.7), "handle_color": Color(0.4, 0.25, 0.15) },
		"watering_can_gold": { "head_color": Color(1.0, 0.85, 0.2), "handle_color": Color(0.4, 0.25, 0.15) },
		"watering_can_iridium": { "head_color": Color(0.6, 0.3, 1.0), "handle_color": Color(0.4, 0.25, 0.15) },
		"axe_copper": { "head_color": Color(0.8, 0.5, 0.2), "handle_color": Color(0.4, 0.25, 0.15) },
		"axe_iron": { "head_color": Color(0.7, 0.7, 0.7), "handle_color": Color(0.4, 0.25, 0.15) },
		"axe_gold": { "head_color": Color(1.0, 0.85, 0.2), "handle_color": Color(0.4, 0.25, 0.15) },
		"axe_iridium": { "head_color": Color(0.6, 0.3, 1.0), "handle_color": Color(0.4, 0.25, 0.15) },
		"pickaxe_copper": { "head_color": Color(0.8, 0.5, 0.2), "handle_color": Color(0.4, 0.25, 0.15) },
		"pickaxe_iron": { "head_color": Color(0.7, 0.7, 0.7), "handle_color": Color(0.4, 0.25, 0.15) },
		"pickaxe_gold": { "head_color": Color(1.0, 0.85, 0.2), "handle_color": Color(0.4, 0.25, 0.15) },
		"pickaxe_iridium": { "head_color": Color(0.6, 0.3, 1.0), "handle_color": Color(0.4, 0.25, 0.15) },
	}

	for name in tools:
		var data = tools[name]
		var sprites = {}
		var img = _draw_tool(data["head_color"], data["handle_color"])
		sprites["default"] = [img]
		SpriteGenerator.save_sprites_as_tres(sprites, "res://resources/sprites/tool_%s.tres" % name)

static func _draw_tool(head: Color, handle: Color) -> Image:
	var img = SpriteGenerator.create_base_image(32, 32)
	var cx = 16
	var cy = 24

	# Cabo
	draw_rect(img, cx - 2, cy - 20, 4, 24, handle)

	# Cabeça (varia por tipo - simplificado)
	draw_rect(img, cx - 6, cy - 22, 12, 6, img.get_pixel(16, 4)) # Placeholder

	# Detalhe na cabeça
	draw_rect(img, cx - 4, cy - 20, 8, 4, img.get_pixel(16, 4))

	return img

static func _generate_item_icons() -> void:
	# Gera ícones para itens comuns
	var items = {
		"gold": Color(1.0, 0.85, 0.2),
		"wood": Color(0.5, 0.35, 0.2),
		"stone": Color(0.5, 0.5, 0.5),
		"copper": Color(0.8, 0.5, 0.2),
		"iron": Color(0.7, 0.7, 0.7),
		"gold_ore": Color(1.0, 0.85, 0.2),
		"iridium": Color(0.6, 0.3, 1.0),
		"coal": Color(0.2, 0.2, 0.2),
		"fiber": Color(0.4, 0.6, 0.3),
		"hay": Color(0.9, 0.8, 0.3),
		"egg": Color(1.0, 1.0, 0.85),
		"milk": Color(1.0, 1.0, 0.95),
		"wool": Color(0.95, 0.95, 0.9),
		"truffle": Color(0.3, 0.2, 0.1),
		"honey": Color(1.0, 0.8, 0.2),
		"jam": Color(0.8, 0.3, 0.2),
		"wine": Color(0.6, 0.1, 0.2),
		"juice": Color(1.0, 0.6, 0.2),
		"cheese": Color(1.0, 0.9, 0.3),
		"mayonnaise": Color(1.0, 1.0, 0.9),
		"cloth": Color(0.8, 0.8, 0.7),
		"leather": Color(0.5, 0.3, 0.2),
		"sap": Color(0.6, 0.8, 0.3),
		"bait": Color(0.5, 0.3, 0.2),
		"tackle": Color(0.4, 0.6, 0.8),
		"bomb": Color(0.3, 0.3, 0.3),
		"staircase": Color(0.5, 0.4, 0.3),
		"fence": Color(0.5, 0.35, 0.2),
		"gate": Color(0.5, 0.35, 0.2),
		"sprinkler": Color(0.4, 0.4, 0.6),
		"scarecrow": Color(0.5, 0.4, 0.2),
		"bee_house": Color(0.9, 0.8, 0.3),
		"keg": Color(0.4, 0.3, 0.2),
		"preserves_jar": Color(0.5, 0.4, 0.3),
		"cheese_press": Color(0.6, 0.5, 0.3),
		"loom": Color(0.5, 0.4, 0.6),
		"oil_maker": Color(0.6, 0.5, 0.3),
		"cask": Color(0.4, 0.3, 0.2),
		"slime_hutch": Color(0.3, 0.8, 0.3),
		"fish_pond": Color(0.3, 0.6, 1.0),
		"well": Color(0.5, 0.5, 0.6),
		"stable": Color(0.5, 0.35, 0.2),
		"silo": Color(0.6, 0.5, 0.4),
		"mill": Color(0.5, 0.4, 0.3),
		"junimo_hut": Color(0.3, 0.8, 0.3),
		"greenhouse": Color(0.4, 0.8, 0.4),
		"cabin": Color(0.5, 0.35, 0.2),
		"shipping_bin": Color(0.5, 0.4, 0.3),
		"statue": Color(0.5, 0.5, 0.5),
		"fountain": Color(0.4, 0.7, 1.0)
	}

	for name in items:
		var color = items[name]
		var sprites = {}
		var img = _draw_item_icon(color, name)
		sprites["default"] = [img]
		SpriteGenerator.save_sprites_as_tres(sprites, "res://resources/sprites/item_%s.tres" % name)

static func _draw_item_icon(base_color: Color, name: String) -> Image:
	var img = SpriteGenerator.create_base_image(32, 32)
	var cx = 16
	var cy = 16

	# Base do ícone
	draw_circle(img, cx, cy, 12, base_color)

	# Detalhes específicos por tipo
	if "ore" in name or name in ["copper", "iron", "gold_ore", "iridium"]:
		# Minério - cristais
		for i in range(5):
			var angle = i * TAU / 5.0
			var x = cx + cos(angle) * 8
			var y = cy + sin(angle) * 8
			draw_circle(img, x, y, 3, base_color.lightened(0.3))
	elif "gold" in name and "ore" not in name:
		# Ouro - brilho
		draw_circle(img, cx, cy, 8, Color(1.0, 0.95, 0.5))
		draw_circle(img, cx, cy, 4, Color(1.0, 1.0, 0.8))
	elif "wood" in name or name == "fence" or name == "gate":
		# Madeira - anéis
		for r in range(3, 10):
			draw_circle(img, cx, cy, r, Color(0.4, 0.25, 0.15) if r % 2 == 0 else Color(0.5, 0.35, 0.2))
	elif "stone" in name or name == "fence" or name == "gate":
		# Pedra - textura
		for x in range(32):
			for y in range(32):
				if (x + y) % 4 == 0:
					draw_pixel(img, x, y, Color(0.4, 0.4, 0.4))
	elif "seed" in name or "crop" in name or "flower" in name:
		# Semente/flor - broto
		draw_rect(img, cx - 2, cy + 2, 4, 6, Color(0.2, 0.6, 0.2))
		draw_rect(img, cx - 1, cy - 2, 2, 6, Color(0.3, 0.7, 0.3))
	elif "fish" in name:
		# Peixe
		draw_rect(img, cx - 10, cy - 3, 20, 6, base_color)
		draw_circle(img, cx + 8, cy, 4, base_color)
		draw_circle(img, cx - 8, cy, 3, base_color.lightened(0.2))
	elif "egg" in name:
		# Ovo
		draw_circle(img, cx, cy + 2, 10, base_color)
		draw_circle(img, cx, cy - 2, 6, base_color.lightened(0.2))
	elif "milk" in name or "juice" in name or "wine" in name or "honey" in name:
		# Líquido em garrafa
		draw_rect(img, cx - 6, cy - 10, 12, 20, base_color.darkened(0.2))
		draw_rect(img, cx - 4, cy - 12, 8, 4, base_color)
		draw_rect(img, cx - 3, cy - 14, 6, 3, Color(0.8, 0.8, 0.8))
	elif "cheese" in name or "mayonnaise" in name:
		# Pote
		draw_rect(img, cx - 8, cy - 4, 16, 12, base_color)
		draw_rect(img, cx - 6, cy - 8, 12, 4, base_color.lightened(0.3))
		draw_rect(img, cx - 4, cy + 4, 8, 2, Color(0.6, 0.5, 0.4))
	elif "bomb" in name:
		# Bomba
		draw_circle(img, cx, cy, 10, base_color)
		draw_rect(img, cx - 1, cy - 12, 2, 6, Color(0.8, 0.6, 0.2)) # Pavio
		draw_circle(img, cx, cy - 14, 3, Color(1.0, 0.5, 0.2)) # Centelha
	elif "sprinkler" in name:
		draw_circle(img, cx, cy, 10, base_color)
		for i in range(4):
			var angle = i * TAU / 4.0
			draw_rect(img, cx + cos(angle) * 12 - 1, cy + sin(angle) * 12 - 1, 2, 6, Color(0.3, 0.7, 1.0))
	elif "scarecrow" in name:
		# Espantalho
		draw_rect(img, cx - 2, cy - 8, 4, 16, Color(0.4, 0.3, 0.2)) # Corpo
		draw_rect(img, cx - 8, cy - 10, 16, 4, Color(0.6, 0.5, 0.3)) # Braços
		draw_circle(img, cx, cy - 16, 6, Color(0.9, 0.8, 0.7)) # Cabeça
		draw_rect(img, cx - 10, cy - 18, 20, 4, Color(0.5, 0.4, 0.3)) # Chapéu
	elif "bee" in name:
		draw_circle(img, cx, cy, 10, Color(0.9, 0.8, 0.2))
		draw_rect(img, cx - 8, cy - 2, 16, 4, Color(0.2, 0.2, 0.1)) # Listras
	elif "keg" in name or "preserves_jar" in name or "cheese_press" in name or "loom" in name or "oil_maker" in name or "cask" in name:
		# Máquinas - barril/pote
		draw_rect(img, cx - 10, cy - 8, 20, 16, base_color)
		draw_rect(img, cx - 8, cy - 12, 16, 4, base_color.lightened(0.3)) # Tampa
		draw_rect(img, cx - 2, cy + 4, 4, 4, Color(0.4, 0.3, 0.2)) # Torneira/alça
	elif "slime_hutch" in name:
		draw_rect(img, cx - 12, cy - 4, 24, 12, Color(0.3, 0.8, 0.3))
		draw_circle(img, cx, cy + 2, 6, Color(0.2, 0.6, 0.2))
	elif "fish_pond" in name:
		draw_circle(img, cx, cy, 12, Color(0.3, 0.5, 1.0))
		for i in range(3):
			var angle = i * TAU / 3.0
			var x = cx + cos(angle) * 6
			var y = cy + sin(angle) * 6
			draw_circle(img, x, y, 3, Color(0.5, 0.7, 1.0))
	elif "well" in name:
		draw_rect(img, cx - 10, cy - 8, 20, 16, Color(0.5, 0.4, 0.3))
		draw_rect(img, cx - 8, cy - 10, 16, 4, Color(0.4, 0.3, 0.2))
		draw_rect(img, cx - 2, cy - 14, 4, 6, Color(0.5, 0.4, 0.3)) # Telhado
		draw_rect(img, cx - 1, cy - 8, 2, 8, Color(0.3, 0.2, 0.1)) # Balde
	elif "stable" in name:
		draw_rect(img, cx - 16, cy - 4, 32, 12, base_color)
		draw_rect(img, cx - 14, cy - 10, 28, 6, base_color.darkened(0.2)) # Telhado
		draw_rect(img, cx - 12, cy - 2, 8, 8, Color(0.3, 0.2, 0.1)) # Porta
	elif "silo" in name:
		draw_rect(img, cx - 8, cy - 12, 16, 20, base_color)
		draw_circle(img, cx, cy - 14, 8, base_color.darkened(0.2)) # Topo
		draw_rect(img, cx - 4, cy + 4, 8, 4, Color(0.3, 0.2, 0.1)) # Porta
	elif "greenhouse" in name:
		draw_rect(img, cx - 14, cy - 10, 28, 20, Color(0.3, 0.7, 0.3))
		for x in range(cx - 12, cx + 12, 4):
			draw_rect(img, x, cy - 8, 2, 16, Color(0.7, 0.9, 0.7)) # Vidros
	elif "shipping_bin" in name:
		draw_rect(img, cx - 10, cy - 6, 20, 12, base_color)
		draw_rect(img, cx - 8, cy - 10, 16, 4, base_color.darkened(0.2))
		draw_rect(img, cx - 4, cy + 2, 8, 4, Color(1.0, 0.85, 0.2)) # Bandeira
	elif "statue" in name:
		draw_rect(img, cx - 4, cy - 12, 8, 20, base_color)
		draw_circle(img, cx, cy - 16, 6, base_color)
		draw_rect(img, cx - 6, cy - 4, 12, 4, base_color) # Braços
	elif "fountain" in name:
		draw_circle(img, cx, cy, 12, Color(0.4, 0.7, 1.0))
		draw_circle(img, cx, cy, 8, Color(0.5, 0.8, 1.0))
		draw_circle(img, cx, cy - 2, 4, Color(0.7, 0.9, 1.0)) # Jato d'água

	return img

## ==================== EXECUÇÃO DIRETA ====================

func _ready() -> void:
	# Permite executar como script standalone
	if OS.get_cmdline_args().has("--generate-assets"):
		generate_all_assets()
		OS.exit(0)