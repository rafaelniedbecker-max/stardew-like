class_name AnimalProducts
extends Node

## Sistema expandido de produtos animais: qualidade, processamento, artesanato

## ==================== PRODUTOS BASE ====================
const ANIMAL_PRODUCTS = {
	# Galinha
	"Chicken": {
		"base": "(O)306",  # Egg
		"large": "(O)307",  # Large Egg
		"brown": "(O)308",  # Brown Egg
		"brown_large": "(O)309",  # Large Brown Egg
		"void": "(O)767",  # Void Egg
		"void_large": "(O)768",  # Large Void Egg
		"produce_time": 1,  # dias
		"quality_factors": ["friendship", "mood", "diet"]
	},
	# Vaca
	"Cow": {
		"base": "(O)306",  # Milk
		"large": "(O)307",  # Large Milk
		"goat": "(O)436",  # Goat Milk
		"goat_large": "(O)437",  # Large Goat Milk
		"produce_time": 1,
		"quality_factors": ["friendship", "mood", "diet", "pregnant"]
	},
	# Ovelha
	"Sheep": {
		"base": "(O)440",  # Wool
		"produce_time": 3,  # dias para regenerar lã
		"quality_factors": ["friendship", "mood", "diet", "sheared_recently"]
	},
	# Porco
	"Pig": {
		"base": "(O)422",  # Truffle
		"produce_time": 1,  # se fora no chão
		"requires_outside": true,
		"quality_factors": ["friendship", "mood", "outside_time"]
	},
	# Coelho
	"Rabbit": {
		"base": "(O)444",  # Rabbit's Foot
		"produce_time": 4,
		"quality_factors": ["friendship", "mood", "diet"]
	},
	# Dinossauro
	"Dinosaur": {
		"base": "(O)107",  # Dinosaur Egg
		"produce_time": 7,
		"quality_factors": ["friendship", "mood"]
	}
}

## ==================== PROCESSAMENTO ARTESANAL ====================
const ARTISAN_PRODUCTS = {
	# Laticínios
	"(O)306": {  # Milk
		"cheese": "(O)424",  # Cheese
		"cheese_time": 200,  # minutos in-game
		"cheese_value_mult": 2.5,
		"yogurt": "(O)425",  # Yogurt (se tiver)
	},
	"(O)307": {  # Large Milk
		"cheese": "(O)424",
		"cheese_time": 200,
		"cheese_value_mult": 3.0,
		"quality_boost": 1  # Quality cheese
	},
	"(O)436": {  # Goat Milk
		"cheese": "(O)426",  # Goat Cheese
		"cheese_time": 200,
		"cheese_value_mult": 2.5
	},
	"(O)437": {  # Large Goat Milk
		"cheese": "(O)426",
		"cheese_time": 200,
		"cheese_value_mult": 3.0,
		"quality_boost": 1
	},
	# Ovos
	"(O)306": {  # Egg
		"mayo": "(O)306",  # Mayonnaise (mesmo ID? No Stardew é diferente)
		"mayo_time": 180,
		"mayo_value_mult": 3.0
	},
	"(O)307": {  # Large Egg
		"mayo": "(O)306",
		"mayo_time": 180,
		"mayo_value_mult": 4.0,
		"quality_boost": 1
	},
	"(O)308": {  # Brown Egg
		"mayo": "(O)306",
		"mayo_time": 180,
		"mayo_value_mult": 3.0
	},
	"(O)309": {  # Large Brown Egg
		"mayo": "(O)306",
		"mayo_time": 180,
		"mayo_value_mult": 4.0,
		"quality_boost": 1
	},
	"(O)767": {  # Void Egg
		"mayo": "(O)769",  # Void Mayo
		"mayo_time": 180,
		"mayo_value_mult": 5.0
	},
	# Lã
	"(O)440": {  # Wool
		"cloth": "(O)428",  # Cloth
		"cloth_time": 240,
		"cloth_value_mult": 3.0
	},
	# Pelo de coelho
	"(O)444": {  # Rabbit's Foot
		"cloth": "(O)428",  # Não faz cloth, é item único
	},
	# Trufas
	"(O)422": {  # Truffle
		"oil": "(O)425",  # Truffle Oil
		"oil_time": 360,  # 6 horas
		"oil_value_mult": 6.0
	}
}

