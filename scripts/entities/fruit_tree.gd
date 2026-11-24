class_name FruitTree
extends Node2D

## Árvore frutífera com estações, qualidade, crescimento por anos

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var fruit_area: Area2D = $FruitArea
@onready var interaction_area: Area2D = $InteractionArea
@onready var name_label: Label = $NameLabel

## Dados da árvore
var tree_data: Dictionary
var tree_type: String = ""  # "Apple", "Apricot", "Orange", etc.
var tree_id: String = ""

## Estado
var age_days: int = 0
var growth_stage: int = 0  # 0=semente, 1=pequena, 2=media, 3=grande, 4=adulta
var season_planted: int = -1
var last_fruit_day: int = -1
var fruit_ready: bool = false
var fruit_quality: int = 0
var fruit_amount: int = 1
var is_stumped: bool = false
var has_fertilizer: bool = false
var fertilizer_type: String = ""  # "Tree Fertilizer", "Deluxe Tree Fertilizer"

## Produção
const GROWTH_STAGES = 5  # 0-4
const DAYS_PER_STAGE = [0, 7, 7, 7, 7]  # Dias para cada estágio (total 28 dias = 1 ano)
const FRUIT_SEASONS = {
	"Apple": [2],      # Fall
	"Apricot": [1],    # Summer
	"Orange": [1],     # Summer
	"Peach": [1],      # Summer
	"Pomegranate": [2], # Fall
	"Cherry": [0],     # Spring
	"Banana": [1, 2],  # Summer, Fall (Ilha Ginger)
	"Mango": [1],      # Summer (Ilha)
	"Coconut": [1, 2], # Summer, Fall (Ilha)
}

## ==================== SINAIS ====================
signal fruit_ready(tree: FruitTree)
signal tree_grew(tree: FruitTree, new_stage: int)
signal tree_harvested(tree: FruitTree, item_id: String, amount: int, quality: int)
signal tree_destroyed(tree: FruitTree)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	add_to_group("fruit_tree")
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)
	name_label.visible = false

	fruit_area.monitoring = true
	fruit_area.monitorable = true
	fruit_area.area_entered.connect(_on_fruit_collected)

func initialize(tree_type: String, tree_id: String, season_planted: int, has_fertilizer: bool = false, fertilizer_type: String = "") -> void:
	self.tree_type = tree_type
	self.tree_id = tree_id
	self.season_planted = season_planted
	self.has_fertilizer = has_fertilizer
	self.fertilizer_type = fertilizer_type

	# Carrega dados
	tree_data = DataLoader.get_fruit_tree(tree_type)
	if not tree_data:
		tree_data = DataLoader.get_fruit_tree("Apple")  # Fallback

	# Nome
	name_label.text = tree_data.get("DisplayName", tree_type)

	# Configura visual
	_setup_visuals()

	# Idade inicial (se carregando save)
	if age_days > 0:
		_update_growth_stage()

func _setup_visuals() -> void:
	var tex_path = tree_data.get("Texture2D", "")
	if tex_path:
		var tex = load("res://resources/sprites/%s.png" % tex_path)
		if tex:
			animated_sprite.texture = tex
			_setup_animations()

	# Escala por estágio
	_apply_stage_scale()

func _setup_animations() -> void:
	var frames = animated_sprite.sprite_frames
	if not frames:
		frames = SpriteFrames.new()
		animated_sprite.sprite_frames = frames

	var sw = tree_data.get("SpriteWidth", 32)
	var sh = tree_data.get("SpriteHeight", 32)

	# Animações por estágio e estação
	for stage in range(GROWTH_STAGES):
		for season in ["spring", "summer", "fall", "winter"]:
			var anim_name = "stage_%d_%s" % [stage, season]
			frames.add_animation(anim_name)
			frames.set_animation_loop(anim_name, true)

	# Animação com fruto
	for season in ["spring", "summer", "fall", "winter"]:
		var anim_name = "fruit_%s" % season
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)

	# Toco
	frames.add_animation("stump")
	frames.set_animation_loop("stump", true)

