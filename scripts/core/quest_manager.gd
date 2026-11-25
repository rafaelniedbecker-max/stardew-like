extends Node

## Gerencia quests, missões especiais, checklists de progresso

@export var quest_ui_scene: PackedScene

## Estado
var active_quests: Dictionary = {}  # {quest_id: QuestInstance}
var completed_quests: Dictionary = {}  # {quest_id: true}
var available_quests: Array = []
var special_orders: Array = []  # Quadro de pedidos especiais (Qi's Walnut Room, etc.)

## Tipos de quest
const QUEST_TYPES = {
	"Story": "História Principal",
	"Skill": "Progresso de Habilidade",
	"Social": "Social / Amizade",
	"Monster": "Caça a Monstros",
	"Resource": "Coleta de Recursos",
	"Crafting": "Artesanato / Cozinha",
	"Fishing": "Pesca",
	"Secret": "Secreto / Oculto"
}

## Recompensas padrão
const DEFAULT_REWARDS = {
	"gold": 0,
	"xp": {},  # {skill: amount}
	"friendship": {},  # {npc: amount}
	"items": [],  # [{item_id, amount, quality}]
	"recipe": "",
	"unlock": ""
}

## ==================== SINAIS ====================
signal quest_added(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String, rewards: Dictionary)
signal quest_failed(quest_id: String)
signal special_order_added(order_id: String)
signal special_order_completed(order_id: String, rewards: Dictionary)
signal daily_quests_refreshed()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Carrega dados de quests
	_load_quest_data()

	# Conecta sinais do GameManager
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)
		GameManager.item_obtained.connect(_on_item_obtained)
		GameManager.monster_killed.connect(_on_monster_killed)
		GameManager.fish_caught.connect(_on_fish_caught)
		GameManager.crop_harvested.connect(_on_crop_harvested)
		GameManager.recipe_learned.connect(_on_recipe_learned)
		GameManager.friendship_changed.connect(_on_friendship_changed)
		GameManager.skill_level_up.connect(_on_skill_level_up)
		GameManager.crafting_done.connect(_on_crafting_done)
		GameManager.building_built.connect(_on_building_built)

func _load_quest_data() -> void:
	# Carrega do DataLoader (Quests.json, SpecialOrders.json)
	available_quests = DataLoader.get_all_quests()
	special_orders = DataLoader.get_special_orders()

	# Adiciona quests iniciais
	_add_starter_quests()

func _add_starter_quests() -> void:
	# Quests que aparecem automaticamente
	var starter_quests = [
		"intro_farming",
		"intro_mining",
		"intro_fishing",
		"intro_foraging",
		"intro_social",
		"intro_crafting"
	]

	for qid in starter_quests:
		if DataLoader.get_quest(qid) and not completed_quests.has(qid):
			add_quest(qid)

## ==================== GERENCIAMENTO DE QUESTS ====================
func add_quest(quest_id: String) -> bool:
	if active_quests.has(quest_id) or completed_quests.has(quest_id):
		return false

	var quest_data = DataLoader.get_quest(quest_id)
	if not quest_data:
		print("Quest não encontrada: %s" % quest_id)
		return false

	var instance = QuestInstance.new()
	instance.initialize(quest_data)
	active_quests[quest_id] = instance

	instance.objective_updated.connect(_on_objective_updated.bind(quest_id))
	instance.quest_completed.connect(_on_quest_completed.bind(quest_id))

	emit_signal("quest_added", quest_id)
	print("Quest adicionada: %s" % quest_data.title)
	return true

func remove_quest(quest_id: String) -> void:
	if active_quests.has(quest_id):
		active_quests[quest_id].cleanup()
		active_quests.erase(quest_id)

func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return

	var instance = active_quests[quest_id]
	var rewards = instance.get_rewards()

	# Aplica recompensas
	_apply_rewards(rewards)

	completed_quests[quest_id] = true
	active_quests.erase(quest_id)

	# Salva progresso
	if GameManager:
		var completed = GameManager.get_data("completed_quests", [])
		if quest_id not in completed:
			completed.append(quest_id)
		GameManager.set_data("completed_quests", completed)

	# Verifica quests em cadeia
	_check_chain_quests(quest_id)

	emit_signal("quest_completed", quest_id, rewards)
	print("Quest completada: %s" % quest_id)

func fail_quest(quest_id: String) -> void:
	if active_quests.has(quest_id):
		active_quests[quest_id].cleanup()
		active_quests.erase(quest_id)
		emit_signal("quest_failed", quest_id)

func _on_objective_updated(quest_id: String, objective_index: int, current: int, required: int) -> void:
	emit_signal("quest_updated", quest_id)

