"""Renders the 1024x1024 app icon. Run: python3 scripts/make_icon.py"""
import math
import sys
from PIL import Image, ImageDraw, ImageFilter

S = 1024
SS = 2  # supersample for smooth edges
W = S * SS
out = sys.argv[1] if len(sys.argv) > 1 else "App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

# Diagonal gradient background: electric blue -> violet
top, bottom = (72, 110, 255), (132, 72, 245)
bg = Image.new("RGB", (W, W))
px = bg.load()
for y in range(W):
    for x in range(0, W):
        t = (x + y) / (2 * W)
        px[x, y] = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))

img = bg.copy()
d = ImageDraw.Draw(img)

def wave_flag(x0, y0, w, h, amp, stripes):
    """Waving flag split into horizontal stripes."""
    n = 80
    def edge(yy, i):
        x = x0 + w * i / n
        return (x, yy + amp * math.sin(i / n * math.pi * 2.0))
    band = h / len(stripes)
    for k, color in enumerate(stripes):
        ya, yb = y0 + k * band, y0 + (k + 1) * band
        pts = [edge(ya, i) for i in range(n + 1)] + [edge(yb, i) for i in range(n, -1, -1)]
        d.polygon([(p[0] * SS, p[1] * SS) for p in pts], fill=color)

# Soft shadow under the flag
shadow = Image.new("L", (W, W), 0)
sd = ImageDraw.Draw(shadow)
sd.rounded_rectangle([300 * SS, 290 * SS, 830 * SS, 640 * SS], radius=40 * SS, fill=120)
shadow = shadow.filter(ImageFilter.GaussianBlur(40 * SS))
img.paste((30, 20, 90), (0, 30 * SS), shadow)

# Pole
d.rounded_rectangle([238 * SS, 205 * SS, 278 * SS, 840 * SS], radius=20 * SS, fill=(255, 255, 255))
d.ellipse([228 * SS, 180 * SS, 288 * SS, 240 * SS], fill=(255, 205, 70))

# Flag: gold / white / coral
wave_flag(270, 250, 540, 360, 34, [(255, 205, 70), (255, 255, 255), (255, 98, 110)])

# Check badge
cx, cy, r = 760, 760, 120
d.ellipse([(cx - r) * SS, (cy - r) * SS, (cx + r) * SS, (cy + r) * SS], fill=(52, 212, 128))
d.line([((cx - 55) * SS, (cy + 2) * SS), ((cx - 12) * SS, (cy + 45) * SS), ((cx + 60) * SS, (cy - 45) * SS)],
       fill=(255, 255, 255), width=34 * SS, joint="curve")

img = img.resize((S, S), Image.LANCZOS).convert("RGB")
img.save(out, "PNG")
print("wrote", out)
