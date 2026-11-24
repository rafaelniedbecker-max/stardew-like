class_name FishingMinigame
extends Control

## Minigame de Pesca Visual Aprimorado

@onready var water_area: TextureRect = $Background/WaterArea
@onready var fish_bar_container: Control = $Background/WaterArea/FishBarContainer
@onready var fish_bar: Control = $Background/WaterArea/FishBarContainer/FishBar
@onready var fish_bar_fill: TextureRect = $Background/WaterArea/FishBarContainer/FishBar/FishBarFill
@onready var fish_bar_border: TextureRect = $Background/WaterArea/FishBarContainer/FishBar/FishBarBorder
@onready var fish_sprite: AnimatedSprite2D = $Background/WaterArea/FishBarContainer/FishSprite
@onready var fish_icon: TextureRect = $Background/WaterArea/FishBarContainer/FishIcon
@onready var catch_progress_bar: ProgressBar = $Background/CatchProgressContainer/CatchProgressBar
@onready var catch_label: Label = $Background/CatchProgressContainer/CatchLabel
@onready var perfect_label: Label = $Background/CatchProgressContainer/PerfectLabel
@onready var perfect_effect: CPUParticles2D = $Background/PerfectEffect
@onready var fish_name_label: Label = $Background/InfoPanel/FishNameLabel
@onready var fish_difficulty_label: Label = $Background/InfoPanel/FishDifficultyLabel
@onready var rod_label: Label = $Background/InfoPanel/RodLabel
@onready var tackle_label: Label = $Background/InfoPanel/TackleLabel
@onready var level_label: Label = $Background/InfoPanel/LevelLabel

## Referência ao FishingManager
var manager: FishingManager = null
var hooked_fish_data: Dictionary = {}
var difficulty: float = 1.0
var bar_size: float = 0.15

## Estado visual
var _fish_bar_position: float = 0.5
var _fish_position: float = 0.5
var _catch_progress: float = 0.0
var _perfect_catch: bool = true

## Visual do peixe
var _fish_anim_timer: float = 0.0
var _water_offset: float = 0.0

## Cores por qualidade
const QUALITY_COLORS = {
	0: Color(1.0, 1.0, 1.0),    # Normal
	1: Color(0.75, 0.75, 0.75), # Prata
	2: Color(1.0, 0.85, 0.2),   # Ouro
	3: Color(0.6, 0.3, 1.0)     # Irídio
}

## ==================== INICIALIZAÇÃO ====================
func initialize(mgr: FishingManager, fish_data: Dictionary, diff: float, bar_sz: float) -> void:
	manager = mgr
	hooked_fish_data = fish_data
	difficulty = diff
	bar_size = bar_sz

	_fish_bar_position = 0.5
	_fish_position = 0.5
	_catch_progress = 0.0
	_perfect_catch = true

	_setup_ui()
	_setup_fish_visual()

	# Foco para input
	grab_focus()

func _setup_ui() -> void:
	# Nome do peixe
	var fish_name = hooked_fish_data.get("name", "Peixe")
	fish_name_label.text = "Peixe: %s" % fish_name

	# Dificuldade em estrelas
	var diff_stars = int(difficulty * 5)
	fish_difficulty_label.text = "Dificuldade: %s" % ("★" * diff_stars + "☆" * (5 - diff_stars))

	# Vara
	var rod_name = "Bambu"
	if manager:
		match manager.current_rod:
			"Fiberglass": rod_name = "Fibra de Vidro"
			"Iridium": rod_name = "Irídio"
	rod_label.text = "Vara: %s" % rod_name

	# Isca/Anzol
	var tackle = "Nenhuma"
	if manager:
		if manager.current_bait != "":
			tackle = "Isca: %s" % manager.current_bait
		if manager.current_tackle != "":
			tackle += " | Anzol: %s" % manager.current_tackle
	tackle_label.text = tackle

	# Nível
	var level = manager.fishing_level if manager else 0
	level_label.text = "Pesca: Nível %d" % level

	# Configura barra
	_update_bar_visual()

func _setup_fish_visual() -> void:
	# Tenta carregar sprite do peixe
	var fish_id = hooked_fish_data.get("id", "")
	var item = DataLoader.get_item(fish_id)
	if item and item.texture_path != "":
		fish_icon.texture = load(item.texture_path)
		fish_icon.visible = true
		fish_sprite.visible = false
	else:
		fish_icon.visible = false
		fish_sprite.visible = true
		# Animação procedural simples
		_setup_procedural_fish()