func _on_quest_completed(quest_id: String) -> void:
	complete_quest(quest_id)

func _check_chain_quests(completed_id: String) -> void:
	# Verifica se completa quest libera próxima na cadeia
	for qid in available_quests:
		var qdata = DataLoader.get_quest(qid)
		if qdata and qdata.get("PrerequisiteQuest", "") == completed_id:
			if not active_quests.has(qid) and not completed_quests.has(qid):
				add_quest(qid)

func _apply_rewards(rewards: Dictionary) -> void:
	if not GameManager:
		return

	# Ouro
	if rewards.has("gold"):
		GameManager.gold += rewards.gold

	# XP
	for skill in rewards.get("xp", {}):
		GameManager.add_skill_xp(skill, rewards.xp[skill])

	# Amizade
	for npc in rewards.get("friendship", {}):
		GameManager.add_friendship(npc, rewards.friendship[npc])

	# Itens
	for item_data in rewards.get("items", []):
		InventoryManager.add_item(item_data.item_id, item_data.amount, item_data.quality)

	# Receita
	if rewards.get("recipe", "") != "":
		GameManager.learn_recipe(rewards.recipe)

	# Desbloqueio
	if rewards.get("unlock", "") != "":
		GameManager.unlock_feature(rewards.unlock)

## ==================== VERIFICAÇÃO DE OBJETIVOS ====================
func _on_day_changed() -> void:
	# Quests diárias expiram
	_expire_daily_quests()

	# Atualiza special orders
	_refresh_special_orders()

	# Atualiza objetivos baseados em tempo
	for instance in active_quests.values():
		instance.on_day_passed()

func _expire_daily_quests() -> void:
	var to_remove = []
	for qid in active_quests:
		var instance = active_quests[qid]
		if instance.is_daily and instance.start_day != GameManager.current_day:
			instance.cleanup()
			to_remove.append(qid)

	for qid in to_remove:
		active_quests.erase(qid)

func _refresh_special_orders() -> void:
	# Special orders do quadro (Qi, Wizard, etc.)
	# Refresh a cada semana ou evento
	if GameManager.current_day % 7 == 1:  # Toda segunda
		_generate_weekly_special_orders()

func _generate_weekly_special_orders() -> void:
	# Gera pedidos especiais semanais baseados em progresso
	var player_level = GameManager.get_total_skill_level()

	# Pool de special orders disponíveis
	var pool = [
		{"id": "qi_gem", "req": 5, "reward": {"gold": 5000, "items": [{"item_id": "(O)749", "amount": 5}]}},  # Prismatic Shard
		{"id": "qi_monster", "req": 10, "reward": {"gold": 10000, "xp": {"Combat": 500}}},
		{"id": "wizard_essence", "req": 15, "reward": {"gold": 2500, "items": [{"item_id": "(O)768", "amount": 1}]}},  # Golden Pumpkin
		{"id": "krobus_void", "req": 8, "reward": {"gold": 3000, "friendship": {"Krobus": 250}}},
	]

	for order in pool:
		if player_level >= order.req and randf() < 0.3:
			_add_special_order(order)

func _add_special_order(order: Dictionary) -> void:
	var order_id = "%s_%d" % [order.id, GameManager.current_day]
	if order_id not in special_orders:
		special_orders.append(order_id)
		emit_signal("special_order_added", order_id)

func _on_item_obtained(item_id: String, amount: int, quality: int) -> void:
	_update_quest_objectives("collect_item", item_id, amount)
	var item_data = DataLoader.get_item(item_id)
	_update_quest_objectives("collect_category", item_data.category if item_data != null else "", amount)

func _on_monster_killed(monster_type: String, level: int) -> void:
	_update_quest_objectives("kill_monster", monster_type, 1)
	_update_quest_objectives("kill_monsters_total", "", 1)

func _on_fish_caught(fish_id: String, size: float, quality: int, location: String) -> void:
	_update_quest_objectives("catch_fish", fish_id, 1)
	_update_quest_objectives("catch_fish_location", location, 1)
	_update_quest_objectives("catch_fish_quality", str(quality), 1)

func _on_crop_harvested(crop_id: String, amount: int, quality: int) -> void:
	_update_quest_objectives("harvest_crop", crop_id, amount)
	var crop_data = DataLoader.get_crop(crop_id)
	_update_quest_objectives("harvest_category", crop_data.category if crop_data != null else "", amount)

func _on_recipe_learned(recipe_id: String) -> void:
	_update_quest_objectives("learn_recipe", recipe_id, 1)
	_update_quest_objectives("learn_recipes_total", "", 1)

