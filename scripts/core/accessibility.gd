class_name Accessibility
extends Node

## Sistema de Acessibilidade: opções para diferentes necessidades

## ==================== CONFIGURAÇÕES ====================
@export var settings: Dictionary = {}

const DEFAULT_SETTINGS = {
	# Visual
	"high_contrast": false,
	"colorblind_mode": "none",  # none, protanopia, deuteranopia, tritanopia
	"text_size": 1.0,
	"ui_scale": 1.0,
	"reduce_motion": false,
	"screen_shake": true,
	"particle_effects": true,
	"weather_effects": true,
	"show_damage_numbers": true,
	"show_floating_text": true,

	# Audio
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"ambient_volume": 0.6,
	"mute_on_focus_loss": true,
	"visual_sound_indicators": false,

	# Gameplay
	"auto_save": true,
	"auto_run": false,
	"hold_to_continue": false,
	"simplified_fishing": false,
	"simplified_mining": false,
	"always_show_tooltips": true,
	"confirm_dangerous_actions": true,
	"pause_on_focus_loss": true,

	# Controls
	"keybindings": {},
	"controller_vibration": true,
	"controller_sensitivity": 1.0,
	"swap_accept_cancel": false,
	"invert_camera_x": false,
	"invert_camera_y": false,

	# Language
	"language": "pt-BR",
	"subtitle_size": 1.0,
	"show_subtitles": true
}

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_settings()
	_apply_settings()

	# Conecta mudanças de configuração
	if SettingsMenu:
		SettingsMenu.settings_changed.connect(_on_settings_changed)

