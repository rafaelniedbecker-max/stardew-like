shader_type canvas_item;
// PBR 2D Shader for Godot 4 - uses normal maps for dynamic lighting
// Usage: Apply to Sprite2D/AnimatedSprite2D, assign albedo + normal textures

uniform sampler2D texture_albedo : source_color;
uniform sampler2D texture_normal : hint_normal_map;
uniform sampler2D texture_roughness : hint_white;

uniform vec3 light_position : source_position = vec3(0.0, 0.0, 100.0);
uniform vec3 light_color = vec3(1.0, 0.95, 0.9);
uniform float light_intensity = 2.0;
uniform float ambient_strength = 0.3;
uniform float specular_strength = 0.5;
uniform float normal_strength = 1.0;

void fragment() {
    vec2 uv = UV;
    vec4 albedo = texture(texture_albedo, uv);
    vec3 normal_map = texture(texture_normal, uv).rgb * 2.0 - 1.0;
    float roughness = texture(texture_roughness, uv).r;

    // Apply normal strength
    normal_map.xy *= normal_strength;
    normal_map = normalize(normal_map);

    // Light direction
    vec3 frag_pos = vec3(uv * VIEWPORT_SIZE, 0.0);
    vec3 light_dir = normalize(light_position - frag_pos);
    float dist = length(light_position - frag_pos);
    float attenuation = 1.0 / (1.0 + 0.001 * dist * dist);

    // Diffuse
    float diff = max(dot(normal_map, light_dir), 0.0);
    vec3 diffuse = diff * light_color * light_intensity * attenuation;

    // Specular (Blinn-Phong)
    vec3 view_dir = normalize(vec3(0.0, 0.0, 1.0));
    vec3 half_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(normal_map, half_dir), 0.0), 32.0 * (1.0 - roughness));
    vec3 specular = spec * light_color * specular_strength * attenuation;

    // Ambient
    vec3 ambient = albedo.rgb * ambient_strength;

    // Final color
    vec3 color = (ambient + diffuse + specular) * albedo.rgb;
    COLOR = vec4(color, albedo.a);
}