func _on_friendship_changed(npc: String, new_value: int) -> void:
	_update_quest_objectives("reach_heart", npc, new_value)
	_update_quest_objectives("max_hearts_total", "", _count_max_hearts())

func _on_skill_level_up(skill: String, level: int) -> void:
	_update_quest_objectives("reach_skill_level", skill, level)
	_update_quest_objectives("max_skill_level", "", GameManager.get_max_skill_level())

func _on_crafting_done(recipe_id: String, amount: int) -> void:
	_update_quest_objectives("craft_recipe", recipe_id, amount)
	var recipe_data = DataLoader.get_recipe(recipe_id)
	_update_quest_objectives("craft_category", recipe_data.category if recipe_data != null else "", amount)

func _on_building_built(building_type: String, pos: Vector2i) -> void:
	_update_quest_objectives("build_building", building_type, 1)

func _update_quest_objectives(objective_type: String, target: String, amount: int) -> void:
	for qid in active_quests:
		var instance = active_quests[qid]
		instance.update_objective(objective_type, target, amount)

func _count_max_hearts() -> int:
	var count = 0
	for npc_id in GameManager.friendships:
		var friendship = GameManager.friendships[npc_id]
		if friendship >= 1000:
			count += 1
	return count

## ==================== QUESTS ESPECIAIS (STORY) ====================
func check_story_triggers() -> void:
	# Verifica gatilhos de história baseados em progresso
	var total_friendship = 0
	for f in GameManager.friendships.values():
		total_friendship += f

	# Community Center bundles
	if GameManager.get_data("cc_boiler_repaired", false) and not completed_quests.has("cc_boiler"):
		add_quest("cc_boiler")

	if GameManager.get_data("cc_crafts_room_repaired", false) and not completed_quests.has("cc_crafts"):
		add_quest("cc_crafts")

	# ... outros bundles

	# Joja Mart
	if GameManager.get_data("joja_member", false) and not completed_quests.has("joja_route"):
		add_quest("joja_route")

	# Grandpa's Evaluation (Ano 3, Spring 1)
	if GameManager.current_year >= 3 and GameManager.current_season == 0 and GameManager.current_day == 1:
		if not completed_quests.has("grandpa_evaluation"):
			add_quest("grandpa_evaluation")

## ==================== UI ====================
func open_quest_log() -> void:
	if quest_ui_scene:
		var ui = quest_ui_scene.instantiate()
		ui.initialize(active_quests, completed_quests)
		get_tree().root.get_child(0).add_child(ui)
	else:
		_show_generic_quest_log()

func _show_generic_quest_log() -> void:
	var panel = Panel.new()
	panel.name = "QuestLog"
	panel.anchors_preset = 15
	panel.offset_left = 100
	panel.offset_top = 50
	panel.offset_right = -100
	panel.offset_bottom = -50

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Diário de Missões"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 28
	vbox.add_child(title)

	# Tabs: Ativas, Completadas
	var tabs = TabContainer.new()
	vbox.add_child(tabs)

	# Ativas
	var active_box = VBoxContainer.new()
	tabs.add_child(active_box)
	tabs.set_tab_title(tabs.get_child_count() - 1, "Ativas")

	for qid in active_quests:
		var instance = active_quests[qid]
		var quest_item = _create_quest_item(instance)
		active_box.add_child(quest_item)

	if active_quests.is_empty():
		var lbl = Label.new()
		lbl.text = "Nenhuma missão ativa"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		active_box.add_child(lbl)

	# Completadas
	var completed_box = VBoxContainer.new()
	tabs.add_child(completed_box)
	tabs.set_tab_title(tabs.get_child_count() - 1, "Completadas (%d)" % completed_quests.size())

	for qid in completed_quests:
		var qdata = DataLoader.get_quest(qid)
		if qdata:
			var lbl = Label.new()
			lbl.text = "✓ %s" % qdata.title
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			completed_box.add_child(lbl)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _create_quest_item(instance: QuestInstance) -> Control:
	var hbox = HBoxContainer.new()

	var info = VBoxContainer.new()
	hbox.add_child(info)

	var name = Label.new()
	name.text = instance.quest_data.title
	name.theme_override_font_size = 18
	info.add_child(name)

	var type_lbl = Label.new()
	type_lbl.text = "[%s] %s" % [QUEST_TYPES.get(instance.quest_data.quest_type, "Outro"), instance.quest_data.description]
	type_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(type_lbl)

	# Progresso objetivos
	for i in range(instance.objectives.size()):
		var obj = instance.objectives[i]
		var prog = HBoxContainer.new()
		var obj_lbl = Label.new()
		obj_lbl.text = "%s: %d/%d" % [obj.description, obj.current, obj.required]
		prog.add_child(obj_lbl)

		var bar = ProgressBar.new()
		bar.min_value = 0
		bar.max_value = obj.required
		bar.value = obj.current
		bar.custom_minimum_size = Vector2(150, 16)
		prog.add_child(bar)

		info.add_child(prog)

	return hbox

