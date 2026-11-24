class_name BuffManager
extends Node

## Gerencia buffs de comida, poções, efeitos temporários

## Buffs ativos
var active_buffs: Dictionary = {}  # {buff_id: BuffInstance}
var buff_sources: Dictionary = {}  # {buff_id: source_item_id}

## Dados de buffs do JSON (Cooking.json, Buffs.json)
const BUFF_DATA = {}  # Preenchido pelo DataLoader

## Categorias de buff (para stacking)
const BUFF_CATEGORIES = [
	"farming", "mining", "foraging", "fishing", "combat",
	"speed", "defense", "attack", "luck", "max_energy",
	"magnetism", "health_regen", "energy_regen"
]

## Buffs que não stackam (mesma categoria = substitui)
const NON_STACKING_CATEGORIES = [
	"farming", "mining", "foraging", "fishing", "combat",
	"speed", "defense", "attack", "luck"
]

## ==================== SINAIS ====================
signal buff_applied(buff_id: String, duration: float)
signal buff_refreshed(buff_id: String, new_duration: float)
signal buff_expired(buff_id: String)
signal buff_removed(buff_id: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	if GameManager:
		GameManager.minute_changed.connect(_on_minute_changed)
		GameManager.day_changed.connect(_on_day_changed)

	# Carrega dados de buffs
	_load_buff_data()

func _load_buff_data() -> void:
	# Carrega de Cooking.json e outros
	var cooking_data = DataLoader.get_all_recipes()
	for recipe_id, recipe in cooking_data:
		var buff = recipe.get("Buff", {})
		if buff:
			BUFF_DATA[recipe_id] = buff

	# Adiciona buffs de itens não-cozinha (café, poções, etc.)
	var items = DataLoader.get_all_items()
	for item_id, item in items:
		if item.get("Buff", {}):
			BUFF_DATA[item_id] = item.Buff

func _on_minute_changed() -> void:
	_update_buffs(1.0 / 60.0)  # 1 minuto in-game = 1/60 hora

func _on_day_changed() -> void:
	# Buffs não persistem entre dias (exceto alguns especiais)
	var to_remove = []
	for buff_id, instance in active_buffs:
		if not instance.persist_through_day:
			to_remove.append(buff_id)

	for bid in to_remove:
		_remove_buff(bid, true)

## ==================== APLICAR BUFF ====================
func apply_buff(source_item_id: String, duration_hours: float = -1) -> bool:
	var buff_def = BUFF_DATA.get(source_item_id)
	if not buff_def:
		return false

	var buff_id = _generate_buff_id(source_item_id)
	var category = buff_def.get("Category", "")

	# Verifica stacking
	if _is_non_stacking(category) and _has_active_buff_in_category(category):
		# Substitui buff existente na mesma categoria
		var existing = _get_active_buff_in_category(category)
		if existing:
			_remove_buff(existing, false)

	# Duração
	var dur = duration_hours
	if dur < 0:
		dur = buff_def.get("Duration", 1.0)  # Padrão 1 hora in-game

	# Cria instância
	var instance = BuffInstance.new()
	instance.initialize(buff_def, dur, source_item_id)
	active_buffs[buff_id] = instance
	buff_sources[buff_id] = source_item_id

	# Aplica efeitos imediatos
	_apply_buff_effects(instance, true)

	emit_signal("buff_applied", buff_id, dur)
	print("Buff aplicado: %s (%sh)" % [buff_id, dur])
	return true

func _generate_buff_id(source: String) -> String:
	return "%s_%d" % [source, Time.get_ticks_msec()]

func _is_non_stacking(category: String) -> bool:
	return category in NON_STACKING_CATEGORIES

func _has_active_buff_in_category(category: String) -> bool:
	for instance in active_buffs.values():
		if instance.category == category:
			return true
	return false

func _get_active_buff_in_category(category: String) -> String:
	for buff_id, instance in active_buffs:
		if instance.category == category:
			return buff_id
	return ""

## ==================== ATUALIZAÇÃO ====================
func _update_buffs(delta_hours: float) -> void:
	var to_remove = []

	for buff_id, instance in active_buffs:
		instance.remaining_time -= delta_hours

		# Efeitos periódicos (regen)
		if instance.has_periodic_effect:
			_apply_periodic_effects(instance, delta_hours)

		if instance.remaining_time <= 0:
			to_remove.append(buff_id)

	for bid in to_remove:
		_remove_buff(bid, true)

func _apply_periodic_effects(instance: BuffInstance, delta_hours: float) -> void:
	# Regen de vida/energia por minuto
	if instance.health_regen_per_min > 0:
		var amount = instance.health_regen_per_min * delta_hours * 60
		GameManager.heal(amount)

	if instance.energy_regen_per_min > 0:
		var amount = instance.energy_regen_per_min * delta_hours * 60
		GameManager.restore_energy(amount)

## ==================== EFEITOS ====================
func _apply_buff_effects(instance: BuffInstance, apply: bool) -> void:
	var mult = 1 if apply else -1

	# Modificadores de habilidade
	for skill in ["Farming", "Mining", "Foraging", "Fishing", "Combat"]:
		var key = skill.lower()
		if instance.skill_bonuses.has(key):
			GameManager.skill_buffs[key] = GameManager.skill_buffs.get(key, 0) + instance.skill_bonuses[key] * mult

	# Atributos de combate
	if instance.attack_bonus != 0:
		GameManager.attack_buff += instance.attack_bonus * mult
	if instance.defense_bonus != 0:
		GameManager.defense_buff += instance.defense_bonus * mult
	if instance.speed_bonus != 0:
		GameManager.speed_buff += instance.speed_bonus * mult
	if instance.max_energy_bonus != 0:
		GameManager.max_energy_buff += instance.max_energy_bonus * mult
	if instance.magnetism_bonus != 0:
		GameManager.magnetism_buff += instance.magnetism_bonus * mult
	if instance.luck_bonus != 0:
		GameManager.luck_buff += instance.luck_bonus * mult

	# Imunidades/resistências
	if instance.immunity_knockback:
		GameManager.knockback_immunity = apply
	if instance.immunity_debuff:
		GameManager.debuff_immunity = apply

	# Visuais
	if apply:
		_show_buff_particles(instance)
	else:
		_hide_buff_particles(instance)

func _show_buff_particles(instance: BuffInstance) -> void:
	# Partículas no jogador
	if instance.particle_effect:
		# TODO: Spawn particles on player
		pass

func _hide_buff_particles(instance: BuffInstance) -> void:
	pass

## ==================== REMOVER BUFF ====================
func remove_buff(buff_id: String) -> void:
	_remove_buff(buff_id, false)

func _remove_buff(buff_id: String, expired: bool) -> void:
	if not active_buffs.has(buff_id):
		return

	var instance = active_buffs[buff_id]
	_apply_buff_effects(instance, false)

	active_buffs.erase(buff_id)
	buff_sources.erase(buff_id)

	if expired:
		emit_signal("buff_expired", buff_id)
	else:
		emit_signal("buff_removed", buff_id)

func clear_all_buffs() -> void:
	var ids = active_buffs.keys()
	for bid in ids:
		_remove_buff(bid, false)

## ==================== CONSUMIR COMIDA ====================
func consume_food(item_id: String) -> Dictionary:
	var item = DataLoader.get_item(item_id)
	if not item:
		return {"success": false, "reason": "Item não encontrado"}

	if item.type != "Food" and item.type != "Drink":
		return {"success": false, "reason": "Não é comida/bebida"}

	# Verifica se pode comer (energia não cheia para comidas, etc.)
	var result = {"success": true, "energy_restored": 0, "health_restored": 0, "buff_applied": false}

	# Restaura energia/vida
	var energy = item.get("EnergyRestore", 0)
	var health = item.get("HealthRestore", 0)

	if energy > 0:
		var restored = GameManager.restore_energy(energy)
		result.energy_restored = restored

	if health > 0:
		var restored = GameManager.heal(health)
		result.health_restored = restored

	# Aplica buff se tiver
	var buff = item.get("Buff", {})
	if buff:
		if apply_buff(item_id):
			result.buff_applied = true
			result.buff_duration = buff.get("Duration", 1.0)

	# XP (algumas comidas dão XP)
	var xp = item.get("XP", {})
	for skill, amount in xp:
		GameManager.add_skill_xp(skill, amount)
		result.xp_gained = result.xp_gained or {}
		result.xp_gained[skill] = amount

	# Efeitos especiais
	_apply_special_food_effects(item_id, item)

	return result

func _apply_special_food_effects(item_id: String, item: ItemData) -> void:
	# Efeitos únicos de certos alimentos
	match item_id:
		"(O)265":  # Coffee - velocidade por 1m30s
			apply_buff(item_id, 1.5 / 60.0)  # 1.5 minutos = 0.025 horas
		"(O)267":  # Triple Shot Espresso
			apply_buff(item_id, 3.0 / 60.0)
		"(O)348":  # Ginger Ale - buff sorte
			apply_buff(item_id, 5.0 / 60.0)
		"(O)642":  # Magic Rock Candy - todos skills +3
			apply_buff(item_id, 10.0 / 60.0)
		_(O)789:  # Qi Seasoning - qualidade +1 próximo item
			GameManager.next_item_quality_boost = 1
		_(O)790:  # Hyper Speed-Gro - crescimento instantâneo
			GameManager.instant_grow_next = true
		_:
			pass

## ==================== QUERY ====================
func get_active_buffs() -> Array[Dictionary]:
	var result = []
	for buff_id, instance in active_buffs:
		result.append({
			"id": buff_id,
			"source": buff_sources.get(buff_id, ""),
			"category": instance.category,
			"name": instance.display_name,
			"description": instance.description,
			"remaining_time": instance.remaining_time,
			"icon": instance.icon
		})
	return result

func get_buff_time_remaining(buff_id: String) -> float:
	return active_buffs.get(buff_id)?.remaining_time ?? 0

func has_buff(category: String) -> bool:
	for instance in active_buffs.values():
		if instance.category == category:
			return true
	return false

func get_skill_buff(skill: String) -> int:
	return GameManager.skill_buffs.get(skill.to_lower(), 0)

## ==================== UI ====================
func open_buff_ui() -> void:
	var panel = Panel.new()
	panel.name = "BuffUI"
	panel.anchors_preset = 15
	panel.offset_left = 50
	panel.offset_top = 50
	panel.offset_right = -50
	panel.offset_bottom = -50

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Efeitos Ativos"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	if active_buffs.is_empty():
		var lbl = Label.new()
		lbl.text = "Nenhum efeito ativo"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(lbl)
	else:
		for buff_id, instance in active_buffs:
			var hbox = HBoxContainer.new()
			vbox.add_child(hbox)

			# Ícone
			var icon = TextureRect.new()
			icon.custom_minimum_size = Vector2(32, 32)
			hbox.add_child(icon)

			# Info
			var info = VBoxContainer.new()
			hbox.add_child(info)

			var name = Label.new()
			name.text = instance.display_name
			name.theme_override_font_size = 16
			info.add_child(name)

			var desc = Label.new()
			desc.text = instance.description
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.add_child(desc)

			# Barra de tempo
			var bar = ProgressBar.new()
			bar.min_value = 0
			bar.max_value = instance.max_duration
			bar.value = instance.remaining_time
			bar.custom_minimum_size = Vector2(200, 16)
			hbox.add_child(bar)

			var time_lbl = Label.new()
			time_lbl.text = _format_time(instance.remaining_time)
			hbox.add_child(time_lbl)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _format_time(hours: float) -> String:
	var total_minutes = hours * 60
	var h = int(total_minutes / 60)
	var m = int(total_minutes % 60)
	if h > 0:
		return "%dh %dm" % [h, m]
	return "%dm" % m

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	var buffs = {}
	for buff_id, instance in active_buffs:
		buffs[buff_id] = instance.get_save_data()
		buffs[buff_id].source = buff_sources.get(buff_id, "")

	return {
		"active_buffs": buffs
	}

func load_save_data(data: Dictionary) -> void:
	for buff_id, buff_data in data.get("active_buffs", {}):
		var source = buff_data.source
		var buff_def = BUFF_DATA.get(source)
		if buff_def:
			var instance = BuffInstance.new()
			instance.load_save_data(buff_data, buff_def)
			active_buffs[buff_id] = instance
			buff_sources[buff_id] = source
			_apply_buff_effects(instance, true)


class BuffInstance:
	var category: String = ""
	var display_name: String = ""
	var description: String = ""
	var icon: String = ""
	var max_duration: float = 0
	var remaining_time: float = 0
	var persist_through_day: bool = false
	var has_periodic_effect: bool = false

	# Bônus de habilidades
	var skill_bonuses: Dictionary = {}  # {skill: amount}

	# Combate
	var attack_bonus: int = 0
	var defense_bonus: int = 0
	var speed_bonus: int = 0
	var max_energy_bonus: int = 0
	var magnetism_bonus: int = 0
	var luck_bonus: float = 0

	# Regen
	var health_regen_per_min: float = 0
	var energy_regen_per_min: float = 0

	# Imunidades
	var immunity_knockback: bool = false
	var immunity_debuff: bool = false

	# Visual
	var particle_effect: String = ""

	func initialize(buff_def: Dictionary, duration: float, source: String) -> void:
		category = buff_def.get("Category", "")
		display_name = buff_def.get("DisplayName", source)
		description = buff_def.get("Description", "")
		icon = buff_def.get("Icon", "")
		max_duration = duration
		remaining_time = duration
		persist_through_day = buff_def.get("PersistThroughDay", false)

		# Skills
		skill_bonuses = buff_def.get("SkillBonuses", {})

		# Combate
		attack_bonus = buff_def.get("AttackBonus", 0)
		defense_bonus = buff_def.get("DefenseBonus", 0)
		speed_bonus = buff_def.get("SpeedBonus", 0)
		max_energy_bonus = buff_def.get("MaxEnergyBonus", 0)
		magnetism_bonus = buff_def.get("MagnetismBonus", 0)
		luck_bonus = buff_def.get("LuckBonus", 0.0)

		# Regen
		health_regen_per_min = buff_def.get("HealthRegenPerMin", 0)
		energy_regen_per_min = buff_def.get("EnergyRegenPerMin", 0)
		has_periodic_effect = health_regen_per_min > 0 or energy_regen_per_min > 0

		# Imunidades
		immunity_knockback = buff_def.get("ImmunityKnockback", false)
		immunity_debuff = buff_def.get("ImmunityDebuff", false)

		# Visual
		particle_effect = buff_def.get("ParticleEffect", "")

	func load_save_data(data: Dictionary, buff_def: Dictionary) -> void:
		initialize(buff_def, data.max_duration, data.source)
		remaining_time = data.remaining_time

	func get_save_data() -> Dictionary:
		return {
			"max_duration": max_duration,
			"remaining_time": remaining_time,
			"source": ""
		}