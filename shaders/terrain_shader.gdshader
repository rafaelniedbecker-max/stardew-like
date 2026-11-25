shader_type canvas_item;
render_mode unshaded;

// ==================== UNIFORMS ====================
uniform sampler2D texture_albedo : source_color;
uniform sampler2D texture_normal : hint_normal;
uniform sampler2D texture_roughness : hint_default_white;
uniform sampler2D texture_ao : hint_default_white;

uniform bool use_normal_map = true;
uniform bool use_roughness = true;
uniform bool use_ao = true;

uniform vec2 normal_map_scale = vec2(1.0, 1.0);
uniform float normal_strength = 1.0;
uniform float roughness_override = -1.0; // -1 = use texture
uniform float ao_override = -1.0;

// Lighting
uniform vec3 light_position = vec3(0.5, 0.5, 100.0);
uniform vec3 light_color = vec3(1.0, 0.95, 0.9);
uniform float light_intensity = 1.5;
uniform float light_radius = 500.0;
uniform bool enable_lighting = true;

// Ambient
uniform vec3 ambient_color = vec3(0.3, 0.3, 0.4);
uniform float ambient_intensity = 0.4;

// Time/Animation
uniform float time = 0.0;
uniform float water_speed = 2.0;

// Seasonal tint
uniform vec3 season_tint = vec3(1.0, 1.0, 1.0);
uniform float season_tint_strength = 0.2;

// Weather
uniform int weather_type = 0; // 0=sun, 1=rain, 2=storm, 3=snow, 4=green rain
uniform float weather_intensity = 0.0;

// ==================== VARYINGS ====================
varying vec2 uv;

// ==================== FRAGMENT ====================
void fragment() {
	// Base UV
	uv = UV;

	// Sample albedo
	vec4 albedo = texture(texture_albedo, uv);

	// Discard transparent pixels
	if (albedo.a < 0.01) {
		discard;
	}

	// Apply seasonal tint
	vec3 color = albedo.rgb * season_tint;
	color = mix(albedo.rgb, color, season_tint_strength);

	// Initialize lighting
	vec3 final_color = color;
	vec3 normal = vec3(0.0, 0.0, 1.0); // Default flat normal (pointing out of screen)
	float roughness = 0.5;
	float ao = 1.0;

	// Normal mapping
	if (use_normal_map) {
		vec3 normal_map = texture(texture_normal, uv * normal_map_scale).rgb;
		// Convert from [0,1] to [-1,1]
		normal_map = normal_map * 2.0 - 1.0;
		// For 2D, we only care about XY (screen space), Z is depth
		// Swap Y for Godot's coordinate system
		normal = normalize(vec3(normal_map.x, -normal_map.y, normal_map.z * normal_strength));
	}

	// Roughness
	if (use_roughness) {
		roughness = texture(texture_roughness, uv).r;
	}
	if (roughness_override >= 0.0) {
		roughness = roughness_override;
	}

	// Ambient Occlusion
	if (use_ao) {
		ao = texture(texture_ao, uv).r;
	}
	if (ao_override >= 0.0) {
		ao = ao_override;
	}

	// Lighting calculation
	if (enable_lighting) {
		// Convert fragment position to world space (approximate)
		vec2 frag_pos = VERTEX.xy;
		vec3 light_dir = normalize(vec3(light_position.xy - frag_pos * 0.01, light_position.z));
		float dist = length(light_position.xy - frag_pos * 0.01);

		// Attenuation
		float attenuation = 1.0 / (1.0 + dist * dist * 0.0001);
		attenuation *= smoothstep(light_radius, 0.0, dist);

		// Diffuse (Lambert)
		float ndotl = max(dot(normal, light_dir), 0.0);
		vec3 diffuse = light_color * ndotl * attenuation * light_intensity;

		// Specular (Blinn-Phong approximation for 2D)
		vec3 view_dir = vec3(0.0, 0.0, 1.0);
		vec3 half_dir = normalize(light_dir + view_dir);
		float ndoth = max(dot(normal, half_dir), 0.0);
		float specular = pow(ndoth, 32.0 * (1.0 - roughness)) * attenuation * light_intensity * 0.5;
		vec3 specular_color = light_color * specular;

		// Combine
		final_color = (color * (ambient_color * ambient_intensity + diffuse) + specular_color) * ao;
	} else {
		final_color = color * (ambient_color * ambient_intensity) * ao;
	}

	// Weather effects
	if (weather_type == 1) { // Rain
		// Darken and desaturate slightly
		final_color *= 0.85;
		final_color = mix(final_color, vec3(0.7, 0.7, 0.85), 0.2 * weather_intensity);
	} else if (weather_type == 2) { // Storm
		final_color *= 0.6;
		final_color = mix(final_color, vec3(0.5, 0.5, 0.65), 0.4 * weather_intensity);
		// Lightning flashes (handled externally)
	} else if (weather_type == 3) { // Snow
		final_color = mix(final_color, vec3(0.9, 0.9, 1.0), 0.3 * weather_intensity);
	} else if (weather_type == 4) { // Green rain
		final_color *= 0.8;
		final_color = mix(final_color, vec3(0.7, 1.0, 0.7), 0.3 * weather_intensity);
	}

	// Water animation (if this is a water tile - detect by blue dominance)
	float is_water = step(0.5, color.b - max(color.r, color.g));
	if (is_water > 0.5) {
		// Animate water normal
		float wave = sin(uv.x * 20.0 + time * water_speed) * 0.5 +
					 sin(uv.y * 20.0 + time * water_speed * 0.7) * 0.5;
		normal.x += wave * 0.1;
		normal.y += wave * 0.1;
		normal = normalize(normal);

		// Recalculate lighting for water
		if (enable_lighting) {
			vec3 light_dir = normalize(vec3(light_position.xy - VERTEX.xy * 0.01, light_position.z));
			float ndotl = max(dot(normal, light_dir), 0.0);
			vec3 diffuse = light_color * ndotl * light_intensity * 2.0; // Water reflects more

			// Specular highlight (sun reflection)
			vec3 view_dir = vec3(0.0, 0.0, 1.0);
			vec3 half_dir = normalize(light_dir + view_dir);
			float ndoth = max(dot(normal, half_dir), 0.0);
			float specular = pow(ndoth, 128.0) * light_intensity * 3.0;
			vec3 specular_color = vec3(1.0, 1.0, 1.0) * specular;

			final_color = vec3(0.1, 0.3, 0.7) * (ambient_color * ambient_intensity + diffuse) + specular_color;
		}
	}

	// Output
	COLOR = vec4(final_color, albedo.a);
}

// ==================== LIGHT ====================
void light() {
	// Custom light processing for 2D lights
	if (!enable_lighting) return;

	// This runs for each light affecting this canvas item
	// Godot 4 2D lights work differently - this is for custom light logic
}