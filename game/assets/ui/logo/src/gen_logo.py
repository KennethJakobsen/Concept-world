#!/usr/bin/env python3
"""Genererer Concept-world-logoet (T-143). Egne bogstavformer (monoline-paths), ingen fonte.
Kør: python3 gen_logo.py  (fra denne mappe) -> skriver ../logo_*.svg
"""
import math, os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
WOOD_D, WOOD_M, WOOD_L = "#5A3A22", "#7A4E2D", "#9C6A3F"
BRASS, BRASS_L, INK, CREAM, RED = "#D9A441", "#F2C96B", "#3B2A1E", "#FFF4DC", "#C8452F"
PAPER = "#F6EBD3"
CATS = ["#D9534F", "#E8A33D", "#5BA05B", "#3F7CBF", "#8E5BB5", "#2F8C8C", "#D9534F", "#E8A33D"]

# Bogstaver i en 100 høj boks: (bredde, centerlinje-path)
GLYPHS = {
    "C": (78, "M74 20 A40 50 0 1 0 74 80"),
    "O": (84, "M42 0 A38 50 0 1 1 42 100 A38 50 0 1 1 42 0 Z"),
    "N": (76, "M6 100 L6 0 L70 100 L70 0"),
    "E": (64, "M62 0 L6 0 L6 100 L62 100 M6 50 L52 50"),
    "P": (70, "M6 100 L6 0 L40 0 A28 27 0 0 1 40 54 L6 54"),
    "T": (72, "M0 0 L72 0 M36 0 L36 100"),
    "W": (96, "M0 0 L22 100 L48 28 L74 100 L96 0"),
    "R": (72, "M6 100 L6 0 L40 0 A28 27 0 0 1 40 54 L6 54 M36 54 L68 100"),
    "L": (60, "M6 0 L6 100 L58 100"),
    "D": (76, "M6 0 L6 100 L30 100 A40 50 0 0 0 30 0 Z"),
}

def word(text, cx, top, h, sw, gap, fill, outline, ow):
    s = h / 100.0
    total = sum(GLYPHS[c][0] for c in text) * s + gap * (len(text) - 1)
    x = cx - total / 2
    parts = []
    for c in text:
        w, d = GLYPHS[c]
        parts.append(f'<path transform="translate({x:.1f},{top}) scale({s:.4f})" d="{d}" stroke-width="@W@"/>')
        x += w * s + gap
    body = "".join(parts)
    common = 'fill="none" stroke-linecap="round" stroke-linejoin="round"'
    return (f'<g {common} stroke="{outline}">' + body.replace("@W@", f"{(sw+ow)/s:.2f}") + '</g>'
            f'<g {common} stroke="{fill}">' + body.replace("@W@", f"{sw/s:.2f}") + '</g>')

