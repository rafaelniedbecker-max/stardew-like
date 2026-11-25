#!/usr/bin/env python3
"""
Batch convert PBR textures for Godot 4.x
- Converts EXR to PNG (better compatibility)
- Creates Godot StandardMaterial3D .tres files
- Organizes by material name
- Generates texture import configs
"""

import os
import sys
import shutil
from pathlib import Path
from PIL import Image

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent
PBR_SOURCE = PROJECT_ROOT / "assets" / "textures" / "pbr"
PBR_OUTPUT = PROJECT_ROOT / "assets" / "textures" / "pbr_ready"
MATERIALS_OUTPUT = PROJECT_ROOT / "assets" / "materials"

# Godot 4 StandardMaterial3D texture parameter names
TEXTURE_MAP = {
    "diff": "albedo_texture",
    "nor_gl": "normal_texture",
    "rough": "roughness_texture",
    "disp": "heightmap_texture",
}

# Texture import settings for Godot
IMPORT_SETTINGS = {
    "albedo": {"compress/mode": 0, "flags/srgb": True, "flags/filter": True, "flags/mipmaps": True},
    "normal": {"compress/mode": 0, "flags/srgb": False, "flags/filter": True, "flags/mipmaps": True},
    "roughness": {"compress/mode": 0, "flags/srgb": False, "flags/filter": True, "flags/mipmaps": True},
    "heightmap": {"compress/mode": 0, "flags/srgb": False, "flags/filter": True, "flags/mipmaps": False},
}

def find_texture_sets(source_dir: Path):
    """Group textures by material name."""
    texture_sets = {}

    for tex_dir in [source_dir, source_dir / "textures"]:
        if not tex_dir.exists():
            continue
        for f in tex_dir.iterdir():
            if f.suffix.lower() in ['.jpg', '.jpeg', '.png', '.exr']:
                # Parse filename: material_map_2k.ext where map can be "nor_gl"
                name = f.stem
                # Remove _2k suffix
                if name.endswith('_2k'):
                    name = name[:-3]
                # Known map types (longest first to match nor_gl before nor)
                known_maps = ['nor_gl', 'diff', 'rough', 'disp']
                material = None
                map_type = None

                for known_map in known_maps:
                    suffix = '_' + known_map
                    if name.endswith(suffix):
                        material = name[:-len(suffix)]
                        map_type = known_map
                        break

                if material and map_type:
                    if material not in texture_sets:
                        texture_sets[material] = {}
                    texture_sets[material][map_type] = f

    return texture_sets

def convert_exr_to_png(exr_path: Path, output_path: Path):
    """Convert EXR to PNG using PIL."""
    try:
        img = Image.open(exr_path)
        # EXR might be float32, convert to 16-bit PNG
        if img.mode == 'F':
            img = img.convert('I;16')
        elif img.mode == 'RGB':
            img = img.convert('RGB')
        img.save(output_path, format='PNG', bitdepth=16)
        return True
    except Exception as e:
        print(f"  Failed to convert {exr_path.name}: {e}")
        return False

def copy_or_convert(src: Path, dst: Path):
    """Copy file, converting EXR to PNG if possible."""
    dst.parent.mkdir(parents=True, exist_ok=True)

    if src.suffix.lower() == '.exr':
        png_dst = dst.with_suffix('.png')
        if convert_exr_to_png(src, png_dst):
            return png_dst
        else:
            # Fallback: copy EXR as-is (Godot 4 supports EXR)
            shutil.copy2(src, dst)
            return dst
    else:
        shutil.copy2(src, dst)
        return dst

def generate_godot_import_config(texture_path: Path, texture_type: str):
    """Generate .import file for Godot."""
    import_path = texture_path.with_suffix(texture_path.suffix + '.import')
    settings = IMPORT_SETTINGS.get(texture_type, IMPORT_SETTINGS['albedo'])

    config = f"""[remap]
importer="texture"
type="StreamTexture2D"
path="res://{texture_path.relative_to(PROJECT_ROOT).as_posix()}"
metadata={{
"vram_texture": false
}}

[deps]
source_file="{texture_path.relative_to(PROJECT_ROOT).as_posix()}"
dest_files=[]

[params]
"""
    for key, value in settings.items():
        if isinstance(value, bool):
            config += f"{key}={str(value).lower()}\n"
        else:
            config += f"{key}={value}\n"

    import_path.write_text(config)
    return import_path

