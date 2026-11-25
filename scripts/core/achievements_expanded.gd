class_name AchievementsExpanded
extends Node

## Sistema Expandido de Conquistas: metas, progresso, recompensas, estatísticas

## ==================== CONQUISTAS COMPLETAS ====================
const ACHIEVEMENTS = {
	# === AGRICULTURA ===
	"first_crop": {
		"id": "first_crop",
		"name": "Primeira Colheita",
		"description": "Colha sua primeira cultura",
		"icon": "🌱",
		"category": "farming",
		"tier": 1,
		"hidden": false,
		"requirements": {"crops_harvested": 1},
		"reward": {"gold": 100, "xp": {"farming": 50}}
	},
	"farmer_novice": {
		"id": "farmer_novice",
		"name": "Agricultor Novato",
		"description": "Colha 50 culturas",
		"icon": "🌾",
		"category": "farming",
		"tier": 2,
		"hidden": false,
		"requirements": {"crops_harvested": 50},
		"reward": {"gold": 500, "xp": {"farming": 200}}
	},
	"farmer_expert": {
		"id": "farmer_expert",
		"name": "Agricultor Experiente",
		"description": "Colha 500 culturas",
		"icon": "🌽",
		"category": "farming",
		"tier": 3,
		"hidden": false,
		"requirements": {"crops_harvested": 500},
		"reward": {"gold": 2000, "xp": {"farming": 1000}, "item": "(O)453"}
	},
	"farmer_master": {
		"id": "farmer_master",
		"name": "Mestre Agricultor",
		"description": "Colha 5000 culturas",
		"icon": "👑",
		"category": "farming",
		"tier": 4,
		"hidden": false,
		"requirements": {"crops_harvested": 5000},
		"reward": {"gold": 10000, "xp": {"farming": 5000}, "item": "(O)768"}
	},
	"perfect_crops": {
		"id": "perfect_crops",
		"name": "Colheita Perfeita",
		"description": "Obtenha 100 culturas de qualidade irídio",
		"icon": "💎",
		"category": "farming",
		"tier": 3,
		"hidden": false,
		"requirements": {"iridium_crops": 100},
		"reward": {"gold": 5000, "item": "(O)346"}
	},
	"all_seasons": {
		"id": "all_seasons",
		"name": "Quatro Estações",
		"description": "Plante e colha pelo menos uma cultura em cada estação",
		"icon": "🌸",
		"category": "farming",
		"tier": 2,
		"hidden": false,
		"requirements": {"spring_crop": 1, "summer_crop": 1, "fall_crop": 1, "winter_crop": 1},
		"reward": {"gold": 2000, "item": "(O)455"}
	},
	"giant_crop": {
		"id": "giant_crop",
		"name": "Colheita Gigante",
		"description": "Cultive uma cultura gigante (3x3)",
		"icon": "🎃",
		"category": "farming",
		"tier": 3,
		"hidden": true,
		"requirements": {"giant_crops": 1},
		"reward": {"gold": 5000, "item": "(O)769"}
	},
	"polyculture": {
		"id": "polyculture",
		"name": "Policultura",
		"description": "Tenha 10 tipos diferentes de culturas crescendo simultaneamente",
		"icon": "🌿",
		"category": "farming",
		"tier": 2,
		"hidden": false,
		"requirements": {"unique_crops_growing": 10},
		"reward": {"gold": 1000, "item": "(O)456"}
	},

	# === MINERAÇÃO ===
	"first_ore": {
		"id": "first_ore",
		"name": "Primeiro Minério",
		"description": "Mine seu primeiro minério",
		"icon": "⛏️",
		"category": "mining",
		"tier": 1,
		"hidden": false,
		"requirements": {"ores_mined": 1},
		"reward": {"gold": 100, "xp": {"mining": 50}}
	},
	"miner_novice": {
		"id": "miner_novice",
		"name": "Minerador Novato",
		"description": "Mine 100 minérios",
		"icon": "💎",
		"category": "mining",
		"tier": 2,
		"hidden": false,
		"requirements": {"ores_mined": 100},
		"reward": {"gold": 500, "xp": {"mining": 200}}
	},
	"miner_expert": {
		"id": "miner_expert",
		"name": "Minerador Experiente",
		"description": "Mine 1000 minérios",
		"icon": "💍",
		"category": "mining",
		"tier": 3,
		"hidden": false,
		"requirements": {"ores_mined": 1000},
		"reward": {"gold": 2000, "xp": {"mining": 1000}, "item": "(O)60"}
	},
	"miner_master": {
		"id": "miner_master",
		"name": "Mestre Minerador",
		"description": "Mine 10000 minérios",
		"icon": "💍",
		"category": "mining",
		"tier": 4,
		"hidden": false,
		"requirements": {"ores_mined": 10000},
		"reward": {"gold": 10000, "xp": {"mining": 5000}, "item": "(O)749"}
	},
	"deep_delver": {
		"id": "deep_delver",
		"name": "Explorador Profundo",
		"description": "Chegue ao nível 40 da mina",
		"icon": "🕳️",
		"category": "mining",
		"tier": 3,
		"hidden": false,
		"requirements": {"mine_level": 40},
		"reward": {"gold": 5000, "item": "(O)60"}
	},
	"skull_cavern": {
		"id": "skull_cavern",
		"name": "Caverna da Caveira",
		"description": "Chegue ao nível 100 da Caverna da Caveira",
		"icon": "💀",
		"category": "mining",
		"tier": 4,
		"hidden": false,
		"requirements": {"skull_cavern_level": 100},
		"reward": {"gold": 20000, "item": "(O)749", "title": "Cave Explorer"}
	},
	"all_gems": {
		"id": "all_gems",
		"name": "Colecionador de Gemas",
		"description": "Encontre todos os tipos de gemas",
		"icon": "💎",
		"category": "mining",
		"tier": 3,
		"hidden": false,
		"requirements": {"unique_gems": 6},
		"reward": {"gold": 5000, "item": "(O)64"}
	},
	"prismatic_shard": {
		"id": "prismatic_shard",
		"name": "Fragmento Prismático",
		"description": "Encontre um Fragmento Prismático",
		"icon": "🌈",
		"category": "mining",
		"tier": 4,
		"hidden": true,
		"requirements": {"items_found": ["(O)749"]},
		"reward": {"gold": 10000, "title": "Prismatic Finder"}
	},
	"dino_egg": {
		"id": "dino_egg",
		"name": "Ovo de Dinossauro",
		"description": "Encontre um Ovo de Dinossauro",
		"icon": "🦕",
		"category": "mining",
		"tier": 4,
		"hidden": true,
		"requirements": {"items_found": ["(O)107"]},
		"reward": {"gold": 5000, "item": "(O)107"}
	},

	# === PESCA ===
	"first_fish": {
		"id": "first_fish",
		"name": "Primeiro Peixe",
		"description": "Pesque seu primeiro peixe",
		"icon": "🐟",
		"category": "fishing",
		"tier": 1,
		"hidden": false,
		"requirements": {"fish_caught": 1},
		"reward": {"gold": 100, "xp": {"fishing": 50}}
	},
	"angler_novice": {
		"id": "angler_novice",
		"name": "Pescador Novato",
		"description": "Pesque 50 peixes",
		"icon": "🎣",
		"category": "fishing",
		"tier": 2,
		"hidden": false,
		"requirements": {"fish_caught": 50},
		"reward": {"gold": 500, "xp": {"fishing": 200}}
	},
	"angler_expert": {
		"id": "angler_expert",
		"name": "Pescador Experiente",
		"description": "Pesque 500 peixes",
		"icon": "🐠",
		"category": "fishing",
		"tier": 3,
		"hidden": false,
		"requirements": {"fish_caught": 500},
		"reward": {"gold": 2000, "xp": {"fishing": 1000}, "item": "(O)690"}
	},
	"angler_master": {
		"id": "angler_master",
		"name": "Mestre Pescador",
		"description": "Pesque 5000 peixes",
		"icon": "🏆",
		"category": "fishing",
		"tier": 4,
		"hidden": false,
		"requirements": {"fish_caught": 5000},
		"reward": {"gold": 10000, "xp": {"fishing": 5000}, "item": "(O)749"}
	},
	"legendary_fish": {
		"id": "legendary_fish",
		"name": "Lenda Viva",
		"description": "Pesque todos os 5 peixes lendários",
		"icon": "⭐",
		"category": "fishing",
		"tier": 4,
		"hidden": true,
		"requirements": {"legendary_fish": ["(O)158", "(O)160", "(O)162", "(O)164", "(O)166"]},
		"reward": {"gold": 20000, "item": "(O)749", "title": "Legendary Angler"}
	},
	"master_angler": {
		"id": "master_angler",
		"name": "Mestre da Pesca",
		"description": "Pesque 100 peixes de qualidade irídio",
		"icon": "💎",
		"category": "fishing",
		"tier": 3,
		"hidden": false,
		"requirements": {"iridium_fish": 100},
		"reward": {"gold": 10000, "item": "(O)749"}
	},
	"all_fish": {
		"id": "all_fish",
		"name": "Ictiologista",
		"description": "Pesque todos os tipos de peixes",
		"icon": "🐟",
		"category": "fishing",
		"tier": 3,
		"hidden": false,
		"requirements": {"unique_fish": 70},
		"reward": {"gold": 10000, "item": "(O)690", "title": "Master Angler"}
	},

	# === COLETA ===
	"first_forage": {
		"id": "first_forage",
		"name": "Primeira Coleta",
		"description": "Colete seu primeiro item de forrageamento",
		"icon": "🌿",
		"category": "foraging",
		"tier": 1,
		"hidden": false,
		"requirements": {"forage_collected": 1},
		"reward": {"gold": 100, "xp": {"foraging": 50}}
	},
	"forager_novice": {
		"id": "forager_novice",
		"name": "Coletor Novato",
		"description": "Colete 100 itens de forrageamento",
		"icon": "🌲",
		"category": "foraging",
		"tier": 2,
		"hidden": false,
		"requirements": {"forage_collected": 100},
		"reward": {"gold": 500, "xp": {"foraging": 200}}
	},
	"forager_expert": {
		"id": "forager_expert",
		"name": "Coletor Experiente",
		"description": "Colete 1000 itens de forrageamento",
		"icon": "🍄",
		"category": "foraging",
		"tier": 3,
		"hidden": false,
		"requirements": {"forage_collected": 1000},
		"reward": {"gold": 2000, "xp": {"foraging": 1000}, "item": "(O)60"}
	},
	"forager_master": {
		"id": "forager_master",
		"name": "Mestre Coletor",
		"description": "Colete 10000 itens de forrageamento",
		"icon": "🌿",
		"category": "foraging",
		"tier": 4,
		"hidden": false,
		"requirements": {"forage_collected": 10000},
		"reward": {"gold": 10000, "xp": {"foraging": 5000}, "item": "(O)768"}
	},
	"all_forage": {
		"id": "all_forage",
		"name": "Botânico Completo",
		"description": "Encontre todos os itens de forrageamento",
		"icon": "🌱",
		"category": "foraging",
		"tier": 3,
		"hidden": false,
		"requirements": {"unique_forage": 40},
		"reward": {"gold": 5000, "item": "(O)60", "title": "Master Forager"}
	},
	"secret_woods": {
		"id": "secret_woods",
		"name": "Madeira Secreta",
		"description": "Entre na Floresta Secreta",
		"icon": "🌳",
		"category": "foraging",
		"tier": 2,
		"hidden": true,
		"requirements": {"visited_secret_woods": true},
		"reward": {"gold": 1000, "item": "(O)770"}
	},

	# === COMBATE ===
	"first_kill": {
		"id": "first_kill",
		"name": "Primeiro Sangue",
		"description": "Derrote seu primeiro monstro",
		"icon": "⚔️",
		"category": "combat",
		"tier": 1,
		"hidden": false,
		"requirements": {"monsters_killed": 1},
		"reward": {"gold": 100, "xp": {"combat": 50}}
	},
	"slayer_novice": {
		"id": "slayer_novice",
		"name": "Matador Novato",
		"description": "Derrote 50 monstros",
		"icon": "🗡️",
		"category": "combat",
		"tier": 2,
		"hidden": false,
		"requirements": {"monsters_killed": 50},
		"reward": {"gold": 500, "xp": {"combat": 200}}
	},
	"slayer_expert": {
		"id": "slayer_expert",
		"name": "Matador Experiente",
		"description": "Derrote 500 monstros",
		"icon": "☠️",
		"category": "combat",
		"tier": 3,
		"hidden": false,
		"requirements": {"monsters_killed": 500},
		"reward": {"gold": 2000, "xp": {"combat": 1000}, "item": "(O)60"}
	},
	"slayer_master": {
		"id": "slayer_master",
		"name": "Carniceiro",
		"description": "Derrote 5000 monstros",
		"icon": "☠️",
		"category": "combat",
		"tier": 4,
		"hidden": false,
		"requirements": {"monsters_killed": 5000},
		"reward": {"gold": 10000, "xp": {"combat": 5000}, "item": "(O)749"}
	},
	"slime_rancher": {
		"id": "slime_rancher",
		"name": "Criador de Slimes",
		"description": "Derrote 1000 slimes",
		"icon": "🟢",
		"category": "combat",
		"tier": 3,
		"hidden": false,
		"requirements": {"slimes_killed": 1000},
		"reward": {"gold": 5000, "item": "(O)766"}
	},
	"serpent_slayer": {
		"id": "serpent_slayer",
		"name": "Matador de Serpentes",
		"description": "Derrote a Serpente da Caverna da Caveira",
		"icon": "🐍",
		"category": "combat",
		"tier": 4,
		"hidden": true,
		"requirements": {"boss_killed": ["Serpent"]},
		"reward": {"gold": 20000, "item": "(O)749", "title": "Serpent Slayer"}
	},

	# === SOCIAL ===
	"first_friend": {
		"id": "first_friend",
		"name": "Primeiro Amigo",
		"description": "Alcance 2 corações com qualquer habitante",
		"icon": "💚",
		"category": "social",
		"tier": 1,
		"hidden": false,
		"requirements": {"any_friendship": 2},
		"reward": {"gold": 100, "xp": {"social": 50}}
	},
	"popular": {
		"id": "popular",
		"name": "Popular",
		"description": "Alcance 5 corações com 5 pessoas",
		"icon": "❤️",
		"category": "social",
		"tier": 2,
		"hidden": false,
		"requirements": {"five_hearts_count": 5},
		"reward": {"gold": 1000, "item": "(O)454"}
	},
	"best_friends": {
		"id": "best_friends",
		"name": "Melhores Amigos",
		"description": "Alcance 10 corações com alguém",
		"icon": "💕",
		"category": "social",
		"tier": 3,
		"hidden": false,
		"requirements": {"max_friendship": 10},
		"reward": {"gold": 5000, "item": "(O)455"}
	},
	"married": {
		"id": "married",
		"name": "Casado",
		"description": "Case-se com alguém",
		"icon": "💍",
		"category": "social",
		"tier": 4,
		"hidden": false,
		"requirements": {"married": true},
		"reward": {"gold": 10000, "item": "(O)455", "title": "Married"}
	},
	"soulmate": {
		"id": "soulmate",
		"name": "Alma Gêmea",
		"description": "Alcance 14 corações com seu cônjuge",
		"icon": "💖",
		"category": "social",
		"tier": 4,
		"hidden": true,
		"requirements": {"spouse_friendship": 14},
		"reward": {"gold": 20000, "item": "(O)749", "title": "Soulmate"}
	},
	"social_butterfly": {
		"id": "social_butterfly",
		"name": "Borboleta Social",
		"description": "Converse com todos os 28 habitantes em um dia",
		"icon": "🦋",
		"category": "social",
		"tier": 3,
		"hidden": true,
		"requirements": {"npcs_talked_today": 28},
		"reward": {"gold": 5000, "item": "(O)456", "title": "Social Butterfly"}
	},
	"gift_master": {
		"id": "gift_master",
		"name": "Mestre dos Presentes",
		"description": "Dê 100 presentes amados",
		"icon": "🎁",
		"category": "social",
		"tier": 3,
		"hidden": false,
		"requirements": {"loved_gifts_given": 100},
		"reward": {"gold": 5000, "item": "(O)457"}
	},

	# === DINHEIRO ===
	"first_gold": {
		"id": "first_gold",
		"name": "Primeiro Ouro",
		"description": "Acumule 1000g",
		"icon": "💰",
		"category": "money",
		"tier": 1,
		"hidden": false,
		"requirements": {"total_gold_earned": 1000},
		"reward": {"gold": 100}
	},
	"rich": {
		"id": "rich",
		"name": "Rico",
		"description": "Tenha 100.000g de uma vez",
		"icon": "💎",
		"category": "money",
		"tier": 2,
		"hidden": false,
		"requirements": {"gold": 100000},
		"reward": {"gold": 5000, "item": "(O)60"}
	},
	"millionaire": {
		"id": "millionaire",
		"name": "Milionário",
		"description": "Tenha 1.000.000g de uma vez",
		"icon": "👑",
		"category": "money",
		"tier": 3,
		"hidden": false,
		"requirements": {"gold": 1000000},
		"reward": {"gold": 50000, "item": "(O)749", "title": "Millionaire"}
	},
	"billionaire": {
		"id": "billionaire",
		"name": "Bilionário",
		"description": "Tenha 10.000.000g de uma vez",
		"icon": "💸",
		"category": "money",
		"tier": 4,
		"hidden": true,
		"requirements": {"gold": 10000000},
		"reward": {"gold": 1000000, "item": "(O)749", "title": "Billionaire"}
	},
	"gold_earner": {
		"id": "gold_earner",
		"name": "Ganhador de Ouro",
		"description": "Ganhe 10.000.000g no total",
		"icon": "💰",
		"category": "money",
		"tier": 3,
		"hidden": false,
		"requirements": {"total_gold_earned": 10000000},
		"reward": {"gold": 100000, "item": "(O)749"}
	},
	"frugal": {
		"id": "frugal",
		"name": "Econômico",
		"description": "Gaste menos de 1000g no primeiro ano",
		"icon": "💵",
		"category": "money",
		"tier": 2,
		"hidden": true,
		"requirements": {"year": 1, "gold_spent": 1000},
		"reward": {"gold": 5000, "item": "(O)454"}
	},

	# === COLEÇÕES ===
	"shipped_50": {
		"id": "shipped_50",
		"name": "Colecionador",
		"description": "Envie 50 itens diferentes",
		"icon": "📦",
		"category": "collections",
		"tier": 2,
		"hidden": false,
		"requirements": {"unique_shipped": 50},
		"reward": {"gold": 1000, "item": "(O)454"}
	},
	"shipped_100": {
		"id": "shipped_100",
		"name": "Colecionador Avançado",
		"description": "Envie 100 itens diferentes",
		"icon": "📦",
		"category": "collections",
		"tier": 3,
		"hidden": false,
		"requirements": {"unique_shipped": 100},
		"reward": {"gold": 5000, "item": "(O)455"}
	},
	"shipped_all": {
		"id": "shipped_all",
		"name": "Completista de Envios",
		"description": "Envie todos os itens enviáveis",
		"icon": "📦",
		"category": "collections",
		"tier": 4,
		"hidden": true,
		"requirements": {"unique_shipped": 800},
		"reward": {"gold": 50000, "item": "(O)749", "title": "Completionist"}
	},
	"complete_museum": {
		"id": "complete_museum",
		"name": "Curador",
		"description": "Complete o museu (todos os itens doados)",
		"icon": "🏛️",
		"category": "collections",
		"tier": 4,
		"hidden": false,
		"requirements": {"museum_complete": true},
		"reward": {"gold": 20000, "item": "(O)749", "title": "Curator"}
	},
	"complete_cc": {
		"id": "complete_cc",
		"name": "Restaurador",
		"description": "Complete o Centro Comunitário",
		"icon": "🏘️",
		"category": "collections",
		"tier": 4,
		"hidden": false,
		"requirements": {"cc_complete": true},
		"reward": {"gold": 20000, "item": "(O)749", "title": "Restorer"}
	},
	"complete_catalog": {
		"id": "complete_catalog",
		"name": "Catalogador",
		"description": "Complete todas as coleções (enviados, peixes, artefatos, minerais, receitas)",
		"icon": "📚",
		"category": "collections",
		"tier": 4,
		"hidden": true,
		"requirements": {"all_collections_complete": true},
		"reward": {"gold": 50000, "item": "(O)749", "title": "Completionist"}
	},

	# === CULINÁRIA ===
	"chef_novice": {
		"id": "chef_novice",
		"name": "Cozinheiro Novato",
		"description": "Cozinhe 10 receitas diferentes",
		"icon": "🍳",
		"category": "cooking",
		"tier": 1,
		"hidden": false,
		"requirements": {"cooking_recipes": 10},
		"reward": {"gold": 500, "item": "(O)306"}
	},
	"chef_expert": {
		"id": "chef_expert",
		"name": "Chef Experiente",
		"description": "Cozinhe 50 receitas diferentes",
		"icon": "👨‍🍳",
		"category": "cooking",
		"tier": 2,
		"hidden": false,
		"requirements": {"cooking_recipes": 50},
		"reward": {"gold": 2000, "item": "(O)346"}
	},
	"gourmet": {
		"id": "gourmet",
		"name": "Gourmet",
		"description": "Cozinhe todas as receitas",
		"icon": "👨‍🍳",
		"category": "cooking",
		"tier": 4,
		"hidden": false,
		"requirements": {"cooking_recipes": 80},
		"reward": {"gold": 20000, "item": "(O)749", "title": "Gourmet"}
	},
	"buff_master": {
		"id": "buff_master",
		"name": "Mestre dos Buffs",
		"description": "Cozinhe 50 pratos com buff",
		"icon": "✨",
		"category": "cooking",
		"tier": 3,
		"hidden": false,
		"requirements": {"buff_recipes_cooked": 50},
		"reward": {"gold": 10000, "item": "(O)346"}
	},

	# === ARTESANATO ===
	"crafter_novice": {
		"id": "crafter_novice",
		"name": "Artesão Novato",
		"description": "Crafte 10 itens diferentes",
		"icon": "🔨",
		"category": "crafting",
		"tier": 1,
		"hidden": false,
		"requirements": {"crafting_recipes": 10},
		"reward": {"gold": 500, "item": "(O)306"}
	},
	"crafter_expert": {
		"id": "crafter_expert",
		"name": "Artesão Experiente",
		"description": "Crafte 50 itens diferentes",
		"icon": "🔨",
		"category": "crafting",
		"tier": 2,
		"hidden": false,
		"requirements": {"crafting_recipes": 50},
		"reward": {"gold": 2000, "item": "(O)346"}
	},
	"crafter_master": {
		"id": "crafter_master",
		"name": "Mestre Artesão",
		"description": "Crafte todos os itens artesanáveis",
		"icon": "🔨",
		"category": "crafting",
		"tier": 3,
		"hidden": false,
		"requirements": {"crafting_recipes": 100},
		"reward": {"gold": 10000, "item": "(O)749"}
	},
	"artisan_goods": {
		"id": "artisan_goods",
		"name": "Produtor Artesanal",
		"description": "Produza 1000 bens artesanais",
		"icon": "🫙",
		"category": "crafting",
		"tier": 3,
		"hidden": false,
		"requirements": {"artisan_items_produced": 1000},
		"reward": {"gold": 10000, "item": "(O)346"}
	},

	# === EXPLORAÇÃO ===
	"explorer": {
		"id": "explorer",
		"name": "Explorador",
		"description": "Visite todas as áreas do mapa",
		"icon": "🗺️",
		"category": "exploration",
		"tier": 2,
		"hidden": false,
		"requirements": {"locations_visited": 20},
		"reward": {"gold": 1000, "item": "(O)454"}
	},
	"desert_explorer": {
		"id": "desert_explorer",
		"name": "Explorador do Deserto",
		"description": "Visite o Deserto e a Caverna da Caveira",
		"icon": "🏜️",
		"category": "exploration",
		"tier": 3,
		"hidden": false,
		"requirements": {"visited_desert": true, "visited_skull_cavern": true},
		"reward": {"gold": 5000, "item": "(O)60"}
	},
	"island_explorer": {
		"id": "island_explorer",
		"name": "Explorador da Ilha",
		"description": "Desbloqueie a Ilha Ginger e colete 50 Nozes Douradas",
		"icon": "🏝️",
		"category": "exploration",
		"tier": 3,
		"hidden": false,
		"requirements": {"island_unlocked": true, "walnuts_collected": 50},
		"reward": {"gold": 10000, "item": "(O)768"}
	},
	"qi_master": {
		"id": "qi_master",
		"name": "Mestre do Qi",
		"description": "Complete a Sala de Nozes do Qi e 50 Pedidos Especiais",
		"icon": "🧙",
		"category": "exploration",
		"tier": 4,
		"hidden": true,
		"requirements": {"qi_walnut_room": true, "special_orders_completed": 50},
		"reward": {"gold": 50000, "item": "(O)749", "title": "Qi Master"}
	},

	# === EDIFÍCIOS ===
	"builder": {
		"id": "builder",
		"name": "Construtor",
		"description": "Construa 5 edifícios na fazenda",
		"icon": "🏠",
		"category": "building",
		"tier": 1,
		"hidden": false,
		"requirements": {"buildings_built": 5},
		"reward": {"gold": 1000, "item": "(O)306"}
	},
	"architect": {
		"id": "architect",
		"name": "Arquiteto",
		"description": "Construa todos os tipos de edifícios",
		"icon": "🏗️",
		"category": "building",
		"tier": 3,
		"hidden": false,
		"requirements": {"unique_buildings": 10},
		"reward": {"gold": 10000, "item": "(O)768"}
	},
	"max_house": {
		"id": "max_house",
		"name": "Mansão Suprema",
		"description": "Melhore a casa ao nível máximo",
		"icon": "🏰",
		"category": "building",
		"tier": 4,
		"hidden": false,
		"requirements": {"house_level": 3},
		"reward": {"gold": 20000, "item": "(O)749"}
	},
	"all_upgrades": {
		"id": "all_upgrades",
		"name": "Melhorias Completas",
		"description": "Melhore todas as ferramentas ao Irídio e mochila máxima",
		"icon": "⚒️",
		"category": "building",
		"tier": 4,
		"hidden": false,
		"requirements": {"all_tools_iridium": true, "backpack_max": true},
		"reward": {"gold": 20000, "item": "(O)749", "title": "Fully Upgraded"}
	},

	# === TEMPO ===
	"night_owl": {
		"id": "night_owl",
		"name": "Coruja Noturna",
		"description": "Fique acordado até depois das 2h da manhã 50 vezes",
		"icon": "🦉",
		"category": "time",
		"tier": 2,
		"hidden": false,
		"requirements": {"late_nights": 50},
		"reward": {"gold": 1000, "item": "(O)454"}
	},
	"early_bird": {
		"id": "early_bird",
		"name": "Madrugador",
		"description": "Acorde antes das 6h da manhã 50 vezes",
		"icon": "🌅",
		"category": "time",
		"tier": 2,
		"hidden": false,
		"requirements": {"early_mornings": 50},
		"reward": {"gold": 1000, "item": "(O)454"}
	},
	"perfectionist": {
		"id": "perfectionist",
		"name": "Perfeccionista",
		"description": "Alcance a pontuação perfeita na avaliação do Avô",
		"icon": "👴",
		"category": "time",
		"tier": 4,
		"hidden": true,
		"requirements": {"grandpa_score": 4},
		"reward": {"gold": 50000, "item": "(O)749", "title": "Perfectionist"}
	},
	"centurion": {
		"id": "centurion",
		"name": "Centurião",
		"description": "Jogue por 100 anos no jogo",
		"icon": "💯",
		"category": "time",
		"tier": 4,
		"hidden": true,
		"requirements": {"years_played": 100},
		"reward": {"gold": 100000, "item": "(O)749", "title": "Centurion"}
	}
}

