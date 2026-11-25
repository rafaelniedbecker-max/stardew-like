extends Node

## Manages HDRI skyboxes and atmospheric effects for day/night cycle
## Uses Belfast Farmhouse and Sunset PureSky EXR files

@export var day_sky_path: String = "res://resources/skyboxes/belfast_farmhouse_2k.exr"
@export var sunset_sky_path: String = "res://resources/skyboxes/belfast_sunset_puresky_2k.exr"
@export var night_sky_path: String = ""  # Optional: separate night sky

@export var enable_skybox: bool = true
@export var sky_transition_duration: float = 5.0

## Sky color overrides for different times (fallback if no HDRI)
@export var dawn_color: Color = Color(1.0, 0.6, 0.4, 1.0)
@export var day_color: Color = Color(0.5, 0.8, 1.0, 1.0)
@export var dusk_color: Color = Color(1.0, 0.5, 0.3, 1.0)
@export var night_color: Color = Color(0.1, 0.1, 0.3, 1.0)

var _world_env: WorldEnvironment
var _panorama_sky: PanoramaSky
var _current_sky: Texture2D
var _target_sky: Texture2D
var _transition_progress: float = 1.0
var _transitioning: bool = false
var _time_of_day: int = 600

func _ready() -> void:
	if not enable_skybox:
		return

	_setup_world_environment()
	_load_skies()
	call_deferred("_apply_initial_sky")

	# O relógio global é publicado pelo GameManager.
	if GameManager:
		GameManager.time_changed.connect(_on_time_changed)

func _setup_world_environment() -> void:
	# O céu 2D usa um ColorRect próprio; não crie um segundo WorldEnvironment,
	# pois DayNightCycle já controla o ambiente da cena.
	_setup_2d_sky_background()

func _setup_2d_sky_background() -> void:
	# Create a background ColorRect that covers the screen
	var bg = ColorRect.new()
	bg.name = "SkyBackground"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.offset_left = -10000
	bg.offset_top = -10000
	bg.offset_right = 10000
	bg.offset_bottom = 10000
	bg.z_index = -100  # Behind everything

	# Create shader material for sky
	var shader_mat = ShaderMaterial.new()
	shader_mat.shader = Shader.new()
	shader_mat.shader.code = _get_sky_shader_code()
	bg.material = shader_mat

	get_tree().root.get_child(0).add_child(bg)

	# Store reference
	_sky_background = bg
	_sky_shader = shader_mat

	# Load sky textures
	_day_sky = load(day_sky_path)
	_sunset_sky = load(sunset_sky_path)
	if night_sky_path != "":
		_night_sky = load(night_sky_path)

func _get_sky_shader_code() -> String:
	return """
	shader_type canvas_item;
	render_mode unshaded;

	uniform sampler2D sky_texture;
	uniform sampler2D sunset_texture;
	uniform sampler2D night_texture;

	uniform float time_of_day = 12.0;  // 0-24
	uniform float transition = 0.0;
	uniform vec3 tint = vec3(1.0);
	uniform vec3 season_tint = vec3(1.0);
	uniform int weather_type = 0;
	uniform float weather_intensity = 0.0;

	void fragment() {
		vec2 uv = UV;
		// Panorama projection - simple equirectangular
		vec2 panorama_uv = vec2(uv.x, uv.y);

		// Determine which sky to use based on time
		vec3 sky_color;

		if (time_of_day >= 5.0 && time_of_day < 7.0) {
			// Dawn - blend day and sunset
			float t = (time_of_day - 5.0) / 2.0;
			vec4 day = texture(sky_texture, panorama_uv);
			vec4 sunset = texture(sunset_texture, panorama_uv);
			sky_color = mix(day.rgb, sunset.rgb, t);
		} else if (time_of_day >= 7.0 && time_of_day < 17.0) {
			// Day
			vec4 day = texture(sky_texture, panorama_uv);
			sky_color = day.rgb;
		} else if (time_of_day >= 17.0 && time_of_day < 19.0) {
			// Dusk - blend sunset and night
			float t = (time_of_day - 17.0) / 2.0;
			vec4 sunset = texture(sunset_texture, panorama_uv);
			vec4 night = texture(night_texture, panorama_uv);
			sky_color = mix(sunset.rgb, night.rgb, t);
		} else {
			// Night
			vec4 night = texture(night_texture, panorama_uv);
			sky_color = night.rgb;
		}

		// Apply tint and weather grading.
		sky_color *= tint * season_tint;
		if (weather_type == 1) {
			sky_color = mix(sky_color, sky_color * vec3(0.8, 0.8, 0.9), weather_intensity);
		} else if (weather_type == 2) {
			sky_color = mix(sky_color, sky_color * vec3(0.5, 0.5, 0.6), weather_intensity);
		} else if (weather_type == 3) {
			sky_color = mix(sky_color, sky_color * vec3(0.9, 0.9, 1.0), weather_intensity);
		} else if (weather_type == 4) {
			sky_color = mix(sky_color, sky_color * vec3(0.8, 1.0, 0.8), weather_intensity);
		}

		// Vignette
		float vignette = 1.0 - length(uv - 0.5) * 0.5;
		sky_color *= vignette;

		COLOR = vec4(sky_color, 1.0);
	}
	"""

func _load_skies() -> void:
	_day_sky = load(day_sky_path)
	_sunset_sky = load(sunset_sky_path)
	if night_sky_path != "":
		_night_sky = load(night_sky_path)
	else:
		# Create a dark night sky from sunset
		_night_sky = _create_night_sky(_sunset_sky)

	if _day_sky:
		print("SkyManager: Day sky loaded - ", day_sky_path)
	if _sunset_sky:
		print("SkyManager: Sunset sky loaded - ", sunset_sky_path)
	if _night_sky:
		print("SkyManager: Night sky ready")

