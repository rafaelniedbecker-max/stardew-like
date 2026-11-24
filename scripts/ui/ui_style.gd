class_name UIStyle
extends Node

## Design System Runtime - aplica tokens, cria componentes padronizados

## ==================== COLOR TOKENS ====================
const COLORS = {
	# Surfaces
	"surface": Color(0xFDF8F0),
	"surface_elevated": Color(0xF5ECD8),
	"surface_hover": Color(0xE8DCC8),
	"surface_dark": Color(0x1A1612),
	"surface_elevated_dark": Color(0x241E18),
	"surface_hover_dark": Color(0x2E261E),

	# Ink
	"ink": Color(0x3D2E1F),
	"ink_muted": Color(0x8B7A63),
	"ink_dark": Color(0xF0E8DC),
	"ink_muted_dark": Color(0x9D8E7A),

	# Brand
	"brand": Color(0xC47A3C),
	"brand_hover": Color(0xA86530),
	"brand_dark": Color(0xD98B4A),
	"brand_hover_dark": Color(0xC47A3C),

	# Status
	"success": Color(0x5D8A4E),
	"success_dark": Color(0x6EBF5F),
	"warning": Color(0xC49A3C),
	"warning_dark": Color(0xD9A84A),
	"danger": Color(0xA84A3C),
	"danger_dark": Color(0xC45A4A),
	"info": Color(0x4A7C9E),
	"info_dark": Color(0x5A9BD8),

	# Seasonal (Spring, Summer, Fall, Winter)
	"season_spring": Color(0xA8D47A),
	"season_spring_muted": Color(0xC8E8A0),
	"season_summer": Color(0xF4C430),
	"season_summer_muted": Color(0xF8D870),
	"season_fall": Color(0xD47A2A),
	"season_fall_muted": Color(0xE8A060),
	"season_winter": Color(0x7AC8E8),
	"season_winter_muted": Color(0xA0D8F0),
}

## ==================== TYPOGRAPHY ====================
const FONT_PATHS = {
	"pixel": "res://resources/fonts/PixelifySans-Variable.ttf",
	"pixel_fallback": "res://resources/fonts/PressStart2P-Regular.ttf",
	"body": "res://resources/fonts/NunitoSans-Variable.ttf",
	"mono": "res://resources/fonts/JetBrainsMono-Variable.ttf",
}

const TYPE_SCALE = {
	"display": {"size": 32, "weight": "Bold", "line_height": 1.2, "letter_spacing": 0.5},
	"h1": {"size": 24, "weight": "Medium", "line_height": 1.3, "letter_spacing": 0.3},
	"h2": {"size": 20, "weight": "Medium", "line_height": 1.3, "letter_spacing": 0.3},
	"h3": {"size": 18, "weight": "Medium", "line_height": 1.4, "letter_spacing": 0.3},
	"body": {"size": 16, "weight": "Regular", "line_height": 1.5, "letter_spacing": 0},
	"body_sm": {"size": 14, "weight": "Regular", "line_height": 1.5, "letter_spacing": 0},
	"label": {"size": 12, "weight": "Regular", "line_height": 1.4, "letter_spacing": 0.2},
	"caption": {"size": 11, "weight": "Regular", "line_height": 1.4, "letter_spacing": 0.2},
}

## ==================== SPACING ====================
const SPACING = {
	"xs": 4, "sm": 8, "md": 12, "lg": 16, "xl": 24, "xxl": 32, "xxxl": 48, "xxxxl": 64
}

const RADIUS = {
	"sm": 4, "md": 6, "lg": 8, "xl": 12, "full": 9999
}

const SHADOWS = {
	"sm": "0 1px 3px rgba(0,0,0,0.08)",
	"md": "0 4px 12px rgba(0,0,0,0.1)",
	"lg": "0 8px 24px rgba(0,0,0,0.12)",
	"dark_sm": "0 1px 3px rgba(0,0,0,0.3)",
	"dark_md": "0 4px 12px rgba(0,0,0,0.4)",
	"dark_lg": "0 8px 24px rgba(0,0,0,0.5)",
}

