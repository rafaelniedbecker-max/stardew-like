class_name CharacterCustomization
extends Node

## Sistema de Personalização: aparência, roupas, chapéus, calças, camisas, acessórios

@export var customization_ui_scene: PackedScene

## Estado visual do jogador
var skin_color: int = 0       # 0-5 (tons de pele)
var hair_style: int = 0       # 0-31 (estilos de cabelo)
var hair_color: int = 0       # 0-15 (cores de cabelo)
var eye_color: int = 0        # 0-5 (cores de olhos)
var pants_style: int = 0      # 0-15 (estilos de calça)
var pants_color: int = 0      # 0-15 (cores de calça)
var shirt_style: int = 0      # 0-15 (estilos de camisa)
var shirt_color: int = 0      # 0-15 (cores de camisa)
var shoes_color: int = 0      # 0-15 (cores de sapato)
var accessory: int = 0        # 0-10 (acessórios: óculos, brincos, etc.)
var hat: int = -1             # -1 = sem chapéu, 0+ = ID do chapéu
var gender: int = 0           # 0 = masculino, 1 = feminino, 2 = não-binário

## Roupas equipadas (itens do inventário)
var equipped_hat: String = ""      # Item ID do chapéu equipado
var equipped_shirt: String = ""    # Item ID da camisa equipada
var equipped_pants: String = ""    # Item ID da calça equipada
var equipped_boots: String = ""    # Item ID das botas equipadas
var equipped_ring: String = ""     # Item ID do anel equipado (slot 1)
var equipped_ring2: String = ""    # Item ID do anel equipado (slot 2)

## Paletas de cores (baseado no Stardew)
const SKIN_COLORS = [
	Color(1.0, 0.87, 0.77),  # Claro
	Color(0.96, 0.76, 0.63),
	Color(0.87, 0.65, 0.51),
	Color(0.73, 0.51, 0.39),
	Color(0.55, 0.35, 0.25),
	Color(0.35, 0.22, 0.16)   # Escuro
]

const HAIR_COLORS = [
	Color(0.15, 0.1, 0.05),    # Preto
	Color(0.25, 0.15, 0.1),    # Castanho escuro
	Color(0.4, 0.25, 0.15),    # Castanho médio
	Color(0.55, 0.35, 0.2),    # Castanho claro
	Color(0.7, 0.5, 0.25),     # Loiro escuro
	Color(0.85, 0.7, 0.35),    # Loiro
	Color(0.95, 0.85, 0.5),    # Loiro claro
	Color(0.8, 0.3, 0.2),      # Ruivo escuro
	Color(0.95, 0.45, 0.25),   # Ruivo
	Color(0.6, 0.25, 0.3),     # Rosa
	Color(0.3, 0.2, 0.5),      # Roxo
	Color(0.2, 0.4, 0.7),      # Azul
	Color(0.2, 0.6, 0.3),      # Verde
	Color(0.9, 0.9, 0.9),      # Branco
	Color(0.5, 0.5, 0.5),      # Cinza
	Color(0.1, 0.1, 0.1)       # Quase preto
]

const EYE_COLORS = [
	Color(0.3, 0.2, 0.1),   # Marrom escuro
	Color(0.5, 0.35, 0.2),  # Marrom
	Color(0.4, 0.5, 0.3),   # Verde
	Color(0.3, 0.5, 0.8),   # Azul
	Color(0.5, 0.4, 0.6),   # Cinza
	Color(0.6, 0.3, 0.5)    # Ambar
]

const CLOTHING_COLORS = [
	Color(0.9, 0.9, 0.9),   # Branco
	Color(0.2, 0.2, 0.2),   # Preto
	Color(0.6, 0.2, 0.2),   # Vermelho escuro
	Color(0.2, 0.5, 0.2),   # Verde escuro
	Color(0.2, 0.3, 0.6),   # Azul escuro
	Color(0.5, 0.3, 0.6),   # Roxo
	Color(0.7, 0.5, 0.2),   # Marrom
	Color(0.5, 0.5, 0.5),   # Cinza
	Color(0.9, 0.6, 0.2),   # Laranja
	Color(0.9, 0.8, 0.2),   # Amarelo
	Color(0.8, 0.3, 0.5),   # Rosa
	Color(0.3, 0.6, 0.7),   # Ciano
	Color(0.6, 0.7, 0.3),   # Lima
	Color(0.7, 0.4, 0.2),   # Marrom claro
	Color(0.4, 0.4, 0.5),   # Azul acinzentado
	Color(0.95, 0.95, 0.8)  # Creme
]

