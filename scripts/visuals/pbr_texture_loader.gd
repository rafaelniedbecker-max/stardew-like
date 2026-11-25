@tool
extends Node
class_name PBRTextureLoader

## Helper to load PBR texture sets for 2D/3D use
## Usage: PBRTextureLoader.load_set("grass_ground")
static func load_set(material_name: String, base_path: String = "res://assets/textures/pbr_ready/") -> Dictionary:
    var mat_dir = base_path + material_name + "/"
    var result = {}

    var maps = {
        "albedo": "_albedo_texture.png",
        "normal": "_normal_texture.png",
        "roughness": "_roughness_texture.png",
        "heightmap": "_heightmap_texture.png",
    }

    for key in maps:
        var path = mat_dir + material_name + maps[key]
        if ResourceLoader.exists(path):
            result[key] = load(path)
        else:
            push_warning("PBR texture not found: " + path)

    return result

static func apply_to_shader_material(material: ShaderMaterial, texture_set: Dictionary):
    if texture_set.has("albedo"):
        material.set_shader_parameter("texture_albedo", texture_set["albedo"])
    if texture_set.has("normal"):
        material.set_shader_parameter("texture_normal", texture_set["normal"])
    if texture_set.has("roughness"):
        material.set_shader_parameter("texture_roughness", texture_set["roughness"])

static func create_terrain_shader(grass_set: Dictionary, dirt_set: Dictionary, sand_set: Dictionary, blend_map: Texture2D) -> ShaderMaterial:
    var shader = ShaderMaterial.new()
    shader.shader = preload("res://shaders/terrain_blend.gdshader")

    # Grass layer
    shader.set_shader_parameter("texture_grass_albedo", grass_set["albedo"])
    shader.set_shader_parameter("texture_grass_normal", grass_set["normal"])
    shader.set_shader_parameter("texture_grass_roughness", grass_set["roughness"])

    # Dirt layer
    shader.set_shader_parameter("texture_dirt_albedo", dirt_set["albedo"])
    shader.set_shader_parameter("texture_dirt_normal", dirt_set["normal"])
    shader.set_shader_parameter("texture_dirt_roughness", dirt_set["roughness"])

    # Sand layer
    shader.set_shader_parameter("texture_sand_albedo", sand_set["albedo"])
    shader.set_shader_parameter("texture_sand_normal", sand_set["normal"])
    shader.set_shader_parameter("texture_sand_roughness", sand_set["roughness"])

    # Blend map
    shader.set_shader_parameter("blend_map", blend_map)

    return shader

## Predefined terrain combinations for Stardew map
static func get_farm_terrains() -> Array[Dictionary]:
    return [
        load_set("grass_ground"),      # Main grass
        load_set("brown_mud_leaves_01"), # Dirt paths
        load_set("coast_sand_rocks_02"), # Sand/beach
    ]

static func get_forest_terrains() -> Array[Dictionary]:
    return [
        load_set("forrest_ground_01"),   # Forest floor
        load_set("brown_mud_leaves_01"), # Mud
        load_set("grass_ground"),         # Clearings
    ]

static func get_mine_terrains() -> Array[Dictionary]:
    return [
        load_set("aerial_rocks_02"),     # Rock walls
        load_set("concrete_floor_worn_001"), # Mine floor
        load_set("asphalt_02"),           # Cart tracks
    ]