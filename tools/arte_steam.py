#!/usr/bin/env python3
"""Arte da Steam da Ilha Cafuné: logo e capas finais.

Lê as fotos sem interface que o jogo tira (`godot --path . -- --arte-steam`, em build/arte_steam/)
e gera em build/arte_steam/steam/:
  logo.png              1280 x 720, fundo transparente (vai por cima do fundo da página)
  hero.png              3840 x 1240, fundo da página do jogo na biblioteca
  capa_vertical.png     600 x 900, capa da biblioteca (com o logo)
  capa_horizontal.png   920 x 430, capa horizontal (com o logo)
  icone.png             256 x 256

Na Steam, atalhos de fora da loja leem a arte de userdata/<conta>/config/grid/ pelo appid do atalho:
<appid>p.png (vertical), <appid>.png (horizontal), <appid>_hero.png e <appid>_logo.png.

Uso: python3 tools/arte_steam.py
"""
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "build" / "arte_steam"
OUT = SRC / "steam"
FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"

OUTLINE = (59, 31, 92, 255)       # roxo escuro, o mesmo tom das rachaduras e lanternas
SHADOW = (40, 20, 70, 150)
FILL_TOP = (255, 236, 120)
FILL_BOTTOM = (255, 150, 60)
BALLOONS = [(240, 80, 90), (70, 150, 240), (255, 205, 60), (80, 200, 120)]


def text_mask(size, lines, stroke=0):
    """Máscara (L) com as linhas de texto centralizadas; cada linha é (texto, tamanho, y)."""
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    for text, font_size, y in lines:
        font = ImageFont.truetype(FONT, font_size)
        d.text((size[0] / 2, y), text, font=font, fill=255, anchor="ms", stroke_width=stroke, stroke_fill=255)
    return mask


def gradient(size, top, bottom, y0, y1):
    """Degradê vertical de `top` (em y0) a `bottom` (em y1)."""
    g = Image.new("RGBA", size)
    d = ImageDraw.Draw(g)
    for y in range(size[1]):
        t = min(max((y - y0) / max(y1 - y0, 1), 0.0), 1.0)
        d.line([(0, y), (size[0], y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,))
    return g


def balloon(img, cx, cy, r, color, knot_to):
    """Balão com brilho e cordinha até `knot_to`, contornado como o texto."""
    d = ImageDraw.Draw(img)
    rx, ry = r, r * 1.18
    d.line([(cx, cy + ry), knot_to], fill=OUTLINE, width=max(4, r // 9))
    d.ellipse([cx - rx - 9, cy - ry - 9, cx + rx + 9, cy + ry + 9], fill=OUTLINE)
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=color + (255,))
    d.polygon([(cx - r * 0.18, cy + ry + 2), (cx + r * 0.18, cy + ry + 2), (cx, cy + ry - r * 0.2)], fill=color + (255,))
    hl = (int(cx - rx * 0.45), int(cy - ry * 0.55))
    d.ellipse([hl[0] - r * 0.2, hl[1] - r * 0.28, hl[0] + r * 0.2, hl[1] + r * 0.28], fill=(255, 255, 255, 190))


def make_logo():
    w, h = 1280, 900
    lines = [("Ilha", 200, 480), ("Cafuné", 300, 770)]
    canvas = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    # Sombra suave embaixo, contorno roxo grosso, contorno branco fino e o miolo em degradê.
    shadow = text_mask((w, h), lines, stroke=30).filter(ImageFilter.GaussianBlur(8))
    shadow = ImageChops.offset(shadow, 0, 16)
    canvas.paste(Image.new("RGBA", (w, h), SHADOW), (0, 0), shadow)
    canvas.paste(Image.new("RGBA", (w, h), OUTLINE), (0, 0), text_mask((w, h), lines, stroke=26))
    canvas.paste(Image.new("RGBA", (w, h), (255, 255, 255, 255)), (0, 0), text_mask((w, h), lines, stroke=11))
    canvas.paste(gradient((w, h), FILL_TOP, FILL_BOTTOM, 300, 780), (0, 0), text_mask((w, h), lines))
    # Três balões amarrados no "a" do "Ilha", como os dos esqueletos que vão embora.
    font = ImageFont.truetype(FONT, 200)
    right = w / 2 + font.getlength("Ilha") / 2
    knot = (right + 6, 372)
    for (dx, y, r), color in zip([(10, 205, 54), (95, 175, 60), (175, 225, 52)], BALLOONS):
        balloon(canvas, int(right + dx), y, r, color, knot)
    canvas = canvas.rotate(4, resample=Image.BICUBIC, center=(w / 2, h / 2))
    bbox = canvas.getbbox()
    return canvas.crop(bbox)


def fit(img, size):
    """Corta e redimensiona para preencher `size` sem distorcer (centralizado)."""
    sw, sh = img.size
    tw, th = size
    k = max(tw / sw, th / sh)
    img = img.resize((round(sw * k), round(sh * k)), Image.LANCZOS)
    x = (img.width - tw) // 2
    y = (img.height - th) // 2
    return img.crop((x, y, x + tw, y + th))


def place_logo(base, logo, width_frac, center):
    """Cola o logo com `width_frac` da largura da imagem, centrado em `center` (frações)."""
    lw = int(base.width * width_frac)
    lh = int(logo.height * lw / logo.width)
    small = logo.resize((lw, lh), Image.LANCZOS)
    x = int(base.width * center[0] - lw / 2)
    y = int(base.height * center[1] - lh / 2)
    out = base.convert("RGBA")
    out.alpha_composite(small, (x, y))
    return out.convert("RGB")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    logo = make_logo()
    # O logo da Steam fica em 1280 x 720 no máximo, com o fundo transparente em volta.
    framed = Image.new("RGBA", (1280, 720), (0, 0, 0, 0))
    k = min(1240 / logo.width, 680 / logo.height)
    scaled = logo.resize((int(logo.width * k), int(logo.height * k)), Image.LANCZOS)
    framed.alpha_composite(scaled, ((1280 - scaled.width) // 2, (720 - scaled.height) // 2))
    framed.save(OUT / "logo.png")
    fit(Image.open(SRC / "hero.png").convert("RGB"), (3840, 1240)).save(OUT / "hero.png")
    vertical = fit(Image.open(SRC / "capa_vertical.png").convert("RGB"), (600, 900))
    place_logo(vertical, logo, 0.84, (0.5, 0.19)).save(OUT / "capa_vertical.png")
    horizontal = fit(Image.open(SRC / "capa_horizontal.png").convert("RGB"), (920, 430))
    place_logo(horizontal, logo, 0.4, (0.76, 0.3)).save(OUT / "capa_horizontal.png")
    fit(Image.open(SRC / "icone.png").convert("RGB"), (256, 256)).save(OUT / "icone.png")
    for f in sorted(OUT.iterdir()):
        print(f.name, Image.open(f).size)


if __name__ == "__main__":
    main()
