extends Node

## Centro Comunitário: Bundles, Junimos, recompensas

@export var cc_scene: PackedScene
@export var junimo_hut_scene: PackedScene

## Estado
var bundles: Dictionary = {}  # {bundle_name: BundleInstance}
var room_status: Dictionary = {}  # {room_name: "locked"|"unlocked"|"completed"}
var junimos_unlocked: bool = false
var greenhouse_unlocked: bool = false
var minecarts_unlocked: bool = false
var bus_unlocked: bool = false
var friendship_rewards_claimed: Array = []

## Salas do Centro Comunitário
const ROOMS = [
	"Boiler Room",      # Caldeira - minérios/barras
	"Crafts Room",      # Artesanato - itens artesanais
	"Pantry",           # Despensa - cultivos/cozinha
	"Fish Tank",        # Aquário - peixes
	"Bulletin Board",   # Quadro - forrageados/artefatos
	"Vault",            # Cofre - ouro
	"Abandoned Joja Mart"  # (se rota Joja)
]

## Bundles por sala (baseado no Stardew)
const BUNDLE_DATA = {
	"Boiler Room": {
		"Blacksmith's Bundle": {
			"items": [{"item_id": "(O)378", "count": 5}, {"item_id": "(O)380", "count": 5}, {"item_id": "(O)384", "count": 5}, {"item_id": "(O)386", "count": 5}, {"item_id": "(O)388", "count": 5}],
			"reward": {"item_id": "(O)326", "count": 1}  # Furnace
		},
		"Geologist's Bundle": {
			"items": [{"item_id": "(O)535", "count": 1}, {"item_id": "(O)536", "count": 1}, {"item_id": "(O)537", "count": 1}, {"item_id": "(O)538", "count": 1}],
			"reward": {"item_id": "(O)328", "count": 1}  # Crystalarium
		}
	},
	"Crafts Room": {
		"Spring Foraging Bundle": {
			"items": [{"item_id": "(O)16", "count": 1}, {"item_id": "(O)18", "count": 1}, {"item_id": "(O)20", "count": 1}, {"item_id": "(O)22", "count": 1}],
			"reward": {"item_id": "(O)288", "count": 10}  # Spring Seeds
		},
		"Summer Foraging Bundle": {
			"items": [{"item_id": "(O)396", "count": 1}, {"item_id": "(O)398", "count": 1}, {"item_id": "(O)400", "count": 1}, {"item_id": "(O)402", "count": 1}],
			"reward": {"item_id": "(O)290", "count": 10}
		},
		"Fall Foraging Bundle": {
			"items": [{"item_id": "(O)404", "count": 1}, {"item_id": "(O)406", "count": 1}, {"item_id": "(O)408", "count": 1}, {"item_id": "(O)410", "count": 1}],
			"reward": {"item_id": "(O)292", "count": 10}
		},
		"Winter Foraging Bundle": {
			"items": [{"item_id": "(O)412", "count": 1}, {"item_id": "(O)414", "count": 1}, {"item_id": "(O)416", "count": 1}, {"item_id": "(O)418", "count": 1}],
			"reward": {"item_id": "(O)294", "count": 10}
		},
		"Construction Bundle": {
			"items": [{"item_id": "(O)388", "count": 99}, {"item_id": "(O)390", "count": 99}, {"item_id": "(O)709", "count": 10}],
			"reward": {"item_id": "(O)272", "count": 1}  # Charcoal Kiln
		},
		"Exotic Foraging Bundle": {
			"items": [{"item_id": "(O)257", "count": 5}, {"item_id": "(O)259", "count": 5}, {"item_id": "(O)261", "count": 5}, {"item_id": "(O)263", "count": 5}],
			"reward": {"item_id": "(O)274", "count": 1}  # Tapper
		}
	},
	"Pantry": {
		"Spring Crops Bundle": {
			"items": [{"item_id": "(O)472", "count": 5}, {"item_id": "(O)474", "count": 5}, {"item_id": "(O)476", "count": 5}, {"item_id": "(O)478", "count": 5}],
			"reward": {"item_id": "(O)332", "count": 1}  # Speed-Gro
		},
		"Summer Crops Bundle": {
			"items": [{"item_id": "(O)480", "count": 5}, {"item_id": "(O)482", "count": 5}, {"item_id": "(O)484", "count": 5}, {"item_id": "(O)486", "count": 5}],
			"reward": {"item_id": "(O)334", "count": 1}  # Quality Sprinkler
		},
		"Fall Crops Bundle": {
			"items": [{"item_id": "(O)488", "count": 5}, {"item_id": "(O)490", "count": 5}, {"item_id": "(O)492", "count": 5}, {"item_id": "(O)494", "count": 5}],
			"reward": {"item_id": "(O)336", "count": 1}  # Pumpkin Seeds
		},
		"Quality Crops Bundle": {
			"items": [{"item_id": "(O)472", "count": 5, "quality": 2}, {"item_id": "(O)480", "count": 5, "quality": 2}, {"item_id": "(O)488", "count": 5, "quality": 2}, {"item_id": "(O)494", "count": 5, "quality": 2}],
			"reward": {"item_id": "(O)280", "count": 1}  # Preserves Jar
		},
		"Animal Bundle": {
			"items": [{"item_id": "(O)306", "count": 1}, {"item_id": "(O)308", "count": 1}, {"item_id": "(O)430", "count": 1}, {"item_id": "(O)432", "count": 1}, {"item_id": "(O)434", "count": 1}],
			"reward": {"item_id": "(O)276", "count": 1}  # Cheese Press
		},
		"Artisan Bundle": {
			"items": [{"item_id": "(O)340", "count": 1}, {"item_id": "(O)342", "count": 1}, {"item_id": "(O)344", "count": 1}, {"item_id": "(O)346", "count": 1}, {"item_id": "(O)348", "count": 1}, {"item_id": "(O)350", "count": 1}],
			"reward": {"item_id": "(O)278", "count": 1}  # Keg
		}
	},
	"Fish Tank": {
		"River Fish Bundle": {
			"items": [{"item_id": "(O)144", "count": 1}, {"item_id": "(O)146", "count": 1}, {"item_id": "(O)148", "count": 1}, {"item_id": "(O)150", "count": 1}],
			"reward": {"item_id": "(O)808", "count": 1}  # Bait
		},
		"Lake Fish Bundle": {
			"items": [{"item_id": "(O)152", "count": 1}, {"item_id": "(O)154", "count": 1}, {"item_id": "(O)156", "count": 1}, {"item_id": "(O)158", "count": 1}],
			"reward": {"item_id": "(O)810", "count": 1}  # Trap Bobber
		},
		"Ocean Fish Bundle": {
			"items": [{"item_id": "(O)160", "count": 1}, {"item_id": "(O)162", "count": 1}, {"item_id": "(O)164", "count": 1}, {"item_id": "(O)166", "count": 1}, {"item_id": "(O)168", "count": 1}],
			"reward": {"item_id": "(O)812", "count": 1}  # Cork Bobber
		},
		"Night Fishing Bundle": {
			"items": [{"item_id": "(O)170", "count": 1}, {"item_id": "(O)172", "count": 1}, {"item_id": "(O)174", "count": 1}, {"item_id": "(O)176", "count": 1}],
			"reward": {"item_id": "(O)814", "count": 1}  # Spinner
		},
		"Specialty Fish Bundle": {
			"items": [{"item_id": "(O)178", "count": 1}, {"item_id": "(O)180", "count": 1}, {"item_id": "(O)182", "count": 1}, {"item_id": "(O)184", "count": 1}],
			"reward": {"item_id": "(O)816", "count": 1}  # Dressed Spinner
		},
		"Crab Pot Bundle": {
			"items": [{"item_id": "(O)718", "count": 1}, {"item_id": "(O)719", "count": 1}, {"item_id": "(O)720", "count": 1}, {"item_id": "(O)721", "count": 1}, {"item_id": "(O)722", "count": 1}, {"item_id": "(O)723", "count": 1}, {"item_id": "(O)724", "count": 1}, {"item_id": "(O)725", "count": 1}, {"item_id": "(O)726", "count": 1}, {"item_id": "(O)727", "count": 1}],
			"reward": {"item_id": "(O)818", "count": 3}  # Crab Pot
		}
	},
	"Bulletin Board": {
		"Chef's Bundle": {
			"items": [{"item_id": "(O)216", "count": 1}, {"item_id": "(O)218", "count": 1}, {"item_id": "(O)220", "count": 1}, {"item_id": "(O)222", "count": 1}],
			"reward": {"item_id": "(O)282", "count": 1}  # Pink Cake
		},
		"Dye Bundle": {
			"items": [{"item_id": "(O)396", "count": 1}, {"item_id": "(O)398", "count": 1}, {"item_id": "(O)400", "count": 1}, {"item_id": "(O)402", "count": 1}, {"item_id": "(O)404", "count": 1}, {"item_id": "(O)406", "count": 1}],
			"reward": {"item_id": "(O)284", "count": 1}  # Seed Maker
		},
		"Field Research Bundle": {
			"items": [{"item_id": "(O)102", "count": 1}, {"item_id": "(O)104", "count": 1}, {"item_id": "(O)106", "count": 1}, {"item_id": "(O)108", "count": 1}, {"item_id": "(O)110", "count": 1}, {"item_id": "(O)112", "count": 1}],
			"reward": {"item_id": "(O)286", "count": 1}  # Recycling Machine
		},
		"Fodder Bundle": {
			"items": [{"item_id": "(O)178", "count": 10}, {"item_id": "(O)180", "count": 10}, {"item_id": "(O)182", "count": 10}, {"item_id": "(O)184", "count": 10}],
			"reward": {"item_id": "(O)288", "count": 1}  # Hay
		},
		"Enchanter's Bundle": {
			"items": [{"item_id": "(O)767", "count": 1}, {"item_id": "(O)768", "count": 1}, {"item_id": "(O)769", "count": 1}],
			"reward": {"item_id": "(O)290", "count": 1}  # Golden Pumpkin
		}
	},
	"Vault": {
		"2,500g Bundle": {"items": [{"item_id": "gold", "count": 2500}], "reward": {"item_id": "(O)330", "count": 1}},
		"5,000g Bundle": {"items": [{"item_id": "gold", "count": 5000}], "reward": {"item_id": "(O)330", "count": 1}},
		"10,000g Bundle": {"items": [{"item_id": "gold", "count": 10000}], "reward": {"item_id": "(O)330", "count": 1}},
		"25,000g Bundle": {"items": [{"item_id": "gold", "count": 25000}], "reward": {"item_id": "(O)330", "count": 1}}
	}
}

