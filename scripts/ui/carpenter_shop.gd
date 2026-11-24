class_name CarpenterShop
extends Control

## Loja da Robin: compra de edifícios, relocação, demolição, upgrade

@onready var building_list: ItemList = $Panel/BuildingList
@onready var building_info: VBoxContainer = $Panel/BuildingInfo
@onready var info_name: Label = $Panel/BuildingInfo/NameLabel
@onready var info_desc: Label = $Panel/BuildingInfo/DescLabel
@onready var info_cost: Label = $Panel/BuildingInfo/CostLabel
@onready var info_size: Label = $Panel/BuildingInfo/SizeLabel
@onready var info_capacity: Label = $Panel/BuildingInfo/CapacityLabel
@onready var buy_button: Button = $Panel/BuildingInfo/BuyButton
@onready var relocate_button: Button = $Panel/BuildingInfo/RelocateButton
@onready var demolish_button: Button = $Panel/BuildingInfo/DemolishButton
@onready var upgrade_button: Button = $Panel/BuildingInfo/UpgradeButton
@onready var gold_label: Label = $Panel/TopBar/GoldLabel
@onready var close_button: Button = $Panel/CloseButton
@onready var tabs: TabContainer = $Panel/TabBar

## Estado
var selected_building_type: String = ""
var selected_building_data: BuildingData = null
var mode: String = "build"  # "build", "upgrade", "relocate", "demolish"
var selected_building: Building = null

