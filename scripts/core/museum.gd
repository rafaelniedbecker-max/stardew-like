extends Node

## Museu: doações de minerais, artefatos, fósseis, recompensas do Gunther

@export var museum_scene: PackedScene

## Estado
var donated_items: Dictionary = {}  # {item_id: true}
var donation_counts: Dictionary = {}  # {category: count}
var rewards_claimed: Array = []  # Milestones já reclamados

## Categorias de doação
const CATEGORIES = {
	"Minerals": {"name": "Minerais", "icon": "⛏️", "items": []},
	"Artifacts": {"name": "Artefatos", "icon": "🏺", "items": []},
	"Fossils": {"name": "Fósseis", "icon": "🦴", "items": []},
	"Lost Books": {"name": "Livros Perdidos", "icon": "📚", "items": []}
}

## Milestones de recompensa (baseado no Stardew)
const MILESTONES = {
	5: {"reward": "(O)326", "count": 1, "name": "Fornalha"},  # Furnace
	10: {"reward": "(O)328", "count": 1, "name": "Cristalário"},  # Crystalarium
	15: {"reward": "(O)166", "count": 1, "name": "Anel do Guerreiro"},  # Warrior Ring
	20: {"reward": "(O)272", "count": 1, "name": "Forno de Carvão"},  # Charcoal Kiln
	25: {"reward": "(O)274", "count": 1, "name": "Extrator de Seiva"},  # Tapper
	30: {"reward": "(O)276", "count": 1, "name": "Prensa de Queijo"},  # Cheese Press
	35: {"reward": "(O)278", "count": 1, "name": "Barril"},  # Keg
	40: {"reward": "(O)280", "count": 1, "name": "Pote de Conservas"},  # Preserves Jar
	45: {"reward": "(O)282", "count": 1, "name": "Bolo Rosa"},  # Pink Cake
	50: {"reward": "(O)284", "count": 1, "name": "Fabricante de Sementes"},  # Seed Maker
	55: {"reward": "(O)286", "count": 1, "name": "Máquina de Reciclagem"},  # Recycling Machine
	60: {"reward": "(O)657", "count": 1, "name": "Totem de Teleporte: Fazenda"},  # Warp Totem Farm
	65: {"reward": "(O)658", "count": 1, "name": "Totem de Teleporte: Praia"},  # Warp Totem Beach
	70: {"reward": "(O)659", "count": 1, "name": "Totem de Teleporte: Montanhas"},  # Warp Totem Mountains
	75: {"reward": "(O)749", "count": 1, "name": "Fragmento Prismático"},  # Prismatic Shard
	80: {"reward": "(O)768", "count": 1, "name": "Abóbora Dourada"},  # Golden Pumpkin
	85: {"reward": "(O)769", "count": 1, "name": "Essência do Vazio"},  # Void Essence
	90: {"reward": "(O)892", "count": 1, "name": "Fragmento de Cinza"},  # Cinder Shard
	95: {"reward": "(O)74", "count": 1, "name": "Chapéu do Gunther"},  # Gunther's Hat
	100: {"reward": "stardrop", "count": 1, "name": "Gota de Estrelas"}  # Stardrop (energia máxima +34)
}

