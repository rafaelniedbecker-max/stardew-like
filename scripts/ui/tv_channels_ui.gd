class_name TVChannelsUI
extends Control

## UI dos Canais de TV: Adivinha, Tempo, Queen of Sauce, Vivendo da Terra

@onready var panel: Panel = $Panel
@onready var close_button: Button = $Panel/CloseButton
@onready var channel_buttons: HBoxContainer = $Panel/TopBar/ChannelButtons
@onready var content_area: Control = $Panel/ContentArea
@onready var fortune_content: VBoxContainer = $Panel/ContentArea/FortuneContent
@onready var weather_content: VBoxContainer = $Panel/ContentArea/WeatherContent
@onready var cooking_content: VBoxContainer = $Panel/ContentArea/CookingContent
@onready var tips_content: VBoxContainer = $Panel/ContentArea/TipsContent

## Estado
var current_channel: int = 0
var tv_channels_ref: TVChannels = null

## Canais
const CHANNELS = [
	{"id": 0, "name": "Adivinha", "icon": "🔮", "key": "fortune"},
	{"id": 1, "name": "Tempo", "icon": "🌤️", "key": "weather"},
	{"id": 2, "name": "Queen of Sauce", "icon": "🍳", "key": "cooking"},
	{"id": 3, "name": "Vivendo da Terra", "icon": "🌱", "key": "tips"}
]

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	visible = false
	panel.visible = false
	close_button.pressed.connect(hide)

	tv_channels_ref = TVChannels
	_create_channel_buttons()

	# Conecta sinais
	if TVChannels:
		TVChannels.channel_changed.connect(_on_channel_changed)

func _create_channel_buttons() -> void:
	for ch in CHANNELS:
		var btn = Button.new()
		btn.text = "%s %s" % [ch.icon, ch.name]
		btn.custom_minimum_size = Vector2(140, 40)
		btn.theme_override_font_size = 16
		btn.toggle_mode = true
		btn.pressed.connect(_on_channel_button_pressed.bind(ch.id))
		channel_buttons.add_child(btn)

	# Seleciona primeiro
	if channel_buttons.get_child_count() > 0:
		var first = channel_buttons.get_child(0)
		first.button_pressed = true
		_show_channel(0)

func _on_channel_button_pressed(channel_id: int) -> void:
	current_channel = channel_id
	if TVChannels:
		TVChannels.current_channel = channel_id
	TVChannels.emit_signal("channel_changed", channel_id)

func _on_channel_changed(channel: int) -> void:
	current_channel = channel
	# Atualiza botões
	for i in range(channel_buttons.get_child_count()):
		var btn = channel_buttons.get_child(i)
		btn.button_pressed = (i == channel)
	_show_channel(channel)

func _show_channel(channel_id: int) -> void:
	# Esconde todos
	fortune_content.visible = false
	weather_content.visible = false
	cooking_content.visible = false
	tips_content.visible = false

	var ch = CHANNELS.find({"id": channel_id})
	if ch == -1:
		return

	# Mostra conteúdo do canal
	match ch.key:
		"fortune":
			fortune_content.visible = true
			_update_fortune()
		"weather":
			weather_content.visible = true
			_update_weather()
		"cooking":
			cooking_content.visible = true
			_update_cooking()
		"tips":
			tips_content.visible = true
			_update_tips()

func _update_fortune() -> void:
	for child in fortune_content.get_children():
		child.queue_free()

	if not TVChannels:
		return

	var fortune_text = TVChannels.get_fortune_text()

	var label = Label.new()
	label.text = fortune_text
	label.autowrap_mode = 1
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.theme_override_font_size = 18
	label.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	fortune_content.add_child(label)

	# Dica extra baseada na sorte
	var luck = GameManager.daily_luck if GameManager else 0
	if luck != 0:
		var tip = Label.new()
		if luck > 0:
			tip.text = "💡 Dica: Boa sorte hoje! Tente geodas, pesca lendária ou minas profundas."
			tip.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		else:
			tip.text = "⚠️ Cuidado: Azar hoje. Evite minas profundas e apostas."
			tip.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		tip.autowrap_mode = 1
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip.theme_override_font_size = 14
		fortune_content.add_child(tip)

func _update_weather() -> void:
	for child in weather_content.get_children():
		child.queue_free()

	if not TVChannels:
		return

	var forecast = TVChannels.get_weather_forecast()

	var icon = Label.new()
	var weather_icons = {"Sunny": "☀️", "Rain": "🌧️", "Storm": "⛈️", "Snow": "❄️"}
	icon.text = weather_icons.get(forecast.weather, "☀️")
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.theme_override_font_size = 64
	weather_content.add_child(icon)

	var title = Label.new()
	title.text = "%s - %s, Dia %d" % [forecast.display_name, _get_season_name(forecast.season), forecast.day]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	weather_content.add_child(title)

	var advice = Label.new()
	advice.text = forecast.advice
	advice.autowrap_mode = 1
	advice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	advice.theme_override_font_size = 16
	advice.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	weather_content.add_child(advice)

	# Detalhes extras
	var details = VBoxContainer.new()
	details.theme_override_constants/separation = 5

	var detail_items = [
		"Umidade: %d%%" % randi_range(40, 90),
		"Vento: %s" % ["Calmo", "Leve", "Moderado", "Forte"][randi_range(0, 3)],
		"Nascer do sol: 6:00",
		"Pôr do sol: 20:00"
	]

	for d in detail_items:
		var lbl = Label.new()
		lbl.text = d
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.theme_override_font_size = 13
		lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		details.add_child(lbl)

	weather_content.add_child(details)