## Recompensas por sala completada
const ROOM_REWARDS = {
	"Boiler Room": {"type": "minecart", "desc": "Minecart reparado: Minas"},
	"Crafts Room": {"type": "minecart", "desc": "Minecart reparado: Pedreira"},
	"Pantry": {"type": "greenhouse", "desc": "Estufa reparada"},
	"Fish Tank": {"type": "minecart", "desc": "Minecart reparado: Praia"},
	"Bulletin Board": {"type": "friendship", "desc": "Amizade +2 corações com todos"},
	"Vault": {"type": "bus", "desc": "Ônibus reparado: Deserto"}
}

## ==================== SINAIS ====================
signal bundle_completed(room: String, bundle: String)
signal room_completed(room: String, reward: Dictionary)
signal community_center_completed()
signal junimos_unlocked_signal()
signal greenhouse_unlocked_signal()
signal minecart_unlocked_signal(location: String)
signal bus_unlocked_signal()

## ==================== INICIALIZAÇÃO ====================
func _ready() -> void:
	_initialize_bundles()
	_load_progress()

func _initialize_bundles() -> void:
	for room_name in BUNDLE_DATA:
		for bundle_name in BUNDLE_DATA[room_name]:
			var data = BUNDLE_DATA[room_name][bundle_name]
			var key = "%s::%s" % [room_name, bundle_name]
			var instance = BundleInstance.new()
			instance.initialize(bundle_name, data)
			bundles[key] = instance
			instance.bundle_completed.connect(_on_bundle_completed.bind(key))

	# Status inicial das salas
	for room in ROOMS:
		room_status[room] = "locked"

	# Boiler Room começa desbloqueada
	room_status["Boiler Room"] = "unlocked"

