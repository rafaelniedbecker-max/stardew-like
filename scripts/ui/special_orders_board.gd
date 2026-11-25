extends Control

## Quadro de Pedidos Especiais (Qi's Walnut Room, Wizard, etc.)

@onready var orders_list: ItemList = $Panel/OrdersList
@onready var order_info: VBoxContainer = $Panel/OrderInfo
@onready var info_title: Label = $Panel/OrderInfo/TitleLabel
@onready var info_desc: Label = $Panel/OrderInfo/DescLabel
@onready var info_rewards: Label = $Panel/OrderInfo/RewardsLabel
@onready var info_time: Label = $Panel/OrderInfo/TimeLabel
@onready var accept_button: Button = $Panel/OrderInfo/AcceptButton
@onready var abandon_button: Button = $Panel/OrderInfo/AbandonButton
@onready var gold_label: Label = $Panel/TopBar/GoldLabel
@onready var qi_gems_label: Label = $Panel/TopBar/QIGemsLabel
@onready var close_button: Button = $Panel/CloseButton
@onready var tabs: TabContainer = $Panel/TabBar

## Estado
var available_orders: Array = []  # Pedidos disponíveis no quadro
var active_orders: Dictionary = {}  # {order_id: OrderInstance}
var completed_orders: Dictionary = {}  # {order_id: true}
var selected_order_id: String = ""
var board_type: String = "qi"  # "qi", "wizard", "krobus", "gilbert"

## Tipos de quadro
const BOARD_TYPES = {
	"qi": {"name": "Qi's Special Orders", "currency": "Qi Gems", "icon": "(O)749"},
	"wizard": {"name": "Wizard's Requests", "currency": "Gold", "icon": "(O)768"},
	"krobus": {"name": "Krobus's Favors", "currency": "Void Essence", "icon": "(O)769"},
	"gilbert": {"name": "Island Trader", "currency": "Cinder Shards", "icon": "(O)892"}
}

## ==================== SINAIS ====================
signal order_accepted(order_id: String)
signal order_completed(order_id: String, rewards: Dictionary)
signal order_abandoned(order_id: String)
signal board_closed()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# If loaded as autoload without scene, UI nodes will be null
	if not close_button or not orders_list or not accept_button or not abandon_button or not tabs:
		# Running as manager only, skip UI setup
		_load_orders()
		return

	visible = false
	close_button.pressed.connect(hide)
	orders_list.item_selected.connect(_on_order_selected)
	accept_button.pressed.connect(_on_accept_pressed)
	abandon_button.pressed.connect(_on_abandon_pressed)
	tabs.tab_changed.connect(_on_tab_changed)

	# Carrega pedidos do DataLoader
	_load_orders()

func _load_orders() -> void:
	# Carrega de SpecialOrders.json
	var all_orders = DataLoader.get_special_orders()
	# Filtra por tipo de quadro
	available_orders = []
	for order in all_orders:
		if order.get("BoardType", "qi") == board_type:
			available_orders.append(order)

	_populate_list()

func _populate_list() -> void:
	orders_list.clear()

	for order in available_orders:
		var oid = order.id
		var is_active = active_orders.has(oid)
		var is_done = completed_orders.has(oid)

		var status = ""
		if is_done:
			status = " ✓"
		elif is_active:
			status = " 📋"

		var text = "%s%s" % [order.title, status]
		orders_list.add_item(text)
		orders_list.set_item_metadata(orders_list.get_item_count() - 1, oid)

		if is_done:
			orders_list.set_item_custom_bg_color(orders_list.get_item_count() - 1, Color(0.2, 0.5, 0.2))
		elif is_active:
			orders_list.set_item_custom_bg_color(orders_list.get_item_count() - 1, Color(0.3, 0.3, 0.5))

func _on_tab_changed(tab_idx: int) -> void:
	var types = ["qi", "wizard", "krobus", "gilbert"]
	if tab_idx < types.size():
		board_type = types[tab_idx]
		_load_orders()
		_clear_info()

