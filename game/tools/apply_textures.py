#!/usr/bin/env python3
"""T-059: Engangs-/genkoerbart vaerktoej, der kobler props til de delte
teksturerede materialer i res://assets/materials/. Idempotent."""
import re, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROPS = ROOT / "scenes/props"
PERSONS = {"tree_blossom", "tree_pine", "tree_round", "flowers", "guest", "cleaner", "mechanic", "entertainer", "thought_bubble", "litter"}

# Materiale-sub-resource-id -> delt materiale
SWAP = {
    "m_wood": "wood", "dm_wood": "wood",
    "m_brown": "wood_dark", "dm_brown": "wood_dark",
    "m_grey": "metal", "dm_grey": "metal",
}
# (scene, node) -> material_override
OVERRIDE = {
    ("haunted_house", "Roof0"): "roof_shingles_dark",
    ("haunted_house", "Roof2"): "roof_shingles_dark",
    ("haunted_house", "PorchRoof"): "roof_shingles_dark",
    ("haunted_house", "Walls"): "brick_purple",
    ("haunted_house", "Tower"): "brick_purple",
    ("toilet", "Roof"): "roof_tiles",
    ("toilet", "Hut"): "plaster_teal",
    ("go_karts", "HutRoof"): "roof_tiles",
    ("entrance", "BoothRoof"): "roof_tiles",
    ("path_tile", "Tile"): "path_stone",
    ("path_tile", "Inlay"): "path_inlay",
}


def ext_line(name):
    return f'[ext_resource type="Material" path="res://assets/materials/{name}.tres" id="mat_{name}"]'


def process(path):
    scene = path.stem
    txt = path.read_text()
    orig = txt
    needed = set()
    if scene not in PERSONS:
        for sid, mat in SWAP.items():
            pat = f'SubResource("{sid}")'
            if pat in txt:
                txt = txt.replace(pat, f'ExtResource("mat_{mat}")')
                needed.add(mat)
                # fjern den nu ubrugte sub-resource
                txt = re.sub(r'\[sub_resource type="StandardMaterial3D" id="%s"\]\n(?:[^\[\n].*\n)*\n?' % sid, "", txt)
    for (sc, node), mat in OVERRIDE.items():
        if sc != scene:
            continue
        m = re.search(r'(\[node name="%s" type="MeshInstance3D"[^\]]*\]\n(?:[^\[\n].*\n)*)' % node, txt)
        if not m or "material_override" in m.group(1):
            continue
        block = m.group(1)
        txt = txt.replace(block, block + f'material_override = ExtResource("mat_{mat}")\n', 1)
        needed.add(mat)
    if txt == orig:
        return
    # path_tile: materialerne er nu overrides; behold sub-resources (harmloese).
    header_end = txt.index("\n") + 1
    exts = "".join(ext_line(n) + "\n\n" for n in sorted(needed) if f'id="mat_{n}"' not in txt)
    txt = txt[:header_end] + "\n" + exts + txt[header_end:].lstrip("\n")
    txt = re.sub(r"load_steps=\d+ ", "", txt)
    path.write_text(txt)
    print(scene, sorted(needed))


for p in sorted(PROPS.glob("*.tscn")):
    process(p)
