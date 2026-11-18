#!/usr/bin/env python3
"""ALTARIS 80 - armado de la imagen de la flash de programa (1 MB).

Pasos:
  1. ensambla todos los modulos con um80
  2. enlaza el BASIC en 4000H (pagina 4) usando la tabla fija del sistema
     operativo en 0100H (osjump.mac)
  3. con los simbolos del BASIC enlaza la pagina 0 (nucleo + sistema)
  4. enlaza los bancos de video, disco y arranque
  5. arma build/codeflash.bin (paginas de 16 KB, sin usar = FFH)
"""
import os, subprocess, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
SRC = os.path.join(ROOT, 'src')
BLD = os.path.join(ROOT, 'build')
os.makedirs(BLD, exist_ok=True)

PAGE = 0x4000
IMAGE_SIZE = 0x100000

# Simbolos del sistema operativo que usa el interprete, en orden fijo.
# La tabla de saltos en 0100H no puede cambiar de orden entre versiones.
OSSYMS = ('OSINIT OSRDCH OSWRCH OSLINE OSSAVE OSLOAD OSOPEN OSSHUT OSBGET '
          'OSBPUT OSSTAT GETEXT GETPTR PUTPTR PROMPT RESET LTRAP OSCLI TRAP '
          'BYE OSCALL CLRSCN PUTCSR GETCSR PUTIME GETIME OSKEY CLG MOVE DRAW '
          'PLOT MODE COLOUR GCOL ADVAL SOUND ENVEL POINT CIRCLE ELLIPS FILL '
          'MOUSE ORIGIN RECTAN LINE TINT WAIT SYS CSRON CSROFF PUTIMS GETIMS '
          'TINTFN MODEFN WIDFN ERRMSG').split()
OSTAB = 0x0100

# Simbolos del interprete que usa la pagina 0
BASSYMS = ('START ESCAPE EXTERR CRLF ACCS CURLIN AUTONO VERMSG ITEMI EXPRI '
           'COMMA TERMQ BRAKET STOREN VAR NXT XEQ COUNT WIDTH').split()


def run(cmd):
    r = subprocess.run(cmd, cwd=BLD, capture_output=True, text=True)
    out = r.stdout + r.stderr
    if r.returncode != 0 or 'rror' in out:
        print(' '.join(cmd))
        print(out)
        sys.exit(1)
    return out


def asm(src, name=None, pre=None):
    name = name or os.path.splitext(os.path.basename(src))[0]
    rel = os.path.join(BLD, name + '.rel')
    cmd = ['um80', '-I', SRC, '-I', BLD, '-o', rel, '-l', os.path.join(BLD, name + '.prn')]
    if pre:
        cmd += ['-e', pre]
    cmd.append(src if os.path.isabs(src) else os.path.join(SRC, src))
    run(cmd)
    return rel


def link(out, rels, origin):
    hexf = os.path.join(BLD, out + '.hex')
    sym = os.path.join(BLD, out + '.sym')
    run(['ul80', '-x', '--no-ds-zeros', '-p', '%X' % origin, '-o', hexf,
         '-S', sym] + rels)
    return read_hex(hexf), read_sym(sym)


def read_hex(path):
    mem = {}
    for line in open(path):
        line = line.strip()
        if not line.startswith(':'):
            continue
        b = bytes.fromhex(line[1:])
        n, addr, typ = b[0], (b[1] << 8) | b[2], b[3]
        if typ == 0:
            for i in range(n):
                mem[addr + i] = b[4 + i]
    return mem


def read_sym(path):
    syms = {}
    for line in open(path):
        p = line.split()
        if len(p) == 2:
            try:
                syms[p[1]] = int(p[0], 16)
            except ValueError:
                pass
    return syms


def place(image, mem, base, lo, hi, what):
    """Copia mem (direcciones de CPU lo..hi-1) a la imagen en base."""
    used = [a for a in mem if mem[a] is not None]
    if not used:
        return 0
    if min(used) < lo or max(used) >= hi:
        print('%s fuera de rango: %04X-%04X (permitido %04X-%04X)' %
              (what, min(used), max(used), lo, hi - 1))
        sys.exit(1)
    for a in used:
        image[base + a - lo] = mem[a]
    return max(used) - lo + 1


