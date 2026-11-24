@tool
class_name CropData
extends Resource

## ID único da cultura (chave do JSON original)
@export var id: int = 0

## Nome interno (ex: "Parsnip", "Potato")
@export var internal_name: String = ""

## Estações válidas: 0=Spring, 1=Summer, 2=Fall, 3=Winter
@export var seasons: Array[int] = []

## Dias em cada fase de crescimento [phase1, phase2, phase3, ...]
@export var days_in_phase: Array[int] = []

## Dias para rebrotar após colheita (-1 = não rebrota)
@export var regrow_days: int = -1

## True se precisa de enxada elevada (trellis)
@export var is_raised: bool = false

## True se é cultura de arroz (paddy)
@export var is_paddy_crop: bool = false

## True se precisa de rega diária
@export var needs_watering: bool = true

## ID do item colhido (referencia Objects.json)
@export var harvest_item_id: String = ""

## Quantidade mínima por colheita
@export var harvest_min_stack: int = 1

## Quantidade máxima por colheita
@export var harvest_max_stack: int = 1

## Aumento máximo por nível de farming
@export var harvest_max_increase_per_farming_level: float = 0.0

## Chance extra de colheita adicional (0.0-1.0)
@export var extra_harvest_chance: float = 0.0

## Método de colheita: 0=normal, 1=foice, 2=pegada
@export var harvest_method: int = 0

## Qualidade mínima da colheita
@export var harvest_min_quality: int = 0

## Cores de tint para variações visuais
@export var tint_colors: Array[Color] = []

## Caminho da textura (TileSheets/crops)
@export var texture_path: String = ""

## Índice do sprite na spritesheet
@export var sprite_index: int = 0

## Conta para monocultura
@export var count_for_monoculture: bool = true

## Conta para policultura
@export var count_for_polyculture: bool = true

## Total de dias para crescer completamente (calculado)
@export var total_growth_days: int = 0:
	get:
		var total = 0
		for day in days_in_phase:
			total += day
		return total

## Número de fases de crescimento
@export var phase_count: int = 0:
	get:
		return days_in_phase.size()

## Retorna o índice da fase atual baseado no dia de crescimento
func get_phase_at_day(growth_day: int) -> int:
	var day_sum = 0
	for i in range(days_in_phase.size()):
		day_sum += days_in_phase[i]
		if growth_day < day_sum:
			return i
	return days_in_phase.size() - 1

## Verifica se pode ser plantada na estação atual
func can_plant_in_season(season: int) -> bool:
	return season in seasons

## Verifica se a cultura está totalmente crescida
func is_fully_grown(growth_day: int) -> bool:
	return growth_day >= total_growth_days

## Verifica se pode rebrotar
func can_regrow() -> bool:
	return regrow_days > 0