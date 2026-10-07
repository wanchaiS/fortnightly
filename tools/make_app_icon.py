"""Draws Fortnightly's app icon: the fortnight donut on the navy shell, in the app's own colours.

Run from the repo root: python3 tools/make_app_icon.py   (needs Pillow)
Writes Fortnightly/Fortnightly/Assets.xcassets/AppIcon.appiconset/AppIcon.png (1024 x 1024).
"""
from PIL import Image, ImageDraw

SIZE = 1024
SCALE = 4  # drawn large, then scaled down for smooth edges
NAVY = (0x16, 0x20, 0x4A)
TRACK = (0x2A, 0x35, 0x6E)
VIOLET = (0x9D, 0x7B, 0xFF)
TEAL = (0x3B, 0xC9, 0xDB)
VIOLET_ROSTERED = (0x5E, 0x4E, 0xA8)
TICK = (0xFF, 0xFF, 0xFF)

# Worked hours first, then rostered, like the board's donut; the gap before the top is the hours left.
ARCS = [(VIOLET, 150), (TEAL, 110), (VIOLET_ROSTERED, 62)]
GAP_DEGREES = 5

big = SIZE * SCALE
image = Image.new("RGB", (big, big), NAVY)
draw = ImageDraw.Draw(image)
centre = big / 2
radius = 0.31 * big
width = int(0.13 * big)
box = [centre - radius, centre - radius, centre + radius, centre + radius]

draw.arc(box, 0, 360, fill=TRACK, width=width)
angle = -90
for colour, sweep in ARCS:
    draw.arc(box, angle, angle + sweep - GAP_DEGREES, fill=colour, width=width)
    angle += sweep

# The 48-hour tick at the top of the ring.
tick_width = int(0.03 * big)
inner, outer = radius - width - 0.03 * big, radius + 0.03 * big
draw.rounded_rectangle(
    [centre - tick_width / 2, centre - outer, centre + tick_width / 2, centre - inner],
    radius=tick_width / 2,
    fill=TICK,
)

image.resize((SIZE, SIZE), Image.LANCZOS).save("Fortnightly/Fortnightly/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
