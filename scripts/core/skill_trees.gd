class_name SkillTrees
extends Node

## Sistema de Árvores de Habilidades: profissões, especializações, talentos

## ==================== PROFISSÕES BASE (NÍVEL 5) ===
const PROFESSIONS = {
	0: {  # Farming
		0: {  # Rancher
			"name": "Criador",
			"description": "Animais produzem bens de maior qualidade. Produtos animais valem +20%.",
			"icon": "🐄",
			"effects": {
				"animal_quality_boost": 0.2,
				"animal_product_value_mult": 1.2
			},
			"level_10_choices": ["Coopmaster", "Shepherd"]
		},
		1: {  # Tiller
			"name": "Agricultor",
			"description": "Culturas valem +10%. Colheita mais rápida.",
			"icon": "🌱",
			"effects": {
				"crop_value_mult": 1.1,
				"growth_speed_mult": 1.05
			},
			"level_10_choices": ["Artisan", "Agriculturist"]
		}
	},
	1: {  # Mining
		0: {  # Miner
			"name": "Minerador",
			"description": "+1 minério extra por veia. Encontra geodas com mais frequência.",
			"icon": "⛏️",
			"effects": {
				"extra_ore_chance": 0.5,
				"geode_chance": 0.2
			},
			"level_10_choices": ["Blacksmith", "Prospector"]
		},
		1: {  # Geologist
			"name": "Geólogo",
			"description": "Geminas aparecem em pares. Chance de geodas dobrada.",
			"icon": "💎",
			"effects": {
				"gem_pair_chance": 1.0,
				"geode_chance": 1.0
			},
			"level_10_choices": ["Excavator", "Gemologist"]
		}
	},
	2: {  # Foraging
		0: {  # Forester
			"name": "Lenhador",
			"description": "Árvores dropam +25% madeira. Chance de madeira dura.",
			"icon": "🌲",
			"effects": {
				"wood_bonus": 0.25,
				"hardwood_chance": 0.1
			},
			"level_10_choices": ["Lumberjack", "Tapper"]
		},
		1: {  # Gatherer
			"name": "Coletor",
			"description": "Chance de item duplo ao forragear. Itens de qualidade superior.",
			"icon": "🌿",
			"effects": {
				"double_forage_chance": 0.2,
				"forage_quality_boost": 0.2
			},
			"level_10_choices": ["Botanist", "Tracker"]
		}
	},
	3: {  # Fishing
		0: {  # Fisher
			"name": "Pescador",
			"description": "Peixes valem +25%. Barra de pesca maior.",
			"icon": "🎣",
			"effects": {
				"fish_value_mult": 1.25,
				"bar_size_mult": 1.15
			},
			"level_10_choices": ["Angler", "Pirate"]
		},
		1: {  # Trapper
			"name": "Armadilhador",
			"description": "Crab pots nunca precisam de isca. Peixes de crab pot valem mais.",
			"icon": "🦀",
			"effects": {
				"crab_pot_no_bait": true,
				"crab_pot_value_mult": 1.5
			},
			"level_10_choices": ["Luremaster", "Mariner"]
		}
	},
	4: {  # Combat
		0: {  # Fighter
			"name": "Lutador",
			"description": "+10% ataque. +15 PV máximos.",
			"icon": "⚔️",
			"effects": {
				"attack_bonus": 0.1,
				"max_health_bonus": 15
			},
			"level_10_choices": ["Brute", "Defender"]
		},
		1: {  # Scout
			"name": "Batedor",
			"description": "+50% chance de crítico. +1 velocidade.",
			"icon": "🏃",
			"effects": {
				"crit_chance": 0.05,
				"speed_bonus": 1.0
			},
			"level_10_choices": ["Acrobat", "Desperado"]
		}
	}
}

