class_name PetExtended
extends Node

## Sistema Expandido de Pets: múltiplos pets, raças, personalidades, interações avançadas

## ==================== TIPOS DE PET ===
const PET_TYPES = {
	"Cat": {
		"name": "Gato",
		"base_cost": 1000,
		"personalities": ["Lazy", "Playful", "Hunter", "Affectionate", "Independent"],
		"sounds": ["meow", "purr", "hiss"],
		"animations": ["idle", "walk", "sleep", "sit", "stretch", "groom", "play", "hunt"],
		"favorite_toys": ["(O)771", "(O)772"],  # Cat toys
		"favorite_treats": ["(O)152", "(O)154"],  # Fish
		"sleep_hours": [22, 6],  # Noite
		"hunt_chance": 0.1,  # Chance de trazer presente
		"hunt_loot": ["(O)152", "(O)154", "(O)388", "(O)422"]  # Fish, quartz, truffle
	},
	"Dog": {
		"name": "Cachorro",
		"base_cost": 1000,
		"personalities": ["Loyal", "Energetic", "Protective", "Playful", "Lazy"],
		"sounds": ["bark", "whine", "pant", "growl"],
		"animations": ["idle", "walk", "run", "sit", "lay", "fetch", "dig", "beg"],
		"favorite_toys": ["(O)773", "(O)774"],  # Dog toys
		"favorite_treats": ["(O)432", "(O)433"],  # Pet food
		"sleep_hours": [22, 7],
		"hunt_chance": 0.05,
		"hunt_loot": ["(O)388", "(O)390", "(O)422", "(O)107"]  # Bones, truffle, dino egg
	},
	"Turtle": {
		"name": "Tartaruga",
		"base_cost": 5000,
		"personalities": ["Slow", "Curious", "Shy", "Ancient"],
		"sounds": ["hiss"],
		"animations": ["idle", "walk", "swim", "hide", "bask"],
		"favorite_treats": ["(O)216", "(O)218"],  # Veggies
		"sleep_hours": [20, 8],
		"hunt_chance": 0.0,
		"special": "carries_items"  # Pode carregar itens na carapaça
	},
	"Rabbit": {
		"name": "Coelho",
		"base_cost": 2000,
		"personalities": ["Skittish", "Curious", "Hungry", "Social"],
		"sounds": ["squeak", "thump"],
		"animations": ["idle", "hop", "sniff", "binky", "groom", "dig"],
		"favorite_treats": ["(O)216", "(O)218", "(O)220"],  # Carrot, etc.
		"sleep_hours": [23, 5],
		"hunt_chance": 0.0,
		"special": "breeds_fast"  # Reproduz rápido
	},
	"Bird": {
		"name": "Pássaro",
		"base_cost": 3000,
		"personalities": ["Chatty", "Musical", "Curious", "Messy"],
		"sounds": ["chirp", "sing", "squawk", "whistle"],
		"animations": ["idle", "fly", "perch", "preen", "bathe", "dance"],
		"favorite_treats": ["(O)432", "(O)433"],  # Seeds
		"sleep_hours": [20, 6],
		"hunt_chance": 0.02,
		"hunt_loot": ["(O)388", "(O)390", "(O)114"],  # Feathers, prismatic
		"special": "sings"  # Canta de manhã
	},
	"Lizard": {
		"name": "Lagarto",
		"base_cost": 4000,
		"personalities": ["Basker", "Hunter", "Territorial", "Calm"],
		"sounds": ["hiss", "click"],
		"animations": ["idle", "walk", "climb", "bask", "tongue_flick"],
		"favorite_treats": ["(O)152", "(O)154"],  # Insects/fish
		"sleep_hours": [21, 7],
		"hunt_chance": 0.05,
		"hunt_loot": ["(O)388", "(O)422"],
		"special": "climbs_walls"
	}
}

