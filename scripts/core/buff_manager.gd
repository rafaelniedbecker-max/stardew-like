extends Node

## Gerencia buffs de comida, poções e efeitos temporários.

var active_buffs: Dictionary = {}  # {buff_id: BuffInstance}
var buff_sources: Dictionary = {}  # {buff_id: source_item_id}
var BUFF_DATA: Dictionary = {}  # {source_item_id: buff_definition}

const NON_STACKING_CATEGORIES = [
	"farming", "mining", "foraging", "fishing", "combat",
	"speed", "defense", "attack", "luck"
]

signal buff_applied(buff_id: String, duration: float)
signal buff_refreshed(buff_id: String, new_duration: float)
signal buff_expired(buff_id: String)
signal buff_removed(buff_id: String)

func _ready() -> void:
	if GameManager:
		GameManager.minute_changed.connect(_on_minute_changed)
		GameManager.day_changed.connect(_on_day_changed)
	_load_buff_data()

func _load_buff_data() -> void:
	BUFF_DATA.clear()
	for item in DataLoader.get_all_items():
		if item == null or not item.has_buff():
			continue

		# ItemData referencia a definição pelo buff_id. O fallback mantém o
		# consumo funcional mesmo quando Buffs.json não está disponível.
		var buff_def: Dictionary = DataLoader.get_buff(item.buff_id).duplicate(true)
		if buff_def.is_empty():
			buff_def = {"Category": item.buff_id.to_lower()}

		buff_def["DisplayName"] = buff_def.get("DisplayName", item.get_display_name())
		buff_def["Description"] = buff_def.get("Description", item.description)
		if item.buff_duration > 0:
			buff_def["Duration"] = item.buff_duration / 60.0

		var definition: Dictionary = buff_def
		BUFF_DATA[str(item.id)] = definition
		BUFF_DATA["(O)%d" % item.id] = definition

func _on_minute_changed(_new_minute: int) -> void:
	_update_buffs(1.0 / 60.0)

func _on_day_changed(_day: int, _season: int, _year: int) -> void:
	var to_remove: Array = []
	for buff_id in active_buffs:
		var instance: BuffInstance = active_buffs[buff_id]
		if not instance.persist_through_day:
			to_remove.append(buff_id)
	for buff_id in to_remove:
		_remove_buff(buff_id, true)

## ==================== APLICAR E REMOVER ====================

func apply_buff(source_item_id: String, duration_hours: float = -1.0) -> bool:
	var buff_def: Dictionary = BUFF_DATA.get(source_item_id, {})
	if buff_def.is_empty():
		return false

	var category: String = buff_def.get("Category", "")
	if _is_non_stacking(category) and _has_active_buff_in_category(category):
		var existing: String = _get_active_buff_in_category(category)
		if existing != "":
			_remove_buff(existing, false)

	var duration: float = duration_hours
	if duration < 0.0:
		duration = buff_def.get("Duration", 1.0)

	var buff_id: String = _generate_buff_id(source_item_id)
	var instance := BuffInstance.new()
	instance.initialize(buff_def, duration, source_item_id)
	active_buffs[buff_id] = instance
	buff_sources[buff_id] = source_item_id
	_apply_buff_effects(instance, true)
	emit_signal("buff_applied", buff_id, duration)
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
	for buff_id in active_buffs:
		var instance: BuffInstance = active_buffs[buff_id]
		if instance.category == category:
			return buff_id
	return ""

func _update_buffs(delta_hours: float) -> void:
	var to_remove: Array = []
	for buff_id in active_buffs:
		var instance: BuffInstance = active_buffs[buff_id]
		instance.remaining_time -= delta_hours
		if instance.has_periodic_effect:
			_apply_periodic_effects(instance, delta_hours)
		if instance.remaining_time <= 0.0:
			to_remove.append(buff_id)
	for buff_id in to_remove:
		_remove_buff(buff_id, true)

func _apply_periodic_effects(instance: BuffInstance, delta_hours: float) -> void:
	if instance.health_regen_per_min > 0.0:
		GameManager.heal(instance.health_regen_per_min * delta_hours * 60.0)
	if instance.energy_regen_per_min > 0.0:
		GameManager.restore_energy(instance.energy_regen_per_min * delta_hours * 60.0)

