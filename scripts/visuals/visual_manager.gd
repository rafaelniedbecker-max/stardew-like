class_name VisualManager
extends Node

## Gerenciador Visual Principal: Aplica todos os assets gerados e efeitos visuais

@export var auto_generate_on_start: bool = true
@export var enable_shaders: bool = true
@export var enable_particles: bool = true
@export var enable_lighting: bool = true
@export var enable_weather: bool = true
@export var enable_ui_effects: bool = true

## Referências
var _sprite_generator: SpriteGenerator
var _particle_manager: ParticleSystemManager
var _dynamic_lighting: DynamicLighting
var _camera_effects: CameraEffects
var _ui_effects: UIEffects

## Estado
var _initialized: bool = false
var _current_weather: int = 0
var _current_season: int = 0
var _time_of_day: int = 600
var _weather_particles: GPUParticles2D = null
var _seasonal_particles: GPUParticles2D = null
var _canvas_modulate: CanvasModulate = null
var _day_night_shader: ShaderMaterial = null

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Inicializa referências aos sistemas
	_sprite_generator = SpriteGenerator.new()
	_particle_manager = ParticleSystemManager.new()
	_dynamic_lighting = DynamicLighting.new()
	_camera_effects = CameraEffects.new()
	_ui_effects = UIEffects.new()

	# Conecta sinais do GameManager
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)
		GameManager.season_changed.connect(_on_season_changed)
		GameManager.weather_changed.connect(_on_weather_changed)
		GameManager.time_changed.connect(_on_time_changed)
		GameManager.level_up.connect(_on_level_up)

	# Conecta sinais do TimeManager
	if TimeManager:
		TimeManager.hour_changed.connect(_on_hour_changed)

	# Inicializa sistemas visuais
	if auto_generate_on_start:
		call_deferred("_initialize_visuals")

	# CanvasModulate para tint global
	_canvas_modulate = CanvasModulate.new()
	_canvas_modulate.name = "GlobalTint"
	get_tree().root.get_child(0).add_child(_canvas_modulate)

	# Shader day/night
	if enable_shaders:
		_day_night_shader = ShaderMaterial.new()
		_day_night_shader.shader = Shader.new()
		_day_night_shader.shader.code = VisualEffects.SHADERS["day_night"]
		get_tree().root.get_child(0).material = _day_night_shader

	# Inicializa iluminação
	if enable_lighting:
		call_deferred("_initialize_lighting")

	_initialized = true
	print("VisualManager inicializado!")

func _initialize_visuals() -> void:
	# Gera assets se não existirem
	_generate_missing_assets()

	# Aplica shaders iniciais
	if enable_shaders:
		_apply_initial_shaders()

	# Inicia partículas sazonais
	if enable_weather:
		_update_seasonal_particles()

	print("Assets visuais inicializados!")

func _generate_missing_assets() -> void:
	# Gera sprites do player se não existirem
	if not ResourceLoader.exists("res://resources/sprites/player_sprites.tres"):
		print("Gerando sprites do player...")
		var sprites = SpriteGenerator.generate_character()
		SpriteGenerator.save_sprites_as_tres(sprites, "res://resources/sprites/player_sprites.tres")

	# Gera tileset se não existir
	if not ResourceLoader.exists("res://resources/tilesets/farm_tileset_detailed.tres"):
		print("Gerando tileset detalhado...")
		_generate_detailed_tileset()

	# Gera culturas
	var crops = ["parsnip", "potato", "cauliflower", "wheat", "corn", "tomato", "blueberry", "strawberry", "melon", "pumpkin", "flower"]
	for crop in crops:
		if not ResourceLoader.exists("res://resources/sprites/crop_%s.tres" % crop):
			var sprites = SpriteGenerator.generate_crop_sprites(crop)
			SpriteGenerator.save_sprites_as_tres(sprites, "res://resources/sprites/crop_%s.tres" % crop)

	# Animais
	var animals = ["chicken", "cow", "goat", "sheep", "pig", "rabbit", "duck", "dinosaur"]
	for animal in animals:
		if not ResourceLoader.exists("res://resources/sprites/animal_%s.tres" % animal):
			var sprites = SpriteGenerator.generate_animal_sprites(animal)
			SpriteGenerator.save_sprites_as_tres(sprites, "res://resources/sprites/animal_%s.tres" % animal)

	print("Assets gerados/verificados!")

