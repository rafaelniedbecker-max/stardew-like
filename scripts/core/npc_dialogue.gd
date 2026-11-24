class_name NPCDialogue
extends Node

## Sistema expandido de diálogos NPC: variedade, contexto, eventos

## Templates de diálogo por contexto
const DIALOGUE_TEMPLATES = {
	# Saudações genéricas por hora
	"greeting_morning": [
		"Bom dia, {player}! Dormiu bem?",
		"Ah, {player}! Um novo dia, novas oportunidades!",
		"Bom dia! O tempo está {weather} hoje, não acha?",
		"Ei {player}, vai começar cedo hoje?",
		"Bom dia! Espero que tenha energia para hoje."
	],
	"greeting_afternoon": [
		"Boa tarde, {player}! Como vai a fazenda?",
		"Oi {player}, já almoçou?",
		"Boa tarde! O dia está {weather}.",
		"E aí, {player}, tudo bem por aqui?"
	],
	"greeting_evening": [
		"Boa noite, {player}. Dia longo, hein?",
		"Já vai tarde, {player}. Cuidado no caminho de volta.",
		"Boa noite! Amanhã é um novo dia.",
		"Oi {player}, vai ficar acordado até tarde?"
	],

	# Por amizade (corações)
	"friendship_0": [  # 0 corações
		"Oh, oi. *volta ao que fazia*",
		"Posso te ajudar? ... Ah, não importa.",
		"Você é o novo fazendeiro, certo? Legal."
	],
	"friendship_1": [  # 1 coração
		"Oi {player}! A cidade está movimentada hoje.",
		"Bom te ver por aqui. Como vão as coisas?",
		"Você tem jeito para isso, hein?"
	],
	"friendship_2": [  # 2 corações
		"{player}! Que bom te ver!",
		"Sabe, acho que estamos ficando amigos.",
		"Se precisar de algo, é só falar."
	],
	"friendship_3": [  # 3 corações
		"Ei {player}! Quer vir aqui em casa depois?",
		"Adoro quando você passa por aqui.",
		"Você é uma pessoa muito legal, {player}."
	],
	"friendship_4": [  # 4 corações
		"{player}... fico feliz que veio me ver.",
		"Às vezes penso em como era antes de você chegar. Melhor agora.",
		"Você significa muito para mim."
	],
	"friendship_5": [  # 5 corações
		"*sorri* Oi, {player}. Hoje o dia ficou melhor.",
		"Não sei o que faria sem você por perto.",
		"Você ilumina este lugar, {player}."
	],
	"friendship_6": [  # 6 corações
		"{player}... tem um minuto? Quero te mostrar algo.",
		"Nossa amizade significa o mundo para mim.",
		"Espero que saiba o quão especial você é."
	],
	"friendship_7": [  # 7 corações
		"Meu coração acelera quando te vejo, {player}.",
		"Você é a melhor coisa que me aconteceu ultimamente.",
		"Às vezes me pego pensando em você..."
	],
	"friendship_8": [  # 8 corações (namoro)
		"Meu amor, que surpresa boa te ver!",
		"Cada dia com você é um presente.",
		"Te amo, {player}. Simples assim."
	],
	"friendship_9": [  # 9 corações
		"Meu querido(a) {player}...",
		"Quero envelhecer ao seu lado.",
		"Você é meu lar."
	],
	"friendship_10": [  # 10 corações (casado)
		"Bom dia, amor! Dormiu bem?",
		"O jantar está quase pronto, querido(a).",
		"Te amo mais a cada dia, {player}."
	],

	# Por estação
	"seasonal_spring": [
		"A primavera chegou! Hora de plantar!",
		"Adoro o cheiro de flores no ar.",
		"As cerejeiras estão lindas este ano."
	],
	"seasonal_summer": [
		"Que calor! Vou na praia depois.",
		"Verão é minha estação favorita. E a sua?",
		"Tomara que não chova muito nos festivais."
	],
	"seasonal_fall": [
		"Outono... as folhas estão tão bonitas.",
		"Hora da colheita! Minha época favorita.",
		"O festival da abóbora vem aí, animado?"
	],
	"seasonal_winter": [
		"Brrr, que frio! Vamos pescar no gelo?",
		"Inverno é tranquilo. Gosto da calmaria.",
		"O festival da luz está chegando!"
	],

	# Por clima
	"weather_rain": [
		"Que chuva boa! Minhas plantas agradecem.",
		"Dias de chuva são perfeitos para ficar em casa.",
		"Espero que não vire tempestade."
	],
	"weather_storm": [
		"Uma tempestade! Melhor ficar dentro de casa.",
		"Relâmpagos... sempre me assustam um pouco.",
		"Pelo menos não preciso regar hoje."
	],
	"weather_snow": [
		"Neve! Tão bonito... e frio.",
		"Cuidado para não escorregar no gelo!",
		"Quer fazer um boneco de neve depois?"
	],
	"weather_sunny": [
		"Dia lindo! Perfeito para trabalhar fora.",
		"O sol está forte hoje. Não esqueça de beber água.",
		"Dias assim me dão energia!"
	],

	# Específicos por NPC (exemplos)
	"npc_specific": {
		"Abigail": {
			"hobby": [
				"Jogou algum jogo legal ultimamente?",
				"Estou no nível 50 em *Journey of the Prairie King*!",
				"Quer vir jogar no meu quarto depois?"
			],
			"gift_love": "Amethyst! Minha favorita! Onde conseguiu?",
			"gift_like": "Legal, obrigada! Vou guardar com carinho."
		},
		"Sebastian": {
			"hobby": [
				"Vou programar um novo mod hoje.",
				"Minha moto precisa de uns ajustes...",
				"Já leu o novo livro do Marlon?"
			],
			"gift_love": "Obsidian... como você sabia?",
			"gift_like": "Obrigado. Vou dar bom uso."
		},
		"Leah": {
			"hobby": [
				"Estou trabalhando numa escultura nova.",
				"A natureza me inspira tanto...",
				"Quer ver meu ateliê?"
			],
			"gift_love": "Salad! Feito com ingredientes frescos!",
			"gift_like": "Que gentil da sua parte."
		}
	},

	# Eventos especiais
	"birthday": [
		"FELIZ ANIVERSÁRIO, {player}!!! 🎉",
		"Parabéns! Espero que seu dia seja incrível!",
		"Feliz aniversário! Tem bolo na festa!"
	],
	"festival": [
		"Viu a decoração do festival? Ficou linda!",
		"Vai participar das competições?",
		"Festival é a melhor época do ano!"
	],
	"heart_event": [
		"{player}... posso falar com você um minuto?",
		"Tenho algo importante para te contar...",
		"Não conte para ninguém, mas..."
	],

	# Despedidas
	"goodbye": [
		"Até mais, {player}!",
		"Tchau! Cuide-se!",
		"Nos vemos por aí!",
		"Foi bom conversar. Até!"
	]
}

