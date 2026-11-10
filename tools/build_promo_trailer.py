#!/usr/bin/env python3
"""Build an 84.833-second game trailer with live Godot footage, narration and music."""

from __future__ import annotations

import argparse
import json
import math
import shutil
import struct
import subprocess
import tempfile
from functools import lru_cache
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
WIDTH, HEIGHT, FPS = 1280, 720, 24
TOTAL_FRAMES = 2036  # Duración comprobada de persecucion.ogg a 24 fps: 84.833333 s
CACHE_VERSION = "promo-gameplay-elevenlabs-scream-v10"

GAMEPLAY = [
    ("camino", 0, "UNA DESAPARICIÓN LO TRAE AQUÍ", "EL INSPECTOR SIGUE EL CAMINO A LA FINCA."),
    ("bosque", 0, "EL BOSQUE ALTERA TODO", "SUS SENTIDOS Y RECUERDOS EMPIEZAN A FALLAR."),
    ("casa", 0, "LA CASA ESCONDE LAS PRUEBAS", "EXAMINA FOTOGRAFÍAS, OBJETOS Y NOTAS."),
	("laberinto", 0, "GRAPPER TE ACORRALA", "CORRE. EL LABERINTO NO TIENE UNA SALIDA FÁCIL."),
]

STILLS = [
    ("casa_sala.png", "RECONSTRUYE LA HISTORIA", "CADA HABITACIÓN REVELA OTRA PARTE DEL CASO."),
    ("atico.png", "HAY ALGO SOBRE EL TECHO", "SIGUE LAS PISTAS HASTA EL ÁTICO."),
    ("establo.png", "LOS ANIMALES CAMBIARON", "LA CORRUPCIÓN TAMBIÉN ALCANZÓ EL ESTABLO."),
    ("pozo.png", "EL AGUA LO CAMBIÓ TODO", "NADA VOLVIÓ A SER NORMAL DESPUÉS DE BEBER."),
    ("campo_cultivo.png", "LA TIERRA YA NO ES LA MISMA", "ALGO CRECE BAJO LOS CULTIVOS."),
    ("bosque.png", "EL CAMINO NO PARECE REAL", "LA FINCA QUEDA CADA VEZ MÁS LEJOS."),
    ("camino_entrada.png", "NO HAY NADIE QUE PUEDA AYUDARTE", "LA NIEBLA BORRA EL CAMINO DE REGRESO."),
    ("laberinto.png", "GRAPPER SE ACERCA", "¿ES UNA CRIATURA O UNA MENTE QUE SE QUIEBRA?"),
    ("crater_meteorito.png", "UN COLOR CAYÓ DEL CIELO", "EL ORIGEN DE UN HORROR CÓSMICO."),
]

INTRO_FRAMES = 120
GAMEPLAY_FRAMES = 132
STILL_FRAMES = 137
SCREAM_FRAMES = 36
OUTRO_FRAMES = TOTAL_FRAMES - INTRO_FRAMES - len(GAMEPLAY) * GAMEPLAY_FRAMES - len(STILLS) * STILL_FRAMES - SCREAM_FRAMES


