extends Node

## Gerenciador global de pets: adoção, spawn, múltiplos pets

@export var pet_scene: PackedScene
@export var pet_bowl_scene: PackedScene

## Estado
var current_pet: Pet = null
var pet_bowl_position: Vector2i = Vector2i(58, 14)  # Posição do pote de água
var has_pet_bowl: bool = true

## Tipos de pet disponíveis para adoção
const AVAILABLE_PETS = [
	{"type": "Cat", "name": "Gato", "cost": 1000, "description": "Independente, caça ratos, ronrona quando feliz."},
	{"type": "Dog", "name": "Cachorro", "cost": 1000, "description": "Leal, avisa de perigos, abana rabo quando feliz."}
]

## ==================== SINAIS ====================
signal pet_adopted(pet: Pet)
signal pet_removed()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_pet_data()
	if current_pet:
		# Defer spawn until player is ready
		call_deferred("_spawn_pet_deferred")

func _load_pet_data() -> void:
	if not GameManager:
		return

	var pet_data = GameManager.get_data("pet_data", {})
	if pet_data:
		_adopt_pet_from_data(pet_data)

func _adopt_pet_from_data(data: Dictionary) -> void:
	if not pet_scene:
		return

	current_pet = pet_scene.instantiate()
	current_pet.pet_type = data.get("pet_type", "Cat")
	current_pet.pet_name = data.get("pet_name", "")
	current_pet.load_save_data(data)

	# Don't add to world yet - wait for _spawn_pet_deferred
	emit_signal("pet_adopted", current_pet)

func _spawn_pet_deferred() -> void:
	# Wait for player to be in scene
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# Try again next frame
		call_deferred("_spawn_pet_deferred")
		return
	_spawn_pet()

func _spawn_pet() -> void:
	if not current_pet:
		return

	var world = get_tree().root.get_child(0)
	if not current_pet.is_inside_tree():
		world.add_child(current_pet)
	current_pet.global_position = _get_pet_spawn_position()

func _get_pet_spawn_position() -> Vector2:
	# Spawna perto da casa do jogador
	var player = get_tree().get_first_node_in_group("player")
	if player and player.is_inside_tree():
		return player.global_position + Vector2(-64, 0)
	return Vector2(320, 320)

## ==================== ADOÇÃO ====================
func open_adoption_menu() -> void:
	if current_pet:
		_show_message("Você já tem um pet: %s" % current_pet.pet_name)
		return

	var panel = Panel.new()
	panel.name = "PetAdoptionUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 150
	panel.offset_right = -200
	panel.offset_bottom = -150

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "🐾 Adotar um Pet - 1.000g"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	vbox.add_child(title)

	var gold_lbl = Label.new()
	gold_lbl.text = "Ouro: %d" % GameManager.gold
	gold_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(gold_lbl)

	for pet_info in AVAILABLE_PETS:
		var btn = Button.new()
		btn.text = "%s %s - %s\n    %s" % [
			"🐱" if pet_info.type == "Cat" else "🐶",
			pet_info.name,
			pet_info.description,
			"Clique para adotar"
		]
		btn.custom_minimum_size = Vector2(0, 80)
		btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_adopt_pet.bind(pet_info.type))
		vbox.add_child(btn)

	var close_btn = Button.new()
	close_btn.text = "Cancelar"
	close_btn.pressed.connect(panel.queue_free)
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _adopt_pet(pet_type: String) -> void:
	if GameManager.gold < 1000:
		_show_message("Ouro insuficiente! Precisa de 1.000g.")
		return

	GameManager.gold -= 1000

	if pet_scene:
		current_pet = pet_scene.instantiate()
		current_pet.pet_type = pet_type
		current_pet.pet_name = ""  # Será gerado aleatoriamente

		var world = get_tree().root.get_child(0)
		world.add_child(current_pet)
		current_pet.global_position = _get_pet_spawn_position()

		_save_pet_data()
		emit_signal("pet_adopted", current_pet)
		_show_message("Você adotou um %s! Dê um nome a ele." % ("Gato" if pet_type == "Cat" else "Cachorro"))

		# Abre diálogo de nome
		_show_name_dialog()
	else:
		_show_message("Pet scene não configurada!")

func _show_name_dialog() -> void:
	if not current_pet:
		return

	var dialog = LineEdit.new()
	dialog.name = "PetNameDialog"
	dialog.placeholder_text = "Digite o nome do pet..."
	dialog.anchors_preset = 15
	dialog.offset_left = 200
	dialog.offset_top = 200
	dialog.offset_right = -200
	dialog.offset_bottom = -150

	var panel = Panel.new()
	panel.add_child(dialog)
	get_tree().root.get_child(0).add_child(panel)

	dialog.grab_focus()
	dialog.text_submitted.connect(_on_name_submitted.bind(panel))

