extends Node

## Sistema de Canais de TV: Adivinha, Tempo, Queen of Sauce, Vivendo da Terra

@export var tv_scene: PackedScene

## Estado
var current_channel: int = 0
var last_watched_day: int = -1
var watched_shows: Dictionary = {}  # {channel: [episodes watched]}

## Canais disponíveis
const CHANNELS = [
	{"id": 0, "name": "Adivinha", "icon": "🔮", "color": Color(0.8, 0.4, 1.0)},
	{"id": 1, "name": "Previsão do Tempo", "icon": "🌤️", "color": Color(0.4, 0.8, 1.0)},
	{"id": 2, "name": "Queen of Sauce", "icon": "🍳", "color": Color(1.0, 0.6, 0.3)},
	{"id": 3, "name": "Vivendo da Terra", "icon": "🌱", "color": Color(0.4, 1.0, 0.5)}
]

## ==================== SINAIS ====================
signal channel_changed(channel: int)
signal recipe_learned(recipe: String)
signal tip_learned(tip: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_tv_data()

func _load_tv_data() -> void:
	if not GameManager:
		return

	last_watched_day = GameManager.get_data("tv_last_watched_day", -1)
	watched_shows = GameManager.get_data("tv_watched_shows", {})

	# Garante arrays para cada canal
	for ch in CHANNELS:
		if not watched_shows.has(str(ch.id)):
			watched_shows[str(ch.id)] = []

## ==================== CANAIS ====================

# ===== CANAL 0: ADIVINHA =====
func get_fortune_text() -> String:
	var luck = GameManager.daily_luck
	var fortune = ""

	if luck > 0.05:
		fortune = "As espíritos estão muito felizes hoje. Você sentirá uma aura de boa sorte ao seu redor. \n\nEsta é uma excelente dia para: explorar as minas, pescar peixes lendários, abrir geodas, ou tentar a sorte no cassino."
	elif luck > 0:
		fortune = "Os espíritos estão contentes hoje. Você pode notar que as coisas correm um pouco mais suavemente que o normal. \n\nBom dia para: colher culturas, cuidar dos animais, coletar itens de forrageamento."
	elif luck > -0.05:
		fortune = "Os espíritos estão neutros hoje. Não há influências especiais em sua sorte. \n\nDia comum - faça suas tarefas normais."
	else:
		fortune = "Os espíritos estão irritados hoje. Você pode sentir uma aura de má sorte ao seu redor. \n\nEvite: explorar andares profundos das minas, pescar peixes difíceis, apostar no cassino. \n\nBom dia para: organizar baús, planejar fazenda, socializar na cidade."

	# Adiciona dica específica baseada na sorte
	var tips = []
	if luck > 0:
		tips.append("💡 Dica: A sorte afeta qualidade de geodas, chance de peixes lendários, e drops de monstros.")
	elif luck < -0.05:
		tips.append("⚠️ Cuidado: Baixa sorte aumenta chance de monstros, reduz qualidade de itens encontrados.")

	if tips:
		fortune += "\n\n" + tips[0]

	return fortune

# ===== CANAL 1: PREVISÃO DO TEMPO =====
func get_weather_forecast() -> Dictionary:
	var tomorrow = GameManager.current_day + 1
	var season = GameManager.current_season
	var year = GameManager.current_year

	# Usa a semente do jogo para determinar tempo determinístico
	var seed = (year * 112 + GameManager.season_days[season] * 28 + tomorrow) * 12345
	var rng = RandomNumberGenerator.new()
	rng.seed = seed

	var weather_type = "Sunny"
	var rng_val = rng.randi_range(0, 100)

	# Probabilidades por estação
	match season:
		"Spring":
			if rng_val < 18: weather_type = "Rain"
			elif rng_val < 20: weather_type = "Storm"
		"Summer":
			if rng_val < 10: weather_type = "Rain"
			elif rng_val < 12: weather_type = "Storm"
		"Fall":
			if rng_val < 15: weather_type = "Rain"
			elif rng_val < 17: weather_type = "Storm"
		"Winter":
			if rng_val < 25: weather_type = "Snow"
			elif rng_val < 27: weather_type = "Storm"
		_:
			weather_type = "Sunny"

	var weather_names = {
		"Sunny": "Ensolarado ☀️",
		"Rain": "Chuvoso 🌧️",
		"Storm": "Tempestade ⛈️",
		"Snow": "Nevando ❄️"
	}

	var advice = _get_weather_advice(weather_type, season)

	return {
		"weather": weather_type,
		"display_name": weather_names[weather_type],
		"season": season,
		"day": tomorrow,
		"advice": advice
	}

func _get_weather_advice(weather: String, season: String) -> String:
	match weather:
		"Rain":
			return "Chuva amanhã! Suas culturas serão regadas automaticamente. \n\nÓtimo dia para: ir às minas, pescar (peixes de chuva aparecem), forragear, socializar. \n\nNão precisa regar culturas ao ar livre!"
		"Storm":
			return "Tempestade amanhã! Chuva forte com raios. \n\nCulturas regadas. Peixes de tempestade raros podem aparecer. \n\nEvite ficar ao ar livre tarde da noite. Relâmpagos podem atingir árvores/objetos."
		"Snow":
			return "Neve amanhã! Culturas de inverno crescem, outras morrem. \n\nBom para: pescar peixes de inverno, forragear itens de neve, minas. \n\nRegue culturas de estufa/vasos normalmente."
		"Sunny":
			return "Dia ensolarado amanhã! \n\nLembre-se de regar suas culturas. \n\nBom para: colheita, plantio, construção, energia solar (painéis)."
		_:
			return ""

# ===== CANAL 2: QUEEN OF SAUCE =====
# Episódios baseados no Stardew (ano 1-2, depois repete)
const QUEEN_OF_SAUCE_EPISODES = {
	# Ano 1 - Primavera
	1: {"season": "Spring", "day": 7, "recipe": "Fried Egg", "ingredients": ["(O)306"]},
	2: {"season": "Spring", "day": 14, "recipe": "Bread", "ingredients": ["(O)305"]},
	3: {"season": "Spring", "day": 21, "recipe": "Salad", "ingredients": ["(O)216", "(O)218", "(O)220"]},
	4: {"season": "Spring", "day": 28, "recipe": "Cheese Cauliflower", "ingredients": ["(O)424", "(O)428"]},

	# Ano 1 - Verão
	5: {"season": "Summer", "day": 7, "recipe": "Pancakes", "ingredients": ["(O)305", "(O)306", "(O)424"]},
	6: {"season": "Summer", "day": 14, "recipe": "Cookie", "ingredients": ["(O)305", "(O)306", "(O)330", "(O)340"]},
	7: {"season": "Summer", "day": 21, "recipe": "Rhubarb Pie", "ingredients": ["(O)412", "(O)305", "(O)330", "(O)340"]},
	8: {"season": "Summer", "day": 28, "recipe": "Vegetable Medley", "ingredients": ["(O)216", "(O)218", "(O)220", "(O)222"]},

	# Ano 1 - Outono
	9: {"season": "Fall", "day": 7, "recipe": "Cranberry Candy", "ingredients": ["(O)260", "(O)330"]},
	10: {"season": "Fall", "day": 14, "recipe": "Pumpkin Pie", "ingredients": ["(O)276", "(O)305", "(O)330", "(O)340"]},
	11: {"season": "Fall", "day": 21, "recipe": "Baked Fish", "ingredients": ["(O)152", "(O)388", "(O)390"]},
	12: {"season": "Fall", "day": 28, "recipe": "Stuffing", "ingredients": ["(O)305", "(O)388", "(O)390", "(O)392"]},

	# Ano 1 - Inverno
	13: {"season": "Winter", "day": 7, "recipe": "Ice Cream", "ingredients": ["(O)306", "(O)330", "(O)424"]},
	14: {"season": "Winter", "day": 14, "recipe": "Plum Pudding", "ingredients": ["(O)260", "(O)305", "(O)330", "(O)340"]},
	15: {"season": "Winter", "day": 21, "recipe": "Artichoke Dip", "ingredients": ["(O)414", "(O)305", "(O)424"]},
	16: {"season": "Winter", "day": 28, "recipe": "Chocolate Cake", "ingredients": ["(O)305", "(O)330", "(O)340", "(O)440", "(O)424"]},

	# Ano 2 - Primavera
	17: {"season": "Spring", "day": 7, "recipe": "Pink Cake", "ingredients": ["(O)305", "(O)306", "(O)330", "(O)340", "(O)424", "(O)260"]},
	18: {"season": "Spring", "day": 14, "recipe": "Complete Breakfast", "ingredients": ["(O)305", "(O)306", "(O)160", "(O)216", "(O)424", "(O)428"]},
	19: {"season": "Spring", "day": 21, "recipe": "Farmer's Lunch", "ingredients": ["(O)305", "(O)306", "(O)424", "(O)216", "(O)428"]},
	20: {"season": "Spring", "day": 28, "recipe": "Survival Burger", "ingredients": ["(O)305", "(O)160", "(O)216", "(O)424"]},

	# Ano 2 - Verão
	21: {"season": "Summer", "day": 7, "recipe": "Dish o' The Sea", "ingredients": ["(O)152", "(O)154", "(O)388", "(O)390"]},
	22: {"season": "Summer", "day": 14, "recipe": "Maki Roll", "ingredients": ["(O)392", "(O)152", "(O)388"]},
	23: {"season": "Summer", "day": 21, "recipe": "Tropical Curry", "ingredients": ["(O)392", "(O)414", "(O)388", "(O)428"]},
	24: {"season": "Summer", "day": 28, "recipe": "Pizza", "ingredients": ["(O)305", "(O)390", "(O)428", "(O)216"]},

	# Ano 2 - Outono
	25: {"season": "Fall", "day": 7, "recipe": "Spicy Eel", "ingredients": ["(O)162", "(O)430", "(O)388"]},
	26: {"season": "Fall", "day": 14, "recipe": "Fried Mushroom", "ingredients": ["(O)404", "(O)388", "(O)390"]},
	27: {"season": "Fall", "day": 21, "recipe": "Pumpkin Soup", "ingredients": ["(O)276", "(O)305", "(O)424"]},
	28: {"season": "Fall", "day": 28, "recipe": "Super Meal", "ingredients": ["(O)305", "(O)160", "(O)424", "(O)216", "(O)428", "(O)388"]},

	# Ano 2 - Inverno
	29: {"season": "Winter", "day": 7, "recipe": "Crab Cakes", "ingredients": ["(O)172", "(O)305", "(O)306", "(O)388"]},
	30: {"season": "Winter", "day": 14, "recipe": "Lobster Bisque", "ingredients": ["(O)174", "(O)424", "(O)305", "(O)388"]},
	31: {"season": "Winter", "day": 21, "recipe": "Maple Bar", "ingredients": ["(O)305", "(O)330", "(O)340", "(O)724"]},
	32: {"season": "Winter", "day": 28, "recipe": "Strange Bun", "ingredients": ["(O)305", "(O)160", "(O)390", "(O)388", "(O)392"]}
}

func get_queen_of_sauce_today() -> Dictionary:
	var season = GameManager.current_season
	var day = GameManager.current_day
	var year = GameManager.current_year

	# Calcula episódio baseado no dia absoluto
	var absolute_day = (year - 1) * 112 + _season_to_offset(season) + day

	# Episódios passam domingo (dia 7, 14, 21, 28 de cada estação)
	if day not in [7, 14, 21, 28]:
		return {"airing": false, "message": "Queen of Sauce passa aos domingos (dias 7, 14, 21, 28)."}

	# Encontra episódio correspondente
	for ep_num in QUEEN_OF_SAUCE_EPISODES:
		var ep = QUEEN_OF_SAUCE_EPISODES[ep_num]
		var ep_absolute = (ep_num - 1)  # Simplificado

		# Verifica se é o episódio de hoje
		var ep_day_in_year = (ep_num - 1) % 28 + 1
		var ep_season_idx = (ep_num - 1) / 28
		var seasons = ["Spring", "Summer", "Fall", "Winter"]
		var ep_season = seasons[ep_season_idx % 4]

		if ep_season == season and ep_day_in_year == day:
			var watched = str(ep_num) in watched_shows.get("2", [])
			return {
				"airing": true,
				"episode": ep_num,
				"recipe": ep.recipe,
				"ingredients": ep.ingredients,
				"watched": watched,
				"message": "Hoje no Queen of Sauce: %s!" % ep.recipe
			}

	return {"airing": false, "message": "Nenhum episódio hoje."}

func learn_recipe_from_tv(recipe_name: String) -> bool:
	if InventoryManager.known_recipes.has(recipe_name):
		return false

	InventoryManager.known_recipes.append(recipe_name)
	GameManager.set_data("known_recipes", InventoryManager.known_recipes)

	CollectionsMenu.register_recipe_learned(recipe_name)
	emit_signal("recipe_learned", recipe_name)
	_show_message("Aprendeu receita: %s!" % recipe_name)
	return true

func watch_queen_of_sauce() -> void:
	var data = get_queen_of_sauce_today()
	if not data.airing or data.watched:
		return

	learn_recipe_from_tv(data.recipe)

	# Marca como assistido
	var ep_num = data.episode
	if not watched_shows.has("2"):
		watched_shows["2"] = []
	watched_shows["2"].append(str(ep_num))
	GameManager.set_data("tv_watched_shows", watched_shows)

# ===== CANAL 3: VIVENDO DA TERRA =====
const LIVIN_OFF_THE_LAND_TIPS = {
	# Primavera
	"Spring": [
		"🌱 Dica: Plante batatas na primavera - crescem rápido e dão múltiplas colheitas!",
		"🌱 Dica: Couve-flor leva 12 dias mas vende por muito. Plante no dia 1 para colher antes do verão.",
		"🌱 Dica: Morangos só podem ser comprados no Festival do Ovo (dia 13). Guarde sementes para o próximo ano!",
		"🌱 Dica: Use fertilizante básico nas primeiras culturas para aumentar chance de qualidade prata/ouro.",
		"🌱 Dica: Complete o bundle da Primavera no Centro Comunitário cedo para desbloquear a estufa!",
		"🐟 Dica: Peixes de primavera: Sardinha, Arenque, Atum. Chuva traz peixes diferentes.",
		"⛏️ Dica: Nas minas, andares 1-39 são tema marrom. Procure cobre e ferro.",
		"🎁 Dica: Presentes amados dão 80 amizade, gostados 45. Descubra o que cada NPC ama!",
	],

	# Verão
	"Summer": [
		"🌱 Dica: Mirtilos (Blueberries) dão múltiplas colheitas a cada 4 dias! Melhor cultura de verão.",
		"🌱 Dica: Melões levam 12 dias. Starfruit (Fruta Estelar) leva 13 dias mas vende muito - compre sementes no Oásis.",
		"🌱 Dica: Pimentas quentes (Hot Pepper) crescem em 5 dias e regeneram a cada 3. Ótimo lucro contínuo.",
		"🌱 Dica: Girassóis dão sementes de girassol ao colher - plante de novo grátis!",
		"🐟 Dica: Festival de Pesca no dia 18. Ganhe vara melhor e iscas!",
		"⛏️ Dica: Andares 40-79 das minas são tema gelo. Procure ouro e quartzo.",
		"🐄 Dica: Animais precisam de água no verão. Preencha o bebedouro do celeiro/galinheiro.",
	],

	# Outono
	"Fall": [
		"🌱 Dica: Abóboras regeneram a cada 2 dias após 13 dias iniciais. Melhor cultura de outono!",
		"🌱 Dica: Uvas levam 10 dias e regeneram a cada 3. Ótimo para vinho (barril).",
		"🌱 Dica: Amoras (Cranberries) em 7 dias, regeneram a cada 5. Múltiplas colheitas!",
		"🌱 Dica: Alcachofras (Artichoke) só no 2º ano no Oásis. Caras mas lucrativas.",
		"🍂 Dica: Festival do Espírito no dia 27. Labirinto dá recompensa única!",
		"⛏️ Dica: Andares 80-119 das minas são tema lava. Procure irídio!",
		"🍄 Dica: Cogumelos selvagens aparecem na caverna se escolher cogumelos no Demetrius.",
	],

	# Inverno
	"Winter": [
		"❄️ Dica: Inverno não tem culturas ao ar livre (exceto inverno). Foque em: minas, pesca, forrageamento, social.",
		"❄️ Dica: Culturas na estufa crescem o ano todo! Plante as melhores (Fruta Estelar, Abóbora, Uva).",
		"❄️ Dica: Pesca no inverno: Lula, Polvo, Peixe-Gelo. Lenda: Peixe-Lenda II (precisa vara irídio).",
		"❄️ Dica: Forrageamento de inverno: Raiz de Invernalia, Fruta de Cristal, Nabo, Crocus.",
		"❄️ Dica: Festival da Estrela de Inverno dia 25. Troca de presentes secreta!",
		"⛏️ Dica: Andares 120+ (Calabouço da Caveira) precisam chave de caveira. Muito irídio!",
		"🎁 Dica: Compre presentes para o Festival da Estrela de Inverno na loja do Pierre.",
	]
}

func get_livin_off_the_land_today() -> String:
	var season = GameManager.current_season
	var day = GameManager.current_day

	var tips = LIVIN_OFF_THE_LAND_TIPS.get(season, [])
	if tips.is_empty():
		return "Sem dicas para esta estação."

	# Dica determinística baseada no dia
	var tip_index = (day - 1) % tips.size()
	var tip = tips[tip_index]

	var header = "=== VIVENDO DA TERRA ===\nEstação: %s | Dia %d\n\n" % [season, day]
	return header + tip + "\n\n[Aperte 'Aprender' para registrar esta dica]"

func learn_tip(tip_text: String) -> void:
	var tip_id = tip_text.hash()
	if not watched_shows.has("3"):
		watched_shows["3"] = []
	if tip_id not in watched_shows["3"]:
		watched_shows["3"].append(tip_id)
		GameManager.set_data("tv_watched_shows", watched_shows)
		emit_signal("tip_learned", tip_text)

## ==================== UI ====================
func open_tv() -> void:
	if tv_scene:
		var ui = tv_scene.instantiate()
		ui.initialize(CHANNELS, current_channel)
		ui.channel_selected.connect(_on_channel_selected)
		get_tree().root.get_child(0).add_child(ui)
	else:
		_show_generic_tv_ui()

func _show_generic_tv_ui() -> void:
	var panel = Panel.new()
	panel.name = "TVUI"
	panel.anchors_preset = 15
	panel.offset_left = 100
	panel.offset_top = 50
	panel.offset_right = -100
	panel.offset_bottom = -50

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# Sidebar canais
	var sidebar = VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(150, 0)
	hbox.add_child(sidebar)

	var title = Label.new()
	title.text = "📺 TV"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	sidebar.add_child(title)

	for ch in CHANNELS:
		var btn = Button.new()
		btn.text = "%s %s" % [ch.icon, ch.name]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(_on_channel_selected.bind(ch.id))
		if ch.id == current_channel:
			btn.disabled = true
		sidebar.add_child(btn)

	# Conteúdo
	var content = VBoxContainer.new()
	hbox.add_child(content)
	content.set_h_size_flags(Control.SIZE_EXPAND_FILL)

	var close_btn = Button.new()
	close_btn.text = "Desligar TV"
	close_btn.pressed.connect(panel.queue_free)
	content.add_child(close_btn)

	_show_channel_content(content, current_channel)

	get_tree().root.get_child(0).add_child(panel)

func _on_channel_selected(channel: int) -> void:
	current_channel = channel
	# Reabre UI para atualizar
	open_tv()

func _show_channel_content(content: VBoxContainer, channel: int) -> void:
	# Limpa conteúdo anterior (mantém botão fechar)
	for child in content.get_children():
		if child != content.get_child(0):  # Mantém botão fechar
			child.queue_free()

	match channel:
		0:  # Adivinha
			var fortune_text = get_fortune_text()
			var lbl = Label.new()
			lbl.text = fortune_text
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(lbl)

		1:  # Tempo
			var forecast = get_weather_forecast()
			var lbl = Label.new()
			lbl.text = "🌤️ PREVISÃO PARA AMANHÃ (Dia %d de %s)\n\n%s\n\n%s" % [
				forecast.day, forecast.season, forecast.display_name, forecast.advice
			]
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(lbl)

		2:  # Queen of Sauce
			var data = get_queen_of_sauce_today()
			var lbl = Label.new()
			if data.airing:
				var ingredient_names = []
				for i in data.ingredients:
					var item_data = DataLoader.get_item(i)
					var item_name = item_data.display_name if item_data != null else i
					ingredient_names.append("  • %s" % item_name)
				lbl.text = "🍳 QUEEN OF SAUCE - Episódio %d\n\nReceita de hoje: %s\n\nIngredientes:\n%s" % [
					data.episode, data.recipe, "\n".join(ingredient_names)
				]
				if not data.watched:
					var btn = Button.new()
					btn.text = "Assistir e Aprender Receita"
					btn.pressed.connect(watch_queen_of_sauce)
					content.add_child(btn)
				else:
					lbl.text += "\n\n✅ Já assistido hoje."
			else:
				lbl.text = data.message
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(lbl)

		3:  # Vivendo da Terra
			var tip = get_livin_off_the_land_today()
			var lbl = Label.new()
			lbl.text = tip
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			content.add_child(lbl)

			var btn = Button.new()
			btn.text = "Registrar Dica"
			btn.pressed.connect(learn_tip.bind(tip))
			content.add_child(btn)

func _show_message(text: String) -> void:
	print("TV: %s" % text)

func _season_to_offset(season: String) -> int:
	match season:
		"Spring": return 0
		"Summer": return 28
		"Fall": return 56
		"Winter": return 84
		_: return 0

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"current_channel": current_channel,
		"last_watched_day": last_watched_day,
		"watched_shows": watched_shows
	}

func load_save_data(data: Dictionary) -> void:
	current_channel = data.get("current_channel", 0)
	last_watched_day = data.get("last_watched_day", -1)
	watched_shows = data.get("watched_shows", {})