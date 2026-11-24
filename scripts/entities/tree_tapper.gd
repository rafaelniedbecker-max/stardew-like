class_name TreeTapper
extends Node2D

## Tree Tapper - extrai resina, seiva, xarope de árvores

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var output_slot: TextureRect = $OutputSlot

## Estado
var tree_type: String = ""  # "Oak", "Maple", "Pine", "Mahogany", "Mushroom"
var is_ready: bool = false
var product_item: String = ""
var product_amount: int = 1
var days_to_ready: int = 0
var current_day: int = 0

## Tempos de produção (dias)
const PRODUCTION_TIME = {
	"Oak": 7,       # Resina
	"Maple": 9,     # Xarope de Bordo
	"Pine": 5,      # Seiva de Pinheiro
	"Mahogany": 7,  # Seiva de Mogno
	"Mushroom": 2,  # Cogumelo (Mushroom Tree)
}

## Produtos por tipo
const PRODUCTS = {
	"Oak": "(O)766",       # Resina
	"Maple": "(O)767",     # Xarope de Bordo
	"Pine": "(O)768",      # Seiva de Pinheiro
	"Mahogany": "(O)769",  # Seiva de Mogno
	"Mushroom": "(O)281",  # Cogumelo Comum (pode variar)
}

## Mushroom Tree variants
const MUSHROOM_VARIANTS = [
	"(O)281",  # Common Mushroom
	"(O)283",  # Morel
	"(O)285",  # Chanterelle
	"(O)287",  # Porcini
	"(O)289",  # Lobster Mushroom
]

## ==================== SINAIS ====================
signal product_ready(item_id: String, amount: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	progress_bar.visible = false
	output_slot.visible = false

	_load_state()

	# Conecta ao ciclo diário
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if is_ready:
			HUD.show_interaction_prompt("E: Coletar %s" % DataLoader.get_item(product_item)?.display_name, global_position + Vector2(0, -50))
		else:
			HUD.show_interaction_prompt("Tapper: %d dias" % (days_to_ready - current_day), global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	if is_ready:
		_collect()
	else:
		_show_info()

func _show_info() -> void:
	var tree_names = {"Oak": "Carvalho", "Maple": "Bordo", "Pine": "Pinheiro", "Mahogany": "Mogno", "Mushroom": "Cogumelo"}
	var name = tree_names.get(tree_type, tree_type)
	var remaining = days_to_ready - current_day
	HUD.show_message("%s Tapper: %d dias restantes" % [name, remaining])

func _collect() -> void:
	if not is_ready:
		return

	if InventoryManager.add_item(product_item, product_amount):
		is_ready = false
		current_day = 0
		product_item = ""
		product_amount = 1
		days_to_ready = 0

		_save_state()

		if ParticleManager:
			ParticleManager.spawn("harvest", global_position + Vector2(16, -16))

		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/tapper_collect.ogg", global_position)

		var item = DataLoader.get_item(product_item)
		HUD.show_notification("🌲 Coletado!", "%s x%d" % [item?.display_name ?? product_item, product_amount], Color(0.5, 1.0, 0.5))

		emit_signal("product_ready", product_item, product_amount)

		_update_visuals()

func _on_day_changed(day: int, season: int, year: int) -> void:
	if tree_type == "":
		return

	if is_ready:
		return

	current_day += 1
	days_to_ready = PRODUCTION_TIME.get(tree_type, 7)

	if current_day >= days_to_ready:
		_finish_production()

	_update_visuals()
	_save_state()

func _finish_production() -> void:
	is_ready = true
	product_item = PRODUCTS.get(tree_type, "(O)766")
	product_amount = 1

	# Mushroom tree tem chance de cogumelos raros
	if tree_type == "Mushroom" and randf() < 0.2:
		product_item = MUSHROOM_VARIANTS.pick_random()
		product_amount = 1

	progress_bar.value = 100
	progress_bar.visible = true

	# Mostra bolha de pronto
	output_slot.visible = true
	if output_slot:
		var item = DataLoader.get_item(product_item)
		if item and item.texture_path != "":
			output_slot.texture = load(item.texture_path)

func initialize(tree_type_param: String) -> void:
	tree_type = tree_type_param
	days_to_ready = PRODUCTION_TIME.get(tree_type, 7)
	current_day = 0
	is_ready = false
	product_item = ""
	product_amount = 1

	_setup_visuals()

func _setup_visuals() -> void:
	# Configura sprite baseado no tipo
	if sprite and sprite.sprite_frames:
		var anim_map = {
			"Oak": "oak_tapper",
			"Maple": "maple_tapper",
			"Pine": "pine_tapper",
			"Mahogany": "mahogany_tapper",
			"Mushroom": "mushroom_tapper"
		}
		var anim = anim_map.get(tree_type, "oak_tapper")
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)

func _update_visuals() -> void:
	if not is_ready:
		progress_bar.value = (current_day / days_to_ready) * 100
		progress_bar.visible = true
		output_slot.visible = false
	else:
		progress_bar.value = 100
		progress_bar.visible = true
		output_slot.visible = true
		if output_slot:
			var item = DataLoader.get_item(product_item)
			if item and item.texture_path != "":
				output_slot.texture = load(item.texture_path)

func _save_state() -> void:
	if GameManager:
		GameManager.set("tree_tapper_%s" % [name], {
			"tree_type": tree_type,
			"is_ready": is_ready,
			"product_item": product_item,
			"product_amount": product_amount,
			"current_day": current_day,
			"days_to_ready": days_to_ready
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get("tree_tapper_%s" % [name], {})
		if data:
			tree_type = data.get("tree_type", "")
			is_ready = data.get("is_ready", false)
			product_item = data.get("product_item", "")
			product_amount = data.get("product_amount", 1)
			current_day = data.get("current_day", 0)
			days_to_ready = data.get("days_to_ready", 0)

			if tree_type != "":
				_setup_visuals()
				_update_visuals()