## ==================== SINAIS ====================
signal appearance_changed()
signal clothing_changed(slot: String, item_id: String)
signal color_changed(part: String, color_index: int)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_appearance()
	# Defer applying appearance until player is ready
	call_deferred("_apply_to_player_deferred")

func _apply_to_player_deferred() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		call_deferred("_apply_to_player_deferred")
		return
	_apply_to_player()

func _load_appearance() -> void:
	if not GameManager:
		return

	skin_color = GameManager.get("player_skin", 0)
	hair_style = GameManager.get("player_hair", 0)
	hair_color = GameManager.get("player_hair_color", 0)
	eye_color = GameManager.get("player_eyes", 0)
	pants_style = GameManager.get("player_pants", 0)
	pants_color = GameManager.get("player_pants_color", 0)
	shirt_style = GameManager.get("player_shirt", 0)
	shirt_color = GameManager.get("player_shirt_color", 0)
	shoes_color = GameManager.get("player_shoes", 0)
	accessory = GameManager.get("player_accessory", 0)
	hat = GameManager.get("player_hat", -1)
	gender = GameManager.get("player_gender", 0)

	# Roupas equipadas
	equipped_hat = GameManager.get("equipped_hat", "")
	equipped_shirt = GameManager.get("equipped_shirt", "")
	equipped_pants = GameManager.get("equipped_pants", "")
	equipped_boots = GameManager.get("equipped_boots", "")
	equipped_ring = GameManager.get("equipped_ring", "")
	equipped_ring2 = GameManager.get("equipped_ring2", "")

func _apply_to_player() -> void:
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var anim = player.get_node_or_null("AnimatedSprite2D")
	if not anim:
		return

	# Aplica cores nas partes do sprite (usa shader ou modulação)
	_set_player_colors(player)

	# Aplica chapéu se equipado
	if equipped_hat != "":
		_equip_hat_visual(equipped_hat)
	else:
		_remove_hat_visual()

func _set_player_colors(player: Node) -> void:
	# Em implementação real, usa shader para colorir partes específicas
	# Por agora, armazena nas propriedades do player para o shader usar
	player.set("skin_color", SKIN_COLORS[skin_color])
	player.set("hair_color", HAIR_COLORS[hair_color])
	player.set("eye_color", EYE_COLORS[eye_color])
	player.set("pants_color", CLOTHING_COLORS[pants_color])
	player.set("shirt_color", CLOTHING_COLORS[shirt_color])
	player.set("shoes_color", CLOTHING_COLORS[shoes_color])

func _equip_hat_visual(item_id: String) -> void:
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var hat_node = player.get_node_or_null("HatSprite")
	if not hat_node:
		hat_node = Sprite2D.new()
		hat_node.name = "HatSprite"
		hat_node.z_index = 10
		player.add_child(hat_node)

	var item = DataLoader.get_item(item_id)
	if item and item.texture_path != "":
		hat_node.texture = load(item.texture_path)
	else:
		# Placeholder
		hat_node.texture = _create_hat_placeholder(item_id)

func _remove_hat_visual() -> void:
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var hat_node = player.get_node_or_null("HatSprite")
	if hat_node:
		hat_node.queue_free()

func _create_hat_placeholder(item_id: String) -> Texture2D:
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.4, 0.2))
	var tex = ImageTexture.create_from_image(img)
	return tex

## ==================== PERSONALIZAÇÃO DE APARÊNCIA ====================
func set_skin_color(index: int) -> void:
	skin_color = clamp(index, 0, SKIN_COLORS.size() - 1)
	GameManager.set("player_skin", skin_color)
	_apply_to_player()
	emit_signal("color_changed", "skin", skin_color)

