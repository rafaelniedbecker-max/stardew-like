extends Node

## Gerencia relacionamentos profundos: eventos de coração, namoro, casamento, filhos

@export var heart_event_scenes: Dictionary = {}  # {event_id: PackedScene}

## Estado
var dating_npc: String = ""  # NPC que está namorando
var spouse: String = ""  # NPC casado
var spouse_room_unlocked: bool = false
var children: Array = []  # [{name, gender, birth_day, age_days, npc_parent}]
var pending_proposal: String = ""  # NPC esperando resposta
var divorced: Array = []  # NPCs divorciados

## Eventos de coração por NPC
const HEART_EVENTS = {
	# Exemplo estrutura - dados reais viriam do JSON
	"Abigail": {
		2: {"id": "abigail_2", "location": "Pierre's Shop", "time": "1100-1700", "season": "any", "rain": false},
		4: {"id": "abigail_4", "location": "Mountain Lake", "time": "1100-1700", "season": "any", "rain": false},
		6: {"id": "abigail_6", "location": "Abigail's Room", "time": "1800-2300", "season": "any", "rain": false},
		8: {"id": "abigail_8", "location": "Graveyard", "time": "2000-2400", "season": "Fall", "rain": false},
		10: {"id": "abigail_10", "location": "Wizard Tower", "time": "2000-2400", "season": "any", "rain": false},
		14: {"id": "abigail_14", "location": "Abigail's Room", "time": "1800-2300", "season": "any", "rain": false}  # Casamento
	},
	# ... outros NPCs seguiriam mesma estrutura
}

## Itens de casamento
const MERMAID_PENDANT = "(O)460"  # Pingente de Sereia
const DIVORCE_COST = 50000

## ==================== SINAIS ====================
signal friendship_changed(npc: String, old_value: int, new_value: int)
signal heart_event_available(npc: String, heart_level: int)
signal heart_event_started(event_id: String)
signal heart_event_completed(event_id: String)
signal dating_started(npc: String)
signal dating_ended(npc: String)
signal marriage_proposed(npc: String)
signal married(npc: String)
signal divorced_signal(npc: String)
signal child_born(child_data: Dictionary)
signal child_grew_up(child_data: Dictionary)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)
		GameManager.friendship_changed.connect(_on_friendship_changed)

	# Carrega dados salvos
	_load_relationship_data()

func _load_relationship_data() -> void:
	if not GameManager:
		return

	dating_npc = GameManager.get_data("dating_npc", "")
	spouse = GameManager.get_data("spouse", "")
	spouse_room_unlocked = GameManager.get_data("spouse_room_unlocked", false)
	children = GameManager.get_data("children", [])
	divorced = GameManager.get_data("divorced_npcs", [])

func _on_day_changed() -> void:
	_check_heart_events()
	_update_spouse_behavior()
	_update_children()

func _on_friendship_changed(npc: String, new_value: int) -> void:
	# Verifica eventos de coração desbloqueados
	var old_hearts = (new_value - 1) / 250  # Aproximado
	var new_hearts = new_value / 250

	# Verifica marcos de 2, 4, 6, 8, 10, 12, 14 corações
	for threshold in [250, 500, 750, 1000, 1250, 1500, 1750, 2000, 2250, 2500, 2750]:
		if new_value >= threshold and (new_value - 250) < threshold:
			_check_heart_event_unlock(npc, threshold / 250)

	# Verifica bouquet (8 corações = 2000 pts)
	if new_value >= 2000 and not dating_npc and not spouse and not divorced.has(npc):
		_show_bouquet_available(npc)

	# Verifica casamento (10 corações = 2500 pts + dating)
	if new_value >= 2500 and dating_npc == npc and not spouse:
		_show_mermaid_pendant_available(npc)

	emit_signal("friendship_changed", npc, new_value - 250, new_value)