func _generate_detailed_tileset() -> void:
	var tileset = TileSet.new()
	tileset.tile_size = Vector2i(16, 16)

	# Gera textura do tileset
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

		# Copia tile para atlas
		for tx in range(16):
			for ty in range(16):
				var c = tile_img.get_pixel(tx, ty)
				if c.a > 0:
					atlas.set_pixel(x + tx, y + ty, c)

		# Cria tile no TileSet
		var tile_id = tileset.create_tile(0)
		tileset.set_tile_texture(tile_id, 0, ImageTexture.create_from_image(tile_img))
		tileset.set_tile_name(tile_id, tile_name)

		# Configura autotiling para tiles de terreno
		if tile_name.begins_with("grass") or tile_name.begins_with("dirt") or tile_name.begins_with("water") or tile_name.begins_with("path"):
			_setup_autotiling(tileset, tile_id)

		tile_idx += 1

	# Salva textura do atlas
	var atlas_tex = ImageTexture.create_from_image(atlas)
	ResourceSaver.save(atlas_tex, "res://resources/tilesets/farm_atlas.png")

	# Adiciona textura ao TileSet
	tileset.set_tile_texture(0, 0, atlas_tex)

	ResourceSaver.save(tileset, "res://resources/tilesets/farm_tileset_detailed.tres")
	print("Tileset detalhado gerado!")

func _setup_autotiling(tileset: TileSet, tile_id: int) -> void:
	# Configura bitmask 3x3 para autotiling
	tileset.set_tile_texture(0, 0, load("res://resources/tilesets/farm_atlas.png"))
	# O Godot 4.3+ usa TileMapLayer com autotiling automático

func _apply_initial_shaders() -> void:
	# Aplica shader day/night
	if _day_night_shader:
		if GameManager:
			_day_night_shader.set_shader_parameter("time_of_day", GameManager.current_time)
			_day_night_shader.set_shader_parameter("season", GameManager.current_season)
			_day_night_shader.set_shader_parameter("weather", GameManager.today_weather)

func _initialize_lighting() -> void:
	# Luz do sol
	DynamicLighting.set_time_of_day(GameManager.current_time if GameManager else 600)

	# Luzes de edifícios
	if BuildingManager:
		for building in BuildingManager.get_all_buildings():
			if building.has_method("get_light_position"):
				DynamicLighting.add_light(
					building.get_light_position(),
					Color(1.0, 0.9, 0.6, 0.8),
					80.0,
					0.5,
					true
				)

func _update_seasonal_particles() -> void:
	# Remove partículas antigas
	if _seasonal_particles and _seasonal_particles.is_inside_tree():
		_seasonal_particles.queue_free()
		_seasonal_particles = null

	if not enable_weather:
		return

	# Partículas sazonais
	if GameManager:
		match GameManager.current_season:
			0: # Primavera - pétalas
				_seasonal_particles = ParticleSystemManager.petals_spring()
			1: # Verão - vaga-lumes (noite)
				# Vaga-lumes ativados via DayNightCycle
				pass
			2: # Outono - folhas
				_seasonal_particles = ParticleSystemManager.leaves_fall()
			3: # Inverno - neve leve
				_seasonal_particles = ParticleSystemManager.weather_snow(0.3)

## ==================== CALLBACKS DO GAME MANAGER ====================

func _on_day_changed(day: int, season: int, year: int) -> void:
	_current_season = season
	_update_seasonal_particles()
	_update_lighting_for_season(season)

	# Efeito visual de novo dia
	_ui_effects.show_toast("🌅 Novo Dia", "Dia %d de %s, Ano %d" % [day, ["Primavera", "Verão", "Outono", "Inverno"][season], year], "info", 5.0)

func _on_season_changed(season: int, year: int) -> void:
	_current_season = season
	_update_seasonal_particles()
	_update_lighting_for_season(season)

	# Transição visual de estação
	_transition_season(season)

func _on_weather_changed(weather: int) -> void:
	_current_weather = weather
	_update_weather_effects(weather)

func _on_time_changed(time: int) -> void:
	_time_of_day = time

	# Atualiza shader day/night
	if _day_night_shader:
		_day_night_shader.set_shader_parameter("time_of_day", time)
		_day_night_shader.set_shader_parameter("season", _current_season)
		_day_night_shader.set_shader_parameter("weather", _current_weather)

	# Atualiza iluminação
	if enable_lighting:
		DynamicLighting.set_time_of_day(time)

	# Atualiza canvas modulate (fallback)
	_update_canvas_tint()

	# Efeitos de hora específica
	_check_special_times(time)