## ==================== ABRIR QUADRO ====================
func open_board(type: String = "qi") -> void:
	# If UI nodes don't exist, instantiate the scene
	if not close_button or not orders_list:
		var scene = load("res://scenes/ui/special_orders_board.tscn")
		if scene:
			var instance = scene.instantiate()
			get_tree().root.get_child(0).add_child(instance)
			instance.open_board(type)
		return

	board_type = type
	visible = true
	_update_currency()
	_load_orders()
	_clear_info()
	grab_focus()

func _update_currency() -> void:
	var board = BOARD_TYPES[board_type]
	gold_label.text = "%dg" % GameManager.gold

	# Moeda especial
	var currency_amount = 0
	match board_type:
		"qi":
			currency_amount = GameManager.get_data("qi_gems", 0)
			qi_gems_label.text = "%s %d" % [board.icon, currency_amount]
		"wizard":
			currency_amount = GameManager.get_data("wizard_reputation", 0)
			qi_gems_label.text = "Rep: %d" % currency_amount
		"krobus":
			currency_amount = InventoryManager.get_item_count("(O)769")
			qi_gems_label.text = "%s %d" % [board.icon, currency_amount]
		"gilbert":
			currency_amount = InventoryManager.get_item_count("(O)892")
			qi_gems_label.text = "%s %d" % [board.icon, currency_amount]

## ==================== SELEÇÃO ====================
func _on_order_selected(index: int) -> void:
	var oid = orders_list.get_item_metadata(index)
	selected_order_id = oid

	var order = _find_order(oid)
	if order:
		_show_order_info(order)

	_update_buttons()

func _find_order(oid: String) -> Dictionary:
	for order in available_orders:
		if order.id == oid:
			return order
	return null

func _show_order_info(order: Dictionary) -> void:
	info_title.text = order.title
	info_desc.text = order.description

	# Recompensas
	var rewards_text = "Recompensas:\n"
	for reward in order.get("Rewards", []):
		rewards_text += "• %s\n" % _format_reward(reward)
	info_rewards.text = rewards_text

	# Tempo restante
	if active_orders.has(order.id):
		var instance = active_orders[order.id]
		var days_left = instance.days_remaining
		info_time.text = "Tempo: %d dia(s)" % days_left
		abandon_button.visible = true
	else:
		info_time.text = "Duração: %d dia(s)" % order.get("Duration", 7)
		abandon_button.visible = false

func _format_reward(reward: Dictionary) -> String:
	match reward.type:
		"gold": return "%dg" % reward.amount
		"qi_gems": return "%d Qi Gems" % reward.amount
		"item":
				var item_data = DataLoader.get_item(reward.item_id)
				var item_name = item_data.display_name if item_data != null else reward.item_id
				return "%s x%d" % [item_name, reward.amount]
		"xp": return "%d XP %s" % [reward.amount, reward.skill]
		"friendship": return "%d amizade com %s" % [reward.amount, reward.npc]
		"recipe": return "Receita: %s" % reward.recipe_id
		"unlock": return "Desbloqueio: %s" % reward.unlock_id
		_: return "Recompensa desconhecida"

func _update_buttons() -> void:
	var is_active = active_orders.has(selected_order_id)
	var is_done = completed_orders.has(selected_order_id)

	accept_button.visible = not is_active and not is_done
	accept_button.disabled = not _can_accept_order(selected_order_id)
	abandon_button.visible = is_active

func _can_accept_order(oid: String) -> bool:
	var order = _find_order(oid)
	if not order:
		return false

	# Verifica pré-requisitos
	var prereqs = order.get("Prerequisites", {})
	for key in prereqs:
		var value = prereqs[key]
		match key:
			"skill_level":
				for skill in value:
					var level = value[skill]
					if GameManager.get_skill_level(skill) < level:
						return false
			"friendship":
				for npc in value:
					var level = value[npc]
					if GameManager.friendships.get(npc, 0) < level:
						return false
			"quest_completed":
				for qid in value:
					if not QuestManager.completed_quests.has(qid):
						return false
			"building_built":
				for btype in value:
					if not BuildingManager.has_building_type(btype):
						return false

	return true