## ==================== EVENTOS DE CORAÇÃO ====================
func _check_heart_event_unlock(npc: String, heart_level: int) -> void:
	if not HEART_EVENTS.has(npc):
		return

	var events = HEART_EVENTS[npc]
	if events.has(heart_level):
		var event = events[heart_level]
		# Verifica condições (estação, hora, clima)
		if _check_event_conditions(event):
			# Marca evento como disponível
			var key = "%s_%d" % [npc, heart_level]
			GameManager.set_data("heart_event_%s_unlocked" % key, true)
			emit_signal("heart_event_available", npc, heart_level)

func _check_event_conditions(event: Dictionary) -> bool:
	if not GameManager:
		return false

	# Estação
	if event.get("season", "any") != "any":
		var seasons = ["Spring", "Summer", "Fall", "Winter"]
		if seasons[GameManager.current_season] != event.season:
			return false

	# Hora
	var time_range = event.get("time", "0-2400").split("-")
	var start = time_range[0].to_int()
	var end = time_range[1].to_int()
	var current = GameManager.current_time
	if current < start or current > end:
		return false

	# Chuva
	if event.get("rain", false) and not GameManager.is_raining:
		return false

	# Local - jogador deve estar lá
	# TODO: Verificar localização do jogador

	return true

func _check_heart_events() -> void:
	# Verifica se algum evento pode acontecer agora
	for npc in HEART_EVENTS:
		var events = HEART_EVENTS[npc]
		for heart_level in events:
			var key = "%s_%d" % [npc, heart_level]
			if GameManager.get_data("heart_event_%s_unlocked" % key, false) and not GameManager.get_data("heart_event_%s_done" % key, false):
				var event = events[heart_level]
				if _check_event_conditions(event):
					_trigger_heart_event(npc, heart_level, event.id)
					return  # Um por dia

func _trigger_heart_event(npc: String, heart_level: int, event_id: String) -> void:
	print("Evento de coração: %s - %d corações" % [npc, heart_level])

	# Marca como iniciado
	var key = "%s_%d" % [npc, heart_level]
	GameManager.set_data("heart_event_%s_done" % key, true)

	emit_signal("heart_event_started", event_id)

	# Usa o novo HeartEventsUI
	if HeartEventsUI:
		var npc_data = DataLoader.get_npc(npc)
		HeartEventsUI.play_event(npc, event_id, npc_data, func():
			_on_heart_event_completed(event_id)
		)
		return

	# Fallback para evento genérico
	_show_generic_heart_event(npc, heart_level, event_id)

func _show_generic_heart_event(npc: String, heart_level: int, event_id: String) -> void:
	var npc_data = DataLoader.get_npc(npc)
	var name = npc_data.get_display_name() if npc_data != null else npc

	var panel = Panel.new()
	panel.name = "HeartEvent_%s" % event_id
	panel.anchors_preset = 15
	panel.offset_left = 150
	panel.offset_top = 100
	panel.offset_right = -150
	panel.offset_bottom = -100

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Evento de Coração: %s (%d/14)" % [name, heart_level]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = _get_heart_event_description(npc, heart_level)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Opções de diálogo (se aplicável)
	var choices = _get_heart_event_choices(npc, heart_level)
	for choice in choices:
		var btn = Button.new()
		btn.text = choice.text
		btn.pressed.connect(_on_heart_event_choice.bind(choice.friendship_change, choice.affection_change))
		vbox.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Continuar"
	close_btn.pressed.connect(func(): _complete_heart_event(event_id, panel))
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _get_heart_event_description(npc: String, heart_level: int) -> String:
	# Descrições genéricas baseadas no nível
	var descriptions = {
		2: "%s te convida para passar um tempo juntos.",
		4: "%s compartilha um segredo pessoal com você.",
		6: "%s mostra um lado vulnerável.",
		8: "%s expressa sentimentos profundos por você.",
		10: "%s revela algo muito importante.",
		12: "%s planeja o futuro juntos.",
		14: "O dia do seu casamento com %s chegou!"
	}
	return descriptions.get(heart_level, "Um momento especial com %s.") % npc

