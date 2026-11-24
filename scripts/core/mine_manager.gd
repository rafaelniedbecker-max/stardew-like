class_name MineManager
extends Node

## Gerencia a mina: andares, minérios, monstros, elevador, escadas

@export var mine_scene: PackedScene
@export var mine_level_scene: PackedScene
@export var monster_scene: PackedScene
@export var ore_node_scene: PackedScene
@export var ladder_scene: PackedScene
@export var elevator_scene: PackedScene

## Estado da mina
var current_level: int = 0  # 0 = entrada, 1-120 = andares
var deepest_level_reached: int = 0
var levels_cleared: Dictionary = {}  # {level: true}
var elevator_unlocked: bool = false

## Andar atual
var current_level_instance: Node2D = null
var level_monsters: Array = []
var level_ore_nodes: Array = []
var level_ladders: Array = []

## Configurações da mina
const MAX_LEVEL = 120
const LEVELS_PER_THEME = 10
const THEMES = ["brown", "ice", "lava"]  # 1-40, 41-80, 81-120

## Minérios por tema
const ORE_BY_THEME = {
	"brown": ["Copper", "Iron", "Coal", "Stone", "Geode"],
	"ice": ["Iron", "Gold", "Iridium", "Frozen Geode", "Stone"],
	"lava": ["Gold", "Iridium", "Radioactive Ore", "Magma Geode", "Stone"]
}

## Monstros por tema
const MONSTERS_BY_THEME = {
	"brown": ["Green Slime", "Rock Crab", "Bug", "Dust Spirit", "Bat"],
	"ice": ["Ice Slime", "Frost Bat", "Ice Golem", "Shadow Shaman", "Squid Kid"],
	"lava": ["Lava Slime", "Magma Sprite2D", "Fire Bat", "Iridium Bat", "Serpent"]
}

## ==================== SINAIS ====================
signal level_changed(new_level: int)
signal level_generated(level: int, theme: String)
signal monster_spawned(monster: Node)
signal ore_spawned(ore: Node)
signal ladder_found(level: int, position: Vector2)
signal elevator_unlocked()
signal mine_entered()
signal mine_exited()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Carrega progresso salvo
	_load_mine_progress()

func _load_mine_progress() -> void:
	if GameManager:
		deepest_level_reached = GameManager.get("deepest_mine_level", 0)
		elevator_unlocked = GameManager.get("mine_elevator_unlocked", false)
		levels_cleared = GameManager.get("mine_levels_cleared", {})

		# Desbloqueia elevador a cada 5 andares
		if deepest_level_reached >= 5:
			elevator_unlocked = true
			GameManager.set("mine_elevator_unlocked", true)

## ==================== ENTRAR NA MINA ====================
func enter_mine(target_level: int = -1) -> void:
	# Usa o novo sistema de transições
	if MineTransitions:
		MineTransitions.enter_mine(target_level)
		MineTransitions.mine_exited.connect(_on_mine_exited)
		return

	# Fallback para sistema antigo
	if target_level == -1:
		target_level = max(1, deepest_level_reached - 4)
		if elevator_unlocked and deepest_level_reached > 5:
			_show_elevator_menu()
			return

	current_level = target_level
	_generate_level(current_level)
	emit_signal("mine_entered")

func _show_elevator_menu() -> void:
	var popup = PopupMenu.new()
	for i in range(0, deepest_level_reached + 1, 5):
		popup.add_item("Andar %d (%s)" % [i, _get_theme_name(i)], i)
	popup.id_pressed.connect(_on_elevator_selected)
	add_child(popup)
	popup.popup_centered()

func _on_elevator_selected(level: int) -> void:
	current_level = level
	_generate_level(current_level)
	emit_signal("mine_entered")

## ==================== GERAÇÃO DE ANDAR ====================
func _generate_level(level: int) -> void:
	# Limpa andar anterior
	if current_level_instance:
		current_level_instance.queue_free()
	level_monsters.clear()
	level_ore_nodes.clear()
	level_ladders.clear()

	# Cria instância do andar
	current_level_instance = mine_level_scene.instantiate()
	current_level_instance.name = "MineLevel_%d" % level
	get_tree().root.get_child(0).add_child(current_level_instance)

	# Determina tema
	var theme = _get_theme(level)

	# Gera layout (simplificado - usa TileMap)
	_generate_layout(level, theme)

	# Spawna minérios
	_spawn_ores(level, theme)

	# Spawna monstros
	_spawn_monsters(level, theme)

	# Spawna escadas
	_spawn_ladders(level)

	# Atualiza progresso
	if level > deepest_level_reached:
		deepest_level_reached = level
		if GameManager:
			GameManager.set("deepest_mine_level", level)
			if level % 5 == 0:
				elevator_unlocked = true
				GameManager.set("mine_elevator_unlocked", true)
				emit_signal("elevator_unlocked")

	emit_signal("level_generated", level, theme)
	emit_signal("level_changed", level)