func _apply_buff_effects(instance: BuffInstance, apply: bool) -> void:
	var mult: int = 1 if apply else -1
	for skill in ["Farming", "Mining", "Foraging", "Fishing", "Combat"]:
		var key: String = skill.to_lower()
		if instance.skill_bonuses.has(key):
			GameManager.skill_buffs[key] = GameManager.skill_buffs.get(key, 0) + instance.skill_bonuses[key] * mult

	GameManager.attack_buff += instance.attack_bonus * mult
	GameManager.defense_buff += instance.defense_bonus * mult
	GameManager.speed_buff += instance.speed_bonus * mult
	GameManager.max_energy_buff += instance.max_energy_bonus * mult
	GameManager.magnetism_buff += instance.magnetism_bonus * mult
	GameManager.luck_buff += instance.luck_bonus * mult

	if instance.immunity_knockback:
		GameManager.knockback_immunity = apply
	if instance.immunity_debuff:
		GameManager.debuff_immunity = apply

func remove_buff(buff_id: String) -> void:
	_remove_buff(buff_id, false)

func _remove_buff(buff_id: String, expired: bool) -> void:
	if not active_buffs.has(buff_id):
		return
	var instance: BuffInstance = active_buffs[buff_id]
	_apply_buff_effects(instance, false)
	active_buffs.erase(buff_id)
	buff_sources.erase(buff_id)
	if expired:
		emit_signal("buff_expired", buff_id)
	else:
		emit_signal("buff_removed", buff_id)

func clear_all_buffs() -> void:
	for buff_id in active_buffs.keys():
		_remove_buff(buff_id, false)

## ==================== CONSUMIR COMIDA ====================

func consume_food(item_id: String) -> Dictionary:
	var item: ItemData = DataLoader.get_item(item_id)
	if item == null:
		return {"success": false, "reason": "Item não encontrado"}
	if not item.is_edible() and item.item_type not in ["Food", "Drink"]:
		return {"success": false, "reason": "Não é comida/bebida"}

	var result: Dictionary = {
		"success": true,
		"energy_restored": 0.0,
		"health_restored": 0.0,
		"buff_applied": false
	}

	var energy: float = max(0.0, float(item.edibility))
	var health: float = max(0.0, floor(float(item.edibility) / 2.0))
	var old_energy: float = GameManager.energy
	var old_health: float = GameManager.health
	GameManager.restore_energy(energy)
	GameManager.heal(health)
	result.energy_restored = GameManager.energy - old_energy
	result.health_restored = GameManager.health - old_health

	if item.has_buff() and apply_buff(item_id):
		result.buff_applied = true
		result.buff_duration = BUFF_DATA[item_id].get("Duration", 1.0)

	_apply_special_food_effects(item_id)
	return result

func _apply_special_food_effects(item_id: String) -> void:
	match item_id:
		"(O)265":
			apply_buff(item_id, 1.5 / 60.0)
		"(O)267":
			apply_buff(item_id, 3.0 / 60.0)
		"(O)348":
			apply_buff(item_id, 5.0 / 60.0)
		"(O)642":
			apply_buff(item_id, 10.0 / 60.0)
		"(O)789":
			GameManager.set_data("next_item_quality_boost", 1)
		"(O)790":
			GameManager.set_data("instant_grow_next", true)

## ==================== CONSULTAS ====================

func get_active_buffs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for buff_id in active_buffs:
		var instance: BuffInstance = active_buffs[buff_id]
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
	var instance: BuffInstance = active_buffs.get(buff_id)
	return instance.remaining_time if instance != null else 0.0

func has_buff(category: String) -> bool:
	return _has_active_buff_in_category(category)

func get_skill_buff(skill: String) -> int:
	return GameManager.skill_buffs.get(skill.to_lower(), 0)

## ==================== UI ====================

func open_buff_ui() -> void:
	var panel := Panel.new()
	panel.name = "BuffUI"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 360)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Efeitos Ativos"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	if active_buffs.is_empty():
		var label := Label.new()
		label.text = "Nenhum efeito ativo"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
	else:
		for buff_id in active_buffs:
			var instance: BuffInstance = active_buffs[buff_id]
			var row := HBoxContainer.new()
			vbox.add_child(row)

			var info := VBoxContainer.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)

			var name_label := Label.new()
			name_label.text = instance.display_name
			info.add_child(name_label)

			var description := Label.new()
			description.text = instance.description
			description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.add_child(description)

			var bar := ProgressBar.new()
			bar.min_value = 0.0
			bar.max_value = instance.max_duration
			bar.value = instance.remaining_time
			bar.custom_minimum_size = Vector2(200, 16)
			row.add_child(bar)

			var time_label := Label.new()
			time_label.text = _format_time(instance.remaining_time)
			row.add_child(time_label)

	var close_button := Button.new()
	close_button.text = "Fechar"
	close_button.pressed.connect(panel.queue_free)
	vbox.add_child(close_button)
	get_tree().root.get_child(0).add_child(panel)

