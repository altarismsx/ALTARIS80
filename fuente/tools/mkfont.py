#!/usr/bin/env python3
"""Genera src/font.inc: fuente de 5x8 (Spleen 5x8, (C) 2018 Frederic Cambus,
licencia BSD de 2 clausulas) mas caracteres graficos propios en 80H-9FH.
Formato de salida: 8 bytes por caracter, fila superior primero,
bit 0 = punto de la izquierda. Al final, FWIDE: 32 bytes con un bit por
caracter que indica que el dibujo usa los 8 puntos de ancho."""
import sys, os
here = os.path.dirname(os.path.abspath(__file__))
src = sys.argv[1] if len(sys.argv) > 1 else '/tmp/MailStation-Example/lib/font/spleen-5x8.hex'
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(here, '..', 'src', 'font.inc')

def rev(b):
    return int('{:08b}'.format(b)[::-1], 2)

font = [[0]*8 for _ in range(256)]
for line in open(src):
    line = line.strip()
    if not line:
        continue
    code, data = line.split(':')
    c = int(code, 16)
    if c > 255:
        continue
    rows = bytes.fromhex(data)
    font[c] = [rev(r) for r in rows]

wide = set()

def pic(code, rows, is_wide=False):
    assert len(rows) == 8, hex(code)
    out = []
    for r in rows:
        r = r.ljust(8, '.')
        v = 0
        for i, ch in enumerate(r[:8]):
            if ch == '#':
                v |= 1 << i
        out.append(v)
    font[code] = out
    if is_wide:
        wide.add(code)

F = '########'
E = '........'
H = '..######'   # media linea desde la columna 2 hacia la derecha
HL = '###.....'  # desde la izquierda hasta la columna 2
V = '..#.....'
pic(0x80, [F]*8, True)
pic(0x81, [F]*4 + [E]*4, True)
pic(0x82, [E]*4 + [F]*4, True)
pic(0x83, ['###.....']*8, True)
pic(0x84, ['...#####']*8, True)
pic(0x85, ['#...#...', '........', '..#...#.', '........']*2, True)
pic(0x86, ['#.#.#.#.', '.#.#.#.#']*4, True)
pic(0x87, ['.###.###', '########', '##.###.#', '########']*2, True)
pic(0x88, [E]*3 + [F] + [E]*4, True)
pic(0x89, [V]*8, True)
pic(0x8A, [E]*3 + [H] + [V]*4, True)
pic(0x8B, [E]*3 + [HL] + [V]*4, True)
pic(0x8C, [V]*3 + [H] + [E]*4, True)
pic(0x8D, [V]*3 + [HL] + [E]*4, True)
pic(0x8E, [V]*3 + [H] + [V]*4, True)
pic(0x8F, [V]*3 + [HL] + [V]*4, True)
pic(0x90, [E]*3 + [F] + [V]*4, True)
pic(0x91, [V]*3 + [F] + [E]*4, True)
pic(0x92, [V]*3 + [F] + [V]*4, True)
pic(0x93, ['.....', '.###.', '#####', '#####', '#####', '.###.', '.....', '.....'])
pic(0x94, ['.....', '##.##', '#####', '#####', '.###.', '..#..', '.....', '.....'])
pic(0x95, ['..#..', '.###.', '#####', '.###.', '..#..', '.....', '.....', '.....'])
pic(0x96, ['..#..', '.###.', '#.#.#', '#####', '#.#.#', '..#..', '.###.', '.....'])
pic(0x97, ['..#..', '.###.', '#####', '#####', '..#..', '.###.', '.....', '.....'])
pic(0x98, ['.###.', '#.#.#', '#####', '.###.', '#####', '..#..', '.#.#.', '##.##'])  # robot
pic(0x99, ['.###.', '#.#.#', '#####', '.###.', '#####', '..#..', '.##..', '.#.#.'])  # robot corriendo
pic(0x9A, ['.....', '..#..', '.###.', '#####', '#.#.#', '.###.', '.....', '.....'])  # nave
pic(0x9B, ['#...#', '.#.#.', '#####', '#.#.#', '.###.', '.#.#.', '#...#', '.....'])  # pajaro
pic(0x9C, ['.....', '.....', '.##..', '#####', '#####', '.#.#.', '.....', '.....'])  # auto
pic(0x9D, [E] + [F]*6 + [E], True)                                                       # ladrillo
pic(0x9E, [E]*2 + [F]*4 + [E]*2, True)                                                   # paleta
pic(0x9F, ['..#..', '..#..', '#####', '.###.', '.#.#.', '#...#', '.....', '.....'])  # estrella

# --- Letras del castellano (la version de Spleen usada no las trae) ---
def base(ch):
    rows = []
    for b in font[ord(ch)]:
        rows.append(''.join('#' if b & (1 << i) else '.' for i in range(8)))
    return rows

def accent_low(ch, a0, a1):
    r = base(ch)
    r[0] = a0
    r[1] = a1
    return r