## ==================== GERADOR DE DIÁLOGO ====================
static func get_dialogue(npc_name: String, context: String, player_name: String = "Jogador", extra: Dictionary = {}) -> String:
	var templates = DIALOGUE_TEMPLATES.get(context, [])
	if templates.is_empty():
		# Fallback genérico
		return "Oi, {player}!".format({"player": player_name})

	var dialogue = templates.pick_random()

	# Substitui placeholders
	dialogue = dialogue.format({
		"player": player_name,
		"weather": _get_weather_text(extra.get("weather", 0)),
		"season": _get_season_text(extra.get("season", 0)),
		"npc": npc_name
	})

	# Chance de adicionar diálogo específico do NPC
	if context == "friendship_2" or context == "friendship_3" or context == "friendship_4":
		var specific = DIALOGUE_TEMPLATES.npc_specific.get(npc_name, {})
		var hobby_lines = specific.get("hobby", [])
		if hobby_lines and randf() < 0.3:
			dialogue += "\n\n" + hobby_lines.pick_random()

	return dialogue

static func _get_weather_text(weather: int) -> String:
	match weather:
		0: return "ensolarado"
		1: return "chuvoso"
		2: return "tempestuoso"
		3: return "nevando"
		4: return "chuva verde"
		_: return "normal"

