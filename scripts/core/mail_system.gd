class_name MailSystem
extends Node

## Sistema de Correio: cartas, pacotes, notificações de missões, convites de festivais

@export var mail_ui_scene: PackedScene

## Estado
var mailbox: Array = []  # Lista de cartas na caixa de correio
var read_mails: Array = []  # IDs de cartas lidas
var next_mail_id: int = 1

## Tipos de carta
const MAIL_TYPES = {
	"letter": {"icon": "📜", "color": Color(0.9, 0.8, 0.4)},       # Carta normal
	"package": {"icon": "📦", "color": Color(0.5, 0.8, 0.5)},       # Pacote com item
	"quest": {"icon": "📋", "color": Color(0.4, 0.7, 1.0)},         # Nova missão
	"festival": {"icon": "🎪", "color": Color(1.0, 0.5, 0.8)},      # Convite festival
	"bill": {"icon": "🧾", "color": Color(1.0, 0.4, 0.4)},          # Conta/impostos
	"secret": {"icon": "🤫", "color": Color(0.7, 0.4, 1.0)},        # Nota secreta
	"relationship": {"icon": "💌", "color": Color(1.0, 0.3, 0.6)}    # Carta de relacionamento
}

## Templates de cartas (baseado no Stardew)
const LETTER_TEMPLATES = {
	# Cartas de boas-vindas
	"welcome": {
		"type": "letter",
		"sender": "Lewis",
		"subject": "Bem-vindo a Pelican Town!",
		"body": "Olá,\n\nBem-vindo a Pelican Town! Espero que você goste da sua nova vida na fazenda do seu avô. Se precisar de qualquer coisa, não hesite em vir à prefeitura.\n\nAtenciosamente,\nPrefeito Lewis"
	},

	# Cartas de NPCs (amizade)
	"friendship_milestone": {
		"type": "relationship",
		"sender": "{npc}",
		"subject": "Pensando em você",
		"body": "Oi {player},\n\nTenho pensado em você ultimamente. Achei que você gostaria disso.\n\nAnexo: {gift}\n\nCom carinho,\n{npc}"
	},

	# Receitas por correio
	"recipe_mail": {
		"type": "package",
		"sender": "{npc}",
		"subject": "Receita: {recipe}",
		"body": "Oi {player},\n\nAqui está a receita que prometi. Espero que goste!\n\n{npc}",
		"attachment": "{recipe}"
	},

	# Convites de festival
	"festival_invite": {
		"type": "festival",
		"sender": "Lewis",
		"subject": "{festival} Amanhã!",
		"body": "Lembrete: O {festival} é amanhã! Venha à cidade entre 9h e 14h para participar.\n\nHaverá comida, jogos e prêmios!\n\nPrefeito Lewis"
	},

	# Notas secretas
	"secret_note": {
		"type": "secret",
		"sender": "???",
		"subject": "Nota Secreta #{note_num}",
		"body": "{secret_text}"
	},

	# Missões
	"quest_new": {
		"type": "quest",
		"sender": "{quest_giver}",
		"subject": "Nova Missão: {quest_name}",
		"body": "{quest_description}\n\nRecompensa: {reward}\n\n- {quest_giver}"
	},

	# Aniversário
	"birthday": {
		"type": "letter",
		"sender": "{npc}",
		"subject": "Feliz Aniversário!",
		"body": "Feliz aniversário, {player}!\n\nEspero que tenha um dia maravilhoso.\n\n{npc}"
	}
}

## ==================== SINAIS ====================
signal mail_received(mail: Dictionary)
signal mail_read(mail_id: int)
signal package_claimed(mail_id: int, item_id: String)

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_load_mail_data()
	_check_daily_mail()

