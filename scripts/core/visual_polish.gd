class_name VisualPolish
extends Node

## Sistema de Polish Visual: shaders, pós-processamento, efeitos atmosféricos

## ==================== SHADERS ===
const SHADERS = {
	"water": """
		shader_type canvas_item;
		uniform sampler2D screen_texture;
		uniform float time;
		uniform float distortion_strength = 0.02;
		uniform vec2 resolution;

		void fragment() {
			vec2 uv = UV;
			uv.x += sin(uv.y * 20.0 + time * 3.0) * distortion_strength;
			uv.y += sin(uv.x * 15.0 + time * 2.0) * distortion_strength * 0.5;
			COLOR = texture(screen_texture, uv);
		}
	""",

	"heat_haze": """
		shader_type canvas_item;
		uniform sampler2D screen_texture;
		uniform float time;
		uniform float intensity = 0.01;

		void fragment() {
			vec2 uv = UV;
			uv.x += sin(uv.y * 10.0 + time * 5.0) * intensity;
			uv.y += cos(uv.x * 8.0 + time * 3.0) * intensity * 0.5;
			COLOR = texture(screen_texture, uv);
		}
	""",

	"pixelate": """
		shader_type canvas_item;
		uniform sampler2D screen_texture;
		uniform int pixel_size = 2;

		void fragment() {
			vec2 uv = UV;
			uv = floor(uv * (1.0 / float(pixel_size))) * float(pixel_size);
			COLOR = texture(screen_texture, uv);
		}
	""",

	"crt": """
		shader_type canvas_item;
		uniform sampler2D screen_texture;
		uniform float time;
		uniform float scanline_intensity = 0.1;
		uniform float vignette = 0.3;

		void fragment() {
			vec2 uv = UV;
			vec4 color = texture(screen_texture, uv);

			// Scanlines
			float scanline = sin(uv.y * 500.0 + time * 50.0) * scanline_intensity;
			color.rgb -= scanline;

			// Vignette
			float dist = length(uv - 0.5) * 1.5;
			color.rgb *= 1.0 - dist * vignette;

			// Slight chromatic aberration
			vec2 offset = vec2(0.001, 0.0);
			float r = texture(screen_texture, uv + offset).r;
			float b = texture(screen_texture, uv - offset).b;
			color.r = r;
			color.b = b;

			COLOR = color;
		}
	""",

	"day_night": """
		shader_type canvas_item;
		uniform sampler2D screen_texture;
		uniform float time_of_day; // 0-2400
		uniform float season; // 0-3

		void fragment() {
			vec2 uv = UV;
			vec4 color = texture(screen_texture, uv);

			// Convert time to 0-1
			float t = time_of_day / 2400.0;

			// Night tint
			float night_factor = 0.0;
			if (t < 0.25 || t > 0.83) {
				night_factor = 1.0 - smoothstep(0.25, 0.35, t) * smoothstep(0.75, 0.83, t);
			}

			vec3 night_color = vec3(0.2, 0.25, 0.4);
			color.rgb = mix(color.rgb, night_color, night_factor * 0.6);

			// Season tint
			if (season == 0.0) { // Spring
				color.rgb *= vec3(1.0, 1.02, 0.98);
			} else if (season == 1.0) { // Summer
				color.rgb *= vec3(1.02, 1.0, 0.95);
			} else if (season == 2.0) { // Fall
				color.rgb *= vec3(1.03, 0.98, 0.9);
			} else if (season == 3.0) { // Winter
				color.rgb *= vec3(0.98, 0.98, 1.02);
			}

			COLOR = color;
		}
	""",

	"underwater": """
		shader_type canvas_item;
		uniform sampler2D screen_texture;
		uniform float time;
		uniform float depth = 1.0;

		void fragment() {
			vec2 uv = UV;
			vec4 color = texture(screen_texture, uv);

			// Caustics
			float caustic = sin(uv.x * 20.0 + time * 2.0) * sin(uv.y * 15.0 + time * 1.5);
			caustic = (caustic + 1.0) * 0.5;

			// Blue tint
			vec3 water_color = vec3(0.1, 0.4, 0.8);
			color.rgb = mix(color.rgb, water_color, depth * 0.5);

			// Caustic lighting
			color.rgb += vec3(caustic * 0.1 * depth);

			// Fog
			color.rgb = mix(color.rgb, vec3(0.05, 0.2, 0.4), depth * 0.3);

			// Distortion
			uv.x += sin(uv.y * 10.0 + time * 3.0) * 0.01 * depth;
			uv.y += cos(uv.x * 8.0 + time * 2.0) * 0.005 * depth;
			color = texture(screen_texture, uv);

			COLOR = color;
		}
	""",

	"transition": """
		shader_type canvas_item;
		uniform sampler2D screen_texture;
		uniform sampler2D next_texture;
		uniform float progress; // 0-1
		uniform int transition_type; // 0=fade, 1=slide, 2=circle, 3=swipe

		void fragment() {
			vec2 uv = UV;
			vec4 from = texture(screen_texture, uv);
			vec4 to = texture(next_texture, uv);

			if (transition_type == 0) {
				// Fade
				COLOR = mix(from, to, progress);
			} else if (transition_type == 1) {
				// Slide horizontal
				vec2 uv_from = uv + vec2(progress - 1.0, 0.0);
				vec2 uv_to = uv + vec2(progress, 0.0);
				COLOR = mix(texture(screen_texture, uv_from), texture(next_texture, uv_to), progress);
			} else if (transition_type == 2) {
				// Circle wipe
				float dist = length(uv - 0.5);
				float radius = progress * 1.5;
				COLOR = mix(from, to, smoothstep(radius - 0.1, radius, dist));
			} else if (transition_type == 3) {
				// Swipe diagonal
				float line = uv.x + uv.y - progress * 2.0;
				COLOR = mix(from, to, step(0.0, line));
			}
		}
	"""
}

