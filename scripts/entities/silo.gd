class_name Silo
extends Node2D

## Silo - armazena feno automaticamente ao cortar grama

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var hay_label: Label = $HayLabel

## Estado
var hay_stored: int = 0
var hay_capacity: int = 240
var building_data: BuildingData = null

## ==================== SINAIS ====================
signal hay_changed(amount: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	interaction_area.monitorable = true
	interaction_area.monitoring = true
	interaction_area.area_entered.connect(_on_player_entered)
	interaction_area.area_exited.connect(_on_player_exited)

	progress_bar.visible = false
	hay_label.visible = false

	_load_state()

	# Conecta ao BuildingManager para receber feno
	if BuildingManager:
		BuildingManager.hay_cut.connect(_on_hay_cut)

func _on_player_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.show_interaction_prompt("E: Ver Silo (%d/%d)" % [hay_stored, hay_capacity], global_position + Vector2(0, -50))

func _on_player_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		HUD.hide_interaction_prompt()

func interact() -> void:
	_open_ui()

func _on_hay_cut(amount: int) -> void:
	# Chamado quando player corta grama com foice
	var space = hay_capacity - hay_stored
	var stored = min(amount, space)
	hay_stored += stored
	_save_state()
	_update_ui()

	if stored < amount:
		HUD.show_message("Silo cheio! %d feno perdido." % (amount - stored))

	# Notificação
	if stored > 0:
		HUD.show_notification("🏠 Silo", "%d feno armazenado (%d/%d)" % [stored, hay_stored, hay_capacity], Color(0.5, 1.0, 0.5))

	emit_signal("hay_changed", hay_stored)

func _open_ui() -> void:
	var panel = Panel.new()
	panel.name = "SiloUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 150
	panel.offset_right = -200
	panel.offset_bottom = -150

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🏠 Silo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	# Barra de progresso visual
	var bar_container = HBoxContainer.new()
	bar_container.alignment = HORIZONTAL_ALIGNMENT_CENTER

	var bar = ProgressBar.new()
	bar.max_value = hay_capacity
	bar.value = hay_stored
	bar.custom_minimum_size = Vector2(300, 30)
	bar_container.add_child(bar)

	vbox.add_child(bar_container)

	var info = Label.new()
	info.text = "Feno: %d / %d" % [hay_stored, hay_capacity]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.theme_override_font_size = 18
	vbox.add_child(info)

	var desc = Label.new()
	desc.text = "Armazena feno automaticamente ao cortar grama com a foice.\nCada silo comporta 240 unidades."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = 1
	desc.theme_override_font_size = 13
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc)

	# Se tem edifícios de animais, mostra consumo
	if BuildingManager:
		var total_animals = 0
		for building in BuildingManager.get_all_buildings():
			if building.building_type in ["Coop", "Barn", "BigCoop", "BigBarn", "DeluxeCoop", "DeluxeBarn"]:
				total_animals += building.occupants.size()

		if total_animals > 0:
			var consumption = Label.new()
			consumption.text = "Consumo diário: %d feno/dia (%d animais)" % [total_animals, total_animals]
			consumption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			consumption.theme_override_font_size = 13
			consumption.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
			vbox.add_child(consumption)

			var days_left = total_animals > 0 ? hay_stored / total_animals : 999
			var days_label = Label.new()
			days_label.text = "Duração estimada: %d dias" % days_left
			days_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			days_label.theme_override_font_size = 13
			vbox.add_child(days_label)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(panel.queue_free.bind())
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _update_ui() -> void:
	# Atualiza labels se UI aberta
	var ui = get_tree().root.get_child(0).get_node_or_null("SiloUI")
	if ui:
		var bar = ui.get_node_or_null("VBoxContainer/HBoxContainer/ProgressBar")
		if bar:
			bar.value = hay_stored
		var info = ui.get_node_or_null("VBoxContainer/Label[1]")
		if info:
			info.text = "Feno: %d / %d" % [hay_stored, hay_capacity]

func _save_state() -> void:
	if GameManager:
		GameManager.set("silo_%s" % [name], {
			"hay_stored": hay_stored,
			"hay_capacity": hay_capacity
		})

func _load_state() -> void:
	if GameManager:
		var data = GameManager.get("silo_%s" % [name], {})
		if data:
			hay_stored = data.get("hay_stored", 0)
			hay_capacity = data.get("hay_capacity", 240)