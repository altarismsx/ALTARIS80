#!/usr/bin/env python3
"""Arma el disco de aplicaciones (build/romdisk.bin) a partir de la carpeta disk/.

  *.bas  programas en texto (UTF-8): se tokenizan; el nombre es el del
         archivo sin la extension, en mayusculas (MENU.bas -> MENU)
  otros  se copian tal cual (los .txt se pasan a Latin-1 con CR al final
         de cada linea, para leerlos con *VER); conservan el nombre

Formato (en la pagina 8 de la flash de programa, desde el byte 0):
  0-7    'ALTROM' 0 0
  8-9    cantidad de archivos
  10-31  libre
  32...  entradas de 32 bytes ordenadas por nombre:
         0-15 nombre, 16-17 FFFF, 18-21 largo, 22-23 carga, 24-25 ejecucion,
         26-28 posicion en la flash, 29 0, 30 atributos (1 = protegido), 31 FF
  Los datos empiezan en multiplos de 256 bytes.
"""
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, here)
from bbcbasic import tokenize, BasicError

ROOT = os.path.join(here, '..')
BASE = 8 * 0x4000           # pagina 8 de la flash de programa
LIMIT = 0x100000 - BASE      # hasta el final de la flash


def preprocess(text, fn=''):
    """Numera las lineas (10, 20, ...) y resuelve etiquetas {nombre}.
    Las lineas que empiezan con # son comentarios del fuente y no se copian.
    Una linea que empieza con un numero conserva ese numero."""
    import re
    lines = text.replace('\r\n', '\n').split('\n')
    out = []
    labels = {}
    pending = []
    num = 0
    for raw in lines:
        s = raw.strip()
        if not s or s.startswith('#'):
            continue
        m = re.match(r'^\{(\w+)\}\s*(.*)$', s)
        if m:
            pending.append(m.group(1))
            s = m.group(2)
            if not s:
                continue
        m = re.match(r'^(\d+)\s*(.*)$', s)
        if m:
            n = int(m.group(1))
            if n <= num:
                sys.exit('%s: numero de linea fuera de orden: %d' % (fn, n))
            num = n
            s = m.group(2)
        else:
            num += 10
        for lab in pending:
            if lab in labels:
                sys.exit('%s: etiqueta repetida {%s}' % (fn, lab))
            labels[lab] = num
        pending = []
        out.append((num, s))
    def fix(code):
        # reemplaza {etiqueta} fuera de las comillas
        parts = code.split('"')
        for i in range(0, len(parts), 2):
            def rep(m):
                if m.group(1) not in labels:
                    sys.exit('%s: etiqueta desconocida {%s}' % (fn, m.group(1)))
                return str(labels[m.group(1)])
            parts[i] = re.sub(r'\{(\w+)\}', rep, parts[i])
        return '"'.join(parts)
    return '\n'.join('%d %s' % (n, fix(c)) for n, c in out) + '\n'


def lint(data, fn):
    """Busca variables cuyo nombre empieza con una palabra clave (por ejemplo
    BY% o LN%): el BASIC las parte en dos y da errores raros."""
    from bbcbasic import keyword
    errs = []
    p = 0
    while p < len(data) and data[p]:
        ln = data[p]
        num = data[p + 1] | (data[p + 2] << 8)
        body = data[p + 3:p + ln - 1]
        q = False
        k = 0
        while k < len(body):
            b = body[k]
            if b == 0x22:
                q = not q
            elif not q:
                if b == 0x8D:
                    k += 4
                    continue
                if b in (0xF4, 0xDC):       # REM, DATA
                    break
                tok = b >= 0x80 or (b < 0x20 and b != 0x0D)
                if tok and b not in (0xA4, 0xF2) and k + 1 < len(body):
                    n = body[k + 1]
                    w = keyword(b) or b'?'
                    if (chr(n).isalpha() or n in (0x25, 0x5F)) and w[-1:] not in (b'(', b'$'):
                        errs.append('%s linea %d: "%s" pegado a "%s"' %
                                    (fn, num, w.decode(), chr(n)))
            k += 1
        p += ln
    return errs


def lint_else(text, fn):
    """Avisa de "IF a THEN ... IF b THEN x ELSE y" en una sola linea: si a es
    falso, el BASIC ejecuta igual lo que sigue al ELSE."""
    import re
    errs = []
    for line in text.split('\n'):
        parts = line.split('"')
        code = ' '.join(parts[0::2])
        m = re.match(r'^(\d+)\s*(.*)$', code)
        if not m:
            continue
        num, body = m.group(1), m.group(2)
        if body.startswith('REM') or body.startswith('DATA'):
            continue
        k = body.find('ELSE')
        if k < 0:
            continue
        if len(re.findall(r'\bIF\b', body[:k])) > 1:
            errs.append('%s linea %s: IF anidado antes de ELSE' % (fn, num))
    return errs


def load_files(src):
    files = []
    for fn in sorted(os.listdir(src)):
        path = os.path.join(src, fn)
        if not os.path.isfile(path) or fn.startswith('.'):
            continue
        stem, ext = os.path.splitext(fn)
        ext = ext.lower()
        if ext == '.bas':
            name = stem.upper()
            text = preprocess(open(path, encoding='utf-8').read(), fn)
            try:
                data = tokenize(text.encode('latin-1'))
            except BasicError as e:
                sys.exit('%s: %s' % (fn, e))
            errs = lint(data, fn) + lint_else(text, fn)
            if errs:
                sys.exit('Problemas en los programas:\n  ' +
                         '\n  '.join(errs))
            load = 0x8000
        elif ext == '.txt':
            name = fn.upper()
            text = open(path, encoding='utf-8').read()
            data = text.replace('\r\n', '\n').replace('\n', '\r').encode('latin-1')
            load = 0
        else:
            name = fn.upper()
            data = open(path, 'rb').read()
            load = 0
        if len(name) > 16:
            sys.exit('%s: nombre de mas de 16 letras' % fn)
        files.append((name, data, load))
    files.sort(key=lambda f: f[0])
    return files


def build(src, out):
    files = load_files(src)
    n = len(files)
    dirsize = 32 + 32 * n
    pos = (dirsize + 255) & ~255
    image = bytearray(b'\xff' * pos)
    image[0:8] = b'ALTROM\0\0'
    image[8:10] = n.to_bytes(2, 'little')
    image[10:32] = b'\0' * 22
    for i, (name, data, load) in enumerate(files):
        e = 32 + 32 * i
        ent = bytearray(b'\xff' * 32)
        ent[0:16] = name.encode('latin-1').ljust(16, b'\0')
        ent[18:22] = len(data).to_bytes(4, 'little')
        ent[22:24] = load.to_bytes(2, 'little')
        ent[24:26] = load.to_bytes(2, 'little')
        ent[26:29] = (BASE + pos).to_bytes(3, 'little')
        ent[29] = 0
        ent[30] = 1
        image[e:e + 32] = ent
        padded = data + b'\xff' * ((256 - len(data) % 256) % 256)
        image += padded
        pos += len(padded)
    if len(image) > LIMIT:
        sys.exit('El disco de aplicaciones no entra: %d bytes (maximo %d)' %
                 (len(image), LIMIT))
    open(out, 'wb').write(image)
    total = sum(len(d) for _, d, _ in files)
    print('disco de aplicaciones: %d archivos, %d bytes de datos, %d KB usados de %d KB'
          % (n, total, len(image) // 1024, LIMIT // 1024))
    for name, data, _ in files:
        print('  %-16s %6d' % (name, len(data)))


if __name__ == '__main__':
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'disk')
    out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, 'build', 'romdisk.bin')
    build(src, out)
