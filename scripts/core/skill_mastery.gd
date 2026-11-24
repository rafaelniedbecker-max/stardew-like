class_name SkillMastery
extends Node

## Sistema de Maestria de Habilidades (nível 10+) com benefícios especiais

@export var mastery_ui_scene: PackedScene

## Estado
var mastery_levels: Dictionary = {}  # skill_index -> mastery_level (0-5)
var mastery_xp: Dictionary = {}  # skill_index -> xp
var unlocked_masteries: Dictionary = {}  # skill_index -> Array[mastery_id]

## XP necessária por nível de maestria
const MASTERY_XP_REQUIRED = [0, 10000, 25000, 50000, 100000, 200000]

## Maestrias por habilidade
const MASTERIES = {
	0: {  # Farming
		"farming_1": {"name": "Mãos Verdes I", "desc": "Culturas crescem 10% mais rápido", "effect": "growth_speed", "value": 0.10},
		"farming_2": {"name": "Colheita Farta I", "desc": "+1 item extra na colheita (chance 20%)", "effect": "extra_harvest", "value": 0.20},
		"farming_3": {"name": "Qualidade Superior I", "desc": "+15% chance de qualidade prata/ouro", "effect": "quality_boost", "value": 0.15},
		"farming_4": {"name": "Mestre das Estações", "desc": "Pode plantar culturas fora de estação (estufa não necessária)", "effect": "ignore_season", "value": 1},
		"farming_5": {"name": "Lenda Viva", "desc": "Todas as anteriores + culturas regrow instantâneo", "effect": "instant_regrow", "value": 1}
	},
	1: {  # Mining
		"mining_1": {"name": "Rocha Dura I", "desc": "Minérios dropam +1 unidade (chance 30%)", "effect": "extra_ore", "value": 0.30},
		"mining_2": {"name": "Olho de Geólogo", "desc": "Geodas dropam 2 itens", "effect": "double_geode", "value": 1},
		"mining_3": {"name": "Sorte do Mineiro", "desc": "+25% chance de irídio/prismatic shard", "effect": "rare_boost", "value": 0.25},
		"mining_4": {"name": "Elevador Mestre", "desc": "Pode ir a qualquer nível da mina instantaneamente", "effect": "any_level", "value": 1},
		"mining_5": {"name": "Coração da Terra", "desc": "Todas as anteriores + auto-smelt ores", "effect": "auto_smelt", "value": 1}
	},
	2: {  # Foraging
		"foraging_1": {"name": "Olho de Falcão I", "desc": "Itens de forrageamento aparecem destacadas", "effect": "highlight_forage", "value": 1},
		"foraging_2": {"name": "Mãos de Madeira", "desc": "Árvores dropam +1 madeira/serra", "effect": "extra_wood", "value": 1},
		"foraging_3": {"name": "Botânico Mestre", "desc": "Itens de forrageamento sempre qualidade ouro", "effect": "forage_gold_quality", "value": 1},
		"foraging_4": {"name": "Semeador Selvagem", "desc": "Planta sementes selvagens (mudas de árvores)", "effect": "wild_seeds", "value": 1},
		"foraging_5": {"name": "Guardião da Floresta", "desc": "Todas as anteriores + árvores crescem 2x mais rápido", "effect": "fast_trees", "value": 1}
	},
	3: {  # Fishing
		"fishing_1": {"name": "Pescador Nato I", "desc": "Barra de pesca 15% maior", "effect": "bigger_bar", "value": 0.15},
		"fishing_2": {"name": "Olho de Peixe", "desc": "Vê tipo/tamanho do peixe antes de puxar", "effect": "see_fish_info", "value": 1},
		"fishing_3": {"name": "Mestre das Iscas", "desc": "Iscas duram 2x mais, anzol nunca quebra", "effect": "infinite_tackle", "value": 1},
		"fishing_4": {"name": "Senhor dos Mares", "desc": "Pesca lendários sem isca especial", "effect": "legendary_no_bait", "value": 1},
		"fishing_5": {"name": "Poseidon", "desc": "Todas as anteriores + peixes nunca escapam", "effect": "never_escape", "value": 1}
	},
	4: {  # Combat
		"combat_1": {"name": "Guerreiro Nato I", "desc": "+10% dano crítico", "effect": "crit_chance", "value": 0.10},
		"combat_2": {"name": "Pele de Ferro", "desc": "-15% dano recebido", "effect": "damage_reduction", "value": 0.15},
		"combat_3": {"name": "Golpe Mortal", "desc": "Chance de matar instantaneamente (5%)", "effect": "insta_kill", "value": 0.05},
		"combat_4": {"name": "Mestre das Armas", "desc": "Todas as armas têm efeito especial ativo", "effect": "weapon_effects", "value": 1},
		"combat_5": {"name": "Lenda Viva", "desc": "Todas as anteriores + imune a knockback", "effect": "knockback_immune", "value": 1}
	}
}