## ==================== QUALIDADE DE PRODUTOS ====================
func calculate_product_quality(animal_type: String, base_quality: int, factors: Dictionary) -> int:
	"""
	factors = {
		"friendship": 0-1000,
		"mood": 0-255,
		"diet": "hay" | "grass" | "mixed",
		"outside_time": 0.0-1.0,
		"pregnant": bool,
		"sheared_recently": bool
	}
	"""
	var base_chance = 0.0

	# Amizade (0-1000) -> 0.0-0.5
	base_chance += (factors.get("friendship", 0) / 1000.0) * 0.5

	# Humor (0-255) -> 0.0-0.3
	base_chance += (factors.get("mood", 0) / 255.0) * 0.3

	# Dieta
	var diet = factors.get("diet", "hay")
	if diet == "grass":
		base_chance += 0.1
	elif diet == "mixed":
		base_chance += 0.05

	# Tempo fora
	base_chance += factors.get("outside_time", 0.0) * 0.1

	# Gravidez (vacas/ovelhas)
	if factors.get("pregnant", false):
		base_chance += 0.15

	# Tosquia recente (ovelhas)
	if factors.get("sheared_recently", false):
		base_chance += 0.1

	# Profissão Artisan (level 10 farming)
	if GameManager and GameManager.professions.get("Farming") == 1:
		base_chance += 0.2

	# Sorte diária
	base_chance += (GameManager.daily_luck + 0.1) * 0.5 if GameManager else 0

	# Determina qualidade
	if base_chance > 0.95: return 3  # Irídio
	elif base_chance > 0.75: return 2  # Ouro
	elif base_chance > 0.5: return 1  # Prata
	return 0  # Normal

## ==================== PRODUÇÃO ARTESANAL ====================
func process_artisan(input_item_id: String, machine_type: String, input_quality: int) -> Dictionary:
	"""
	Retorna {output_item_id, output_quality, processing_time, value_multiplier}
	"""
	machine_data = _get_machine_data(machine_type)
	if not machine_data:
		return {}

	var recipe = machine_data.recipes.get(input_item_id)
	if not recipe:
		return {}

	var output_item = recipe.output
	var base_time = recipe.time
	var value_mult = recipe.value_mult
	var quality_boost = recipe.get("quality_boost", 0)

	# Qualidade do output
	var output_quality = min(3, input_quality + quality_boost)

	# Profissão Artisan
	var artisan_boost = 0
	if GameManager and GameManager.professions.get("Farming") == 1:
		artisan_boost = 0.5
		value_mult *= 1.5

	# Chance de qualidade extra
	var quality_chance = 0.0
	quality_chance += (GameManager.daily_luck + 0.1) * 0.5 if GameManager else 0
	quality_chance += artisan_boost * 0.3

	if randf() < quality_chance:
		output_quality = min(3, output_quality + 1)

	return {
		"output_item": output_item,
		"output_quality": output_quality,
		"processing_time": base_time,
		"value_multiplier": value_mult
	}

