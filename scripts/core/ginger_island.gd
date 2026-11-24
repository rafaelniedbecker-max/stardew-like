class_name GingerIsland
extends Node

## Ginger Island (Ilha Ginger) - conteúdo pós-jogo

@export var island_scene: PackedScene

## Estado
var island_unlocked: bool = false
var walnut_room_unlocked: bool = false
var walnuts_collected: int = 0
var total_walnuts: int = 130
var farm_unlocked: bool = false
var farm_obelisks: Dictionary = {}

## Locais da ilha
const ISLAND_LOCATIONS = {
	"Dock": {"name": "Doca", "walnuts": 5},
	"Farm": {"name": "Fazenda da Ilha", "walnuts": 15},
	"Volcano": {"name": "Vulcão", "walnuts": 25},
	"Jungle": {"name": "Selva", "walnuts": 20},
	"DigSite": {"name": "Sítio de Escavação", "walnuts": 15},
	"PirateCove": {"name": "Cove dos Piratas", "walnuts": 10},
	"GourmandFrog": {"name": "Sapo Gourmet", "walnuts": 10},
	"Leo": {"name": "Leo", "walnuts": 5},
	"FieldOffice": {"name": "Escritório de Campo", "walnuts": 5},
	"Birdie": {"name": "Birdie", "walnuts": 5},
	"Mermaid": {"name": "Sereia", "walnuts": 5},
	"QiWalnutRoom": {"name": "Sala de Nozes do Qi", "walnuts": 0}
}