## ==================== AÇÕES ====================
func _on_accept_pressed() -> void:
	if not selected_order_id:
		return

	var order = _find_order(selected_order_id)
	if not order:
		return

	# Cria instância ativa
	var instance = SpecialOrderInstance.new()
	instance.initialize(order)
	active_orders[selected_order_id] = instance

	instance.objective_updated.connect(_on_objective_updated.bind(selected_order_id))
	instance.order_completed.connect(_on_order_completed.bind(selected_order_id))
	instance.order_failed.connect(_on_order_failed.bind(selected_order_id))

	emit_signal("order_accepted", selected_order_id)
	_populate_list()
	_update_buttons()
	_show_message("Pedido aceito: %s" % order.title)

func _on_abandon_pressed() -> void:
	if not selected_order_id or not active_orders.has(selected_order_id):
		return

	var dialog = ConfirmationDialog.new()
	dialog.title = "Abandonar Pedido"
	dialog.text = "Tem certeza? Perderá progresso."
	dialog.confirmed.connect(func(): _confirm_abandon(selected_order_id))
	add_child(dialog)
	dialog.popup_centered()

func _confirm_abandon(oid: String) -> void:
	if active_orders.has(oid):
		active_orders[oid].cleanup()
		active_orders.erase(oid)
		emit_signal("order_abandoned", oid)
		_populate_list()
		_update_buttons()

func _on_objective_updated(oid: String, obj_index: int, current: int, required: int) -> void:
	_populate_list()
	if oid == selected_order_id:
		_show_order_info(_find_order(oid))

func _on_order_completed(oid: String) -> void:
	if not active_orders.has(oid):
		return

	var instance = active_orders[oid]
	var rewards = instance.get_rewards()

	# Aplica recompensas
	_apply_rewards(rewards)

	completed_orders[oid] = true
	active_orders.erase(oid)

	# Salva
	if GameManager:
		var completed = GameManager.get_data("special_orders_completed", [])
		if oid not in completed:
			completed.append(oid)
		GameManager.set_data("special_orders_completed", completed)

	emit_signal("order_completed", oid, rewards)
	_populate_list()
	_update_buttons()
	_show_message("Pedido completado! Recompensas recebidas.")

func _on_order_failed(oid: String) -> void:
	if active_orders.has(oid):
		active_orders[oid].cleanup()
		active_orders.erase(oid)
		_populate_list()
		_update_buttons()
		_show_message("Pedido falhou (tempo esgotado).")

func _apply_rewards(rewards: Array) -> void:
	for reward in rewards:
		match reward.type:
			"gold":
				GameManager.gold += reward.amount
			"qi_gems":
				GameManager.set_data("qi_gems", GameManager.get_data("qi_gems", 0) + reward.amount)
			"item":
				InventoryManager.add_item(reward.item_id, reward.amount, reward.quality)
			"xp":
				GameManager.add_skill_xp(reward.skill, reward.amount)
			"friendship":
				GameManager.add_friendship(reward.npc, reward.amount)
			"recipe":
				GameManager.learn_recipe(reward.recipe_id)
			"unlock":
				GameManager.unlock_feature(reward.unlock_id)

func _show_message(text: String) -> void:
	print("SpecialOrders: %s" % text)

## ==================== ATUALIZAÇÃO DIÁRIA ====================
func on_day_changed() -> void:
	# Atualiza pedidos ativos
	var to_check = []
	for oid in active_orders:
		var instance = active_orders[oid]
		to_check.append(oid)

	for oid in to_check:
		if active_orders.has(oid):
			active_orders[oid].on_day_passed()

	_populate_list()
	_update_currency()

	# Gera novos pedidos semanais
	if GameManager.current_day % 7 == 1:
		_generate_weekly_orders()

