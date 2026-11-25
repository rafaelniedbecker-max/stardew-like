extends Node

## Gerencia o relógio do jogo, estações e eventos temporais

@export var tick_rate: float = 1.0  # Minutos de jogo por segundo real (padrão: 1 min/seg = 24h = 24min real)
@export var paused: bool = false

## Tempo acumulado para ticks
var _accumulator: float = 0.0

## Callbacks registrados para horários específicos
var _time_callbacks: Dictionary = {}  # {time: [callable]}

## Eventos agendados: {event_id: {time, callable, repeating}}
var _scheduled_events: Dictionary = {}

## ==================== SINAIS ====================
signal minute_ticked(new_time: int)
signal hour_changed(new_hour: int)
signal day_started()
signal day_ended()
signal season_changed(season: int)
signal year_changed(year: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Conecta ao GameManager
	if GameManager:
		GameManager.time_changed.connect(_on_time_changed)

func _process(delta: float) -> void:
	if paused:
		return

	# Apenas roda se GameManager existir
	if not GameManager:
		return

	_accumulator += delta * tick_rate  # tick_rate = minutos de jogo por segundo real

	while _accumulator >= 1.0:
		_accumulator -= 1.0
		_tick_minute()

func _tick_minute() -> void:
	var old_time = GameManager.current_time
	GameManager.advance_time(1)

	# Verifica callbacks para esta hora
	var new_time = GameManager.current_time
	if _time_callbacks.has(new_time):
		for callback in _time_callbacks[new_time]:
			callback.call()

	# Verifica eventos agendados
	_check_scheduled_events(new_time)

	emit_signal("minute_ticked", new_time)

	# Verifica mudança de hora
	var old_hour = old_time / 100
	var new_hour = new_time / 100
	if old_hour != new_hour:
		emit_signal("hour_changed", new_hour)

func _on_time_changed(new_time: int) -> void:
	# Sincroniza se necessário
	pass

## ==================== CALLBACKS DE HORÁRIO ====================

## Registra callback para um horário específico (ex: 1800 = 6PM)
func register_time_callback(time: int, callback: Callable) -> void:
	if not _time_callbacks.has(time):
		_time_callbacks[time] = []
	_time_callbacks[time].append(callback)

## Remove callback
func unregister_time_callback(time: int, callback: Callable) -> void:
	if _time_callbacks.has(time):
		_time_callbacks[time].erase(callback)
		if _time_callbacks[time].is_empty():
			_time_callbacks.erase(time)

## ==================== EVENTOS AGENDADOS ====================

## Agenda evento único
func schedule_event(event_id: String, time: int, callback: Callable) -> void:
	_scheduled_events[event_id] = {
		"time": time,
		"callback": callback,
		"repeating": false,
		"days": []
	}

## Agenda evento repetitivo (diário, semanal, etc.)
func schedule_recurring_event(event_id: String, time: int, callback: Callable, days: Array[int] = [-1]) -> void:
	_scheduled_events[event_id] = {
		"time": time,
		"callback": callback,
		"repeating": true,
		"days": days  # -1 = todos os dias, 0-6 = dias da semana
	}

## Cancela evento agendado
func cancel_event(event_id: String) -> void:
	_scheduled_events.erase(event_id)

func _check_scheduled_events(current_time: int) -> void:
	var current_day = GameManager.current_weekday
	var to_remove = []

	for event_id in _scheduled_events:
		var event = _scheduled_events[event_id]
		if event.time == current_time:
			var should_trigger = false
			if event.repeating:
				if -1 in event.days or current_day in event.days:
					should_trigger = true
			else:
				should_trigger = true
				to_remove.append(event_id)

			if should_trigger:
				event.callback.call()

	for id in to_remove:
		_scheduled_events.erase(id)

## ==================== UTILIDADES DE TEMPO ====================

## Converte minutos para string legível
static func time_to_string(time: int) -> String:
	var hours = time / 100
	var mins = time % 100
	var period = "AM"
	if hours >= 12:
		period = "PM"
		if hours > 12:
			hours -= 12
	if hours == 0:
		hours = 12
	return "%02d:%02d %s" % [hours, mins, period]

## Converte string para minutos (ex: "6:00 AM" -> 600)
static func string_to_time(time_str: String) -> int:
	var parts = time_str.split(" ")
	var time_part = parts[0]
	var period = parts[1] if parts.size() > 1 else "AM"
	var hm = time_part.split(":")
	var hours = hm[0].to_int()
	var mins = hm[1].to_int() if hm.size() > 1 else 0

	if period == "PM" and hours != 12:
		hours += 12
	elif period == "AM" and hours == 12:
		hours = 0

	return hours * 100 + mins

## Retorna progressão do dia (0.0 a 1.0)
static func get_day_progress(time: int) -> float:
	# Dia vai de 6:00 (600) a 2:00 (2600) = 20 horas = 1200 minutos
	var day_start = 600
	var day_end = 2600
	if time < day_start:
		return 0.0
	if time >= day_end:
		return 1.0
	return (time - day_start) / (day_end - day_start)

## Retorna se é noite (após 18:00)
static func is_night(time: int) -> bool:
	return time >= 1800

## Retorna se é madrugada (meia-noite a 6:00)
static func is_late_night(time: int) -> bool:
	return time >= 2400 or time < 600

## Retorna minutos até um horário
static func minutes_until(current: int, target: int) -> int:
	var diff = target - current
	if diff < 0:
		diff += 2000  # Próximo dia (aproximado)
	return diff

## Formata duração em minutos para string
static func format_duration(minutes: int) -> String:
	if minutes < 60:
		return "%d min" % minutes
	var hours = minutes / 60
	var mins = minutes % 60
	if mins == 0:
		return "%dh" % hours
	return "%dh %dmin" % [hours, mins]

## ==================== PAUSA/CONTROLE ====================
func set_paused(p: bool) -> void:
	paused = p

func set_time_scale(scale: float) -> void:
	tick_rate = max(0.0, scale)

## Para usar em menus/diálogos
func pause_game() -> void:
	paused = true

func resume_game() -> void:
	paused = false