class_name NPCPortraits
extends Node

## Sistema de Retratos NPC com animações e expressões

@export var portrait_atlas: Texture2D = null

## Dados de retratos por NPC
const PORTRAIT_DATA = {
	"Abigail": {
		"base": "abigail_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"sad": {"x": 128, "y": 0, "w": 64, "h": 64},
			"angry": {"x": 192, "y": 0, "w": 64, "h": 64},
			"surprised": {"x": 256, "y": 0, "w": 64, "h": 64},
			"love": {"x": 0, "y": 64, "w": 64, "h": 64},
			"blush": {"x": 64, "y": 64, "w": 64, "h": 64},
			"thinking": {"x": 128, "y": 64, "w": 64, "h": 64},
			"sleepy": {"x": 192, "y": 64, "w": 64, "h": 64},
			"drunk": {"x": 256, "y": 64, "w": 64, "h": 64}
		}
	},
	"Alex": {
		"base": "alex_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"sad": {"x": 128, "y": 0, "w": 64, "h": 64},
			"angry": {"x": 192, "y": 0, "w": 64, "h": 64},
			"flex": {"x": 256, "y": 0, "w": 64, "h": 64},
			"love": {"x": 0, "y": 64, "w": 64, "h": 64},
			"blush": {"x": 64, "y": 64, "w": 64, "h": 64},
			"sweaty": {"x": 128, "y": 64, "w": 64, "h": 64},
			"proud": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	},
	"Elliott": {
		"base": "elliott_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"sad": {"x": 128, "y": 0, "w": 64, "h": 64},
			"romantic": {"x": 192, "y": 0, "w": 64, "h": 64},
			"love": {"x": 256, "y": 0, "w": 64, "h": 64},
			"blush": {"x": 0, "y": 64, "w": 64, "h": 64},
			"thinking": {"x": 64, "y": 64, "w": 64, "h": 64},
			"surprised": {"x": 128, "y": 64, "w": 64, "h": 64},
			"dramatic": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	},
	"Emily": {
		"base": "emily_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"excited": {"x": 128, "y": 0, "w": 64, "h": 64},
			"love": {"x": 192, "y": 0, "w": 64, "h": 64},
			"blush": {"x": 256, "y": 0, "w": 64, "h": 64},
			"dance": {"x": 0, "y": 64, "w": 64, "h": 64},
			"sparkle": {"x": 64, "y": 64, "w": 64, "h": 64},
			"dreamy": {"x": 128, "y": 64, "w": 64, "h": 64},
			"surprised": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	},
	"Haley": {
		"base": "haley_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"annoyed": {"x": 128, "y": 0, "w": 64, "h": 64},
			"angry": {"x": 192, "y": 0, "w": 64, "h": 64},
			"love": {"x": 256, "y": 0, "w": 64, "h": 64},
			"blush": {"x": 0, "y": 64, "w": 64, "h": 64},
			"selfie": {"x": 64, "y": 64, "w": 64, "h": 64},
			"sad": {"x": 128, "y": 64, "w": 64, "h": 64},
			"proud": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	},
	"Harvey": {
		"base": "harvey_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"concerned": {"x": 128, "y": 0, "w": 64, "h": 64},
			"love": {"x": 192, "y": 0, "w": 64, "h": 64},
			"blush": {"x": 256, "y": 0, "w": 64, "h": 64},
			"tired": {"x": 0, "y": 64, "w": 64, "h": 64},
			"thinking": {"x": 64, "y": 64, "w": 64, "h": 64},
			"surprised": {"x": 128, "y": 64, "w": 64, "h": 64},
			"professional": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	},
	"Leah": {
		"base": "leah_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"sad": {"x": 128, "y": 0, "w": 64, "h": 64},
			"love": {"x": 192, "y": 0, "w": 64, "h": 64},
			"blush": {"x": 256, "y": 0, "w": 64, "h": 64},
			"inspired": {"x": 0, "y": 64, "w": 64, "h": 64},
			"thinking": {"x": 64, "y": 64, "w": 64, "h": 64},
			"peaceful": {"x": 128, "y": 64, "w": 64, "h": 64},
			"excited": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	},
	"Maru": {
		"base": "maru_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"love": {"x": 128, "y": 0, "w": 64, "h": 64},
			"blush": {"x": 192, "y": 0, "w": 64, "h": 64},
			"curious": {"x": 256, "y": 0, "w": 64, "h": 64},
			"thinking": {"x": 0, "y": 64, "w": 64, "h": 64},
			"surprised": {"x": 64, "y": 64, "w": 64, "h": 64},
			"proud": {"x": 128, "y": 64, "w": 64, "h": 64},
			"science": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	},
	"Penny": {
		"base": "penny_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"sad": {"x": 128, "y": 0, "w": 64, "h": 64},
			"love": {"x": 192, "y": 0, "w": 64, "h": 64},
			"blush": {"x": 256, "y": 0, "w": 64, "h": 64},
			"shy": {"x": 0, "y": 64, "w": 64, "h": 64},
			"thinking": {"x": 64, "y": 64, "w": 64, "h": 64},
			"reading": {"x": 128, "y": 64, "w": 64, "h": 64},
			"hopeful": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	},
	"Sam": {
		"base": "sam_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"excited": {"x": 128, "y": 0, "w": 64, "h": 64},
			"love": {"x": 192, "y": 0, "w": 64, "h": 64},
			"blush": {"x": 256, "y": 0, "w": 64, "h": 64},
			"rock_on": {"x": 0, "y": 64, "w": 64, "h": 64},
			"cool": {"x": 64, "y": 64, "w": 64, "h": 64},
			"surprised": {"x": 128, "y": 64, "w": 64, "h": 64},
			"laughing": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	},
	"Sebastian": {
		"base": "sebastian_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"annoyed": {"x": 128, "y": 0, "w": 64, "h": 64},
			"love": {"x": 192, "y": 0, "w": 64, "h": 64},
			"blush": {"x": 256, "y": 0, "w": 64, "h": 64},
			"tired": {"x": 0, "y": 64, "w": 64, "h": 64},
			"thinking": {"x": 64, "y": 64, "w": 64, "h": 64},
			"smirk": {"x": 128, "y": 64, "w": 64, "h": 64},
			"gaming": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	},
	"Shane": {
		"base": "shane_base",
		"expressions": {
			"neutral": {"x": 0, "y": 0, "w": 64, "h": 64},
			"happy": {"x": 64, "y": 0, "w": 64, "h": 64},
			"sad": {"x": 128, "y": 0, "w": 64, "h": 64},
			"drunk": {"x": 192, "y": 0, "w": 64, "h": 64},
			"love": {"x": 256, "y": 0, "w": 64, "h": 64},
			"blush": {"x": 0, "y": 64, "w": 64, "h": 64},
			"tired": {"x": 64, "y": 64, "w": 64, "h": 64},
			"hopeful": {"x": 128, "y": 64, "w": 64, "h": 64},
			"determined": {"x": 192, "y": 64, "w": 64, "h": 64}
		}
	}
}

