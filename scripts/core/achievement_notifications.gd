extends Node

## Sistema de Notificações de Conquistas e Progresso

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	if GameManager:
		GameManager.achievement_unlocked.connect(_on_achievement_unlocked)
		GameManager.skill_level_up.connect(_on_skill_level_up)
		GameManager.friendship_changed.connect(_on_friendship_milestone)
		GameManager.crop_harvested.connect(_on_crop_harvested)
		GameManager.fish_caught.connect(_on_fish_caught)
		GameManager.monster_killed.connect(_on_monster_killed)
		GameManager.recipe_learned.connect(_on_recipe_learned)
		GameManager.building_built.connect(_on_building_built)
		GameManager.item_shipped.connect(_on_item_shipped)

	# Conquistas rastreadas internamente
	_achievement_progress = {}

	# Verifica conquistas iniciais
	_check_startup_achievements()

## ==================== CONQUISTAS ====================
const ACHIEVEMENTS = {
	# Agricultura
	"first_crop": {"name": "Primeira Colheita", "desc": "Colha sua primeira cultura", "icon": "🌱", "type": "counter", "target": 1, "stat": "crops_harvested"},
	"farmer_10": {"name": "Agricultor Iniciante", "desc": "Colha 10 culturas", "icon": "🌾", "type": "counter", "target": 10, "stat": "crops_harvested"},
	"farmer_100": {"name": "Agricultor Experiente", "desc": "Colha 100 culturas", "icon": "🌽", "type": "counter", "target": 100, "stat": "crops_harvested"},
	"farmer_1000": {"name": "Mestre Agricultor", "desc": "Colha 1000 culturas", "icon": "👑", "type": "counter", "target": 1000, "stat": "crops_harvested"},
	"all_season_crops": {"name": "Quatro Estações", "desc": "Plante pelo menos uma cultura em cada estação", "icon": "🌸", "type": "collection", "target": 4, "check": "_check_season_crops"},

	# Mineração
	"first_ore": {"name": "Primeiro Minério", "desc": "Miner seu primeiro minério", "icon": "⛏️", "type": "counter", "target": 1, "stat": "ores_mined"},
	"miner_50": {"name": "Minerador", "desc": "Miner 50 minérios", "icon": "💎", "type": "counter", "target": 50, "stat": "ores_mined"},
	"deep_delver": {"name": "Explorador Profundo", "desc": "Chegue ao nível 40 da mina", "icon": "🕳️", "type": "milestone", "target": 40, "check": "_check_mine_level"},
	"skull_cavern": {"name": "Caverna da Caveira", "desc": "Chegue ao nível 120 da mina", "icon": "💀", "type": "milestone", "target": 120, "check": "_check_mine_level"},

	# Pesca
	"first_fish": {"name": "Primeiro Peixe", "desc": "Pesque seu primeiro peixe", "icon": "🐟", "type": "counter", "target": 1, "stat": "fish_caught"},
	"angler_10": {"name": "Pescador", "desc": "Pesque 10 peixes", "icon": "🎣", "type": "counter", "target": 10, "stat": "fish_caught"},
	"angler_100": {"name": "Mestre Pescador", "desc": "Pesque 100 peixes", "icon": "🏆", "type": "counter", "target": 100, "stat": "fish_caught"},
	"legendary_fish": {"name": "Lenda Viva", "desc": "Pesque um peixe lendário", "icon": "⭐", "type": "collection", "target": 5, "check": "_check_legendary_fish"},

	# Combate
	"first_kill": {"name": "Primeiro Sangue", "desc": "Derrote seu primeiro monstro", "icon": "⚔️", "type": "counter", "target": 1, "stat": "monsters_killed"},
	"slayer_50": {"name": "Matador", "desc": "Derrote 50 monstros", "icon": "🗡️", "type": "counter", "target": 50, "stat": "monsters_killed"},
	"slayer_500": {"name": "Carniceiro", "desc": "Derrote 500 monstros", "icon": "☠️", "type": "counter", "target": 500, "stat": "monsters_killed"},

	# Social
	"first_friend": {"name": "Primeiro Amigo", "desc": "Alcance 2 corações com alguém", "icon": "💚", "type": "milestone", "target": 2, "check": "_check_hearts"},
	"popular": {"name": "Popular", "desc": "Alcance 5 corações com 5 pessoas", "icon": "❤️", "type": "collection", "target": 5, "check": "_check_hearts_5"},
	"best_friends": {"name": "Melhores Amigos", "desc": "Alcance 10 corações com alguém", "icon": "💕", "type": "milestone", "target": 10, "check": "_check_hearts_10"},
	"married": {"name": "Casado", "desc": "Case-se com alguém", "icon": "💍", "type": "milestone", "target": 1, "check": "_check_married"},

	# Dinheiro
	"first_1000g": {"name": "Primeiro Ouro", "desc": "Acumule 1000g", "icon": "💰", "type": "milestone", "target": 1000, "stat": "gold"},
	"rich_100k": {"name": "Rico", "desc": "Tenha 100.000g", "icon": "💎", "type": "milestone", "target": 100000, "stat": "gold"},
	"millionaire": {"name": "Milionário", "desc": "Tenha 1.000.000g", "icon": "👑", "type": "milestone", "target": 1000000, "stat": "gold"},

	# Coleções
	"shipped_50": {"name": "Colecionador", "desc": "Envie 50 itens diferentes", "icon": "📦", "type": "collection", "target": 50, "check": "_check_shipped_unique"},
	"complete_museum": {"name": "Curador", "desc": "Complete o museu", "icon": "🏛️", "type": "milestone", "target": 1, "check": "_check_museum_complete"},
	"complete_cc": {"name": "Restaurador", "desc": "Complete o Centro Comunitário", "icon": "🏘️", "type": "milestone", "target": 1, "check": "_check_cc_complete"},

	# Culinária
	"chef_10": {"name": "Cozinheiro", "desc": "Cozinhe 10 receitas diferentes", "icon": "🍳", "type": "collection", "target": 10, "check": "_check_cooking_recipes"},
	"gourmet": {"name": "Gourmet", "desc": "Cozinhe 50 receitas diferentes", "icon": "👨‍🍳", "type": "collection", "target": 50, "check": "_check_cooking_recipes"},

	# Artesanato
	"crafter_10": {"name": "Artesão", "desc": "Crafte 10 itens diferentes", "icon": "🔨", "type": "collection", "target": 10, "check": "_check_crafting_recipes"},

	# Exploração
	"explorer": {"name": "Explorador", "desc": "Visite todas as áreas do mapa", "icon": "🗺️", "type": "collection", "target": 10, "check": "_check_locations_visited"},
}