## ==================== SISTEMA DE VERIFICAÇÃO ====================
func check_achievements() -> void:
	if not GameManager:
		return

	for ach_id in ACHIEVEMENTS:
		if ach_id in GameManager.achievements:
			continue  # Já desbloqueada

		var ach = ACHIEVEMENTS[ach_id]
		if _check_requirements(ach.requirements):
			_unlock_achievement(ach_id)

func _check_requirements(reqs: Dictionary) -> bool:
	if not GameManager:
		return false

	for key in reqs:
		var target = reqs[key]
		var current = 0

		match key:
			# Contadores simples
			"crops_harvested": current = GameManager.stats.crops_harvested
			"ores_mined": current = GameManager.stats.ores_mined
			"fish_caught": current = GameManager.stats.fish_caught
			"forage_collected": current = GameManager.stats.forage_collected
			"monsters_killed": current = GameManager.stats.monsters_killed
			"gold": current = GameManager.gold
			"total_gold_earned": current = GameManager.stats.gold_earned
			"gold_spent": current = GameManager.stats.gold_spent
			"years_played": current = GameManager.current_year
			"late_nights": current = GameManager.stats.late_nights
			"early_mornings": current = GameManager.stats.early_mornings

			# Contadores específicos
			"crops_harvested": current = GameManager.stats.crops_harvested
			"iridium_crops": current = GameManager.stats.iridium_crops
			"giant_crops": current = GameManager.stats.giant_crops
			"unique_crops_growing": current = _count_unique_growing_crops()
			"spring_crop": current = _check_season_crop(0)
			"summer_crop": current = _check_season_crop(1)
			"fall_crop": current = _check_season_crop(2)
			"winter_crop": current = _check_season_crop(3)
			"items_found": current = _check_items_found(target)
			"ores_mined": current = GameManager.stats.ores_mined
			"mine_level": current = GameManager.get_data("deepest_mine_level", 0)
			"skull_cavern_level": current = GameManager.get_data("deepest_skull_level", 0)
			"unique_gems": current = _count_unique_gems()
			"fish_caught": current = GameManager.stats.fish_caught
			"iridium_fish": current = GameManager.stats.iridium_fish
			"legendary_fish": current = _check_legendary_fish(target)
			"unique_fish": current = _count_unique_fish()
			"forage_collected": current = GameManager.stats.forage_collected
			"unique_forage": current = _count_unique_forage()
			"visited_secret_woods": current = GameManager.get_data("visited_secret_woods", false)
			"monsters_killed": current = GameManager.stats.monsters_killed
			"slimes_killed": current = GameManager.stats.slimes_killed
			"boss_killed": current = _check_boss_killed(target)
			"any_friendship": current = _get_max_friendship()
			"five_hearts_count": current = _count_friendship_at_least(5)
			"max_friendship": current = _get_max_friendship()
			"married": current = GameManager.get_data("spouse", "") != ""
			"spouse_friendship": current = GameManager.friendships.get(GameManager.get_data("spouse", ""), 0) / 250
			"npcs_talked_today": current = GameManager.npcs_talked_today.size()
			"loved_gifts_given": current = GameManager.stats.loved_gifts_given
			"unique_shipped": current = GameManager.get_data("collection_shipped", {}).size()
			"museum_complete": current = GameManager.get_data("museum_complete", false)
			"cc_complete": current = GameManager.get_data("cc_complete", false)
			"all_collections_complete": current = _check_all_collections()
			"cooking_recipes": current = GameManager.unlocked_cooking_recipes.size()
			"buff_recipes_cooked": current = GameManager.stats.buff_recipes_cooked
			"crafting_recipes": current = GameManager.unlocked_recipes.size()
			"artisan_items_produced": current = GameManager.stats.artisan_items_produced
			"locations_visited": current = _count_locations_visited()
			"visited_desert": current = GameManager.get_data("desert_unlocked", false)
			"visited_skull_cavern": current = GameManager.get_data("skull_cavern_unlocked", false)
			"island_unlocked": current = GameManager.get_data("island_unlocked", false)
			"walnuts_collected": current = GameManager.get_data("walnuts_collected", 0)
			"qi_walnut_room": current = GameManager.get_data("walnut_room_unlocked", false)
			"special_orders_completed": current = GameManager.stats.special_orders_completed
			"buildings_built": current = GameManager.farm_buildings.size()
			"unique_buildings": current = _count_unique_buildings()
			"house_level": current = GameManager.get_data("house_level", 0)
			"all_tools_iridium": current = _check_all_tools_iridium()
			"backpack_max": current = InventoryManager.max_inventory_slots >= 36
			"late_nights": current = GameManager.stats.late_nights
			"early_mornings": current = GameManager.stats.early_mornings
			"grandpa_score": current = GameManager.get_data("grandpa_score", 0)
			"years_played": current = GameManager.current_year

			# Arrays/objetos complexos
			"items_found":
				return _check_items_found(target)
			"legendary_fish":
				return _check_legendary_fish(target)
			"boss_killed":
				return _check_boss_killed(target)
			"unique_fish":
				return _count_unique_fish() >= target
			"unique_forage":
				return _count_unique_forage() >= target
			"visited_desert":
				return target == true and GameManager.get_data("desert_unlocked", false)
			"visited_skull_cavern":
				return target == true and GameManager.get_data("skull_cavern_unlocked", false)
			"island_unlocked":
				return target == true and GameManager.get_data("island_unlocked", false)
			"museum_complete":
				return target == true and GameManager.get_data("museum_complete", false)
			"cc_complete":
				return target == true and GameManager.get_data("cc_complete", false)
			"all_collections_complete":
				return target == true and _check_all_collections()
			"all_tools_iridium":
				return target == true and _check_all_tools_iridium()
			"backpack_max":
				return target == true and InventoryManager.max_inventory_slots >= 36
			"all_tools_iridium":
				return target == true and _check_all_tools_iridium()
			"any_friendship":
				return _get_max_friendship() >= target
			"max_friendship":
				return _get_max_friendship() >= target
			"spouse_friendship":
				var spouse = GameManager.get_data("spouse", "")
				if spouse:
					return GameManager.friendships.get(spouse, 0) / 250 >= target
				return false

		if current < target:
			return false

	return true

