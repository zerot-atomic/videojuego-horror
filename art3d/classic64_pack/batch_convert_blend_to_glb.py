"""
Convierte en lote todos los archivos .blend de una carpeta (y subcarpetas)
a .glb, dejando el archivo exportado junto al .blend original.

CÓMO USARLO
-----------
1. Abre Blender (2.8 o superior).
2. Ve a la pestaña "Scripting" (arriba).
3. Abre este archivo con "Open" o pega su contenido en un nuevo script.
4. Cambia la variable ROOT_DIR de abajo por la ruta de tu carpeta
   "- Classic 64 Asset Pack" (la que sacaste del zip).
5. Ejecuta el script (botón ▶ o Alt+P).
6. Revisa la consola de Blender (Window > Toggle System Console en
   Windows, o la terminal desde la que abriste Blender en Mac/Linux)
   para ver el progreso.

También puedes correrlo sin abrir la interfaz, desde una terminal:
    blender --background --python batch_convert_blend_to_glb.py

Al terminar, cada carpeta tendrá los .blend originales Y sus .glb
correspondientes. Copia esos .glb a tu proyecto de Godot; los .blend
ya no los necesitas ahí.

Si prefieres .fbx en vez de .glb, cambia EXPORT_FORMAT abajo a "FBX".
"""

import bpy
import os
import glob

# --- CONFIGURA ESTO ---
ROOT_DIR = r"C:\Users\CFMH1\Downloads\LaCosechaDelColor_Godot\art3d\classic64_pack\- Classic 64 Asset Pack"
EXPORT_FORMAT = "GLB"  # "GLB" o "FBX"
# -----------------------


def export_current_scene(output_path, fmt):
    if fmt == "GLB":
        bpy.ops.export_scene.gltf(
            filepath=output_path,
            export_format='GLB',
            use_selection=False,
        )
    elif fmt == "FBX":
        bpy.ops.export_scene.fbx(
            filepath=output_path,
            use_selection=False,
        )
    else:
        raise ValueError(f"Formato no soportado: {fmt}")


def main():
    blend_files = glob.glob(os.path.join(ROOT_DIR, "**", "*.blend"), recursive=True)
    print(f"Encontrados {len(blend_files)} archivos .blend")

    ext = ".glb" if EXPORT_FORMAT == "GLB" else ".fbx"
    errores = []

    for i, blend_path in enumerate(blend_files, 1):
        out_path = os.path.splitext(blend_path)[0] + ext
        print(f"[{i}/{len(blend_files)}] {blend_path} -> {out_path}")

        try:
            bpy.ops.wm.open_mainfile(filepath=blend_path)
            export_current_scene(out_path, EXPORT_FORMAT)
        except Exception as e:
            print(f"  ERROR: {e}")
            errores.append((blend_path, str(e)))

    print("\n--- Listo ---")
    print(f"Exportados: {len(blend_files) - len(errores)}")
    if errores:
        print(f"Con errores: {len(errores)}")
        for path, err in errores:
            print(f"  - {path}: {err}")


if __name__ == "__main__":
    main()