## ==================== PERSONALIDADES ===
const PERSONALITY_TRAITS = {
	"Lazy": {
		"activity_modifier": 0.5,
		"sleep_extra": 2,
		"play_reluctance": 0.8,
		"affection_gain": 0.8,
		"description": "Prefere dormir a brincar"
	},
	"Playful": {
		"activity_modifier": 1.5,
		"sleep_extra": -1,
		"play_reluctance": 0.2,
		"affection_gain": 1.2,
		"description": "Adora brincar o dia todo"
	},
	"Hunter": {
		"activity_modifier": 1.2,
		"hunt_chance_bonus": 0.15,
		"description": "Exímio caçador, traz presentes"
	},
	"Affectionate": {
		"activity_modifier": 1.0,
		"affection_gain": 1.5,
		"follow_distance": 0.5,
		"description": "Adora carinho e fica perto de você"
	},
	"Independent": {
		"activity_modifier": 1.0,
		"affection_gain": 0.6,
		"follow_distance": 2.0,
		"description": "Gosta do seu espaço"
	},
	"Loyal": {
		"activity_modifier": 1.1,
		"affection_gain": 1.3,
		"follow_distance": 0.3,
		"protect_chance": 0.1,
		"description": "Sempre ao seu lado, te protege"
	},
	"Energetic": {
		"activity_modifier": 1.4,
		"sleep_extra": -2,
		"play_reluctance": 0.1,
		"description": "Energia infinita!"
	},
	"Protective": {
		"activity_modifier": 1.0,
		"protect_chance": 0.2,
		"description": "Avisa de perigos e defende você"
	},
	"Shy": {
		"activity_modifier": 0.7,
		"affection_gain": 0.5,
		"hide_chance": 0.3,
		"description": "Tímido, precisa de paciência"
	},
	"Curious": {
		"activity_modifier": 1.3,
		"explore_range": 2.0,
		"description": "Explora tudo, encontra coisas"
	},
	"Hungry": {
		"activity_modifier": 1.1,
		"food_consumption": 1.5,
		"description": "Sempre com fome"
	},
	"Social": {
		"activity_modifier": 1.0,
		"group_play": true,
		"description": "Gosta de companhia"
	},
	"Ancient": {
		"activity_modifier": 0.3,
		"wisdom_bonus": 0.2,
		"description": "Viveu muito, sabe segredos"
	},
	"Skittish": {
		"activity_modifier": 1.2,
		"flee_chance": 0.5,
		"description": "Assusta fácil, foge rápido"
	},
	"Hungry": {
		"activity_modifier": 1.1,
		"food_consumption": 1.5,
		"description": "Sempre com fome"
	},
	"Musical": {
		"activity_modifier": 1.0,
		"sing_chance": 0.3,
		"description": "Canta belas melodias"
	},
	"Messy": {
		"activity_modifier": 1.0,
		"mess_chance": 0.2,
		"description": "Faz bagunça por onde passa"
	},
	"Basker": {
		"activity_modifier": 0.8,
		"sun_love": true,
		"description": "Adora tomar sol"
	},
	"Territorial": {
		"activity_modifier": 1.0,
		"defend_chance": 0.15,
		"description": "Protege seu território"
	},
	"Calm": {
		"activity_modifier": 0.9,
		"stress_resistance": 0.5,
		"description": "Nada o abala"
	}
}

## ==================== PET DATA ===
class PetData:
	var pet_type: String
	var pet_name: String
	var personality: String
	var breed: String = ""  # Subtipo visual
	var adoption_day: int
	adoption_season: int
	adoption_year: int

	var friendship: int = 0  # 0-1000
	var happiness: int = 100  # 0-100
	var energy: int = 100  # 0-100
	var hunger: int = 0  # 0-100

	var last_pet_day: int = -1
	var last_feed_day: int = -1
	var last_play_day: int = -1
	var last_walk_day: int = -1

	var tricks_learned: Array[String] = []
	var favorite_toy: String = ""
	var favorite_treat: String = ""
	var favorite_spot: Vector2 = Vector2(0, 0)

	var total_pets: int = 0
	var total_feeds: int = 0
	var total_plays: int = 0
	var total_walks: int = 0
	var gifts_brought: int = 0
	var times_slept_on_bed: int = 0

	var is_sick: bool = false
	var sickness_day: int = 0
	var sickness_type: String = ""

	var position: Vector2 = Vector2(0, 0)
	var state: String = "idle"  # idle, follow, sleep, eat, play, sick, explore, hunt

	var home_position: Vector2 = Vector2(0, 0)

