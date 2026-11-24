@tool
class_name BuildingData
extends Resource

## Nome interno (chave do JSON)
@export var internal_name: String = ""

## Nome para exibição (chave de localização)
@export var display_name: String = ""

## Descrição (chave de localização)
@export var description: String = ""

## Caminho da textura do edifício
@export var texture_path: String = ""

## Skins disponíveis
@export var skins: Array[String] = []

## True se desenha sombra
@export var draw_shadow: bool = true

## Tile do sinal de upgrade (x, y)
@export var upgrade_sign_tile: Vector2i = Vector2i(-1, -1)

## Altura do sinal de upgrade
@export var upgrade_sign_height: float = 0.0

## Tamanho em tiles (largura, altura)
@export var size: Vector2i = Vector2i(3, 2)

## True se desaparece quando jogador está atrás
@export var fade_when_behind: bool = true

## Retângulo de origem na textura (0,0,0,0 = textura inteira)
@export var source_rect: Rect2i = Rect2i(0, 0, 0, 0)

## Offset sazonal
@export var season_offset: Vector2i = Vector2i(0, 0)

## Offset de desenho (x, y)
@export var draw_offset: Vector2i = Vector2i(0, 0)

## Offset de ordenação de tile
@export var sort_tile_offset: float = 0.0

## Tipo de classe do edifício (ex: "StardewValley.Buildings.JunimoHut")
@export var building_type: String = ""

## Construtor: "Robin", "Wizard", "Marlon", etc.
@export var builder: String = "Robin"

## Dias para construir
@export var build_days: int = 2

## Custo em ouro
@export var build_cost: int = 0

## Materiais necessários: Array de {item_id, amount}
@export var build_materials: Array[Dictionary] = []

## True se construção mágica (instantânea)
@export var magical_construction: bool = false

## Offset no menu de construção
@export var build_menu_draw_offset: Vector2i = Vector2i(0, 0)

## Posição da porta humana (x, y) relativo ao edifício
@export var human_door: Vector2i = Vector2i(-1, -1)

## Posição da porta de animais
@export var animal_door: Dictionary = {}

## Duração abertura/fechamento porta animais
@export var animal_door_open_duration: float = 0.0
@export var animal_door_close_duration: float = 0.0

## Máximo de ocupantes
@export var max_occupants: int = 0

## Tipos de ocupantes válidos
@export var valid_occupant_types: Array[String] = []

## True se permite gravidez de animais
@export var allow_animal_pregnancy: bool = false

## Capacidade de feno
@export var hay_capacity: int = 0

## Baús do edifício
@export var chests: Array[Dictionary] = []

## Raio de propriedades adicionais de tile
@export var additional_tile_property_radius: int = 0

## True se permite piso por baixo
@export var allows_flooring_underneath: bool = true

## Retorna nome exibido
func get_display_name() -> String:
	return display_name if display_name != "" else internal_name

## Verifica se jogador tem materiais para construir
func can_afford(player_gold: int, player_inventory: Dictionary) -> bool:
	if player_gold < build_cost:
		return false
	for material in build_materials:
		var item_id = material.get("ItemId", "")
		var amount = material.get("Amount", 0)
		var has_amount = player_inventory.get(item_id, 0)
		if has_amount < amount:
			return false
	return true

## Obtém custo total formatado para UI
func get_cost_description() -> String:
	var parts = []
	if build_cost > 0:
		parts.append("%dg" % build_cost)
	for material in build_materials:
		var item_id = material.get("ItemId", "")
		var amount = material.get("Amount", 0)
		parts.append("%dx %s" % [amount, item_id])
	return ", ".join(parts)