func set_hair_style(index: int) -> void:
	hair_style = clamp(index, 0, 31)
	GameManager.set("player_hair", hair_style)
	_apply_to_player()
	emit_signal("appearance_changed")

func set_hair_color(index: int) -> void:
	hair_color = clamp(index, 0, HAIR_COLORS.size() - 1)
	GameManager.set("player_hair_color", hair_color)
	_apply_to_player()
	emit_signal("color_changed", "hair", hair_color)

func set_eye_color(index: int) -> void:
	eye_color = clamp(index, 0, EYE_COLORS.size() - 1)
	GameManager.set("player_eyes", eye_color)
	_apply_to_player()
	emit_signal("color_changed", "eyes", eye_color)

func set_pants_style(index: int) -> void:
	pants_style = clamp(index, 0, 15)
	GameManager.set("player_pants", pants_style)
	_apply_to_player()
	emit_signal("appearance_changed")

func set_pants_color(index: int) -> void:
	pants_color = clamp(index, 0, CLOTHING_COLORS.size() - 1)
	GameManager.set("player_pants_color", pants_color)
	_apply_to_player()
	emit_signal("color_changed", "pants", pants_color)

func set_shirt_style(index: int) -> void:
	shirt_style = clamp(index, 0, 15)
	GameManager.set("player_shirt", shirt_style)
	_apply_to_player()
	emit_signal("appearance_changed")

func set_shirt_color(index: int) -> void:
	shirt_color = clamp(index, 0, CLOTHING_COLORS.size() - 1)
	GameManager.set("player_shirt_color", shirt_color)
	_apply_to_player()
	emit_signal("color_changed", "shirt", shirt_color)

func set_shoes_color(index: int) -> void:
	shoes_color = clamp(index, 0, CLOTHING_COLORS.size() - 1)
	GameManager.set("player_shoes", shoes_color)
	_apply_to_player()
	emit_signal("color_changed", "shoes", shoes_color)

func set_accessory(index: int) -> void:
	accessory = clamp(index, 0, 10)
	GameManager.set("player_accessory", accessory)
	_apply_to_player()
	emit_signal("appearance_changed")

func set_gender(index: int) -> void:
	gender = clamp(index, 0, 2)
	GameManager.set("player_gender", gender)
	_apply_to_player()
	emit_signal("appearance_changed")

## ==================== ROUPAS EQUIPÁVEIS ====================
func equip_clothing(item_id: String) -> bool:
	var item = DataLoader.get_item(item_id)
	if not item:
		return false

	var slot = _get_clothing_slot(item)
	if slot == "":
		return false

	# Deséquipa item atual no slot
	var old_item = _get_equipped(slot)
	if old_item != "":
		InventoryManager.add_item(old_item, 1)

	# Equipa novo
	_set_equipped(slot, item_id)
	InventoryManager.remove_item(item_id, 1)

	_apply_clothing_visual(slot, item_id)
	emit_signal("clothing_changed", slot, item_id)
	_show_message("Equipado: %s" % item.display_name)
	return true

func unequip_clothing(slot: String) -> bool:
	var item_id = _get_equipped(slot)
	if item_id == "":
		return false

	if InventoryManager.add_item(item_id, 1):
		_set_equipped(slot, "")
		_remove_clothing_visual(slot)
		emit_signal("clothing_changed", slot, "")
		_show_message("Desequipado.")
		return true
	return false

func _get_clothing_slot(item: ItemData) -> String:
	# Baseado no tipo/categoria do item
	if item.category == "Hat":
		return "hat"
	elif item.category == "Shirt":
		return "shirt"
	elif item.category == "Pants":
		return "pants"
	elif item.category == "Boots":
		return "boots"
	elif item.category == "Ring":
		# Tenta slot 1, depois slot 2
		if equipped_ring == "":
			return "ring"
		elif equipped_ring2 == "":
			return "ring2"
	return ""

