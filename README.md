# Stardew-Like 🌾

Um farming simulator inspirado em Stardew Valley, feito no **Godot 4.7.2** com GDScript.

> **Projeto pessoal** - não para publicação, apenas para diversão e aprendizado.

## ✨ Features Implementadas

### 🌱 Farming System
- Grade 64x64 de plots (arar, plantar, regar, colher)
- 20+ cultivos com estações, regrowth, qualidade (normal/prata/ouro/irídio)
- Fertilizantes (básico, qualidade, retentor de água)
- Árvores frutíferas (28 dias, frutas por estação)
- Estufa 10x12 (ano todo) + sprinklers

### 🏠 Buildings & Animals
- 15+ edifícios (casa, celeiro, galinheiro, celeiro deluxe, poço, moinho, etc.)
- Sistema de construção com tempo (Robin) + relocação/demolição
- 8 tipos de animais (galinha, vaca, cabra, ovelha, porco, coelho, dinossauro, avestruz)
- Amizade 0-1000, humor 0-255, gravidez, produtos por qualidade

### 👥 NPCs & Social
- 28 NPCs com agendas semanais/estações/clima
- 10 níveis de amizade (2500 pts) com diálogos únicos por nível
- Presentes (love/like/neutral/dislike/hate) + reações específicas
- Eventos de coração (2, 4, 6, 8, 10 corações)
- Namoro (buquê 8♥), casamento (pendente sereia 10♥), filhos, divórcio

### ⛏️ Minas & Combate
- 120 andares, 3 biomas (terra, gelo, lava)
- Monstros, minérios, geodas, baús, escadas
- Elevador a cada 5 andares
- Armas, anéis, botas com stats

### 🎣 Pesca
- Minigame visual com shader de água animado
- 50+ peixes por estação/hora/clima/local
- Varas (bambu, fibra de vidro, irídio) + 9 anzóis/iscas
- Qualidade + tamanho + perfect catch (1.4x XP)

### 🎪 Festivais & Quests
- 8 festivais sazonais com minigames
- Centro Comunitário (6 salas, 30+ bundles) → Junimo Hut
- Museu (100 doações + recompensas)
- Missões diárias/história + Special Orders (4 quadros)

### 📺 TV & Mail
- 4 canais: Adivinha, Tempo, Queen of Sauce, Vivendo da Terra
- 7 tipos de correio (carta, pacote, quest, festival, conta, secreta, relacionamento)
- Notas secretas (25+)

### 🎨 Customização & QOL
- Personagem: pele, cabelo, olhos, roupas equipáveis (chapéu/camisa/calça/botas/anel×2)
- Coleções (enviados, peixes, artefatos, minerais, receitas, conquistas)
- HUD: quest tracker (3), notificações toast, level-up animado
- Pause menu (save/load/settings/quit)
- Settings (áudio/vídeo/controles/gameplay) persistido em JSON
- Logger automático (captura erros, salva em `user://logs/`, auto-save em crash)

### ⚙️ Technical
- 22 Autoloads (GameManager, TimeManager, InventoryManager, SaveManager, DataLoader, BuildingManager, FestivalManager, QuestManager, RelationshipManager, BuffManager, MineManager, FishingManager, SpecialOrdersBoard, CommunityCenter, Museum, Greenhouse, MineCart, PetManager, TVChannels, MailSystem, CharacterCustomization, CollectionsMenu, ParticleManager, AudioManager, Logger)
- 6 Resources tipados (CropData, ItemData, NPCData, BuildingData, RecipeData, ShopData)
- 47 JSONs de dados do Stardew carregados em runtime
- Save/Load JSON (4 slots + autosave a cada hora in-game)
- Sinal-based architecture (desacoplado)
- Placeholder assets procedurais (roda sem assets externos)

## 🚀 Como Rodar

1. Instale **Godot 4.7.2** (ou 4.x)
2. Clone/baixe este repositório
3. Abra o Godot → Import Project → selecione `project.godot`
4. Rode a cena principal: `res://scenes/world/world.tscn`

### Controles
| Tecla | Ação |
|-------|------|
| WASD / Setas | Mover |
| E / Espaço | Interagir |
| Clique Esquerdo | Usar ferramenta |
| Clique Direito | Ação alternativa |
| Tab / I | Inventário |
| ESC | Pause Menu |
| 1-8 | Hotbar slots |

## 📁 Estrutura

```
stardew_godot/
├── project.godot
├── .gitignore
├── README.md
├── scripts/
│   ├── core/          # 22 autoloads + systems
│   ├── data/          # 6 Resources + DataLoader
│   ├── entities/      # Player, NPC, Crop, Animal, Building, Pet
│   └── ui/            # HUD, Menus (Shop, Crafting, Cooking, Fishing, etc.)
├── scenes/
│   ├── world/         # world.tscn (main)
│   ├── entities/      # .tscn para cada entidade
│   └── ui/            # .tscn para cada menu
└── resources/
    ├── data/          # 47 JSONs (Crops, Objects, NPCs, Buildings, etc.)
    └── sprites/       # (placeholder - usa procedural)
```

## 📊 Progresso

| Sistema | Status |
|---------|--------|
| Core Farming | ✅ Completo |
| Buildings/Animals | ✅ Completo |
| NPCs/Social | ✅ Completo |
| Minas/Combate | ✅ Completo |
| Pesca | ✅ Completo |
| Festivais/CC/Museu | ✅ Completo |
| TV/Mail/Secrets | ✅ Completo |
| Customização | ✅ Completo |
| UI/HUD/Menus | ✅ Completo |
| Audio/Particles | ✅ Completo |
| Save/Load/Settings | ✅ Completo |

## 🛠️ Tech Stack

- **Engine**: Godot 4.7.2
- **Language**: GDScript (tipado)
- **Architecture**: Resource-based + Autoload singletons + Signals
- **Data**: JSON → Resource cache (runtime)
- **Persistence**: JSON serialization

## 📝 Licença

Uso pessoal apenas. Assets e dados baseados em Stardew Valley (ConcernedApe) - não para distribuição comercial.

---

**Feito com 💚 para diversão própria. Aproveite a fazenda!** 🌻