func _get_heart_event_choices(npc: String, heart_level: int) -> Array:
	# Retorna escolhas baseadas no evento
	var choices = []

	if heart_level == 8:  # Confissão
		choices.append({"text": "Eu também gosto de você", "friendship_change": 250, "affection_change": 0})
		choices.append({"text": "Somos apenas amigos", "friendship_change": -500, "affection_change": 0})
	elif heart_level == 10:  # Compromisso
		choices.append({"text": "Sim, quero ficar com você", "friendship_change": 250, "affection_change": 0})
		choices.append({"text": "Não estou pronto", "friendship_change": -250, "affection_change": 0})
	else:
		choices.append({"text": "Ouvir", "friendship_change": 50, "affection_change": 0})

	return choices

func _on_heart_event_choice(friendship_change: int, affection_change: int) -> void:
	# Aplica mudança de amizade
	# O NPC atual seria passado via contexto
	print("Escolha feita: amizade %d, afeição %d" % [friendship_change, affection_change])

func _complete_heart_event(event_id: String, panel: Panel) -> void:
	panel.queue_free()
	emit_signal("heart_event_completed", event_id)

func _on_heart_event_completed(event_id: String) -> void:
	emit_signal("heart_event_completed", event_id)

## ==================== NAMORO ====================
func _show_bouquet_available(npc: String) -> void:
	var npc_data = DataLoader.get_npc(npc)
	var name = npc_data.get_display_name() if npc_data != null else npc

	var dialog = ConfirmationDialog.new()
	dialog.title = "Buquê Disponível"
	dialog.text = "Você pode dar um Buquê para %s para iniciar um namoro (8 corações).\nComprar no Pierre por 200g?" % name
	dialog.confirmed.connect(func(): _buy_and_give_bouquet(npc))
	add_child(dialog)
	dialog.popup_centered()

func _buy_and_give_bouquet(npc: String) -> void:
	if GameManager.gold < 200:
		_show_message("Ouro insuficiente!")
		return

	GameManager.gold -= 200
	InventoryManager.remove_item("(O)458", 1)  # Bouquet

	# Inicia namoro
	dating_npc = npc
	GameManager.set_data("dating_npc", npc)
	GameManager.add_friendship(npc, 250)  # Boost imediato

	emit_signal("dating_started", npc)
	_show_message("Você está namorando %s agora!" % npc)

func give_bouquet(npc: String) -> bool:
	if dating_npc != "" or spouse != "":
		_show_message("Você já tem um parceiro!")
		return false

	var npc_data = DataLoader.get_npc(npc)
	if not npc_data:
		return false

	var friendship = GameManager.friendships.get(npc, 0)
	if friendship < 2000:  # 8 corações
		_show_message("%s precisa de 8 corações para aceitar o buquê." % npc)
		return false

	if not InventoryManager.has_item("(O)458"):
		_show_message("Você não tem um Buquê!")
		return false

	InventoryManager.remove_item("(O)458", 1)
	dating_npc = npc
	GameManager.set_data("dating_npc", npc)
	GameManager.add_friendship(npc, 250)

	emit_signal("dating_started", npc)
	return true

func break_up(npc: String) -> void:
	if dating_npc != npc:
		return

	dating_npc = ""
	GameManager.set_data("dating_npc", "")
	GameManager.add_friendship(npc, -500)  # Penalidade

	emit_signal("dating_ended", npc)
	_show_message("Você terminou com %s." % npc)

## ==================== CASAMENTO ====================
func _show_mermaid_pendant_available(npc: String) -> void:
	var npc_data = DataLoader.get_npc(npc)
	var name = npc_data.get_display_name() if npc_data != null else npc

	var dialog = ConfirmationDialog.new()
	dialog.title = "Pingente de Sereia"
	dialog.text = "Com 10 corações e namorando %s, você pode propor casamento com o Pingente de Sereia (5000g na loja do Velho Marinheiro, dias de chuva)." % name
	dialog.confirmed.connect(func(): _show_mermaid_pendant_info(npc))
	add_child(dialog)
	dialog.popup_centered()