func get_active_quests() -> Array[Dictionary]:
	var result = []
	for qid in active_quests:
		var instance = active_quests[qid]
		var data = {
			"id": qid,
			"title": instance.quest_data.title,
			"description": instance.quest_data.description,
			"type": instance.quest_data.quest_type,
			"objectives": instance.objectives,
			"progress": 0,
			"target": 1
		}
		# Calcula progresso total
		var total_current = 0
		var total_required = 0
		for obj in instance.objectives:
			total_current += obj.current
			total_required += obj.required
		if total_required > 0:
			data.progress = total_current
			data.target = total_required
		result.append(data)
	return result

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	var active = {}
	for qid in active_quests:
		var instance = active_quests[qid]
		active[qid] = instance.get_save_data()

	return {
		"active_quests": active,
		"completed_quests": completed_quests.keys(),
		"special_orders": special_orders
	}

func load_save_data(data: Dictionary) -> void:
	completed_quests = {}
	for qid in data.get("completed_quests", []):
		completed_quests[qid] = true

	special_orders = data.get("special_orders", [])

	for qid in data.get("active_quests", {}):
		var qdata = data.get("active_quests", {})[qid]
		if quest_def:
			var instance = QuestInstance.new()
			instance.initialize(quest_def)
			instance.load_save_data(qdata)
			active_quests[qid] = instance

			instance.objective_updated.connect(_on_objective_updated.bind(qid))
			instance.quest_completed.connect(_on_quest_completed.bind(qid))


class QuestInstance:
	var quest_data: Dictionary
	var objectives: Array[Dictionary] = []  # {description, type, target, current, required}
	var start_day: int = 0
	var is_daily: bool = false

	signal objective_updated(quest_id: String, objective_index: int, current: int, required: int)
	signal quest_completed(quest_id: String)

	func initialize(data: Dictionary) -> void:
		quest_data = data
		start_day = GameManager.current_day if GameManager else 1
		is_daily = data.get("IsDaily", false)

		# Parse objetivos
		var raw_objectives = data.get("Objectives", [])
		for obj in raw_objectives:
			objectives.append({
				"description": obj.get("Description", ""),
				"type": obj.get("Type", ""),
				"target": obj.get("Target", ""),
				"current": 0,
				"required": obj.get("Count", 1)
			})

	func update_objective(obj_type: String, target: String, amount: int) -> void:
		for i in range(objectives.size()):
			var obj = objectives[i]
			if obj.type == obj_type:
				var matches_target = false
				if obj.target == "" or obj.target == target:
					matches_target = true
				elif obj_type == "collect_category":
					var item_data = DataLoader.get_item(target)
					if item_data != null and str(item_data.category) == obj.target:
						matches_target = true
				elif obj_type == "harvest_category":
					var crop_data = DataLoader.get_crop(target)
					if crop_data != null and crop_data.internal_name == obj.target:
						matches_target = true

				if matches_target:
					obj.current = min(obj.current + amount, obj.required)
					emit_signal("objective_updated", quest_data.id, i, obj.current, obj.required)

		_check_completion()

	func _check_completion() -> void:
		for obj in objectives:
			if obj.current < obj.required:
				return
		emit_signal("quest_completed", quest_data.id)

	func on_day_passed() -> void:
		# Para quests diárias, reseta ou expira
		if is_daily:
			for obj in objectives:
				obj.current = 0

	func get_rewards() -> Dictionary:
		return quest_data.get("Rewards", DEFAULT_REWARDS)

	func get_save_data() -> Dictionary:
		var obj_data = []
		for obj in objectives:
			obj_data.append({
				"type": obj.type,
				"target": obj.target,
				"current": obj.current,
				"required": obj.required
			})
		return {
			"objectives": obj_data,
			"start_day": start_day
		}

	func load_save_data(data: Dictionary) -> void:
		start_day = data.get("start_day", 1)
		var saved_objectives: Array = data.get("objectives", [])
		for i in range(saved_objectives.size()):
			var saved_obj: Dictionary = saved_objectives[i]
			if i < objectives.size():
				objectives[i].current = saved_obj.get("current", 0)

	func cleanup() -> void:
		# Limpa conexões
		pass