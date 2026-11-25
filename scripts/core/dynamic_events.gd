class_name DynamicEvents
extends Node

## Sistema de Eventos Dinâmicos: eventos aleatórios, encontros, missões emergentes

@export var event_data_path: String = "res://resources/data/Events.json"

## Estado
var active_events: Array[Dictionary] = []
var event_history: Array[Dictionary] = []
var event_cooldowns: Dictionary = {}

## ==================== SINAIS ====================
signal event_started(event_id: String, event_data: Dictionary)
signal event_completed(event_id: String, outcome: String)
signal event_failed(event_id: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_event_data()

	if GameManager:
		GameManager.day_changed.connect(_on_day_changed)
		GameManager.hour_changed.connect(_on_hour_changed)

	# Verifica eventos iniciais
	_check_random_events()

func _load_event_data() -> void:
	# Carrega eventos do JSON
	var file = FileAccess.open(event_data_path, FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		# Processa eventos
		pass

## ==================== CICLO DIÁRIO ====================
func _on_day_changed(day: int, season: int, year: int) -> void:
	# Limpa cooldowns diários
	event_cooldowns.clear()

	# Verifica eventos sazonais
	_check_seasonal_events(season)

	# Verifica eventos aleatórios
	_check_random_events()

	# Verifica eventos de NPC
	_check_npc_events()

func _on_hour_changed(hour: int) -> void:
	# Eventos baseados em hora
	if hour == 12:
		_check_midday_events()
	elif hour == 18:
		_check_evening_events()
	elif hour == 0:
		_check_midnight_events()

## ==================== EVENTOS TEMPLATES ====================
const EVENT_TEMPLATES = {
	# Eventos de fazenda
	"crop_disease": {
		"id": "crop_disease",
		"name": "Praga nas Culturas",
		"description": "Uma praga atacou suas culturas! Algumas podem morrer se não tratadas.",
		"type": "farm",
		"season": [-1],  # Todas
		"chance": 0.05,
		"duration_days": 3,
		"requirements": {"min_crops": 10},
		"actions": [
			{"id": "treat", "text": "Tratar com pesticida (500g)", "cost": {"gold": 500}, "success": 0.9},
			{"id": "ignore", "text": "Ignorar (arriscar perder culturas)", "cost": {}, "success": 0.3}
		],
		"outcomes": {
			"treat_success": {"text": "Praga controlada! Culturas salvas.", "reward": {}},
			"treat_fail": {"text": "Pesticida falhou. Perdeu 20% das culturas.", "penalty": {"crops_lost": 0.2}},
			"ignore_success": {"text": "Praga passou naturalmente.", "reward": {}},
			"ignore_fail": {"text": "Praga destruiu 50% das culturas!", "penalty": {"crops_lost": 0.5}}
		}
	},

	"animal_sick": {
		"id": "animal_sick",
		"name": "Animal Doente",
		"description": "Um dos seus animais adoeceu! Precisa de remédio.",
		"type": "farm",
		"season": [-1],
		"chance": 0.03,
		"duration_days": 2,
		"requirements": {"min_animals": 1},
		"actions": [
			{"id": "medicine", "text": "Comprar remédio (1000g)", "cost": {"gold": 1000}, "success": 1.0},
			{"id": "vet", "text": "Chamar veterinário (2000g, cura garantida)", "cost": {"gold": 2000}, "success": 1.0},
			{"id": "wait", "text": "Esperar (pode piorar)", "cost": {}, "success": 0.4}
		],
		"outcomes": {
			"medicine": {"text": "Animal curado com remédio!", "reward": {"friendship": 50}},
			"vet": {"text": "Veterinário curou perfeitamente!", "reward": {"friendship": 100, "quality_boost": 1}},
			"wait_success": {"text": "Animal melhorou sozinho.", "reward": {"friendship": 20}},
			"wait_fail": {"text": "Animal piorou! Perdeu produção.", "penalty": {"production_lost": 2}}
		}
	},

	"meteorite": {
		"id": "meteorite",
		"name": "Meteorito Caiu!",
		"description": "Um meteorito caiu na sua fazenda durante a noite!",
		"type": "farm",
		"season": [-1],
		"chance": 0.01,
		"duration_days": 1,
		"requirements": {},
		"actions": [
			{"id": "mine", "text": "Minerar meteorito", "cost": {}, "success": 1.0, "requires_tool": "Pickaxe"},
			{"id": "leave", "text": "Deixar para depois", "cost": {}, "success": 1.0}
		],
		"outcomes": {
			"mine": {"text": "Obteve minério raro do meteorito!", "reward": {"items": [{"id": "(O)80", "count": 3}, {"id": "(O)386", "count": 1}]}},  # Iridium, Prismatic
			"leave": {"text": "Meteorito permanece na fazenda.", "reward": {}}
		}
	},

	"fairy_visit": {
		"id": "fairy_visit",
		"name": "Visita da Fada",
		"description": "Uma fada visitou sua fazenda e abençoou suas culturas!",
		"type": "farm",
		"season": [-1],
		"chance": 0.005,
		"duration_days": 1,
		"requirements": {"min_crops": 5},
		"actions": [
			{"id": "accept", "text": "Agradecer a fada", "cost": {}, "success": 1.0}
		],
		"outcomes": {
			"accept": {"text": "Todas as culturas maduras instantaneamente!", "reward": {"instant_grow": true}}
		}
	},

	# Eventos de NPC
	"npc_lost": {
		"id": "npc_lost",
		"name": "NPC Perdido",
		"description": "Um habitante se perdeu na floresta/minas!",
		"type": "npc",
		"season": [-1],
		"chance": 0.02,
		"duration_days": 1,
		"requirements": {},
		"actions": [
			{"id": "search", "text": "Procurar (%d horas)", "cost": {"time": 2}, "success": 0.8},
			{"id": "ignore", "text": "Ignorar", "cost": {}, "success": 0.1}
		],
		"outcomes": {
			"search_success": {"text": "Encontrou o NPC! Ganhou amizade.", "reward": {"friendship": 100}},
			"search_fail": {"text": "Não encontrou...", "penalty": {}},
			"ignore": {"text": "NPC encontrou o caminho sozinho.", "penalty": {"friendship": -50}}
		}
	},

	"npc_birthday_party": {
		"id": "npc_birthday_party",
		"name": "Festa de Aniversário",
		"description": "Hoje é aniversário de %npc%! Há uma festa na cidade.",
		"type": "social",
		"season": [-1],
		"chance": 0.0,  # Determinado por data
		"duration_days": 1,
		"requirements": {},
		"actions": [
			{"id": "attend", "text": "Participar da festa", "cost": {}, "success": 1.0},
			{"id": "gift", "text": "Levar presente especial", "cost": {}, "success": 1.0},
			{"id": "skip", "text": "Não ir", "cost": {}, "success": 1.0}
		],
		"outcomes": {
			"attend": {"text": "Divertiu-se na festa! +50 amizade com todos.", "reward": {"friendship_all": 50}},
			"gift": {"text": "Presente adorado! +200 amizade.", "reward": {"friendship": 200}},
			"skip": {"text": "Perdeu a festa. -20 amizade com aniversariante.", "penalty": {"friendship": -20}}
		}
	},

	# Eventos de mineração
	"mine_collapse": {
		"id": "mine_collapse",
		"name": "Desmoronamento na Mina",
		"description": "Parte da mina desmoronou! Pode haver tesouros ou perigo.",
		"type": "mine",
		"season": [-1],
		"chance": 0.03,
		"duration_days": 1,
		"requirements": {"in_mine": true},
		"actions": [
			{"id": "explore", "text": "Explorar escombros", "cost": {}, "success": 0.7, "requires_tool": "Pickaxe"},
			{"id": "flee", "text": "Fugir para a saída", "cost": {}, "success": 1.0}
		],
		"outcomes": {
			"explore_success": {"text": "Encontrou tesouro nos escombros!", "reward": {"items": [{"id": "(O)749", "count": 1}]}},  # Prismatic Shard
			"explore_fail": {"text": "Pedras caíram! Perdeu vida.", "penalty": {"health": -20}},
			"flee": {"text": "Escapou ileso.", "reward": {}}
		}
	},

	# Eventos de pesca
	"legendary_fish": {
		"id": "legendary_fish",
		"name": "Peixe Lendário Avistado!",
		"description": "Um peixe lendário apareceu no seu local de pesca!",
		"type": "fishing",
		"season": [-1],
		"chance": 0.01,
		"duration_days": 1,
		"requirements": {"fishing_level": 10},
		"actions": [
			{"id": "catch", "text": "Tentar pescar (difícil)", "cost": {}, "success": 0.3},
			{"id": "bait", "text": "Usar isca especial", "cost": {"item": "(O)773", "count": 1}, "success": 0.7},  # Wild Bait
			{"id": "ignore", "text": "Deixar passar", "cost": {}, "success": 1.0}
		],
		"outcomes": {
			"catch_success": {"text": "Pegou o peixe lendário!", "reward": {"items": [{"id": "(O)158", "count": 1}]}},  # Legend
			"catch_fail": {"text": "O peixe escapou...", "penalty": {}},
			"bait_success": {"text": "Isca funcionou! Pegou o peixe!", "reward": {"items": [{"id": "(O)158", "count": 1}]}},
			"ignore": {"text": "O peixe nadou embora.", "reward": {}}
		}
	}
}

## ==================== EVENTOS DE COMBATE ====================
const COMBAT_EVENTS = {
	"monster_swarm": {
		"id": "monster_swarm",
		"name": "Enxame de Monstros!",
		"description": "Um grande grupo de monstros apareceu!",
		"type": "combat",
		"chance": 0.05,
		"actions": [
			{"id": "fight", "text": "Lutar!", "cost": {}, "success": 0.7},
			{"id": "flee", "text": "Fugir!", "cost": {}, "success": 0.9}
		],
		"outcomes": {
			"fight_win": {"text": "Venceu o enxame! Muito XP.", "reward": {"combat_xp": 200}},
			"fight_lose": {"text": "Foi derrotado...", "penalty": {"health": 0, "gold_lost": 0.1}},
			"flee": {"text": "Escapou!", "reward": {}}
		}
	}
}

## ==================== PROCESSAMENTO ====================
func _check_seasonal_events(season: int) -> void:
	var season_names = ["Spring", "Summer", "Fall", "Winter"]

	# Eventos específicos de estação
	match season:
		0:  # Spring
			_trigger_event("crop_disease", 1.5)  # Mais pragas na primavera
		1:  # Summer
			_trigger_event("animal_sick", 1.2)  # Calor estressa animais
		2:  # Fall
			_trigger_event("meteorite", 1.0)
		3:  # Winter
			_trigger_event("animal_sick", 1.5)  # Frio estressa animais

func _check_random_events() -> void:
	if not GameManager:
		return

	# Verifica cada template
	for event_id in EVENT_TEMPLATES:
		var event = EVENT_TEMPLATES[event_id]

		# Verifica cooldown
		if event_cooldowns.has(event_id):
			continue

		# Verifica estação
		if event.season != [-1] and GameManager.current_season not in event.season:
			continue

		# Verifica requisitos
		if not _check_requirements(event.requirements):
			continue

		# Verifica chance
		var chance = event.chance
		if randf() < chance:
			_start_event(event_id)
			break  # Um evento por dia no máximo

func _check_requirements(reqs: Dictionary) -> bool:
	if not GameManager:
		return false

	for key in reqs:
		match key:
			"min_crops":
				var crops = 0
				for plot in GameManager.farm_crops:
					if not plot.get("is_dead", true):
						crops += 1
				if crops < reqs[key]:
					return false
			"min_animals":
				var animals = GameManager.farm_animals.size()
				if animals < reqs[key]:
					return false
			"fishing_level":
				if GameManager.skill_levels[3] < reqs[key]:
					return false
			"in_mine":
				if not GameManager.get_data("in_mine", false):
					return false
			"time":
				var h = GameManager.current_time / 100
				if h < reqs[key][0] or h > reqs[key][1]:
					return false
	return true

func _start_event(event_id: String) -> void:
	var event = EVENT_TEMPLATES[event_id]

	var event_instance = {
		"id": event_id,
		"data": event,
		"start_day": GameManager.current_day,
		"start_time": GameManager.current_time,
		"status": "active",
		"choices_made": {}
	}

	active_events.append(event_instance)
	event_cooldowns[event_id] = GameManager.current_day + 7  # Cooldown 7 dias

	# Mostra notificação
	HUD.show_notification("⚡ Evento: %s" % event.name, event.description, Color(1.0, 0.6, 0.2))

	# Abre UI do evento
	_open_event_ui(event_instance)

	emit_signal("event_started", event_id, event_instance)

func _open_event_ui(event_instance: Dictionary) -> void:
	var event = event_instance.data

	var panel = Panel.new()
	panel.name = "DynamicEventUI_%s" % event_instance.id
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 150
	panel.offset_right = -200
	panel.offset_bottom = -150

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "⚡ %s" % event.name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = event.description
	desc.autowrap_mode = 1
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.theme_override_font_size = 16
	vbox.add_child(desc)

	# Opções
	for action in event.actions:
		var btn = Button.new()
		btn.text = action.text
		btn.custom_minimum_size = Vector2(0, 50)
		btn.theme_override_font_size = 16

		var can_do = true
		var cost_text = ""

		# Verifica custo
		if action.cost.has("gold"):
			cost_text += "%dg " % action.cost.gold
			if GameManager.gold < action.cost.gold:
				can_do = false
		if action.cost.has("item"):
			var cost_item = DataLoader.get_item(action.cost.item)
			cost_text += "%s " % (cost_item.display_name if cost_item != null else null)
			if not InventoryManager.has_item(action.cost.item):
				can_do = false
		if action.cost.has("time"):
			cost_text += "%dh " % action.cost.time

		if cost_text != "":
			btn.text += " (%s)" % cost_text

		btn.disabled = not can_do
		btn.pressed.connect(_on_event_choice.bind(event_instance.id, action.id, panel))
		vbox.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Ignorar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _on_event_choice(event_id: String, choice_id: String, panel: Panel) -> void:
	var event_instance = _find_active_event(event_id)
	if not event_instance:
		return

	var event = event_instance.data
	var action = event.actions.find(func(a): return a.id == choice_id)

	if not action:
		return

	# Aplica custo
	if action.cost.has("gold"):
		GameManager.gold -= action.cost.gold
		GameManager.emit_signal("gold_changed", GameManager.gold)
	if action.cost.has("item"):
		InventoryManager.remove_item(action.cost.item, action.cost.get("count", 1))

	# Determina resultado
	var success = randf() < action.success
	var outcome_key = choice_id + ("_success" if success else "_fail")
	if not event.outcomes.has(outcome_key):
		outcome_key = "%s_success" % choice_id if success else "%s_fail" % choice_id

	var outcome = event.outcomes.get(outcome_key, {})

	# Aplica resultado
	_apply_outcome(outcome)

	# Notificação
	var text = outcome.get("text", "Evento concluído.")
	HUD.show_notification("⚡ Resultado", text, Color(0.5, 1.0, 0.5) if success else Color(1.0, 0.5, 0.5))

	# Remove evento
	active_events.erase(event_instance)
	event_history.append({
		"id": event_instance.id,
		"choice": choice_id,
		"success": success,
		"day": GameManager.current_day,
		"outcome": outcome
	})

	panel.queue_free()
	emit_signal("event_completed", event_instance.id, "success" if success else "fail")

func _apply_outcome(outcome: Dictionary) -> void:
	if outcome.has("reward"):
		var reward = outcome.reward
		if reward.has("items"):
			for item in reward.items:
				InventoryManager.add_item(item.id, item.count)
		if reward.has("gold"):
			GameManager.gold += reward.gold
			GameManager.emit_signal("gold_changed", GameManager.gold)
		if reward.has("friendship"):
			# Aplica a NPCs aleatórios ou específicos
			pass
		if reward.has("friendship_all"):
			for npc in GameManager.friendships:
				GameManager.friendships[npc] = min(2749, GameManager.friendships[npc] + reward.friendship_all)
				GameManager.emit_signal("friendship_changed", npc, GameManager.friendships[npc])
		if reward.has("instant_grow"):
			# Cresce todas as culturas instantaneamente
			for plot in GameManager.farm_crops:
				plot.growth_day = 999
		if reward.has("items"):
			for item in reward.items:
				InventoryManager.add_item(item.id, item.count)

	if outcome.has("penalty"):
		var penalty = outcome.penalty
		if penalty.has("health"):
			GameManager.health = max(0, GameManager.health + penalty.health)
			GameManager.emit_signal("health_changed", GameManager.health)
		if penalty.has("gold_lost"):
			var lost = int(GameManager.gold * penalty.gold_lost)
			GameManager.gold -= lost
			GameManager.emit_signal("gold_changed", GameManager.gold)
		if penalty.has("crops_lost"):
			# Remove culturas aleatórias
			pass
		if penalty.has("production_lost"):
			pass
		if penalty.has("friendship"):
			pass

	# Emite sinais
	if outcome.has("reward"):
		emit_signal("event_completed", outcome)
	if outcome.has("penalty"):
		emit_signal("event_failed", outcome)

## ==================== EVENTOS DE HORA ====================
func _check_midday_events() -> void:
	# Eventos ao meio-dia
	if randf() < 0.02:
		_trigger_event("npc_lost")

func _check_evening_events() -> void:
	# Eventos à noite
	if GameManager.get_data("in_mine", false) and randf() < 0.05:
		_trigger_event("mine_collapse")

func _check_midnight_events() -> void:
	# Eventos à meia-noite
	if randf() < 0.005:
		_trigger_event("fairy_visit")

func _check_npc_events() -> void:
	# Verifica aniversários
	if GameManager:
		for npc_name in GameManager.friendships:
			var npc = DataLoader.get_npc(npc_name)
			if npc and npc.is_birthday_today(GameManager.current_season, GameManager.current_day):
				_trigger_birthday_event(npc_name)

func _trigger_birthday_event(npc_name: String) -> void:
	var event = EVENT_TEMPLATES["npc_birthday_party"].duplicate()
	event.description = event.description.replace("%npc%", npc_name)
	_start_event_custom(event)

func _start_event_custom(event: Dictionary) -> void:
	var event_instance = {
		"id": event.id,
		"data": event,
		"start_day": GameManager.current_day,
		"status": "active"
	}
	active_events.append(event_instance)
	_open_event_ui(event_instance)
	emit_signal("event_started", event.id, event_instance)

func _trigger_event(event_id: String, chance_mult: float = 1.0) -> void:
	if event_cooldowns.has(event_id):
		return

	var event = EVENT_TEMPLATES.get(event_id)
	if not event:
		return

	if randf() < event.chance * chance_mult:
		_start_event(event_id)

func _find_active_event(event_id: String) -> Dictionary:
	for ev in active_events:
		if ev.id == event_id:
			return ev
	return null

## ==================== PERSISTÊNCIA ====================
func get_save_data() -> Dictionary:
	return {
		"active_events": active_events,
		"event_history": event_history,
		"event_cooldowns": event_cooldowns
	}

func load_save_data(data: Dictionary) -> void:
	active_events = data.get("active_events", [])
	event_history = data.get("event_history", [])
	event_cooldowns = data.get("event_cooldowns", {})