## ==================== ESPECIALIZAÇÕES NÍVEL 10 ===
const SPECIALIZATIONS = {
	"Coopmaster": {
		"parent": "Rancher",
		"name": "Mestre do Galinheiro",
		"description": "Incubação instantânea. Amizade com aves +50%/dia. Qualidade de ovos garantida.",
		"icon": "🐔",
		"effects": {
			"instant_incubation": true,
			"bird_friendship_mult": 1.5,
			"egg_quality_guaranteed": 2
		}
	},
	"Shepherd": {
		"parent": "Rancher",
		"name": "Pastor",
		"description": "Lã produzida diariamente. Carne de ovelha valiosa. Amizade com mamíferos +50%/dia.",
		"icon": "🐑",
		"effects": {
			"daily_wool": true,
			"mammal_friendship_mult": 1.5,
			"wool_quality_guaranteed": 2
		}
	},
	"Artisan": {
		"parent": "Tiller",
		"name": "Artesão",
		"description": "Bens artesanais valem 50% mais. (Vinho, queijo, geleia, etc.)",
		"icon": "🎨",
		"effects": {
			"artisan_value_mult": 1.5
		}
	},
	"Agriculturist": {
		"parent": "Tiller",
		"name": "Agrônomo",
		"description": "Todas as culturas crescem 10% mais rápido.",
		"icon": "🌱",
		"effects": {
			"all_crop_growth_mult": 0.9
		}
	},
	"Blacksmith": {
		"parent": "Miner",
		"name": "Ferreiro",
		"description": "Barras de metal valem 50% mais. Fermentação 2x mais rápida.",
		"icon": "🔨",
		"effects": {
			"metal_bar_value_mult": 1.5,
			"keg_speed_mult": 2.0
		}
	},
	"Prospector": {
		"parent": "Miner",
		"name": "Prospector",
		"description": "Chance dobrada de encontrar carvão. Encontra irídio no nível 40+.",
		"icon": "⛏️",
		"effects": {
			"coal_double_chance": true,
			"iridium_at_40": true
		}
	},
	"Excavator": {
		"parent": "Geologist",
		"name": "Escavador",
		"description": "Chance dobrada de geodas. Minérios dropam em dobro.",
		"icon": "⛏️",
		"effects": {
			"geode_double_chance": true,
			"ore_double_chance": true
		}
	},
	"Gemologist": {
		"parent": "Geologist",
		"name": "Gemólogo",
		"description": "Geminas valem 30% mais. Chance de diamante em geodas.",
		"icon": "💎",
		"effects": {
			"gem_value_mult": 1.3,
			"diamond_geode_chance": 0.05
		}
	},
	"Lumberjack": {
		"parent": "Forester",
		"name": "Lenhador",
		"description": "Árvores normais dropam madeira dura. Madeira vale 25% mais.",
		"icon": "🪓",
		"effects": {
			"hardwood_from_normal": true,
			"wood_value_mult": 1.25
		}
	},
	"Tapper": {
		"parent": "Forester",
		"name": "Extrator",
		"description": "Extratores produzem 2x mais. Xarope de bordo diário.",
		"icon": "🍯",
		"effects": {
			"tapper_double": true,
			"maple_daily": true
		}
	},
	"Botanist": {
		"parent": "Gatherer",
		"name": "Botânico",
		"description": "Itens de forrageamento sempre qualidade irídio. Sementes selvagens.",
		"icon": "🌿",
		"effects": {
			"forage_iridium_quality": true,
			"wild_seeds_craftable": true
		}
	},
	"Tracker": {
		"parent": "Gatherer",
		"name": "Rastreador",
		"description": "Localização de itens de forrageamento revelada no mapa. Chance de item raro.",
		"icon": "🧭",
		"effects": {
			"forage_locations_revealed": true,
			"rare_forage_chance": 0.1
		}
	},
	"Angler": {
		"parent": "Fisher",
		"name": "Pescador Expert",
		"description": "Peixes lendários mais fáceis. Zona de pesca 50% maior.",
		"icon": "🎣",
		"effects": {
			"legendary_easier": true,
			"zone_size_mult": 1.5
		}
	},
	"Pirate": {
		"parent": "Fisher",
		"name": "Pirata",
		"description": "Chance de tesouro ao pescar. Peixes valem 2x no mercado negro.",
		"icon": "🏴‍☠️",
		"effects": {
			"treasure_chance": 0.1,
			"black_market_value": 2.0
		}
	},
	"Luremaster": {
		"parent": "Trapper",
		"name": "Mestre das Iscas",
		"description": "Crab pots nunca precisam de isca. Iscas artesanais duram para sempre.",
		"icon": "🪝",
		"effects": {
			"crab_pot_no_bait_forever": true,
			"crafted_bait_infinite": true
		}
	},
	"Mariner": {
		"parent": "Trapper",
		"name": "Marinheiro",
		"description": "Crab pots capturam peixes lendários. Baús de tesouro nas crab pots.",
		"icon": "⚓",
		"effects": {
			"legendary_in_crab_pots": true,
			"treasure_chests": 0.1
		}
	},
	"Brute": {
		"parent": "Fighter",
		"name": "Bruto",
		"description": "+25% dano. Inimigos derrubam mais itens.",
		"icon": "💪",
		"effects": {
			"damage_mult": 1.25,
			"extra_loot_chance": 0.2
		}
	},
	"Defender": {
		"parent": "Fighter",
		"name": "Defensor",
		"description": "-25% dano recebido. Escudo automático quando HP < 25%.",
		"icon": "🛡️",
		"effects": {
			"damage_reduction": 0.25,
			"auto_shield": 0.25
		}
	},
	"Acrobat": {
		"parent": "Scout",
		"name": "Acrobata",
		"description": "Invulnerabilidade ao rolar. Movimento 20% mais rápido.",
		"icon": "🤸",
		"effects": {
			"roll_invulnerability": true,
			"speed_mult": 1.2
		}
	},
	"Desperado": {
		"parent": "Scout",
		"name": "Desesperado",
		"description": "Ataques críticos causam 3x dano. Crítico não consome stamina.",
		"icon": "💀",
		"effects": {
			"crit_damage_mult": 3.0,
			"crit_no_stamina": true
		}
	}
}