def wheel(cx, cy, r, n=8, bulbs=True, detail=True):
    o = [f'<circle cx="{cx}" cy="{cy}" r="{r+10}" fill="{BRASS}"/>',
         f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{PAPER}"/>']
    if detail:
        o.append(f'<circle cx="{cx}" cy="{cy}" r="{r*0.78:.1f}" fill="none" stroke="{BRASS}" stroke-width="{r*0.05:.1f}"/>')
        o.append(f'<circle cx="{cx}" cy="{cy}" r="{r*0.4:.1f}" fill="none" stroke="{BRASS}" stroke-width="{r*0.03:.1f}"/>')
        for i in range(n):
            a = math.pi * 2 * i / n
            o.append(f'<line x1="{cx}" y1="{cy}" x2="{cx+math.cos(a)*r*0.78:.1f}" y2="{cy+math.sin(a)*r*0.78:.1f}" stroke="{BRASS}" stroke-width="{r*0.035:.1f}"/>')
        for i in range(n):
            a = math.pi * 2 * (i + 0.5) / n
            gx, gy = cx + math.cos(a) * r * 0.78, cy + math.sin(a) * r * 0.78
            g = r * 0.12
            o.append(f'<rect x="{gx-g/2:.1f}" y="{gy-g*0.2:.1f}" width="{g:.1f}" height="{g:.1f}" rx="{g*0.25:.1f}" fill="{CATS[i%len(CATS)]}" stroke="{INK}" stroke-width="{r*0.012:.1f}"/>')
        o.append(f'<circle cx="{cx}" cy="{cy}" r="{r*0.08:.1f}" fill="{BRASS_L}" stroke="{INK}" stroke-width="{r*0.015:.1f}"/>')
    if bulbs:
        for i in range(24):
            a = math.pi * 2 * i / 24
            o.append(f'<circle cx="{cx+math.cos(a)*(r+5):.1f}" cy="{cy+math.sin(a)*(r+5):.1f}" r="{max(2.5, r*0.035):.1f}" fill="#FFF8E6"/>')
    return "".join(o)

DEFS = (f'<defs><linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{WOOD_L}"/>'
        f'<stop offset="1" stop-color="{WOOD_D}"/></linearGradient>'
        f'<linearGradient id="brass" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{BRASS_L}"/>'
        f'<stop offset="1" stop-color="#B07E28"/></linearGradient></defs>')

def svg(w, h, body):
    return f'<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{DEFS}{body}</svg>\n'

def full():
    cx, cy, R = 512, 172, 150   # kuppel (hjulets ramme)
    yb = 196                    # skiltets overkant
    dx = math.sqrt(R * R - (cy - yb) ** 2)
    def outline(inset):
        r = R - inset; d = math.sqrt(r * r - (cy - yb - inset) ** 2) if r > abs(cy - yb - inset) else 0
        x0, x1, y0, y1 = 40 + inset, 984 - inset, yb + inset, 412 - inset
        k = 18
        return (f"M{x0+k} {y0} L{cx-d:.1f} {y0} A{r} {r} 0 1 1 {cx+d:.1f} {y0} L{x1-k} {y0} Q{x1} {y0} {x1} {y0+k} "
                f"L{x1} {y1-k} Q{x1} {y1} {x1-k} {y1} L{x0+k} {y1} Q{x0} {y1} {x0} {y1-k} L{x0} {y0+k} Q{x0} {y0} {x0+k} {y0} Z")
    b = []
    b.append(f'<path d="{outline(0)}" transform="translate(0,10)" fill="#000" opacity="0.35"/>')
    b.append(f'<path d="{outline(0)}" fill="url(#brass)"/>')
    b.append(f'<path d="{outline(12)}" fill="url(#wood)" stroke="#3F2816" stroke-width="3"/>')
    b.append(wheel(cx, cy, R - 34, bulbs=False))
    # skiltkroppen lægges hen over hjulets nederste halvdel -> hjulet "stiger op" af skiltet
    b.append(f'<rect x="52" y="{yb+12}" width="920" height="{412-12-yb-12}" fill="url(#wood)"/>')
    b.append(f'<line x1="52" y1="{yb+12}" x2="972" y2="{yb+12}" stroke="#3F2816" stroke-width="3"/>')
    # rødt bånd integreret som skiltets nederste felt
    b.append(f'<rect x="52" y="336" width="920" height="64" fill="{RED}"/>')
    b.append(f'<line x1="52" y1="336" x2="972" y2="336" stroke="{BRASS}" stroke-width="5"/>')
    b.append(word("CONCEPT", 512, 232, 86, 19, 20, CREAM, "#2A1A0E", 10))
    b.append(word("WORLD", 512, 350, 36, 9, 26, CREAM, "#7A2416", 5))
    # pærer langs kanten
    for i in range(15):
        x = 70 + i * (884 / 14)
        b.append(f'<circle cx="{x:.1f}" cy="{yb+6}" r="5" fill="#FFF8E6"/>' if abs(x - cx) > dx + 8 else "")
        b.append(f'<circle cx="{x:.1f}" cy="406" r="5" fill="#FFF8E6"/>')
    for i in range(11):
        a = math.pi + math.pi * (i + 0.5) / 11
        b.append(f'<circle cx="{cx+math.cos(a)*(R-6):.1f}" cy="{cy+math.sin(a)*(R-6):.1f}" r="5" fill="#FFF8E6"/>')
    return svg(1024, 440, "".join(b))

def symbol(small=False):
    c, r = 256, 236
    b = [f'<circle cx="{c}" cy="{c+8}" r="{r}" fill="#000" opacity="0.35"/>',
         f'<circle cx="{c}" cy="{c}" r="{r}" fill="url(#brass)"/>',
         f'<circle cx="{c}" cy="{c}" r="{r-16}" fill="url(#wood)" stroke="#3F2816" stroke-width="3"/>',
         '<clipPath id="in"><circle cx="256" cy="256" r="217"/></clipPath>',
         wheel(c, 214, 150 if not small else 160, bulbs=not small, detail=not small),
         f'<g clip-path="url(#in)"><rect x="0" y="318" width="512" height="200" fill="url(#wood)"/>'
         f'<line x1="0" y1="318" x2="512" y2="318" stroke="#3F2816" stroke-width="4"/>'
         f'<rect x="0" y="410" width="512" height="120" fill="{RED}"/>'
         f'<line x1="0" y1="410" x2="512" y2="410" stroke="{BRASS}" stroke-width="6"/></g>']
    if small:
        b.append(f'<circle cx="256" cy="214" r="50" fill="{BRASS}"/>')
        b.append(word("CW", 256, 332, 66, 30, 14, CREAM, "#2A1A0E", 12))
    else:
        b.append(word("CW", 256, 336, 60, 20, 16, CREAM, "#2A1A0E", 10))
    return svg(512, 512, "".join(b))

for name, data in [("logo_full.svg", full()), ("logo_symbol.svg", symbol()), ("logo_symbol_small.svg", symbol(True))]:
    open(os.path.join(OUT, name), "w").write(data)