func _show_mermaid_pendant_info(npc: String) -> void:
	_show_message("Visite o Velho Marinheiro na praia em dia de chuva para comprar o Pingente de Sereia (5000g).")

func propose_marriage(npc: String) -> bool:
	if dating_npc != npc:
		_show_message("Você não está namorando %s." % npc)
		return false

	var friendship = GameManager.friendships.get(npc, 0)
	if friendship < 2500:  # 10 corações
		_show_message("%s precisa de 10 corações para aceitar." % npc)
		return false

	if not InventoryManager.has_item(MERMAID_PENDANT):
		_show_message("Você precisa do Pingente de Sereia!")
		return false

	# Verifica casa upgradeada
	if not GameManager.get_data("house_upgrade_2", false):
		_show_message("Você precisa da segunda ampliação da casa (com quarto de bebê).")
		return false

	InventoryManager.remove_item(MERMAID_PENDANT, 1)
	pending_proposal = npc

	# Evento de casamento (3 dias depois)
	GameManager.set_data("wedding_day", GameManager.current_day + 3)
	GameManager.set_data("wedding_npc", npc)

	emit_signal("marriage_proposed", npc)
	_show_message("Você propôs casamento a %s! O casamento será em 3 dias." % npc)
	return true

func _on_wedding_day() -> void:
	var npc = GameManager.get_data("wedding_npc", "")
	if not npc:
		return

	spouse = npc
	dating_npc = ""
	GameManager.set_data("spouse", npc)
	GameManager.set_data("dating_npc", "")
	GameManager.set_data("wedding_npc", "")

	# Desbloqueia quarto do cônjuge
	spouse_room_unlocked = true
	GameManager.set_data("spouse_room_unlocked", true)

	# Adiciona cônjuge à casa
	_add_spouse_to_house(npc)

	emit_signal("married", npc)
	_show_message("Parabéns! Você se casou com %s!" % npc)

	# Evento de casamento (cutscene)
	_play_wedding_cutscene(npc)

func _add_spouse_to_house(npc: String) -> void:
	# Spawna NPC cônjuge na casa
	var house = BuildingManager.get_building_by_type("House")
	if house:
		var spouse_entity = NPC.new()
		spouse_entity.initialize(npc, house.get_spouse_spawn_pos())
		house.add_child(spouse_entity)
		house.spouse = spouse_entity

func _play_wedding_cutscene(npc: String) -> void:
	# TODO: Cutscene de casamento
	pass

func _update_spouse_behavior() -> void:
	if not spouse:
		return

	# Comportamento diário do cônjuge
	var rng = randf()

	if rng < 0.3:
		# Faz café da manhã
		GameManager.add_item_to_fridge(_get_spouse_breakfast())
	elif rng < 0.5:
		# Regar plantas
		_water_random_crops()
	elif rng < 0.6:
		# Alimentar animais
		_feed_animals()
	elif rng < 0.7:
		# Consertar cerca
		_repair_fences()
	else:
		# Passear
		_wander_around()

	# Diálogo matinal
	if GameManager.current_time == 600:
		_show_spouse_morning_dialogue()

func _get_spouse_breakfast() -> String:
	var breakfasts = {
		"Abigail": "(O)216",  # Spicy Eel
		"Emily": "(O)218",   # Autumn's Bounty
		"Haley": "(O)210",   # Pink Cake
		"Leah": "(O)212",    # Salad
		"Maru": "(O)214",    # Spicy Eel
		"Penny": "(O)208",   # Omelet
		"Alex": "(O)206",    # Complete Breakfast
		"Elliott": "(O)220", # Crab Cakes
		"Harvey": "(O)204",  # Coffee
		"Sam": "(O)202",     # Pizza
		"Sebastian": "(O)200", # Void Mayonnaise
		"Shane": "(O)200"    # Void Mayonnaise
	}
	return breakfasts.get(spouse, "(O)200")

