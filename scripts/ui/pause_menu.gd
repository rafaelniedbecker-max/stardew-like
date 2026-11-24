class_name PauseMenu
extends Control

## Menu de pausa: save, load, configurações, sair

@onready var panel: Panel = $Panel
@onready var save_button: Button = $Panel/VBoxContainer/SaveButton
@onready var load_button: Button = $Panel/VBoxContainer/LoadButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var version_label: Label = $Panel/VBoxContainer/VersionLabel

## ==================== SINAIS ====================
signal resume_requested()
signal quit_to_main_menu()
signal quit_to_desktop()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false

	resume_button.pressed.connect(_on_resume)
	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit_confirm)

	version_label.text = "v0.1.0 - Stardew-Like"

	# Input para fechar
	Input.set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and visible:
		_on_resume()
	elif event.is_action_pressed("pause") and not visible:
		show_menu()

func show_menu() -> void:
	visible = true
	panel.visible = true
	popup_centered()
	_get_tree().paused = true

	# Atualiza info do save atual
	if SaveManager:
		var slot = SaveManager.active_slot
		save_button.text = "Salvar Jogo (Slot %d)" % slot
		load_button.text = "Carregar Jogo (Slot %d)" % slot

func _on_resume() -> void:
	visible = false
	panel.visible = false
	_get_tree().paused = false
	emit_signal("resume_requested")

func _on_save() -> void:
	if SaveManager:
		var success = SaveManager.save_game()
		if success:
			HUD.show_message("Jogo salvo com sucesso!")
			save_button.text = "Salvar Jogo (Slot %d)" % SaveManager.active_slot
		else:
			HUD.show_message("Erro ao salvar!")
	_on_resume()

func _on_load() -> void:
	if SaveManager:
		var success = SaveManager.load_game(SaveManager.active_slot)
		if success:
			HUD.show_message("Jogo carregado!")
		else:
			HUD.show_message("Erro ao carregar!")
	_on_resume()

func _on_settings() -> void:
	# Abre menu de configurações
	if SettingsMenu:
		SettingsMenu.open()
	_on_resume()

func _on_quit_confirm() -> void:
	var confirm = ConfirmationDialog.new()
	confirm.title = "Sair do Jogo?"
	confirm.dialog_text = "Deseja salvar antes de sair?"
	confirm.add_button("Salvar e Sair para Menu", true).pressed.connect(_quit_save_menu.bind())
	confirm.add_button("Sair sem Salvar", false).pressed.connect(_quit_no_save.bind())
	confirm.add_button("Cancelar", false).pressed.connect(confirm.queue_free.bind())
	get_tree().root.get_child(0).add_child(confirm)
	confirm.popup_centered()

func _quit_save_menu() -> void:
	if SaveManager:
		SaveManager.save_game()
	emit_signal("quit_to_main_menu")
	_get_tree().paused = false

func _quit_no_save() -> void:
	emit_signal("quit_to_desktop")
	_get_tree().paused = false