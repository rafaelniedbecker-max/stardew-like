class_name DesertManager
extends Node

## Deserto e Caverna da Caveira (Skull Cavern)

@export var desert_scene: PackedScene
@export var skull_cavern_scene: PackedScene

## Estado
var desert_unlocked: bool = false
var skull_cavern_unlocked: bool = false
var bus_repaired: bool = false
var current_skull_level: int = 0
var deepest_skull_level: int = 0

## ==================== SINAIS ====================
signal desert_unlocked()
signal skull_cavern_unlocked()
signal bus_repaired()
signal entered_skull_cavern(level: int)
signal exited_skull_cavern()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Verifica progresso do Community Center (Vault)
	if CommunityCenter:
		CommunityCenter.room_completed.connect(_check_vault_completion)

	# Carrega progresso salvo
	_load_progress()

func _check_vault_completion(room: String) -> void:
	if room == "Vault" and not bus_repaired:
		var bundles = CommunityCenter.get_room_bundles("Vault")
		var all_complete = true
		for bundle in bundles:
			if not bundle.completed:
				all_complete = false
				break
		if all_complete:
			_repair_bus()

func _repair_bus() -> void:
	bus_repaired = true
	desert_unlocked = true
	GameManager.set("bus_repaired", true)
	GameManager.set("desert_unlocked", true)

	emit_signal("bus_repaired")
	emit_signal("desert_unlocked")

	HUD.show_notification("🚌 Ônibus Reparado!", "Agora você pode ir ao Deserto!", Color(1.0, 0.8, 0.2))

	if ParticleManager:
		ParticleManager.show_level_up(Vector2(320, 400), "Deserto Desbloqueado!")

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/bus_repair.ogg")

func enter_desert() -> void:
	if not bus_repaired:
		HUD.show_message("O ônibus ainda não foi reparado!")
		return

	# Teleporta para o deserto
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector2(2400, 2400)  # Posição do deserto
		_get_tree().paused = false

	HUD.show_message("Bem-vindo ao Deserto! Cuidado com os monstros.")

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/bus_ride.ogg")

func unlock_skull_cavern() -> void:
	if skull_cavern_unlocked:
		return

	# Requer: Caverna da Caveira key (doada ao museu) OU atingir nível 120 na mina
	var has_key = GameManager.get("has_skull_key", false)
	var mine_level = GameManager.get("deepest_mine_level", 0)

	if has_key or mine_level >= 120:
		skull_cavern_unlocked = true
		GameManager.set("skull_cavern_unlocked", true)

		emit_signal("skull_cavern_unlocked")
		HUD.show_notification("💀 Caverna da Caveira!", "A entrada foi desbloqueada!", Color(1.0, 0.3, 0.3))

		if ParticleManager:
			ParticleManager.show_level_up(Vector2(2400, 2400), "Caverna da Caveira!")

		if AudioManager:
			AudioManager.play_sfx("res://assets/sfx/skull_cavern_unlock.ogg")
	else:
		HUD.show_message("Você precisa da Chave da Caveira (do museu) ou atingir nível 120 na mina!")

func enter_skull_cavern(level: int = -1) -> void:
	if not skull_cavern_unlocked:
		unlock_skull_cavern()
		return

	if level == -1:
		level = max(1, deepest_skull_level - 10)

	current_skull_level = level
	emit_signal("entered_skull_cavern", level)

	# Gera nível da Caverna da Caveira
	_generate_skull_level(level)

	HUD.show_message("Entrando na Caverna da Caveira - Nível %d" % level)

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/skull_cavern_enter.ogg")

func exit_skull_cavern() -> void:
	emit_signal("exited_skull_cavern")
	HUD.show_message("Você saiu da Caverna da Caveira.")

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/skull_cavern_exit.ogg")

func _generate_skull_level(level: int) -> void:
	# Gera nível procedural da Caverna da Caveira
	# Mais difícil que mina normal, mais irídio, monstros mais fortes

	var theme = _get_skull_theme(level)

	# Spawna escadas, minérios, monstros
	# Lógica similar ao MineManager mas com parâmetros diferentes

	HUD.show_message("Nível %d da Caverna da Caveira gerado." % level)

func _get_skull_theme(level: int) -> String:
	# Temas alternam a cada 10 níveis
	var themes = ["Dirt", "Ice", "Lava", "Dark", "Crystal"]
	return themes[(level / 10) % themes.size()]

## ==================== RECOMPENSAS ESPECIAIS ====================
func get_skull_rewards(level: int) -> Array[Dictionary]:
	var rewards = []

	# Chance de irídio aumenta com nível
	var iridium_chance = 0.02 + (level * 0.001)

	# Baús especiais a cada 10 níveis
	if level % 10 == 0:
		rewards.append({"type": "chest", "tier": "golden", "level": level})

	# Prismatic Shard chance
	if randf() < 0.005 + (level * 0.0001):
		rewards.append({"type": "item", "id": "(O)749", "count": 1})  # Prismatic Shard

	# Dino Egg raro
	if randf() < 0.001:
		rewards.append({"type": "item", "id": "(O)107", "count": 1})  # Dino Egg

	return rewards

## ==================== PERSISTÊNCIA ====================
func _load_progress() -> void:
	if GameManager:
		bus_repaired = GameManager.get("bus_repaired", false)
		desert_unlocked = GameManager.get("desert_unlocked", false)
		skull_cavern_unlocked = GameManager.get("skull_cavern_unlocked", false)
		deepest_skull_level = GameManager.get("deepest_skull_level", 0)

func get_save_data() -> Dictionary:
	return {
		"bus_repaired": bus_repaired,
		"desert_unlocked": desert_unlocked,
		"skull_cavern_unlocked": skull_cavern_unlocked,
		"deepest_skull_level": deepest_skull_level
	}

func load_save_data(data: Dictionary) -> void:
	bus_repaired = data.get("bus_repaired", false)
	desert_unlocked = data.get("desert_unlocked", false)
	skull_cavern_unlocked = data.get("skull_cavern_unlocked", false)
	deepest_skull_level = data.get("deepest_skull_level", 0)