func _get_equipped(slot: String) -> String:
	match slot:
		"hat": return equipped_hat
		"shirt": return equipped_shirt
		"pants": return equipped_pants
		"boots": return equipped_boots
		"ring": return equipped_ring
		"ring2": return equipped_ring2
	return ""

func _set_equipped(slot: String, item_id: String) -> void:
	match slot:
		"hat":
			equipped_hat = item_id
			GameManager.set("equipped_hat", item_id)
		"shirt":
			equipped_shirt = item_id
			GameManager.set("equipped_shirt", item_id)
		"pants":
			equipped_pants = item_id
			GameManager.set("equipped_pants", item_id)
		"boots":
			equipped_boots = item_id
			GameManager.set("equipped_boots", item_id)
		"ring":
			equipped_ring = item_id
			GameManager.set("equipped_ring", item_id)
		"ring2":
			equipped_ring2 = item_id
			GameManager.set("equipped_ring2", item_id)

func _apply_clothing_visual(slot: String, item_id: String) -> void:
	match slot:
		"hat":
			_equip_hat_visual(item_id)
		"shirt":
			_apply_shirt_visual(item_id)
		"pants":
			_apply_pants_visual(item_id)
		"boots":
			_apply_boots_visual(item_id)
		"ring", "ring2":
			_apply_ring_visual(slot, item_id)

func _remove_clothing_visual(slot: String) -> void:
	match slot:
		"hat":
			_remove_hat_visual()
		"shirt":
			_reset_shirt_visual()
		"pants":
			_reset_pants_visual()
		"boots":
			_reset_boots_visual()
		"ring", "ring2":
			_remove_ring_visual(slot)

func _apply_shirt_visual(item_id: String) -> void:
	# Aplica textura da camisa ou cor
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var shirt_node = player.get_node_or_null("ShirtSprite")
	if not shirt_node:
		shirt_node = Sprite2D.new()
		shirt_node.name = "ShirtSprite"
		shirt_node.z_index = 5
		player.add_child(shirt_node)

	var item = DataLoader.get_item(item_id)
	if item and item.texture_path != "":
		shirt_node.texture = load(item.texture_path)
	else:
		shirt_node.modulate = CLOTHING_COLORS[shirt_color]

func _reset_shirt_visual() -> void:
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var shirt_node = player.get_node_or_null("ShirtSprite")
	if shirt_node:
		shirt_node.modulate = CLOTHING_COLORS[shirt_color]

func _apply_pants_visual(item_id: String) -> void:
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var pants_node = player.get_node_or_null("PantsSprite")
	if not pants_node:
		pants_node = Sprite2D.new()
		pants_node.name = "PantsSprite"
		pants_node.z_index = 4
		player.add_child(pants_node)

	var item = DataLoader.get_item(item_id)
	if item and item.texture_path != "":
		pants_node.texture = load(item.texture_path)
	else:
		pants_node.modulate = CLOTHING_COLORS[pants_color]

func _reset_pants_visual() -> void:
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var pants_node = player.get_node_or_null("PantsSprite")
	if pants_node:
		pants_node.modulate = CLOTHING_COLORS[pants_color]

func _apply_boots_visual(item_id: String) -> void:
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var boots_node = player.get_node_or_null("BootsSprite")
	if not boots_node:
		boots_node = Sprite2D.new()
		boots_node.name = "BootsSprite"
		boots_node.z_index = 3
		player.add_child(boots_node)

	var item = DataLoader.get_item(item_id)
	if item and item.texture_path != "":
		boots_node.texture = load(item.texture_path)
	else:
		boots_node.modulate = CLOTHING_COLORS[shoes_color]

func _reset_boots_visual() -> void:
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var boots_node = player.get_node_or_null("BootsSprite")
	if boots_node:
		boots_node.modulate = CLOTHING_COLORS[shoes_color]