func _apply_stage_scale() -> void:
	var scales = [0.3, 0.5, 0.7, 0.9, 1.0]
	if growth_stage < scales.size():
		scale = Vector2(scales[growth_stage], scales[growth_stage])

## ==================== CICLO DIÁRIO ====================
func new_day() -> void:
	if is_stumped:
		return

	age_days += 1
	var old_stage = growth_stage
	_update_growth_stage()

	if growth_stage != old_stage:
		_apply_stage_scale()
		_play_growth_animation()
		emit_signal("tree_grew", self, growth_stage)

	# Verifica produção de fruto
	if growth_stage >= 4:  # Adulta
		_check_fruit_production()

func _update_growth_stage() -> void:
	# Calcula estágio baseado na idade
	# Ano 1: stages 0-3, Ano 2+: stage 4 (adulta)
	var year = age_days / 28
	var day_in_year = age_days % 28

	if year == 0:
		# Primeiro ano
		if day_in_year < 7:
			growth_stage = 0
		elif day_in_year < 14:
			growth_stage = 1
		elif day_in_year < 21:
			growth_stage = 2
		else:
			growth_stage = 3
	else:
		growth_stage = 4  # Adulta

func _check_fruit_production() -> void:
	if fruit_ready:
		return  # Já tem fruto esperando

	var current_season = GameManager.current_season if GameManager else 0
	var fruit_seasons = FRUIT_SEASONS.get(tree_type, [2])

	if current_season in fruit_seasons:
		# Verifica se é dia de produção (a cada 1 dia na estação)
		var days_in_season = GameManager.current_day % 28
		if last_fruit_day != GameManager.current_day:
			# Produz fruto
			_produce_fruit()

func _produce_fruit() -> void:
	last_fruit_day = GameManager.current_day

	# Determina qualidade
	fruit_quality = _calculate_fruit_quality()

	# Quantidade (chance de fruto extra com fertilizante deluxe)
	fruit_amount = 1
	if fertilizer_type == "Deluxe Tree Fertilizer" and randf() < 0.2:
		fruit_amount = 2

	fruit_ready = true

	# Atualiza visual para mostrar fruto
	_update_fruit_visual()

	emit_signal("fruit_ready", self)

func _calculate_fruit_quality() -> int:
	var chance = 0.0

	# Base: idade da árvore (mais velha = melhor)
	var years = age_days / 28
	chance += min(years * 0.05, 0.3)

	# Fertilizante
	if fertilizer_type == "Tree Fertilizer":
		chance += 0.2
	elif fertilizer_type == "Deluxe Tree Fertilizer":
		chance += 0.4

	# Sorte diária
	chance += (GameManager.daily_luck + 0.1) * 0.2

	# Profissão Tapper (não afeta árvores frutíferas diretamente)
	# Profissão Botanist (level 10 foraging) - qualidade irídio garantida
	if GameManager and GameManager.professions.get("Foraging") == 1:
		return 3

	if chance > 0.9:
		return 3
	elif chance > 0.6:
		return 2
	elif chance > 0.3:
		return 1
	return 0

func _update_fruit_visual() -> void:
	var season_names = ["spring", "summer", "fall", "winter"]
	var season = season_names[GameManager.current_season] if GameManager else "spring"
	var anim = "fruit_%s" % season
	if animated_sprite.sprite_frames.has_animation(anim):
		animated_sprite.play(anim)

func _play_growth_animation() -> void:
	var season_names = ["spring", "summer", "fall", "winter"]
	var season = season_names[GameManager.current_season] if GameManager else "spring"
	var anim = "stage_%d_%s" % [growth_stage, season]
	if animated_sprite.sprite_frames.has_animation(anim):
		animated_sprite.play(anim)

## ==================== INTERAÇÕES ====================
var _player_nearby: bool = false

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		_player_nearby = true
		name_label.visible = true
		if fruit_ready:
			HUD.show_interaction_prompt("E: Colher (%dx %s)" % [fruit_amount, tree_type], global_position + Vector2(0, -60))
		elif growth_stage < 4:
			HUD.show_interaction_prompt("E: Verificar (%d anos)" % (age_days / 28), global_position + Vector2(0, -60))
		else:
			HUD.show_interaction_prompt("E: Verificar", global_position + Vector2(0, -60))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		_player_nearby = false
		name_label.visible = false
		HUD.hide_interaction_prompt()