func _load_mail_data() -> void:
	if not GameManager:
		return

	mailbox = GameManager.get("mailbox", [])
	read_mails = GameManager.get("read_mails", [])
	next_mail_id = GameManager.get("next_mail_id", 1)

	# Envia carta de boas-vindas se primeira vez
	if mailbox.is_empty() and not GameManager.get("welcome_mail_sent", false):
		send_welcome_mail()
		GameManager.set("welcome_mail_sent", true)

func _check_daily_mail() -> void:
	# Verifica convites de festival
	if FestivalManager and FestivalManager.is_festival_tomorrow():
		var festival = FestivalManager.get_tomorrow_festival()
		if festival:
			send_festival_invite(festival)

	# Verifica aniversários de NPCs
	_check_npc_birthdays()

	# Cartas de relacionamento aleatórias
	_check_relationship_mail()

func _check_npc_birthdays() -> void:
	if not DataLoader or not GameManager:
		return

	var tomorrow = GameManager.current_day + 1
	var season = GameManager.current_season

	for npc_id in DataLoader.get_all_npcs():
		var npc = DataLoader.get_npc(npc_id)
		if npc and npc.birthday_season == season and npc.birthday_day == tomorrow:
			send_birthday_mail(npc_id)

func _check_relationship_mail() -> void:
	if not GameManager or not DataLoader:
		return

	# 5% chance por dia de receber carta de NPC com alta amizade
	if randf() < 0.05:
		var high_friendship_npcs = []
		for npc_id in DataLoader.get_all_npcs():
			var friendship = GameManager.get_friendship(npc_id)
			if friendship >= 750:  # 3+ corações
				high_friendship_npcs.append(npc_id)

		if not high_friendship_npcs.is_empty():
			var npc = high_friendship_npcs.pick_random()
			send_friendship_mail(npc)

## ==================== ENVIAR CARTAS ====================
func _create_mail(template_key: String, params: Dictionary = {}) -> Dictionary:
	var template = LETTER_TEMPLATES.get(template_key, LETTER_TEMPLATES["welcome"]).duplicate(true)

	var mail = {
		"id": next_mail_id,
		"type": template.type,
		"sender": template.sender,
		"subject": template.subject,
		"body": template.body,
		"day": GameManager.current_day,
		"season": GameManager.current_season,
		"year": GameManager.current_year,
		"read": false,
		"attachment": template.get("attachment", ""),
		"params": params
	}

	# Substitui placeholders
	for key in ["sender", "subject", "body"]:
		for param_key, param_val in params:
			mail[key] = mail[key].replace("{%s}" % param_key, str(param_val))

	next_mail_id += 1
	return mail

func _add_mail(mail: Dictionary) -> void:
	mailbox.append(mail)
	_save_mail_data()
	emit_signal("mail_received", mail)

func send_mail(template_key: String, params: Dictionary = {}) -> int:
	var mail = _create_mail(template_key, params)
	_add_mail(mail)
	return mail.id

# Cartas específicas
func send_welcome_mail() -> void:
	send_mail("welcome")

func send_festival_invite(festival_name: String) -> void:
	send_mail("festival_invite", {"festival": festival_name})

func send_birthday_mail(npc_id: String) -> void:
	var npc = DataLoader.get_npc(npc_id)
	if npc:
		send_mail("birthday", {"npc": npc.display_name, "player": GameManager.player_name})

func send_friendship_mail(npc_id: String) -> void:
	var npc = DataLoader.get_npc(npc_id)
	if not npc:
		return

	var gifts = npc.loved_gifts + npc.liked_gifts
	if gifts.is_empty():
		return

	var gift_id = gifts.pick_random()
	var gift_data = DataLoader.get_item(gift_id)
	var gift_name = gift_data?.display_name ?? gift_id

	send_mail("friendship_milestone", {
		"npc": npc.display_name,
		"player": GameManager.player_name,
		"gift": gift_name
	})

	# Anexa o item se for pacote
	var mail = mailbox[-1]
	mail.attachment = gift_id