## ==================== SINAIS ====================
signal island_unlocked()
signal walnut_collected(location: String, amount: int)
signal walnut_room_unlocked()
signal volcano_entered(level: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_progress()

	# Verifica desbloqueio (precisa reparar barco no Willy's Boat Shop)
	if GameManager:
		GameManager.day_changed.connect(_check_boat_repair)

func _check_boat_repair() -> void:
	if not island_unlocked and GameManager.get("boat_repaired", false):
		_unlock_island()

func _unlock_island() -> void:
	island_unlocked = true
	GameManager.set("island_unlocked", true)
	emit_signal("island_unlocked")

	HUD.show_notification("🏝️ Ilha Ginger!", "O barco foi reparado! Você pode visitar a Ilha Ginger!", Color(0.3, 0.8, 0.5))

	if ParticleManager:
		ParticleManager.show_level_up(Vector2(320, 320), "Ilha Ginger!")

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/island_unlock.ogg")

func travel_to_island() -> void:
	if not island_unlocked:
		HUD.show_message("O barco para a Ilha Ginger ainda não está pronto!")
		return

	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.global_position = Vector2(4800, 4800)  # Posição da ilha
		_get_tree().paused = false

	HUD.show_message("Bem-vindo à Ilha Ginger! Explore e colete Nozes Douradas!")

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/boat_travel.ogg")

func collect_walnut(location: String, amount: int = 1) -> void:
	if not island_unlocked:
		return

	var loc_data = ISLAND_LOCATIONS.get(location, {})
	var max_walnuts = loc_data.get("walnuts", 0)

	# Verifica se já coletou todas deste local
	var collected_key = "walnut_%s" % location
	var already = GameManager.get(collected_key, 0)
	if already >= max_walnuts:
		return

	var to_collect = min(amount, max_walnuts - already)
	walnuts_collected += to_collect
	GameManager.set(collected_key, already + to_collect)

	GameManager.set("walnuts_collected", walnuts_collected)

	emit_signal("walnut_collected", location, to_collect)

	HUD.show_notification("🥜 Noz Dourada!", "%d encontrada em %s! Total: %d/%d" % [to_collect, loc_data.get("name", location), walnuts_collected, total_walnuts], Color(1.0, 0.85, 0.2))

	if walnuts_collected >= 100 and not walnut_room_unlocked:
		_unlock_walnut_room()

	if ParticleManager:
		ParticleManager.spawn("harvest", get_tree().get_first_node_in_group("player").global_position)

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/walnut_collect.ogg", get_tree().get_first_node_in_group("player").global_position)

func _unlock_walnut_room() -> void:
	walnut_room_unlocked = true
	GameManager.set("walnut_room_unlocked", true)
	emit_signal("walnut_room_unlocked")

	HUD.show_notification("🥜 Sala das Nozes do Qi!", "Você coletou 100 nozes! A sala secreta está aberta!", Color(1.0, 0.8, 0.2))

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/walnut_room.ogg")

func enter_volcano(level: int = 1) -> void:
	if not island_unlocked:
		HUD.show_message("A ilha ainda não está acessível!")
		return

	emit_signal("volcano_entered", level)
	HUD.show_message("Entrando no Vulcão - Nível %d" % level)

	# Gera nível do vulcão
	_generate_volcano_level(level)

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/volcano_enter.ogg")

func _generate_volcano_level(level: int) -> void:
	# Gera nível do vulcão (similar a mina mas com tema vulcânico)
	# Monstros: Lava Slime, Magma Sprite, Fire Bat, etc.
	# Minérios: Irídio, Ouro, Radioactive Ore

	HUD.show_message("Nível %d do Vulcão gerado." % level)

## ==================== RECOMPENSAS ====================
func get_volcano_rewards(level: int) -> Array[Dictionary]:
	var rewards = []

	# Chance de Cinder Shards (moeda da ilha)
	var shard_count = randi_range(5, 15) + level
	rewards.append({"type": "currency", "id": "(O)892", "count": shard_count})  # Cinder Shard

	# Chance de Gemas
	if randf() < 0.1:
		var gems = ["(O)60", "(O)62", "(O)64", "(O)66"]  # Emerald, Aquamarine, Ruby, Amethyst
		rewards.append({"type": "item", "id": gems.pick_random(), "count": randi_range(1, 3)})

	# Chance de Radioactive Ore
	if randf() < 0.05:
		rewards.append({"type": "item", "id": "(O)765", "count": randi_range(1, 3)})  # Radioactive Ore

	# Chance de Ginger Island itens exclusivos
	if randf() < 0.02:
		var exclusive = ["(O)912", "(O)913", "(O)914"]  # Banana, Mango, Pineapple saplings
		rewards.append({"type": "item", "id": exclusive.pick_random(), "count": 1})

	return rewards

## ==================== QI'S WALNUT ROOM ====================
func enter_qi_walnut_room() -> void:
	if not walnut_room_unlocked:
		HUD.show_message("Você precisa de 100 Nozes Douradas!")
		return

	# Abre loja especial do Qi
	if SpecialOrdersBoard:
		SpecialOrdersBoard.open_board("qi")

	HUD.show_message("Bem-vindo à Sala de Nozes do Qi!")

## ==================== FAZENDA DA ILHA ====================
func unlock_island_farm() -> void:
	if farm_unlocked:
		return

	# Requer: 10 nozes + completar quest do papagaio
	if walnuts_collected >= 10:
		farm_unlocked = true
		GameManager.set("island_farm_unlocked", true)
		HUD.show_notification("🏝️ Fazenda da Ilha!", "A fazenda da ilha está disponível!", Color(0.5, 1.0, 0.5))
	else:
		HUD.show_message("Precisa de 10 Nozes Douradas para desbloquear a fazenda!")

func add_farm_obelisk(obelisk_type: String) -> void:
	# Obeliscos de teleporte na fazenda da ilha
	var costs = {
		"Water": {"walnuts": 20, "cinder_shards": 100},
		"Earth": {"walnuts": 20, "cinder_shards": 100},
		"Island": {"walnuts": 40, "cinder_shards": 200}
	}

	var cost = costs.get(obelisk_type, {})
	if not cost:
		return

	if walnuts_collected < cost.walnuts:
		HUD.show_message("Nozes Douradas insuficientes! Precisa de %d" % cost.walnuts)
		return

	if GameManager.get("cinder_shards", 0) < cost.cinder_shards:
		HUD.show_message("Cinder Shards insuficientes! Precisa de %d" % cost.cinder_shards)
		return

	walnuts_collected -= cost.walnuts
	GameManager.set("cinder_shards", GameManager.get("cinder_shards", 0) - cost.cinder_shards)
	GameManager.set("walnuts_collected", walnuts_collected)

	farm_obelisks[obelisk_type] = true
	GameManager.set("farm_obelisks", farm_obelisks)

	HUD.show_notification("🗿 Obelisco Construído!", "Obelisco %s construído na fazenda da ilha!" % obelisk_type, Color(0.5, 1.0, 0.8))

## ==================== PERSISTÊNCIA ====================
func get_save_data() -> Dictionary:
	return {
		"island_unlocked": island_unlocked,
		"walnut_room_unlocked": walnut_room_unlocked,
		"walnuts_collected": walnuts_collected,
		"farm_unlocked": farm_unlocked,
		"farm_obelisks": farm_obelisks
	}

func load_save_data(data: Dictionary) -> void:
	island_unlocked = data.get("island_unlocked", false)
	walnut_room_unlocked = data.get("walnut_room_unlocked", false)
	walnuts_collected = data.get("walnuts_collected", 0)
	farm_unlocked = data.get("farm_unlocked", false)
	farm_obelisks = data.get("farm_obelisks", {})