## ==================== FUNÇÕES ====================
static func get_portrait_region(npc_name: String, expression: String = "neutral") -> Rect2:
	var data = PORTRAIT_DATA.get(npc_name)
	if not data:
		return Rect2(0, 0, 64, 64)

	var expr = data.expressions.get(expression, data.expressions["neutral"])
	return Rect2(expr.x, expr.y, expr.w, expr.h)

static func get_portrait_texture(npc_name: String) -> Texture2D:
	var data = PORTRAIT_DATA.get(npc_name)
	if not data or not data.base:
		return null

	# Tenta carregar do caminho padrão
	var path = "res://resources/sprites/portraits/%s.png" % data.base
	if ResourceLoader.exists(path):
		return load(path)
	return null

static func create_portrait_control(npc_name: String, expression: String = "neutral", size: Vector2 = Vector2(128, 128)) -> TextureRect:
	var ctrl = TextureRect.new()
	ctrl.custom_minimum_size = size
	ctrl.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var texture = get_portrait_texture(npc_name)
	if texture:
		ctrl.texture = texture
		ctrl.region_enabled = true
		ctrl.region_rect = get_portrait_region(npc_name, expression)
	else:
		# Fallback procedural
		ctrl.texture = _create_placeholder_portrait(npc_name)

	return ctrl

static func _create_placeholder_portrait(npc_name: String) -> Texture2D:
	var colors = {
		"Abigail": Color(0.6, 0.3, 0.8),
		"Alex": Color(0.2, 0.6, 1.0),
		"Elliott": Color(0.8, 0.4, 1.0),
		"Emily": Color(1.0, 0.5, 0.8),
		"Haley": Color(1.0, 0.8, 0.3),
		"Harvey": Color(0.4, 0.8, 0.4),
		"Leah": Color(0.6, 1.0, 0.6),
		"Maru": Color(0.8, 0.6, 1.0),
		"Penny": Color(1.0, 0.9, 0.5),
		"Sam": Color(1.0, 0.6, 0.2),
		"Sebastian": Color(0.4, 0.3, 0.6),
		"Shane": Color(0.6, 0.5, 0.4)
	}
	var color = colors.get(npc_name, Color(0.5, 0.5, 0.5))

	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(color)

	# Desenha silhueta simples
	for x in range(16, 48):
		for y in range(16, 48):
			var dx = (x - 32) / 16
			var dy = (y - 32) / 16
			if dx*dx + dy*dy < 1:
				img.set_pixel(x, y, color.lightened(0.3))

	return ImageTexture.create_from_image(img)

## Animação de expressão
static func animate_expression(portrait: TextureRect, npc_name: String, from_expr: String, to_expr: String, duration: float = 0.3) -> void:
	if not portrait or not portrait.texture:
		return

	var from_region = get_portrait_region(npc_name, from_expr)
	var to_region = get_portrait_region(npc_name, to_expr)

	var tween = portrait.create_tween()
	tween.tween_property(portrait, "region_rect", to_region, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Efeito de "pop" na transição
	var original_scale = portrait.scale
	tween.tween_property(portrait, "scale", original_scale * 1.1, duration * 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_property(portrait, "scale", original_scale, duration * 0.7).set_trans(Tween.TRANS_BACK)