def generate_material_tres(material_name: str, textures: dict):
    """Generate Godot StandardMaterial3D .tres file."""
    mat_path = MATERIALS_OUTPUT / f"{material_name}.tres"
    MATERIALS_OUTPUT.mkdir(parents=True, exist_ok=True)

    # Resource header
    tres = f"""[gd_resource type="StandardMaterial3D" load_steps={2 + len(textures)} format=3 uid="{material_name.lower()}_material"]

[sub_resource type="Shader" id="Shader"]
code = """

    # Add texture sub-resources
    sub_resources = []
    texture_params = []

    for i, (map_type, tex_path) in enumerate(textures.items()):
        if map_type not in TEXTURE_MAP:
            continue
        godot_param = TEXTURE_MAP[map_type]
        rel_path = tex_path.relative_to(PROJECT_ROOT).as_posix()
        sub_id = f"Texture2D_{i}"

        sub_resources.append(f"""[sub_resource type="Texture2D" id="{sub_id}"]
resource_path = "res://{rel_path}"
""")
        texture_params.append(f"{godot_param} = SubResource(\"{sub_id}\")")

    # Build the tres content
    tres_content = '[gd_resource type="StandardMaterial3D" load_steps="%d" format=3]\n\n' % (2 + len(textures))

    # Add texture sub-resources
    for i, (map_type, tex_path) in enumerate(textures.items()):
        if map_type not in TEXTURE_MAP:
            continue
        rel_path = tex_path.relative_to(PROJECT_ROOT).as_posix()
        tres_content += f'[sub_resource type="Texture2D" id="Texture2D_{i}"]\n'
        tres_content += f'resource_path = "res://{rel_path}"\n\n'

    # Main material resource
    tres_content += '[resource]\n'
    tres_content += 'shader = ExtResource("res://shaders/pbr_material.gdshader")\n'  # fallback

    for i, (map_type, tex_path) in enumerate(textures.items()):
        if map_type not in TEXTURE_MAP:
            continue
        godot_param = TEXTURE_MAP[map_type]
        tres_content += f'{godot_param} = SubResource("Texture2D_{i}")\n'

    # Standard PBR settings
    tres_content += '\n# PBR Settings\n'
    tres_content += 'transparency = 0\n'
    tres_content += 'cull_mode = 2\n'
    tres_content += 'diffuse_mode = 0\n'
    tres_content += 'specular_mode = 0\n'
    tres_content += 'roughness = 1.0\n'
    tres_content += 'metallic = 0.0\n'
    tres_content += 'specular = 0.5\n'

    mat_path.write_text(tres_content)
    return mat_path

def main():
    print("[SCAN] Scanning PBR textures...")
    texture_sets = find_texture_sets(PBR_SOURCE)

    print(f"Found {len(texture_sets)} material(s):")
    for mat, maps in texture_sets.items():
        print(f"  {mat}: {list(maps.keys())}")

    print("\n[CONVERT] Converting and organizing...")
    PBR_OUTPUT.mkdir(parents=True, exist_ok=True)

    for material, maps in texture_sets.items():
        print(f"\n  Processing {material}...")
        mat_dir = PBR_OUTPUT / material
        mat_dir.mkdir(exist_ok=True)

        converted_textures = {}

        for map_type, src_path in maps.items():
            if map_type not in TEXTURE_MAP:
                print(f"    Skipping unknown map: {map_type}")
                continue

            godot_type = TEXTURE_MAP[map_type]
            dst_name = f"{material}_{godot_type}.png"
            dst_path = mat_dir / dst_name

            result_path = copy_or_convert(src_path, dst_path)
            converted_textures[map_type] = result_path

            # Generate import config
            generate_godot_import_config(result_path, godot_type.replace('_texture', ''))
            print(f"    [OK] {map_type} -> {result_path.name}")

        # Generate material
        if converted_textures:
            generate_material_tres(material, converted_textures)
            print(f"    [OK] Material: {material}.tres")

    # Copy HDRI files
    print("\n[HDRI] Processing HDRI skies...")
    for hdri in PBR_SOURCE.glob("*.exr"):
        dst = PBR_OUTPUT / "hdri" / hdri.name
        result = copy_or_convert(hdri, dst)
        generate_godot_import_config(result, "albedo")
        print(f"  [OK] {hdri.name} -> {result.name}")

    print(f"\n[DONE] Output in: {PBR_OUTPUT}")
    print(f"[DONE] Materials in: {MATERIALS_OUTPUT}")
    print("\n[NEXT] Next steps:")
    print("  1. Open Godot editor to reimport textures")
    print("  2. Assign materials to MeshInstance3D nodes")
    print("  3. For 2D: use albedo as sprite, normal for lighting")

if __name__ == "__main__":
    main()