func send_recipe_mail(npc_id: String, recipe_name: String) -> void:
	var npc = DataLoader.get_npc(npc_id)
	if npc:
		send_mail("recipe_mail", {
			"npc": npc.display_name,
			"player": GameManager.player_name,
			"recipe": recipe_name
		})
		var mail = mailbox[-1]
		mail.attachment = recipe_name

func send_quest_mail(quest_giver: String, quest_name: String, description: String, reward: String) -> void:
	send_mail("quest_new", {
		"quest_giver": quest_giver,
		"quest_name": quest_name,
		"quest_description": description,
		"reward": reward
	})

func send_secret_note(note_num: Int, text: String) -> void:
	send_mail("secret_note", {"note_num": note_num, "secret_text": text})

## ==================== LER/REIVINDICAR ====================
func read_mail(mail_id: int) -> Dictionary:
	for mail in mailbox:
		if mail.id == mail_id:
			if mail_id not in read_mails:
				read_mails.append(mail_id)
				_save_mail_data()
				emit_signal("mail_read", mail_id)
			mail.read = true
			return mail
	return {}

func claim_package(mail_id: int) -> bool:
	for mail in mailbox:
		if mail.id == mail_id and mail.type == "package" and mail.attachment != "":
			var item_id = mail.attachment
			if InventoryManager.add_item(item_id):
				mail.attachment = ""
				_save_mail_data()
				emit_signal("package_claimed", mail_id, item_id)
				_show_message("Recebeu: %s" % DataLoader.get_item(item_id)?.display_name ?? item_id)
				return true
			else:
				_show_message("Inventário cheio!")
				return false
	return false

func claim_recipe(mail_id: int) -> bool:
	for mail in mailbox:
		if mail.id == mail_id and mail.attachment != "":
			var recipe_name = mail.attachment
			if not InventoryManager.known_recipes.has(recipe_name):
				InventoryManager.known_recipes.append(recipe_name)
				GameManager.set("known_recipes", InventoryManager.known_recipes)
				CollectionsMenu.register_recipe_learned(recipe_name)
				mail.attachment = ""
				_save_mail_data()
				_show_message("Aprendeu receita: %s" % recipe_name)
				return true
	return false

func delete_mail(mail_id: int) -> void:
	mailbox.erase(mail_id)
	read_mails.erase(mail_id)
	_save_mail_data()

func get_unread_count() -> int:
	var count = 0
	for mail in mailbox:
		if not mail.read:
			count += 1
	return count

## ==================== UI ====================
func open_mailbox() -> void:
	if mail_ui_scene:
		var ui = mail_ui_scene.instantiate()
		ui.initialize(mailbox, read_mails)
		ui.mail_selected.connect(_on_mail_selected)
		ui.package_claimed.connect(claim_package)
		ui.recipe_claimed.connect(claim_recipe)
		ui.mail_deleted.connect(delete_mail)
		get_tree().root.get_child(0).add_child(ui)
	else:
		_show_generic_mail_ui()

func _show_generic_mail_ui() -> void:
	var panel = Panel.new()
	panel.name = "MailUI"
	panel.anchors_preset = 15
	panel.offset_left = 50
	panel.offset_top = 30
	panel.offset_right = -50
	panel.offset_bottom = -30

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# Lista de cartas
	var list_box = VBoxContainer.new()
	list_box.custom_minimum_size = Vector2(300, 0)
	hbox.add_child(list_box)

	var title = Label.new()
	title.text = "📬 Caixa de Correio (%d não lidas)" % get_unread_count()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 24
	list_box.add_child(title)

	var scroll = ScrollContainer.new()
	scroll.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	list_box.add_child(scroll)

	var mail_list = VBoxContainer.new()
	scroll.add_child(mail_list)

	for mail in mailbox:
		var mail_type = MAIL_TYPES.get(mail.type, MAIL_TYPES["letter"])
		var btn = Button.new()
		btn.text = "%s %s\n    %s" % [mail_type.icon, mail.subject, mail.sender]
		btn.custom_minimum_size = Vector2(0, 60)
		btn.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.tooltip_text = mail.body.left(100)
		if mail.read:
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		btn.pressed.connect(_on_mail_selected.bind(mail.id))
		mail_list.add_child(btn)

	# Conteúdo da carta
	var content_box = VBoxContainer.new()
	content_box.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	hbox.add_child(content_box)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	content_box.add_child(close_btn)

	# Mostra primeira carta não lida ou a primeira
	var first_unread = mailbox.find(lambda m: not m.read)
	var mail_to_show = first_unread >= 0 ? mailbox[first_unread] : (mailbox[0] if mailbox else null)

	if mail_to_show:
		_show_mail_content(content_box, mail_to_show)

	get_tree().root.get_child(0).add_child(panel)