## Itens do museu por categoria (IDs do Stardew)
const MUSEUM_ITEMS = {
	"Minerals": [
		# Minérios/Barras
		"(O)378", "(O)380", "(O)384", "(O)386", "(O)388", "(O)390",
		# Gemas
		"(O)60", "(O)62", "(O)64", "(O)66", "(O)68", "(O)70", "(O)72", "(O)74",
		"(O)76", "(O)78", "(O)80", "(O)82", "(O)84", "(O)86", "(O)88", "(O)90",
		# Geodas
		"(O)535", "(O)536", "(O)537", "(O)538",
		# Minerais de fogo/gelo
		"(O)88", "(O)90"
	],
	"Artifacts": [
		# Artefatos
		"(O)100", "(O)102", "(O)104", "(O)106", "(O)108", "(O)110", "(O)112",
		"(O)114", "(O)116", "(O)118", "(O)120", "(O)122", "(O)124", "(O)126",
		"(O)128", "(O)130", "(O)132", "(O)134", "(O)136", "(O)138", "(O)140",
		# Ossos/Anomalia
		"(O)142", "(O)144", "(O)146", "(O)148", "(O)150", "(O)152", "(O)154",
		"(O)156", "(O)158", "(O)160", "(O)162", "(O)164", "(O)166", "(O)168",
		"(O)170", "(O)172", "(O)174", "(O)176", "(O)178", "(O)180", "(O)182",
		"(O)184", "(O)186", "(O)188", "(O)190", "(O)192", "(O)194", "(O)196",
		"(O)198", "(O)200", "(O)202", "(O)204", "(O)206", "(O)208", "(O)210",
		"(O)212", "(O)214", "(O)216", "(O)218", "(O)220", "(O)222", "(O)224"
	],
	"Fossils": [
		# Fósseis (itens de escavação)
		"(O)590", "(O)591", "(O)592", "(O)593", "(O)594", "(O)595",
		"(O)596", "(O)597", "(O)598", "(O)599", "(O)600", "(O)601",
		"(O)602", "(O)603", "(O)604", "(O)605", "(O)606", "(O)607",
		"(O)608", "(O)609", "(O)610", "(O)611", "(O)612", "(O)613"
	],
	"Lost Books": [
		# Livros perdidos
		"(O)590", "(O)591", "(O)592", "(O)593", "(O)594", "(O)595",
		"(O)596", "(O)597", "(O)598", "(O)599", "(O)600", "(O)601",
		"(O)602", "(O)603", "(O)604", "(O)605", "(O)606", "(O)607",
		"(O)608", "(O)609", "(O)610", "(O)611", "(O)612", "(O)613"
	]
}

## ==================== SINAIS ====================
signal item_donated(item_id: String, category: String)
signal milestone_reached(count: int, reward: Dictionary)
signal museum_completed()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_museum_data()
	_populate_categories()

func _load_museum_data() -> void:
	if not GameManager:
		return

	donated_items = GameManager.get_data("museum_donated", {})
	donation_counts = GameManager.get_data("museum_counts", {"Minerals": 0, "Artifacts": 0, "Fossils": 0, "Lost Books": 0})
	rewards_claimed = GameManager.get_data("museum_rewards_claimed", [])

func _populate_categories() -> void:
	for category in CATEGORIES:
		CATEGORIES[category].items = MUSEUM_ITEMS.get(category, [])

## ==================== DOAÇÃO ====================
func can_donate(item_id: String) -> bool:
	# Verifica se é item de museu
	var category = _get_item_category(item_id)
	if not category:
		return false

	# Verifica se já doou
	return not donated_items.has(item_id)

func _get_item_category(item_id: String) -> String:
	for category in CATEGORIES:
		if item_id in CATEGORIES[category].items:
			return category
	return ""

func donate_item(item_id: String) -> bool:
	if not can_donate(item_id):
		return false

	# Remove do inventário
	if not InventoryManager.remove_item(item_id, 1):
		return false

	var category = _get_item_category(item_id)
	donated_items[item_id] = true
	donation_counts[category] = donation_counts.get(category, 0) + 1

	emit_signal("item_donated", item_id, category)

	# Verifica milestones
	_check_milestones()

	_save_progress()
	return true

func _check_milestones() -> void:
	var total = 0
	for count in donation_counts.values():
		total += count

	for milestone in MILESTONES:
		if total >= milestone and milestone not in rewards_claimed:
			_claim_milestone(milestone)

func _claim_milestone(milestone: int) -> void:
	var data = MILESTONES[milestone]
	rewards_claimed.append(milestone)

	var reward_item = data.reward
	if reward_item == "stardrop":
		# Gota de Estrelas: energia máxima permanente +34
		GameManager.max_energy += 34
		GameManager.energy = GameManager.max_energy
		_show_message("Você recebeu uma Gota de Estrelas! Energia máxima aumentada para %d." % GameManager.max_energy)
	else:
		InventoryManager.add_item(reward_item, data.count)
		var item_data = DataLoader.get_item(reward_item)
		var name = item_data.display_name if item_data != null else data.name
		_show_message("Marco de %d doações atingido! Recebeu: %s" % [milestone, name])

	emit_signal("milestone_reached", milestone, data)

	if get_total_donations() >= 100:
		emit_signal("museum_completed")

	_save_progress()

## ==================== CONSULTAS ====================
func is_donated(item_id: String) -> bool:
	return donated_items.has(item_id)

