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
		"rewards": {"ice_fishing": "prizes"}
	},
	"Winter_25": {
		"name": "Feast of the Winter Star",
		"display_name": "Banquete da Estrela de Inverno",
		"season": 3, "day": 25,
		"start_time": 900, "end_time": 1400,
		"location": "Pelican Town",
		"activities": ["gift_exchange", "shop"],
		"rewards": {"secret_santa": "gift"}
	}
}

## ==================== SINAIS ====================
signal festival_started(festival_name: String)
signal festival_ended(festival_name: String)
signal festival_activity_started(activity: String)
signal festival_reward_earned(reward: Dictionary)
signal star_tokens_changed(amount: int)

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
	else:
		festival_data = {}
		GameManager.active_festival = ""

func _check_festival_time(hour: int) -> void:
	if not festival_data:
		return

	var start = festival_data.get("start_time", 0)
	var end = festival_data.get("end_time", 0)
	var current = GameManager.current_time if GameManager else 0

	# Inicia festival
	if current == start and not active_festival:
		_start_festival()
	# Termina festival
	elif current >= end and active_festival:
		_end_festival()

func _start_festival() -> void:
	active_festival = festival_data.name
	festival_day = GameManager.current_day if GameManager else 0

	print("Festival: %s iniciado!" % festival_data.display_name)
	emit_signal("festival_started", active_festival)

	# Abre UI do festival
	_open_festival_ui()

func _end_festival() -> void:
	print("Festival: %s terminou!" % festival_data.display_name)
	emit_signal("festival_ended", active_festival)
	active_festival = ""
	festival_data = {}

func _open_festival_ui() -> void:
	var scene = festival_scenes.get(active_festival)
	if scene:
		var ui = scene.instantiate()
		ui.initialize(festival_data)
		get_tree().root.get_child(0).add_child(ui)
	else:
		# UI genérica
		_show_generic_festival_ui()

func _show_generic_festival_ui() -> void:
	var panel = Panel.new()
	panel.name = "FestivalUI"
	panel.anchors_preset = 15
	panel.offset_left = 100
	panel.offset_top = 50
	panel.offset_right = -100
	panel.offset_bottom = -50

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = festival_data.display_name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 28
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Bem-vindo ao %s!\nLocal: %s\nHorário: %s - %s" % [
		festival_data.display_name,
		festival_data.location,
		TimeManager.time_to_string(festival_data.start_time),
		TimeManager.time_to_string(festival_data.end_time)
	]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Botões de atividades
	for activity in festival_data.get("activities", []):
		var btn = Button.new()
		btn.text = _get_activity_name(activity)
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(_on_activity_selected.bind(activity))
		vbox.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _get_activity_name(activity: String) -> String:
	var names = {
		"egg_hunt": "Caça aos Ovos",
		"pierre_shop": "Loja do Pierre",
		"dance": "Dança das Flores",
		"potluck": "Potluck (Comida Compartilhada)",
		"shop": "Loja do Festival",
		"viewing": "Observar Águas-Vivas",
		"grange_display": "Exposição de Produtos",
		"fishing_game": "Pesca Competitiva",
		"slingshot_game": "Tiro ao Alvo",
		"maze": "Labirinto Assombrado",
		"ice_fishing": "Pesca no Gelo",
		"gift_exchange": "Troca de Presentes"
	}
	return names.get(activity, activity.capitalize())

func _on_activity_selected(activity: String) -> void:
	emit_signal("festival_activity_started", activity)

	match activity:
		"egg_hunt":
			if FestivalMinigames:
				FestivalMinigames.start_egg_hunt(self)
			else:
				_start_egg_hunt()
		"grange_display":
			if FestivalMinigames:
				FestivalMinigames.start_grange_display(self)
			else:
				_open_grange_ui()
		"fishing_game":
			if FestivalMinigames:
				FestivalMinigames.start_fishing_contest(self)
			else:
				_start_fishing_contest()
		"slingshot_game":
			if FestivalMinigames:
				FestivalMinigames.start_slingshot_game(self)
			else:
				_start_slingshot_game()
		"maze":
			if FestivalMinigames:
				FestivalMinigames.start_maze(self)
			else:
				_start_maze()
		"ice_fishing":
			if FestivalMinigames:
				FestivalMinigames.start_ice_fishing(self)
			else:
				_start_ice_fishing()
		"gift_exchange":
			if FestivalMinigames:
				FestivalMinigames.start_gift_exchange(self)
			else:
				_start_gift_exchange()
		"potluck":
			if FestivalMinigames:
				FestivalMinigames.start_potluck(self)
			else:
				_open_potluck_ui()
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
	# Cria arena com ovos escondidos
	var arena = Node2D.new()
	arena.name = "EggHuntArena"

	# Spawna ovos
	for i in range(12):
		var egg = Area2D.new()
		egg.name = "Egg_%d" % i
		var sprite = Sprite2D.new()
		sprite.texture = load("res://resources/sprites/ui/egg.png")
		egg.add_child(sprite)
		var col = CollisionShape2D.new()
		col.shape = CircleShape2D.new()
		(col.shape as CircleShape2D).radius = 16
		egg.add_child(col)
		egg.global_position = Vector2(randi_range(100, 700), randi_range(100, 500))
		egg.area_entered.connect(_on_egg_collected.bind(i))
		arena.add_child(egg)

	# Timer 50 segundos
	var timer = Timer.new()
	timer.wait_time = 50.0
	timer.one_shot = true
	timer.timeout.connect(_end_egg_hunt)
	arena.add_child(timer)
	timer.start()

	get_tree().root.get_child(0).add_child(arena)

	# UI de contador
	var ui = _create_minigame_ui("Caça aos Ovos", "Colete 9 ovos em 50 segundos!", timer)
	ui.name = "EggHuntUI"

	# Armazena estado
	arena.set("eggs_collected", 0)
	arena.set("target", 9)