func _apply_ring_visual(slot: String, item_id: String) -> void:
	# Anéis aparecem na mão - visual simples
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var ring_node = player.get_node_or_null("RingSprite_%s" % slot)
	if not ring_node:
		ring_node = Sprite2D.new()
		ring_node.name = "RingSprite_%s" % slot
		ring_node.z_index = 11
		ring_node.position = Vector2(8, -4) if slot == "ring" else Vector2(-8, -4)
		player.add_child(ring_node)

	var item = DataLoader.get_item(item_id)
	if item and item.texture_path != "":
		ring_node.texture = load(item.texture_path)
		ring_node.visible = true
	else:
		ring_node.visible = false

func _remove_ring_visual(slot: String) -> void:
	if not GameManager:
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var ring_node = player.get_node_or_null("RingSprite_%s" % slot)
	if ring_node:
		ring_node.queue_free()

## ==================== UI ====================
func open_customization_menu() -> void:
	if customization_ui_scene:
		var ui = customization_ui_scene.instantiate()
		ui.initialize(self)
		get_tree().root.get_child(0).add_child(ui)
	else:
		_show_generic_customization_ui()

func _show_generic_customization_ui() -> void:
	var panel = Panel.new()
	panel.name = "CustomizationUI"
	panel.anchors_preset = 15
	panel.offset_left = 50
	panel.offset_top = 30
	panel.offset_right = -50
	panel.offset_bottom = -30

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# Preview do personagem
	var preview_box = VBoxContainer.new()
	preview_box.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(preview_box)

	var preview_title = Label.new()
	preview_title.text = "Pré-visualização"
	preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(preview_title)

	# Placeholder do sprite do jogador
	var preview_sprite = Sprite2D.new()
	preview_sprite.name = "PreviewSprite"
	preview_sprite.custom_minimum_size = Vector2(128, 128)
	preview_box.add_child(preview_sprite)

	# Tabs de personalização
	var tabs = TabContainer.new()
	hbox.add_child(tabs)
	tabs.set_h_size_flags(Control.SIZE_EXPAND_FILL)

	# Tab Aparência
	_create_appearance_tab(tabs)
	# Tab Roupas
	_create_clothing_tab(tabs)
	# Tab Cores
	_create_colors_tab(tabs)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	panel.add_child(close_btn)
	close_btn.position = Vector2(400, 500)

	get_tree().root.get_child(0).add_child(panel)

func _create_appearance_tab(tabs: TabContainer) -> void:
	var tab = VBoxContainer.new()
	tabs.add_child(tab)
	tabs.set_tab_title(tabs.get_child_count() - 1, "👤 Aparência")

	var scroll = ScrollContainer.new()
	scroll.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	tab.add_child(scroll)

	var grid = GridContainer.new()
	grid.columns = 2
	scroll.add_child(grid)

	# Gênero
	var gender_box = VBoxContainer.new()
	grid.add_child(gender_box)
	var lbl = Label.new()
	lbl.text = "Gênero"
	gender_box.add_child(lbl)
	var gender_opt = OptionButton.new()
	gender_opt.add_item("Masculino")
	gender_opt.add_item("Feminino")
	gender_opt.add_item("Não-binário")
	gender_opt.selected = gender
	gender_opt.item_selected.connect(set_gender)
	gender_box.add_child(gender_opt)

	# Pele
	var skin_box = VBoxContainer.new()
	grid.add_child(skin_box)
	lbl = Label.new()
	lbl.text = "Tom de Pele"
	skin_box.add_child(lbl)
	var skin_opt = OptionButton.new()
	for i in range(SKIN_COLORS.size()):
		skin_opt.add_item("Opção %d" % (i + 1))
	skin_opt.selected = skin_color
	skin_opt.item_selected.connect(set_skin_color)
	skin_box.add_child(skin_opt)

	# Cabelo estilo
	var hair_box = VBoxContainer.new()
	grid.add_child(hair_box)
	lbl = Label.new()
	lbl.text = "Estilo de Cabelo"
	hair_box.add_child(lbl)
	var hair_opt = OptionButton.new()
	for i in range(32):
		hair_opt.add_item("Estilo %d" % (i + 1))
	hair_opt.selected = hair_style
	hair_opt.item_selected.connect(set_hair_style)
	hair_box.add_child(hair_opt)

	# Olhos
	var eye_box = VBoxContainer.new()
	grid.add_child(eye_box)
	lbl = Label.new()
	lbl.text = "Cor dos Olhos"
	eye_box.add_child(lbl)
	var eye_opt = OptionButton.new()
	for i in range(EYE_COLORS.size()):
		eye_opt.add_item("Cor %d" % (i + 1))
	eye_opt.selected = eye_color
	eye_opt.item_selected.connect(set_eye_color)
	eye_box.add_child(eye_opt)

	# Acessório
	var acc_box = VBoxContainer.new()
	grid.add_child(acc_box)
	lbl = Label.new()
	lbl.text = "Acessório"
	acc_box.add_child(lbl)
	var acc_opt = OptionButton.new()
	acc_opt.add_item("Nenhum")
	for i in range(1, 11):
		acc_opt.add_item("Acessório %d" % i)
	acc_opt.selected = accessory
	acc_opt.item_selected.connect(set_accessory)
	acc_box.add_child(acc_opt)

