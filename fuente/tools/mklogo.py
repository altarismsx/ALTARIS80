#!/usr/bin/env python3
"""Genera el logo de arranque (src/logo.inc) y una vista previa PNG.
Logo: 'ALTARIS' rayado al estilo de los 80 y '80' en un recuadro invertido.
Salida: mapa de bits en el formato de la pantalla virtual (columnas de 8
puntos x 128 filas, bit 0 = punto de la izquierda), recortado a W x H."""
import os, sys
from PIL import Image, ImageDraw, ImageFont
here = os.path.dirname(os.path.abspath(__file__))
W, H = 200, 32
img = Image.new('1', (W, H), 0)
d = ImageDraw.Draw(img)
f = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 31)
txt = 'ALTARIS'
bb = d.textbbox((0, 0), txt, font=f)
d.text((1 - bb[0], 1 - bb[1]), txt, font=f, fill=1)
tw = bb[2] - bb[0] + 2
# rayas horizontales: 1 fila apagada de cada 4
for y in range(H):
    if y % 4 == 3:
        for x in range(tw + 1):
            img.putpixel((x, y), 0)
# recuadro "80"
f2 = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 24)
bx0 = tw + 5
bb2 = d.textbbox((0, 0), '80', font=f2)
bw = bb2[2] - bb2[0] + 8
d.rounded_rectangle((bx0, 1, bx0 + bw, H - 2), radius=4, fill=1)
d.text((bx0 + 4 - bb2[0], (H - (bb2[3] - bb2[1])) // 2 - bb2[1]), '80', font=f2, fill=0)
used_w = bx0 + bw + 1
img = img.crop((0, 0, used_w, H))
W = used_w
img.resize((W * 3, H * 3), Image.NEAREST).save(os.path.join(here, '..', 'build', 'logo_preview.png'))
cols = (W + 7) // 8
data = []
for c in range(cols):
    for y in range(H):
        b = 0
        for i in range(8):
            x = c * 8 + i
            if x < W and img.getpixel((x, y)):
                b |= 1 << i
        data.append(b)
out = os.path.join(here, '..', 'src', 'logo.inc')
with open(out, 'w') as fo:
    fo.write('; Generado por tools/mklogo.py - no editar\n')
    fo.write('LOGOC\tEQU\t%d\t\t;columnas de 8 puntos\n' % cols)
    fo.write('LOGOH\tEQU\t%d\t\t;filas\n' % H)
    fo.write('LOGO:\n')
    for i in range(0, len(data), 16):
        fo.write('\tDEFB\t' + ','.join('%03XH' % b for b in data[i:i + 16]) + '\n')
print('logo %dx%d, %d columnas, %d bytes' % (W, H, cols, len(data)))
