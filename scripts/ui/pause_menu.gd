extends Control

## Menu de pausa: save, load, configurações, sair

@onready var panel: Panel = $Panel
@onready var vbox: VBoxContainer = $Panel/VBoxContainer
@onready var resume_button: Button
@onready var save_button: Button
@onready var load_button: Button
@onready var settings_button: Button
@onready var quit_button: Button
@onready var version_label: Label

## ==================== SINAIS ====================
signal resume_requested()
signal quit_to_main_menu()
signal quit_to_desktop()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false

	# Cria botões via UIStyle se não existirem na cena
	_setup_buttons()

	resume_button.pressed.connect(_on_resume)
	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit_confirm)

	version_label.text = "v0.1.0 - Stardew-Like"
	UIStyle.apply_to_label(version_label, "caption")
	version_label.add_theme_color_override("font_color", UIStyle.get_color("ink_muted"))

	# Input para fechar
	set_process_unhandled_input(true)

func _setup_buttons() -> void:
	# Resume
	resume_button = vbox.get_node_or_null("ResumeButton")
	if not resume_button:
		resume_button = UIStyle.create_button("▶ Continuar", "primary", "large", _on_resume.bind())
		vbox.add_child(resume_button)
		resume_button.move_child(resume_button, 0)
	else:
		UIStyle.apply_to_button(resume_button, "primary", "large")

	# Save
	save_button = vbox.get_node_or_null("SaveButton")
	if not save_button:
		save_button = UIStyle.create_button("💾 Salvar Jogo", "secondary", "medium", _on_save.bind())
		vbox.add_child(save_button)
	else:
		UIStyle.apply_to_button(save_button, "secondary", "medium")

	# Load
	load_button = vbox.get_node_or_null("LoadButton")
	if not load_button:
		load_button = UIStyle.create_button("📂 Carregar Jogo", "secondary", "medium", _on_load.bind())
		vbox.add_child(load_button)
	else:
		UIStyle.apply_to_button(load_button, "secondary", "medium")

	# Settings
	settings_button = vbox.get_node_or_null("SettingsButton")
	if not settings_button:
		settings_button = UIStyle.create_button("⚙ Configurações", "secondary", "medium", _on_settings.bind())
		vbox.add_child(settings_button)
	else:
		UIStyle.apply_to_button(settings_button, "secondary", "medium")

	# Quit
	quit_button = vbox.get_node_or_null("QuitButton")
	if not quit_button:
		quit_button = UIStyle.create_button("🚪 Sair para Menu", "ghost", "medium", _on_quit_confirm.bind())
		vbox.add_child(quit_button)
	else:
		UIStyle.apply_to_button(quit_button, "ghost", "medium")

	# Espaçamento
	vbox.add_theme_constant_override("separation", UIStyle.SPACING.lg)
	vbox.add_theme_constant_override("margin_left", UIStyle.SPACING.xl)
	vbox.add_theme_constant_override("margin_right", UIStyle.SPACING.xl)
	vbox.add_theme_constant_override("margin_top", UIStyle.SPACING.xl)
	vbox.add_theme_constant_override("margin_bottom", UIStyle.SPACING.xl)

	# Panel styling
	UIStyle.apply_to_panel(panel, "default")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and visible:
		_on_resume()
	elif event.is_action_pressed("pause") and not visible:
		show_menu()

func show_menu() -> void:
	visible = true
	panel.visible = true
	panel.position = (get_viewport_rect().size - panel.size) * 0.5
	get_tree().paused = true

	# Atualiza info do save atual
	if SaveManager:
		var slot = SaveManager.active_slot
		save_button.text = "💾 Salvar Jogo (Slot %d)" % slot
		load_button.text = "📂 Carregar Jogo (Slot %d)" % slot

func _on_resume() -> void:
	visible = false
	panel.visible = false
	get_tree().paused = false
	emit_signal("resume_requested")

func _on_save() -> void:
	if SaveManager:
		var success = SaveManager.save_game()
		if success:
			UIStyle.show_toast("💾 Salvo", "Jogo salvo com sucesso!", "success")
			if SaveManager:
				save_button.text = "💾 Salvar Jogo (Slot %d)" % SaveManager.active_slot
		else:
			UIStyle.show_toast("❌ Erro", "Erro ao salvar!", "danger")
	_on_resume()

func _on_load() -> void:
	if SaveManager:
		var success = SaveManager.load_game(SaveManager.active_slot)
		if success:
			UIStyle.show_toast("📂 Carregado", "Jogo carregado!", "success")
		else:
			UIStyle.show_toast("❌ Erro", "Erro ao carregar!", "danger")
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
	get_tree().paused = false

func _quit_no_save() -> void:
	emit_signal("quit_to_desktop")
	get_tree().paused = false