var _achievement_progress: Dictionary = {}

## ==================== CALLBACKS ====================
func _on_achievement_unlocked(achievement_id: String) -> void:
	_show_achievement_popup(achievement_id)

func _on_skill_level_up(skill_index: int, new_level: int) -> void:
	# Verifica conquistas relacionadas a skills
	_check_skill_achievements(skill_index, new_level)

func _on_friendship_milestone(npc: String, new_points: int) -> void:
	_check_friendship_achievements(npc, new_points)

func _on_crop_harvested(crop_id: String, amount: int, quality: int) -> void:
	_increment_counter("crops_harvested", amount)
	_check_crop_achievements(crop_id, quality)

func _on_fish_caught(fish_id: String, size: float, quality: int, location: String) -> void:
	_increment_counter("fish_caught", 1)
	_check_fish_achievements(fish_id, quality, size)

func _on_monster_killed(monster_type: String, level: int) -> void:
	_increment_counter("monsters_killed", 1)

func _on_recipe_learned(recipe_id: String) -> void:
	_check_recipe_achievements(recipe_id)

func _on_building_built(building_type: String, position: Vector2i) -> void:
	_check_building_achievements(building_type)

func _on_item_shipped(item_id: String, amount: int, quality: int) -> void:
	_increment_counter("items_shipped", amount)
	_check_shipping_achievements(item_id, quality)

## ==================== VERIFICAÇÕES ====================
func _check_startup_achievements() -> void:
	if GameManager:
		# Verifica ouro
		_check_milestone("first_1000g", GameManager.gold)
		_check_milestone("rich_100k", GameManager.gold)
		_check_milestone("millionaire", GameManager.gold)

		# Verifica nível de mina
		var mine_level = GameManager.get_data("deepest_mine_level", 0)
		_check_milestone("deep_delver", mine_level)
		_check_milestone("skull_cavern", mine_level)

		# Verifica casamento
		if GameManager.get_data("spouse", "") != "":
			_unlock_achievement("married")

func _check_skill_achievements(skill_index: int, level: int) -> void:
	var skill_names = ["farming", "mining", "foraging", "fishing", "combat"]
	var skill = skill_names[skill_index]

	if level >= 5 or level >= 10:
		# Profissão escolhida
		pass

	if skill == "farming" and level >= 10:
		# Desbloqueia receitas de sprinkler
		pass

func _check_friendship_achievements(npc: String, points: int) -> void:
	var hearts = points / 250

	# 2 corações com alguém
	if hearts >= 2:
		_unlock_achievement("first_friend")

	# 10 corações com alguém
	if hearts >= 10:
		_unlock_achievement("best_friends")

	# Conta quantos NPCs têm 5+ corações
	var count_5 = 0
	for npc_name in GameManager.friendships:
		if GameManager.friendships[npc_name] / 250 >= 5:
			count_5 += 1
	if count_5 >= 5:
		_unlock_achievement("popular")

func _check_crop_achievements(crop_id: String, quality: int) -> void:
	# Verifica culturas de todas as estações
	var crop_data = DataLoader.get_crop(crop_id.to_int())
	if crop_data:
		var season = crop_data.seasons[0] if crop_data.seasons else 0
		_achievement_progress["season_crops_%d" % season] = true

		if _achievement_progress["season_crops_0"] and _achievement_progress["season_crops_1"] and \
		   _achievement_progress["season_crops_2"] and _achievement_progress["season_crops_3"]:
			_unlock_achievement("all_season_crops")