func _generate_weekly_orders() -> void:
	# Adiciona pedidos novos ao pool disponível
	var new_orders = DataLoader.generate_weekly_special_orders(board_type, GameManager.get_total_skill_level())
	for order in new_orders:
		# Verifica se já não existe
		var exists = false
		for o in available_orders:
			if o.id == order.id:
				exists = true
				break
		if not exists:
			available_orders.append(order)

	_populate_list()

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	var active = {}
	for oid in active_orders:
		var instance = active_orders[oid]
		active[oid] = instance.get_save_data()

	return {
		"board_type": board_type,
		"active_orders": active,
		"completed_orders": completed_orders.keys()
	}

func load_save_data(data: Dictionary) -> void:
	board_type = data.get("board_type", "qi")
	completed_orders = {}
	for oid in data.get("completed_orders", []):
		completed_orders[oid] = true

	for oid in data.get("active_orders", {}):
		var odata = data.get("active_orders", {})[oid]
		var order_def = _find_order(oid)
		if order_def:
			var instance = SpecialOrderInstance.new()
			instance.initialize(order_def)
			instance.load_save_data(odata)
			active_orders[oid] = instance

			instance.objective_updated.connect(_on_objective_updated.bind(oid))
			instance.order_completed.connect(_on_order_completed.bind(oid))
			instance.order_failed.connect(_on_order_failed.bind(oid))


class SpecialOrderInstance:
	var order_data: Dictionary
	var objectives: Array = []
	var days_remaining: int = 0
	var start_day: int = 0

	signal objective_updated(order_id: String, obj_index: int, current: int, required: int)
	signal order_completed(order_id: String)
	signal order_failed(order_id: String)

	func initialize(data: Dictionary) -> void:
		order_data = data
		start_day = GameManager.current_day if GameManager else 1
		days_remaining = data.get("Duration", 7)

		# Parse objetivos
		var raw = data.get("Objectives", [])
		for obj in raw:
			objectives.append({
				"type": obj.get("Type", ""),
				"target": obj.get("Target", ""),
				"current": 0,
				"required": obj.get("Count", 1),
				"description": obj.get("Description", "")
			})

	func on_day_passed() -> void:
		days_remaining -= 1
		if days_remaining <= 0:
			emit_signal("order_failed", order_data.id)

	func update_objective(obj_type: String, target: String, amount: int) -> void:
		for i in objectives:
			var obj = objectives[i]
			if obj.type == obj_type:
				var match = false
				if obj.target == "" or obj.target == target:
					match = true
				elif obj_type == "collect_category":
					var item_data = DataLoader.get_item(target)
					if item_data != null and item_data.category == obj.target:
						match = true
				elif obj_type == "kill_monster_category":
					var monster_data = DataLoader.get_monster(target)
					if monster_data != null and monster_data.category == obj.target:
						match = true

				if match:
					obj.current = min(obj.current + amount, obj.required)
					emit_signal("objective_updated", order_data.id, i, obj.current, obj.required)

		_check_completion()

	func _check_completion() -> void:
		for obj in objectives:
			if obj.current < obj.required:
				return
		emit_signal("order_completed", order_data.id)

	func get_rewards() -> Array:
		return order_data.get("Rewards", [])

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
			"days_remaining": days_remaining,
			"start_day": start_day
		}

	func load_save_data(data: Dictionary) -> void:
		days_remaining = data.get("days_remaining", 7)
		start_day = data.get("start_day", 1)
		var saved_objectives = data.get("objectives", [])
		for i in range(saved_objectives.size()):
			var saved = saved_objectives[i]
			if i < objectives.size():
				objectives[i].current = saved.get("current", 0)

	func cleanup() -> void:
		pass