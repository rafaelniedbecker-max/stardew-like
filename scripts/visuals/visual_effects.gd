extends Node

## Sistema de Efeitos Visuais: Shaders, Partículas, Iluminação, Pós-processamento

## ==================== SHADERS ====================

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

	"water_surface": """
		shader_type canvas_item;
		uniform float time;
		uniform vec2 resolution;
		uniform sampler2D normal_map;

		void fragment() {
			vec2 uv = UV;
			vec2 distorted_uv = uv;

			// Ondas
			float wave1 = sin(uv.x * 20.0 + time * 2.0) * 0.01;
			float wave2 = sin(uv.y * 15.0 + time * 1.5) * 0.005;
			float wave3 = sin((uv.x + uv.y) * 10.0 + time) * 0.003;

			distorted_uv.x += wave1 + wave3;
			distorted_uv.y += wave2;

			// Reflexão do céu
			vec3 sky_color = vec3(0.5, 0.7, 1.0);
			vec3 water_color = vec3(0.1, 0.3, 0.6);

			float depth = 1.0 - UV.y;
			vec3 color = mix(water_color, sky_color, pow(1.0 - UV.y, 2.0));

			// Caustics
			float caustic = sin(UV.x * 30.0 + TIME * 3.0) * sin(UV.y * 20.0 + TIME * 2.0);
			caustic = (caustic + 1.0) * 0.5;
			color += vec3(caustic * 0.1);

			// Espuma nas bordas
			float foam = smoothstep(0.95, 1.0, UV.y) * sin(UV.x * 50.0 + TIME * 5.0);
			color += vec3(foam * 0.3);

			COLOR = vec4(color, 0.9);
		}
	""",

	"day_night": """
		shader_type canvas_item;
		uniform sampler2D screen_texture;
		uniform float time_of_day; // 0-2400
		uniform float season; // 0-3
		uniform float weather; // 0=sol, 1=chuva, 2=tempestade, 3=neve

		void fragment() {
			vec2 uv = UV;
			vec4 color = texture(screen_texture, uv);

			// Converte hora para 0-1
			float t = time_of_day / 2400.0;

			// Fator noturno
			float night = 0.0;
			if (t < 0.25 || t > 0.83) {
				night = 1.0 - smoothstep(0.25, 0.35, t) * smoothstep(0.75, 0.83, t);
			}

			// Cor da noite
			vec3 night_color = vec3(0.15, 0.15, 0.3);
			color.rgb = mix(color.rgb, night_color, night * 0.7);

			// Estação
			if (season == 0.0) { // Primavera
				color.rgb *= vec3(1.0, 1.02, 0.98);
			} else if (season == 1.0) { // Verão
				color.rgb *= vec3(1.02, 1.0, 0.95);
			} else if (season == 2.0) { // Outono
				color.rgb *= vec3(1.03, 0.98, 0.9);
			} else if (season == 3.0) { // Inverno
				color.rgb *= vec3(0.98, 0.98, 1.02);
			}

			// Clima
			if (weather == 1.0) { // Chuva
				color.rgb *= 0.85;
				color.b += 0.1;
			} else if (weather == 2.0) { // Tempestade
				color.rgb *= 0.6;
				color.b += 0.2;
			} else if (weather == 3.0) { // Neve
				color.rgb = mix(color.rgb, vec3(0.9, 0.9, 1.0), 0.3);
			}

			COLOR = color;
		}
	""",

	"crop_growth": """
		shader_type canvas_item;
		uniform float growth_progress; // 0-1
		uniform vec3 base_color;
		uniform float season;

		void fragment() {
			vec2 uv = UV;
			vec4 tex = texture(TEXTURE, uv);

			if (tex.a == 0.0) discard;

			// Crescimento da planta
			float grow = smoothstep(0.0, 1.0, growth_progress);

			// Cor baseada no progresso
			vec3 sprout = vec3(0.3, 0.7, 0.3);
			vec3 mature = vec3(0.8, 0.5, 0.2);
			vec3 color = mix(sprout, mature, growth_progress);

			// Pulso quando pronto
			float pulse = 1.0;
			if (growth_progress >= 1.0) {
				pulse = 0.8 + 0.2 * sin(TIME * 3.0);
			}

			COLOR = vec4(color * pulse, 1.0);
		}
	""",

	"tool_swing": """
		shader_type canvas_item;
		uniform float swing_progress; // 0-1
		uniform vec2 swing_direction;
		uniform float power;

		void fragment() {
			vec2 uv = UV;
			vec4 tex = texture(TEXTURE, uv);

			if (tex.a == 0.0) discard;

			// Efeito de rastro da ferramenta
			float trail = 1.0 - swing_progress;
			float trail_width = 0.1;

			// Distância da borda do swing
			float dist = abs(UV.x * swing_direction.y - UV.y * swing_direction.x);

			float trail_alpha = smoothstep(0.0, trail_width, dist) * (1.0 - swing_progress);
			vec3 trail_color = vec3(1.0, 0.9, 0.5) * power;

			COLOR = vec4(TEXTURE.rgb + trail_color * trail_alpha, tex.a);
		}
	""",

	"weather_rain": """
		shader_type canvas_item;
		uniform float time;
		uniform float intensity; // 0-1
		uniform vec2 wind_direction;

		void fragment() {
			vec2 uv = UV;
			vec4 color = texture(TEXTURE, uv);

			// Gotas de chuva
			for (int i = 0; i < 50; i++) {
				float seed = float(i) * 12.9898;
				float rand_x = fract(sin(time * 0.5 + float(i) * 13.54) * 43758.5453);
				float rand_y = fract(sin(time * 0.3 + float(i) * 21.73) * 43758.5453);

				float drop_x = fract(uv.x * 100.0 + rand_x + time * 0.3 + wind_direction.x * 0.5);
				float drop_y = fract(uv.y * 100.0 + rand_y + time * 2.0 + wind_direction.y * 0.5);

				float drop = step(0.995, drop_x) * step(0.99, drop_y);
				drop *= smoothstep(0.0, 0.02, abs(uv.x - drop_x) * 50.0) * smoothstep(0.0, 0.1, abs(uv.y - drop_y) * 10.0);

				COLOR.rgb += vec3(0.6, 0.7, 1.0) * drop * 0.5;
			}

			COLOR.rgb *= 1.0 - intensity * 0.2;
			COLOR.b += intensity * 0.1;
		}
	""",

	"weather_snow": """
		shader_type canvas_item;
		uniform float time;
		uniform float intensity;

		void fragment() {
			vec2 uv = UV;
			vec4 color = texture(TEXTURE, uv);

			// Flocos de neve
			for (int i = 0; i < 30; i++) {
				float seed = float(i) * 12.9898;
				float rand_x = fract(sin(time * 0.2 + float(i) * 13.54) * 43758.5453);
				float rand_y = fract(sin(time * 0.15 + float(i) * 21.73) * 43758.5453);

				float flake_x = fract(uv.x * 50.0 + rand_x + time * 0.15 + sin(time * 0.5 + float(i)) * 0.5);
				float flake_y = fract(uv.y * 50.0 + rand_y + time * 0.5 + cos(time * 0.3 + float(i)) * 0.3);

				float flake = step(0.99, flake_x) * step(0.995, flake_y);
				flake *= smoothstep(0.0, 0.02, abs(uv.x - flake_x) * 30.0) * smoothstep(0.0, 0.02, abs(uv.y - flake_y) * 30.0);

				COLOR.rgb += vec3(1.0, 1.0, 1.0) * flake * 0.8;
			}

			// Neblina
			COLOR.rgb = mix(COLOR.rgb, vec3(0.9, 0.9, 1.0), intensity * 0.3);
		}
	""",

	"lighting": """
		shader_type canvas_item;
		uniform sampler2D normal_map;
		uniform vec2 light_pos;
		uniform vec3 light_color;
		uniform float light_radius;
		uniform float ambient;

		void fragment() {
			vec2 uv = UV;
			vec4 tex = texture(TEXTURE, uv);

			if (tex.a == 0.0) discard;

			// Normal map
			vec3 normal = texture(normal_map, uv).rgb * 2.0 - 1.0;
			normal.z = sqrt(max(0.0, 1.0 - normal.x * normal.x - normal.y * normal.y));

			// Luz
			vec2 to_light = light_pos - VERTEX.xy;
			float dist = length(to_light);
			vec2 light_dir = normalize(to_light);

			float attenuation = 1.0 - smoothstep(0.0, light_radius, dist);
			float diffuse = max(dot(normal.xy, light_dir), 0.0) * attenuation;

			vec3 lighting = light_color * diffuse + vec3(ambient);

			COLOR = tex * vec4(lighting, 1.0);
		}
	""",

	"transition": """
		shader_type canvas_item;
		uniform sampler2D from_texture;
		uniform sampler2D to_texture;
		uniform float progress;
		uniform int type; // 0=fade, 1=slide, 2=circle, 3=swipe, 4=dissolve

		void fragment() {
			vec2 uv = UV;
			vec4 from = texture(from_texture, uv);
			vec4 to = texture(to_texture, uv);

			if (type == 0) {
				// Fade
				COLOR = mix(from, to, progress);
			} else if (type == 1) {
				// Slide horizontal
				vec2 uv_from = uv + vec2(progress - 1.0, 0.0);
				vec2 uv_to = uv + vec2(progress, 0.0);
				COLOR = mix(texture(from_texture, uv_from), texture(to_texture, uv_to), progress);
			} else if (type == 2) {
				// Circle wipe
				float dist = length(UV - vec2(0.5));
				float radius = progress * 1.5;
				COLOR = mix(from, to, smoothstep(radius - 0.1, radius, dist));
			} else if (type == 3) {
				// Swipe diagonal
				float line = UV.x + UV.y - progress * 2.0;
				COLOR = mix(from, to, step(0.0, line));
			} else if (type == 4) {
				// Dissolve
				float noise = fract(sin(UV.x * 12.9898 + UV.y * 78.233) * 43758.5453);
				COLOR = mix(from, to, step(noise, progress));
			}
		}
	""",

	"heat_haze": """
		shader_type canvas_item;
		uniform float time;
		uniform float intensity;

		void fragment() {
			vec2 uv = UV;
			vec4 color = texture(screen_texture, uv);

			// Distorção de calor
			vec2 distorted = uv;
			distorted.x += sin(uv.y * 15.0 + time * 5.0) * intensity;
			distorted.y += cos(uv.x * 10.0 + time * 3.0) * intensity * 0.5;

			COLOR = texture(screen_texture, distorted);
		}
	""",

	"magic_glow": """
		shader_type canvas_item;
		uniform float time;
		uniform vec3 glow_color;
		uniform float intensity;
		uniform sampler2D mask;

		void fragment() {
			vec4 tex = texture(TEXTURE, UV);
			vec4 mask_tex = texture(mask, UV);

			if (tex.a == 0.0 && mask_tex.a == 0.0) discard;

			// Brilho pulsante
			float pulse = 0.5 + 0.5 * sin(time * 2.0);
			vec3 glow = glow_color * intensity * pulse * mask_tex.r;

			COLOR = tex + vec4(glow, 0.0);
		}
	""",

	"pixelate": """
		shader_type canvas_item;
		uniform int pixel_size;

		void fragment() {
			vec2 uv = UV;
			uv = floor(uv * (1.0 / float(pixel_size))) * float(pixel_size);
			COLOR = texture(TEXTURE, uv);
		}
	""",

	"crt": """
		shader_type canvas_item;
		uniform float time;
		uniform float scanline_intensity;
		uniform float vignette;

		void fragment() {
			vec2 uv = UV;
			vec4 color = texture(screen_texture, uv);

			// Scanlines
			float scanline = sin(uv.y * 500.0 + time * 50.0) * scanline_intensity;
			color.rgb -= scanline;

			// Vignette
			float dist = length(uv - 0.5) * 1.5;
			color.rgb *= 1.0 - dist * vignette;

			// Chromatic aberration
			vec2 offset = vec2(0.001, 0.0);
			float r = texture(screen_texture, uv + offset).r;
			float b = texture(screen_texture, uv - offset).b;
			color.r = r;
			color.b = b;

			COLOR = color;
		}
	"""
}