## ==================== HELPERS ====================
func _count_unique_growing_crops() -> int:
	var unique = []
	for plot in GameManager.farm_crops.values():
		if plot.crop_id and not plot.is_dead:
			if plot.crop_id not in unique:
				unique.append(plot.crop_id)
	return unique.size()

func _check_season_crop(season: int) -> int:
	for plot in GameManager.farm_crops.values():
		var crop_data = DataLoader.get_crop(plot.crop_id.to_int())
		if crop_data and season in crop_data.seasons and not plot.is_dead:
			return 1
	return 0

func _check_items_found(target_items: Array) -> bool:
	for item in target_items:
		if not GameManager.get_data("collection_shipped", {}).has(item) and \
		   not GameManager.get_data("collection_fish", {}).has(item) and \
		   not GameManager.get_data("collection_artifacts", {}).has(item) and \
		   not GameManager.get_data("collection_minerals", {}).has(item):
			return false
	return true

func _count_unique_gems() -> int:
	var gems = ["(O)60", "(O)62", "(O)64", "(O)66", "(O)68", "(O)70"]
	var count = 0
	for gem in gems:
		if GameManager.get_data("collection_minerals", {}).has(gem):
			count += 1
	return count

func _check_legendary_fish(target: Array) -> bool:
	for fish in target:
		if not GameManager.get_data("collection_fish", {}).has(fish):
			return false
	return true