func _on_hour_changed(hour: int) -> void:
	# Atualiza vaga-lumes no verão
	if _current_season == 1: # Verão
		_toggle_fireflies(hour)

	# Atualiza vaga-lumes no outono
	if _current_season == 2: # Outono
		_toggle_fireflies(hour)

func _on_level_up(skill_index: int, new_level: int) -> void:
	var skill_names = ["Agricultura", "Mineração", "Coleta", "Pesca", "Combate"]
	var skill_name = skill_names[skill_index] if skill_index < skill_names.size() else "Habilidade"

	_ui_effects.show_level_up(skill_name, new_level, get_tree().root.get_child(0).global_position)

	# Partículas de level up
	if ParticleSystemManager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ParticleSystemManager.level_up_effect(player.global_position, skill_name)

## ==================== CLIMA ====================

func _on_weather_changed(weather: int) -> void:
	_update_weather_effects(weather)

func _update_weather_effects(weather: int) -> void:
	# Remove clima anterior
	if _weather_particles and _weather_particles.is_inside_tree():
		_queue_free_weather()

	# Aplica novo clima
	if not enable_weather:
		return

	match weather:
		0: # Sol
			# Nada especial
			pass
		1: # Chuva
			_weather_particles = ParticleSystemManager.weather_rain(1.0)
			_apply_rain_shader()
		2: # Tempestade
			_weather_particles = ParticleSystemManager.weather_storm(1.0)
			_apply_storm_shader()
			CameraEffects.shake(3.0, 0.5)
		3: # Neve
			ParticleSystemManager.weather_snow(1.0)
		4: # Chuva verde
			_weather_particles = ParticleSystemManager.weather_rain(1.5)
			_apply_green_rain_shader()

	# Atualiza shader day/night
	if _day_night_shader:
		_day_night_shader.set_shader_parameter("weather", _current_weather)

func _queue_free_weather() -> void:
	if _weather_particles and _weather_particles.is_inside_tree():
		_weather_particles.emitting = false
		_weather_particles.queue_free()
		_weather_particles = null

	# Remove shaders de clima
	if get_tree().root.get_child(0).material and get_tree().root.get_child(0).material is ShaderMaterial:
		var shader = get_tree().root.get_child(0).material
		if shader.shader.code == VisualEffects.SHADERS["weather_rain"] or \
		   shader.shader.code == VisualEffects.SHADERS["weather_storm"]:
			get_tree().root.get_child(0).material = null

func _apply_rain_shader() -> void:
	var shader = ShaderMaterial.new()
	shader.shader = Shader.new()
	shader.shader.code = VisualEffects.SHADERS["weather_rain"]
	get_tree().root.get_child(0).material = shader

func _apply_storm_shader() -> void:
	var shader = ShaderMaterial.new()
	shader.shader = Shader.new()
	shader.shader.code = VisualEffects.SHADERS["weather_storm"]
	get_tree().root.get_child(0).material = shader

func _apply_green_rain_shader() -> void:
	var shader = ShaderMaterial.new()
	shader.shader = Shader.new()
	shader.shader.code = """
		shader_type canvas_item;
		uniform sampler2D screen_texture;
		uniform float time;
		void fragment() {
			vec2 uv = UV;
			vec4 color = texture(screen_texture, uv);
			// Gotas verdes
			for (int i = 0; i < 50; i++) {
				float seed = float(i) * 12.9898;
				float rand_x = fract(sin(time * 0.5 + float(i) * 13.54) * 43758.5453);
				float rand_y = fract(sin(time * 0.3 + float(i) * 21.73) * 43758.5453);
				float drop_x = fract(UV.x * 100.0 + rand_x + time * 0.3);
				float drop_y = fract(UV.y * 100.0 + rand_y + time * 2.0);
				float drop = step(0.995, drop_x) * step(0.99, drop_y);
				drop *= smoothstep(0.0, 0.02, abs(UV.x - drop_x) * 50.0) * smoothstep(0.0, 0.1, abs(UV.y - drop_y) * 10.0);
				COLOR.rgb += vec3(0.3, 1.0, 0.3) * drop * 0.5;
			}
			COLOR.rgb = mix(COLOR.rgb, vec3(0.7, 0.9, 0.7), 0.2);
		}
	"""
	get_tree().root.get_child(0).material = shader