## ==================== SEASONAL ====================
func get_season_colors(season: int) -> Dictionary:
	# 0=Spring, 1=Summer, 2=Fall, 3=Winter
	return {
		0: {"accent": COLORS.season_spring, "accent_muted": COLORS.season_spring_muted, "name": "Spring"},
		1: {"accent": COLORS.season_summer, "accent_muted": COLORS.season_summer_muted, "name": "Summer"},
		2: {"accent": COLORS.season_fall, "accent_muted": COLORS.season_fall_muted, "name": "Fall"},
		3: {"accent": COLORS.season_winter, "accent_muted": COLORS.season_winter_muted, "name": "Winter"},
	}[season]

func is_dark_mode() -> bool:
	return OS.has_feature("editor") ? false : (DisplayServer.screen_get_dpi() > 0 and true) # Placeholder

func get_color(name: String) -> Color:
	var dark = is_dark_mode()
	var key = name + (dark ? "_dark" : "")
	return COLORS.get(key, COLORS.get(name, Color.WHITE))

## ==================== COMPONENT FACTORIES ====================
func create_button(text: String, variant: String = "primary", size: String = "medium", callback: Callable = null) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.theme_type_variation = variant

	# Size
	match size:
		"small": btn.custom_minimum_size = Vector2(0, 32)
		"medium": btn.custom_minimum_size = Vector2(0, 40)
		"large": btn.custom_minimum_size = Vector2(0, 48)

	if callback:
		btn.pressed.connect(callback)

	return btn

func create_panel(variant: String = "default") -> Panel:
	var panel = Panel.new()
	panel.theme_type_variation = variant
	return panel

func create_progress_bar(variant: String = "default", size: String = "medium") -> ProgressBar:
	var bar = ProgressBar.new()
	bar.theme_type_variation = variant
	match size:
		"thin": bar.custom_minimum_size = Vector2(0, 8)
		"medium": bar.custom_minimum_size = Vector2(0, 16)
		"large": bar.custom_minimum_size = Vector2(0, 24)
	return bar

func create_label(text: String, style: String = "body") -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.theme_type_variation = style
	return lbl

func create_line_edit(placeholder: String = "") -> LineEdit:
	var le = LineEdit.new()
	le.placeholder_text = placeholder
	return le

func create_item_slot(item_id: String = "", amount: int = 0, show_quality: int = 0) -> Control:
	var slot = HBoxContainer.new()
	slot.custom_minimum_size = Vector2(70, 70)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(64, 64)
	btn.flat = true

	var vbox = VBoxContainer.new()
	vbox.anchors_preset = 15
	btn.add_child(vbox)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon)

	if item_id != "":
		var item = DataLoader.get_item(item_id)
		if item and item.texture_path != "":
			icon.texture = load(item.texture_path)

	var name = Label.new()
	name.text = item?.display_name ?? item_id
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.theme_override_font_size = 10
	name.autowrap_mode = 1
	vbox.add_child(name)

	if amount > 1:
		var qty = Label.new()
		qty.text = "x%d" % amount
		qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty.theme_override_font_size = 9
		vbox.add_child(qty)

	if show_quality > 0:
		var q_colors = [Color.WHITE, Color(0.75,0.75,0.75), Color(1.0,0.85,0.2), Color(0.6,0.3,1.0)]
		var q_indicator = Label.new()
		q_indicator.text = ["", "⭐", "⭐⭐", "⭐⭐⭐"][show_quality]
		q_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q_indicator.theme_override_font_size = 12
		if show_quality < q_colors.size():
			q_indicator.add_theme_color_override("font_color", q_colors[show_quality])
		vbox.add_child(q_indicator)

	btn.add_child(vbox)
	slot.add_child(btn)
	slot.set("item_id", item_id)
	slot.set("amount", amount)
	slot.set("quality", show_quality)

	return slot

func create_tooltip(text: String, parent: Control = null) -> Control:
	var panel = Panel.new()
	panel.name = "Tooltip"
	panel.theme_type_variation = "tooltip"

	var lbl = Label.new()
	lbl.text = text
	lbl.theme_type_variation = "tooltip"
	lbl.autowrap_mode = 1
	panel.add_child(lbl)

	if parent:
		parent.add_child(panel)
		panel.global_position = parent.get_global_mouse_position() + Vector2(16, 16)

	return panel