## ==================== FUNÇÕES ===
static func create_pet(pet_type: String, name: String = "") -> PetData:
	var pet = PetData.new()
	pet.pet_type = pet_type
	pet.pet_name = name if name != "" else _generate_name(pet_type)
	pet.personality = PET_TYPES[pet_type].personalities.pick_random()
	pet.adoption_day = GameManager.current_day if GameManager else 1
	pet.adoption_season = GameManager.current_season if GameManager else 0
	pet.adoption_year = GameManager.current_year if GameManager else 1
	pet.home_position = Vector2(320, 320)
	pet.position = pet.home_position
	pet.favorite_treat = PET_TYPES[pet_type].favorite_treats.pick_random()
	pet.favorite_toy = PET_TYPES[pet_type].favorite_toys.pick_random()
	return pet

static func _generate_name(pet_type: String) -> String:
	var names = {
		"Cat": ["Whiskers", "Mittens", "Shadow", "Luna", "Oliver", "Simba", "Nala", "Tiger", "Mochi", "Biscuit"],
		"Dog": ["Buster", "Buddy", "Max", "Bella", "Charlie", "Daisy", "Rocky", "Molly", "Cooper", "Luna"],
		"Turtle": ["Sheldon", "Turbo", "Shelly", "Crush", "Squirt"],
		"Rabbit": ["Thumper", "Bugs", "Cottontail", "Hoppy", "Bunny"],
		"Bird": ["Tweety", "Sunny", "Sky", "Chirpy", "Melody"],
		"Lizard": ["Lizzy", "Spike", "Geico", "Rango", "Draco"]
	}
	return names.get(pet_type, ["Pet"]).pick_random()

## ==================== INTERAÇÕES ===
static func pet(pet: PetData) -> Dictionary:
	var result = {"success": false, "message": "", "friendship_gain": 0}

	if pet.last_pet_day == GameManager.current_day:
		result.message = "%s já foi acariciado hoje." % pet.pet_name
		return result

	pet.last_pet_day = GameManager.current_day

	# Base gain
	var base_gain = 12
	var personality = PERSONALITY_TRAITS.get(pet.personality, {})
	var affection_mod = personality.get("affection_gain", 1.0)

	var gain = int(base_gain * affection_mod)
	pet.friendship = min(1000, pet.friendship + gain)
	pet.happiness = min(100, pet.happiness + 5)
	pet.total_pets += 1

	# Chance de reação especial
	var special = _get_special_pet_reaction(pet)

	result.success = true
	result.friendship_gain = gain
	result.message = "%s %s! (+%d ❤️)" % [pet.pet_name, special, gain]

	# Som e partículas
	if AudioManager:
		AudioManager.play_sfx_at_position("res://assets/sfx/pet_%s.ogg" % pet.pet_type.to_lower(), pet.position)

	if ParticleManager:
		ParticleManager.spawn_area("harvest", pet.position, 8, 24.0)

	return result