func _toggle_fireflies(hour: int) -> void:
	# Vaga-lumes ativos 19h-5h no verão/outono
	var active = (hour >= 19 || hour < 5)
	# Implementar toggle de vaga-lumes
	pass

## ==================== ILUMINAÇÃO E TINTS ====================

func _update_lighting_for_season(season: int) -> void:
	DynamicLighting.set_time_of_day(GameManager.current_time if GameManager else 600)

	# Ajusta cor ambiente por estação
	if _canvas_modulate:
		match _current_season:
			0: _canvas_modulate.color = Color(1.0, 1.0, 0.95, 1.0) # Primavera - quente
			1: _canvas_modulate.color = Color(1.0, 0.98, 0.9, 1.0)  # Verão - amarelo quente
			2: _canvas_modulate.color = Color(1.0, 0.95, 0.9, 1.0)  # Outono - laranja suave
			3: _canvas_modulate.color = Color(0.95, 0.95, 1.0, 1.0) # Inverno - azulado

func _update_canvas_tint() -> void:
	if not _canvas_modulate:
		return

	var time = _time_of_day
	var season = _current_season
	var weather = _current_weather

	# Calcula cor base
	var base_color = Color(1, 1, 1, 1)

	# Estação
	match season:
		0: base_color = Color(1.0, 1.0, 0.95) # Primavera
		1: base_color = Color(1.0, 0.98, 0.9)   # Verão
		2: base_color = Color(1.0, 0.95, 0.9)   # Outono
		3: base_color = base_color.lerp(Color(0.95, 0.95, 1.0), 0.5) # Inverno

	# Hora do dia
	var hour = time / 100
	if hour >= 5 and hour < 7:
		base_color = base_color.lerp(Color(1.0, 0.6, 0.4), 0.5) # Nascer do sol
	elif hour >= 7 and hour < 12:
		base_color = base_color # Manhã
	elif hour >= 12 and hour < 14:
		base_color = base_color # Meio-dia
	elif hour >= 14 and hour < 17:
		base_color = base_color.lerp(Color(1.0, 0.9, 0.8), 0.3) # Tarde
	elif hour >= 17 and hour < 19:
		base_color = base_color.lerp(Color(1.0, 0.6, 0.4), 0.5) # Pôr do sol
	elif hour >= 19 or hour < 5:
		base_color = base_color.lerp(Color(0.3, 0.3, 0.5), 0.7) # Noite

	# Clima
	if _current_weather == 1: # Chuva
		base_color = base_color.lerp(Color(0.7, 0.7, 0.85), 0.3)
	elif _current_weather == 2: # Tempestade
		base_color = base_color.lerp(Color(0.5, 0.5, 0.65), 0.5)
	elif _current_weather == 3: # Neve
		base_color = base_color.lerp(Color(0.8, 0.85, 1.0), 0.4)
	elif _current_weather == 4: # Chuva verde
		base_color = base_color.lerp(Color(0.7, 0.9, 0.7), 0.3)

	_canvas_modulate.color = base_color

## ==================== TRANSIÇÕES VISUAIS ====================

func _transition_season(season: int) -> void:
	var season_names = ["Primavera", "Verão", "Outono", "Inverno"]
	var season_colors = [
		Color(0.5, 0.8, 0.5),   # Primavera - verde
		Color(1.0, 0.8, 0.3),   # Verão - amarelo
		Color(1.0, 0.5, 0.2),   # Outono - laranja
		Color(0.5, 0.7, 1.0)    # Inverno - azul
	]

	var panel = Panel.new()
	panel.name = "SeasonTransition"
	panel.anchors_preset = 15
	panel.offset_left = -400
	panel.offset_top = -100
	panel.offset_right = 400
	panel.offset_bottom = 100
	panel.modulate = Color(1, 1, 1, 0)

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	panel.add_child(vbox)

	var icon = Label.new()
	icon.text = ["🌸", "☀️", "🍂", "❄️"][season]
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.theme_override_font_size = 64
	vbox.add_child(icon)

	var title = Label.new()
	title.text = "%s Chegou!" % ["Primavera", "Verão", "Outono", "Inverno"][season]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 36
	title.add_theme_color_override("font_color", season_colors[season])
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = _get_season_description(season)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = 1
	desc.theme_override_font_size = 16
	desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(desc)

	get_tree().root.get_child(0).add_child(panel)

	# Animação
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 1.0).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "modulate:a", 0.0, 1.0).set_delay(3.0)
	tween.finished.connect(panel.queue_free.bind())

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/season_change.ogg")

	# Partículas de transição
	if ParticleSystemManager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ParticleSystemManager.show_level_up(player.global_position, "Nova Estação: %s" % ["Primavera", "Verão", "Outono", "Inverno"][season])