def locate_font(candidates: list[str], size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in candidates:
        path = Path(candidate)
        if path.exists():
            return ImageFont.truetype(str(path), size=size)
    return ImageFont.load_default()


def cover(image: Image.Image, scale: float, pan_x: float, pan_y: float) -> Image.Image:
    image = image.convert("RGB")
    ratio = max(WIDTH / image.width, HEIGHT / image.height) * scale
    nw, nh = math.ceil(image.width * ratio), math.ceil(image.height * ratio)
    image = image.resize((nw, nh), Image.Resampling.LANCZOS)
    extra_x, extra_y = max(0, nw - WIDTH), max(0, nh - HEIGHT)
    left = int(extra_x * pan_x)
    top = int(extra_y * pan_y)
    return image.crop((left, top, left + WIDTH, top + HEIGHT))


@lru_cache(maxsize=1)
def vignette_mask() -> Image.Image:
    small_w, small_h = WIDTH // 4, HEIGHT // 4
    vignette = Image.new("L", (small_w, small_h), 0)
    px = vignette.load()
    cx, cy = small_w / 2, small_h / 2
    max_dist = math.sqrt(cx * cx + cy * cy)
    for y in range(small_h):
        for x in range(small_w):
            d = math.sqrt((x - cx) ** 2 + (y - cy) ** 2) / max_dist
            px[x, y] = int(max(0, min(82, (d ** 1.7) * 82)))
    return vignette.resize((WIDTH, HEIGHT), Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(12))


def atmospheric_grade(image: Image.Image) -> Image.Image:
    image = ImageEnhance.Color(image).enhance(0.78)
    image = ImageEnhance.Contrast(image).enhance(1.05)
    image = ImageEnhance.Brightness(image).enhance(0.94)
    shade = Image.new("RGBA", image.size, (6, 9, 12, 20))
    image = Image.alpha_composite(image.convert("RGBA"), shade)
    dark = Image.new("RGBA", image.size, (0, 0, 0, 0))
    dark.putalpha(vignette_mask())
    return Image.alpha_composite(image, dark)


def overlay_copy(image: Image.Image, title: str, subtitle: str, progress: float, index: int,
                 gameplay: bool = False) -> Image.Image:
    image = atmospheric_grade(image)
    draw = ImageDraw.Draw(image, "RGBA")
    serif = locate_font([r"C:\Windows\Fonts\georgiab.ttf", r"C:\Windows\Fonts\timesbd.ttf"], 38)
    sans = locate_font([r"C:\Windows\Fonts\segoeuib.ttf", r"C:\Windows\Fonts\arial.ttf"], 15)
    small = locate_font([r"C:\Windows\Fonts\segoeui.ttf", r"C:\Windows\Fonts\arial.ttf"], 12)
    # Restrained editorial frame, copper accent and unobtrusive alpha tag.
    # Covers the residual in-game tutorial text cropped from live captures.
    header_height = 34 if gameplay else 94
    draw.rectangle((0, 0, WIDTH, header_height), fill=(4, 6, 9, 245))
    frame_top = max(42, header_height)
    draw.rectangle((44, frame_top, WIDTH - 44, HEIGHT - 42), outline=(220, 194, 143, 115), width=1)
    draw.rectangle((44, HEIGHT - 178, WIDTH - 44, HEIGHT - 42), fill=(4, 6, 9, 175))
    draw.rectangle((44, HEIGHT - 178, 51, HEIGHT - 42), fill=(198, 142, 86, 235))
    draw.text((72, HEIGHT - 151), title, font=serif, fill=(247, 239, 220, 255), stroke_width=1, stroke_fill=(10, 10, 12, 145))
    draw.text((74, HEIGHT - 94), subtitle, font=sans, fill=(211, 202, 184, 240))
    draw.text((72, 58), "LA COSECHA DEL COLOR", font=small, fill=(240, 229, 208, 210))
    tag = "JUGABILIDAD CAPTURADA · ALFA" if gameplay else "ESCENAS DEL JUEGO · ALFA"
    draw.text((WIDTH - 190, 58), tag, font=small, fill=(235, 227, 211, 185))
    draw.line((72, HEIGHT - 62, WIDTH - 72, HEIGHT - 62), fill=(214, 195, 157, 65), width=1)
    bar_end = 72 + int((WIDTH - 144) * max(0.0, min(1.0, progress)))
    draw.line((72, HEIGHT - 62, bar_end, HEIGHT - 62), fill=(201, 144, 83, 240), width=2)
    draw.text((WIDTH - 99, HEIGHT - 92), f"{index:02d}", font=small, fill=(225, 216, 199, 195))
    return image.convert("RGB")


def title_card(kind: str, frame: int, total: int) -> Image.Image:
    t = frame / max(1, total - 1)
    image = Image.new("RGB", (WIDTH, HEIGHT), (3, 5, 7))
    draw = ImageDraw.Draw(image, "RGBA")
    title_font = locate_font([r"C:\Windows\Fonts\georgiab.ttf", r"C:\Windows\Fonts\timesbd.ttf"], 68)
    sub_font = locate_font([r"C:\Windows\Fonts\segoeui.ttf", r"C:\Windows\Fonts\arial.ttf"], 24)
    micro = locate_font([r"C:\Windows\Fonts\segoeui.ttf", r"C:\Windows\Fonts\arial.ttf"], 13)
    # A slow, organic violet bloom gives the card atmosphere without fake gameplay.
    glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    pulse = 0.8 + 0.2 * math.sin(t * math.pi)
    radius = int(245 * pulse)
    gd.ellipse((WIDTH // 2 - radius, HEIGHT // 2 - radius, WIDTH // 2 + radius, HEIGHT // 2 + radius), fill=(86, 46, 107, 35))
    glow = glow.filter(ImageFilter.GaussianBlur(100))
    image = Image.alpha_composite(image.convert("RGBA"), glow)
    draw = ImageDraw.Draw(image, "RGBA")
    draw.rectangle((44, 42, WIDTH - 44, HEIGHT - 42), outline=(220, 194, 143, 90), width=1)
    if kind == "open":
        title = "LA COSECHA\nDEL COLOR"
        sub = "UN INSPECTOR. UNA GRANJA AISLADA. UN COLOR IMPOSIBLE."
        y = 255
    else:
        title = "¿ES REAL\nLO QUE TE PERSIGUE?"
        sub = "TERROR CÓSMICO INSPIRADO EN H. P. LOVECRAFT · EN DESARROLLO"
        y = 265
    box = draw.multiline_textbbox((0, 0), title, font=title_font, align="center", spacing=6, stroke_width=1)
    draw.multiline_text(((WIDTH - (box[2] - box[0])) / 2, y), title, font=title_font, align="center", spacing=6,
                        fill=(247, 239, 220, 255), stroke_width=1, stroke_fill=(20, 15, 21, 100))
    sb = draw.textbbox((0, 0), sub, font=sub_font)
    draw.text(((WIDTH - (sb[2] - sb[0])) / 2, 480), sub, font=sub_font, fill=(209, 191, 170, 235))
    draw.line((WIDTH // 2 - 100, 526, WIDTH // 2 + 100, 526), fill=(201, 144, 83, 210), width=2)
    draw.text((64, HEIGHT - 71), "IMÁGENES CAPTURADAS EN JUEGO · VERSIÓN ALFA", font=micro, fill=(227, 217, 198, 165))
    draw.text((WIDTH - 64, HEIGHT - 71), "LA COSECHA DEL COLOR", font=micro, fill=(227, 217, 198, 165), anchor="ra")
    return image.convert("RGB")


def make_timeline(output_dir: Path) -> tuple[list[Path], int]:
    frames_out: list[Path] = []
    screenshots = ROOT / "docs" / "screenshots"
    live_root = ROOT / ".godot" / "gameplay_clips"
    black = Image.new("RGB", (WIDTH, HEIGHT), (0, 0, 0))
    segment_index = 0

    def emit(frames: int, render_frame) -> None:
        nonlocal segment_index
        fade_len = 10
        for local in range(frames):
            p = local / max(1, frames - 1)
            base = render_frame(local, p).convert("RGB")
            fade = min(1.0, (local + 1) / fade_len, (frames - local) / fade_len)
            base = Image.blend(black, base, fade)
            segment_index += 1
            path = output_dir / f"promo_{segment_index:05d}.jpg"
            base.save(path, "JPEG", quality=87, optimize=False, subsampling=1)
            frames_out.append(path)

    emit(INTRO_FRAMES, lambda i, p: title_card("open", i, INTRO_FRAMES))
    for clip_index, (clip, start, title, subtitle) in enumerate(GAMEPLAY):
        clip_dir = live_root / clip
        clip_frames = [clip_dir / f"frame_{n:04d}.jpg" for n in range(start, start + GAMEPLAY_FRAMES)]
        missing = [p for p in clip_frames if not p.exists()]
        if missing:
            raise FileNotFoundError(f"Falta captura de jugabilidad: {missing[0]}")
        for i, source_path in enumerate(clip_frames):
            source = Image.open(source_path).convert("RGB")
            # Recorta el bloque de instrucciones del borde superior, conserva HUD y encuadre del juego.
            source = source.crop((0, 100, source.width, source.height))
            p = i / max(1, GAMEPLAY_FRAMES - 1)
            zoom = 1.00 + 0.025 * p
            base = cover(source, zoom, 0.5 + 0.08 * p, 0.48)
            base = overlay_copy(base, title, subtitle, p, clip_index + 1, gameplay=True)
            base = base.convert("RGB")
            fade = min(1.0, (i + 1) / 10, (GAMEPLAY_FRAMES - i) / 10)
            base = Image.blend(black, base, fade)
            segment_index += 1
            path = output_dir / f"promo_{segment_index:05d}.jpg"
            base.save(path, "JPEG", quality=87, optimize=False, subsampling=1)
            frames_out.append(path)

    for still_index, (filename, title, subtitle) in enumerate(STILLS):
        source_path = screenshots / filename
        if not source_path.exists():
            raise FileNotFoundError(f"Falta una captura incluida en el tráiler: {source_path}")
        source = Image.open(source_path).convert("RGB")

        def render_still(local: int, p: float, source=source, title=title, subtitle=subtitle,
                         idx=still_index + 1) -> Image.Image:
            zoom = 1.025 + 0.075 * p
            pan_x = 0.30 + 0.35 * ((idx + 1) % 2) + 0.18 * p
            pan_y = 0.26 + 0.30 * (idx % 2) + 0.16 * p
            base = cover(source, zoom, min(1.0, pan_x), min(1.0, pan_y))
            return overlay_copy(base, title, subtitle, p, idx, gameplay=False)

        emit(STILL_FRAMES, render_still)
    screamer_path = ROOT / "art3d" / "thewrapper" / "screamer_face.png"
    if not screamer_path.exists():
        raise FileNotFoundError(f"Falta la captura del Grapper para el susto: {screamer_path}")
    screamer = Image.open(screamer_path).convert("RGB").resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
    for local in range(SCREAM_FRAMES):
        frame = screamer.copy()
        if local % 6 < 2:
            tint = Image.new("RGB", frame.size, (126, 5, 15))
            frame = Image.blend(frame, tint, 0.18 if local % 2 == 0 else 0.34)
        if local % 4 == 0:
            draw = ImageDraw.Draw(frame)
            y = 112 + ((local * 37) % 470)
            draw.rectangle((0, y, WIDTH, y + 8), fill=(210, 12, 24))
        frame.save(output_dir / f"promo_{segment_index + 1:05d}.jpg", "JPEG", quality=90, optimize=False)
        segment_index += 1
        frames_out.append(output_dir / f"promo_{segment_index:05d}.jpg")
    emit(OUTRO_FRAMES, lambda i, p: title_card("close", i, OUTRO_FRAMES))
    if len(frames_out) != TOTAL_FRAMES:
        raise RuntimeError(f"La línea de tiempo debe tener {TOTAL_FRAMES} fotogramas, tiene {len(frames_out)}")
    return frames_out, len(frames_out)


def normalize_mp4_timeline(path: Path, total_frames: int = TOTAL_FRAMES) -> None:
    """Set MP4 presentation durations to the exact 24-fps frame count.

    AAC stores a padded final codec packet. Keep the media samples intact and
    trim their presentation edit to the same final video frame.
    """
    data = bytearray(path.read_bytes())

    def boxes(start: int, end: int):
        pos = start
        while pos + 8 <= end:
            size = struct.unpack_from(">I", data, pos)[0]
            kind = data[pos + 4:pos + 8].decode("latin1")
            header = 8
            if size == 1:
                size = struct.unpack_from(">Q", data, pos + 8)[0]
                header = 16
            elif size == 0:
                size = end - pos
            if size < header or pos + size > end:
                break
            yield kind, pos + header, pos + size
            pos += size

    def child(start: int, end: int, wanted: str):
        return next(((a, b) for name, a, b in boxes(start, end) if name == wanted), None)

    moov = child(0, len(data), "moov")
    if moov is None:
        raise ValueError("MP4 sin átomo moov")
    mvhd = child(*moov, "mvhd")
    if mvhd is None:
        raise ValueError("MP4 sin átomo mvhd")
    version = data[mvhd[0]]
    if version == 1:
        struct.pack_into(">I", data, mvhd[0] + 20, FPS)
        struct.pack_into(">Q", data, mvhd[0] + 24, total_frames)
    else:
        struct.pack_into(">I", data, mvhd[0] + 12, FPS)
        struct.pack_into(">I", data, mvhd[0] + 16, total_frames)

    for kind, trak_start, trak_end in boxes(*moov):
        if kind != "trak":
            continue
        tkhd = child(trak_start, trak_end, "tkhd")
        if tkhd is not None:
            version = data[tkhd[0]]
            if version == 1:
                struct.pack_into(">Q", data, tkhd[0] + 28, total_frames)
            else:
                struct.pack_into(">I", data, tkhd[0] + 20, total_frames)
        edts = child(trak_start, trak_end, "edts")
        elst = child(*edts, "elst") if edts is not None else None
        if elst is None:
            continue
        version = data[elst[0]]
        count = struct.unpack_from(">I", data, elst[0] + 4)[0]
        entry = elst[0] + 8
        duration_size = 8 if version == 1 else 4
        entry_size = 20 if version == 1 else 12
        for _ in range(count):
            struct.pack_into(">Q" if version == 1 else ">I", data, entry, total_frames)
            entry += entry_size
    path.write_bytes(data)


BLENDER_SCRIPT = r'''import bpy, json, sys
from pathlib import Path
cfg_path = Path(sys.argv[sys.argv.index("--") + 1])
cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
scene = bpy.context.scene
scene.render.resolution_x = cfg["width"]
scene.render.resolution_y = cfg["height"]
scene.render.resolution_percentage = 100
scene.render.fps = cfg["fps"]
scene.render.image_settings.media_type = "VIDEO"
scene.render.image_settings.file_format = "FFMPEG"
scene.render.ffmpeg.format = "MPEG4"
scene.render.ffmpeg.codec = "H264"
scene.render.ffmpeg.constant_rate_factor = "HIGH"
scene.render.ffmpeg.audio_codec = "AAC"
scene.render.ffmpeg.audio_bitrate = 192
scene.render.filepath = cfg["output"]
scene.render.image_settings.color_mode = "RGB"
scene.view_settings.view_transform = "Standard"
editor = scene.sequence_editor_create()
strips = editor.strips if hasattr(editor, "strips") else editor.sequences
frames = cfg["frames"]
first = strips.new_image("Juego · montaje promocional", frames[0], channel=1, frame_start=1)
for p in frames[1:]:
    first.elements.append(Path(p).name)
first.frame_final_duration = len(frames)
sound = strips.new_sound("Música de persecución", cfg["soundtrack"], channel=2, frame_start=1)
sound.volume = 0.0
sound.keyframe_insert(data_path="volume", frame=1)
sound.volume = 0.20
sound.keyframe_insert(data_path="volume", frame=36)
sound.volume = 0.24
sound.keyframe_insert(data_path="volume", frame=120)
sound.volume = 0.32
sound.keyframe_insert(data_path="volume", frame=900)
sound.volume = 0.48
sound.keyframe_insert(data_path="volume", frame=1540)
sound.volume = 0.56
sound.keyframe_insert(data_path="volume", frame=len(frames) - 36)
sound.volume = 0.0
sound.keyframe_insert(data_path="volume", frame=len(frames))
voice = strips.new_sound("Narración dramática en español", cfg["voice"], channel=3, frame_start=28)
voice.volume = 0.0
voice.keyframe_insert(data_path="volume", frame=28)
voice.volume = 0.92
voice.keyframe_insert(data_path="volume", frame=56)
voice.volume = 0.92
voice.keyframe_insert(data_path="volume", frame=min(len(frames) - 24, voice.frame_final_end - 20))
voice.volume = 0.0
voice.keyframe_insert(data_path="volume", frame=min(len(frames), voice.frame_final_end))
scream = strips.new_sound("Grito distorsionado del Grapper", cfg["scream"], channel=4,
                          frame_start=cfg["scream_start"])
scream.volume = 0.0
scream.keyframe_insert(data_path="volume", frame=cfg["scream_start"])
scream.volume = 1.0
scream.keyframe_insert(data_path="volume", frame=cfg["scream_start"] + 2)
scream.volume = 0.0
scream.keyframe_insert(data_path="volume", frame=min(len(frames), cfg["scream_start"] + 34))
scene.frame_start = 1
scene.frame_end = len(frames)
scene.render.use_sequencer = True
scene.render.use_file_extension = True
scene.render.image_settings.color_depth = "8"
bpy.ops.wm.save_as_mainfile(filepath=cfg["blend"])
bpy.ops.render.render(animation=True)
'''


def main() -> int:
    parser = argparse.ArgumentParser(description="Crear el tráiler de La Cosecha del Color")
    parser.add_argument("--blender", default=r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe")
    parser.add_argument("--output", default=str(ROOT / "docs" / "Promo_La_Cosecha.mp4"))
    parser.add_argument("--soundtrack", default=str(ROOT / "audio" / "persecucion.ogg"))
    parser.add_argument("--voice", default=str(ROOT / "docs" / "narration" / "trailer_elevenlabs.mp3"))
    parser.add_argument("--keep-frames", action="store_true", help="conservar los JPG intermedios junto al video")
    args = parser.parse_args()
    blender = Path(args.blender)
    soundtrack = Path(args.soundtrack)
    voice = Path(args.voice)
    scream = ROOT / "audio" / "scream_distorted.wav"
    output = Path(args.output).resolve()
    if not blender.exists():
        raise SystemExit(f"No se encontró Blender: {blender}")
    if not soundtrack.exists():
        raise SystemExit(f"No se encontró la música: {soundtrack}")
    if not voice.exists():
        raise SystemExit(f"No se encontró la narración: {voice}")
    if not scream.exists():
        raise SystemExit(f"No se encontró el efecto de grito: {scream}")
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="cosecha_promo_") as temp:
        frame_dir = ROOT / ".godot" / "promo_frames"
        frame_dir.mkdir(exist_ok=True)
        frames = sorted(frame_dir.glob("promo_*.jpg"))
        expected_frames = TOTAL_FRAMES
        version_file = frame_dir / ".version"
        version_matches = version_file.exists() and version_file.read_text(encoding="utf-8") == CACHE_VERSION
        if len(frames) != expected_frames or not version_matches:
            for stale_frame in frame_dir.glob("promo_*.jpg"):
                stale_frame.unlink()
            frames, total = make_timeline(frame_dir)
            version_file.write_text(CACHE_VERSION, encoding="utf-8")
        else:
            total = len(frames)
        blend_path = (ROOT / "docs" / "Promo_La_Cosecha.blend").resolve()
        blender_script = Path(temp) / "encode_trailer.py"
        config = Path(temp) / "trailer_config.json"
        blender_script.write_text(BLENDER_SCRIPT, encoding="utf-8")
        config.write_text(json.dumps({
            "width": WIDTH, "height": HEIGHT, "fps": FPS,
            "output": str(output.with_suffix("")),
            "soundtrack": str(soundtrack.resolve()), "voice": str(voice.resolve()),
            "scream": str(scream.resolve()),
            "scream_start": INTRO_FRAMES + len(GAMEPLAY) * GAMEPLAY_FRAMES + len(STILLS) * STILL_FRAMES + 1,
            "frames": [str(p.resolve()) for p in frames],
            "blend": str(blend_path),
        }, ensure_ascii=False), encoding="utf-8")
        subprocess.run([str(blender), "-b", "--python", str(blender_script), "--", str(config)], check=True)
        # Blender appends the frame range to its movie filename. Promote the new
        # render even when an older trailer already exists at the output path.
        candidates = sorted(output.parent.glob(output.stem + "*.mp4"), key=lambda p: p.stat().st_mtime, reverse=True)
        candidate = next((p for p in candidates if p != output), None)
        if candidate is not None:
            if output.exists():
                output.unlink()
            candidate.replace(output)
        if not output.exists():
            raise SystemExit("Blender terminó, pero no apareció el MP4 esperado.")
        normalize_mp4_timeline(output, total)
        print(f"Tráiler exportado: {output} ({total / FPS:.1f} s, 1280x720, 24 fps)")
        if args.keep_frames:
            keep = output.parent / (output.stem + "_frames")
            shutil.copytree(frame_dir, keep, dirs_exist_ok=True)
            print(f"Fotogramas: {keep}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
