@tool
class_name NPCData
extends Resource

## Nome interno (chave do JSON)
@export var internal_name: String = ""

## Nome para exibição (chave de localização)
@export var display_name: String = ""

## Estação de aniversário: 0=Spring, 1=Summer, 2=Fall, 3=Winter
@export var birth_season: int = 0

## Dia do aniversário (1-28)
@export var birth_day: int = 1

## Região da casa: "Town", "Farm", "Desert", etc.
@export var home_region: String = "Town"

## Gênero: 0=Male, 1=Female, 2=Undefined
@export var gender: int = 0

## Idade: 1=Child, 2=Teen, 3=Adult
@export var age: int = 3

## Maneira: 0=Polite, 1=Rude, 2=Neutral
@export var manner: int = 2

## Ansiedade social (0-2)
@export var social_anxiety: int = 0

## Otimismo (0-2)
@export var optimism: int = 2

## True se pele escura
@export var is_dark_skinned: bool = false

## True se pode casar
@export var can_be_romanced: bool = false

## Nome do interesse romântico (se houver)
@export var love_interest: String = ""

## ID do calendário para exibição
@export var calendar: int = 0

## ID da aba social
@export var social_tab: int = 0

## True se pode receber presentes
@export var can_receive_gifts: bool = true

## True se cumprimenta NPCs próximos
@export var can_greet_nearby_characters: bool = true

## True se conta para perfeição
@export var perfection_score: bool = true

## ID do slide final (casamento)
@export var end_slide_show: int = 0

## Mudança de amizade por ciúmes do cônjuge
@export var spouse_gift_jealousy_friendship_change: int = -30

## Quartos do cônjuge (dados de mapa)
@export var spouse_room: Dictionary = {}

## Pátio do cônjuge
@export var spouse_patio: Dictionary = {}

## Pisos preferidos do cônjuge
@export var spouse_floors: Array[String] = []

## Papéis de parede preferidos do cônjuge
@export var spouse_wallpapers: Array[String] = []

## Gostos de presentes (Universal + Personais)
## Formato: "Love: 74 446 797" ou "Like: -2 -7 -26"
@export var gift_tastes: Dictionary = {}

## Agenda semanal (chave: dia da semana, valor: string de agenda)
@export var schedule: Dictionary = {}

## Diálogos (chave: situação, valor: array de falas)
@export var dialogues: Dictionary = {}

## Textura base do sprite
@export var texture_path: String = ""

## Retrato para diálogos
@export var portrait_path: String = ""

## Animações do sprite (idle, walk, etc.)
@export var animations: Dictionary = {}

## Retorna nome exibido
func get_display_name() -> String:
	return display_name if display_name != "" else internal_name

## Verifica se é aniversário hoje
func is_birthday_today(current_season: int, current_day: int) -> bool:
	return current_season == birth_season and current_day == birth_day

## Obtém reação a um item (item_id como string)
## Retorna: "Love", "Like", "Neutral", "Dislike", "Hate"
func get_gift_reaction(item_id: String) -> String:
	# Verifica gostos universais primeiro
	var universal_love = gift_tastes.get("Universal_Love", "")
	var universal_like = gift_tastes.get("Universal_Like", "")
	var universal_neutral = gift_tastes.get("Universal_Neutral", "")
	var universal_dislike = gift_tastes.get("Universal_Dislike", "")
	var universal_hate = gift_tastes.get("Universal_Hate", "")

	if item_id in universal_love.split(" "):
		return "Love"
	if item_id in universal_like.split(" "):
		return "Like"
	if item_id in universal_neutral.split(" "):
		return "Neutral"
	if item_id in universal_dislike.split(" "):
		return "Dislike"
	if item_id in universal_hate.split(" "):
		return "Hate"

	# Verifica gostos pessoais
	var personal = gift_tastes.get(internal_name, "")
	if personal == "":
		return "Neutral"

	# Parse: "Love/ItemIDs/Like/ItemIDs/Dislike/ItemIDs/Hate/ItemIDs"
	var parts = personal.split("/")
	var current_category = "Neutral"
	for part in parts:
		if part in ["Love", "Like", "Dislike", "Hate", "Neutral"]:
			current_category = part
		else:
			var ids = part.split(" ")
			if item_id in ids:
				return current_category

	return "Neutral"

## Obtém diálogo de reação a presente
func get_gift_dialogue(item_id: String) -> String:
	var reaction = get_gift_reaction(item_id)
	var personal = gift_tastes.get(internal_name, "")
	if personal == "":
		return ""

	var parts = personal.split("/")
	var current_category = ""
	var current_dialogue = ""

	for part in parts:
		if part in ["Love", "Like", "Dislike", "Hate", "Neutral"]:
			current_category = part
			current_dialogue = ""
		elif current_category == reaction:
			current_dialogue = part
			break

	return current_dialogue

## Verifica se pode casar
func is_marriage_candidate() -> bool:
	return can_be_romanced

## Obtém agenda para um dia da semana (0=Segunda, 6=Domingo)
func get_schedule_for_day(weekday: int) -> String:
	var day_names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
	return schedule.get(day_names[weekday], "")