static func _get_season_text(season: int) -> String:
	match season:
		0: return "Primavera"
		1: return "Verão"
		2: return "Outono"
		3: return "Inverno"
		_: return ""

## ==================== DIÁLOGOS COM ESCOLHAS ====================
static func get_choice_dialogue(npc_name: String, situation: String) -> Dictionary:
	match situation:
		"ask_out":  # Convidar para festival
			return {
				"text": "Ei {player}, o festival é amanhã... quer ir junto?".format({"player": GameManager.player_name if GameManager else "Jogador"}),
				"choices": [
					{"text": "Claro! Adoraria.", "affection": 50, "response": "Sério?! Que legal! Nos encontramos lá!"},
					{"text": "Talvez...", "affection": 10, "response": "Ah... tudo bem. Sem pressão."},
					{"text": "Não, obrigado.", "affection": -20, "response": "Ah... entendi. Tudo bem."}
				]
			}
		"give_gift":
			return {
				"text": "Tem isso para você!",
				"choices": [
					{"text": "Dar presente", "action": "gift"},
					{"text": "Cancelar", "action": "cancel"}
				]
			}
		"propose_marriage":
			return {
				"text": "{player}... eu te amo. Quer se casar comigo?".format({"player": GameManager.player_name if GameManager else "Jogador"}),
				"choices": [
					{"text": "Sim! Mil vezes sim!", "affection": 500, "response": "*lágrimas de felicidade* Sim! Sim! Sim!"},
					{"text": "Não agora...", "affection": -200, "response": "*olhos baixos* Eu... entendo. Desculpa."}
				]
			}
		"heart_event_2":  # 2 corações - convite casa
			return {
				"text": "Ei {player}, quer vir aqui em casa tomar um chá?".format({"player": GameManager.player_name if GameManager else "Jogador"}),
				"choices": [
					{"text": "Adoraria!", "affection": 30, "response": "Ótimo! Venha quando quiser."},
					{"text": "Outra hora.", "affection": 0, "response": "Sem problemas. Fica para a próxima."}
				]
			}
		"heart_event_4":  # 4 corações - segredo
			return {
				"text": "{player}... posso te contar um segredo?".format({"player": GameManager.player_name if GameManager else "Jogador"}),
				"choices": [
					{"text": "Claro, confio em você.", "affection": 50, "response": "*sussurra* Às vezes eu..."},
					{"text": "Prefiro não saber.", "affection": -10, "response": "Ah... tudo bem. Entendo."}
				]
			}
		"heart_event_6":  # 6 corações - momento romântico
			return {
				"text": "{player}... você é muito especial para mim.".format({"player": GameManager.player_name if GameManager else "Jogador"}),
				"choices": [
					{"text": "Você também.", "affection": 100, "response": "*sorri* Fico feliz em ouvir isso."},
					{"text": "Somos bons amigos.", "affection": 20, "response": "É... amigos. Claro."}
				]
			}
		"heart_event_8":  # 8 corações - bouquet
			return {
				"text": "{player}, eu te amo. Quer namorar comigo?".format({"player": GameManager.player_name if GameManager else "Jogador"}),
				"choices": [
					{"text": "Sim! Adoraria!", "affection": 250, "response": "*coração dispara* Sério?! Que felicidade!"},
					{"text": "Sinto muito...", "affection": -100, "response": "*olhos marejados* Ah... tudo bem. Desculpa por ter perguntado."}
				]
			}
		"heart_event_10":  # 10 corações - casamento
			return {
				"text": "{player}... quero passar o resto da vida com você. Casa comigo?".format({"player": GameManager.player_name if GameManager else "Jogador"}),
				"choices": [
					{"text": "Sim! Para sempre!", "affection": 500, "response": "*chorando de felicidade* Sim! Sim! Sim!"},
					{"text": "Não posso...", "affection": -200, "response": "*triste* Eu... entendo. Vou respeitar."}
				]
			}
	return {}

