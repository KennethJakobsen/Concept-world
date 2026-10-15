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
    # T-061
    ("go_karts", "Track"): "asphalt",
    ("ferris_wheel", "Booth"): "wood",
}

# T-061: tekstur paa eksisterende farvede sub-materialer (farven bevares, tekstur
# tintes). (scene) -> {sub-id: (tekstur, uv-skala)}. Ikke-listede (hud, glas) urørt.
# Eksisterende tekstur-linjer erstattes, saa skalaer/teksturer kan justeres og genkoeres.
_PN = ("panel", 2.0)   # malet metal m. samlinger/nitter (karosser, kabiner, heste, trim)
_CV = ("canvas", 2.0)  # stof (tage, markiser, flag, skilte, saeder)
_RB = ("asphalt", 3.0) # gummi (daek, kofangere)
_WD = ("planks", 1.5)
COLORS = ["red", "cream", "gold", "teal", "pink", "blue", "green", "yellow", "orange", "white", "dark", "black", "grey", "purple", "stone"]


def _all(default, **over):
    d = {}
    for c in COLORS:
        for pre in ("m_", "dm_"):
            d[pre + c] = over.get(pre + c, default)
    return d


TINT = {
    "carousel": _all(_PN, m_red=_CV, dm_red=_CV),
    "ferris_wheel": _all(_PN, dm_red=_CV, dm_yellow=_CV, dm_blue=_WD),
    "go_karts": _all(_PN, m_green=("grass", 0.6), m_white=("canvas", 4.0), m_red=("canvas", 4.0),
                     dm_white=_CV, dm_red=_PN, dm_black=_RB, dm_blue=_WD, dm_yellow=_CV),
    "bumper_cars": _all(_PN, m_red=_CV, m_cream=_CV, m_dark=_CV, dm_black=_RB, dm_red=_CV, dm_blue=_CV),
    "haunted_house": _all(_PN, m_dark=_WD, dm_dark=_WD, m_white=_CV, dm_stone=("cobble", 2.0),
                          dm_black=_PN, m_purple=("brick", 1.5)),
    "swing_ride": _all(_PN, m_teal=_CV, dm_teal=_CV, dm_cream=_PN, dm_yellow=_CV, dm_red=_CV),
}
RIDES = set(TINT)
# Delte materialer, der skiftes til kraftigere varianter paa forlystelser.
RIDE_SWAP = {"mat_metal": "steel"}
OVERRIDE[("bumper_cars", "Floor")] = "tread_plate"


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
    tex_needed = set()
    if scene in RIDES:
        for old_id, mat in RIDE_SWAP.items():
            if f'ExtResource("{old_id}")' in txt:
                txt = txt.replace(f'ExtResource("{old_id}")', f'ExtResource("mat_{mat}")')
                txt = re.sub(r'\[ext_resource type="Material" path="[^"]+" id="%s"\]\n\n?' % old_id, "", txt)
                needed.add(mat)
    for sid, (tex, sc) in TINT.get(scene, {}).items():
        m = re.search(r'(\[sub_resource type="StandardMaterial3D" id="%s"\]\n(?:[^\[\n].*\n)*)' % sid, txt)
        if not m:
            continue
        block = m.group(1)
        base = re.sub(r'(albedo_texture|uv1_scale|uv1_triplanar|texture_filter) = .*\n', "", block)
        add = (f'albedo_texture = ExtResource("tex_{tex}")\nuv1_scale = Vector3({sc}, {sc}, {sc})\n'
               'uv1_triplanar = true\ntexture_filter = 5\n')
        txt = txt.replace(block, base + add, 1)
        tex_needed.add(tex)
    if txt == orig:
        return
    # path_tile: materialerne er nu overrides; behold sub-resources (harmloese).
    header_end = txt.index("\n") + 1
    exts = "".join(ext_line(n) + "\n\n" for n in sorted(needed) if f'id="mat_{n}"' not in txt)
    # fjern ubrugte tekstur-ext_resources
    for n in re.findall(r'id="tex_(\w+)"', txt):
        if f'ExtResource("tex_{n}")' not in txt:
            txt = re.sub(r'\[ext_resource type="Texture2D" path="[^"]+" id="tex_%s"\]\n\n?' % n, "", txt)
    exts += "".join(f'[ext_resource type="Texture2D" path="res://assets/textures/{n}.png" id="tex_{n}"]\n\n'
                    for n in sorted(tex_needed) if f'id="tex_{n}"' not in txt)
    txt = txt[:header_end] + "\n" + exts + txt[header_end:].lstrip("\n")
    txt = re.sub(r"load_steps=\d+ ", "", txt)
    path.write_text(txt)
    print(scene, sorted(needed), sorted(tex_needed))


for p in sorted(PROPS.glob("*.tscn")):
    process(p)