## ==================== SINAIS ====================
signal shop_closed()
signal start_placement(building_type: String)
signal start_relocation(building: Building)
signal demolish_building(grid_pos: Vector2i)
signal upgrade_building(grid_pos: Vector2i, new_type: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	close_button.pressed.connect(hide)
	building_list.item_selected.connect(_on_building_selected)
	buy_button.pressed.connect(_on_buy_pressed)
	relocate_button.pressed.connect(_on_relocate_pressed)
	demolish_button.pressed.connect(_on_demolish_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	tabs.tab_changed.connect(_on_tab_changed)

	# Popula lista de edifícios
	_populate_building_list()

func _populate_building_list() -> void:
	building_list.clear()

	var buildings = DataLoader.get_all_buildings()
	# Filtra apenas edifícios construíveis pelo jogador (Robin)
	var buildable = []
	for b in buildings:
		if b.builder == "Robin":
			buildable.append(b)

	# Ordena por preço
	buildable.sort_custom(Callable(self, "_sort_by_cost"))

	for b in buildable:
		var affordable = BuildingManager.can_afford_building(b.internal_name)
		var text = "%s (%s)" % [b.get_display_name(), BuildingManager.get_building_cost_text(b.internal_name)]
		building_list.add_item(text)
		building_list.set_item_metadata(building_list.get_item_count() - 1, b.internal_name)
		if not affordable:
			building_list.set_item_custom_bg_color(building_list.get_item_count() - 1, Color(0.3, 0.3, 0.3))

func _sort_by_cost(a: BuildingData, b: BuildingData) -> int:
	return -1 if a.build_cost < b.build_cost else 1

## ==================== ABRIR LOJA ====================
func open_shop() -> void:
	visible = true
	_update_gold()
	_populate_building_list()
	_clear_info()
	grab_focus()

func _update_gold() -> void:
	gold_label.text = "%dg" % GameManager.gold

func _on_tab_changed(tab_idx: Int) -> void:
	var tab_names = ["build", "upgrade", "relocate", "demolish"]
	mode = tab_names[tab_idx]
	_update_buttons_visibility()

func _update_buttons_visibility() -> void:
	buy_button.visible = (mode == "build")
	upgrade_button.visible = (mode == "upgrade")
	relocate_button.visible = (mode == "relocate")
	demolish_button.visible = (mode == "demolish")

	# Atualiza lista baseada no modo
	if mode == "upgrade":
		_populate_upgrade_list()
	elif mode in ["relocate", "demolish"]:
		_populate_owned_buildings_list()
	else:
		_populate_building_list()

## ==================== SELEÇÃO ====================
func _on_building_selected(index: int) -> void:
	var building_type = building_list.get_item_metadata(index)
	selected_building_type = building_type
	selected_building_data = DataLoader.get_building(building_type)

	if selected_building_data:
		_show_building_info(selected_building_data)

	_update_buttons_state()

func _show_building_info(data: BuildingData) -> void:
	info_name.text = data.get_display_name()
	info_desc.text = data.description.replace("[LocalizedText ", "").replace("]", "")
	info_cost.text = "Custo: %s" % data.get_cost_description()
	info_size.text = "Tamanho: %dx%d tiles" % [data.size.x, data.size.y]

	var cap_text = "Capacidade: %d" % data.max_occupants if data.max_occupants > 0 else "Capacidade: N/A"
	if data.hay_capacity > 0:
		cap_text += " | Feno: %d" % data.hay_capacity
	info_capacity.text = cap_text

func _clear_info() -> void:
	info_name.text = "Selecione um edifício"
	info_desc.text = ""
	info_cost.text = ""
	info_size.text = ""
	info_capacity.text = ""
	selected_building_type = ""
	selected_building_data = null
	_update_buttons_state()

func _update_buttons_state() -> void:
	var can_afford = BuildingManager.can_afford_building(selected_building_type) if selected_building_type else false
	buy_button.disabled = not can_afford || mode != "build"
	upgrade_button.disabled = mode != "upgrade" || not selected_building
	relocate_button.disabled = mode != "relocate" || not selected_building
	demolish_button.disabled = mode != "demolish" || not selected_building

## ==================== LISTAS ESPECIAIS ====================
func _populate_upgrade_list() -> void:
	building_list.clear()
	# Mostra edifícios que podem ser upgradados
	for building in BuildingManager.get_all_buildings():
		if building.construction_complete:
			# Verifica upgrades possíveis
			var upgrades = _get_possible_upgrades(building.building_type)
			if upgrades.size() > 0:
				var text = "%s (%s) -> Upgrades: %s" % [building.building_data.get_display_name(), building.position_key, upgrades.size()]
				building_list.add_item(text)
				building_list.set_item_metadata(building_list.get_item_count() - 1, building)

func _populate_owned_buildings_list() -> void:
	building_list.clear()
	for building in BuildingManager.get_all_buildings():
		if building.construction_complete:
			var text = "%s (%s)" % [building.building_data.get_display_name(), building.position_key]
			building_list.add_item(text)
			building_list.set_item_metadata(building_list.get_item_count() - 1, building)

func _get_possible_upgrades(building_type: String) -> Array[String]:
	# Mapeamento de upgrades (simplificado)
	var upgrade_paths = {
		"Coop": ["Big Coop", "Deluxe Coop"],
		"Barn": ["Big Barn", "Deluxe Barn"],
		"House": ["House Upgrade 1", "House Upgrade 2", "House Upgrade 3"],
		"Shed": ["Big Shed"],
		"Cabin": ["Cabin Upgrade"],
	}
	return upgrade_paths.get(building_type, [])

## ==================== AÇÕES ====================
func _on_buy_pressed() -> void:
	if not selected_building_type:
		return

	# Inicia colocação via BuildingManager
	emit_signal("start_placement", selected_building_type)
	hide()

func _on_relocate_pressed() -> void:
	var index = building_list.get_selected_items()
	if index.size() == 0:
		return

	var building = building_list.get_item_metadata(index[0])
	if building and building is Building:
		selected_building = building
		emit_signal("start_relocation", building)
		hide()

func _on_demolish_pressed() -> void:
	var index = building_list.get_selected_items()
	if index.size() == 0:
		return

	var building = building_list.get_item_metadata(index[0])
	if building and building is Building:
		# Confirmação
		var dialog = ConfirmationDialog.new()
		dialog.title = "Demolir %s?" % building.building_data.get_display_name()
		dialog.text = "Tem certeza? Isso destruirá o edifício permanentemente.\nAnimais e itens dentro devem ser removidos primeiro."
		dialog.confirmed.connect(func(): _confirm_demolish(building))
		add_child(dialog)
		dialog.popup_centered()

func _confirm_demolish(building: Building) -> void:
	emit_signal("demolish_building", building.grid_position)
	_populate_owned_buildings_list()
	_clear_info()

func _on_upgrade_pressed() -> void:
	var index = building_list.get_selected_items()
	if index.size() == 0:
		return

	var building = building_list.get_item_metadata(index[0])
	if building and building is Building:
		var upgrades = _get_possible_upgrades(building.building_type)
		if upgrades.size() == 0:
			return

		# Menu de seleção de upgrade
		var popup = PopupMenu.new()
		for upg in upgrades:
			var bd = DataLoader.get_building(upg)
			var cost = bd.get_cost_description() if bd else "?"
			popup.add_item("%s (%s)" % [upg, cost], popup.get_item_count())
		popup.id_pressed.connect(func(id): _confirm_upgrade(building, upgrades[id]))
		add_child(popup)
		popup.popup_centered()

func _confirm_upgrade(building: Building, new_type: String) -> void:
	emit_signal("upgrade_building", building.grid_position, new_type)
	_populate_upgrade_list()
	_clear_info()

func hide() -> void:
	visible = false
	emit_signal("shop_closed")