static func feed(pet: PetData, item_id: String = "") -> Dictionary:
	var result = {"success": false, "message": "", "friendship_gain": 0}

	if pet.last_feed_day == GameManager.current_day:
		result.message = "%s já comeu hoje." % pet.pet_name
		return result

	# Verifica se tem o item
	var treat = item_id if item_id != "" else pet.favorite_treat
	var treat_data = DataLoader.get_item(treat)
	var treat_name = treat_data.display_name if treat_data != null else treat
	if not InventoryManager.has_item(treat):
		result.message = "Você não tem %s!" % treat_name
		return result

	if InventoryManager.remove_item(treat, 1):
		pet.last_feed_day = GameManager.current_day
		pet.hunger = max(0, pet.hunger - 30)
		pet.happiness = min(100, pet.happiness + 10)

		var base_gain = 6
		var personality = PERSONALITY_TRAITS.get(pet.personality, {})
		var affection_mod = personality.get("affection_gain", 1.0)
		var gain = int(base_gain * affection_mod)

		# Bônus se for o petisco favorito
		if treat == pet.favorite_treat:
			gain += 4

		pet.friendship = min(1000, pet.friendship + gain)
		pet.total_feeds += 1

		result.success = true
		result.friendship_gain = gain
		result.message = "%s comeu %s feliz! (+%d ❤️)" % [pet.pet_name, treat_name, gain]

		# Som e partículas
		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/eat.ogg", pet.position)

		if ParticleManager:
			ParticleManager.spawn_area("seed", pet.position, 6, 20.0)

	return result

static func play(pet: PetData, toy_id: String = "") -> Dictionary:
	var result = {"success": false, "message": "", "friendship_gain": 0}

	if pet.last_play_day == GameManager.current_day:
		result.message = "%s já brincou hoje." % pet.pet_name
		return result

	pet.last_play_day = GameManager.current_day

	var toy = toy_id if toy_id != "" else pet.favorite_toy
	var toy_data = DataLoader.get_item(toy)
	var toy_name = toy_data.display_name if toy_data != null else toy
	if not InventoryManager.has_item(toy):
		result.message = "Você não tem %s!" % toy_name
		return result

	if InventoryManager.remove_item(toy, 1):
		pet.happiness = min(100, pet.happiness + 15)
		pet.energy = max(0, pet.energy - 10)

		var base_gain = 10
		var personality = PERSONALITY_TRAITS.get(pet.personality, {})
		var play_mod = personality.get("play_reluctance", 0.5)
		var gain = int(base_gain * (1.0 - play_mod))

		if toy == pet.favorite_toy:
			gain += 5

		pet.friendship = min(1000, pet.friendship + gain)
		pet.total_plays += 1

		# Chance de aprender truque
		if pet.friendship > 500 and randf() < 0.1:
			_learn_trick(pet)

		result.success = true
		result.friendship_gain = gain
		result.message = "Você brincou com %s usando %s! (+%d ❤️)" % [pet.pet_name, toy_name, gain]

		# Som e partículas
		if AudioManager:
			AudioManager.play_sfx_at_position("res://assets/sfx/pet_play.ogg", pet.position)

		if ParticleManager:
			ParticleManager.spawn_area("harvest", pet.position, 10, 32.0)

	return result

static func walk(pet: PetData) -> Dictionary:
	var result = {"success": false, "message": ""}

	if pet.last_walk_day == GameManager.current_day:
		result.message = "%s já passeou hoje." % pet.pet_name
		return result

	pet.last_walk_day = GameManager.current_day
	pet.energy = max(0, pet.energy - 20)
	pet.happiness = min(100, pet.happiness + 20)

	# Chance de encontrar algo
	if randf() < 0.3:
		var loot = _find_walk_loot(pet)
		var loot_data = DataLoader.get_item(loot)
		result.message = "%s encontrou %s durante o passeio!" % [pet.pet_name, loot_data.display_name if loot_data != null else loot]
		InventoryManager.add_item(loot, 1)
	else:
		result.message = "%s gostou do passeio!" % pet.pet_name

	pet.total_walks += 1
	result.success = true
	return result

static func _find_walk_loot(pet: PetData) -> String:
	var pet_type_data = PET_TYPES.get(pet.pet_type, {})
	var loot_table = pet_type_data.get("hunt_loot", ["(O)388"])
	return loot_table.pick_random()

