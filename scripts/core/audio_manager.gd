extends Node

## Gerenciador de áudio: música sazonal, ambientes, SFX

@export var music_player: AudioStreamPlayer = null
@export var ambient_player: AudioStreamPlayer = nil
@export var sfx_player: AudioStreamPlayer = nil

## Playlists por estação
const SEASONAL_MUSIC = {
	0: [  # Spring
		"res://assets/music/spring_1.ogg",
		"res://assets/music/spring_2.ogg",
		"res://assets/music/spring_3.ogg"
	],
	1: [  # Summer
		"res://assets/music/summer_1.ogg",
		"res://assets/music/summer_2.ogg",
		"res://assets/music/summer_night.ogg"
	],
	2: [  # Fall
		"res://assets/music/fall_1.ogg",
		"res://assets/music/fall_2.ogg",
		"res://assets/music/fall_rain.ogg"
	],
	3: [  # Winter
		"res://assets/music/winter_1.ogg",
		"res://assets/music/winter_2.ogg",
		"res://assets/music/winter_festival.ogg"
	]
}

## Ambientes por hora/clima
const AMBIENT_SOUNDS = {
	"day_clear": "res://assets/ambient/day_birds.ogg",
	"day_rain": "res://assets/ambient/rain_light.ogg",
	"day_storm": "res://assets/ambient/storm.ogg",
	"day_snow": "res://assets/ambient/wind_snow.ogg",
	"night_clear": "res://assets/ambient/night_crickets.ogg",
	"night_rain": "res://assets/ambient/rain_night.ogg",
	"night_storm": "res://assets/ambient/storm_night.ogg",
	"night_snow": "res://assets/ambient/wind_night.ogg",
	"mine": "res://assets/ambient/mine_ambient.ogg",
	"festival": "res://assets/ambient/festival_crowd.ogg"
}

var _current_music_index: int = -1
var _current_ambient: String = ""
var _music_timer: Timer = null
var _fade_tween: Tween = null

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Cria players se não existirem
	if not music_player:
		music_player = AudioStreamPlayer.new()
		music_player.bus = "Music"
		music_player.autoplay = false
		add_child(music_player)

	if not ambient_player:
		ambient_player = AudioStreamPlayer.new()
		ambient_player.bus = "Ambient"
		ambient_player.autoplay = false
		ambient_player.stream_paused = false
		add_child(ambient_player)

	if not sfx_player:
		sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = "SFX"
		add_child(sfx_player)

	# Conecta sinais
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)
		GameManager.season_changed.connect(_on_season_changed)
		GameManager.hour_changed.connect(_on_hour_changed)

	if TimeManager:
		TimeManager.hour_changed.connect(_check_ambient_change)

	# Timer para trocar música
	_music_timer = Timer.new()
	_music_timer.wait_time = 180.0  # 3 minutos
	_music_timer.one_shot = false
	_music_timer.timeout.connect(_play_next_seasonal_track)
	add_child(_music_timer)

	# Inicia música da estação atual
	if GameManager:
		_play_seasonal_music(GameManager.current_season)
		_update_ambient()

func _on_day_changed(day: int, season: int, year: int) -> void:
	_play_seasonal_music(season)
	_update_ambient()

func _on_season_changed(season: int, year: int) -> void:
	_play_seasonal_music(season)
	_update_ambient()

func _on_hour_changed(hour: int) -> void:
	_update_ambient()

func _check_ambient_change(hour: int) -> void:
	_update_ambient()

## ==================== MÚSICA SAZONAL ====================
func _play_seasonal_music(season: int) -> void:
	var playlist = SEASONAL_MUSIC.get(season, [])
	if playlist.is_empty():
		return

	# Para música atual com fade
	if music_player.playing:
		_fade_out(music_player, 2.0).finished.connect(_start_new_track.bind(playlist))
	else:
		_start_new_track(playlist)

func _start_new_track(playlist: Array[String]) -> void:
	var track = playlist.pick_random()
	if ResourceLoader.exists(track):
		music_player.stream = load(track)
		music_player.play()
		_fade_in(music_player, 3.0)
		_music_timer.start()
		Logger.info("Tocando música: %s" % track)
	else:
		Logger.warn("Música não encontrada: %s" % track)

