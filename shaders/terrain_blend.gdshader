shader_type canvas_item;
// Terrain Blend Shader - blends between multiple PBR textures based on vertex color or noise
// For Stardew-like: blend grass, dirt, sand textures seamlessly

uniform sampler2D texture_grass_albedo : source_color;
uniform sampler2D texture_grass_normal : hint_normal;
uniform sampler2D texture_grass_roughness : hint_default_white;

uniform sampler2D texture_dirt_albedo : source_color;
uniform sampler2D texture_dirt_normal : hint_normal;
uniform sampler2D texture_dirt_roughness : hint_default_white;

uniform sampler2D texture_sand_albedo : source_color;
uniform sampler2D texture_sand_normal : hint_normal;
uniform sampler2D texture_sand_roughness : hint_default_white;

uniform sampler2D blend_map : hint_default_white; // R=grass, G=dirt, B=sand

uniform vec3 light_position = vec3(0.0, 0.0, 100.0);
uniform vec3 light_color = vec3(1.0, 0.95, 0.9);
uniform float light_intensity = 1.5;
uniform float ambient_strength = 0.4;

vec3 sample_layer(sampler2D albedo, sampler2D normal, sampler2D rough, vec2 uv, vec3 light_dir, vec3 view_dir) {
    vec4 alb = texture(albedo, uv);
    vec3 nrm = texture(normal, uv).rgb * 2.0 - 1.0;
    nrm = normalize(nrm);
    float rgh = texture(rough, uv).r;

    float diff = max(dot(nrm, light_dir), 0.0);
    vec3 half_dir = normalize(light_dir + view_dir);
    float spec = pow(max(dot(nrm, half_dir), 0.0), 16.0 * (1.0 - rgh));

    vec3 diffuse = diff * light_color;
    vec3 specular = spec * light_color * 0.3;
    vec3 ambient = alb.rgb * ambient_strength;

    return (ambient + diffuse + specular) * alb.rgb;
}

void fragment() {
    vec2 uv = UV * 8.0; // Tile textures 8x
    vec3 blend = texture(blend_map, UV).rgb;
    blend = normalize(blend + 0.001); // Avoid division by zero

    vec3 frag_pos = vec3(UV * VIEWPORT_SIZE, 0.0);
    vec3 light_dir = normalize(light_position - frag_pos);
    vec3 view_dir = normalize(vec3(0.0, 0.0, 1.0));

    vec3 grass = sample_layer(texture_grass_albedo, texture_grass_normal, texture_grass_roughness, uv, light_dir, view_dir);
    vec3 dirt = sample_layer(texture_dirt_albedo, texture_dirt_normal, texture_dirt_roughness, uv, light_dir, view_dir);
    vec3 sand = sample_layer(texture_sand_albedo, texture_sand_normal, texture_sand_roughness, uv, light_dir, view_dir);

    vec3 color = grass * blend.r + dirt * blend.g + sand * blend.b;
    COLOR = vec4(color, 1.0);
}