func _on_name_submitted(name: String, panel: Panel) -> void:
	if current_pet:
		current_pet.rename(name.strip_edges())
	panel.queue_free()

## ==================== CUIDADOS ====================
func pet_current_pet() -> bool:
	if not current_pet:
		_show_message("Você não tem um pet.")
		return false

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return false

	var dist = current_pet.global_position.distance_to(player.global_position)
	if dist > 64:
		_show_message("%s está muito longe." % current_pet.pet_name)
		return false

	return current_pet.pet()

func feed_current_pet() -> void:
	if not current_pet:
		_show_message("Você não tem um pet.")
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var dist = current_pet.global_position.distance_to(player.global_position)
	if dist > 64:
		_show_message("%s está muito longe." % current_pet.pet_name)
		return

	# Verifica se tem ração
	if InventoryManager.remove_item("(O)432", 1) or InventoryManager.remove_item("(O)433", 1):  # Pet food
		current_pet.feed()
	else:
		_show_message("Você precisa de ração para pet!")

func play_with_current_pet() -> void:
	if not current_pet:
		_show_message("Você não tem um pet.")
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var dist = current_pet.global_position.distance_to(player.global_position)
	if dist > 64:
		_show_message("%s está muito longe." % current_pet.pet_name)
		return

	current_pet.play_with()

## ==================== REMOÇÃO ====================
func remove_pet() -> void:
	if not current_pet:
		return

	var name = current_pet.pet_name
	current_pet.queue_free()
	current_pet = null
	GameManager.set_data("pet_data", {})
	emit_signal("pet_removed")
	_show_message("%s foi para um novo lar." % name)

## ==================== PROCESSAMENTO DIÁRIO ====================
func process_daily() -> void:
	if current_pet:
		current_pet.process_daily()
		_save_pet_data()

	# Enche o pote de água
	if has_pet_bowl:
		_fill_water_bowl()

func _fill_water_bowl() -> void:
	# Lógica visual do pote de água
	pass

## ==================== UI STATUS ====================
func open_pet_status() -> void:
	if not current_pet:
		_show_message("Você não tem um pet.")
		return

	var panel = Panel.new()
	panel.name = "PetStatusUI"
	panel.anchors_preset = 15
	panel.offset_left = 200
	panel.offset_top = 150
	panel.offset_right = -200
	panel.offset_bottom = -150

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var icon = "🐱" if current_pet.pet_type == "Cat" else "🐶"
	var title = Label.new()
	title.text = "%s %s" % [icon, current_pet.pet_name]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 28
	vbox.add_child(title)

	var status = current_pet.get_status_text()
	var lbl = Label.new()
	lbl.text = status
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.theme_override_font_size = 18
	vbox.add_child(lbl)

	var hearts = current_pet.get_friendship_hearts()
	var heart_bar = ProgressBar.new()
	heart_bar.max_value = 5
	heart_bar.value = hearts
	heart_bar.custom_minimum_size = Vector2(200, 20)
	vbox.add_child(heart_bar)

	# Botões de ação
	var btn_pet = Button.new()
	btn_pet.text = "Acariciar"
	btn_pet.pressed.connect(pet_current_pet)
	vbox.add_child(btn_pet)

	var btn_feed = Button.new()
	btn_feed.text = "Dar Ração"
	btn_feed.pressed.connect(feed_current_pet)
	vbox.add_child(btn_feed)

	var btn_play = Button.new()
	btn_play.text = "Brincar"
	btn_play.pressed.connect(play_with_current_pet)
	vbox.add_child(btn_play)

	var btn_rename = Button.new()
	btn_rename.text = "Renomear"
	btn_rename.pressed.connect(_show_name_dialog)
	vbox.add_child(btn_rename)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _save_pet_data() -> void:
	if not GameManager or not current_pet:
		return
	GameManager.set_data("pet_data", current_pet.get_save_data())

func _show_message(text: String) -> void:
	print("PetManager: %s" % text)
	if GameManager and GameManager.hud:
		GameManager.hud.show_message(text)

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"pet_data": current_pet.get_save_data() if current_pet else {},
		"has_pet_bowl": has_pet_bowl,
		"pet_bowl_position": {"x": pet_bowl_position.x, "y": pet_bowl_position.y}
	}

func load_save_data(data: Dictionary) -> void:
	has_pet_bowl = data.get("has_pet_bowl", true)
	var pos = data.get("pet_bowl_position", {})
	pet_bowl_position = Vector2i(pos.get("x", 58), pos.get("y", 14))

	var pet_data = data.get("pet_data", {})
	if pet_data:
		_adopt_pet_from_data(pet_data)