## ==================== CICLO DIÁRIO ===
static func process_daily(pet: PetData) -> void:
	# Reseta contadores diários
	# (last_pet_day, last_feed_day, etc. são verificados por data)

	# Decaimento de necessidades
	pet.hunger = min(100, pet.hunger + 20)
	pet.energy = min(100, pet.energy + 10)  # Recupera energia dormindo
	pet.happiness = max(0, pet.happiness - 5)  # Leve decaimento

	# Doença aleatória
	if not pet.is_sick and randf() < 0.01:
		pet.is_sick = true
		pet.sickness_day = GameManager.current_day
		pet.sickness_type = ["cold", "upset_stomach", "lethargy"].pick_random()
		HUD.show_message("🤒 %s está doente!" % pet.pet_name)

	# Recuperação de doença
	if pet.is_sick:
		var days_sick = GameManager.current_day - pet.sickness_day
		if days_sick >= 3 or (randf() < 0.3 and days_sick >= 1):
			pet.is_sick = false
			pet.sickness_type = ""
			HUD.show_message("%s se recuperou!" % pet.pet_name)

	# Caça (gatos/cães)
	var pet_type_data = PET_TYPES.get(pet.pet_type, {})
	if pet_type_data.get("hunt_chance", 0) > 0 and randf() < pet_type_data.hunt_chance:
		var loot = _find_walk_loot(PetData.new())  # Simplificado
		var loot_data = DataLoader.get_item(loot)
		pet.gifts_brought += 1
		HUD.show_notification("🎁 Presente de %s!" % pet.pet_name, "Trouxe %s!" % (loot_data.display_name if loot_data != null else loot), Color(1.0, 0.8, 0.3))
		InventoryManager.add_item(loot, 1)

	# Presentes de personalidade
	_grant_personality_gifts(pet)

	# Dorme na cama do player
	if randf() < 0.3 and pet.friendship > 500:
		pet.times_slept_on_bed += 1
		HUD.show_message("%s dormiu na sua cama! 💤" % pet.pet_name)

static func _grant_personality_gifts(pet: PetData) -> void:
	var personality = pet.personality
	if personality == "Hunter" and randf() < 0.1:
		var loot = _find_walk_loot(PetData.new())
		var loot_data = DataLoader.get_item(loot)
		InventoryManager.add_item(loot, 1)
		HUD.show_message("%s trouxe %s da caça!" % [pet.pet_name, loot_data.display_name if loot_data != null else loot])
	elif personality == "Curious" and randf() < 0.05:
		var item = ["(O)388", "(O)390", "(O)114", "(O)107"].pick_random()
		var item_data = DataLoader.get_item(item)
		InventoryManager.add_item(item, 1)
		HUD.show_message("%s encontrou %s explorando!" % [pet.pet_name, item_data.display_name if item_data != null else item])
	elif personality == "Musical" and randf() < 0.2:
		HUD.show_message("%s cantou uma bela melodia! 🎵" % pet.pet_name)
		if AudioManager:
			AudioManager.play_sfx("res://assets/sfx/bird_sing.ogg")

## ==================== TRUQUES ===
static func _learn_trick(pet: PetData) -> void:
	var available_tricks = ["sit", "stay", "roll_over", "shake", "high_five", "fetch", "spin", "jump", "play_dead", "speak"]
	var unlearned = []
	for trick in available_tricks:
		if trick not in pet.tricks_learned:
			unlearned.append(trick)

	if unlearned:
		var new_trick = unlearned.pick_random()
		pet.tricks_learned.append(new_trick)
		HUD.show_notification("🎓 Novo Truque!", "%s aprendeu: %s!" % [pet.pet_name, new_trick], Color(1.0, 0.9, 0.3))

		if AudioManager:
			AudioManager.play_sfx("res://assets/sfx/trick_learned.ogg")

## ==================== DOENÇA ===
static func give_medicine(pet: PetData, medicine_id: String) -> bool:
	if not pet.is_sick:
		return false

	if pet.sickness_type == "cold" and medicine_id == "(O)424":  # Cheese = remédio?
		pet.is_sick = false
		pet.sickness_type = ""
		HUD.show_message("%s se curou com o remédio!" % pet.pet_name)
		return true
	elif pet.sickness_type == "upset_stomach" and medicine_id == "(O)306":  # Milk
		pet.is_sick = false
		pet.sickness_type = ""
		HUD.show_message("O leite acalmou o estômago de %s!" % pet.pet_name)
		return true
	elif pet.sickness_type == "lethargy" and medicine_id == "(O)340":  # Honey
		pet.is_sick = false
		pet.sickness_type = ""
		HUD.show_message("O mel deu energia para %s!" % pet.pet_name)
		return true

	return false