## ==================== PÓS-PROCESSAMENTO ===
class PostProcessManager:
	var effects: Array[Dictionary] = []
	var active_shaders: Dictionary = {}

	func add_effect(effect_name: String, params: Dictionary = {}) -> void:
		if not SHADERS.has(effect_name):
			return

		var effect = {
			"name": effect_name,
			"params": params,
			"enabled": true
		}
		effects.append(effect)
		_compile_shader(effect_name)

	func remove_effect(effect_name: String) -> void:
		effects.erase(effect_name)
		if active_shaders.has(effect_name):
			active_shaders[effect_name].queue_free()
			active_shaders.erase(effect_name)

	func set_param(effect_name: String, param: String, value: Variant) -> void:
		for effect in effects:
			if effect.name == effect_name:
				effect.params[param] = value
				if active_shaders.has(effect_name):
					active_shaders[effect_name].material.set_shader_parameter(param, value)
				break

	func _compile_shader(effect_name: String) -> void:
		if active_shaders.has(effect_name):
			return

		var shader_code = SHADERS[effect_name]
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = Shader.new()
		shader_mat.shader.code = shader_code

		# Aplica parâmetros padrão
		# (Seria aplicado via CanvasItem.material ou WorldEnvironment)

		active_shaders[effect_name] = shader_mat

	func get_shader_material(effect_name: String) -> ShaderMaterial:
		return active_shaders.get(effect_name)