func _count_unique_fish() -> int:
	return GameManager.get_data("collection_fish", {}).size()

func _count_unique_forage() -> int:
	return GameManager.get_data("collection_artifacts", {}).size()  # Aproximação

func _check_boss_killed(target: Array) -> bool:
	var killed = GameManager.get_data("bosses_killed", [])
	for boss in target:
		if boss not in killed:
			return false
	return true

func _get_max_friendship() -> int:
	var max_f = 0
	for f in GameManager.friendships.values():
		max_f = max(max_f, f)
	return max_f / 250

func _count_friendship_at_least(hearts: int) -> int:
	var count = 0
	for f in GameManager.friendships.values():
		if f / 250 >= hearts:
			count += 1
	return count

func _count_locations_visited() -> int:
	return GameManager.get_data("locations_visited", {}).size()

func _check_all_tools_iridium() -> bool:
	var tools = ["Pickaxe", "Axe", "Hoe", "WateringCan", "TrashCan", "FishingRod"]
	for tool in tools:
		if GameManager.tools.get(tool, 0) < 3:
			return false
	return true

func _check_all_collections() -> bool:
	var collections = ["collection_shipped", "collection_fish", "collection_artifacts", "collection_minerals", "collection_recipes"]
	for coll in collections:
		if GameManager.get_data(coll, {}).size() < 100:  # Threshold arbitrário
			return false
	return true