## ==================== SINAIS ====================
signal mastery_gained(skill_index: int, mastery_id: String)
signal mastery_xp_gained(skill_index: int, amount: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_mastery_data()

	if GameManager:
		GameManager.skill_level_up.connect(_on_skill_level_up)
		GameManager.monster_killed.connect(_on_monster_killed)
		GameManager.fish_caught.connect(_on_fish_caught)
		GameManager.crop_harvested.connect(_on_crop_harvested)
		GameManager.ore_mined.connect(_on_ore_mined)
		GameManager.forage_collected.connect(_on_forage_collected)

func _load_mastery_data() -> void:
	if GameManager:
		mastery_levels = GameManager.get("mastery_levels", {})
		mastery_xp = GameManager.get("mastery_xp", {})
		unlocked_masteries = GameManager.get("unlocked_masteries", {})

func _on_skill_level_up(skill_index: int, new_level: int) -> void:
	if new_level >= 10:
		# Inicia maestria
		if not mastery_levels.has(skill_index):
			mastery_levels[skill_index] = 0
			mastery_xp[skill_index] = 0
			unlocked_masteries[skill_index] = []

		HUD.show_notification("⭐ Maestria Desbloqueada!", "Habilidade %s atingiu nível 10! Ganhe XP de maestria para benefícios especiais." % _get_skill_name(skill_index), Color(1.0, 0.8, 0.2))

		if ParticleManager:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				ParticleManager.show_level_up(player.global_position, "Maestria!")

		if AudioManager:
			AudioManager.play_sfx("res://assets/sfx/mastery_unlock.ogg")

func _on_monster_killed(monster_type: String, level: int) -> void:
	_add_mastery_xp(4, level * 10)  # Combat

func _on_fish_caught(fish_id: String, size: float, quality: int, location: String) -> void:
	var base_xp = 50 + quality * 25
	_add_mastery_xp(3, int(base_xp * size))  # Fishing

func _on_crop_harvested(crop_id: String, amount: int, quality: int) -> void:
	_add_mastery_xp(0, amount * 10 + quality * 5)  # Farming

func _on_ore_mined(ore_id: String, amount: int) -> void:
	_add_mastery_xp(1, amount * 20)  # Mining

func _on_forage_collected(item_id: String) -> void:
	_add_mastery_xp(2, 15)  # Foraging

func _add_mastery_xp(skill_index: int, amount: int) -> void:
	if not mastery_levels.has(skill_index):
		return

	var current_xp = mastery_xp.get(skill_index, 0)
	var current_level = mastery_levels.get(skill_index, 0)

	if current_level >= 5:
		return  # Max level

	mastery_xp[skill_index] = current_xp + amount

	var required = MASTERY_XP_REQUIRED[current_level + 1]
	if mastery_xp[skill_index] >= required:
		_level_up_mastery(skill_index)

	emit_signal("mastery_xp_gained", skill_index, amount)

func _level_up_mastery(skill_index: int) -> void:
	var new_level = mastery_levels[skill_index] + 1
	mastery_levels[skill_index] = new_level

	# Desbloqueia maestria
	var mastery_id = "%s_%d" % [_get_skill_key(skill_index), new_level]
	if not unlocked_masteries.has(skill_index):
		unlocked_masteries[skill_index] = []
	unlocked_masteries[skill_index].append(mastery_id)

	_save_mastery_data()
	emit_signal("mastery_gained", skill_index, mastery_id)

	# Notificação
	var mastery_data = MASTERIES.get(skill_index, {}).get(mastery_id, {})
	var name = mastery_data.get("name", mastery_id)
	var desc = mastery_data.get("desc", "")

	HUD.show_notification("⭐ Maestria Nível %d!" % new_level, "%s: %s" % [name, desc], Color(1.0, 0.8, 0.2))

	if ParticleManager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ParticleManager.show_level_up(player.global_position, "Maestria %d!" % new_level)

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/mastery_levelup.ogg")

func _get_skill_name(index: int) -> String:
	return ["Agricultura", "Mineração", "Coleta", "Pesca", "Combate"][index]

func _get_skill_key(index: int) -> String:
	return ["farming", "mining", "foraging", "fishing", "combat"][index]

## ==================== EFEITOS DE MAESTRIA ====================
func has_mastery(skill_index: int, mastery_id: String) -> bool:
	return mastery_id in unlocked_masteries.get(skill_index, [])

func get_mastery_effect(skill_index: int, effect: String) -> Variant:
	if not has_mastery(skill_index, "%s_%d" % [_get_skill_key(skill_index), mastery_levels.get(skill_index, 0)]):
		return null

	var masteries = MASTERIES.get(skill_index, {})
	for m_id in unlocked_masteries.get(skill_index, []):
		var m = masteries.get(m_id, {})
		if m.effect == effect:
			return m.value
	return null

func get_total_effect(effect: String) -> Variant:
	var total = 0
	for skill in range(5):
		var val = get_mastery_effect(skill, effect)
		if val:
			if typeof(val) == TYPE_FLOAT or typeof(val) == TYPE_INT:
				total += val
			else:
				total = val  # Boolean-like
	return total

# Exemplos de uso:
# get_mastery_effect(0, "growth_speed") -> 0.10 (10% mais rápido)
# get_mastery_effect(3, "bigger_bar") -> 0.15 (barra 15% maior)
# get_mastery_effect(4, "damage_reduction") -> 0.15 (15% redução)

## ==================== UI ====================
func open_mastery_menu() -> void:
	if mastery_ui_scene:
		var ui = mastery_ui_scene.instantiate()
		ui.initialize(mastery_levels, mastery_xp, unlocked_masteries, MASTERIES)
		get_tree().root.get_child(0).add_child(ui)
	else:
		_show_generic_mastery_ui()

func _show_generic_mastery_ui() -> void:
	var panel = Panel.new()
	panel.name = "MasteryUI"
	panel.anchors_preset = 15
	panel.offset_left = 100
	panel.offset_top = 50
	panel.offset_right = -100
	panel.offset_bottom = -50

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "⭐ Maestria de Habilidades"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 28
	vbox.add_child(title)

	var skill_names = ["Agricultura", "Mineração", "Coleta", "Pesca", "Combate"]
	var skill_icons = ["🌱", "⛏️", "🌲", "🎣", "⚔️"]

	for i in range(5):
		var level = mastery_levels.get(i, 0)
		var xp = mastery_xp.get(i, 0)
		var required = MASTERY_XP_REQUIRED[level + 1] if level < 5 else 0

		var skill_panel = Panel.new()
		skill_panel.custom_minimum_size = Vector2(0, 100)

		var hbox = HBoxContainer.new()
		skill_panel.add_child(hbox)

		var icon = Label.new()
		icon.text = skill_icons[i]
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.custom_minimum_size = Vector2(60, 60)
		icon.theme_override_font_size = 32
		hbox.add_child(icon)

		var info = VBoxContainer.new()
		info.theme_override_constants/separation = 5
		hbox.add_child(info)

		var name = Label.new()
		name.text = "%s %s (Nível %d/5)" % [skill_icons[i], skill_names[i], level]
		name.theme_override_font_size = 18
		info.add_child(name)

		var xp_bar = ProgressBar.new()
		if level < 5:
			xp_bar.max_value = required
			xp_bar.value = mastery_xp.get(i, 0)
		else:
			xp_bar.max_value = 100
			xp_bar.value = 100
		xp_bar.custom_minimum_size = Vector2(300, 20)
		info.add_child(xp_bar)

		var xp_text = Label.new()
		if level < 5:
			xp_text.text = "XP: %d/%d" % [mastery_xp.get(i, 0), required]
		else:
			xp_text.text = "MÁXIMO"
		xp_text.theme_override_font_size = 12
		info.add_child(xp_text)

		# Maestrias desbloqueadas
		var masteries = unlocked_masteries.get(i, [])
		if masteries:
			var m_text = "Maestrias: " + ", ".join(masteries.map(func(m): return MASTERIES[i][m].name))
			var m_label = Label.new()
			m_label.text = m_text
			m_label.autowrap_mode = 1
			m_label.theme_override_font_size = 12
			m_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
			info.add_child(m_label)

		vbox.add_child(skill_panel)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

## ==================== PERSISTÊNCIA ====================
func _save_mastery_data() -> void:
	if GameManager:
		GameManager.set("mastery_levels", mastery_levels)
		GameManager.set("mastery_xp", mastery_xp)
		GameManager.set("unlocked_masteries", unlocked_masteries)

func get_save_data() -> Dictionary:
	return {
		"mastery_levels": mastery_levels,
		"mastery_xp": mastery_xp,
		"unlocked_masteries": unlocked_masteries
	}

func load_save_data(data: Dictionary) -> void:
	mastery_levels = data.get("mastery_levels", {})
	mastery_xp = data.get("mastery_xp", {})
	unlocked_masteries = data.get("unlocked_masteries", {})