func _water_random_crops() -> void:
	# Regar algumas plantações aleatórias
	var farm = WorldInit.get_farm_plots()
	var watered = 0
	for plot in farm:
		if plot.has_crop and plot.needs_water and watered < 10:
			plot.water()
			watered += 1

func _feed_animals() -> void:
	# Alimentar animais nas construções
	for building in BuildingManager.get_all_buildings():
		if building.building_type in ["Coop", "Big Coop", "Deluxe Coop", "Barn", "Big Barn", "Deluxe Barn"]:
			building.auto_feed_animals()

func _repair_fences() -> void:
	# Consertar cercas quebradas
	WorldInit.repair_random_fences(5)

func _wander_around() -> void:
	# Cônjuge passeia pela fazenda
	pass

func _show_spouse_morning_dialogue() -> void:
	var dialogues = {
		"Abigail": ["Bom dia! Quer jogar depois?", "Acordei cedo pra te ver."],
		"Emily": ["Bom dia, amor! Que dia lindo!", "Sonhei com você."],
		"Haley": ["Bom dia. Fez café?", "Não esqueça de me dar um beijo."],
		"Leah": ["Bom dia. A natureza está linda hoje.", "Vamos passear depois?"],
		"Maru": ["Bom dia! Tenho uma invenção nova.", "Dormiu bem?"],
		"Penny": ["Bom dia. As crianças já acordaram?", "Fiz seu chá favorito."],
		"Alex": ["Bom dia! Vamos treinar hoje?", "Você é minha motivação."],
		"Elliott": ["Bom dia, minha musa.", "Escrevi um poema pra você."],
		"Harvey": ["Bom dia. Como você dormiu?", "Lembre-se de comer bem."],
		"Sam": ["Bom dia! Skate depois?", "Que tal pizza no jantar?"],
		"Sebastian": ["Bom dia...", "Vou pro porão programar."],
		"Shane": ["Bom dia. Café forte, por favor.", "Obrigado por estar aqui."]
	}

	var lines = dialogues.get(spouse, ["Bom dia, querido!"])
	var line = lines[randi() % lines.size()]

	# Mostra bolha de diálogo acima do cônjuge
	_show_spouse_bubble(line)

func _show_spouse_bubble(text: String) -> void:
	var house = BuildingManager.get_building_by_type("House")
	if house and house.spouse:
		house.spouse.show_dialogue_bubble(text)

## ==================== DIVÓRCIO ====================
func divorce() -> void:
	if not spouse:
		return

	var dialog = ConfirmationDialog.new()
	dialog.title = "Divórcio"
	dialog.text = "Tem certeza? Custa %dg. %s vai embora e a amizade zera.\nFilhos ficam com você." % [DIVORCE_COST, spouse]
	dialog.confirmed.connect(_confirm_divorce)
	add_child(dialog)
	dialog.popup_centered()

func _confirm_divorce() -> void:
	if GameManager.gold < DIVORCE_COST:
		_show_message("Ouro insuficiente!")
		return

	GameManager.gold -= DIVORCE_COST

	var ex = spouse
	divorced.append(ex)
	GameManager.set_data("divorced_npcs", divorced)

	# Remove cônjuge da casa
	var house = BuildingManager.get_building_by_type("House")
	if house and house.spouse:
		house.spouse.queue_free()
		house.spouse = null

	spouse = ""
	spouse_room_unlocked = false
	GameManager.set_data("spouse", "")
	GameManager.set_data("spouse_room_unlocked", false)

	# Zera amizade
	GameManager.friendships[ex] = 0

	emit_signal("divorced_signal", ex)
	_show_message("Você se divorciou de %s." % ex)