func _on_egg_collected(index: int, area: Area2D) -> void:
	if area.is_in_group("player"):
		var arena = get_tree().root.get_child(0).get_node("EggHuntArena")
		var collected = arena.get("eggs_collected", 0) + 1
		arena.set("eggs_collected", collected)
		area.queue_free()

		# Atualiza UI
		var ui = get_tree().root.get_child(0).get_node("EggHuntUI")
		if ui:
			ui.update_counter(collected, arena.get("target", 9))

		if collected >= arena.get("target", 9):
			_end_egg_hunt(true)

func _end_egg_hunt(won: bool = false) -> void:
	var arena = get_tree().root.get_child(0).get_node_or_null("EggHuntArena")
	var ui = get_tree().root.get_child(0).get_node_or_null("EggHuntUI")
	if arena:
		arena.queue_free()
	if ui:
		ui.queue_free()

	if won:
		# Recompensa: Straw Hat
		InventoryManager.add_item("(O)453", 1)
		emit_signal("festival_reward_earned", {"item": "(O)453", "name": "Straw Hat"})
		_show_message("Parabéns! Você ganhou o Chapéu de Palha!")
	else:
		# Recompensa de participação
		InventoryManager.add_item("(O)454", 1)
		_show_message("Tempo esgotado! Você recebeu um ovo de chocolate.")

## Feira do Vale (Fall 16) - Grange Display
func _open_grange_ui() -> void:
	var panel = Panel.new()
	panel.name = "GrangeUI"
	panel.anchors_preset = 15
	panel.offset_left = 50
	panel.offset_top = 30
	panel.offset_right = -50
	panel.offset_bottom = -30

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Exposição de Produtos - Grange Display"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Coloque até 9 itens para julgamento.\nCategorias: Vegetais, Frutas, Flores, Artisanais, Minerais, Peixes, Cozinhados, Forrageados, Outros"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Grid 3x3 para itens
	var grid = GridContainer.new()
	grid.columns = 3
	grid.theme_override_constants/h_separation = 10
	grid.theme_override_constants/v_separation = 10
	vbox.add_child(grid)

	for i in range(9):
		var slot = _create_grange_slot(i)
		grid.add_child(slot)

	# Pontuação atual
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "Pontuação: 0 / 100"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.theme_override_font_size = 18
	vbox.add_child(score_label)

	# Botões
	var hbox = HBoxContainer.new()
	var submit_btn = Button.new()
	submit_btn.text = "Submeter para Julgamento"
	submit_btn.pressed.connect(_judge_grange)
	hbox.add_child(submit_btn)

	var clear_btn = Button.new()
	clear_btn.text = "Limpar"
	clear_btn.pressed.connect(_clear_grange)
	hbox.add_child(clear_btn)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	hbox.add_child(close_btn)
	vbox.add_child(hbox)

	get_tree().root.get_child(0).add_child(panel)

func _create_grange_slot(index: int) -> Control:
	var btn = Button.new()
	btn.name = "Slot_%d" % index
	btn.custom_minimum_size = Vector2(100, 100)
	btn.tooltip_text = "Clique para adicionar item"
	btn.pressed.connect(_on_grange_slot_clicked.bind(index))
	return btn

func _on_grange_slot_clicked(index: Int) -> void:
	# Abre inventário para selecionar item
	InventoryManager.emit_signal("inventory_opened")
	# TODO: Callback para receber item selecionado
	pass

func _judge_grange() -> void:
	# Calcula pontuação
	var panel = get_tree().root.get_child(0).get_node("GrangeUI")
	var grid = panel.get_node("VBoxContainer/GridContainer")
	var items = []

	for child in grid.get_children():
		if child is Button and child.get("item_id", "") != "":
			items.append({
				"item_id": child.get("item_id"),
				"quality": child.get("quality", 0)
			})

	if items.is_empty():
		_show_message("Coloque itens primeiro!")
		return

	var score = _calculate_grange_score(items)
	panel.get_node("VBoxContainer/ScoreLabel").text = "Pontuação: %d / 100" % score

	# Recompensas em Star Tokens
	var tokens = max(0, score * 2)  # 2 tokens por ponto
	GameManager.set("star_tokens", GameManager.get("star_tokens", 0) + tokens)
	emit_signal("star_tokens_changed", tokens)

	if score >= 90:
		_show_message("Primeiro lugar! %d Star Tokens!" % tokens)
	elif score >= 70:
		_show_message("Segundo lugar! %d Star Tokens!" % tokens)
	elif score >= 50:
		_show_message("Terceiro lugar! %d Star Tokens!" % tokens)
	else:
		_show_message("Participação: %d Star Tokens" % tokens)

