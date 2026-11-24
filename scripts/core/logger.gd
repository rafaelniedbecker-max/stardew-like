class_name Logger
extends Node

## Sistema de log centralizado com salvamento automático em arquivo

@export var log_level: int = 2  # 0=DEBUG, 1=INFO, 2=WARNING, 3=ERROR
@export var max_log_entries: int = 1000
@export var auto_save_on_error: bool = true
@export var log_to_file: bool = true
@export var log_folder: String = "user://logs/"

## Níveis de log
const LEVEL_DEBUG = 0
const LEVEL_INFO = 1
const LEVEL_WARNING = 2
const LEVEL_ERROR = 3

const LEVEL_NAMES = ["DEBUG", "INFO", "WARN", "ERROR"]
const LEVEL_COLORS = {
	LEVEL_DEBUG: Color(0.5, 0.5, 0.8),
	LEVEL_INFO: Color(0.4, 0.8, 0.4),
	LEVEL_WARNING: Color(1.0, 0.8, 0.2),
	LEVEL_ERROR: Color(1.0, 0.3, 0.3)
}

## Buffer de logs em memória
var _log_buffer: Array[Dictionary] = []
var _log_file: FileAccess = null
var _current_log_file: String = ""

## ==================== SINAIS ====================
signal log_received(level: int, message: String, timestamp: Dictionary)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_setup_log_file()

	# Intercepta prints e erros do Godot
	OS.set_print_handler(_on_print.bind())
	OS.set_error_handler(_on_error.bind())

	log_info("Logger inicializado")

func _setup_log_file() -> void:
	if not log_to_file:
		return

	var dir = DirAccess.open(log_folder)
	if not dir:
		DirAccess.make_dir_recursive_absolute(log_folder)

	var timestamp = Time.get_datetime_string_from_system(false).replace(":", "-").replace("/", "-")
	_current_log_file = log_folder + "game_log_%s.txt" % timestamp

	_log_file = FileAccess.open(_current_log_file, FileAccess.WRITE)
	if _log_file:
		_log_file.store_line("=== Stardew-Like Log iniciado em %s ===" % Time.get_datetime_string_from_system(true))
		_log_file.store_line("Versão Godot: %s" % Engine.get_version_info()["string"])
		_log_file.store_line("")

## ==================== INTERCEPTAÇÃO DE PRINTS/ERROS ====================
func _on_print(message: String, is_error: bool) -> void:
	if is_error:
		log_error(message)
	else:
		log_debug(message)

func _on_error(function: String, message: String, stack: String) -> void:
	var full_msg = "[%s] %s\nStack: %s" % [function, message, stack]
	log_error(full_msg)

## ==================== MÉTODOS DE LOG ====================
func log_debug(message: String) -> void:
	_write_log(LEVEL_DEBUG, message)

func log_info(message: String) -> void:
	_write_log(LEVEL_INFO, message)

func log_warning(message: String) -> void:
	_write_log(LEVEL_WARNING, message)

func log_error(message: String) -> void:
	_write_log(LEVEL_ERROR, message)

	# Auto-save se configurado
	if auto_save_on_error and SaveManager:
		call_deferred("_auto_save_on_crash")

func _write_log(level: int, message: String) -> void:
	if level < log_level:
		return

	var timestamp = Time.get_datetime_dict_from_system()
	var time_str = "%02d:%02d:%02d" % [timestamp.hour, timestamp.minute, timestamp.second]
	var level_name = LEVEL_NAMES[level]

	var entry = {
		"level": level,
		"level_name": level_name,
		"message": message,
		"time": time_str,
		"timestamp": timestamp,
		"frame": Engine.get_frames_drawn()
	}

	_log_buffer.append(entry)

	# Mantém buffer limitado
	if _log_buffer.size() > max_log_entries:
		_log_buffer.pop_front()

	# Escreve no arquivo
	if _log_file:
		_log_file.store_line("[%s] [%s] %s" % [time_str, level_name, message])
		_log_file.flush()

	emit_signal("log_received", level, message, timestamp)

## ==================== AUTO-SAVE EM ERRO CRÍTICO ====================
func _auto_save_on_crash() -> void:
	if SaveManager:
		var slot = SaveManager.active_slot
		SaveManager.save_game(0)  # Salva no slot 0 (autosave de emergência)
		log_info("Auto-save de emergência realizado no slot 0")

## ==================== UTILIDADES ====================
func get_recent_logs(count: int = 50) -> Array[Dictionary]:
	var start = max(0, _log_buffer.size() - count)
	return _log_buffer.slice(start, _log_buffer.size())

func get_errors_only() -> Array[Dictionary]:
	var errors = []
	for entry in _log_buffer:
		if entry.level >= LEVEL_ERROR:
			errors.append(entry)
	return errors

func clear_logs() -> void:
	_log_buffer.clear()
	if _log_file:
		_log_file.close()
	_setup_log_file()

func export_logs(file_path: String = "") -> bool:
	if file_path == "":
		file_path = log_folder + "exported_log_%s.txt" % Time.get_datetime_string_from_system(false).replace(":", "-")

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return false

	file.store_line("=== Exportação de Logs ===")
	file.store_line("Data: %s" % Time.get_datetime_string_from_system(true))
	file.store_line("Total de entradas: %d" % _log_buffer.size())
	file.store_line("")

	for entry in _log_buffer:
		file.store_line("[%s] [%s] %s" % [entry.time, entry.level_name, entry.message])

	file.close()
	log_info("Logs exportados para: %s" % file_path)
	return true

## ==================== CONTEXTO DE DEBUG ====================
func log_with_context(level: int, message: String, context: Dictionary = {}) -> void:
	var ctx_str = ""
	if context.size() > 0:
		ctx_str = " | Contexto: " + JSON.stringify(context)
	_write_log(level, message + ctx_str)

# Métodos de conveniência
func debug(message: String, context: Dictionary = {}) -> void:
	log_with_context(LEVEL_DEBUG, message, context)

func info(message: String, context: Dictionary = {}) -> void:
	log_with_context(LEVEL_INFO, message, context)

func warn(message: String, context: Dictionary = {}) -> void:
	log_with_context(LEVEL_WARNING, message, context)

func error(message: String, context: Dictionary = {}) -> void:
	log_with_context(LEVEL_ERROR, message, context)

## ==================== FINALIZAÇÃO ====================
func _exit_tree() -> void:
	if _log_file:
		_log_file.store_line("")
		_log_file.store_line("=== Log finalizado em %s ===" % Time.get_datetime_string_from_system(true))
		_log_file.close()