func _setup_procedural_fish() -> void:
	# Cria sprite procedural do peixe
	var frames = SpriteFrames.new()
	frames.add_animation("swim")
	frames.add_animation("struggle")
	frames.add_animation("caught")

	var colors = {
		"(O)152": Color(1.0, 0.5, 0.2),  # Sunfish - laranja
		"(O)150": Color(0.5, 0.3, 0.2),  # Catfish - marrom
		"(O)151": Color(0.8, 0.4, 0.3),  # Salmon - vermelho
		"(O)153": Color(0.8, 0.6, 0.2),  # Tiger Trout - dourado/listrado
		"(O)154": Color(0.4, 0.4, 0.6),  # Lingcod - azulado
	}
	var fish_color = colors.get(hooked_fish_data.get("id", ""), Color(0.5, 0.7, 0.4))

	for anim in ["swim", "struggle", "caught"]:
		for frame in range(4):
			var img = Image.create(48, 24, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			# Desenha peixe simples
			_draw_fish(img, fish_color, anim, frame)
			var tex = ImageTexture.create_from_image(img)
			frames.set_frame_texture(anim, frame, tex)

	frames.set_animation_speed("swim", 8)
	frames.set_animation_speed("struggle", 12)
	frames.set_animation_loop("swim", true)
	frames.set_animation_loop("struggle", true)
	frames.set_animation_loop("caught", false)

	fish_sprite.sprite_frames = frames
	fish_sprite.play("swim")

func _draw_fish(img: Image, base_color: Color, anim: String, frame: int) -> void:
	var cx = 24
	var cy = 12
	var body_w = 24
	var body_h = 12

	# Animação de natação
	var tail_offset = sin(frame * PI / 2) * 4 if anim == "swim" else 0
	var struggle = anim == "struggle"
	if struggle:
		tail_offset = sin(frame * PI) * 8

	# Corpo
	for x in range(cx - body_w/2, cx + body_w/2):
		for y in range(cy - body_h/2, cy + body_h/2):
			var dx = (x - cx) / (body_w/2)
			var dy = (y - cy) / (body_h/2)
			if dx*dx + dy*dy < 1:
				var c = base_color
				if struggle and frame % 2 == 0:
					c = c.lightened(0.3)
				img.set_pixel(x, y, c)

	# Cauda
	var tail_x = cx - body_w/2 + tail_offset
	for x in range(int(tail_x) - 6, int(tail_x) + 6):
		for y in range(cy - 6, cy + 6):
			var dx = (x - tail_x) / 6
			var dy = (y - cy) / 6
			if dx*dx + dy*dy < 1:
				img.set_pixel(x, y, base_color)

	# Olho
	img.set_pixel(cx + 6, cy - 2, Color(0, 0, 0))

## ==================== LOOP PRINCIPAL ====================
func _process(delta: float) -> void:
	if not manager or not manager.is_fishing:
		queue_free()
		return

	# Atualiza lógica do minigame
	var input_up = Input.is_action_pressed("move_up") or Input.is_action_pressed("tool_use")
	var input_down = Input.is_action_pressed("move_down")

	var result = manager.update_minigame(delta, input_up, input_down)

	if result.has("caught") or result.has("escaped"):
		_on_result(result)
		return

	# Atualiza estado visual
	_fish_bar_position = result.bar_position
	_fish_position = result.fish_position
	_catch_progress = result.catch_progress
	_perfect_catch = result.perfect

	_update_visuals(delta)

func _update_visuals(delta: float) -> void:
	# Animação da água
	_water_offset += delta * 50
	water_area.offset_top = 150 + sin(_water_offset * 0.01) * 3

	# Atualiza barra do jogador
	_update_bar_visual()

	# Atualiza posição do peixe
	var container_h = fish_bar_container.size.y
	var fish_y = lerp(container_h * 0.1, container_h * 0.9, 1.0 - _fish_position)
	fish_sprite.global_position = Vector2(fish_bar_container.global_position.x + 30, fish_bar_container.global_position.y + fish_y)
	fish_icon.global_position = fish_sprite.global_position

	# Animação do peixe
	_fish_anim_timer += delta
	if manager and manager.fish_in_bar:
		fish_sprite.play("swim")
	else:
		fish_sprite.play("struggle")

	# Atualiza progresso
	catch_progress_bar.value = _catch_progress * 100
	catch_label.text = "Progresso: %d%%" % int(_catch_progress * 100)

	# Perfect catch indicator
	if _perfect_catch:
		perfect_label.visible = true
		perfect_label.modulate = Color(1, 1, 0.3, 0.5 + 0.5 * sin(_fish_anim_timer * 5))
	else:
		perfect_label.visible = false

	# Efeito visual na barra
	if manager and manager.fish_in_bar:
		fish_bar_fill.color = Color(0.2, 1.0, 0.4, 0.8)
		fish_bar_border.color = Color(0.4, 1.0, 0.6, 1.0)
	else:
		fish_bar_fill.color = Color(0.3, 0.7, 1.0, 0.8)
		fish_bar_border.color = Color(0.5, 0.8, 1.0, 1.0)

func _update_bar_visual() -> void:
	var container_h = fish_bar_container.size.y
	var bar_h = container_h * bar_size
	var bar_y = container_h * (1.0 - _fish_bar_position - bar_size) + container_h * 0.1

	fish_bar.position = Vector2(0, bar_y)
	fish_bar.size = Vector2(fish_bar_container.size.x, bar_h)

func _on_result(result: Dictionary) -> void:
	if result.has("caught") and result.caught:
		# Sucesso!
		perfect_effect.emitting = true
		perfect_effect.global_position = fish_bar_container.global_position + Vector2(fish_bar_container.size.x/2, fish_bar_container.size.y/2)

		if _perfect_catch:
			perfect_label.text = "✨ PERFECT CATCH! ✨"
			perfect_label.visible = true
			perfect_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
			manager.emit_signal("perfect_catch_achieved", hooked_fish_data)

		# Animação de sucesso
		fish_sprite.play("caught")

		# Delay antes de fechar
		var timer = Timer.new()
		timer.wait_time = 1.5
		timer.one_shot = true
		timer.timeout.connect(queue_free.bind())
		add_child(timer)
		timer.start()

	elif result.has("escaped") and result.escaped:
		# Falhou
		fish_name_label.text = "O peixe escapou! 😢"
		fish_name_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

		var timer = Timer.new()
		timer.wait_time = 1.5
		timer.one_shot = true
		timer.timeout.connect(queue_free.bind())
		add_child(timer)
		timer.start()

## ==================== INPUT ====================
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		# Pausa o jogo
		get_tree().paused = true
		var pause = PauseMenu.new()
		pause.resume_requested.connect(_on_resume)
		get_tree().root.get_child(0).add_child(pause)
		pause.show_menu()

func _on_resume() -> void:
	get_tree().paused = false
	grab_focus()