func _get_theme(level: int) -> String:
	if level <= 40:
		return "brown"
	elif level <= 80:
		return "ice"
	return "lava"

func _get_theme_name(level: int) -> String:
	var theme = _get_theme(level)
	return {"brown": "Minas", "ice": "Gelo", "lava": "Lava"}[theme]

func _generate_layout(level: int, theme: String) -> void:
	# TODO: Geração procedural real de cavernas
	# Por enquanto: sala retangular simples com TileMap
	var tilemap = current_level_instance.get_node_or_null("TileMap")
	if tilemap:
		# Preenche chão
		for x in range(20):
			for y in range(15):
				tilemap.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))  # Chão
		# Paredes nas bordas
		for x in range(20):
			tilemap.set_cell(Vector2i(x, 0), 1, Vector2i(1, 0))
			tilemap.set_cell(Vector2i(x, 14), 1, Vector2i(1, 1))
		for y in range(15):
			tilemap.set_cell(Vector2i(0, y), 1, Vector2i(2, 0))
			tilemap.set_cell(Vector2i(19, y), 1, Vector2i(2, 1))

func _spawn_ores(level: int, theme: String) -> void:
	var ores = ORE_BY_THEME[theme]
	var ore_count = randi_range(5, 15) + (level / 10)

	for i in range(ore_count):
		var ore_type = ores[randi() % ores.size()]
		var ore = ore_node_scene.instantiate()
		ore.initialize(ore_type, level)
		var pos = Vector2(randi_range(50, 590), randi_range(50, 430))
		ore.global_position = pos
		current_level_instance.add_child(ore)
		level_ore_nodes.append(ore)

		emit_signal("ore_spawned", ore)

func _spawn_monsters(level: int, theme: String) -> void:
	var monsters = MONSTERS_BY_THEME[theme]
	var monster_count = randi_range(3, 8) + (level / 20)

	for i in range(monster_count):
		var monster_type = monsters[randi() % monsters.size()]
		var monster = monster_scene.instantiate()
		monster.initialize(monster_type, level)
		var pos = Vector2(randi_range(100, 540), randi_range(100, 380))
		monster.global_position = pos
		current_level_instance.add_child(monster)
		level_monsters.append(monster)

		emit_signal("monster_spawned", monster)

func _spawn_ladders(level: int) -> void:
	# Escada para baixo (exceto no último andar)
	if level < MAX_LEVEL:
		var ladder_down = ladder_scene.instantiate()
		ladder_down.initialize("down", level + 1)
		ladder_down.global_position = Vector2(randi_range(100, 540), randi_range(100, 380))
		current_level_instance.add_child(ladder_down)
		level_ladders.append(ladder_down)

	# Escada para cima (exceto no primeiro)
	if level > 1:
		var ladder_up = ladder_scene.instantiate()
		ladder_up.initialize("up", level - 1)
		ladder_up.global_position = Vector2(randi_range(100, 540), randi_range(100, 380))
		current_level_instance.add_child(ladder_up)
		level_ladders.append(ladder_up)

	# Marca andar como limpo se matou todos monstros
	levels_cleared[level] = false

## ==================== NAVEGAÇÃO ====================
func go_down() -> void:
	if current_level < MAX_LEVEL:
		current_level += 1

		# Usa MineTransitions se disponível
		if MineTransitions:
			MineTransitions.next_level()

		_generate_level(current_level)

func go_up() -> void:
	if current_level > 1:
		current_level -= 1
		_generate_level(current_level)
	else:
		exit_mine()

func _on_mine_exited(level: int) -> void:
	# Chamado quando o jogador sai da mina via MineTransitions
	current_level = 0
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null

func exit_mine() -> void:
	if current_level_instance:
		current_level_instance.queue_free()
		current_level_instance = null
	current_level = 0
	emit_signal("mine_exited")

	# Notifica transições se estiver usando
	if MineTransitions:
		MineTransitions.visible = false
		MineTransitions.panel.visible = false
		MineTransitions._get_tree().paused = false