func _play_next_seasonal_track() -> void:
	if GameManager:
		_play_seasonal_music(GameManager.current_season)

## ==================== AMBIENTES ====================
func _update_ambient() -> void:
	if not GameManager:
		return

	var is_day = GameManager.current_time >= 600 and GameManager.current_time < 1800
	var weather = GameManager.today_weather
	var time_prefix = "day" if is_day else "night"

	var weather_suffix = ""
	match weather:
		1: weather_suffix = "_rain"
		2: weather_suffix = "_storm"
		3: weather_suffix = "_snow"
		4: weather_suffix = "_rain"  # Green rain

	var ambient_key = "%s%s" % [time_prefix, weather_suffix]

	# Verifica se está em local especial
	if GameManager.get_data("in_mine", false):
		ambient_key = "mine"
	elif GameManager.active_festival != "":
		ambient_key = "festival"

	if ambient_key != _current_ambient:
		_play_ambient(ambient_key)
		_current_ambient = ambient_key

func _play_ambient(key: String) -> void:
	var path = AMBIENT_SOUNDS.get(key)
	if not path or not ResourceLoader.exists(path):
		return

	if ambient_player.playing:
		_fade_out(ambient_player, 1.5).finished.connect(_start_ambient.bind(path))
	else:
		_start_ambient(path)

func _start_ambient(path: String) -> void:
	ambient_player.stream = load(path)
	ambient_player.play()
	_fade_in(ambient_player, 2.0)

## ==================== FADE HELPERS ====================
func _fade_out(player: AudioStreamPlayer, duration: float) -> Tween:
	var tween = player.create_tween()
	tween.tween_property(player, "volume_db", -80.0, duration)
	tween.finished.connect(func(): player.stop())
	return tween

func _fade_in(player: AudioStreamPlayer, duration: float) -> void:
	player.volume_db = -80.0
	var tween = player.create_tween()
	tween.tween_property(player, "volume_db", 0.0, duration)

## ==================== SFX ====================
func play_sfx(sound_path: String, pitch_variance: float = 0.1) -> void:
	if not ResourceLoader.exists(sound_path):
		return

	sfx_player.stream = load(sound_path)
	sfx_player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	sfx_player.play()

func play_sfx_at_position(sound_path: String, position: Vector2, max_distance: float = 500.0) -> void:
	# Cria player 2D para som posicional
	var player = AudioStreamPlayer2D.new()
	player.stream = load(sound_path) if ResourceLoader.exists(sound_path) else null
	if player.stream:
		player.global_position = position
		player.max_distance = max_distance
		player.attenuation_model = AudioStreamPlayer2D.ATTENUATION_INVERSE_DISTANCE
		player.play()
		player.finished.connect(player.queue_free.bind())
		get_tree().root.get_child(0).add_child(player)

## ==================== MÚSICAS ESPECIAIS ====================
func play_festival_music(festival_name: String) -> void:
	var path = "res://assets/music/festival_%s.ogg" % festival_name.to_lower()
	if ResourceLoader.exists(path):
		_stop_music()
		music_player.stream = load(path)
		music_player.play()
		_fade_in(music_player, 2.0)

func resume_seasonal_music() -> void:
	if GameManager:
		_play_seasonal_music(GameManager.current_season)

func _stop_music() -> void:
	if music_player.playing:
		_fade_out(music_player, 1.0)

## ==================== VOLUME ====================
func set_music_volume(volume: float) -> void:
	if music_player:
		music_player.volume_db = linear_to_db(volume)

func set_ambient_volume(volume: float) -> void:
	if ambient_player:
		ambient_player.volume_db = linear_to_db(volume)

func set_sfx_volume(volume: float) -> void:
	if sfx_player:
		sfx_player.volume_db = linear_to_db(volume)

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"current_music_index": _current_music_index,
		"current_ambient": _current_ambient
	}

func load_save_data(data: Dictionary) -> void:
	_current_music_index = data.get("current_music_index", -1)
	_current_ambient = data.get("current_ambient", "")
	_update_ambient()