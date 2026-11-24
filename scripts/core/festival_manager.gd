class_name FestivalManager
extends Node

## Gerencia festivais sazonais com minigames, lojas especiais, eventos

@export var festival_scenes: Dictionary = {}  # {festival_name: PackedScene}

## Estado
var active_festival: String = ""
var festival_day: int = 0
var festival_data: Dictionary = {}

## Festivais do Stardew Valley
const FESTIVALS = {
	# Spring
	"Spring_13": {
		"name": "Egg Festival",
		"display_name": "Festival do Ovo",
		"season": 0, "day": 13,
		"start_time": 900, "end_time": 1400,
		"location": "Town Square",
		"activities": ["egg_hunt", "pierre_shop"],
		"rewards": {"egg_hunt": {"first": "(O)453", "participation": "(O)454"}}
	},
	"Spring_24": {
		"name": "Flower Dance",
		"display_name": "Dança das Flores",
		"season": 0, "day": 24,
		"start_time": 900, "end_time": 1400,
		"location": "Cindersap Forest",
		"activities": ["dance", "shop"],
		"rewards": {"dance_partner": "friendship_boost"}
	},
	# Summer
	"Summer_11": {
		"name": "Luau",
		"display_name": "Luau",
		"season": 1, "day": 11,
		"start_time": 900, "end_time": 1400,
		"location": "Beach",
		"activities": ["potluck", "shop"],
		"rewards": {"potluck_quality": "friendship_villagers"}
	},
	"Summer_28": {
		"name": "Moonlight Jellies",
		"display_name": "Águas-Vivas ao Luar",
		"season": 1, "day": 28,
		"start_time": 2200, "end_time": 2400,
		"location": "Beach",
		"activities": ["viewing", "shop"],
		"rewards": {}
	},
	# Fall
	"Fall_16": {
		"name": "Stardew Valley Fair",
		"display_name": "Feira do Vale Stardew",
		"season": 2, "day": 16,
		"start_time": 900, "end_time": 1500,
		"location": "Pelican Town",
		"activities": ["grange_display", "fishing_game", "slingshot_game", "shop"],
		"rewards": {"grange": "star_tokens", "games": "star_tokens"},
		"currency": "Star Tokens"
	},
	"Fall_27": {
		"name": "Spirit's Eve",
		"display_name": "Véspera dos Espíritos",
		"season": 2, "day": 27,
		"start_time": 2200, "end_time": 2400,
		"location": "Pelican Town",
		"activities": ["maze", "shop"],
		"rewards": {"maze": "(O)768"}  # Golden Pumpkin
	},
	# Winter
	"Winter_8": {
		"name": "Festival of Ice",
		"display_name": "Festival do Gelo",
		"season": 3, "day": 8,
		"start_time": 900, "end_time": 1400,
		"location": "Cindersap Forest",
		"activities": ["ice_fishing", "shop"],
		"rewards": {"ice_fishing": "trophy"}
	},
	"Winter_25": {
		"name": "Feast of the Winter Star",
		"display_name": "Festival da Estrela de Inverno",
		"season": 3, "day": 25,
		"start_time": 900, "end_time": 1400,
		"location": "Town Square",
		"activities": ["gift_exchange", "shop"],
		"rewards": {"secret_santa": "gift"}
	}
}

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	# Verifica festival do dia atual
	_check_today_festival()

	# Conecta ao GameManager
	if GameManager:
		GameManager.day_changed.connect(_check_today_festival)
		TimeManager.hour_changed.connect(_check_festival_time)

	# Carrega minigames
	if FestivalMinigames:
		pass  # Autoload carrega automaticamente

func _check_today_festival() -> void:
	if not GameManager:
		return

	var key = "%s_%d" % [["Spring", "Summer", "Fall", "Winter"][GameManager.current_season], GameManager.current_day]
	if FESTIVALS.has(key):
		festival_data = FESTIVALS[key]
		GameManager.active_festival = festival_data.name
		festival_day = GameManager.current_day
	else:
		festival_data = {}
		GameManager.active_festival = ""

func _check_festival_time(hour: int) -> void:
	if not festival_data:
		return

	var start = festival_data.get("start_time", 0)
	var end = festival_data.get("end_time", 0)
	var current = GameManager.current_time if GameManager else 0

	if current >= start and current < end:
		# Festival ativo
		if not active_festival:
			_start_festival()
	else:
		if active_festival:
			_end_festival()

func _start_festival() -> void:
	active_festival = festival_data.name
	HUD.show_notification("🎪 Festival Iniciado!", "%s começou em %s!" % [festival_data.display_name, festival_data.location], Color(1.0, 0.5, 0.8))

	if FestivalMinigames:
		FestivalMinigames.start_festival(active_festival, self)

	emit_signal("festival_started", active_festival)

func _end_festival() -> void:
	HUD.show_notification("🎪 Festival Encerrado", "%s terminou. Até o próximo ano!" % festival_data.display_name, Color(0.8, 0.8, 0.8))
	active_festival = ""
	festival_data = {}
	emit_signal("festival_ended", active_festival)