AC0, AC1 = '...#.', '..#..'          # tilde aguda en dos filas
GR0, GR1 = '.#...', '..#..'          # grave
for ch, code in (('a', 0xE1), ('e', 0xE9), ('o', 0xF3), ('u', 0xFA)):
    pic(code, accent_low(ch, AC0, AC1))
for ch, code in (('a', 0xE0), ('e', 0xE8), ('o', 0xF2), ('u', 0xF9)):
    pic(code, accent_low(ch, GR0, GR1))
pic(0xED, ['...#.', '..#..', '.....', '..#..', '..#..', '..#..', '..#..', '.....'])   # i aguda
pic(0xEC, ['.#...', '..#..', '.....', '..#..', '..#..', '..#..', '..#..', '.....'])   # i grave
pic(0xF1, accent_low('n', '.#.#.', '#.#..'))                                          # enie
pic(0xFC, accent_low('u', '.....', '#..#.'))                                          # u dieresis
pic(0xE7, ['.....', '.....', '.###.', '#....', '#....', '#....', '.###.', '..#..'])   # c cedilla
# mayusculas: la marca en la fila 0
def accent_up(ch, a0):
    r = base(ch)
    r[0] = a0
    return r
for ch, code in (('A', 0xC1), ('E', 0xC9), ('I', 0xCD), ('O', 0xD3), ('U', 0xDA)):
    pic(code, accent_up(ch, '...#.'))
for ch, code in (('A', 0xC0), ('E', 0xC8), ('I', 0xCC), ('O', 0xD2), ('U', 0xD9)):
    pic(code, accent_up(ch, '.#...'))
pic(0xD1, accent_up('N', '.####'))                                                    # ENIE
pic(0xDC, ['#..#.', '.....', '#..#.', '#..#.', '#..#.', '#..#.', '.##..', '.....'])   # U dieresis
pic(0xC7, ['.....', '.###.', '#....', '#....', '#....', '.###.', '..#..', '.#...'])   # C cedilla
pic(0xBF, ['..#..', '.....', '..#..', '.#...', '#....', '#..#.', '.##..', '.....'])   # abre pregunta
pic(0xA1, ['..#..', '.....', '..#..', '..#..', '..#..', '..#..', '..#..', '.....'])   # abre exclamacion
pic(0xBA, ['.##..', '#..#.', '.##..', '.....', '####.', '.....', '.....', '.....'])   # ordinal o
pic(0xAA, ['.##..', '..#..', '.###.', '.....', '####.', '.....', '.....', '.....'])   # ordinal a
pic(0xB0, ['.##..', '#..#.', '.##..', '.....', '.....', '.....', '.....', '.....'])   # grado
pic(0xAB, ['.....', '.....', '..#.#', '.#.#.', '#.#..', '.#.#.', '..#.#', '.....'])   # comillas
pic(0xBB, ['.....', '.....', '#.#..', '.#.#.', '..#.#', '.#.#.', '#.#..', '.....'])
pic(0xB7, ['.....', '.....', '.....', '..#..', '.....', '.....', '.....', '.....'])   # punto medio
pic(0xB1, ['.....', '..#..', '.###.', '..#..', '.....', '.###.', '.....', '.....'])   # mas/menos
pic(0xD7, ['.....', '.....', '#...#', '.#.#.', '..#..', '.#.#.', '#...#', '.....'])   # por
pic(0xF7, ['.....', '..#..', '.....', '#####', '.....', '..#..', '.....', '.....'])   # dividido
pic(0xA9, ['.###.', '#...#', '#.#.#', '#.#.#', '#...#', '.###.', '.....', '.....'])   # copyright (5 de ancho)

lines = ['; Generado por tools/mkfont.py - no editar',
         '; Spleen 5x8 (C) 2018 Frederic Cambus, licencia BSD de 2 clausulas.',
         '; Caracteres 80H-9FH: (C) 2026 Altaris Software.']
for c in range(256):
    lines.append('\tDEFB\t' + ','.join('%03XH' % b for b in font[c]) + '\t;%02XH' % c)
fw = [0]*32
for c in wide:
    fw[c >> 3] |= 1 << (c & 7)
lines.append('FWIDE:')
for i in range(0, 32, 8):
    lines.append('\tDEFB\t' + ','.join('%03XH' % b for b in fw[i:i+8]))
open(out, 'w').write('\n'.join(lines) + '\n')
print('font.inc: %d caracteres anchos' % len(wide))
try:
    from PIL import Image
    img = Image.new('L', (16 * 7, 16 * 10), 255)
    for c in range(256):
        x0, y0 = (c % 16) * 7, (c // 16) * 10
        for y in range(8):
            for x in range(8 if c in wide else 5):
                if font[c][y] & (1 << x):
                    img.putpixel((x0 + x, y0 + y), 0)
    img.resize((img.width * 4, img.height * 4), Image.NEAREST).save(
        os.path.join(here, '..', 'build', 'font_preview.png'))
except ImportError:
    pass
