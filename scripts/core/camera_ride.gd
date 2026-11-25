extends Node

## Passeio de Câmera Cinematográfico: tour automático pela fazenda/mundo

@export var ride_speed: float = 100.0  # pixels por segundo
@export var pause_at_points: float = 3.0  # segundos de pausa em cada ponto

## Pontos do tour predefinidos
const TOUR_POINTS = [
	{"name": "Casa do Jogador", "position": Vector2(160, 160), "zoom": 2.0, "duration": 4.0},
	{"name": "Celeiro", "position": Vector2(480, 320), "zoom": 2.0, "duration": 3.0},
	{"name": "Galinheiro", "position": Vector2(480, 480), "zoom": 2.0, "duration": 3.0},
	{"name": "Estufa", "position": Vector2(600, 100), "zoom": 1.5, "duration": 4.0},
	{"name": "Poço", "position": Vector2(320, 200), "zoom": 2.0, "duration": 2.0},
	{"name": "Silo", "position": Vector2(300, 400), "zoom": 2.0, "duration": 2.0},
	{"name": "Cava", "position": Vector2(1000, 100), "zoom": 1.5, "duration": 3.0},
	{"name": "Cidade", "position": Vector2(320, 400), "zoom": 1.5, "duration": 4.0},
	{"name": "Praia", "position": Vector2(1600, 600), "zoom": 1.5, "duration": 3.0},
	{"name": "Floresta", "position": Vector2(800, 800), "zoom": 1.5, "duration": 3.0},
	{"name": "Minas", "position": Vector2(400, 100), "zoom": 1.5, "duration": 3.0},
	{"name": "Deserto", "position": Vector2(1200, 200), "zoom": 1.5, "duration": 3.0},
]

## ==================== ESTADO ====================
var is_riding: bool = false
var current_point_index: int = 0
var ride_tween: Tween = null
var on_ride_complete: Callable = null
var custom_points: Array = []

## ==================== SINAIS ====================
signal ride_started()
signal point_reached(point_name: String, index: int)
signal ride_completed()
signal ride_cancelled()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	pass

## ==================== INICIAR PASSEIO ====================
func start_ride(points: Array = null, on_complete: Callable = null) -> void:
	if is_riding:
		return

	custom_points = points if points else TOUR_POINTS
	on_ride_complete = on_complete
	current_point_index = 0
	is_riding = true

	var camera = _get_camera()
	if not camera:
		is_riding = false
		return

	emit_signal("ride_started")
	_go_to_next_point()