def main():
    # 0a. instalador (corre en la RAM desde 8000H): va al disco de
    # aplicaciones (para *ACTUALIZAR) y al kit (para el Loader)
    lines = [l for l in open(os.path.join(SRC, 'font.inc')) if l.strip().startswith('DEFB')]
    with open(os.path.join(BLD, 'instfont.inc'), 'w') as f:
        f.write(''.join(lines[0x20:0x5B]))
    imem, _ = link('instalar', [asm('instalar.mac')], 0x8000)
    hi = max(imem)
    ibin = bytes(imem.get(a, 0) for a in range(0x8000, hi + 1))
    if len(ibin) > 0x3000:
        sys.exit('El instalador es demasiado grande: %d bytes' % len(ibin))
    open(os.path.join(BLD, 'instalar.bin'), 'wb').write(ibin)
    open(os.path.join(ROOT, 'disk', 'INSTALAR.BIN'), 'wb').write(ibin)
    if os.path.isdir(os.path.join(ROOT, 'kit')):
        open(os.path.join(ROOT, 'kit', 'INSTALAR.BIN'), 'wb').write(ibin)
    print('instalador: %d bytes' % len(ibin))
    # 0b. prueba de cables (tambien corre en la RAM desde 8000H, por el Loader)
    cmem, _ = link('cables', [asm('cables.mac')], 0x8000)
    cbin = bytes(cmem.get(a, 0) for a in range(0x8000, max(cmem) + 1))
    open(os.path.join(BLD, 'cables.bin'), 'wb').write(cbin)
    if os.path.isdir(os.path.join(ROOT, 'kit')):
        open(os.path.join(ROOT, 'kit', 'CABLES.BIN'), 'wb').write(cbin)
    print('prueba de cables: %d bytes' % len(cbin))
    # 0. disco de aplicaciones
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import mkromdisk
    if os.path.isdir(os.path.join(ROOT, 'disk')):
        mkromdisk.build(os.path.join(ROOT, 'disk'), os.path.join(BLD, 'romdisk.bin'))
    # 1. tabla de saltos del sistema operativo, para enlazar el BASIC
    with open(os.path.join(BLD, 'osjump.mac'), 'w') as f:
        f.write('\t.Z80\n')
        for i, s in enumerate(OSSYMS):
            f.write('\tPUBLIC\t%s\n%s\tEQU\t%04XH\n' % (s, s, OSTAB + 3 * i))
        # ERRPTR: direccion de la tabla de mensajes de error (dentro del JP)
        f.write('\tPUBLIC\tERRPTR\nERRPTR\tEQU\t%04XH\n' %
                (OSTAB + 3 * OSSYMS.index('ERRMSG') + 1))
        f.write('\tEND\n')
    with open(os.path.join(BLD, 'ostable.mac'), 'w') as f:
        f.write('\t.Z80\n\tASEG\n\tORG\t%04XH\n' % OSTAB)
        for s in OSSYMS:
            f.write('\tEXTRN\t%s\n' % s)
        for s in OSSYMS:
            f.write('\tJP\t%s\n' % s)
        f.write('\tEND\n')

    # 2. BASIC
    bas = [asm(m + '.Z80', pre='.Z80') for m in ('MAIN', 'EXEC', 'EVAL', 'ASMB', 'MATH')]
    bas.append(asm(os.path.join(BLD, 'osjump.mac')))
    bas.append(asm('DATA.Z80', pre='.Z80!ASEG!ORG 0%04XH' % 0xF500))
    bmem, bsym = link('basic', bas, 0x4000)

    # 3. pagina 0
    with open(os.path.join(BLD, 'basicsym.mac'), 'w') as f:
        f.write('\t.Z80\n')
        for s in BASSYMS:
            f.write('\tPUBLIC\t%s\n%s\tEQU\t0%04XH\n' % (s, s, bsym[s]))
        f.write('\tEND\n')
    p0 = [asm('core.mac'), asm(os.path.join(BLD, 'ostable.mac')),
          asm('msos.mac'), asm('ACORN.Z80', pre='.Z80'), asm('update.mac'),
          asm(os.path.join(BLD, 'basicsym.mac'))]
    p0mem, p0sym = link('page0', p0, 0x0200)

    # rutinas de la pagina 0 que usan los bancos
    with open(os.path.join(BLD, 'p0sym.inc'), 'w') as f:
        f.write('; Generado por build.py\n')
        for s in ('OSWRCH', 'PSTR', 'PDEC', 'CRLF2', 'TIMSTR', 'VWRCH',
                  'OSRDCH', 'OSCLI'):
            f.write('%s\tEQU\t0%04XH\n' % (s, p0sym[s]))

    # 4. bancos
    banks = {}
    for name, page in (('vdu', 5), ('fs', 6), ('boot', 7)):
        m, s = link(name, [asm(name + '.mac')], 0x4000)
        banks[name] = (page, m, s)

    # 5. imagen
    image = bytearray([0xFF]) * IMAGE_SIZE
    n0 = place(image, p0mem, 0x0000, 0x0000, 0x4000, 'pagina 0')
    nb = place(image, bmem, 4 * PAGE, 0x4000, 0x8000, 'BASIC')
    print('pagina 0 : %5d bytes (libres %d)' % (n0, PAGE - n0))
    print('BASIC    : %5d bytes (libres %d)' % (nb, PAGE - nb))
    for name, (page, m, s) in banks.items():
        n = place(image, m, page * PAGE, 0x4000, 0x8000, name)
        print('%-9s: %5d bytes (libres %d)' % (name, n, PAGE - n))

    # disco de aplicaciones (paginas 8 en adelante)
    romd = os.path.join(BLD, 'romdisk.bin')
    if os.path.exists(romd):
        data = open(romd, 'rb').read()
        if 8 * PAGE + len(data) > IMAGE_SIZE:
            print('disco de aplicaciones demasiado grande')
            sys.exit(1)
        image[8 * PAGE:8 * PAGE + len(data)] = data
        print('disco ROM: %d bytes' % len(data))

    open(os.path.join(BLD, 'codeflash.bin'), 'wb').write(image)
    # simbolos combinados para el depurador
    with open(os.path.join(BLD, 'altaris.sym'), 'w') as f:
        for s, a in sorted(p0sym.items(), key=lambda x: x[1]):
            f.write('%04X %s\n' % (a, s))
        for s, a in sorted(bsym.items(), key=lambda x: x[1]):
            f.write('%04X %s\n' % (a, s))
    # imagen para el kit: hasta la ultima pagina usada
    if os.path.isdir(os.path.join(ROOT, 'kit')):
        ult = max(i for i in range(IMAGE_SIZE // PAGE)
                  if image[i * PAGE:(i + 1) * PAGE] != b'\xff' * PAGE)
        open(os.path.join(ROOT, 'kit', 'ALTARIS80.BIN'), 'wb').write(
            bytes(image[:(ult + 1) * PAGE]))
        print('kit/ALTARIS80.BIN: %d paginas' % (ult + 1))
    print('build/codeflash.bin listo')


if __name__ == '__main__':
    main()
