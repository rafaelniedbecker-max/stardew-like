extends Control

## Menu de configurações: áudio, vídeo, controles, gameplay

@onready var panel: Panel = $Panel
@onready var tab_bar: TabContainer = $Panel/TabBar
@onready var close_button: Button = $Panel/CloseButton

## Configurações atuais
var settings: Dictionary = {}

const DEFAULT_SETTINGS = {
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"ambient_volume": 0.6
	},
	"video": {
		"fullscreen": false,
		"vsync": true,
		"resolution": "1280x720",
		"zoom": 2.0
	},
	"controls": {
		"keyboard_layout": "WASD",
		"controller_enabled": true,
		"vibration": true
	},
	"gameplay": {
		"auto_save": true,
		"show_tooltips": true,
		"show_fps": false,
		"language": "pt-BR"
	}
}

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	close_button.pressed.connect(hide)

	_load_settings()
	_create_tabs()
	_populate_controls()

func _load_settings() -> void:
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		settings = json
	else:
		settings = DEFAULT_SETTINGS.duplicate(true)
	_save_settings()

	_applies_settings()

func _save_settings() -> void:
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()

func _applies_settings() -> void:
	# Áudio
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(settings.audio.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(settings.audio.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(settings.audio.sfx_volume))

	# Vídeo
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.video.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.video.vsync else DisplayServer.VSYNC_DISABLED)

	# Gameplay
	if GameManager:
		GameManager.auto_save_enabled = settings.gameplay.auto_save

func _create_tabs() -> void:
	var tabs_data = [
		{"name": "🔊 Áudio", "scene": _create_audio_tab()},
		{"name": "🖥 Vídeo", "scene": _create_video_tab()},
		{"name": "⌨ Controles", "scene": _create_controls_tab()},
		{"name": "🎮 Gameplay", "scene": _create_gameplay_tab()}
	]

	for tab in tabs_data:
		tab_bar.add_child(tab.scene)
		tab_bar.set_tab_title(tab_bar.get_child_count() - 1, tab.name)

func _populate_controls() -> void:
	# Será chamado após criar tabs
	pass

## ==================== ABA: ÁUDIO ====================
func _create_audio_tab() -> ScrollContainer:
	var scroll = ScrollContainer.new()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(vbox)

	# Master Volume
	var master = _create_slider_row("Volume Geral", "audio", "master_volume", 0.0, 1.0, 0.05)
	vbox.add_child(master)

	# Music Volume
	var music = _create_slider_row("Volume Música", "audio", "music_volume", 0.0, 1.0, 0.05)
	vbox.add_child(music)

	# SFX Volume
	var sfx = _create_slider_row("Volume Efeitos", "audio", "sfx_volume", 0.0, 1.0, 0.05)
	vbox.add_child(sfx)

	# Ambient Volume
	var ambient = _create_slider_row("Volume Ambiente", "audio", "ambient_volume", 0.0, 1.0, 0.05)
	vbox.add_child(ambient)

	# Botão testar som
	var test_btn = Button.new()
	test_btn.text = "🔊 Testar Som"
	test_btn.custom_minimum_size = Vector2(0, 40)
	test_btn.pressed.connect(_test_sound.bind())
	vbox.add_child(test_btn)

	return scroll

## ==================== ABA: VÍDEO ====================
func _create_video_tab() -> ScrollContainer:
	var scroll = ScrollContainer.new()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(vbox)

	# Fullscreen
	var fs = _create_check_row("Tela Cheia", "video", "fullscreen")
	vbox.add_child(fs)

	# VSync
	var vsync = _create_check_row("V-Sync", "video", "vsync")
	vbox.add_child(vsync)

	# Resolução
	var res = _create_option_row("Resolução", "video", "resolution", ["1280x720", "1600x900", "1920x1080", "2560x1440"])
	vbox.add_child(res)

	# Zoom
	var zoom = _create_slider_row("Zoom da Câmera", "video", "zoom", 1.0, 4.0, 0.25)
	vbox.add_child(zoom)

	return scroll

## ==================== ABA: CONTROLES ====================
func _create_controls_tab() -> ScrollContainer:
	var scroll = ScrollContainer.new()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(vbox)

	# Layout teclado
	var layout = _create_option_row("Layout Teclado", "controls", "keyboard_layout", ["WASD", "Setas", "AZERTY"])
	vbox.add_child(layout)

	# Controller
	var ctrl = _create_check_row("Habilitar Controle", "controls", "controller_enabled")
	vbox.add_child(ctrl)

	# Vibração
	var vib = _create_check_row("Vibração do Controle", "controls", "vibration")
	vbox.add_child(vib)

	# Botão remapear
	var remap_btn = Button.new()
	remap_btn.text = "⌨ Remapear Teclas"
	remap_btn.custom_minimum_size = Vector2(0, 40)
	remap_btn.pressed.connect(_open_remap_dialog.bind())
	vbox.add_child(remap_btn)

	return scroll

