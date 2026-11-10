#!/bin/bash
# ============================================================
#  Migra TU proyecto "La Cosecha del Color" de Godot 3 a Godot 4.7.2
#
#  Uso (desde la carpeta donde descomprimiste este zip):
#      bash migrar_a_godot4.sh /ruta/a/tu/proyecto
#
#  Ejemplo:
#      bash migrar_a_godot4.sh ~/Documentos/LaCosechaDelColor_Godot
#
#  Que hace, en orden:
#   1) Hace una COPIA DE RESPALDO completa de tu proyecto (por si algo sale mal).
#   2) Borra las importaciones viejas de Godot 3 (la carpeta .import y los
#      archivos *.import que acompanan a cada modelo/imagen/sonido). Godot 4
#      NO puede usarlas y las vuelve a generar solo.
#   3) Copia encima los archivos ya portados (scripts, escenas, project.godot).
#
#  NO toca tus modelos, texturas ni audio (art3d/ y audio/ quedan igual).
# ============================================================
set -e

AQUI="$(cd "$(dirname "$0")" && pwd)"
DESTINO="$1"

if [ -z "$DESTINO" ]; then
  echo "Falta la ruta de tu proyecto."
  echo "Uso: bash migrar_a_godot4.sh /ruta/a/tu/proyecto"
  exit 1
fi

DESTINO="$(cd "$DESTINO" 2>/dev/null && pwd)" || { echo "No existe esa carpeta."; exit 1; }

if [ ! -f "$DESTINO/project.godot" ]; then
  echo "Esa carpeta no parece un proyecto de Godot (no hay project.godot adentro)."
  exit 1
fi

if grep -q "config_version=5" "$DESTINO/project.godot"; then
  echo "Ese proyecto YA parece ser de Godot 4 (config_version=5). No hago nada."
  exit 1
fi

for f in project.godot default_env.tres autoload scripts3d scenes3d; do
  if [ ! -e "$AQUI/$f" ]; then
    echo "Falta '$f' junto a este script. Ejecutalo desde la carpeta del zip descomprimido."
    exit 1
  fi
done

RESPALDO="${DESTINO}_RESPALDO_godot3"
if [ -e "$RESPALDO" ]; then
  echo "Ya existe un respaldo en: $RESPALDO"
  echo "Muevelo o borralo primero, para no pisar un respaldo anterior."
  exit 1
fi

echo "Proyecto a migrar : $DESTINO"
echo "Respaldo se hara en: $RESPALDO"
echo
read -r -p "Escribe SI para continuar: " R
if [ "$R" != "SI" ]; then
  echo "Cancelado. No se toco nada."
  exit 0
fi

echo "[1/3] Haciendo respaldo (puede tardar, el proyecto pesa ~200 MB)..."
cp -a "$DESTINO" "$RESPALDO"

echo "[2/3] Borrando importaciones viejas de Godot 3..."
rm -rf "$DESTINO/.import" "$DESTINO/.godot"
find "$DESTINO" -name "*.import" -type f -delete

echo "[3/3] Copiando archivos portados a Godot 4..."
cp -f "$AQUI/project.godot" "$DESTINO/project.godot"
cp -f "$AQUI/default_env.tres" "$DESTINO/default_env.tres"
mkdir -p "$DESTINO/autoload" "$DESTINO/scripts3d" "$DESTINO/scenes3d"
cp -f "$AQUI"/autoload/*.gd "$DESTINO/autoload/"
cp -f "$AQUI"/scripts3d/*.gd "$DESTINO/scripts3d/"
cp -f "$AQUI"/scenes3d/*.tscn "$DESTINO/scenes3d/"

echo
echo "LISTO."
echo "Siguiente paso: abre el proyecto con Godot 4.7.2."
echo "La primera vez va a tardar varios minutos reimportando todo; es normal."
echo "Si algo sale muy mal, tu proyecto original esta intacto en:"
echo "   $RESPALDO"