func _create_clothing_tab(tabs: TabContainer) -> void:
	var tab = VBoxContainer.new()
	tabs.add_child(tab)
	tabs.set_tab_title(tabs.get_child_count() - 1, "👕 Roupas")

	var scroll = ScrollContainer.new()
	scroll.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	tab.add_child(scroll)

	var vbox = VBoxContainer.new()
	scroll.add_child(vbox)

	# Slots de roupa
	var slots = [
		{"slot": "hat", "name": "Chapéu", "icon": "🎩", "equipped": equipped_hat},
		{"slot": "shirt", "name": "Camisa", "icon": "👕", "equipped": equipped_shirt},
		{"slot": "pants", "name": "Calça", "icon": "👖", "equipped": equipped_pants},
		{"slot": "boots", "name": "Botas", "icon": "👢", "equipped": equipped_boots},
		{"slot": "ring", "name": "Anel 1", "icon": "💍", "equipped": equipped_ring},
		{"slot": "ring2", "name": "Anel 2", "icon": "💍", "equipped": equipped_ring2}
	]

	for slot_info in slots:
		var hbox = HBoxContainer.new()
		vbox.add_child(hbox)

		var lbl = Label.new()
		lbl.text = "%s %s:" % [slot_info.icon, slot_info.name]
		lbl.custom_minimum_size = Vector2(120, 0)
		hbox.add_child(lbl)

		var equipped_name = "Nada equipado"
		if slot_info.equipped != "":
			var item = DataLoader.get_item(slot_info.equipped)
			equipped_name = item?.display_name ?? slot_info.equipped

		var equip_lbl = Label.new()
		equip_lbl.text = equipped_name
		equip_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		hbox.add_child(equip_lbl)

		var btn_equip = Button.new()
		btn_equip.text = "Equipar"
		btn_equip.pressed.connect(_open_equip_dialog.bind(slot_info.slot))
		hbox.add_child(btn_equip)

		var btn_unequip = Button.new()
		btn_unequip.text = "Remover"
		btn_unequip.pressed.connect(unequip_clothing.bind(slot_info.slot))
		btn_unequip.disabled = slot_info.equipped == ""
		hbox.add_child(btn_unequip)

func _open_equip_dialog(slot: String) -> void:
	var items = InventoryManager.get_items_by_category(_slot_to_category(slot))
	if items.is_empty():
		_show_message("Nenhum item compatível no inventário.")
		return

	var popup = PopupMenu.new()
	for item_id in items:
		var item = DataLoader.get_item(item_id)
		if item:
			popup.add_item("%s (x%d)" % [item.display_name, InventoryManager.get_item_count(item_id)], popup.get_item_count())
			popup.set_item_metadata(popup.get_item_count() - 1, item_id)

	popup.id_pressed.connect(_on_equip_selected.bind(slot))
	popup.popup_centered()