## ==================== SERIALIZAÇÃO ===
static func to_dict(pet: PetData) -> Dictionary:
	return {
		"pet_type": pet.pet_type,
		"pet_name": pet.pet_name,
		"personality": pet.personality,
		"breed": pet.breed,
		"adoption_day": pet.adoption_day,
		"adoption_season": pet.adoption_season,
		"adoption_year": pet.adoption_year,
		"friendship": pet.friendship,
		"happiness": pet.happiness,
		"energy": pet.energy,
		"hunger": pet.hunger,
		"last_pet_day": pet.last_pet_day,
		"last_feed_day": pet.last_feed_day,
		"last_play_day": pet.last_play_day,
		"last_walk_day": pet.last_walk_day,
		"tricks_learned": pet.tricks_learned,
		"favorite_toy": pet.favorite_toy,
		"favorite_treat": pet.favorite_treat,
		"favorite_spot": {"x": pet.favorite_spot.x, "y": pet.favorite_spot.y},
		"total_pets": pet.total_pets,
		"total_feeds": pet.total_feeds,
		"total_plays": pet.total_plays,
		"total_walks": pet.total_walks,
		"gifts_brought": pet.gifts_brought,
		"times_slept_on_bed": pet.times_slept_on_bed,
		"is_sick": pet.is_sick,
		"sickness_day": pet.sickness_day,
		"sickness_type": pet.sickness_type,
		"position": {"x": pet.position.x, "y": pet.position.y},
		"state": pet.state,
		"home_position": {"x": pet.home_position.x, "y": pet.home_position.y}
	}

static func from_dict(data: Dictionary) -> PetData:
	var pet = PetData.new()
	pet.pet_type = data.get("pet_type", "Cat")
	pet.pet_name = data.get("pet_name", "Pet")
	pet.personality = data.get("personality", "Lazy")
	pet.breed = data.get("breed", "")
	pet.adoption_day = data.get("adoption_day", 1)
	pet.adoption_season = data.get("adoption_season", 0)
	pet.adoption_year = data.get("adoption_year", 1)
	pet.friendship = data.get("friendship", 0)
	pet.happiness = data.get("happiness", 100)
	pet.energy = data.get("energy", 100)
	pet.hunger = data.get("hunger", 0)
	pet.last_pet_day = data.get("last_pet_day", -1)
	pet.last_feed_day = data.get("last_feed_day", -1)
	pet.last_play_day = data.get("last_play_day", -1)
	pet.last_walk_day = data.get("last_walk_day", -1)
	pet.tricks_learned = data.get("tricks_learned", [])
	pet.favorite_toy = data.get("favorite_toy", "")
	pet.favorite_treat = data.get("favorite_treat", "")
	var spot = data.get("favorite_spot", {})
	pet.favorite_spot = Vector2(spot.get("x", 0), spot.get("y", 0))
	pet.total_pets = data.get("total_pets", 0)
	pet.total_feeds = data.get("total_feeds", 0)
	pet.total_plays = data.get("total_plays", 0)
	pet.total_walks = data.get("total_walks", 0)
	pet.gifts_brought = data.get("gifts_brought", 0)
	pet.times_slept_on_bed = data.get("times_slept_on_bed", 0)
	pet.is_sick = data.get("is_sick", false)
	pet.sickness_day = data.get("sickness_day", 0)
	pet.sickness_type = data.get("sickness_type", "")
	pet.position = Vector2(data.get("position", {}).get("x", 0), data.get("position", {}).get("y", 0))
	pet.state = data.get("state", "idle")
	var home = data.get("home_position", {})
	pet.home_position = Vector2(home.get("x", 0), home.get("y", 0))
	return pet