func _calculate_grange_score(items: Array) -> int:
	var score = 0
	var categories_used = []

	for item_data in items:
		var item = DataLoader.get_item(item_data.item_id)
		if not item:
			continue

		# Pontuação base por qualidade
		var quality_mult = [1.0, 1.25, 1.5, 2.0][item_data.quality]
		score += int(item.price * quality_mult * 0.1)

		# Bônus por categoria única
		var cat = item.category
		if cat not in categories_used:
			categories_used.append(cat)
			score += 5

		# Bônus por variedade (categorias diferentes)
		if categories_used.size() >= 5:
			score += 10
		elif categories_used.size() >= 3:
			score += 5

	return min(100, score)

func _clear_grange() -> void:
	var panel = get_tree().root.get_child(0).get_node("GrangeUI")
	var grid = panel.get_node("VBoxContainer/GridContainer")
	for child in grid.get_children():
		if child is Button:
			child.set("item_id", "")
			child.set("quality", 0)
			child.text = ""
	panel.get_node("VBoxContainer/ScoreLabel").text = "Pontuação: 0 / 100"

## Pesca Competitiva (Fair)
func _start_fishing_contest() -> void:
	# Similar ao minigame normal mas com tempo limite e peixes específicos
	_show_message("Pesca Competitiva iniciada! Pegue o maior peixe em 2 minutos!")
	# TODO: Implementar lógica completa
	pass

## Tiro ao Alvo (Fair)
func _start_slingshot_game() -> void:
	_show_message("Tiro ao Alvo! Acertar os alvos móveis!")
	# TODO: Implementar
	pass

## Labirinto (Spirit's Eve)
func _start_maze() -> void:
	_show_message("Encontre a Abóbora Dourada no labirinto!")
	# TODO: Gerar labirinto procedural
	pass

## Pesca no Gelo (Festival of Ice)
func _start_ice_fishing() -> void:
	_show_message("Pesca no Gelo! Peixes de inverno disponíveis!")
	# TODO: Implementar
	pass

## Troca de Presentes (Winter Star)
func _start_gift_exchange() -> void:
	# Secret Santa com NPC aleatório
	var npcs = DataLoader.get_all_npcs()
	var giver = npcs[randi() % npcs.size()]
	_show_message("Você tirou %s no Amigo Secreto!" % giver.get_display_name())
	# TODO: UI para dar presente
	pass

## Potluck (Luau)
func _open_potluck_ui() -> void:
	_show_message("Traga um prato para o Potluck! Qualidade afeta amizade dos aldeões.")
	# TODO: UI para selecionar item de comida
	pass

## Dança das Flores
func _open_dance_ui() -> void:
	# Convida NPC para dançar (precisa 4+ corações)
	var available = []
	for npc in DataLoader.get_all_npcs():
		if GameManager.friendships.get(npc.internal_name, 0) >= 1000:  # 4 corações
			available.append(npc)

	if available.is_empty():
		_show_message("Ninguém quer dançar com você... (precisa 4+ corações)")
		return

	# Menu de seleção
	var popup = PopupMenu.new()
	for npc in available:
		popup.add_item(npc.get_display_name(), popup.get_item_count())
	popup.id_pressed.connect(_confirm_dance_partner.bind(available))
	add_child(popup)
	popup.popup_centered()

func _confirm_dance_partner(available: Array, id: int) -> void:
	var partner = available[id]
	GameManager.friendships[partner.internal_name] = GameManager.friendships.get(partner.internal_name, 0) + 250
	_show_message("Você dançou com %s! (+1 coração)" % partner.get_display_name())
	emit_signal("festival_reward_earned", {"type": "friendship", "npc": partner.internal_name, "amount": 250})

## Loja do Festival
func _open_festival_shop() -> void:
	var shop_id = "FestivalShop_%s" % active_festival
	var shop = DataLoader.get_shop(shop_id)
	if shop:
		ShopUI.open_shop(shop, {"Name": "Festival Vendor"})
	else:
		# Loja genérica do festival
		_show_message("Loja do festival aberta!")
	pass

## ==================== UTILIDADES ====================
func is_festival_today() -> bool:
	return festival_data != {}

func get_current_festival() -> Dictionary:
	return festival_data

func get_festival_shop(festival_name: String) -> ShopData:
	return DataLoader.get_shop("FestivalShop_%s" % festival_name)

func _show_message(text: String) -> void:
	print("Festival: %s" % text)
	# TODO: Toast