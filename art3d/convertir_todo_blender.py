import bpy
import subprocess
import os
import tempfile

# ============================================================
# CONVERSION AUTOMATICA A .glb - correr desde Blender (Scripting > Run Script)
# ============================================================

CLASSIC64_DIR = r"C:\Users\CFMH1\OneDrive\Escritorio\LaCosechaDelColor_Godot\art3d\classic64_pack"
HORROR_FBX_DIR = r"C:\Users\CFMH1\OneDrive\Escritorio\LaCosechaDelColor_Godot\art3d\horror_pack\HorrorPackFBX"

BLENDER_EXE = bpy.app.binary_path  # se detecta solo, no hay que escribirlo

# --- sub-script para convertir un .blend abierto a .glb ---
EXPORT_BLEND_SCRIPT = r'''
import bpy, os
blend_path = bpy.data.filepath
out_path = os.path.splitext(blend_path)[0] + ".glb"
bpy.ops.export_scene.gltf(
    filepath=out_path,
    export_format='GLB',
    export_apply=True,
    export_yup=True,
    export_animations=True,
)
print("OK ->", out_path)
'''

# --- sub-script para importar un .fbx y exportarlo a .glb ---
CONVERT_FBX_SCRIPT = r'''
import bpy, sys
argv = sys.argv
argv = argv[argv.index("--") + 1:]
fbx_path, glb_path = argv[0], argv[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=fbx_path)
bpy.ops.export_scene.gltf(
    filepath=glb_path,
    export_format='GLB',
    export_apply=True,
    export_yup=True,
    export_animations=True,
)
print("OK:", fbx_path, "->", glb_path)
'''

tmp_dir = tempfile.mkdtemp(prefix="cosecha_convert_")
export_blend_path = os.path.join(tmp_dir, "export_blend_to_glb.py")
convert_fbx_path = os.path.join(tmp_dir, "convert_fbx_to_glb.py")

with open(export_blend_path, "w", encoding="utf-8") as f:
    f.write(EXPORT_BLEND_SCRIPT)
with open(convert_fbx_path, "w", encoding="utf-8") as f:
    f.write(CONVERT_FBX_SCRIPT)


def find_files(root, ext):
    result = []
    for dirpath, _, filenames in os.walk(root):
        for name in filenames:
            if name.lower().endswith(ext):
                result.append(os.path.join(dirpath, name))
    return result


print("=" * 60)
print("Blender detectado en:", BLENDER_EXE)

if not os.path.isdir(CLASSIC64_DIR):
    print("ERROR: no existe la carpeta:", CLASSIC64_DIR)
elif not os.path.isdir(HORROR_FBX_DIR):
    print("ERROR: no existe la carpeta:", HORROR_FBX_DIR)
else:
    blend_files = find_files(CLASSIC64_DIR, ".blend")
    fbx_files = find_files(HORROR_FBX_DIR, ".fbx")

    print(f"Encontrados {len(blend_files)} .blend en classic64_pack")
    print(f"Encontrados {len(fbx_files)} .fbx en horror_pack")
    print("=" * 60)

    print("\n== Convirtiendo .blend -> .glb ==")
    for i, blend_file in enumerate(blend_files, 1):
        print(f"[{i}/{len(blend_files)}] {blend_file}")
        subprocess.run([
            BLENDER_EXE, "--background", blend_file,
            "--python", export_blend_path,
        ])

    print("\n== Convirtiendo .fbx -> .glb ==")
    for i, fbx_file in enumerate(fbx_files, 1):
        glb_file = os.path.splitext(fbx_file)[0] + ".glb"
        print(f"[{i}/{len(fbx_files)}] {fbx_file} -> {glb_file}")
        subprocess.run([
            BLENDER_EXE, "--background",
            "--python", convert_fbx_path,
            "--", fbx_file, glb_file,
        ])

    print("\nListo. Revisa las carpetas: cada .blend/.fbx ahora tiene su .glb al lado.")
