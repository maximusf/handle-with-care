"""Art List images built straight from the shipped sprites.

Every image is the bare sprite (or a plain grid of sprites) scaled up on a
transparent background: no labels, frames or shadows. Writes to docs/wiki-images.

    python docs/wiki-images/src/wiki_art_sheets.py
"""
import glob
import json
import os

from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
A = os.path.join(ROOT, "assets") + "/"
OUT = os.path.join(ROOT, "docs", "wiki-images") + "/"


def load(rel):
    return Image.open(A + rel).convert("RGBA")


def frames(rel):
    """All frames of a sheet, using its Aseprite JSON when there is one."""
    im = load(rel)
    js = A + os.path.splitext(rel)[0] + ".json"
    if not os.path.exists(js):
        return [im]
    out = []
    for f in json.load(open(js, encoding="utf-8"))["frames"]:
        r = f["frame"]
        out.append(im.crop((r["x"], r["y"], r["x"] + r["w"], r["y"] + r["h"])))
    return out


def pack(items, width, gap=8):
    """Shelf-pack images left to right, bottom aligned per row, on transparency."""
    rows, cur, x = [], [], 0
    for im in items:
        if cur and x + im.width > width:
            rows.append(cur)
            cur, x = [], 0
        cur.append(im)
        x += im.width + gap
    rows.append(cur)
    w = max(sum(i.width for i in r) + gap * (len(r) - 1) for r in rows)
    h = sum(max(i.height for i in r) for r in rows) + gap * (len(rows) - 1)
    c = Image.new("RGBA", (w, h))
    y = 0
    for r in rows:
        rh = max(i.height for i in r)
        x = 0
        for i in r:
            c.alpha_composite(i, (x, y + rh - i.height))
            x += i.width + gap
        y += rh + gap
    return c


def save(im, name, s):
    im.resize((im.width * s, im.height * s), Image.NEAREST).save(OUT + name + ".png")
    print("saved %s %dx%d" % (name, im.width * s, im.height * s))


def row(items, gap=8):
    return pack(items, 10 ** 6, gap)


save(load("tilesets/hotel_tileset.png"), "art_hotel_tileset", 4)
save(load("sprites/vehicles/delivery_truck.png"), "art_delivery_truck", 4)
save(row(frames("sprites/vehicles/dolly.png")), "art_dolly", 4)

I = "sprites/interactables/"
save(row(frames(I + "lever.png")), "art_lever", 6)
save(row(frames(I + "pressure_plate.png")), "art_pressure_plate", 6)
save(row(frames(I + "wall_switch.png")), "art_wall_switch", 6)
save(pack(frames("sprites/fx/power_arrow.png"), 140, 4), "art_power_arrow", 4)

em, rc, bm = frames(I + "laser/laser_emitter.png"), frames(I + "laser/laser_receiver.png"), frames(I + "laser/laser_beam.png")
live = Image.new("RGBA", (128, 16))
live.alpha_composite(em[2], (0, 0))
for i in range(3):
    live.alpha_composite(bm[0], (16 + i * 32, 0))
live.alpha_composite(rc[1], (112, 0))
save(row([live] + frames(I + "laser/laser_impact.png") + [load(I + "laser/laser_warning.png")], 12), "art_laser", 4)

P = "sprites/package/"
save(row([load(P + n + ".png") for n in ["box_b_flaps", "box_c_yeet", "silly_cereal", "silly_pizza"]], 16),
     "art_package_variants", 4)
types = ["small", "long", "mailer", "fragile", "large", "heavy", "bouncy", "cold", "balloon", "explosive", "animal"]
save(pack([load(P + "type_" + n + ".png") for n in types], 480, 12), "art_package_types", 4)

guests = sorted(glob.glob(A + "sprites/guests/guest_*.png"))
save(pack([frames("sprites/guests/" + os.path.basename(g))[0] for g in guests], 360, 4), "art_guests", 4)
save(pack(frames("sprites/guests/guest_a.png"), 200, 4), "art_guest_expressions", 4)

props = [frames("sprites/props/" + os.path.basename(p))[0] for p in sorted(glob.glob(A + "sprites/props/*.png"))]
half = len(props) // 2
save(pack(props[:half], 640), "art_props_1", 3)
save(pack(props[half:], 640), "art_props_2", 3)

ui = ["button", "panel", "panel_alt", "slider_track", "slider_fill", "slider_grabber", "checkbox", "keycap", "mouse"]
save(pack([load("ui/" + n + ".png") for n in ui], 240), "art_ui_kit", 4)
screens = [load("ui/screens/" + os.path.basename(p)) for p in sorted(glob.glob(A + "ui/screens/*.png"))]
save(pack(screens, 300), "art_screen_sprites", 4)
save(load("ui/title_logo.png"), "art_title_logo", 4)
save(load("ui/icon_256.png"), "art_game_icon", 1)

F = "sprites/fx/"
fx = []
for n in ["kick_impact", "cardboard_debris", "dust_puff", "puddle_splash", "reaction_bubble", "camera_flash", "photo_timer"]:
    fx.append(row(frames(F + n + ".png"), 4))
save(pack(fx, 1, 8), "art_fx", 4)