func _update_cooking() -> void:
	for child in cooking_content.get_children():
		child.queue_free()

	if not TVChannels:
		return

	# Episódio de hoje
	var today_key = "%d" % (GameManager.current_year * 112 + GameManager.current_season * 28 + GameManager.current_day)
	var episode = TVChannels.get_tv_cooking_episode(today_key)

	var recipe_name = episode.get("recipe", "Nenhum episódio hoje")
	var ingredients = episode.get("ingredients", [])

	var title = Label.new()
	title.text = "📺 Queen of Sauce - Hoje"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	cooking_content.add_child(title)

	var recipe_title = Label.new()
	recipe_title.text = "Receita: %s" % recipe_name
	recipe_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_title.theme_override_font_size = 20
	recipe_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	cooking_content.add_child(recipe_title)

	if ingredients:
		var ing_label = Label.new()
		ing_label.text = "Ingredientes:"
		ing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ing_label.theme_override_font_size = 16
		cooking_content.add_child(ing_label)

		var ing_grid = GridContainer.new()
		ing_grid.columns = 3
		ing_grid.theme_override_constants/h_separation = 10
		ing_grid.theme_override_constants/v_separation = 10

		for ing_id in ingredients:
			var item = DataLoader.get_item(ing_id)
			var name = item?.display_name ?? ing_id
			var has = InventoryManager and InventoryManager.get_item_count(ing_id) > 0

			var hbox = VBoxContainer.new()
			hbox.theme_override_constants/separation = 3

			var icon = TextureRect.new()
			icon.custom_minimum_size = Vector2(48, 48)
			if item and item.texture_path != "":
				icon.texture = load(item.texture_path)
			hbox.add_child(icon)

			var n = Label.new()
			n.text = name
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			n.theme_override_font_size = 12
			if not has:
				n.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			hbox.add_child(n)

			var h = Label.new()
			h.text = "(%d)" % (InventoryManager.get_item_count(ing_id) if InventoryManager else 0)
			h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			h.theme_override_font_size = 11
			h.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			hbox.add_child(h)

			ing_grid.add_child(hbox)

		cooking_content.add_child(ing_grid)

	# Verifica se já aprendeu
	var learned = GameManager and recipe_name in GameManager.unlocked_cooking_recipes
	var status = Label.new()
	if learned:
		status.text = "✅ Já aprendida!"
		status.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	else:
		status.text = "📺 Assista para aprender!"
		status.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.theme_override_font_size = 14
	cooking_content.add_child(status)

	# Botão assistir se não aprendeu
	if not learned:
		var watch_btn = Button.new()
		watch_btn.text = "👁 Assistir e Aprender"
		watch_btn.custom_minimum_size = Vector2(0, 40)
		watch_btn.theme_override_font_size = 16
		watch_btn.pressed.connect(_on_watch_cooking.bind(recipe_name))
		cooking_content.add_child(watch_btn)

func _on_watch_cooking(recipe_name: String) -> void:
	if TVChannels:
		TVChannels.watch_channel(2)  # Queen of Sauce = canal 2
	if CookingMenu:
		CookingMenu.open()

func _update_tips() -> void:
	for child in tips_content.get_children():
		child.queue_free()

	if not TVChannels:
		return

	var today_key = "%d" % (GameManager.current_year * 112 + GameManager.current_season * 28 + GameManager.current_day)
	var tip = TVChannels.get_tv_tip_channel(today_key)

	var title = Label.new()
	title.text = "📺 Vivendo da Terra - Dica do Dia"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	tips_content.add_child(title)

	var tip_text = tip.get("tip", "Nenhuma dica hoje.")
	var tip_label = Label.new()
	tip_label.text = tip_text
	tip_label.autowrap_mode = 1
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.theme_override_font_size = 16
	tip_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	tips_content.add_child(tip_label)

	# Dicas relacionadas
	var related = tip.get("related", [])
	if related:
		var rel_label = Label.new()
		rel_label.text = "Relacionado:"
		rel_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rel_label.theme_override_font_size = 14
		tips_content.add_child(rel_label)

		for r in related:
			var r_item = DataLoader.get_item(r)
			var r_name = r_item?.display_name ?? r
			var lbl = Label.new()
			lbl.text = "• %s" % r_name
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lbl.theme_override_font_size = 13
			lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
			tips_content.add_child(lbl)

func _get_season_name(season: int) -> String:
	return ["Primavera", "Verão", "Outono", "Inverno"][season]

## ==================== PÚBLICO ====================
func open() -> void:
	visible = true
	panel.visible = true
	popup_centered()
	_get_tree().paused = true

func hide() -> void:
	visible = false
	panel.visible = false
	_get_tree().paused = false