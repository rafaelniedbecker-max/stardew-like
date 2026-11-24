class_name MushroomLog
extends Node2D

## Mushroom Log - produz cogumelos a cada poucos dias

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var output_slot: TextureRect = $OutputSlot

## Estado
var is_ready: bool = false
var mushrooms: Array[String] = []
var current_day: int = 0
var harvest_day: int = 0

## Configuração
const HARVEST_INTERVAL = 2  # Dias entre colheitas
const MAX_MUSHROOMS = 6     # Máximo acumulado

## Cogumelos possíveis (por raridade)
const MUSHROOM_POOL = {
	"common": ["(O)281", "(O)283", "(O)285"],  # Common, Morel, Chanterelle
	"uncommon": ["(O)287", "(O)289"],          # Porcini, Lobster
	"rare": ["(O)291", "(O)293"]               # Truffle, etc. (se existirem)
}

const MUSHROOM_WEIGHTS = {
	"common": 70,
	"uncommon": 25,
	"rare": 5
}

## ==================== SINAIS ====================
signal mushrooms_harvested(items: Array)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	progress_bar.visible = false
	output_slot.visible = false

	_load_state()

	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if is_ready:
			var count = mushrooms.size()
			HUD.show_interaction_prompt("E: Coletar %d cogumelo(s)" % count, global_position + Vector2(0, -50))
		else:
			HUD.show_interaction_prompt("Mushroom Log: %d dias" % (HARVEST_INTERVAL - current_day), global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	if is_ready:
		_collect()
	else:
		_show_info()

func _show_info() -> void:
	HUD.show_message("Mushroom Log: %d dias para próxima colheita" % (HARVEST_INTERVAL - current_day))

func _collect() -> void:
	if not is_ready or mushrooms.is_empty():
		return

	var collected = []
	for mushroom_id in mushrooms:
		if InventoryManager.add_item(mushroom_id, 1):
			collected.append(mushroom_id)
		else:
			break  # Inventário cheio

	if collected.is_empty():
		HUD.show_message("Inventário cheio!")
		return

	mushrooms = mushrooms.slice(collected.size())

	if mushrooms.is_empty():
		is_ready = false
		progress_bar.value = 0
		output_slot.visible = false
	else:
		progress_bar.value = 100
		_update_output_slot()

	_save_state()

	if ParticleManager:
		ParticleManager.spawn("harvest", global_position + Vector2(16, -16))

	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/mushroom_collect.ogg", global_position)

	# Notificação com detalhes
	var names = []
	for id in collected:
		var item = DataLoader.get_item(id)
		names.append(item?.display_name ?? id)
	HUD.show_notification("🍄 Colhido!", "%s" % names.join(", "), Color(0.8, 0.5, 1.0))

	emit_signal("mushrooms_harvested", collected)

func _on_day_changed(day: int, season: int, year: int) -> void:
	if is_ready:
		return

	current_day += 1

	if current_day >= HARVEST_INTERVAL:
		_produce_mushrooms()

	_update_visuals()
	_save_state()

func _produce_mushrooms() -> void:
	# Reseta contador
	current_day = 0

	# Adiciona 1-2 cogumelos (máximo MAX_MUSHROOMS)
	var to_add = randi_range(1, 2)
	var space = MAX_MUSHROOMS - mushrooms.size()
	to_add = min(to_add, space)

	for i in range(to_add):
		var mushroom = _roll_mushroom()
		mushrooms.append(mushroom)

	if mushrooms.size() > 0:
		is_ready = true
		progress_bar.value = 100
		_update_output_slot()
	else:
		progress_bar.value = 0

func _roll_mushroom() -> String:
	var rand = randf() * 100
	var accum = 0

	for rarity in ["common", "uncommon", "rare"]:
		accum += MUSHROOM_WEIGHTS[rarity]
		if rand <= accum:
			return MUSHROOM_POOL[rarity].pick_random()

	return MUSHROOM_POOL["common"].pick_random()

func _update_output_slot() -> void:
	if mushrooms.is_empty():
		output_slot.visible = false
		return

	output_slot.visible = true
	# Mostra o último cogumelo adicionado
	var last = mushrooms[-1]
	var item = DataLoader.get_item(last)
	if item and item.texture_path != "":
		output_slot.texture = load(item.texture_path)

func _update_visuals() -> void:
	if is_ready:
		progress_bar.value = 100
		progress_bar.visible = true
		_update_output_slot()
	else:
		progress_bar.value = (current_day / HARVEST_INTERVAL) * 100
		progress_bar.visible = true
		output_slot.visible = false

func _save_state() -> void:
	if GameManager:
		GameManager.set("mushroom_log_%s" % [name], {
			"is_ready": is_ready,
			"mushrooms": mushrooms,
			"current_day": current_day
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get("mushroom_log_%s" % [name], {})
		if data:
			is_ready = data.get("is_ready", false)
			mushrooms = data.get("mushrooms", [])
			current_day = data.get("current_day", 0)

			_update_visuals()