func _count_unique_buildings() -> int:
	var types = []
	for b in GameManager.farm_buildings:
		if b.type not in types:
			types.append(b.type)
	return types.size()

## ==================== DESBLOQUEIO ====================
func _unlock_achievement(ach_id: String) -> void:
	if ach_id in GameManager.achievements:
		return

	GameManager.achievements.append(ach_id)

	var ach = ACHIEVEMENTS[ach_id]

	# Aplica recompensas
	var reward = ach.reward
	if reward.has("gold"):
		GameManager.gold += reward.gold
		GameManager.emit_signal("gold_changed", GameManager.gold)
	if reward.has("xp"):
		for skill in reward.xp:
			GameManager.add_skill_xp(_get_skill_index(skill), reward.xp[skill])
	if reward.has("item"):
		InventoryManager.add_item(reward.item, 1)
	if reward.has("title"):
		GameManager.set_data("title", reward.title)

	# Notificação
	HUD.show_notification("🏆 Conquista Desbloqueada!", "%s: %s" % [ach.name, ach.description], Color(1.0, 0.9, 0.2))

	if ParticleManager:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			ParticleManager.show_level_up(player.global_position, "Conquista!")

	if AudioManager:
		AudioManager.play_sfx("res://assets/sfx/achievement.ogg")

	GameManager.emit_signal("achievement_unlocked", ach_id)