func _go_to_next_point() -> void:
	if not is_riding or current_point_index >= custom_points.size():
		_finish_ride()
		return

	var point = custom_points[current_point_index]
	var camera = _get_camera()
	if not camera:
		_finish_ride()
		return

	# Anima movimento da câmera
	var target_pos = point.position
	var target_zoom = point.zoom
	var duration = _calculate_duration(camera.global_position, target_pos)

	ride_tween = camera.create_tween()
	ride_tween.tween_property(camera, "global_position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ride_tween.tween_property(camera, "zoom", Vector2(target_zoom, target_zoom), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	ride_tween.finished.connect(_on_arrived.bind(point))

	# Feedback visual
	HUD.show_notification("🎬 Tour: %s" % point.name, "", "info", 2.0)

func _on_arrived(point: Dictionary) -> void:
	if not is_riding:
		return

	emit_signal("point_reached", point.name, current_point_index)

	# Pausa no ponto
	var pause_duration = point.duration if point.has("duration") else pause_at_points

	var timer = Timer.new()
	timer.wait_time = pause_duration
	timer.one_shot = true
	timer.timeout.connect(_continue_ride)
	add_child(timer)
	timer.start()

func _continue_ride() -> void:
	current_point_index += 1
	_go_to_next_point()

func _finish_ride() -> void:
	is_riding = false
	current_point_index = 0

	if ride_tween:
		ride_tween.kill()
		ride_tween = null

	emit_signal("ride_completed")

	if on_ride_complete:
		on_ride_complete.call()

	HUD.show_notification("🎬 Tour Finalizado", "Passeio pela fazenda concluído!", "achievement", 3.0)

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/tour_complete.ogg")

## ==================== CANCELAR ====================
func cancel_ride() -> void:
	if not is_riding:
		return

	is_riding = false

	if ride_tween:
		ride_tween.kill()
		ride_tween = null

	emit_signal("ride_cancelled")
	HUD.show_message("Tour cancelado.")

## ==================== UTILIDADES ====================
func _get_camera() -> Camera2D:
	var player = get_tree().root.get_child(0).get_node_or_null("Player")
	if player:
		return player.get_node_or_null("Camera2D")
	return null

func _calculate_duration(from: Vector2, to: Vector2) -> float:
	var distance = from.distance_to(to)
	return max(1.0, distance / ride_speed)

func pause_ride() -> void:
	if not is_riding:
		return

	if ride_tween:
		ride_tween.pause()

func resume_ride() -> void:
	if not is_riding:
		return

	if ride_tween:
		ride_tween.resume()

## ==================== TOURS PERSONALIZADOS ====================
## Tour pelas construções
static func get_buildings_tour() -> Array:
	return [
		{"name": "Casa", "position": Vector2(160, 160), "zoom": 2.5, "duration": 4.0},
		{"name": "Celeiro Deluxe", "position": Vector2(480, 320), "zoom": 2.0, "duration": 4.0},
		{"name": "Galinheiro Deluxe", "position": Vector2(480, 480), "zoom": 2.0, "duration": 4.0},
		{"name": "Estábulo", "position": Vector2(560, 320), "zoom": 2.0, "duration": 3.0},
		{"name": "Slime Hutch", "position": Vector2(600, 400), "zoom": 2.0, "duration": 3.0},
		{"name": "Fish Pond", "position": Vector2(520, 560), "zoom": 2.0, "duration": 3.0},
		{"name": "Estufa", "position": Vector2(600, 100), "zoom": 1.8, "duration": 4.0},
		{"name": "Silo", "position": Vector2(300, 400), "zoom": 2.0, "duration": 2.0},
		{"name": "Poço", "position": Vector2(320, 200), "zoom": 2.0, "duration": 2.0},
		{"name": "Cava", "position": Vector2(1000, 100), "zoom": 1.5, "duration": 3.0},
	]

## Tour sazonal (mostra plantações)
static func get_seasonal_tour(season: int) -> Array:
	var season_names = ["Primavera", "Verão", "Outono", "Inverno"]
	var points = TOUR_POINTS.duplicate()
	points.insert(0, {"name": "Tour de %s" % season_names[season], "position": Vector2(160, 160), "zoom": 2.0, "duration": 3.0})
	return points

## Tour das minas
static func get_mines_tour() -> Array:
	return [
		{"name": "Entrada Minas (Andar 1)", "position": Vector2(400, 100), "zoom": 1.5, "duration": 3.0},
		{"name": "Andar 10 - Primeiro Elevador", "position": Vector2(500, 150), "zoom": 1.5, "duration": 2.0},
		{"name": "Andar 20 - Minério de Ferro", "position": Vector2(550, 200), "zoom": 1.5, "duration": 2.0},
		{"name": "Andar 30 - Ouro", "position": Vector2(600, 250), "zoom": 1.5, "duration": 2.0},
		{"name": "Andar 40 - Segundo Elevador", "position": Vector2(650, 300), "zoom": 1.5, "duration": 2.0},
		{"name": "Andar 50 - Irídio Início", "position": Vector2(700, 350), "zoom": 1.5, "duration": 2.0},
		{"name": "Andar 80 - Gemas Raras", "position": Vector2(800, 450), "zoom": 1.5, "duration": 2.0},
		{"name": "Andar 100 - Fim Minas", "position": Vector2(900, 500), "zoom": 1.5, "duration": 3.0},
		{"name": "Skull Cavern Entrada", "position": Vector2(1200, 200), "zoom": 1.5, "duration": 3.0},
	]

## ==================== UI DE CONTROLE ====================
func open_control_ui() -> void:
	var panel = Panel.new()
	panel.name = "CameraRideUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 100
	panel.offset_right = -200
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🎬 Câmera Tour"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var buttons = [
		{"text": "🌾 Tour Completo", "callback": func(): start_ride()},
		{"text": "🏠 Tour Construções", "callback": func(): start_ride(CameraRide.get_buildings_tour())},
		{"text": "⛏️ Tour Minas", "callback": func(): start_ride(CameraRide.get_mines_tour())},
		{"text": "🌸 Tour Primavera", "callback": func(): start_ride(CameraRide.get_seasonal_tour(0))},
		{"text": "☀️ Tour Verão", "callback": func(): start_ride(CameraRide.get_seasonal_tour(1))},
		{"text": "🍂 Tour Outono", "callback": func(): start_ride(CameraRide.get_seasonal_tour(2))},
		{"text": "❄️ Tour Inverno", "callback": func(): start_ride(CameraRide.get_seasonal_tour(3))},
	]

	for btn_data in buttons:
		var btn = Button.new()
		btn.text = btn_data.text
		btn.custom_minimum_size = Vector2(0, 45)
		btn.theme_override_font_size = 16
		btn.pressed.connect(func(): _start_selected(btn_data.callback, panel))
		vbox.add_child(btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "❌ Cancelar"
	cancel_btn.custom_minimum_size = Vector2(0, 40)
	cancel_btn.theme_override_font_size = 14
	cancel_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(cancel_btn)

	get_tree().root.get_child(0).add_child(panel)

func _start_selected(callback: Callable, panel: Panel) -> void:
	callback.call()
	panel.queue_free()