func _get_season_description(season: int) -> String:
	match season:
		0: return "As flores desabrocham e as culturas de primavera crescem rápido. Perfeito para plantar!"
		1: return "O calor do verão acelera o crescimento. Cuidado com tempestades e regue suas plantas!"
		2: return "As folhas caem e as culturas de outono são as mais valiosas. Prepare-se para o inverno!"
		3: return "A neve cobre a terra. Culturas morrem ao ar livre, mas a estufa continua produzindo."
	return ""

## ==================== EVENTOS ESPECIAIS DE HORA ====================

func _check_special_times(time: int) -> void:
	match time:
		600: # 6:00 - Nascer do sol
			_camera_effects.flash(Color(1.0, 0.8, 0.4, 0.3), 1.0)
			_ui_effects.show_toast("🌅 Nascer do Sol", "Um novo dia começa!", "info", 3.0)
		1200: # Meio-dia
			pass
		1800: # 18:00 - Pôr do sol
			_camera_effects.flash(Color(1.0, 0.5, 0.3, 0.3), 1.0)
		2200: # 22:00 - Noite
			_ui_effects.show_toast("🌙 Noite Chegou", "Hora de descansar. Energia baixa!", "warning", 3.0)
		2400: # Meia-noite
			if enable_weather and _current_season == 3 and randf() < 0.01:
				# Aurora boreal rara no inverno
				ParticleSystemManager.aurora_borealis()
		2600: # 2:00 - Desmaio
			_camera_effects.flash(Color(1, 0, 0, 0.5), 1.0)
		_: pass

## ==================== UTILITÁRIOS PÚBLICOS ====================

func show_damage_number(position: Vector2, amount: int, type: String = "damage") -> void:
	var colors = {
		"damage": Color(1.0, 0.3, 0.3),
		"heal": Color(0.4, 1.0, 0.4),
		"xp": Color(1.0, 0.9, 0.2),
		"gold": Color(1.0, 0.85, 0.2),
		"crit": Color(1.0, 0.5, 1.0)
	}

	var label = Label.new()
	label.text = "%s%d" % [type == "heal" ? "+" : "", amount]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_override_font_size = 20
	label.add_theme_color_override("font_color", colors.get(type, Color.WHITE))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	label.add_theme_constant_override("outline_size", 2)
	label.global_position = position + Vector2(randi_range(-20, 20), -30)

	get_tree().root.get_child(0).add_child(label)

	var tween = label.create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 50, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(label.queue_free.bind())

	if type == "crit":
		CameraEffects.shake(3.0, 0.2)

func show_floating_text(text: String, position: Vector2, color: Color = Color.WHITE, duration: float = 2.0) -> void:
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.theme_override_font_size = 16
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.global_position = position

	get_tree().root.get_child(0).add_child(label)

	var tween = label.create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 40, duration)
	tween.tween_property(label, "modulate:a", 0.0, duration)
	tween.finished.connect(label.queue_free.bind())

func screen_shake(intensity: float = 5.0, duration: float = 0.5) -> void:
	CameraEffects.shake(intensity, duration)

func play_cutscene(transition_type: int = 0, duration: float = 1.0) -> void:
	CameraEffects.transition_scene(null, transition_type, duration)

## ==================== PERSISTÊNCIA ====================

func get_save_data() -> Dictionary:
	return {
		"current_season": _current_season,
		"current_weather": _current_weather,
		"time_of_day": _time_of_day,
		"canvas_tint": _canvas_modulate.color if _canvas_modulate else Color(1,1,1,1)
	}

func load_save_data(data: Dictionary) -> void:
	_current_season = data.get("current_season", 0)
	_current_weather = data.get("current_weather", 0)
	_time_of_day = data.get("time_of_day", 600)

	if _canvas_modulate:
		_canvas_modulate.color = data.get("canvas_tint", Color(1,1,1,1))

	_update_seasonal_particles()
	_update_lighting_for_season(_current_season)
	_update_canvas_tint()