func interact(action: String = "check") -> Dictionary:
	match action:
		"harvest":
			return harvest()
		"chop":
			chop_down()
			return {}
		"check":
			return get_info()
	return {}

func harvest() -> Dictionary:
	if not fruit_ready:
		return {}

	var item_id = tree_data.get("FruitItemId", "")
	if not item_id:
		return {}

	var result = {
		"item_id": item_id,
		"amount": fruit_amount,
		"quality": fruit_quality
	}

	# Adiciona ao inventário
	for i in range(fruit_amount):
		InventoryManager.add_item(item_id, 1, fruit_quality)

	# XP Foraging
	GameManager.add_skill_xp(3, 7 * fruit_amount)

	fruit_ready = false
	fruit_amount = 1
	_update_fruit_visual()

	emit_signal("tree_harvested", self, item_id, fruit_amount, fruit_quality)
	return result

func chop_down() -> void:
	if is_stumped:
		return

	is_stumped = true
	animated_sprite.play("stump")
	interaction_area.monitoring = false
	fruit_area.monitoring = false

	# Drop madeira
	var wood_amount = max(1, growth_stage) * 2
	for i in range(wood_amount):
		InventoryManager.add_item("(O)388", 1)  # Wood

	# Se tinha fruto, dropa também
	if fruit_ready:
		harvest()

	emit_signal("tree_destroyed", self)

func apply_fertilizer(fert_type: String) -> bool:
	if has_fertilizer:
		_show_message("Já tem fertilizante!")
		return false

	if growth_stage >= 4:
		_show_message("Árvore adulta não aceita fertilizante!")
		return false

	has_fertilizer = true
	fertilizer_type = fert_type
	_show_message("Fertilizante aplicado!")
	return true

func get_info() -> Dictionary:
	return {
		"type": tree_type,
		"age_years": age_days / 28,
		"age_days": age_days % 28,
		"stage": growth_stage,
		"fruit_ready": fruit_ready,
		"fruit_quality": fruit_quality,
		"fertilizer": fertilizer_type
	}

func _on_fruit_collected(area: Area2D) -> void:
	if area.is_in_group("player") and fruit_ready:
		harvest()

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"tree_type": tree_type,
		"tree_id": tree_id,
		"age_days": age_days,
		"growth_stage": growth_stage,
		"season_planted": season_planted,
		"last_fruit_day": last_fruit_day,
		"fruit_ready": fruit_ready,
		"fruit_quality": fruit_quality,
		"fruit_amount": fruit_amount,
		"is_stumped": is_stumped,
		"has_fertilizer": has_fertilizer,
		"fertilizer_type": fertilizer_type,
		"position": global_position
	}

func load_save_data(data: Dictionary) -> void:
	tree_type = data.get("tree_type", "")
	tree_id = data.get("tree_id", "")
	age_days = data.get("age_days", 0)
	growth_stage = data.get("growth_stage", 0)
	season_planted = data.get("season_planted", 0)
	last_fruit_day = data.get("last_fruit_day", -1)
	fruit_ready = data.get("fruit_ready", false)
	fruit_quality = data.get("fruit_quality", 0)
	fruit_amount = data.get("fruit_amount", 1)
	is_stumped = data.get("is_stumped", false)
	has_fertilizer = data.get("has_fertilizer", false)
	fertilizer_type = data.get("fertilizer_type", "")
	global_position = data.get("position", Vector2.ZERO)

	initialize(tree_type, tree_id, season_planted, has_fertilizer, fertilizer_type)
	# Reaplica estado
	age_days = data.get("age_days", 0)
	growth_stage = data.get("growth_stage", 0)
	_apply_stage_scale()
	if fruit_ready:
		_update_fruit_visual()

func _show_message(text: String) -> void:
	print("FruitTree: %s" % text)