## ==================== MONSTROS MORTOS ====================
func on_monster_killed(monster: Node) -> void:
	level_monsters.erase(monster)

	# Drop de loot
	var drops = _get_monster_drops(monster)
	for drop in drops:
		InventoryManager.add_item(drop.item_id, drop.amount)

	# XP de combate
	GameManager.add_skill_xp(4, monster.get("xp_reward", 10))

	# Verifica se limpou o andar
	if level_monsters.is_empty() and not levels_cleared.get(current_level, false):
		levels_cleared[current_level] = true
		if GameManager:
			var cleared = GameManager.get("mine_levels_cleared", {})
			cleared[str(current_level)] = true
			GameManager.set("mine_levels_cleared", cleared)

		# Chance de baú aparecer
		if randf() < 0.3:
			_spawn_chest()

func _get_monster_drops(monster: Node) -> Array:
	# Baseado no tipo do monstro
	var monster_type = monster.get("monster_type", "")
	var drops = []

	# Loot table simplificado
	match monster_type:
		"Green Slime", "Ice Slime", "Lava Slime":
			drops.append({"item_id": "(O)766", "amount": randi_range(1, 3)})  # Slime
		"Rock Crab", "Frost Golem", "Magma Sprite2D":
			drops.append({"item_id": "(O)390", "amount": randi_range(1, 2)})  # Stone
		"Bat", "Frost Bat", "Fire Bat":
			drops.append({"item_id": "(O)393", "amount": 1})  # Bat Wing
		"Bug":
			drops.append({"item_id": "(O)394", "amount": 1})  # Bug Meat
		_:
			pass

	return drops

func _spawn_chest() -> void:
	var chest = Node2D.new()
	chest.name = "MineChest"
	# TODO: Sprite de baú
	var area = Area2D.new()
	area.monitoring = true
	var rect = RectangleShape2D.new()
	rect.size = Vector2(32, 32)
	var col = CollisionShape2D.new()
	col.shape = rect
	area.add_child(col)
	area.area_entered.connect(_on_chest_opened)
	chest.add_child(area)
	chest.global_position = Vector2(randi_range(200, 440), randi_range(200, 280))
	current_level_instance.add_child(chest)

func _on_chest_opened(area: Area2D) -> void:
	if area.is_in_group("player"):
		# Loot do baú
		var loot = _generate_chest_loot()
		for item in loot:
			InventoryManager.add_item(item.item_id, item.amount)
		area.get_parent().queue_free()

func _generate_chest_loot() -> Array:
	var loot = []
	var theme = _get_theme(current_level)

	# Garante pelo menos 1 minério bom
	var good_ores = {"brown": ["(O)384", "(O)386"], "ice": ["(O)386", "(O)388"], "lava": ["(O)388", "(O)390"]}
	loot.append({"item_id": good_ores[theme][randi() % 2], "amount": randi_range(3, 6)})

	# Itens extras
	for i in range(randi_range(1, 3)):
		var extra = ["(O)382", "(O)386", "(O)388", "(O)390", "(O)767", "(O)768"]
		loot.append({"item_id": extra[randi() % extra.size()], "amount": randi_range(1, 3)})

	return loot

## ==================== MINÉRIO COLETADO ====================
func on_ore_mined(ore: Node, item_id: String, amount: int) -> void:
	level_ore_nodes.erase(ore)
	InventoryManager.add_item(item_id, amount)

	# XP de mineração
	var xp = {"(O)378": 3, "(O)380": 5, "(O)384": 8, "(O)386": 10, "(O)388": 12}[item_id] ?? 3
	GameManager.add_skill_xp(1, xp)

	# Chance de geoda
	if randf() < 0.1:
		var geodes = {"brown": "(O)535", "ice": "(O)536", "lava": "(O)537"}
		InventoryManager.add_item(geodes[_get_theme(current_level)], 1)

## ==================== UTILIDADES ====================
func get_current_level() -> int:
	return current_level

func get_deepest_level() -> int:
	return deepest_level_reached

func is_elevator_unlocked() -> bool:
	return elevator_unlocked

func get_level_theme(level: int) -> String:
	return _get_theme(level)

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"deepest_level": deepest_level_reached,
		"elevator_unlocked": elevator_unlocked,
		"levels_cleared": levels_cleared
	}