## ==================== REAÇÕES A PRESENTES ====================
static func get_gift_reaction(npc_name: String, item_id: String, taste: String, player_name: String) -> String:
	# taste: "love", "like", "neutral", "dislike", "hate"
	var item = DataLoader.get_item(item_id)
	var item_name = item?.display_name ?? item_id

	var specific = DIALOGUE_TEMPLATES.npc_specific.get(npc_name, {})
	var reactions = specific.get("gift_" + taste, [])

	match taste:
		"love":
			if reactions and randf() < 0.7:
				return reactions.pick_random().format({"player": player_name, "item": item_name})
			return _get_generic_love(item_name, npc_name).format({"player": player_name})
		"like":
			if reactions and randf() < 0.7:
				return reactions.pick_random().format({"player": player_name, "item": item_name})
			return _get_generic_like(item_name, npc_name).format({"player": player_name})
		"neutral":
			return _get_generic_neutral(item_name, npc_name).format({"player": player_name})
		"dislike":
			return _get_generic_dislike(item_name, npc_name).format({"player": player_name})
		"hate":
			return _get_generic_hate(item_name, npc_name).format({"player": player_name})
	return "Obrigado, {player}.".format({"player": player_name})

static func _get_generic_love(item: String, npc: String) -> String:
	var lines = [
		"{player}, você me deu {item}! É minha coisa favorita no mundo! ❤️",
		"{item}!!! *olhos brilham* Como você sabia? Te amo, {player}!",
		"Meu deus, {item}! Você é a melhor pessoa que existe, {player}!",
		"{item}... *quase chora* Isso significa tanto para mim, {player}."
	]
	return lines.pick_random()

static func _get_generic_like(item: String, npc: String) -> String:
	var lines = [
		"Obrigado, {player}! {item} é bem legal.",
		"Legal, {player}! Vou aproveitar este {item}.",
		"Que gentil, {player}. Gosto de {item}.",
		"Obrigado! {item} vai ser útil."
	]
	return lines.pick_random()

static func _get_generic_neutral(item: String, npc: String) -> String:
	var lines = [
		"Hm, {item}. Obrigado, {player}.",
		"Ok... {item}. Valeu, acho.",
		"{player} me deu {item}. Interessante."
	]
	return lines.pick_random()

static func _get_generic_dislike(item: String, npc: String) -> String:
	var lines = [
		"Ah... {item}. Bem, a intenção conta, {player}.",
		"{item} não é bem minha praia... mas obrigado, {player}.",
		"É... {item}. *força sorriso* Valeu, {player}."
	]
	return lines.pick_random()

static func _get_generic_hate(item: String, npc: String) -> String:
	var lines = [
		"{player}... você sabe que eu ODEIO {item}, certo?",
		"*faz cara de nojo* {item}? Sério, {player}?",
		"Por que você me daria {item}?! Eu detesto isso!"
	]
	return lines.pick_random()