func create_toast(title: String, message: String, type: String = "info", duration: float = 4.0) -> Control:
	var panel = Panel.new()
	panel.name = "Toast"
	panel.anchors_preset = 11 # Top right

	var hbox = HBoxContainer.new()
	hbox.theme_override_constants/separation = 12
	panel.add_child(hbox)

	var icons = {"info": "ℹ️", "success": "✅", "warning": "⚠️", "danger": "❌", "achievement": "🏆"}
	var icon_lbl = Label.new()
	icon_lbl.text = icons.get(type, "ℹ️")
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.theme_override_font_size = 24
	hbox.add_child(icon_lbl)

	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.theme_override_font_size = 16
	title_lbl.add_theme_color_override("font_color", get_color("brand"))
	vbox.add_child(title_lbl)

	var msg_lbl = Label.new()
	msg_lbl.text = message
	msg_lbl.theme_override_font_size = 13
	msg_lbl.autowrap_mode = 1
	vbox.add_child(msg_lbl)

	# Animação
	panel.modulate = Color(1, 1, 1, 0)
	panel.position = Vector2(50, 0)
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "position", Vector2(0, 0), 0.3).set_trans(Tween.TRANS_BACK)

	# Auto-remove
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func():
		var t = panel.create_tween()
		t.tween_property(panel, "modulate:a", 0.0, 0.3)
		t.tween_property(panel, "position:x", 50, 0.3)
		t.finished.connect(panel.queue_free.bind())
	))
	panel.add_child(timer)
	timer.start()

	get_tree().root.get_child(0).add_child(panel)
	return panel