func _on_mail_selected(mail_id: int) -> void:
	var mail = mailbox.find(lambda m: m.id == mail_id)
	if mail:
		read_mail(mail_id)
		open_mailbox()  # Refresh

func _show_mail_content(content: VBoxContainer, mail: Dictionary) -> void:
	# Limpa exceto botão fechar
	for child in content.get_children():
		if child != content.get_child(0):
			child.queue_free()

	var mail_type = MAIL_TYPES.get(mail.type, MAIL_TYPES["letter"])

	var header = Label.new()
	header.text = "%s %s" % [mail_type.icon, mail.subject]
	header.theme_override_font_size = 20
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(header)

	var sender_lbl = Label.new()
	sender_lbl.text = "De: %s" % mail.sender
	sender_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sender_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	content.add_child(sender_lbl)

	var date_lbl = Label.new()
	date_lbl.text = "Dia %d de %s, Ano %d" % [mail.day, mail.season, mail.year]
	date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	content.add_child(date_lbl)

	var separator = HSeparator.new()
	content.add_child(separator)

	var body = Label.new()
	body.text = mail.body
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(body)

	# Anexo
	if mail.attachment != "":
		var separator2 = HSeparator.new()
		content.add_child(separator2)

		var attach_lbl = Label.new()
		attach_lbl.text = "📎 Anexo: %s" % (DataLoader.get_item(mail.attachment)?.display_name ?? mail.attachment)
		attach_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		attach_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
		content.add_child(attach_lbl)

		if mail.type == "package":
			var btn = Button.new()
			btn.text = "Reivindicar Item"
			btn.pressed.connect(_claim_package_ui.bind(mail.id))
			content.add_child(btn)
		elif mail.attachment.begins_with("recipe_"):
			var btn = Button.new()
			btn.text = "Aprender Receita"
			btn.pressed.connect(_claim_recipe_ui.bind(mail.id))
			content.add_child(btn)

	var delete_btn = Button.new()
	delete_btn.text = "Excluir Carta"
	delete_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	delete_btn.pressed.connect(_delete_mail_ui.bind(mail.id))
	content.add_child(delete_btn)

func _claim_package_ui(mail_id: int) -> void:
	claim_package(mail_id)
	open_mailbox()

func _claim_recipe_ui(mail_id: int) -> void:
	claim_recipe(mail_id)
	open_mailbox()

func _delete_mail_ui(mail_id: int) -> void:
	delete_mail(mail_id)
	open_mailbox()

func _show_message(text: String) -> void:
	print("Mail: %s" % text)

func _save_mail_data() -> void:
	if not GameManager:
		return
	GameManager.set("mailbox", mailbox)
	GameManager.set("read_mails", read_mails)
	GameManager.set("next_mail_id", next_mail_id)

## ==================== SERIALIZAÇÃO ====================
func get_save_data() -> Dictionary:
	return {
		"mailbox": mailbox,
		"read_mails": read_mails,
		"next_mail_id": next_mail_id
	}

func load_save_data(data: Dictionary) -> void:
	mailbox = data.get("mailbox", [])
	read_mails = data.get("read_mails", [])
	next_mail_id = data.get("next_mail_id", 1)