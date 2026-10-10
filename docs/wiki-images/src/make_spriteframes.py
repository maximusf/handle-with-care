"""Build a Godot SpriteFrames .tres next to every Aseprite sheet in assets/.

Reads each <name>.json (Aseprite json-array export) and writes <name>.tres with
one animation per frame tag. Run from anywhere:

    python docs/wiki-images/src/make_spriteframes.py
"""
import glob
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))

# Tags that play once and hold on the last frame. Everything else with more
# than one frame loops.
ONE_SHOT = {"jump", "kick", "bump", "impact", "powering_down", "tripped", "warming",
            "hit", "burst", "puff", "splash"}


def build(json_path):
    data = json.load(open(json_path, encoding="utf-8"))
    if not isinstance(data, dict) or "frames" not in data:
        return None
    frames = data["frames"]
    if isinstance(frames, dict):
        frames = list(frames.values())
    tags = data.get("meta", {}).get("frameTags", [])
    if not tags:
        tags = [{"name": "default", "from": 0, "to": len(frames) - 1}]

    png = os.path.splitext(json_path)[0] + ".png"
    res = "res://" + os.path.relpath(png, ROOT).replace(os.sep, "/")

    out = ['[gd_resource type="SpriteFrames" load_steps=%d format=3]' % (len(frames) + 2), ""]
    out += ['[ext_resource type="Texture2D" path="%s" id="1"]' % res, ""]
    for i, f in enumerate(frames):
        r = f["frame"]
        out += [
            '[sub_resource type="AtlasTexture" id="f%d"]' % i,
            'atlas = ExtResource("1")',
            "region = Rect2(%d, %d, %d, %d)" % (r["x"], r["y"], r["w"], r["h"]),
            "",
        ]

    anims = []
    for t in sorted(tags, key=lambda t: t["name"]):
        idx = range(t["from"], t["to"] + 1)
        base = min(frames[i].get("duration", 100) for i in idx)
        fr = ",\n".join(
            '{\n"duration": %s,\n"texture": SubResource("f%d")\n}'
            % (round(frames[i].get("duration", 100) / base, 3), i)
            for i in idx
        )
        loop = len(idx) > 1 and t["name"] not in ONE_SHOT
        anims.append(
            '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}'
            % (fr, "true" if loop else "false", t["name"], round(1000.0 / base, 2))
        )
    out += ["[resource]", "animations = [%s]" % ", ".join(anims), ""]

    tres = os.path.splitext(json_path)[0] + ".tres"
    with open(tres, "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(out))
    return tres, len(frames), len(tags)


def main():
    n = 0
    for p in sorted(glob.glob(os.path.join(ROOT, "assets", "**", "*.json"), recursive=True)):
        r = build(p)
        if r:
            n += 1
            print("%s  %d frames, %d animations" % (os.path.relpath(r[0], ROOT).replace(os.sep, "/"), r[1], r[2]))
    print("wrote %d SpriteFrames" % n)


if __name__ == "__main__":
    main()