func _check_fish_achievements(fish_id: String, quality: int, size: float) -> void:
	# Peixes lendários
	var legendary_fish = ["(O)158", "(O)160", "(O)162", "(O)164", "(O)166"]
	if fish_id in legendary_fish:
		_achievement_progress["legendary_%s" % fish_id] = true
		var count = 0
		for lf in legendary_fish:
			if _achievement_progress["legendary_%s" % lf]:
				count += 1
		if count >= 5:
			_unlock_achievement("legendary_fish")

func _check_recipe_achievements(recipe_id: String) -> void:
	# Conta receitas de culinária
	if recipe_id.begins_with("Cooking"):
		var count = 0
		for r in GameManager.unlocked_cooking_recipes:
			if r.begins_with("Cooking"):
				count += 1
		if count >= 10:
			_unlock_achievement("chef_10")
		if count >= 50:
			_unlock_achievement("gourmet")

	# Receitas de crafting
	if recipe_id.begins_with("Crafting"):
		var count = 0
		for r in GameManager.unlocked_recipes:
			if r.begins_with("Crafting"):
				count += 1
		if count >= 10:
			_unlock_achievement("crafter_10")

func _check_building_achievements(building_type: String) -> void:
	# Verifica se tem todos os edifícios principais
	var key_buildings = ["House", "Barn", "Coop", "Silo", "Stable", "Well", "Greenhouse"]
	var count = 0
	for b in key_buildings:
		if GameManager.get_data("building_%s_built" % b, false):
			count += 1
	# Conquista implícita por completar

func _check_shipping_achievements(item_id: String, quality: int) -> void:
	# Itens únicos enviados
	_achievement_progress["shipped_%s" % item_id] = true
	var unique_count = 0
	for key in _achievement_progress:
		if key.begins_with("shipped_"):
			unique_count += 1
	if unique_count >= 50:
		_unlock_achievement("shipped_50")

## ==================== HELPERS ====================
func _increment_counter(stat: String, amount: int) -> void:
	var current = _achievement_progress.get(stat, 0)
	_achievement_progress[stat] = current + amount

	# Verifica conquistas baseadas em contador
	for ach_id in ACHIEVEMENTS:
		var ach_data = ACHIEVEMENTS[ach_id]
		if ach_data.type == "counter" and ach_data.stat == stat:
			var target = ach_data.target
			if _achievement_progress[stat] >= target:
				_unlock_achievement(ach_id)

func _check_milestone(ach_id: String, current_value: int) -> void:
	if ach_id in ACHIEVEMENTS:
		var target = ACHIEVEMENTS[ach_id].target
		if current_value >= target:
			_unlock_achievement(ach_id)

func _unlock_achievement(ach_id: String) -> void:
	if ach_id in GameManager.achievements:
		return  # Já desbloqueado

	if ach_id in ACHIEVEMENTS:
		GameManager.achievements.append(ach_id)
		GameManager.emit_signal("achievement_unlocked", ach_id)
		Logger.info("Conquista desbloqueada: %s" % ach_id)

## ==================== POPUP VISUAL ====================
func _show_achievement_popup(ach_id: String) -> void:
	var ach = ACHIEVEMENTS.get(ach_id, {})
	var name = ach.get("name", ach_id)
	var desc = ach.get("desc", "")
	var icon = ach.get("icon", "🏆")

	var panel = Panel.new()
	panel.name = "AchievementPopup_%s" % ach_id
	panel.anchors_preset = 11  # Top right
	panel.offset_left = -400
	panel.offset_top = 50 + (_get_popup_count() * 120)
	panel.offset_right = -20
	panel.offset_bottom = -120

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var header = HBoxContainer.new()
	vbox.add_child(header)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.theme_override_font_size = 32
	header.add_child(icon_label)

	var text_vbox = VBoxContainer.new()
	header.add_child(text_vbox)

	var title = Label.new()
	title.text = "🏆 Conquista Desbloqueada!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.theme_override_font_size = 16
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	text_vbox.add_child(title)

	var name_label = Label.new()
	name_label.text = name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.theme_override_font_size = 18
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	text_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = desc
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	desc_label.theme_override_font_size = 13
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	text_vbox.add_child(desc_label)

	# Animação de entrada
	panel.modulate = Color(1, 1, 1, 0)
	panel.position = Vector2(50, 0)
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.5).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "position", Vector2(0, 0), 0.5).set_trans(Tween.TRANS_BACK)

	# Som
	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/achievement.ogg")

	get_tree().root.get_child(0).add_child(panel)

	# Auto-remove após 5 segundos
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(_fade_out_popup.bind(panel))
	panel.add_child(timer)
	timer.start()

func _fade_out_popup(panel: Panel) -> void:
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_property(panel, "position:x", 50, 0.5)
	tween.finished.connect(panel.queue_free.bind())

func _get_popup_count() -> int:
	var count = 0
	var root = get_tree().root.get_child(0)
	for child in root.get_children():
		if child.name.begins_with("AchievementPopup_"):
			count += 1
	return count