func get_donation_count(category: String = "") -> int:
	if category == "":
		var total = 0
		for count in donation_counts.values():
			total += count
		return total
	return donation_counts.get(category, 0)

func get_total_donations() -> int:
	return get_donation_count("")

func get_missing_items(category: String = "") -> Array:
	var missing = []
	var categories = [category] if category != "" else CATEGORIES.keys()

	for cat in categories:
		for item_id in CATEGORIES[cat].items:
			if not donated_items.has(item_id):
				missing.append({"item_id": item_id, "category": cat})
	return missing

func get_completion_percentage() -> float:
	var total = 0
	var donated = 0
	for category in CATEGORIES:
		total += CATEGORIES[category].items.size()
		for item_id in CATEGORIES[category].items:
			if donated_items.has(item_id):
				donated += 1
	return (donated / float(total) * 100.0) if total > 0 else 0.0

## ==================== UI ====================
func open_museum() -> void:
	if museum_scene:
		var ui = museum_scene.instantiate()
		ui.initialize(donated_items, donation_counts, rewards_claimed)
		get_tree().root.get_child(0).add_child(ui)
	else:
		_show_generic_museum_ui()

func _show_generic_museum_ui() -> void:
	var panel = Panel.new()
	panel.name = "MuseumUI"
	panel.anchors_preset = 15
	panel.offset_left = 50
	panel.offset_top = 30
	panel.offset_right = -50
	panel.offset_bottom = -30

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Museu - Doações: %d/100 (%.1f%%)" % [get_total_donations(), get_completion_percentage()]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	# Tabs por categoria
	var tabs = TabContainer.new()
	vbox.add_child(tabs)

	for category in CATEGORIES:
		var cat_box = VBoxContainer.new()
		tabs.add_child(cat_box)
		tabs.set_tab_title(tabs.get_child_count() - 1, "%s %s (%d/%d)" % [
			CATEGORIES[category].icon,
			CATEGORIES[category].name,
			donation_counts.get(category, 0),
			CATEGORIES[category].items.size()
		])

		# Grid de itens
		var grid = GridContainer.new()
		grid.columns = 10
		grid.add_theme_constant_override("h_separation", 5)
		grid.add_theme_constant_override("v_separation", 5)
		cat_box.add_child(grid)

		for item_id in CATEGORIES[category].items:
			var item_data = DataLoader.get_item(item_id)
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(50, 50)
			btn.tooltip_text = item_data.display_name if item_data != null else item_id

			if donated_items.has(item_id):
				btn.disabled = true
				btn.add_theme_color_override("font_color", Color(0, 1, 0))
				btn.text = "✓"
			else:
				btn.text = "?"
				btn.pressed.connect(_on_donate_clicked.bind(item_id, category))

			grid.add_child(btn)

	# Recompensas reclamadas
	var rewards_box = VBoxContainer.new()
	vbox.add_child(rewards_box)

	var rewards_title = Label.new()
	rewards_title.text = "Recompensas Reclamadas:"
	rewards_title.theme_override_font_size = 18
	rewards_box.add_child(rewards_title)

	for milestone in rewards_claimed:
		var data = MILESTONES[milestone]
		var lbl = Label.new()
		lbl.text = "  %d itens: %s" % [milestone, data.name]
		rewards_box.add_child(lbl)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _on_donate_clicked(item_id: String, category: String) -> void:
	if donate_item(item_id):
		# Atualiza UI
		open_museum()  # Reabre para refresh
	else:
		_show_message("Não pode doar este item!")

func _show_message(text: String) -> void:
	print("Museum: %s" % text)

## ==================== SERIALIZAÇÃO ====================
func _save_progress() -> void:
	if not GameManager:
		return
	GameManager.set_data("museum_donated", donated_items)
	GameManager.set_data("museum_counts", donation_counts)
	GameManager.set_data("museum_rewards_claimed", rewards_claimed)

func get_save_data() -> Dictionary:
	return {
		"donated_items": donated_items,
		"donation_counts": donation_counts,
		"rewards_claimed": rewards_claimed
	}

func load_save_data(data: Dictionary) -> void:
	donated_items = data.get("donated_items", {})
	donation_counts = data.get("donation_counts", {"Minerals": 0, "Artifacts": 0, "Fossils": 0, "Lost Books": 0})
	rewards_claimed = data.get("rewards_claimed", [])