## ==================== TALENTOS (PASSIVOS) ===
const TALENTS = {
	# Farming
	"green_thumb": {"name": "Dedo Verde", "desc": "+5% chance de cultura extra", "req": {"farming": 1}},
	"speed_grower": {"name": "Crescimento Rápido", "desc": "Culturas crescem 5% mais rápido", "req": {"farming": 3}},
	"quality_soil": {"name": "Solo de Qualidade", "desc": "+10% chance de qualidade prata+", "req": {"farming": 5}},
	"harvest_master": {"name": "Mestre da Colheita", "desc": "Colheita em área 3x3 com foice", "req": {"farming": 7}},
	"seasonal_master": {"name": "Mestre das Estações", "desc": "Pode plantar fora de estação (custo 2x)", "req": {"farming": 10}},

	# Mining
	"ore_sense": {"name": "Sentido de Minério", "desc": "Minérios brilham no minimapa", "req": {"mining": 1}},
	"gem_luck": {"name": "Sorte das Gemas", "desc": "+10% chance de gema extra", "req": {"mining": 3}},
	"coal_magnet": {"name": "Ímã de Carvão", "desc": "Carvão dropa 2x", "req": {"mining": 5}},
	"iridium_nose": {"name": "Nariz de Irídio", "desc": "Irídio aparece no nível 40+", "req": {"mining": 7}},
	"core_driller": {"name": "Perfurador do Núcleo", "desc": "Pickaxe quebra rochas 3x3", "req": {"mining": 10}},

	# Foraging
	"sharp_eyes": {"name": "Olhos Aguçados", "desc": "Itens de forrageamento brilham", "req": {"foraging": 1}},
	"nature_gift": {"name": "Presente da Natureza", "desc": "Itens de forrageamento qualidade +1", "req": {"foraging": 3}},
	"wood_walker": {"name": "Andarilho da Madeira", "desc": "Move 20% mais rápido na floresta", "req": {"foraging": 5}},
	"wild_crafter": {"name": "Artesão Selvagem", "desc": "Crafta sementes selvagens grátis", "req": {"foraging": 7}},
	"forest_lord": {"name": "Senhor da Floresta", "desc": "Árvores crescem 2x mais rápido", "req": {"foraging": 10}},

	# Fishing
	"fish_finder": {"name": "Localizador de Peixes", "desc": "Mostra tipo de peixe antes de puxar", "req": {"fishing": 1}},
	"perfect_cast": {"name": "Arremesso Perfeito", "desc": "Sempre arremessa na distância máxima", "req": {"fishing": 3}},
	"bait_master": {"name": "Mestre das Iscas", "desc": "Iscas duram 2x mais", "req": {"fishing": 5}},
	"legendary_lure": {"name": "Isca Lendária", "desc": "Chance de peixe lendário +50%", "req": {"fishing": 7}},
	"ocean_king": {"name": "Rei do Oceano", "desc": "Pesca qualquer peixe sem isca", "req": {"fishing": 10}},

	# Combat
	"critical_strike": {"name": "Golpe Crítico", "desc": "+5% chance de crítico", "req": {"combat": 1}},
	"life_steal": {"name": "Roubo de Vida", "desc": "Cura 5% do dano causado", "req": {"combat": 3}},
	"combo_master": {"name": "Mestre do Combo", "desc": "Ataques rápidos causam +20% dano", "req": {"combat": 5}},
	"berserker": {"name": "Berserker", "desc": "Dano +50% quando HP < 25%", "req": {"combat": 7}},
	"immortal": {"name": "Imortal", "desc": "Sobrevive a golpe fatal 1x/dia", "req": {"combat": 10}},

	# General
	"early_riser": {"name": "Madrugador", "desc": "Energia +20 se acordar antes 6h", "req": {}},
	"night_owl": {"name": "Coruja Noturna", "desc": "Energia não decai após meia-noite", "req": {}},
	"pack_mule": {"name": "Mula de Carga", "desc": "+12 slots de inventário", "req": {}},
	"quick_learner": {"name": "Aprendiz Rápido", "desc": "XP de todas skills +10%", "req": {}},
	"lucky": {"name": "Sortudo", "desc": "Sorte diária +0.02", "req": {}},
	"hoarder": {"name": "Acumulador", "desc": "Baús têm 50% mais slots", "req": {}},
	"chef": {"name": "Chef", "desc": "Pratos dão 2x buff duration", "req": {}},
	"miner_69": {"name": "Mineiro 69", "desc": "Chance de item raro 69% maior", "req": {"mining": 6}},

	# Social
	"charmer": {"name": "Encantador", "desc": "Amizade +20% com presentes", "req": {}},
	"matchmaker": {"name": "Cupido", "desc": "NPCs solteiros se casam entre si", "req": {}},
	"polyglot": {"name": "Poliglota", "desc": "Entende todos os idiomas NPC", "req": {}},

	# Magic/Special
	"fairy_friend": {"name": "Amigo das Fadas", "desc": "Fadas visitam 2x mais", "req": {}},
	"junimo_whisperer": {"name": "Sussurrador Junimo", "desc": "Junimos colhem 2x mais rápido", "req": {}},
	"witch_friend": {"name": "Amigo da Bruxa", "desc": "Acesso à bruxa sem magia", "req": {}},
	"dwarf_friend": {"name": "Amigo do Anão", "desc": "Comércio com anão desbloqueado", "req": {}},
	"krobus_friend": {"name": "Amigo do Krobus", "desc": "Krobus vende itens raros", "req": {}},
	"gilbert_friend": {"name": "Amigo do Gilberto", "desc": "Comércio na Ilha Ginger", "req": {}},
	"professor_snail": {"name": "Professor Caracol", "desc": "Pesquisas de fósseis grátis", "req": {}},
	"pirate_friend": {"name": "Amigo Pirata", "desc": "Acesso ao cove dos piratas", "req": {}},
}

