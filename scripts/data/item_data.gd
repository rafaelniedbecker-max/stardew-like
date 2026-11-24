@tool
class_name ItemData
extends Resource

## ID numérico do item (chave do JSON original)
@export var id: int = 0

## Nome interno (ex: "Parsnip", "Copper Ore")
@export var internal_name: String = ""

## Nome para exibição (chave de localização)
@export var display_name: String = ""

## Descrição (chave de localização)
@export var description: String = ""

## Tipo do item: "Basic", "Seeds", "Food", "Drink", "Tool", "Weapon", "Ring", "Boots", "Hat", "Furniture", "Wallpaper", "Flooring", "Crafting", "Minerals", "Artifact", "Trinket", "Quest", "Litter", "Sword", "Dagger", "Club", "Slingshot", "FishingRod", "Trinket"
@export var item_type: String = "Basic"

## Categoria numérica (para agrupamento em lojas/inventário)
@export var category: int = -999

## Preço de venda base
@export var price: int = 0

## Índice do sprite na spritesheet de objetos
@export var sprite_index: int = 0

## Se usa overlay de cor do próximo índice
@export var color_overlay_from_next_index: bool = false

## Comestibilidade (negativo = veneno, positivo = cura energia/saúde)
@export var edibility: int = 0

## True se é bebida (buffs diferentes)
@export var is_drink: bool = false

## Se pode ser dado de presente
@export var can_be_given_as_gift: bool = true

## Se pode ser jogado no lixo
@export var can_be_trashed: bool = true

## Excluir da coleção de pesca
@export var exclude_from_fishing_collection: bool = false

## Excluir da coleção de envio
@export var exclude_from_shipping_collection: bool = false

## Excluir de vendas aleatórias
@export var exclude_from_random_sale: bool = false

## Tags para busca/filtro (ex: "vegetable", "mineral", "cooking_ingredient")
@export var tags: Array[String] = []

## Dados de buff se for comida/bebida
@export var buff_id: String = ""

## Duração do buff em minutos (in-game)
@export var buff_duration: int = 0

## Se é ingrediente de receita
@export var is_cooking_ingredient: bool = false

## Se é ingrediente de crafting
@export var is_crafting_ingredient: bool = false

## Preço de compra em lojas (se diferente de venda)
@export var shop_buy_price: int = -1

## Nível de qualidade máximo (0=normal, 1=prata, 2=ouro, 3=irídio)
@export var max_quality: int = 3

## Textura customizada (se não usar spritesheet padrão)
@export var custom_texture: String = ""

## Retorna o nome exibido (fallback para internal_name)
func get_display_name() -> String:
	return display_name if display_name != "" else internal_name

## Verifica se é comestível
func is_edible() -> bool:
	return edibility != 0

## Verifica se tem buff
func has_buff() -> bool:
	return buff_id != ""

## Verifica se é semente
func is_seed() -> bool:
	return item_type == "Seeds"

## Verifica se é ferramenta
func is_tool() -> bool:
	return item_type in ["Tool", "Sword", "Dagger", "Club", "Slingshot", "FishingRod"]

## Verifica se é arma
func is_weapon() -> bool:
	return item_type in ["Sword", "Dagger", "Club", "Slingshot"]

## Verifica se é mobiliário
func is_furniture() -> bool:
	return item_type in ["Furniture", "Wallpaper", "Flooring"]

## Obtém preço de venda efetivo
func get_sell_price(quality: int = 0) -> int:
	var multiplier = 1.0
	match quality:
		1: multiplier = 1.25  # Prata
		2: multiplier = 1.5   # Ouro
		3: multiplier = 2.0   # Irídio
	return inti(price * multiplier)