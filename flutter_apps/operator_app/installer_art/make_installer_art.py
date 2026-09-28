# Regenerate the operator installer's wizard artwork from the app icon:
#   python make_installer_art.py      (needs Pillow; uses the Windows Segoe UI fonts)
#
# Input:   ..\windows\runner\resources\app_icon_512.png — icon A: the Gridler brain
#          mark in a white disc on a green tile (2026-09-28); app_icon.ico next to it
#          is the app's own Windows icon (Runner.rc) and the setup exe's icon.
# Outputs (this folder), used by ..\face_snap_operator.iss:
#   wizard_side_WxH.bmp   welcome/finish page side image (WizardImageFile)
#   wizard_small_N.bmp    header image on the other pages (WizardSmallImageFile)
# Every standard DPI scale (100..250%) is produced; Inno picks the best match.
# The server installer's twin lives in server\resources\make_installer_art.py.
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, '..', 'windows', 'runner', 'resources', 'app_icon_512.png')
FONTS = os.path.join(os.environ.get('WINDIR', r'C:\Windows'), 'Fonts')
GREEN, GREEN_DEEP, MUTED = (62, 145, 66), (46, 118, 52), (90, 107, 122)

icon = Image.open(SRC).convert('RGBA')


def side(w, h):
    """White side panel: the icon near the top, a green rule, 'FaceSnap Operator'."""
    s = int(w * 0.68)
    x, y = (w - s) // 2, int(h * 0.10)
    img = Image.new('RGBA', (w, h), (255, 255, 255, 255))
    img.alpha_composite(icon.resize((s, s), Image.LANCZOS), (x, y))
    img = img.convert('RGB')
    d = ImageDraw.Draw(img)
    rule_y = y + s + int(h * 0.05)
    d.rounded_rectangle((x, rule_y, x + s, rule_y + max(2, h // 120)), radius=2, fill=GREEN)
    fs = max(12, int(w * 0.105))
    bold = ImageFont.truetype(os.path.join(FONTS, 'segoeuib.ttf'), fs)
    regular = ImageFont.truetype(os.path.join(FONTS, 'segoeui.ttf'), max(10, int(fs * 0.72)))
    ty = rule_y + int(h * 0.035)
    for text, font, colour in (('FaceSnap', bold, GREEN), ('Operator', bold, GREEN_DEEP),
                               ('by Gridler', regular, MUTED)):
        d.text(((w - d.textlength(text, font=font)) / 2, ty), text, fill=colour, font=font)
        ty += int(font.size * 1.25)
    return img


def small(n):
    """Header image: the icon on white with a margin (the modern wizard puts it
    flush against the right window edge; without a margin it clips)."""
    inner = int(n * 0.80)
    img = Image.new('RGBA', (n, n), (255, 255, 255, 255))
    off = (n - inner) // 2
    img.alpha_composite(icon.resize((inner, inner), Image.LANCZOS), (off, off))
    return img.convert('RGB')


for w, h in ((164, 314), (192, 386), (246, 459), (273, 556), (328, 604), (355, 700), (410, 797)):
    side(w, h).save(os.path.join(HERE, f'wizard_side_{w}x{h}.bmp'))
for n in (55, 64, 83, 92, 110, 119, 138):
    small(n).save(os.path.join(HERE, f'wizard_small_{n}.bmp'))
print('operator wizard images written')