## ==================== SISTEMA DE PARTÍCULAS ====================

class ParticleSystemManager:
	static var emitters: Array = []

	static func create_emitter(config: Dictionary) -> GPUParticles2D:
		var particles = GPUParticles2D.new()
		particles.emitting = config.get("emitting", true)
		particles.one_shot = config.get("one_shot", false)
		particles.amount = config.get("amount", 10)
		particles.lifetime = config.get("lifetime", 1.0)
		particles.explosiveness = config.get("explosiveness", 0.5)
		particles.spread = config.get("spread", 45.0)
		particles.gravity = config.get("gravity", Vector2(0, 50))
		particles.initial_velocity = config.get("initial_velocity", 50)
		particles.scale = config.get("scale", 0.2)
		particles.scale_curve = _create_curve(config.get("scale_curve", []))
		particles.color = config.get("color", Color(1, 1, 1))
		particles.color_ramp = _create_color_ramp(config.get("color_ramp", []))
		particles.emission_shape = config.get("emission_shape", GPUParticles2D.EMISSION_SHAPE_POINT)
		particles.local_coords = config.get("local_coords", false)

		if config.has("emission_ring_radius"):
			particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RING
			particles.emission_ring_radius = config.emission_ring_radius

		if config.has("emission_rect_extents"):
			particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
			particles.emission_rect_extents = config.emission_rect_extents

		get_tree().root.get_child(0).add_child(particles)
		emitters.append(particles)

		if config.get("one_shot", false):
			var timer = Timer.new()
			timer.wait_time = config.get("lifetime", 1.0) + 0.5
			timer.one_shot = true
			timer.timeout.connect(particles.queue_free.bind())
			particles.add_child(timer)
			timer.start()

		return particles

	static func _create_curve(points: Array) -> Curve:
		var c = Curve.new()
		for p in points:
			c.add_point(Vector2(p.x, p.y))
		return c

	static func _create_color_ramp(colors: Array) -> Gradient:
		var g = Gradient.new()
		if colors.size() >= 2:
			g.colors = PackedColorArray(colors)
		else:
			g.colors = PackedColorArray([Color(1,1,1), Color(1,1,1,0)])
		return g

	static func clear_all() -> void:
		for e in emitters:
			if e.is_inside_tree():
				e.queue_free()
		emitters.clear()

	# Efeitos pré-definidos
	static func tool_hit_hoe(position: Vector2) -> void:
		create_emitter({
			"amount": 15,
			"lifetime": 0.5,
			"explosiveness": 1.0,
			"spread": 45,
			"gravity": Vector2(0, 100),
			"initial_velocity": 60,
			"scale": 0.3,
			"color": Color(0.4, 0.25, 0.15, 0.8),
			"color_ramp": [Color(0.5, 0.3, 0.2, 0.8), Color(0.3, 0.2, 0.1, 0.0)],
			"one_shot": true,
			"global_position": position
		})

	static func tool_hit_watering(position: Vector2) -> void:
		create_emitter({
			"amount": 20,
			"lifetime": 0.4,
			"explosiveness": 0.8,
			"spread": 30,
			"gravity": Vector2(0, 50),
			"initial_velocity": 40,
			"scale": 0.2,
			"color": Color(0.2, 0.5, 1.0, 0.7),
			"color_ramp": [Color(0.3, 0.6, 1.0, 0.7), Color(0.2, 0.4, 0.8, 0.0)],
			"one_shot": true,
			"global_position": position
		})

	static func tool_hit_axe(position: Vector2) -> void:
		create_emitter({
			"amount": 15,
			"lifetime": 0.4,
			"explosiveness": 0.9,
			"spread": 40,
			"gravity": Vector2(0, 100),
			"initial_velocity": 70,
			"scale": 0.3,
			"color": Color(0.3, 0.6, 0.2, 0.8),
			"color_ramp": [Color(0.4, 0.7, 0.3, 0.8), Color(0.2, 0.4, 0.1, 0.0)],
			"one_shot": true,
			"global_position": position
		})

	static func tool_hit_pickaxe(position: Vector2) -> void:
		create_emitter({
			"amount": 20,
			"lifetime": 0.5,
			"explosiveness": 1.0,
			"spread": 50,
			"gravity": Vector2(0, 150),
			"initial_velocity": 100,
			"scale": 0.35,
			"color": Color(0.5, 0.45, 0.4, 0.9),
			"color_ramp": [Color(0.6, 0.55, 0.5, 0.9), Color(0.3, 0.25, 0.2, 0.0)],
			"one_shot": true,
			"global_position": position
		})

	static func harvest_effect(position: Vector2) -> void:
		create_emitter({
			"amount": 25,
			"lifetime": 0.8,
			"explosiveness": 1.0,
			"spread": 60,
			"gravity": Vector2(0, 120),
			"initial_velocity": 80,
			"scale": 0.4,
			"scale_curve": [Vector2(0, 1), Vector2(0.5, 1.2), Vector2(1, 0)],
			"color": Color(0.9, 0.7, 0.2, 1.0),
			"color_ramp": [Color(1.0, 0.8, 0.3, 1.0), Color(0.8, 0.5, 0.1, 0.0)],
			"one_shot": true,
			"global_position": position
		})

	static func level_up_effect(position: Vector2, text: String = "Level Up!") -> void:
		var particles = GPUParticles2D.new()
		particles.amount = 30
		particles.lifetime = 1.5
		particles.explosiveness = 0.5
		particles.spread = 360
		particles.gravity = Vector2(0, -50)
		particles.initial_velocity = 30
		particles.scale = 0.5
		particles.scale_curve = _create_curve([Vector2(0, 0), Vector2(0.3, 1), Vector2(1, 0)])
		particles.color = Color(1.0, 0.9, 0.3, 1.0)
		particles.color_ramp = _create_color_ramp([Color(1.0, 1.0, 0.5, 1.0), Color(1.0, 0.8, 0.0, 0.0)])
		particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RING
		particles.emission_ring_radius = 20
		particles.one_shot = true
		particles.global_position = position
		get_tree().root.get_child(0).add_child(particles)
		particles.emitting = true

		# Texto flutuante
		var label = Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.theme_override_font_size = 24
		label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		label.add_theme_constant_override("outline_size", 2)
		label.global_position = position
		get_tree().root.get_child(0).add_child(label)

		var tween = label.create_tween()
		tween.tween_property(label, "global_position:y", position.y - 60, 1.5)
		tween.tween_property(label, "modulate:a", 0.0, 1.5)
		tween.finished.connect(label.queue_free.bind())

	static func weather_rain(intensity: float = 1.0) -> GPUParticles2D:
		var particles = GPUParticles2D.new()
		particles.amount = int(500 * intensity)
		particles.lifetime = 2.0
		particles.explosiveness = 0.0
		particles.spread = 5
		particles.gravity = Vector2(30, 400)
		particles.initial_velocity = 200
		particles.scale = 0.1
		particles.color = Color(0.6, 0.7, 0.9, 0.4)
		particles.color_ramp = _create_gradient(Color(0.6, 0.7, 0.9, 0.4), Color(0.5, 0.6, 0.8, 0.0))
		particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(1920, 100)
		particles.local_coords = false
		particles.one_shot = false
		get_tree().root.get_child(0).add_child(particles)
		particles.emitting = true
		return particles

	static func weather_snow(intensity: float = 1.0) -> GPUParticles2D:
		var particles = GPUParticles2D.new()
		particles.amount = int(300 * intensity)
		particles.lifetime = 5.0
		particles.explosiveness = 0.0
		particles.spread = 10
		particles.gravity = Vector2(20, 80)
		particles.initial_velocity = 30
		particles.scale = 0.15
		particles.color = Color(1.0, 1.0, 1.0, 0.6)
		particles.color_ramp = _create_gradient(Color(1.0, 1.0, 1.0, 0.6), Color(0.9, 0.9, 1.0, 0.0))
		particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(1920, 100)
		particles.local_coords = false
		particles.one_shot = false
		get_tree().root.get_child(0).add_child(particles)
		particles.emitting = true
		return particles

	static func weather_storm(intensity: float = 1.0) -> GPUParticles2D:
		var particles = GPUParticles2D.new()
		particles.amount = int(800 * intensity)
		particles.lifetime = 1.5
		particles.explosiveness = 0.0
		particles.spread = 15
		particles.gravity = Vector2(50, 500)
		particles.initial_velocity = 300
		particles.scale = 0.1
		particles.color = Color(0.5, 0.55, 0.7, 0.5)
		particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(1920, 100)
		particles.local_coords = false
		particles.one_shot = false
		get_tree().root.get_child(0).add_child(particles)
		particles.emitting = true
		return particles

	static func petals_spring() -> GPUParticles2D:
		var particles = GPUParticles2D.new()
		particles.amount = 100
		particles.lifetime = 8.0
		particles.explosiveness = 0.0
		particles.spread = 45
		particles.gravity = Vector2(10, 20)
		particles.initial_velocity = 15
		particles.scale = 0.2
		particles.angular_velocity = 2
		particles.color = Color(1.0, 0.7, 0.8, 0.5)
		particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(1920, 1080)
		particles.local_coords = false
		particles.one_shot = false
		get_tree().root.get_child(0).add_child(particles)
		particles.emitting = true
		return particles

	static func leaves_fall() -> GPUParticles2D:
		var particles = GPUParticles2D.new()
		particles.amount = 80
		particles.lifetime = 10.0
		particles.explosiveness = 0.0
		particles.spread = 30
		particles.gravity = Vector2(30, 40)
		particles.initial_velocity = 20
		particles.scale = 0.25
		particles.angular_velocity = 3
		particles.color = Color(0.8, 0.4, 0.2, 0.5)
		particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(1920, 1080)
		particles.local_coords = false
		particles.one_shot = false
		get_tree().root.get_child(0).add_child(particles)
		particles.emitting = true
		return particles

	static func fairy_blessing(position: Vector2) -> void:
		create_emitter({
			"amount": 50,
			"lifetime": 2.0,
			"explosiveness": 1.0,
			"spread": 360,
			"gravity": Vector2(0, -30),
			"initial_velocity": 100,
			"scale": 0.4,
			"scale_curve": [Vector2(0, 0), Vector2(0.5, 1.5), Vector2(1, 0)],
			"color": Color(1.0, 0.5, 1.0, 1.0),
			"color_ramp": [Color(1.0, 1.0, 0.5, 1.0), Color(1.0, 0.3, 1.0, 0.0)],
			"emission_shape": GPUParticles2D.EMISSION_SHAPE_RING,
			"emission_ring_radius": 50,
			"one_shot": true,
			"global_position": position
		})

	static func junimo_harvest(area: Rect2) -> void:
		for i in range(20):
			var pos = Vector2(randi_range(int(area.position.x), int(area.end.x)), randi_range(int(area.position.y), int(area.end.y)))
			create_emitter({
				"amount": 5,
				"lifetime": 1.0,
				"explosiveness": 1.0,
				"spread": 90,
				"gravity": Vector2(0, -20),
				"initial_velocity": 50,
				"scale": 0.3,
				"color": Color(0.5, 1.0, 0.5, 1.0),
				"color_ramp": [Color(0.4, 1.0, 0.4, 1.0), Color(0.3, 0.8, 0.3, 0.0)],
				"one_shot": true,
				"global_position": Vector2(randi_range(int(area.position.x), int(area.end.x)), randi_range(int(area.position.y), int(area.end.y)))
			})

	static func star_shower(center: Vector2) -> void:
		var particles = GPUParticles2D.new()
		particles.amount = 100
		particles.lifetime = 5.0
		particles.explosiveness = 1.0
		particles.spread = 360
		particles.gravity = Vector2(0, 50)
		particles.initial_velocity = 200
		particles.scale = 0.2
		particles.color = Color(1.0, 1.0, 0.6, 1.0)
		particles.color_ramp = _create_gradient(Color(1.0, 1.0, 0.8, 1.0), Color(1.0, 0.9, 0.3, 0.0))
		particles.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
		particles.emission_rect_extents = Vector2(1920, 100)
		particles.local_coords = false
		particles.one_shot = true
		particles.global_position = center + Vector2(0, -500)
		get_tree().root.get_child(0).add_child(particles)
		particles.emitting = true

	static func aurora_borealis() -> void:
		var colors = [
			Color(0.3, 1.0, 0.5, 0.3),
			Color(0.5, 0.3, 1.0, 0.3),
			Color(1.0, 0.3, 0.5, 0.3)
		]

		for i in range(3):
			var aurora = GPUParticles2D.new()
			aurora.amount = 50
			aurora.lifetime = 10.0
			aurora.explosiveness = 0.0
			aurora.spread = 180
			aurora.gravity = Vector2(0, -20)
			aurora.initial_velocity = 30
			aurora.scale = 0.5
			aurora.scale_curve = _create_curve([Vector2(0, 0), Vector2(0.5, 1), Vector2(1, 0)])
			aurora.color = colors[i]
			aurora.emission_shape = GPUParticles2D.EMISSION_SHAPE_RECTANGLE
			aurora.emission_rect_extents = Vector2(1920, 200)
			aurora.local_coords = false
			aurora.one_shot = true
			aurora.global_position = Vector2(0, 200 + i * 100)
			get_tree().root.get_child(0).add_child(aurora)
			aurora.emitting = true

	static func _create_gradient(from: Color, to: Color) -> Gradient:
		var g = Gradient.new()
		g.colors = PackedColorArray([from, to])
		return g

	static func _create_curve(points: Array) -> Curve:
		var c = Curve.new()
		for p in points:
			c.add_point(Vector2(p.x, p.y))
		return c