func _create_night_sky(source: Texture2D) -> Texture2D:
	# Create a dark version for night
	# In practice, you'd want a proper night HDRI
	# For now, return the sunset texture (will be tinted dark by shader)
	return source

func _apply_initial_sky() -> void:
	if _sky_shader and _day_sky:
		_sky_shader.set_shader_parameter("sky_texture", _day_sky)
		_sky_shader.set_shader_parameter("sunset_texture", _sunset_sky)
		_sky_shader.set_shader_parameter("night_texture", _night_sky)
		_sky_shader.set_shader_parameter("time_of_day", 12.0)

func _on_time_changed(time: int) -> void:
	_time_of_day = time
	var hour = time / 100.0

	if _sky_shader:
		_sky_shader.set_shader_parameter("time_of_day", hour)

		# Update tint based on time
		var tint = _calculate_sky_tint(hour)
		_sky_shader.set_shader_parameter("tint", tint)

func _calculate_sky_tint(hour: float) -> Color:
	# Calculate color tint for sky based on time
	if hour >= 5.0 && hour < 7.0:
		# Dawn - warm orange/pink
		var t = (hour - 5.0) / 2.0
		return Color(1.0, 0.6, 0.4).lerp(Color(0.5, 0.8, 1.0), t)
	elif hour >= 7.0 && hour < 12.0:
		# Morning - bright blue
		return Color(0.5, 0.8, 1.0)
	elif hour >= 12.0 && hour < 14.0:
		# Noon - slightly warmer
		return Color(0.6, 0.85, 1.0)
	elif hour >= 14.0 && hour < 17.0:
		# Afternoon - golden
		var t = (hour - 14.0) / 3.0
		return Color(0.6, 0.85, 1.0).lerp(Color(1.0, 0.7, 0.4), t)
	elif hour >= 17.0 && hour < 19.0:
		# Dusk - orange/red
		var t = (hour - 17.0) / 2.0
		return Color(1.0, 0.7, 0.4).lerp(Color(0.8, 0.3, 0.2), t)
	elif hour >= 19.0 && hour < 22.0:
		# Evening - dark blue/purple
		var t = (hour - 19.0) / 3.0
		return Color(0.8, 0.3, 0.2).lerp(Color(0.15, 0.1, 0.3), t)
	elif hour >= 22.0 || hour < 5.0:
		# Night - very dark
		if hour >= 22.0:
			var t = (hour - 22.0) / 2.0
			return Color(0.15, 0.1, 0.3).lerp(Color(0.05, 0.05, 0.15), min(t, 1.0))
		else:
			var t = (hour + 2.0) / 5.0  # 22-24 + 0-5
			return Color(0.05, 0.05, 0.15).lerp(Color(0.1, 0.1, 0.25), t)

	return Color(1.0, 1.0, 1.0)

## ==================== WEATHER EFFECTS ====================

func apply_weather_overlay(weather: int, intensity: float) -> void:
	"""Apply weather effects to sky."""
	if not _sky_shader:
		return

	match weather:
		1: # Rain
			_sky_shader.set_shader_parameter("weather_type", 1)
			_sky_shader.set_shader_parameter("weather_intensity", intensity)
			_sky_shader.set_shader_parameter("tint", _sky_shader.get_shader_parameter("tint") * Color(0.8, 0.8, 0.9))
		2: # Storm
			_sky_shader.set_shader_parameter("weather_type", 2)
			_sky_shader.set_shader_parameter("weather_intensity", intensity)
			_sky_shader.set_shader_parameter("tint", _sky_shader.get_shader_parameter("tint") * Color(0.5, 0.5, 0.6))
		3: # Snow
			_sky_shader.set_shader_parameter("weather_type", 3)
			_sky_shader.set_shader_parameter("weather_intensity", intensity)
			_sky_shader.set_shader_parameter("tint", _sky_shader.get_shader_parameter("tint") * Color(0.9, 0.9, 1.0))
		4: # Green rain
			_sky_shader.set_shader_parameter("weather_type", 4)
			_sky_shader.set_shader_parameter("weather_intensity", intensity)
			_sky_shader.set_shader_parameter("tint", _sky_shader.get_shader_parameter("tint") * Color(0.8, 1.0, 0.8))
		_: # Clear
			_sky_shader.set_shader_parameter("weather_type", 0)
			_sky_shader.set_shader_parameter("weather_intensity", 0.0)

## ==================== SEASONAL EFFECTS ====================

func apply_season_tint(season: int) -> void:
	"""Apply seasonal color grading to sky."""
	if not _sky_shader:
		return

	match season:
		0: # Spring - fresh, slightly green tint
			_sky_shader.set_shader_parameter("season_tint", Color(0.95, 1.0, 0.95))
		1: # Summer - warm, golden
			_sky_shader.set_shader_parameter("season_tint", Color(1.0, 0.98, 0.9))
		2: # Autumn - orange/red tint
			_sky_shader.set_shader_parameter("season_tint", Color(1.0, 0.95, 0.85))
		3: # Winter - cold blue tint
			_sky_shader.set_shader_parameter("season_tint", Color(0.95, 0.95, 1.0))

## ==================== UTILITÁRIOS ====================

var _sky_background: ColorRect
var _sky_shader: ShaderMaterial
var _day_sky: Texture2D
var _sunset_sky: Texture2D
var _night_sky: Texture2D