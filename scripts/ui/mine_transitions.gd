extends Control

## Transições de nível da Mina com efeitos visuais

@onready var panel: Panel = $Panel
@onready var level_label: Label = $Panel/LevelLabel
@onready var theme_label: Label = $Panel/ThemeLabel
@onready var progress_bar: ProgressBar = $Panel/ProgressBar
@onready var elevator_button: Button = $Panel/ElevatorButton
@onready var leave_button: Button = $Panel/LeaveButton
@onready var particles: CPUParticles2D = $Panel/Particles

## Estado
var current_level: int = 0
var current_theme: int = 0  # 0=Mines, 1=Ice, 2=Lava
var deepest_level: int = 0
var unlocked_elevators: Array[int] = []  # Checkpoints cada 5 níveis

## Temas da mina
const MINE_THEMES = {
	0: {"name": "Minas", "color": Color(0.4, 0.35, 0.3), "levels": "1-40", "bg": "res://resources/sprites/mine/mine_bg.png"},
	1: {"name": "Minas Congeladas", "color": Color(0.3, 0.5, 0.8), "levels": "41-80", "bg": "res://resources/sprites/mine/ice_bg.png"},
	2: {"name": "Minas de Lava", "color": Color(0.8, 0.3, 0.2), "levels": "81-120", "bg": "res://resources/sprites/mine/lava_bg.png"}
}

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false

	elevator_button.pressed.connect(_on_elevator_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	# Carrega progresso salvo
	_load_progress()

func _load_progress() -> void:
	if GameManager:
		current_level = GameManager.get_data("current_mine_level", 0)
		deepest_level = GameManager.get_data("deepest_mine_level", 0)
		unlocked_elevators = GameManager.get_data("mine_elevator_unlocked", [])
		_update_theme()

func _update_theme() -> void:
	var old_theme = current_theme
	if current_level <= 40:
		current_theme = 0
	elif current_level <= 80:
		current_theme = 1
	else:
		current_theme = 2

	if current_theme != old_theme:
		_show_theme_transition()

func _show_theme_transition() -> void:
	var theme = MINE_THEMES[current_theme]

	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func():
		# Muda fundo se tiver textura
		if ResourceLoader.exists(theme.bg):
			panel.texture = load(theme.bg)
		panel.modulate = theme.color

		tween.tween_property(panel, "modulate:a", 1.0, 0.5)

		# Partículas temáticas
		if particles:
			particles.emitting = true
			particles.one_shot = true
			match current_theme:
				0: particles.color = Color(0.5, 0.4, 0.3, 1.0)  # Poeira
				1: particles.color = Color(0.4, 0.7, 1.0, 1.0)  # Neve
				2: particles.color = Color(1.0, 0.4, 0.2, 1.0)  # Cinzas/brasa
	)

## ==================== ENTRADA NA MINA ====================
func enter_mine(level: int = -1) -> void:
	if level >= 0:
		current_level = level
	else:
		# Usa checkpoint mais próximo ou nível 1
		var checkpoint = 0
		for e in unlocked_elevators:
			if e <= deepest_level:
				checkpoint = e
		current_level = max(1, checkpoint)

	_update_theme()
	visible = true
	panel.visible = true
	panel.position = (get_viewport_rect().size - panel.size) * 0.5
	get_tree().paused = true

	_update_ui()

	# Som de entrada
	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/mine_enter.ogg")

func _update_ui() -> void:
	var theme = MINE_THEMES[current_theme]
	level_label.text = "Nível %d" % current_level
	theme_label.text = "%s (%s)" % [theme.name, theme.levels]
	theme_label.add_theme_color_override("font_color", theme.color)

	# Progress bar
	var theme_max = [40, 80, 120][current_theme]
	var theme_start = [0, 40, 80][current_theme]
	var progress = (current_level - theme_start) / (theme_max - theme_start)
	progress_bar.value = progress * 100

	# Botão elevador
	elevator_button.disabled = (current_level % 5 != 0) or (current_level <= 5)
	if elevator_button.disabled:
		elevator_button.text = "⛗ Elevador (a cada 5 níveis)"
	else:
		elevator_button.text = "⛗ Usar Elevador (Nível %d)" % current_level

