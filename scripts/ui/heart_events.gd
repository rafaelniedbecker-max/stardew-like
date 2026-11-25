extends Control

## UI de Eventos de Coração (Heart Events) - cenas cinematográficas

@onready var panel: Panel = $Panel
@onready var bg: TextureRect = $Panel/Background
@onready var dialogue_box: VBoxContainer = $Panel/DialogueBox
@onready var speaker_name: Label = $Panel/DialogueBox/SpeakerName
@onready var dialogue_text: Label = $Panel/DialogueBox/DialogueText
@onready var portrait: TextureRect = $Panel/DialogueBox/Portrait
@onready var choices_container: HBoxContainer = $Panel/DialogueBox/ChoicesContainer
@onready var skip_button: Button = $Panel/SkipButton
@onready var auto_button: Button = $Panel/AutoButton

## Estado
var current_event: Dictionary = {}
var event_script: Array = []
var script_index: int = 0
var is_playing: bool = false
var auto_mode: bool = false
var skip_pressed: bool = false
var on_complete: Callable = null

## NPC atual
var current_npc: String = ""
var current_npc_data: NPCData = null

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	skip_button.pressed.connect(_on_skip)
	auto_button.pressed.connect(_toggle_auto)

	# Input para avançar
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if not is_playing:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("tool_use"):
		if not choices_container.visible:
			_advance_script()
		else:
			# Se tem escolhas, não avança automaticamente
			pass

	if event.is_action_pressed("pause"):
		_toggle_pause()

func _toggle_auto() -> void:
	auto_mode = not auto_mode
	auto_button.text = "▶ Auto" if auto_mode else "⏸ Auto"
	auto_button.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5) if auto_mode else Color.WHITE)

func _on_skip() -> void:
	skip_pressed = true
	_advance_script(true)

## ==================== INICIAR EVENTO ====================
func play_event(npc_name: String, event_id: String, npc_data: NPCData, callback: Callable = null) -> void:
	current_npc = npc_name
	current_npc_data = npc_data
	on_complete = callback

	# Carrega script do evento
	event_script = _load_event_script(npc_name, event_id)
	if event_script.is_empty():
		Logger.warn("Evento não encontrado: %s - %s" % [npc_name, event_id])
		_end_event()
		return

	script_index = 0
	is_playing = true
	skip_pressed = false

	visible = true
	panel.visible = true
	panel.position = (get_viewport_rect().size - panel.size) * 0.5
	get_tree().paused = true

	# Configura retrato
	if npc_data.portrait_path != "" and ResourceLoader.exists(npc_data.portrait_path):
		portrait.texture = load(npc_data.portrait_path)
		portrait.visible = true
	else:
		portrait.visible = false

	# Fundo do evento
	bg.color = Color(0, 0, 0, 0.85)

	_next_line()

func _load_event_script(npc_name: String, event_id: String) -> Array:
	# Scripts de eventos de coração pré-definidos
	# Em produção, viria de JSON
	var scripts = {
		"Abigail": {
			"heart_2": [
				{"type": "scene", "bg": "res://resources/sprites/events/abigail_room.png"},
				{"type": "dialogue", "speaker": "Abigail", "text": "Oi {player}! Quer vir no meu quarto? Ninguém entra aqui..."},
				{"type": "dialogue", "speaker": "Abigail", "text": "Olha meu violão! Tô aprendendo uma música nova."},
				{"type": "choice", "text": "Como vai a banda?", "choices": [{"text": "Legal!", "affection": 25}, {"text": "Não ligo.", "affection": -10}]},
				{"type": "dialogue", "speaker": "Abigail", "text": "Hehe, você é legal {player}. Vamos jogar algo depois?"}
			],
			"heart_4": [
				{"type": "scene", "bg": "res://resources/sprites/events/abigail_forest.png"},
				{"type": "dialogue", "speaker": "Abigail", "text": "{player}... posso te contar um segredo?"},
				{"type": "dialogue", "speaker": "Abigail", "text": "Às vezes eu vou na floresta à noite... só pra pensar."},
				{"type": "dialogue", "speaker": "Abigail", "text": "Não conte pra ninguém, tá? Principalmente pro meu pai."},
				{"type": "choice", "text": "Seu segredo está seguro.", "choices": [{"text": "Prometo.", "affection": 50}, {"text": "Hm...", "affection": -5}]},
				{"type": "dialogue", "speaker": "Abigail", "text": "Obrigada, {player}. Isso significa muito."}
			],
			"heart_6": [
				{"type": "scene", "bg": "res://resources/sprites/events/abigail_grave.png"},
				{"type": "dialogue", "speaker": "Abigail", "text": "Vim aqui pensar... sobre tudo."},
				{"type": "dialogue", "speaker": "Abigail", "text": "Você já sentiu que não se encaixa em lugar nenhum?"},
				{"type": "dialogue", "speaker": "Abigail", "text": "Mas quando você tá por perto... faz sentido."},
				{"type": "choice", "text": "...", "choices": [{"text": "Eu também sinto isso.", "affection": 100}, {"text": "Não sei dizer.", "affection": 20}]},
				{"type": "dialogue", "speaker": "Abigail", "text": "*sorri* Bom saber que não sou só eu."}
			],
			"heart_8": [
				{"type": "scene", "bg": "res://resources/sprites/events/abigail_bedroom.png"},
				{"type": "dialogue", "speaker": "Abigail", "text": "{player}... eu gosto de você. Muito."},
				{"type": "dialogue", "speaker": "Abigail", "text": "Quer namorar comigo?"},
				{"type": "choice", "text": "Responda...", "choices": [{"text": "Sim! Adoraria!", "affection": 250}, {"text": "Sinto muito...", "affection": -100}]}
			]
		},
		"Sebastian": {
			"heart_2": [
				{"type": "scene", "bg": "res://resources/sprites/events/sebastian_room.png"},
				{"type": "dialogue", "speaker": "Sebastian", "text": "Oh, {player}. O que faz aqui?"},
				{"type": "dialogue", "speaker": "Sebastian", "text": "Tava programando um mod pro *Journey of the Prairie King*."},
				{"type": "choice", "text": "Falar sobre jogos?", "choices": [{"text": "Legal, mostra.", "affection": 25}, {"text": "Não entendo isso.", "affection": -10}]},
				{"type": "dialogue", "speaker": "Sebastian", "text": "É... a maioria não entende. Mas valeu por perguntar."}
			]
		}
		# ... outros NPCs
	}

	return scripts.get(npc_name, {}).get(event_id, [])