## ==================== ILUMINAÇÃO DINÂMICA ====================

class DynamicLighting:
	static var lights: Array = []

	static func add_light(position: Vector2, color: Color, radius: float = 100.0, intensity: float = 1.0, flicker: bool = false) -> Light2D:
		var light = Light2D.new()
		light.global_position = position
		light.color = color
		light.light_energy = intensity
		light.light_color = color
		light.height = 50.0
		light.texture_scale = Vector2(0.5, 0.5)

		# Textura radial
		if not light.texture:
			var img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 0))
			for x in range(256):
				for y in range(256):
					var dx = x - 128
					var dy = y - 128
					var dist = sqrt(dx*dx + dy*dy)
					if dist < 128:
						var alpha = 1.0 - dist / 128.0
						img.set_pixel(x, y, Color(1, 1, 1, alpha))
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

		var rect = Rect2(-sprite.texture.get_width()/2, -sprite.texture.get_height()/2, sprite.texture.get_width(), sprite.texture.get_height())
		polygon.polygon = rect.to_polygon()

		occluder.polygon = polygon.polygon
		occluder.height = height

		sprite.add_child(occluder)
		return occluder

	static func set_time_of_day(time: int) -> void:
		var sun = get_tree().root.get_child(0).get_node_or_null("SunLight")
		if not sun:
			sun = DirectionalLight2D.new()
			sun.name = "SunLight"
			get_tree().root.get_child(0).add_child(sun)

		var t = time / 2400.0
		var angle = (t - 0.25) * TAU
		sun.rotation = angle
		sun.light_energy = clamp(sin(angle + PI/2) * 2.0, 0.1, 1.0)
		sun.light_color = Color(1.0, 0.95, 0.8).lerp(Color(0.3, 0.3, 0.5), 1.0 - clamp(sin(angle + PI/2), 0.0, 1.0))

		# Lua
		var moon = get_tree().root.get_child(0).get_node_or_null("MoonLight")
		if not moon:
			moon = DirectionalLight2D.new()
			moon.name = "MoonLight"
			get_tree().root.get_child(0).add_child(moon)

		moon.rotation = angle + PI
		moon.light_energy = clamp(-sin(angle + PI/2) * 0.5, 0.0, 0.3)
		moon.light_color = Color(0.4, 0.4, 0.6)

