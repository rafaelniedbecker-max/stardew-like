# PBR Texture Assets for Stardew-Like

## Overview
Converted 10 PBR materials from Poly Haven / AmbientCG sources for use in Godot 4.
Original files were `.blend.zip` with 2K/4K textures.

## Materials Included

| Material | Maps | Best For |
|----------|------|----------|
| `aerial_grass_rock` | Albedo, Normal, Roughness, Height | Rocky grass terrain |
| `aerial_rocks_02` | Albedo, Normal, Roughness, Height | Rocky outcrops, cliffs |
| `asphalt_02` | Albedo, Normal, Roughness, Height | Roads, paths |
| `beige_wall_001` | Albedo, Normal, Roughness, Height | Building walls |
| `brown_mud_leaves_01` | Albedo, Normal, Roughness, Height | Forest floor, paths |
| `coast_sand_rocks_02` | Albedo, Normal, Roughness, Height | Beach, shoreline |
| `concrete_floor_worn_001` | Albedo, Normal, Roughness, Height | Farm buildings, silos |
| `forrest_ground_01` | Albedo, Normal, Roughness, Height | Woods, mines |
| `grass_ground` | Albedo, Normal, Roughness, Height | **Main farm terrain** |
| `plywood` | Albedo, Normal, Roughness | Interior floors, crates |

## HDRI Skies
- `belfast_farmhouse_2k.exr` - Overcast farm lighting
- `belfast_sunset_puresky_2k.exr` - Golden hour sunset

## Directory Structure
```
assets/textures/pbr_ready/
├── grass_ground/
│   ├── grass_ground_albedo_texture.png
│   ├── grass_ground_normal_texture.png  (copied from EXR)
│   ├── grass_ground_roughness_texture.png
│   ├── grass_ground_heightmap_texture.png
│   └── *.import files
├── ... (9 more materials)
├── hdri/
│   ├── belfast_farmhouse_2k.exr
│   └── belfast_sunset_puresky_2k.exr
└── assets/materials/
    ├── grass_ground.tres
    ├── ... (9 more .tres files)
```

## Usage in Godot 4

### 3D (StandardMaterial3D)
1. Open Godot Editor
2. Create `StandardMaterial3D` in Inspector
3. Load `.tres` files from `assets/materials/` OR:
   - Albedo → `pbr_ready/material/albedo.png`
   - Normal → `pbr_ready/material/normal.png` (set as Normal Map)
   - Roughness → `pbr_ready/material/roughness.png`
   - Heightmap → `pbr_ready/material/heightmap.png` (enable Parallax)

### 2D (Sprite2D with Normal Mapping)
Use the provided shader `shaders/pbr_2d.gdshader`:

```gdscript
# On Sprite2D
material = ShaderMaterial.new()
material.shader = preload("res://shaders/pbr_2d.gdshader")
material.set_shader_parameter("texture_albedo", load("res://assets/textures/pbr_ready/grass_ground/grass_ground_albedo_texture.png"))
material.set_shader_parameter("texture_normal", load("res://assets/textures/pbr_ready/grass_ground/grass_ground_normal_texture.png"))
material.set_shader_parameter("texture_roughness", load("res://assets/textures/pbr_ready/grass_ground/grass_ground_roughness_texture.png"))
```

### Terrain Blending
Use `shaders/terrain_blend.gdshader` for seamless transitions:
- Create a blend map (R=grass, G=dirt, B=sand)
- Assign 3 terrain texture sets
- Shader handles blending + lighting

## For Pixel Art Style (Stardew-Like)

Since this is a 2D pixel art game, you likely want:

1. **Downscale to pixel art resolution** (16x16, 32x32 tiles):
   ```bash
   # Using ImageMagick
   magick grass_ground_albedo_texture.png -resize 256x256 -colors 16 grass_ground_pixel.png
   ```

2. **Extract color palette** for hand-painted tiles

3. **Use normal maps only for dynamic lighting** on static pixel art sprites

4. **Bake lighting** into sprites for performance

## Reimporting in Godot
After copying files, open Godot Editor → it will auto-detect `.import` files.
If not: Project → Reimport All.

## Converting More Textures
Run the conversion script again:
```bash
python scripts/convert_pbr_textures.py
```

It will:
- Scan `assets/textures/pbr/` for new `.blend.zip` or loose textures
- Convert EXR → PNG (or keep EXR for Godot)
- Generate `.import` configs
- Create `.tres` materials

## License
Textures sourced from Poly Haven / AmbientCG (CC0 / Public Domain).
Safe for commercial use. See original sources for details.