func _get_machine_data(machine_type: String) -> Dictionary:
	match machine_type:
		"Cheese Press":
			return {
				"recipes": {
					"(O)306": {"output": "(O)424", "time": 200, "value_mult": 2.5},
					"(O)307": {"output": "(O)424", "time": 200, "value_mult": 3.0, "quality_boost": 1},
					"(O)436": {"output": "(O)426", "time": 200, "value_mult": 2.5},
					"(O)437": {"output": "(O)426", "time": 200, "value_mult": 3.0, "quality_boost": 1}
				}
			}
		"Mayonnaise Machine":
			return {
				"recipes": {
					"(O)306": {"output": "(O)306", "time": 180, "value_mult": 3.0},
					"(O)307": {"output": "(O)306", "time": 180, "value_mult": 4.0, "quality_boost": 1},
					"(O)308": {"output": "(O)306", "time": 180, "value_mult": 3.0},
					"(O)309": {"output": "(O)306", "time": 180, "value_mult": 4.0, "quality_boost": 1},
					"(O)767": {"output": "(O)769", "time": 180, "value_mult": 5.0}  # Void Mayo
				}
			}
		"Loom":
			return {
				"recipes": {
					"(O)440": {"output": "(O)428", "time": 240, "value_mult": 3.0},  # Wool -> Cloth
					"(O)444": {"output": "(O)428", "time": 240, "value_mult": 2.0}   # Rabbit's Foot -> Cloth
				}
			}
		"Oil Maker":
			return {
				"recipes": {
					"(O)422": {"output": "(O)425", "time": 360, "value_mult": 6.0},  # Truffle -> Truffle Oil
					"(O)424": {"output": "(O)425", "time": 120, "value_mult": 2.0},  # Cheese -> Oil
					"(O)426": {"output": "(O)425", "time": 120, "value_mult": 2.0},  # Goat Cheese -> Oil
					"(O)306": {"output": "(O)425", "time": 100, "value_mult": 1.5},  # Milk -> Oil
					"(O)307": {"output": "(O)425", "time": 100, "value_mult": 2.0}   # Large Milk -> Oil
				}
			}
		"Keg":
			return {
				"recipes": {
					# Frutas -> Vinho
					"(O)428": {"output": "(O)348", "time": 6000, "value_mult": 3.0},  # Fruit -> Wine
					# Vegetais -> Suco
					"(O)216": {"output": "(O)350", "time": 4000, "value_mult": 2.5},
					# Mel -> Met
					"(O)340": {"output": "(O)346", "time": 6000, "value_mult": 3.0},
					# Trigo -> Cerveja
					"(O)236": {"output": "(O)348", "time": 4000, "value_mult": 2.5},
					# Café -> Café
					"(O)432": {"output": "(O)433", "time": 2000, "value_mult": 2.0}
				}
			}
		"Preserves Jar":
			return {
				"recipes": {
					# Frutas -> Geleia
					"(O)428": {"output": "(O)344", "time": 4000, "value_mult": 2.0},
					# Vegetais -> Picles
					"(O)216": {"output": "(O)344", "time": 4000, "value_mult": 2.0},
					# Peixes -> Conserva
					"(O)152": {"output": "(O)390", "time": 6000, "value_mult": 1.5},
					# Forrageamento -> Conserva
					"(O)16": {"output": "(O)344", "time": 4000, "value_mult": 1.5}
				}
			}
	return {}

## ==================== VALOR FINAL ====================
func calculate_final_value(base_item_id: String, quality: Int, artisan_type: String = "") -> int:
	var item = DataLoader.get_item(base_item_id)
	if not item:
		return 0

	var base_price = item.price
	var quality_mult = [1.0, 1.25, 1.5, 2.0][quality] if quality < 4 else 1.0

	var artisan_mult = 1.0
	if artisan_type != "":
		var machine_data = _get_machine_data(artisan_type)
		if machine_data:
			var recipe = machine_data.recipes.get(base_item_id, {})
			artisan_mult = recipe.get("value_mult", 1.0)

	# Profissão Artisan
	if GameManager and GameManager.professions.get("Farming") == 1:
		artisan_mult *= 1.5

	return int(base_price * quality_mult * artisan_mult)

## ==================== PRODUÇÃO DIÁRIA ESPERADA ====================
func get_expected_daily_income(animal_type: String, count: int, avg_friendship: int, avg_mood: int) -> int:
	var data = ANIMAL_PRODUCTS.get(animal_type, {})
	if not data:
		return 0

	var base_item = data.base
	var produce_time = data.produce_time
	var daily_per_animal = 1.0 / produce_time

	var factors = {
		"friendship": avg_friendship,
		"mood": avg_mood,
		"diet": "mixed",
		"outside_time": 0.5
	}

	var avg_quality = calculate_product_quality(animal_type, 0, factors)
	var base_item_data = DataLoader.get_item(base_item)
	var base_price = base_item_data?.price ?? 0

	var quality_mult = [1.0, 1.25, 1.5, 2.0][avg_quality] if avg_quality < 4 else 1.0

	return int(count * daily_per_animal * base_price * quality_mult)