## ==================== ABA: GAMEPLAY ====================
func _create_gameplay_tab() -> ScrollContainer:
	var scroll = ScrollContainer.new()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	scroll.add_child(vbox)

	# Auto-save
	var autosave = _create_check_row("Auto-save a cada hora", "gameplay", "auto_save")
	vbox.add_child(autosave)

	# Tooltips
	var tips = _create_check_row("Mostrar Dicas", "gameplay", "show_tooltips")
	vbox.add_child(tips)

	# FPS
	var fps = _create_check_row("Mostrar FPS", "gameplay", "show_fps")
	vbox.add_child(fps)

	# Idioma
	var lang = _create_option_row("Idioma", "gameplay", "language", ["pt-BR", "en-US", "es-ES", "fr-FR"])
	vbox.add_child(lang)

	return scroll

## ==================== HELPERS UI ====================
func _create_slider_row(label_text: String, category: String, key: String, min_val: float, max_val: float, step: float) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	label.theme_override_font_size = 18
	hbox.add_child(label)

	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = step
	slider.value = settings[category][key]
	slider.custom_minimum_size = Vector2(200, 0)
	slider.value_changed.connect(_on_slider_changed.bind(category, key))
	hbox.add_child(slider)

	var value_label = Label.new()
	value_label.text = "%d%%" % int(settings[category][key] * 100)
	value_label.custom_minimum_size = Vector2(60, 0)
	value_label.theme_override_font_size = 18
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slider.value_changed.connect(value_label.set_text.bind("%d%%" % int(slider.value * 100)))
	hbox.add_child(value_label)

	return hbox

func _create_check_row(label_text: String, category: String, key: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(250, 0)
	label.theme_override_font_size = 18
	hbox.add_child(label)

	var check = CheckBox.new()
	check.pressed = settings[category][key]
	check.toggled.connect(_on_check_toggled.bind(category, key))
	hbox.add_child(check)

	return hbox

func _create_option_row(label_text: String, category: String, key: String, options: Array[String]) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var label = Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(180, 0)
	label.theme_override_font_size = 18
	hbox.add_child(label)

	var option_btn = OptionButton.new()
	for opt in options:
		option_btn.add_item(opt)
	option_btn.selected = options.find(settings[category][key])
	option_btn.custom_minimum_size = Vector2(200, 0)
	option_btn.item_selected.connect(_on_option_selected.bind(category, key, options))
	hbox.add_child(option_btn)

	return hbox

## ==================== CALLBACKS ====================
func _on_slider_changed(value: float, category: String, key: String) -> void:
	settings[category][key] = value
	_save_settings()
	_applies_settings()

func _on_check_toggled(pressed: bool, category: String, key: String) -> void:
	settings[category][key] = pressed
	_save_settings()
	_applies_settings()

func _on_option_selected(index: int, category: String, key: String, options: Array[String]) -> void:
	settings[category][key] = options[index]
	_save_settings()
	_applies_settings()

func _test_sound() -> void:
	# Toca som de teste
	if AudioServer:
		# Cria player temporário
		var player = AudioStreamPlayer.new()
		player.stream = load("res://assets/sfx/ui_click.ogg") if ResourceLoader.exists("res://assets/sfx/ui_click.ogg") else null
		if player.stream:
			player.bus = "SFX"
			player.play()
		player.finished.connect(player.queue_free.bind())
		get_tree().root.get_child(0).add_child(player)

func _open_remap_dialog() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Remapear Controles"
	dialog.dialog_text = "Funcionalidade de remapeamento será implementada.\nPor enquanto, edite o Input Map em Project Settings."
	dialog.add_button("OK", true)
	get_tree().root.get_child(0).add_child(dialog)
	dialog.popup_centered()

## ==================== PÚBLICO ====================
func open() -> void:
	visible = true
	panel.visible = true
	panel.position = (get_viewport_rect().size - panel.size) * 0.5
	get_tree().paused = true

@warning_ignore("native_method_override")
func hide() -> void:
	visible = false
	panel.visible = false
	get_tree().paused = false