func _load_progress() -> void:
	if not GameManager:
		return

	# Carrega bundles completados
	var completed = GameManager.get_data("cc_bundles_completed", {})
	for key in completed:
		var done = completed[key]
		if done and bundles.has(key):
			bundles[key].complete()

	# Carrega status das salas
	var saved_rooms = GameManager.get_data("cc_room_status", {})
	for room in saved_rooms:
		var status = saved_rooms[room]
		room_status[room] = status

	# Flags globais
	junimos_unlocked = GameManager.get_data("cc_junimos_unlocked", false)
	greenhouse_unlocked = GameManager.get_data("cc_greenhouse_unlocked", false)
	minecarts_unlocked = GameManager.get_data("cc_minecarts_unlocked", false)
	bus_unlocked = GameManager.get_data("cc_bus_unlocked", false)

## ==================== VERIFICAÇÃO DE ITENS ====================
func check_item_submission(item_id: String, quality: int = 0) -> void:
	# Verifica todos bundles não completados
	for key in bundles:
		var instance = bundles[key]
		if not instance.is_completed:
			instance.try_submit_item(item_id, quality)

func _on_bundle_completed(key: String) -> void:
	var parts = key.split("::")
	var room = parts[0]
	var bundle = parts[1]

	emit_signal("bundle_completed", room, bundle)

	# Verifica se completou a sala
	_check_room_completion(room)

	_save_progress()