func _on_equip_selected(slot: String, idx: int) -> void:
	var popup = get_tree().root.get_child(0).get_node_or_null("PopupMenu")
	if not popup:
		return
	var item_id = popup.get_item_metadata(idx)
	equip_clothing(item_id)
	open_customization_menu()  # Refresh

func _slot_to_category(slot: String) -> String:
	match slot:
		"hat": return "Hat"
		"shirt": return "Shirt"
		"pants": return "Pants"
		"boots": return "Boots"
		"ring", "ring2": return "Ring"
	return ""

func _create_colors_tab(tabs: TabContainer) -> void:
	var tab = VBoxContainer.new()
	tabs.add_child(tab)
	tabs.set_tab_title(tabs.get_child_count() - 1, "🎨 Cores")

	var scroll = ScrollContainer.new()
	scroll.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	tab.add_child(scroll)

	var grid = GridContainer.new()
	grid.columns = 2
	scroll.add_child(grid)

	# Cabelo
	_add_color_picker(grid, "Cabelo", hair_color, HAIR_COLORS.size(), set_hair_color)
	# Camisa
	_add_color_picker(grid, "Camisa", shirt_color, CLOTHING_COLORS.size(), set_shirt_color)
	# Calça
	_add_color_picker(grid, "Calça", pants_color, CLOTHING_COLORS.size(), set_pants_color)
	# Sapatos
	_add_color_picker(grid, "Sapatos", shoes_color, CLOTHING_COLORS.size(), set_shoes_color)

func _add_color_picker(grid: GridContainer, label: String, current: int, max_colors: int, setter: Callable) -> void:
	var box = VBoxContainer.new()
	grid.add_child(box)

	var lbl = Label.new()
	lbl.text = label
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lbl)

	var opt = OptionButton.new()
	for i in range(max_colors):
		opt.add_item("Cor %d" % (i + 1))
	opt.selected = current
	opt.item_selected.connect(setter)
	box.add_child(opt)

	# Preview da cor
	var preview = Panel.new()
	preview.custom_minimum_size = Vector2(100, 30)
	var colors = label == "Cabelo" ? HAIR_COLORS : CLOTHING_COLORS
	preview.add_theme_color_override("panel_color", colors[current])
	box.add_child(preview)

	opt.item_selected.connect(func(idx): preview.add_theme_color_override("panel_color", colors[idx]))

func _show_message(text: String) -> void:
	print("Customization: %s" % text)
	if GameManager and GameManager.hud:
		GameManager.hud.show_message(text)

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"skin_color": skin_color,
		"hair_style": hair_style,
		"hair_color": hair_color,
		"eye_color": eye_color,
		"pants_style": pants_style,
		"pants_color": pants_color,
		"shirt_style": shirt_style,
		"shirt_color": shirt_color,
		"shoes_color": shoes_color,
		"accessory": accessory,
		"hat": hat,
		"gender": gender,
		"equipped_hat": equipped_hat,
		"equipped_shirt": equipped_shirt,
		"equipped_pants": equipped_pants,
		"equipped_boots": equipped_boots,
		"equipped_ring": equipped_ring,
		"equipped_ring2": equipped_ring2
	}

func load_save_data(data: Dictionary) -> void:
	skin_color = data.get("skin_color", 0)
	hair_style = data.get("hair_style", 0)
	hair_color = data.get("hair_color", 0)
	eye_color = data.get("eye_color", 0)
	pants_style = data.get("pants_style", 0)
	pants_color = data.get("pants_color", 0)
	shirt_style = data.get("shirt_style", 0)
	shirt_color = data.get("shirt_color", 0)
	shoes_color = data.get("shoes_color", 0)
	accessory = data.get("accessory", 0)
	hat = data.get("hat", -1)
	gender = data.get("gender", 0)
	equipped_hat = data.get("equipped_hat", "")
	equipped_shirt = data.get("equipped_shirt", "")
	equipped_pants = data.get("equipped_pants", "")
	equipped_boots = data.get("equipped_boots", "")
	equipped_ring = data.get("equipped_ring", "")
	equipped_ring2 = data.get("equipped_ring2", "")

	_apply_to_player()