func _load_settings() -> void:
	var file = FileAccess.open("user://accessibility_settings.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		settings = json
		file.close()
	else:
		settings = DEFAULT_SETTINGS.duplicate()
		_save_settings()

func _save_settings() -> void:
	var file = FileAccess.open("user://accessibility_settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()

func _apply_settings() -> void:
	# Visual
	_if_high_contrast()
	_if_colorblind()
	_if_text_size()
	_if_ui_scale()
	_if_reduce_motion()
	_if_visual_sound_indicators()

	# Audio
	_if_audio_volumes()
	_if_mute_on_focus_loss()
	_if_visual_sound_indicators()

	# Gameplay
	_if_auto_save()
	_if_auto_run()
	_if_simplified_fishing()
	_if_always_show_tooltips()

	# Controls
	_if_controller_settings()

	# Language
	_if_language()

func _on_settings_changed(category: String, key: String, value: Variant) -> void:
	settings[key] = value
	_save_settings()
	_apply_settings()

## ==================== VISUAL ====================
func _if_high_contrast() -> void:
	var canvas = get_tree().root.get_child(0).get_node_or_null("HighContrastModulate")
	if settings.high_contrast:
		if not canvas:
			canvas = CanvasModulate.new()
			canvas.name = "HighContrastModulate"
			get_tree().root.get_child(0).add_child(canvas)
		canvas.color = Color(1, 1, 1, 1)  # Shader de alto contraste seria melhor
	else:
		if canvas:
			canvas.queue_free()

func _if_colorblind() -> void:
	# Aplica shader de daltonismo
	var shader = get_tree().root.get_child(0).get_node_or_null("ColorblindShader")
	var mode = settings.colorblind_mode

	if mode != "none":
		if not shader:
			shader = ColorRect.new()
			shader.name = "ColorblindShader"
			shader.anchors_preset = 15
			get_tree().root.get_child(0).add_child(shader)

		var shader_code = """
			shader_type canvas_item;
			uniform sampler2D screen_texture;
			uniform int mode; // 1=protanopia, 2=deuteranopia, 3=tritanopia
			void fragment() {
				vec4 color = texture(screen_texture, UV);
				if (mode == 1) { // Protanopia
					color.r = color.r * 0.567 + color.g * 0.433;
					color.g = color.r * 0.558 + color.g * 0.442;
				} else if (mode == 2) { // Deuteranopia
					color.r = color.r * 0.625 + color.g * 0.375;
					color.g = color.r * 0.7 + color.g * 0.3;
				} else if (mode == 3) { // Tritanopia
					color.g = color.g * 0.95 + color.b * 0.05;
					color.b = color.g * 0.433 + color.b * 0.567;
				}
				COLOR = color;
			}
		"""
		shader.material = ShaderMaterial.new()
		shader.material.shader = Shader.new()
		shader.material.shader.code = shader_code
		shader.material.set_shader_parameter("mode", {"protanopia": 1, "deuteranopia": 2, "tritanopia": 3}[mode])
	else:
		if shader:
			shader.queue_free()

func _if_text_size() -> void:
	# Aplica escala de texto globalmente
	var scale = settings.text_size
	# Em Godot, isso seria via theme override ou scaling individual

func _if_ui_scale() -> void:
	var scale = settings.ui_scale
	# Aplica via viewport scaling ou anchor scaling

func _if_reduce_motion() -> void:
	if settings.reduce_motion:
		# Desabilita animações desnecessárias
		# Reduz particle amounts
		if ParticleManager:
			# ParticleManager.set_global_scale(0.5)
			pass
		# Desabilita screen shake
		settings.screen_shake = false

func _if_visual_sound_indicators() -> void:
	if settings.visual_sound_indicators:
		# Ativa indicadores visuais para sons importantes
		# Ex: flash na tela para passos, alertas, etc.
		if AudioManager:
			AudioManager.visual_indicators_enabled = true

## ==================== AUDIO ====================
func _if_audio_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(settings.master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(settings.music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(settings.sfx_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambient"), linear_to_db(settings.ambient_volume))

func _if_mute_on_focus_loss() -> void:
	# Godot já faz isso por padrão, mas podemos forçar
	OS.set_low_processor_usage_mode(settings.mute_on_focus_loss)

## ==================== GAMEPLAY ====================
func _if_auto_save() -> void:
	if SaveManager:
		SaveManager.auto_save_enabled = settings.auto_save

func _if_auto_run() -> void:
	if Player:
		Player.auto_run_enabled = settings.auto_run

func _if_simplified_fishing() -> void:
	if FishingManager:
		FishingManager.simplified_mode = settings.simplified_fishing

func _if_always_show_tooltips() -> void:
	if HUD:
		HUD.always_show_tooltips = settings.always_show_tooltips

## ==================== CONTROLS ====================
func _if_controller_settings() -> void:
	if Input:
		Input.set_vibration_enabled(settings.controller_vibration)
		# Sensitivity seria aplicado no processamento de input

## ==================== LANGUAGE ====================
func _if_language() -> void:
	# Carrega tradução
	var lang = settings.language
	if TranslationServer.get_locale() != lang:
		TranslationServer.set_locale(lang)

## ==================== PRESETS ====================
func apply_preset(preset: String) -> void:
	match preset:
		"high_accessibility":
			settings.high_contrast = true
			settings.text_size = 1.3
			ettings.ui_scale = 1.2
			settings.reduce_motion = true
			settings.always_show_tooltips = true
			settings.simplified_fishing = true
			settings.simplified_mining = true
			settings.auto_run = true
			settings.hold_to_continue = true
			settings.visual_sound_indicators = true
			settings.show_subtitles = true
			settings.subtitle_size = 1.2

		"low_vision":
			settings.high_contrast = true
			settings.text_size = 1.5
			settings.ui_scale = 1.3
			settings.show_floating_text = true
			settings.show_damage_numbers = true

		"motor_impaired":
			settings.auto_run = true
			settings.hold_to_continue = true
			settings.simplified_fishing = true
			settings.simplified_mining = true
			settings.confirm_dangerous_actions = true

		"hearing_impaired":
			settings.visual_sound_indicators = true
			settings.show_subtitles = true
			settings.subtitle_size = 1.3
			settings.music_volume = 0.3
			settings.sfx_volume = 0.5

		"cognitive":
			settings.always_show_tooltips = true
			settings.confirm_dangerous_actions = true
			settings.simplified_fishing = true
			settings.simplified_mining = true
			settings.text_size = 1.2

		"default":
			settings = DEFAULT_SETTINGS.duplicate()

	_save_settings()
	_apply_settings()

## ==================== UI ====================
func open_accessibility_menu() -> void:
	if SettingsMenu:
		SettingsMenu.open_accessibility_tab()

## ==================== PERSISTÊNCIA ====================
func get_save_data() -> Dictionary:
	return {"settings": settings}

func load_save_data(data: Dictionary) -> void:
	settings = data.get("settings", DEFAULT_SETTINGS.duplicate())
	_apply_settings()