## ==================== EFEITOS DE CÂMERA ====================

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

	static func pixelate(amount: int = 4) -> void:
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

## ==================== EFEITOS DE UI ====================

class UIEffects:
	static func show_toast(title: String, message: String, type: String = "info", duration: float = 4.0) -> void:
		var colors = {
			"info": Color(0.3, 0.7, 1.0),
			"success": Color(0.4, 1.0, 0.4),
			"warning": Color(1.0, 0.8, 0.2),
			"danger": Color(1.0, 0.3, 0.3)
		}

		var panel = Panel.new()
		panel.anchors_preset = 11 # Top right
		panel.offset_left = -350
		panel.offset_top = 50 + (UIEffects._get_toast_count() * 90)
		panel.offset_right = -20
		panel.offset_bottom = -120
		panel.add_theme_stylebox_override("panel", UIEffects._create_toast_stylebox(colors.get(type, Color.WHITE)))

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 5)
		panel.add_child(vbox)

		var icon_label = Label.new()
		icon_label.text = {"info": "ℹ️", "success": "✅", "warning": "⚠️", "danger": "❌"}.get(type, "ℹ️")
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.theme_override_font_size = 24
		vbox.add_child(icon_label)

		var title_label = Label.new()
		title_label.text = title
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.theme_override_font_size = 16
		vbox.add_child(title_label)

		var msg_label = Label.new()
		msg_label.text = message
		msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		msg_label.autowrap_mode = 1
		msg_label.theme_override_font_size = 13
		vbox.add_child(msg_label)

		# Animação
		panel.modulate = Color(1, 1, 1, 0)
		panel.position = Vector2(50, 0)
		var tween = panel.create_tween()
		tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.3).set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "position", Vector2(0, 0), 0.3).set_trans(Tween.TRANS_BACK)

		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(UIEffects._fade_out_toast.bind(panel))
		panel.add_child(timer)
		timer.start()

		get_tree().root.get_child(0).add_child(panel)

	static func _get_toast_count() -> int:
		var count = 0
		var root = get_tree().root.get_child(0)
		for child in root.get_children():
			if child.name.begins_with("Toast_"):
				count += 1
		return count

	static func _fade_out_toast(panel: Panel) -> void:
		var tween = panel.create_tween()
		tween.tween_property(panel, "modulate:a", 0.0, 0.5)
		tween.tween_property(panel, "position:x", 50, 0.5)
		tween.finished.connect(panel.queue_free.bind())

	static func _create_toast_stylebox(color: Color) -> StyleBoxFlat:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.1, 0.1, 0.15, 0.95)
		sb.border_color = color
		sb.border_width_bottom = 3
		sb.border_width_top = 1
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		return sb

	static func animate_button_press(button: Button) -> void:
		var tween = button.create_tween()
		tween.tween_property(button, "scale", Vector2(0.95, 0.95), 0.05)
		tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BOUNCE)

	static func animate_item_get(icon: TextureRect, target_pos: Vector2) -> void:
		var tween = icon.create_tween()
		tween.tween_property(icon, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(icon, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(icon, "scale", Vector2(0, 0), 0.2).set_delay(0.5)
		tween.finished.connect(icon.queue_free.bind())

	static func pulse_icon(icon: TextureRect, color: Color = Color(1, 1, 0.3)) -> void:
		var tween = icon.create_tween()
		tween.set_loops()
		tween.tween_property(icon, "modulate", color, 0.5)
		tween.tween_property(icon, "modulate", Color(1, 1, 1), 0.5)

	static func show_level_up(skill_name: String, level: int, position: Vector2) -> void:
		var panel = Panel.new()
		panel.anchors_preset = 15
		panel.offset_left = -200
		panel.offset_top = -100
		panel.offset_right = 200
		panel.offset_bottom = 100

		var vbox = VBoxContainer.new()
		vbox.anchors_preset = 15
		vbox.offset_left = 20
		vbox.offset_top = 20
		vbox.offset_right = -20
		vbox.offset_bottom = -20
		vbox.add_theme_constant_override("separation", 10)
		panel.add_child(vbox)

		var icon_label = Label.new()
		icon_label.text = "⭐"
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.theme_override_font_size = 48
		vbox.add_child(icon_label)

		var level_label = Label.new()
		level_label.text = "%s\nNível %d!" % [skill_name, level]
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.theme_override_font_size = 28
		level_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		vbox.add_child(level_label)

		get_tree().root.get_child(0).add_child(panel)

		panel.modulate = Color(1, 1, 1, 0)
		panel.scale = Vector2(0.5, 0.5)
		var tween = panel.create_tween()
		tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.4).set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK)

		var timer = Timer.new()
		timer.wait_time = 3.0
		timer.one_shot = true
		timer.timeout.connect(UIEffects._fade_out_toast.bind(panel))
		panel.add_child(timer)
		timer.start()

		if ParticleManager:
			ParticleSystemManager.show_level_up(position, skill_name)