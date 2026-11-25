shader_type canvas_item;
render_mode unshaded;

// Simple normal-mapped terrain shader for Godot 4 TileMapLayer
// Works with CanvasItemMaterial normal_map property

uniform sampler2D texture_normal : hint_normal;
uniform float normal_strength = 1.0;
uniform float normal_depth = 1.0;

varying vec2 uv;

void fragment() {
	uv = UV;

	// Get base color from texture (set via CanvasItemMaterial)
	vec4 base_color = texture(TEXTURE, UV);

	if (base_color.a < 0.01) {
		discard;
	}

	// Sample normal map
	vec3 normal_map = texture(texture_normal, uv).rgb;
	normal_map = normal_map * 2.0 - 1.0;

	// Adjust for 2D (Y is flipped in Godot UV space)
	normal_map.y = -normal_map.y;

	// Apply strength
	normal_map.xy *= normal_strength;
	normal_map.z *= normal_depth;

	// Normalize
	vec3 normal = normalize(normal_map);

	// The actual lighting is handled by Godot's 2D light system
	// when CanvasItemMaterial.normal_map is set and 2D lights are present
	// We just pass the normal through

	COLOR = base_color;
}

// Light processor for custom light interaction (optional)
void light() {
	// Godot handles 2D light interaction automatically when normal_map is set
	// in CanvasItemMaterial. This function is called per-light.
}