func _check_room_completion(room: String) -> void:
	var all_done = true
	for key in bundles:
		var instance = bundles[key]
		if key.begins_with(room + "::") and not instance.is_completed:
			all_done = false
			break

	if all_done and room_status[room] != "completed":
		room_status[room] = "completed"
		_complete_room(room)

func _complete_room(room: String) -> void:
	var reward = ROOM_REWARDS.get(room, {})
	emit_signal("room_completed", room, reward)

	# Aplica recompensa da sala
	match reward.type:
		"greenhouse":
			greenhouse_unlocked = true
			GameManager.set_data("cc_greenhouse_unlocked", true)
			emit_signal("greenhouse_unlocked_signal")
		"minecart":
			minecarts_unlocked = true
			GameManager.set_data("cc_minecarts_unlocked", true)
			emit_signal("minecart_unlocked", reward.desc)
		"bus":
			bus_unlocked = true
			GameManager.set_data("cc_bus_unlocked", true)
			emit_signal("bus_unlocked_signal")
		"friendship":
			# +2 corações com todos NPCs
			for npc in DataLoader.get_all_npcs():
				GameManager.add_friendship(npc.internal_name, 500)
		_:
			pass

	# Verifica se completou tudo
	_check_full_completion()

	_save_progress()

func _check_full_completion() -> void:
	for room in ROOMS:
		if room_status.get(room, "locked") != "completed":
			return

	# Centro Comunitário completo!
	junimos_unlocked = true
	GameManager.set_data("cc_junimos_unlocked", true)
	emit_signal("community_center_completed")
	emit_signal("junimos_unlocked_signal")

	# Spawna Junimo Hut na fazenda
	_spawn_junimo_hut()

func _spawn_junimo_hut() -> void:
	if junimo_hut_scene:
		var hut = junimo_hut_scene.instantiate()
		hut.global_position = Vector2(100, 100)  # Perto da casa
		get_tree().root.get_child(0).add_child(hut)

func _save_progress() -> void:
	if not GameManager:
		return

	var completed = {}
	for key in bundles:
		var instance = bundles[key]
		completed[key] = instance.is_completed
	GameManager.set_data("cc_bundles_completed", completed)

	var rooms = {}
	for room in room_status:
		var status = room_status[room]
		rooms[room] = status
	GameManager.set_data("cc_room_status", rooms)

## ==================== UI ====================
func open_community_center() -> void:
	if cc_scene:
		var ui = cc_scene.instantiate()
		ui.initialize(bundles, room_status)
		get_tree().root.get_child(0).add_child(ui)
	else:
		_show_generic_cc_ui()