func _format_time(hours: float) -> String:
	var total_minutes: int = int(hours * 60.0)
	var h: int = total_minutes / 60
	var m: int = total_minutes % 60
	return "%dh %dm" % [h, m] if h > 0 else "%dm" % m

## ==================== SERIALIZAÇÃO ====================

func get_save_data() -> Dictionary:
	var buffs: Dictionary = {}
	for buff_id in active_buffs:
		var instance: BuffInstance = active_buffs[buff_id]
		buffs[buff_id] = instance.get_save_data()
		buffs[buff_id].source = buff_sources.get(buff_id, "")
	return {"active_buffs": buffs}

func load_save_data(data: Dictionary) -> void:
	clear_all_buffs()
	var saved_buffs: Dictionary = data.get("active_buffs", {})
	for buff_id in saved_buffs:
		var buff_data: Dictionary = saved_buffs[buff_id]
		var source: String = buff_data.get("source", "")
		var buff_def: Dictionary = BUFF_DATA.get(source, {})
		if buff_def.is_empty():
			continue
		var instance := BuffInstance.new()
		instance.load_save_data(buff_data, buff_def)
		active_buffs[buff_id] = instance
		buff_sources[buff_id] = source
		_apply_buff_effects(instance, true)

class BuffInstance:
	var category: String = ""
	var display_name: String = ""
	var description: String = ""
	var icon: String = ""
	var max_duration: float = 0.0
	var remaining_time: float = 0.0
	var persist_through_day: bool = false
	var has_periodic_effect: bool = false
	var skill_bonuses: Dictionary = {}
	var attack_bonus: int = 0
	var defense_bonus: int = 0
	var speed_bonus: int = 0
	var max_energy_bonus: int = 0
	var magnetism_bonus: int = 0
	var luck_bonus: float = 0.0
	var health_regen_per_min: float = 0.0
	var energy_regen_per_min: float = 0.0
	var immunity_knockback: bool = false
	var immunity_debuff: bool = false
	var particle_effect: String = ""

	func initialize(buff_def: Dictionary, duration: float, source: String) -> void:
		category = buff_def.get("Category", "")
		display_name = buff_def.get("DisplayName", source)
		description = buff_def.get("Description", "")
		icon = buff_def.get("Icon", "")
		max_duration = duration
		remaining_time = duration
		persist_through_day = buff_def.get("PersistThroughDay", false)
		skill_bonuses = buff_def.get("SkillBonuses", {})
		attack_bonus = buff_def.get("AttackBonus", 0)
		defense_bonus = buff_def.get("DefenseBonus", 0)
		speed_bonus = buff_def.get("SpeedBonus", 0)
		max_energy_bonus = buff_def.get("MaxEnergyBonus", 0)
		magnetism_bonus = buff_def.get("MagnetismBonus", 0)
		luck_bonus = buff_def.get("LuckBonus", 0.0)
		health_regen_per_min = buff_def.get("HealthRegenPerMin", 0.0)
		energy_regen_per_min = buff_def.get("EnergyRegenPerMin", 0.0)
		has_periodic_effect = health_regen_per_min > 0.0 or energy_regen_per_min > 0.0
		immunity_knockback = buff_def.get("ImmunityKnockback", false)
		immunity_debuff = buff_def.get("ImmunityDebuff", false)
		particle_effect = buff_def.get("ParticleEffect", "")

	func load_save_data(data: Dictionary, buff_def: Dictionary) -> void:
		initialize(buff_def, data.get("max_duration", 0.0), data.get("source", ""))
		remaining_time = data.get("remaining_time", 0.0)

	func get_save_data() -> Dictionary:
		return {
			"max_duration": max_duration,
			"remaining_time": remaining_time,
			"source": ""
		}