## ==================== FILHOS ====================
func try_have_baby() -> bool:
	if not spouse:
		_show_message("Você precisa ser casado.")
		return false

	if not spouse_room_unlocked:
		_show_message("Precisa do quarto de bebê (2ª ampliação da casa).")
		return false

	# Verifica se já tem 2 filhos
	if children.size() >= 2:
		_show_message("Você já tem 2 filhos.")
		return false

	# Chance baseada em amizade do cônjuge (10 corações = 100%)
	var friendship = GameManager.friendships.get(spouse, 0)
	var chance = friendship / 2500.0 * 0.05  # ~5% por dia no max

	if randf() < chance:
		_pregnancy_announced()
		return true

	return false

func _pregnancy_announced() -> void:
	var dialog = ConfirmationDialog.new()
	dialog.title = "Gravidez!"
	dialog.text = "%s está grávida! O bebê nascerá em 14 dias." % spouse
	dialog.confirmed.connect(func(): _schedule_birth())
	add_child(dialog)
	dialog.popup_centered()

func _schedule_birth() -> void:
	GameManager.set_data("baby_due_day", GameManager.current_day + 14)
	GameManager.set_data("baby_spouse", spouse)

func _check_birth() -> void:
	var due_day = GameManager.get_data("baby_due_day", 0)
	if due_day > 0 and GameManager.current_day >= due_day:
		_give_birth()

func _give_birth() -> void:
	GameManager.set_data("baby_due_day", 0)

	# Gênero aleatório
	var is_boy = randf() < 0.5
	var names_boy = ["Jas", "Vincent", "Leo", "Milo", "Finn", "Kai"]
	var names_girl = ["Jas", "Vincent", "Luna", "Maya", "Ivy", "Nova"]
	var name = (names_boy if is_boy else names_girl)[randi() % 6]

	var child = {
		"name": name,
		"gender": "boy" if is_boy else "girl",
		"birth_day": GameManager.current_day,
		"age_days": 0,
		"stage": "newborn",  # newborn, baby, toddler, child
		"npc_parent": spouse
	}

	children.append(child)
	GameManager.set_data("children", children)

	emit_signal("child_born", child)
	_show_message("Nasceu %s! Parabéns!" % name)

func _update_children() -> void:
	for child in children:
		child.age_days += 1

		# Crescimento
		if child.age_days == 14 and child.stage == "newborn":
			child.stage = "baby"
		elif child.age_days == 28 and child.stage == "baby":
			child.stage = "toddler"
		elif child.age_days == 56 and child.stage == "toddler":
			child.stage = "child"
			emit_signal("child_grew_up", child)

		# Criança aparece na casa
		_spawn_child_in_house(child)

func _spawn_child_in_house(child: Dictionary) -> void:
	var house = BuildingManager.get_building_by_type("House")
	if house and child.stage != "newborn":
		# Spawna criança na casa
		var child_entity = NPC.new()
		child_entity.initialize_child(child)
		house.add_child(child_entity)
		house.children.append(child_entity)

## ==================== UTILIDADES ====================
func get_dating_npc() -> String:
	return dating_npc

func get_spouse() -> String:
	return spouse

func get_children_data() -> Array:
	return children

func is_married() -> bool:
	return spouse != ""

func can_have_children() -> bool:
	return spouse != "" and spouse_room_unlocked and children.size() < 2

func _show_message(text: String) -> void:
	print("Relationship: %s" % text)

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"dating_npc": dating_npc,
		"spouse": spouse,
		"spouse_room_unlocked": spouse_room_unlocked,
		"children": children,
		"divorced": divorced,
		"pending_proposal": pending_proposal
	}

func load_save_data(data: Dictionary) -> void:
	dating_npc = data.get("dating_npc", "")
	spouse = data.get("spouse", "")
	spouse_room_unlocked = data.get("spouse_room_unlocked", false)
	children = data.get("children", [])
	divorced = data.get("divorced", [])
	pending_proposal = data.get("pending_proposal", "")