func _next_line() -> void:
	if script_index >= event_script.size():
		_end_event()
		return

	var line = event_script[script_index]
	script_index += 1

	match line.type:
		"scene":
			_set_background(line.bg)
			_next_line()
		"dialogue":
			_show_dialogue(line.speaker, line.text)
		"choice":
			_show_choices(line.text, line.choices)
		"action":
			_do_action(line.action, line.params)
			_next_line()
		"wait":
			_wait(line.duration)
		_:
			_next_line()

func _set_background(path: String) -> void:
	if ResourceLoader.exists(path):
		bg.texture = load(path)
	else:
		bg.color = Color(0, 0, 0, 0.85)

func _show_dialogue(speaker: String, text: String) -> void:
	speaker_name.text = speaker
	dialogue_text.text = text.format({"player": GameManager.player_name if GameManager else "Jogador"})
	choices_container.visible = false

	# Animação de digitação
	dialogue_text.visible = true
	var full_text = dialogue_text.text
	dialogue_text.text = ""

	var timer = Timer.new()
	timer.wait_time = 0.03
	timer.one_shot = false
	var char_index = 0

	timer.timeout.connect(func():
		char_index += 1
		dialogue_text.text = full_text.substr(0, char_index)
		if char_index >= full_text.length():
			timer.stop()
			timer.queue_free()
			_on_dialogue_complete()
	)
	add_child(timer)
	timer.start()

func _on_dialogue_complete() -> void:
	if auto_mode and not skip_pressed:
		var timer = Timer.new()
		timer.wait_time = 2.0
		timer.one_shot = true
		timer.timeout.connect(_advance_script)
		add_child(timer)
		timer.start()

func _advance_script(force: bool = false) -> void:
	if force or not auto_mode:
		_next_line()

func _show_choices(prompt: String, choices: Array) -> void:
	dialogue_text.text = prompt
	choices_container.visible = true

	for child in choices_container.get_children():
		child.queue_free()

	for choice in choices:
		var btn = Button.new()
		btn.text = choice.text
		btn.custom_minimum_size = Vector2(200, 40)
		btn.theme_override_font_size = 16
		btn.pressed.connect(_on_choice_selected.bind(choice))
		choices_container.add_child(btn)

func _on_choice_selected(choice: Dictionary) -> void:
	choices_container.visible = false

	if choice.has("affection"):
		# Aplica afeto
		if RelationshipManager:
			RelationshipManager.change_friendship(current_npc, choice.affection)

		# Mostra resposta se tiver
		if choice.has("response"):
			_show_dialogue(current_npc, choice.response)
			return

	# Continua
	_advance_script()

func _do_action(action: String, params: Dictionary) -> void:
	match action:
		"give_item":
			if InventoryManager:
				InventoryManager.add_item(params.item_id, params.amount)
		"play_sfx":
			if AudioManager:
				AudioManager.play_sfx(params.path)
		"particles":
			if ParticleManager:
				ParticleManager.spawn(params.type, get_tree().root.get_child(0).global_position)

func _wait(duration: float) -> void:
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_advance_script)
	add_child(timer)
	timer.start()

	# Pausa o avanço automático até o timer terminar
	var old_auto = auto_mode
	auto_mode = false
	timer.timeout.connect(func(): auto_mode = old_auto)

func _end_event() -> void:
	is_playing = false
	visible = false
	panel.visible = false
	get_tree().paused = false

	if on_complete:
		on_complete.call()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused