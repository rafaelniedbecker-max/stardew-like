class_name Well
extends Node2D

## Poço - recarrega regador instantaneamente

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var water_particles: CPUParticles2D = $WaterParticles

## ==================== SINAIS ====================
signal water_refilled()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	if water_particles:
		water_particles.emitting = false

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.show_interaction_prompt("E: Encher Regador", global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	_refill_watering_can()

func _refill_watering_can() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Procura regador no inventário/hotbar
	if InventoryManager:
		var watering_can_id = ""
		var can_level = 0

		# Verifica hotbar
		for i in range(12):
			var item = InventoryManager.get_hotbar_item(i)
			if item.begins_with("(T)3"):  # Watering Can
				watering_can_id = item
				can_level = InventoryManager.get_tool_level("WateringCan")
				break

		if watering_can_id == "":
			# Verifica inventário
			for item_id in GameManager.inventory:
				if item_id.begins_with("(T)3"):
					watering_can_id = item_id
					can_level = InventoryManager.get_tool_level("WateringCan")
					break

		if watering_can_id != "":
			# Recarrega baseado no nível
			var capacities = [40, 55, 70, 100]  # Cobre, Ferro, Ouro, Irídio
			var max_water = capacities[can_level] if can_level < capacities.size() else 40

			# Simula recarga (no sistema real, o regador teria água atual)
			HUD.show_notification("💧 Poço", "Regador %s recarregado (%d/%d)" % [["Cobre", "Ferro", "Ouro", "Irídio"][can_level], max_water, max_water], Color(0.3, 0.7, 1.0))

			# Efeitos visuais
			if water_particles:
				water_particles.emitting = true
				water_particles.one_shot = true

			if AudioManager:
				AudioManager.play_sfx_at_position("res://assets/sfx/well_refill.ogg", global_position)

			if ParticleManager:
				ParticleManager.spawn_area("water", global_position + Vector2(0, -32), 15, 24.0)

			emit_signal("water_refilled")
		else:
			HUD.show_message("Você não tem um regador!")

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.show_interaction_prompt("E: Encher Regador", global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()