func _on_elevator_pressed() -> void:
	# Abre seletor de checkpoint
	_open_elevator_selector()

func _open_elevator_selector() -> void:
	var selector = Panel.new()
	selector.name = "ElevatorSelector"
	selector.anchors_preset = 15
	selector.offset_left = 200
	selector.offset_top = 150
	selector.offset_right = -200
	selector.offset_bottom = -150

	var vbox = VBoxContainer.new()
	selector.add_child(vbox)

	var title = Label.new()
	title.text = "⛗ Elevador da Mina"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Escolha um checkpoint desbloqueado:"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.theme_override_font_size = 14
	vbox.add_child(desc)

	# Lista checkpoints (cada 5 níveis até o mais profundo)
	for i in range(5, deepest_level + 1, 5):
		if i > 120:
			break

		var unlocked = i in unlocked_elevators or i <= deepest_level
		var is_current = (i == current_level)

		var btn = Button.new()
		btn.text = "Nível %d %s" % [i, "✓" if unlocked else "🔒"]
		btn.custom_minimum_size = Vector2(0, 40)
		btn.theme_override_font_size = 16
		btn.disabled = not unlocked or is_current

		if is_current:
			btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		elif not unlocked:
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		btn.pressed.connect(_on_elevator_selected.bind(i, selector))
		vbox.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.pressed.connect(selector.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(selector)

func _on_elevator_selected(level: int, selector: Panel) -> void:
	current_level = level
	_update_theme()
	_update_ui()
	selector.queue_free()

	# Efeito de teleporte
	if ParticleManager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ParticleManager.show_level_up(player.global_position, "Elevador: Nível %d" % level)

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/elevator.ogg")

	HUD.show_notification("⛗ Elevador", "Transportado para o Nível %d" % level, Color(0.5, 1.0, 1.0))

func _on_leave_pressed() -> void:
	# Salva progresso
	if GameManager:
		GameManager.set_data("current_mine_level", current_level)
		GameManager.set_data("deepest_mine_level", deepest_level)
		GameManager.set_data("mine_elevator_unlocked", unlocked_elevators)

	visible = false
	panel.visible = false
	get_tree().paused = false

	# Teleporta player para fora
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector2(320, 400)  # Entrada da mina

	emit_signal("mine_exited", current_level)

## ==================== AVANÇAR NÍVEL ====================
func next_level() -> void:
	current_level += 1
	deepest_level = max(deepest_level, current_level)

	# Desbloqueia elevador a cada 5 níveis
	if current_level % 5 == 0 and current_level not in unlocked_elevators:
		unlocked_elevators.append(current_level)
		unlocked_elevators.sort()
		HUD.show_notification("⛗ Novo Checkpoint!", "Elevador desbloqueado no Nível %d!" % current_level, Color(0.5, 1.0, 1.0))

	# Verifica mudança de tema
	_update_theme()

	# Salva
	if GameManager:
		GameManager.set_data("current_mine_level", current_level)
		GameManager.set_data("deepest_mine_level", deepest_level)
		GameManager.set_data("mine_elevator_unlocked", unlocked_elevators)

	_update_ui()

	# Efeito de transição de nível
	_show_level_transition()

func _show_level_transition() -> void:
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.finished.connect(func():
		_update_ui()
		tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	)

	# Partículas
	if particles:
		particles.emitting = true
		particles.one_shot = true

	# Som
	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/mine_level_up.ogg")

## ==================== PÚBLICO ====================
func get_current_level() -> int:
	return current_level

func get_current_theme() -> int:
	return current_theme

func get_deepest_level() -> int:
	return deepest_level

signal mine_exited(level: int)