func _get_activity_name(activity: String) -> String:
	var names = {
		"egg_hunt": "Caça aos Ovos",
		"grange_display": "Exposição de Produtos",
		"fishing_game": "Pesca Competitiva",
		"slingshot_game": "Tiro ao Alvo",
		"maze": "Labirinto Assombrado",
		"ice_fishing": "Pesca no Gelo",
		"gift_exchange": "Troca de Presentes",
		"potluck": "Sopa Comunitária (Luau)",
		"dance": "Dança das Flores",
		"viewing": "Observação de Águas-Vivas",
		"shop": "Loja do Festival",
		"pierre_shop": "Loja do Pierre",
		"dance_partner": "Par de Dança",
		"potluck_quality": "Qualidade da Sopa",
		"star_tokens": "Fichas Estrela",
		"trophy": "Trofeu",
		"secret_santa": "Amigo Secreto"
	}
	return names.get(activity, activity.capitalize())

func _on_activity_selected(activity: String) -> void:
	emit_signal("festival_activity_started", activity)

	match activity:
		"egg_hunt":
			if FestivalMinigames:
				FestivalMinigames.start_egg_hunt(self)
		"grange_display":
			if FestivalMinigames:
				FestivalMinigames.start_grange_display(self)
		"fishing_game":
			if FestivalMinigames:
				FestivalMinigames.start_fishing_contest(self)
		"slingshot_game":
			if FestivalMinigames:
				FestivalMinigames.start_slingshot_game(self)
		"maze":
			if FestivalMinigames:
				FestivalMinigames.start_maze(self)
		"ice_fishing":
			if FestivalMinigames:
				FestivalMinigames.start_ice_fishing(self)
		"gift_exchange":
			if FestivalMinigames:
				FestivalMinigames.start_gift_exchange(self)
		"potluck":
			if FestivalMinigames:
				FestivalMinigames.start_potluck(self)
		"dance":
			_open_dance_ui()
		"viewing":
			# Apenas visual
			pass
		"shop":
			_open_festival_shop()
		_:
			pass

## ==================== MINIGAMES DE FESTIVAL ====================

## Caça aos Ovos (Spring 13)
func _start_egg_hunt() -> void:
	if FestivalMinigames:
		FestivalMinigames.start_egg_hunt(self)

## Feira do Vale (Fall 16) - Grange Display
func _open_grange_ui() -> void:
	if FestivalMinigames:
		FestivalMinigames.start_grange_display(self)

## Pesca Competitiva
func _start_fishing_contest() -> void:
	if FestivalMinigames:
		FestivalMinigames.start_fishing_contest(self)

## Tiro ao Alvo
func _start_slingshot_game() -> void:
	if FestivalMinigames:
		FestivalMinigames.start_slingshot_game(self)

## Labirinto (Spirit's Eve)
func _start_maze() -> void:
	if FestivalMinigames:
		FestivalMinigames.start_maze(self)

## Pesca no Gelo
func _start_ice_fishing() -> void:
	if FestivalMinigames:
		FestivalMinigames.start_ice_fishing(self)

## Troca de Presentes (Winter Star)
func _start_gift_exchange() -> void:
	if FestivalMinigames:
		FestivalMinigames.start_gift_exchange(self)

## Luau - Potluck
func _start_potluck() -> void:
	if FestivalMinigames:
		FestivalMinigames.start_potluck(self)

## Dança das Flores
func _open_dance_ui() -> void:
	var panel = Panel.new()
	panel.name = "FlowerDanceUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 100
	panel.offset_right = -200
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "💃 Dança das Flores"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Convide um habitante para dançar!\nPrecisa ter 4+ corações com alguém."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = 1
	desc.theme_override_font_size = 14
	vbox.add_child(desc)

	# Lista NPCs disponíveis
	var scroll = ScrollContainer.new()
	var grid = GridContainer.new()
	grid.columns = 2
	grid.theme_override_constants/h_separation = 10
	grid.theme_override_constants/v_separation = 10
	scroll.add_child(grid)
	scroll.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(scroll)

	if GameManager:
		for npc_name in GameManager.friendships:
			var hearts = GameManager.friendships[npc_name] / 250
			if hearts >= 4:
				var npc = DataLoader.get_npc(npc_name)
				if npc:
					var btn = Button.new()
					btn.custom_minimum_size = Vector2(0, 60)

					var hbox = HBoxContainer.new()
					btn.add_child(hbox)

					var icon = TextureRect.new()
					icon.custom_minimum_size = Vector2(48, 48)
					if npc.portrait_path != "" and ResourceLoader.exists(npc.portrait_path):
						icon.texture = load(npc.portrait_path)
					hbox.add_child(icon)

					var info = VBoxContainer.new()
					var name = Label.new()
					name.text = npc.display_name
					name.theme_override_font_size = 14
					info.add_child(name)

					var heart_info = Label.new()
					heart_info.text = "%d corações" % hearts
					heart_info.theme_override_font_size = 12
					heart_info.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
					info.add_child(heart_info)

					hbox.add_child(info)
					btn.pressed.connect(_invite_to_dance.bind(npc_name, panel))
					grid.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Cancelar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _invite_to_dance(npc_name: String, panel: Panel) -> void:
	var hearts = GameManager.friendships[npc_name] / 250
	if hearts < 4:
		HUD.show_message("Precisa de 4+ corações!")
		return

	# Chance de aceitar baseada na amizade
	var accept_chance = 0.5 + (hearts - 4) * 0.1
	if randf() < accept_chance:
		# Aceitou!
		HUD.show_notification("💃 Dança Aceita!", "%s aceitou dançar com você!" % npc_name, Color(1.0, 0.4, 0.7))

		# Boost de amizade
		if GameManager:
			var current = GameManager.friendships.get(npc_name, 0)
			GameManager.friendships[npc_name] = min(2749, current + 250)
			GameManager.emit_signal("friendship_changed", npc_name, GameManager.friendships[npc_name])

		panel.queue_free()
	else:
		# Recusou
		HUD.show_message("%s recusou... Talvez no próximo ano." % npc_name)
		panel.queue_free()

