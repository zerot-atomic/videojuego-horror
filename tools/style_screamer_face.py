"""Style the captured Grapper portrait for the one-shot scare overlay."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

root = Path(__file__).resolve().parents[1]
image = Image.open(root / ".godot" / "screamer_capture_raw.png").convert("RGBA")
glow = Image.new("RGBA", image.size, (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)

# Small, deep-set lights give the otherwise featureless mask a disturbing gaze.
for cx, cy in [(564, 445), (655, 436)]:
    gd.ellipse((cx - 28, cy - 17, cx + 28, cy + 17), fill=(255, 12, 30, 185))
glow = glow.filter(ImageFilter.GaussianBlur(18))
image = Image.alpha_composite(image, glow)
draw = ImageDraw.Draw(image, "RGBA")
for cx, cy, lean in [(564, 445, -2), (655, 436, 3)]:
    draw.ellipse((cx - 23, cy - 11, cx + 23, cy + 11), fill=(16, 0, 5, 255))
    draw.polygon([(cx - 17, cy), (cx - 5, cy - 7 + lean), (cx + 18, cy - 1),
                  (cx + 7, cy + 6), (cx - 10, cy + 5)], fill=(232, 222, 207, 255))
    draw.ellipse((cx + 2, cy - 5, cx + 11, cy + 5), fill=(116, 4, 20, 255))
    draw.ellipse((cx + 5, cy - 3, cx + 8, cy + 3), fill=(255, 240, 217, 255))

# A narrow, torn mouth; off-white teeth flash between the dark folds.
draw.polygon([(546, 478), (580, 470), (621, 474), (670, 466), (689, 478),
              (676, 507), (640, 515), (603, 506), (566, 512)], fill=(13, 0, 3, 245))
draw.polygon([(551, 478), (581, 481), (590, 497), (605, 480), (620, 502),
              (635, 481), (654, 500), (671, 474), (663, 492), (644, 506),
              (624, 488), (607, 505), (588, 489), (568, 499)], fill=(232, 218, 193, 245))
draw.line((548, 476, 679, 466), fill=(50, 0, 8, 240), width=5)
image.convert("RGB").save(root / "art3d" / "thewrapper" / "screamer_face.png", quality=95)
print("Grapper scare portrait styled")