## ==================== EFEITOS DE CÂMERA ===
class CameraEffects:
	static func shake(intensity: float = 5.0, duration: float = 0.5) -> void:
		var camera = get_tree().root.get_child(0).get_node_or_null("Camera2D")
		if not camera:
			return

		var original_pos = camera.position
		var tween = camera.create_tween()
		tween.set_loops(int(duration * 30))
		tween.tween_property(camera, "position:x", original_pos.x + randf_range(-intensity, intensity), 0.03)
		tween.tween_property(camera, "position:y", original_pos.y + randf_range(-intensity, intensity), 0.03)
		tween.tween_property(camera, "position", original_pos, 0.1).set_delay(duration)

	static func zoom(target_zoom: float, duration: float = 0.5) -> void:
		var camera = get_tree().root.get_child(0).get_node_or_null("Camera2D")
		if not camera:
			return
		var tween = camera.create_tween()
		tween.tween_property(camera, "zoom", Vector2(target_zoom, target_zoom), duration)

	static func flash(color: Color = Color(1,1,1), duration: float = 0.2) -> void:
		var flash = ColorRect.new()
		flash.color = color
		flash.anchors_preset = 15
		get_tree().root.get_child(0).add_child(flash)

		var tween = flash.create_tween()
		tween.tween_property(flash, "color:a", 0.0, duration)
		tween.finished.connect(flash.queue_free.bind())

	static func vignette(intensity: float = 0.5, duration: float = 1.0) -> void:
		var vignette = ColorRect.new()
		vignette.color = Color(0, 0, 0, 0)
		vignette.anchors_preset = 15
		get_tree().root.get_child(0).add_child(vignette)

		var tween = vignette.create_tween()
		tween.tween_property(vignette, "color", Color(0, 0, 0, intensity), duration * 0.5)
		tween.tween_property(vignette, "color:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
		tween.finished.connect(vignette.queue_free.bind())

## ==================== PARTÍCULAS AVANÇADAS ===
class AdvancedParticles:
	static func create_emitter(position: Vector2, config: Dictionary) -> GPUParticles2D:
		var particles = GPUParticles2D.new()
		particles.global_position = position
		particles.emitting = true
		particles.one_shot = config.get("one_shot", false)
		particles.amount = config.get("amount", 10)
		particles.lifetime = config.get("lifetime", 1.0)
		particles.explosiveness = config.get("explosiveness", 0.5)
		particles.spread = config.get("spread", 45.0)
		particles.gravity = config.get("gravity", Vector2(0, 50))
		particles.initial_velocity = config.get("initial_velocity", 50)
		particles.scale = config.get("scale", 0.2)
		particles.color = config.get("color", Color(1, 1, 1))
		particles.color_ramp = _create_color_ramp(config.get("color_ramp", []))
		particles.scale_curve = _create_curve(config.get("scale_curve", []))
		particles.emission_shape = config.get("emission_shape", GPUParticles2D.EMISSION_SHAPE_POINT)
		particles.emission_ring_radius = config.get("ring_radius", 0.0)

		get_tree().root.get_child(0).add_child(particles)

		if config.get("one_shot", false):
			var timer = Timer.new()
			timer.wait_time = config.get("lifetime", 1.0) + 0.5
			timer.one_shot = true
			timer.timeout.connect(particles.queue_free.bind())
			particles.add_child(timer)
			timer.start()

		return particles

	static func _create_color_ramp(colors: Array) -> Gradient:
		var grad = Gradient.new()
		if colors.size() >= 2:
			grad.colors = PackedColorArray(colors)
		else:
			grad.colors = PackedColorArray([Color(1,1,1), Color(1,1,1,0)])
		return grad

	static func _create_curve(points: Array) -> Curve:
		var curve = Curve.new()
		for p in points:
			curve.add_point(Vector2(p.x, p.y))
		return curve

	static func burst(position: Vector2, color: Color, count: int = 20, speed: float = 100.0) -> void:
		create_emitter(position, {
			"amount": count,
			"lifetime": 0.8,
			"explosiveness": 1.0,
			"spread": 360.0,
			"gravity": Vector2(0, 50),
			"initial_velocity": speed,
			"scale": 0.3,
			"color": color,
			"color_ramp": [color, Color(1,1,1,0)],
			"one_shot": true
		})

	static func trail(position: Vector2, color: Color, length: int = 10) -> GPUParticles2D:
		return create_emitter(position, {
			"amount": length,
			"lifetime": 0.5,
			"explosiveness": 0.0,
			"spread": 10.0,
			"gravity": Vector2(0, 0),
			"initial_velocity": 20.0,
			"scale": 0.2,
			"color": color,
			"color_ramp": [color, Color(1,1,1,0)],
			"emission_shape": GPUParticles2D.EMISSION_SHAPE_LINE
		})

	static func magic_circle(position: Vector2, color: Color, radius: float = 50.0) -> void:
		var particles = GPUParticles2D.new()
		particles.amount = 30
		particles.lifetime = 2.0
		particles.explosiveness = 0.0
		particles.spread = 360.0
		particles.gravity = Vector2(0, -20)
		particles.initial_velocity = 30.0
		particles.scale = 0.2
		particles.color = color
		particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RING
		particles.emission_ring_radius = radius
		particles.one_shot = false
		particles.global_position = position
		particles.emitting = true
		get_tree().root.get_child(0).add_child(particles)

		var tween = particles.create_tween()
		tween.tween_property(particles, "lifetime", 0.0, 2.0)
		tween.finished.connect(particles.queue_free.bind())

	static func portal_effect(position: Vector2, color: Color) -> void:
		var particles = GPUParticles2D.new()
		particles.amount = 50
		particles.lifetime = 3.0
		particles.explosiveness = 0.0
		particles.spread = 360.0
		particles.gravity = Vector2(0, -50)
		particles.initial_velocity = 80.0
		particles.scale = 0.4
		particles.color = color
		particles.color_ramp = Gradient.new()
		particles.color_ramp.colors = PackedColorArray([color.lightened(0.5), color, Color(1,1,1,0)])
		particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RING
		particles.emission_ring_radius = 30.0
		particles.local_coords = false
		particles.one_shot = false
		particles.global_position = position
		get_tree().root.get_child(0).add_child(particles)
		particles.emitting = true

		# Animação de expansão
		var tween = particles.create_tween()
		tween.tween_property(particles, "emission_ring_radius", 80.0, 2.0)
		tween.tween_property(particles, "scale", 0.0, 3.0).set_delay(2.0)
		tween.finished.connect(particles.queue_free.bind())

## ==================== ILUMINAÇÃO DINÂMICA ===
class DynamicLighting:
	static var lights: Array[Dictionary] = []

	static func add_light(position: Vector2, color: Color, radius: float = 100.0, intensity: float = 1.0, flicker: bool = false) -> Light2D:
		var light = Light2D.new()
		light.global_position = position
		light.color = color
		light.light_energy = intensity
		light.light_color = color
		light.height = 50.0
		light.texture_scale = Vector2(0.5, 0.5)
		light.light_mode = Light2D.MODE_ADD

		# Cria textura de luz radial se não existir
		if not light.texture:
			var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
			img.fill(Color(0,0,0,0))
			for x in range(256):
				for y in range(256):
					var dx = x - 128
					var dy = y - 128
					var dist = sqrt(dx*dx + dy*dy)
					if dist < 128:
						var alpha = 1.0 - dist / 128.0
						img.set_pixel(x, y, Color(1,1,1, alpha))
			light.texture = ImageTexture.create_from_image(img)

		if flicker:
			var tween = light.create_tween()
			tween.set_loops()
			tween.tween_property(light, "light_energy", intensity * 0.8, randf_range(0.1, 0.3))
			tween.tween_property(light, "light_energy", intensity * 1.2, randf_range(0.1, 0.3))

		get_tree().root.get_child(0).add_child(light)
		lights.append({"light": light, "position": position})
		return light

	static func remove_light(light: Light2D) -> void:
		if light in lights:
			lights.erase(light)
		light.queue_free()

	static func create_shadow_caster(sprite: Sprite2D, height: float = 10.0) -> LightOccluder2D:
		var occluder = LightOccluder2D.new()
		var polygon = Polygon2D.new()

		# Cria polígono baseado no sprite
		var rect = Rect2(-sprite.texture.get_width()/2, -sprite.texture.get_height()/2, sprite.texture.get_width(), sprite.texture.get_height())
		polygon.polygon = rect.to_polygon()

		occluder.polygon = polygon.polygon
		occluder.height = height

		sprite.add_child(occluder)
		return occluder

	static func set_time_of_day(time: int) -> void:
		# Atualiza luz global (sol/lua)
		var sun = get_tree().root.get_child(0).get_node_or_null("SunLight")
		if not sun:
			sun = DirectionalLight2D.new()
			sun.name = "SunLight"
			get_tree().root.get_child(0).add_child(sun)

		var t = time / 2400.0
		var angle = (t - 0.25) * TAU  # 6:00 = -90°, 12:00 = 0°, 18:00 = 90°
		sun.rotation = angle
		sun.light_energy = clamp(sin(angle + PI/2) * 2.0, 0.1, 1.0)
		sun.light_color = Color(1.0, 0.95, 0.8).lerp(Color(0.3, 0.3, 0.5), 1.0 - clamp(sin(angle + PI/2), 0.0, 1.0))

## ==================== EFEITOS DE TELA ===
class ScreenEffects:
	static func pixelate(amount: int = 4) -> void:
		# Aplica shader de pixelização via CanvasItem.material
		var shader = ShaderMaterial.new()
		shader.shader = Shader.new()
		shader.shader.code = SHADERS["pixelate"]
		shader.set_shader_parameter("pixel_size", amount)
		get_tree().root.get_child(0).material = shader

	static func crt_mode(enabled: bool = true) -> void:
		if enabled:
			var shader = ShaderMaterial.new()
			shader.shader = Shader.new()
			shader.shader.code = SHADERS["crt"]
			get_tree().root.get_child(0).material = shader
		else:
			get_tree().root.get_child(0).material = null

	static func underwater_mode(enabled: bool = true, depth: float = 1.0) -> void:
		if enabled:
			var shader = ShaderMaterial.new()
			shader.shader = Shader.new()
			shader.shader.code = SHADERS["underwater"]
			shader.set_shader_parameter("depth", depth)
			get_tree().root.get_child(0).material = shader
		else:
			get_tree().root.get_child(0).material = null

	static func heat_haze(intensity: float = 0.02) -> void:
		var shader = ShaderMaterial.new()
		shader.shader = Shader.new()
		shader.shader.code = SHADERS["heat_haze"]
		shader.set_shader_parameter("intensity", intensity)
		get_tree().root.get_child(0).material = shader

	static func transition_scene(next_scene: PackedScene, transition_type: int = 0, duration: float = 1.0) -> void:
		var current = get_tree().root.get_child(0)
		var next = next_scene.instantiate()
		get_tree().root.add_child(next)

		var shader = ShaderMaterial.new()
		shader.shader = Shader.new()
		shader.shader.code = SHADERS["transition"]
		shader.set_shader_parameter("next_texture", next.get_viewport().get_texture())
		shader.set_shader_parameter("transition_type", transition_type)
		current.material = shader

		var tween = current.create_tween()
		tween.tween_property(shader, "progress", 1.0, duration)
		tween.finished.connect(func():
			current.queue_free()
			next.material = null
			get_tree().root.add_child(next)
		)

## ==================== UTILIDADES ===
func get_time_of_day() -> int:
	return GameManager.current_time if GameManager else 600

func get_current_season() -> int:
	return GameManager.current_season if GameManager else 0