## ==================== LOJA DO FESTIVAL ====================
func _open_festival_shop() -> void:
	if ShopUI and ShopUI.shop_scene:
		var shop = ShopUI.shop_scene.instantiate()
		shop.initialize("festival_%s" % active_festival)
		get_tree().root.get_child(0).add_child(shop)
		shop.open_shop()
	else:
		_show_generic_festival_shop()

func _show_generic_festival_shop() -> void:
	var panel = Panel.new()
	panel.name = "FestivalShopUI"
	panel.anchors_preset = 15
	panel.offset_left = 100
	panel.offset_top = 50
	panel.offset_right = -100
	panel.offset_bottom = -50

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🏪 Loja do %s" % festival_data.display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var scroll = ScrollContainer.new()
	var grid = GridContainer.new()
	grid.columns = 4
	grid.theme_override_constants/h_separation = 10
	grid.theme_override_constants/v_separation = 10
	scroll.add_child(grid)
	scroll.custom_minimum_size = Vector2(0, 300)
	vbox.add_child(scroll)

	# Itens especiais do festival
	var festival_items = _get_festival_shop_items()
	for item_id in festival_items:
		var item = DataLoader.get_item(item_id)
		if not item:
			continue

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 120)
		btn.flat = true

		var vbox = VBoxContainer.new()
		vbox.anchors_preset = 15
		btn.add_child(vbox)

		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(48, 48)
		if item.texture_path != "":
			icon.texture = load(item.texture_path)
		vbox.add_child(icon)

		var name = Label.new()
		name.text = item.display_name
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.theme_override_font_size = 12
		name.autowrap_mode = 1
		vbox.add_child(name)

		var price = Label.new()
		price.text = "%dg" % item.price
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.theme_override_font_size = 12
		price.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		vbox.add_child(price)

		btn.pressed.connect(_buy_festival_item.bind(item_id, item.price))
		grid.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _get_festival_shop_items() -> Array[String]:
	match active_festival:
		"Egg Festival":
			return ["(O)453", "(O)454", "(O)455", "(O)456"]  # Straw Hat, Chocolate Egg, etc.
		"Flower Dance":
			return ["(O)380", "(O)382", "(O)384", "(O)591", "(O)593"]  # Hats, flowers
		"Luau":
			return ["(O)216", "(O)218", "(O)220", "(O)222"]  # Ingredients
		"Stardew Valley Fair":
			return ["(O)453", "(O)454", "(O)455", "(O)456", "(O)457", "(O)458"]  # Rare items
		"Spirit's Eve":
			return ["(O)768", "(O)453", "(O)454", "(O)455"]  # Golden Pumpkin, hats
		"Festival of Ice":
			return ["(O)453", "(O)454", "(O)455", "(O)456", "(O)457"]  # Winter items
		"Feast of the Winter Star":
			return ["(O)453", "(O)454", "(O)455", "(O)456", "(O)457", "(O)458"]  # Gifts
	return []

func _buy_festival_item(item_id: String, price: int) -> void:
	if GameManager.gold < price:
		HUD.show_message("Ouro insuficiente!")
		return

	GameManager.gold -= price
	GameManager.emit_signal("gold_changed", GameManager.gold)

	if InventoryManager.add_item(item_id, 1):
		HUD.show_message("Comprado: %s por %dg" % [DataLoader.get_item(item_id)?.display_name ?? item_id, price])
	else:
		GameManager.gold += price
		GameManager.emit_signal("gold_changed", GameManager.gold)
		HUD.show_message("Inventário cheio!")

## ==================== PÚBLICO ====================
func is_festival_today() -> bool:
	return active_festival != ""

func get_current_festival() -> Dictionary:
	return festival_data

func get_festival_shop(festival_name: String) -> ShopData:
	var shop = ShopData.new()
	shop.shop_name = "Festival: %s" % festival_name
	shop.items = _get_festival_shop_items()
	return shop