func _get_skill_index(skill: String) -> int:
	return ["farming", "mining", "foraging", "fishing", "combat"].find(skill)

## ==================== UI ====================
func open_achievements_menu() -> void:
	var panel = Panel.new()
	panel.name = "AchievementsMenu"
	panel.anchors_preset = 15
	panel.offset_left = 50
	panel.offset_top = 30
	panel.offset_right = -50
	panel.offset_bottom = -30

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🏆 Conquistas"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 28
	vbox.add_child(title)

	# Progresso geral
	var total = ACHIEVEMENTS.size()
	var unlocked = GameManager.achievements.size()
	var progress = Label.new()
	progress.text = "Progresso: %d/%d (%.1f%%)" % [unlocked, total, unlocked/total*100]
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.theme_override_font_size = 16
	vbox.add_child(progress)

	# Filtros
	var filter_bar = HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 5)
	var categories = ["all", "farming", "mining", "fishing", "foraging", "combat", "social", "money", "collections", "cooking", "crafting", "exploration", "building", "time"]
	for cat in categories:
		var btn = Button.new()
		btn.text = cat.capitalize()
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(80, 30)
		btn.pressed.connect(_filter_achievements.bind(cat))
		filter_bar.add_child(btn)
	vbox.add_child(filter_bar)

	# Lista de conquistas
	var scroll = ScrollContainer.new()
	var grid = GridContainer.new()
	grid.columns = 1
	grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(grid)
	scroll.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(scroll)

	_populate_achievements_grid(grid, "all")

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _populate_achievements_grid(grid: GridContainer, filter: String) -> void:
	grid.clear()

	for ach_id in ACHIEVEMENTS:
		var ach = ACHIEVEMENTS[ach_id]
		if filter != "all" and ach.category != filter:
			continue

		var unlocked = ach_id in GameManager.achievements
		if not unlocked and ach.hidden:
			continue  # Não mostra ocultas não desbloqueadas

		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(0, 80)

		var hbox = HBoxContainer.new()
		panel.add_child(hbox)

		var icon = Label.new()
		icon.text = ach.icon if unlocked else "❓"
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.custom_minimum_size = Vector2(60, 60)
		icon.theme_override_font_size = 28
		if not unlocked:
			icon.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		hbox.add_child(icon)

		var info = VBoxContainer.new()
		hbox.add_child(info)

		var name = Label.new()
		name.text = ach.name if unlocked else "???"
		name.theme_override_font_size = 18
		if not unlocked:
			name.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		info.add_child(name)

		var desc = Label.new()
		desc.text = ach.description if unlocked else "Conquista oculta"
		desc.theme_override_font_size = 13
		desc.autowrap_mode = 1
		if not unlocked:
			desc.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		info.add_child(desc)

		var tier = Label.new()
		tier.text = "Tier %d | %s" % [ach.tier, ach.category.capitalize()]
		tier.theme_override_font_size = 11
		tier.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		info.add_child(tier)

		if unlocked:
			var reward = Label.new()
			var rew = ACHIEVEMENTS[ach_id].reward
			var rew_text = []
			if rew.has("gold"): rew_text.append("%dg" % rew.gold)
			if rew.has("item"): rew_text.append(rew.item)
			if rew.has("title"): rew_text.append("Título: %s" % rew.title)
			reward.text = "Recompensa: " + ", ".join(rew_text)
			reward.theme_override_font_size = 12
			reward.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			info.add_child(reward)

		grid.add_child(panel)

	get_tree().root.get_child(0).add_child(panel)

## ==================== PERSISTÊNCIA ====================
func get_save_data() -> Dictionary:
	return {
		"achievements": GameManager.achievements
	}

func load_save_data(data: Dictionary) -> void:
	if GameManager:
		GameManager.achievements = data.get("achievements", [])