## ==================== THEME GENERATION ====================
func generate_theme_tres() -> Theme:
	var theme = Theme.new()

	# Fontes
	var pixel_font = load(FONT_PATHS.pixel) if ResourceLoader.exists(FONT_PATHS.pixel) else load(FONT_PATHS.pixel_fallback)
	var body_font = load(FONT_PATHS.body) if ResourceLoader.exists(FONT_PATHS.body) else pixel_font
	var mono_font = load(FONT_PATHS.mono) if ResourceLoader.exists(FONT_PATHS.mono) else pixel_font

	# Cores base
	var dark = is_dark_mode()
	var surface = dark ? COLORS.surface_dark : COLORS.surface
	var surface_elevated = dark ? COLORS.surface_elevated_dark : COLORS.surface_elevated
	var surface_hover = dark ? COLORS.surface_hover_dark : COLORS.surface_hover
	var ink = dark ? COLORS.ink_dark : COLORS.ink
	var ink_muted = dark ? COLORS.ink_muted_dark : COLORS.ink_muted
	var brand = dark ? COLORS.brand_dark : COLORS.brand
	var brand_hover = dark ? COLORS.brand_hover_dark : COLORS.brand_hover

	# Default font
	theme.set_font(pixel_font, "Label")
	theme.set_font(pixel_font, "Button")
	theme.set_font(body_font, "LineEdit")
	theme.set_font(mono_font, "RichTextLabel")

	# Font sizes (via theme overrides no código, não no theme.tres)
	# Colors
	theme.set_color(surface, "Panel", "bg_color")
	theme.set_color(surface_elevated, "Button", "bg_color")
	theme.set_color(surface_hover, "Button", "bg_color_hover")
	theme.set_color(ink, "Label", "font_color")
	theme.set_color(ink_muted, "Label", "font_disabled_color")
	theme.set_color(ink, "Button", "font_color")
	theme.set_color(ink, "LineEdit", "font_color")
	theme.set_color(ink_muted, "LineEdit", "font_placeholder_color")
	theme.set_color(brand, "Button", "font_hover_color")
	theme.set_color(Color(0,0,0,0), "Button", "border_color")
	theme.set_color(Color(0.2,0.2,0.2,0.1), "Panel", "border_color")

	# Constants
	theme.set_constant(8, "Button", "corner_radius")
	theme.set_constant(6, "Panel", "corner_radius")
	theme.set_constant(6, "LineEdit", "corner_radius")
	theme.set_constant(12, "Button", "h_padding")
	theme.set_constant(10, "Button", "v_padding")
	theme.set_constant(8, "BoxContainer", "separation")
	theme.set_constant(16, "MarginContainer", "margin_left")
	theme.set_constant(16, "MarginContainer", "margin_right")
	theme.set_constant(16, "MarginContainer", "margin_top")
	theme.set_constant(16, "MarginContainer", "margin_bottom")

	# Styleboxes
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = surface_elevated
	btn_normal.corner_radius_top_left = 6
	btn_normal.corner_radius_top_right = 6
	btn_normal.corner_radius_bottom_left = 6
	btn_normal.corner_radius_bottom_right = 6
	btn_normal.content_margin_left = 12
	btn_normal.content_margin_right = 12
	btn_normal.content_margin_top = 10
	btn_normal.content_margin_bottom = 10
	theme.set_stylebox(btn_normal, "Button", "normal")

	var btn_hover = btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = surface_hover
	theme.set_stylebox(btn_hover, "Button", "hover")

	var btn_pressed = btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = surface_hover.darkened(0.1)
	theme.set_stylebox(btn_pressed, "Button", "pressed")

	var btn_disabled = btn_normal.duplicate() as StyleBoxFlat
	btn_disabled.bg_color = surface_hover.darkened(0.2)
	theme.set_stylebox(btn_disabled, "Button", "disabled")

	var panel_sb = StyleBoxFlat.new()
	panel_sb.bg_color = surface_elevated
	panel_sb.corner_radius_top_left = 8
	panel_sb.corner_radius_top_right = 8
	panel_sb.corner_radius_bottom_left = 8
	panel_sb.corner_radius_bottom_right = 8
	panel_sb.border_color = Color(0,0,0,0.05)
	panel_sb.border_width_left = 1
	panel_sb.border_width_right = 1
	panel_sb.border_width_top = 1
	panel_sb.border_width_bottom = 1
	panel_sb.content_margin_left = 16
	panel_sb.content_margin_right = 16
	panel_sb.content_margin_top = 16
	panel_sb.content_margin_bottom = 16
	theme.set_stylebox(panel_sb, "Panel", "panel")

	var progress_sb = StyleBoxFlat.new()
	progress_sb.bg_color = surface
	progress_sb.corner_radius_top_left = 4
	progress_sb.corner_radius_top_right = 4
	progress_sb.corner_radius_bottom_left = 4
	progress_sb.corner_radius_bottom_right = 4
	theme.set_stylebox(progress_sb, "ProgressBar", "background")

	var progress_fill = StyleBoxFlat.new()
	progress_fill.bg_color = brand
	progress_fill.corner_radius_top_left = 4
	progress_fill.corner_radius_top_right = 4
	progress_fill.corner_radius_bottom_left = 4
	progress_fill.corner_radius_bottom_right = 4
	theme.set_stylebox(progress_fill, "ProgressBar", "fill")

	return theme

## ==================== HELPERS ====================
func apply_to_button(btn: Button, variant: String = "primary", size: String = "medium") -> void:
	btn.theme_type_variation = variant
	match size:
		"small": btn.custom_minimum_size = Vector2(0, 32)
		"medium": btn.custom_minimum_size = Vector2(0, 40)
		"large": btn.custom_minimum_size = Vector2(0, 48)

func apply_to_panel(panel: Panel, variant: String = "default") -> void:
	panel.theme_type_variation = variant

func apply_to_progress_bar(bar: ProgressBar, color: String = "brand", size: String = "medium") -> void:
	bar.theme_type_variation = color
	match size:
		"thin": bar.custom_minimum_size = Vector2(0, 8)
		"medium": bar.custom_minimum_size = Vector2(0, 16)
		"large": bar.custom_minimum_size = Vector2(0, 24)

func apply_to_label(lbl: Label, style: String = "body") -> void:
	lbl.theme_type_variation = style

func show_toast(title: String, message: String, type: String = "info", duration: float = 4.0) -> void:
	create_toast(title, message, type, duration)