## ==================== DIÁLOGOS CONTEXTUAIS EXTRAS ====================
static func get_contextual_dialogue(npc_name: String, situation: String, player_name: String) -> String:
	match situation:
		"player_fainted":
			return "Meu deus, {player}! Você desmaiou! Cuidado da próxima vez!".format({"player": player_name})
		"player_exhausted":
			return "Você parece exausto, {player}. Vai dormir cedo hoje, tá?".format({"player": player_name})
		"first_meeting":
			return "Oi! Você deve ser o novo fazendeiro. Sou {npc}. Bem-vindo a Pelican Town!".format({"npc": npc_name})
		"after_festival_win":
			return "Parabéns por ganhar no festival, {player}! Arrasou!".format({"player": player_name})
		"after_festival_lose":
			return "Não ficou triste, {player}. Participar já é legal!".format({"player": player_name})
		"rain_tomorrow":
			return "Vai chover amanhã, {player}. Bom para as plantas!".format({"player": player_name})
		"storm_tomorrow":
			return "Tempestade amanhã! Cuidado com os relâmpagos, {player}!".format({"player": player_name})
	return ""

## ==================== AGENDA EXPANDIDA ====================
# Retorna agenda baseada em dia da semana, estação, clima, relacionamento
static func generate_schedule(npc_data: NPCData, weekday: int, season: int, weather: int, friendship: int) -> Dictionary:
	var schedule = npc_data.get_schedule_for_day(weekday)
	if schedule == "":
		schedule = _get_default_schedule(npc_data, weekday, season, weather, friendship)
	return _parse_schedule(schedule)

static func _get_default_schedule(npc_data: NPCData, weekday: int, season: int, weather: int, friendship: int) -> String:
	var home = npc_data.home_region
	var name = npc_data.internal_name

	# Agendas base por região
	var base_schedules = {
		"Town": {
			0: "9:00 Home 12:00 Saloon 18:00 Home 22:00 Sleep",  # Monday
			1: "9:00 Home 12:00 Library 17:00 Home 22:00 Sleep",
			2: "9:00 Home 12:00 Museum 17:00 Home 22:00 Sleep",
			3: "9:00 Home 12:00 Saloon 18:00 Home 22:00 Sleep",
			4: "9:00 Home 12:00 Park 17:00 Home 22:00 Sleep",
			5: "10:00 Home 13:00 Saloon 20:00 Home 23:00 Sleep",  # Saturday
			6: "10:00 Home 14:00 Church 18:00 Home 22:00 Sleep"   # Sunday
		},
		"Farm": {
			0: "6:00 Home 8:00 Farm 12:00 Home 17:00 Home 21:00 Sleep",
			1: "6:00 Home 8:00 Farm 12:00 Home 17:00 Home 21:00 Sleep",
			2: "6:00 Home 8:00 Farm 12:00 Home 17:00 Home 21:00 Sleep",
			3: "6:00 Home 8:00 Farm 12:00 Home 17:00 Home 21:00 Sleep",
			4: "6:00 Home 8:00 Farm 12:00 Home 17:00 Home 21:00 Sleep",
			5: "7:00 Home 10:00 Town 18:00 Home 22:00 Sleep",
			6: "8:00 Home 12:00 Home 20:00 Sleep"
		}
	}

	var region_sched = base_schedules.get(home, base_schedules["Town"])
	var base = region_sched.get(weekday, region_sched[0])

	# Modificadores por clima
	if weather == 1 or weather == 2:  # Chuva/Tempestade
		base = base.replace("Park", "Home").replace("Farm", "Home").replace("Beach", "Home")

	# Modificadores por amizade alta
	if friendship > 750:
		# Adiciona chance de visitar o jogador
		if randf() < 0.2:
			base += " 15:00 Farm_Player"

	return base

static func _parse_schedule(schedule_str: String) -> Dictionary:
	var result = {}
	var parts = schedule_str.split(" ")
	for part in parts:
		if ":" in part:
			var time_parts = part.split(":")
			var hour = time_parts[0].to_int()
			var minute = time_parts[1].to_int() if time_parts.size() > 1 else 0
			var location = ""
			# Próxima parte é localização
	# Simplificado - retorna string original para NPC.parse_schedule
	return {"raw": schedule_str}