## ==================== SISTEMA DE PROGRESSÃO ===
class SkillProgression:
	var talents_unlocked: Array[String] = []

	func unlock_talent(talent_id: String) -> bool:
		if talent_id in talents_unlocked:
			return false

		if not TALENTS.has(talent_id):
			return false

		var talent = TALENTS[talent_id]
		var req = talent.req

		# Verifica requisitos
		for skill in req:
			var level = GameManager.skill_levels[_get_skill_index(skill)] if GameManager else 0
			if level < req[skill]:
				return false

		talents_unlocked.append(talent_id)
		_apply_talent_effect(talent_id)
		return true

	func _apply_talent_effect(talent_id: String) -> void:
		match talent_id:
			"green_thumb":
				GameManager.set("talent_green_thumb", true)
			"speed_grower":
				GameManager.set("talent_speed_grower", true)
			"quality_soil":
				GameManager.set("talent_quality_soil", true)
			"harvest_master":
				GameManager.set("talent_harvest_master", true)
			"seasonal_master":
				GameManager.set("talent_seasonal_master", true)
			"ore_sense":
				GameManager.set("talent_ore_sense", true)
			"gem_luck":
				GameManager.set("talent_gem_luck", true)
			"coal_magnet":
				GameManager.set("talent_coal_magnet", true)
			"iridium_nose":
				GameManager.set("talent_iridium_nose", true)
			"core_driller":
				GameManager.set("talent_core_driller", true)
			"sharp_eyes":
				GameManager.set("talent_sharp_eyes", true)
			"nature_gift":
				GameManager.set("talent_nature_gift", true)
			"wood_walker":
				GameManager.set("talent_wood_walker", true)
			"wild_crafter":
				GameManager.set("talent_wild_crafter", true)
			"forest_lord":
				GameManager.set("talent_forest_lord", true)
			"fish_finder":
				GameManager.set("talent_fish_finder", true)
			"perfect_cast":
				GameManager.set("talent_perfect_cast", true)
			"bait_master":
				GameManager.set("talent_bait_master", true)
			"legendary_lure":
				GameManager.set("talent_legendary_lure", true)
			"ocean_king":
				GameManager.set("talent_ocean_king", true)
			"critical_strike":
				GameManager.set("talent_critical_strike", true)
			"life_steal":
				GameManager.set("talent_life_steal", true)
			"combo_master":
				GameManager.set("talent_combo_master", true)
			"berserker":
				GameManager.set("talent_berserker", true)
			"immortal":
				GameManager.set("talent_immortal", true)
			"early_riser":
				GameManager.set("talent_early_riser", true)
			"night_owl":
				GameManager.set("talent_night_owl", true)
			"pack_mule":
				InventoryManager.max_inventory_slots += 12
			"quick_learner":
				GameManager.set("talent_quick_learner", true)
			"lucky":
				GameManager.set("talent_lucky", true)
			"hoarder":
				GameManager.set("talent_hoarder", true)
			"chef":
				GameManager.set("talent_chef", true)
			"miner_69":
				GameManager.set("talent_miner_69", true)
			"charmer":
				GameManager.set("talent_charmer", true)
			"matchmaker":
				GameManager.set("talent_matchmaker", true)
			"polyglot":
				GameManager.set("talent_polyglot", true)
			"fairy_friend":
				GameManager.set("talent_fairy_friend", true)
			"junimo_whisperer":
				GameManager.set("talent_junimo_whisperer", true)
			"witch_friend":
				GameManager.set("talent_witch_friend", true)
			"dwarf_friend":
				GameManager.set("talent_dwarf_friend", true)
			"krobus_friend":
				GameManager.set("talent_krobus_friend", true)
			"gilbert_friend":
				GameManager.set("talent_gilbert_friend", true)
			"professor_snail":
				GameManager.set("talent_professor_snail", true)
			"pirate_friend":
				GameManager.set("talent_pirate_friend", true)

		# Efeitos específicos
		_apply_specific_effects(talent_id)

	func _apply_specific_effects(talent_id: String) -> void:
		match talent_id:
			"pack_mule":
				InventoryManager.max_inventory_slots += 12
				GameManager.emit_signal("inventory_changed")
			"early_riser":
				# Verificado no day_changed
				pass
			"night_owl":
				# Verificado no hour_changed
				pass

static func get_available_talents() -> Array[Dictionary]:
	var available = []
	for talent_id in TALENTS:
		var talent = TALENTS[talent_id]
		var met = true
		for skill in talent.req:
			var level = GameManager.skill_levels[_get_skill_index(skill)] if GameManager else 0
			if level < talent.req[skill]:
				met = false
				break
		if met:
			available.append({
				"id": talent_id,
				"name": talent.name,
				"desc": talent.desc,
				"req": talent.req
			})
	return available

static func _get_skill_index(skill: String) -> int:
	return ["farming", "mining", "foraging", "fishing", "combat"].find(skill)