func _show_generic_cc_ui() -> void:
	var panel = Panel.new()
	panel.name = "CommunityCenterUI"
	panel.anchors_preset = 15
	panel.offset_left = 50
	panel.offset_top = 30
	panel.offset_right = -50
	panel.offset_bottom = -30

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "Centro Comunitário"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_override_font_size = 28
	vbox.add_child(title)

	# Tabs por sala
	var tabs = TabContainer.new()
	vbox.add_child(tabs)

	for room in ROOMS:
		if room == "Abandoned Joja Mart":
			continue
		var room_box = VBoxContainer.new()
		tabs.add_child(room_box)
		tabs.set_tab_title(tabs.get_child_count() - 1, room)

		var status = room_status.get(room, "locked")
		var status_label = Label.new()
		status_label.text = "Status: %s" % {"locked": "🔒 Trancada", "unlocked": "🔓 Disponível", "completed": "✅ Completa"}[status]
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		room_box.add_child(status_label)

		if status == "locked":
			continue

		# Bundles da sala
		for key in bundles:
			var instance = bundles[key]
			if key.begins_with(room + "::"):
				var bundle_box = _create_bundle_ui(instance)
				room_box.add_child(bundle_box)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	close_btn.pressed.connect(panel.queue_free)
	vbox.add_child(close_btn)

	get_tree().root.get_child(0).add_child(panel)

func _create_bundle_ui(instance: BundleInstance) -> Control:
	var panel = Panel.new()
	panel.add_theme_constant_override("stylebox", StyleBoxFlat.new())
	var style = panel.get_theme_stylebox("stylebox") as StyleBoxFlat
	style.bg_color = Color(0.15, 0.15, 0.2) if instance.is_completed else Color(0.1, 0.1, 0.15)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)

	var name = Label.new()
	name.text = "%s %s" % ["✅" if instance.is_completed else "📦", instance.bundle_name]
	name.theme_override_font_size = 18
	hbox.add_child(name)

	# Itens necessários
	for item_req in instance.requirements:
		var item_data = DataLoader.get_item(item_req.item_id)
		var item_name = item_data.display_name if item_data != null else item_req.item_id
		var quality_text = " (Qualidade %d)" % [item_req.quality + 1] if item_req.quality > 0 else ""
		var progress_text = "%s: %d/%d%s" % [item_name, item_req.submitted, item_req.count, quality_text]

		var item_label = Label.new()
		item_label.text = progress_text
		item_label.add_theme_color_override("font_color", Color(0, 1, 0) if item_req.submitted >= item_req.count else Color(1, 1, 1))
		vbox.add_child(item_label)

	# Recompensa
	if instance.reward:
		var reward_data = DataLoader.get_item(instance.reward.item_id)
		var reward_name = reward_data.display_name if reward_data != null else instance.reward.item_id
		var reward_label = Label.new()
		reward_label.text = "Recompensa: %s x%d" % [reward_name, instance.reward.count]
		reward_label.add_theme_color_override("font_color", Color(1, 0.8, 0))
		vbox.add_child(reward_label)

	return panel

## ==================== JUNIMO HUT ====================
func get_junimo_hut_production() -> Array:
	# Junimos colhem cultivos maduros automaticamente
	var harvested = []
	if not junimos_unlocked:
		return harvested

	var farm = WorldInit.get_farm_plots()
	for plot in farm:
		if plot.has_crop and plot.crop.ready_to_harvest:
			var result = plot.harvest()
			if result:
				harvested.append(result)
	return harvested


class BundleInstance:
	var bundle_name: String = ""
	var requirements: Array = []  # {item_id, count, quality, submitted}
	var reward: Dictionary = {}  # {item_id, count}
	var is_completed: bool = false

	signal bundle_completed(bundle_key: String)

	func initialize(name: String, data: Dictionary) -> void:
		bundle_name = name
		reward = data.get("reward", {})

		for item_data in data.get("items", []):
			requirements.append({
				"item_id": item_data.item_id,
				"count": item_data.count,
				"quality": item_data.get("quality", 0),
				"submitted": 0
			})

	func try_submit_item(item_id: String, quality: int) -> void:
		if is_completed:
			return

		for req in requirements:
			if req.item_id == item_id and (req.quality == 0 or quality >= req.quality):
				if req.submitted < req.count:
					req.submitted += 1
					_check_completion()
					return

	func _check_completion() -> void:
		for req in requirements:
			if req.submitted < req.count:
				return
		is_completed = true
		emit_signal("bundle_completed", bundle_name)

	func complete() -> void:
		is_completed = true
		for req in requirements:
			req.submitted = req.count