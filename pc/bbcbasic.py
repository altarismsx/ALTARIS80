#!/usr/bin/env python3
"""Tokenizador y destokenizador de Altaris BASIC (BBC BASIC Z80 v5).

Es una traduccion fiel de LEXAN/LEX de MAIN.Z80 (R.T. Russell, licencia
zlib), para convertir programas de texto (.bas) al formato que graba SAVE,
y al reves. Uso:
    python3 bbcbasic.py tok  entrada.bas salida
    python3 bbcbasic.py list entrada salida.bas
Los textos se leen y escriben en UTF-8 y se pasan a Latin-1 (los acentos
del castellano estan en la fuente de la MailStation).
"""
import sys

KEYWDS = bytes.fromhex('80414e44944142539541435396414456414c974153439841534e9941544e9a4247455420d542505554200f425920fb434f4c4f5552fb434f4c4f52d643414c4cc843415345d7434841494ebd43485224d8434c45415220d9434c4f534520da434c4720db434c53209b434f539c434f554e542001434952434c45dc444154419d444547dd44454681444956de44494ddf44524157e1454e4450524f4320ce454e445748494c4520cb454e444341534520cd454e44494620e0454e4420e2454e56454c4f50458b454c5345a04556414c9e45524c20854552524f52c5454f462082454f529f45525220104558495420a1455850a24558542002454c4c49505345e3464f52a346414c5345200346494c4ca4464ee5474f544fbe47455424a5474554e4474f535542e647434f4c9348494d454d20e8494e505554e74946bf494e4b455924a6494e4b4559a8494e54a7494e535452280c494e5354414c4c864c494e45924c4f4d454d20ea4c4f43414cc04c4546542428a94c454ee94c4554ab4c4f47aa4c4ec14d49442428eb4d4f4445834d4f44ec4d4f5645044d4f555345ed4e455854ac4e4f54ee4f4e874f464620ca4f4620054f524947494e844f528e4f50454e494eae4f50454e4f5554ad4f50454e5550ff4f53434c49cc4f5448455257495345f15052494e549050414745208f50545220af504920f0504c4f54b0504f494e5428f250524f43b1504f53200e505554065155495420f852455455524e20f5524550454154f65245504f525420f352454144f452454df952554e20b2524144f7524553544f5245c252494748542428b3524e44200752454354414e474c458853544550b453474eb553494eb653515289535043c353545224c4535452494e472428d4534f554e44fa53544f5020c653554d085357415009535953b754414e8a544142288c5448454e9154494d45200a54494e54b8544ffc5452414345b95452554520fd554e54494cba555352ef564455bb56414cbc56504f5320c75748494c45c95748454e0b5741495420fe5749445448cf505452d154494d45d348494d454dd24c4f4d454dd050414745114d697373696e6720124e6f2073756368201342616420142072616e6765157661726961626c65164f7574206f66174e6f2018207370616365194e6f7420696e2061201a206c6f6f701b206e6f7420') + b'\xff\xff'

CR = 0x0D
TERROR, TELSE, TTHEN, TLINO = 0x85, 0x8B, 0x8C, 0x8D
TFN, TDATA, TGOSUB, TGOTO = 0xA4, 0xDC, 0xE4, 0xE5
TPROC, TREM, TREPEAT, TRESTORE, TTRACE = 0xF2, 0xF4, 0xF5, 0xF7, 0xFC
TOKLO, TOKHI = 0x8F, 0x93
OFFSET = 0xCF - TOKLO
LIST1 = (TGOTO, TGOSUB, TRESTORE, TTRACE, TTHEN, TELSE)
LIST2 = (TTHEN, TELSE, TREPEAT, TERROR, ord(':'))


class BasicError(Exception):
    pass


def printable(a):          # "CP 160 / JP PE" del original
    return 0x20 <= a <= 0x7F


def range1(a):
    return (0x30 <= a <= 0x39) or a == 0x40 or range2(a)


def range2(a):
    return (0x41 <= a <= 0x5A) or (0x5F <= a <= 0x7A)


def lex(src, iy):
    """Devuelve (codigo, iy). Si no hay palabra clave, el caracter mismo."""
    hl = 0
    while True:
        a = src[iy]
        b = KEYWDS[hl]
        hl += 1
        if a == KEYWDS[hl]:
            save = iy
            found = False
            while True:                     # LEX3
                hl += 1
                t = KEYWDS[hl]
                if not printable(t):
                    found = True
                    break
                iy += 1
                a = src[iy]
                if a != t or not (0x21 <= a <= 0x7F):
                    break                   # LEX7
            if found:
                return b, iy
            a = src[iy]                     # LEX7
            if a == ord('.'):
                return b, iy
            if not range1(a) and KEYWDS[hl] == 0x20:
                return b, iy - 1            # LEX5
            iy = save                       # LEX4
        elif a < KEYWDS[hl]:
            return src[iy], iy              # no hay
        while True:                         # LEX1
            hl += 1
            if not printable(KEYWDS[hl]):
                break


def encode(n):
    d, e = n >> 8, n & 0xFF
    b2 = (((d & 0xC0) >> 2) | (e & 0xC0)) >> 2
    return bytes([TLINO, b2 ^ 0x54, (e & 0x3F) | 0x40, (d & 0x3F) | 0x40])


def lexan(src, c):
    """src termina en CR. Devuelve el texto tokenizado (sin el CR)."""
    out = bytearray()
    iy = 0
    while True:
        if len(out) >= 252:
            raise BasicError('String too long')
        a = src[iy]
        if a == CR:
            return bytes(out)
        if not range1(a):
            c &= ~0x28
        if a in (0x20, 0x2C):
            out.append(a)
            iy += 1
            continue
        if a >= ord('G'):
            c &= ~0x08
        if a == ord('"'):
            c ^= 0x80
        if c & 0x10:
            c &= ~0x10
            while src[iy] == 0x20:
                iy += 1
            n = 0
            while 0x30 <= src[iy] <= 0x39:
                n = n * 10 + src[iy] - 0x30
                if n > 0xFFFF:
                    raise BasicError('Too big')
                iy += 1
            if n:
                out += encode(n)
                c |= 0x10
            continue
        if c == 1:                          # LEXAN7: modo izquierdo
            c = 0                           # (el DEC C del original lo apaga)
            if a == ord('*'):
                c |= 0x40
            else:
                if a < 0x80:
                    a, iy = lex(src, iy)
                if a == TDATA:
                    c |= 0x40
                else:
                    if TOKLO <= a <= TOKHI:
                        a += OFFSET
                    if a == TREM:
                        c |= 0x40
        elif c == 0:
            if a < 0x80:
                a, iy = lex(src, iy)
            if a == TREM:
                c |= 0x40
        else:
            out.append(a)
            iy += 1
            continue
        if a in (TFN, TPROC) or range2(a):  # LEXANA
            c |= 0x20
        if a == ord('&'):
            c |= 0x08
        if a in LIST1:
            c |= 0x10
        if a in LIST2:
            c |= 0x01
        out.append(a)
        iy += 1


def tokenize(text):
    """Programa en texto -> bytes como los graba SAVE."""
    if isinstance(text, str):
        text = text.encode('latin-1')
    lines = {}
    for num, raw in enumerate(text.replace(b'\r\n', b'\n').replace(b'\r', b'\n').split(b'\n'), 1):
        s = raw.rstrip(b' \t')
        if not s.strip():
            continue
        i = 0
        while i < len(s) and s[i] == 0x20:
            i += 1
        n = 0
        j = i
        while j < len(s) and 0x30 <= s[j] <= 0x39:
            n = n * 10 + s[j] - 0x30
            j += 1
        if j == i:
            raise BasicError('linea %d: falta el numero de linea' % num)
        if n > 65279:
            raise BasicError('linea %d: numero de linea muy grande' % num)
        while j < len(s) and s[j] == 0x20:
            j += 1
        body = lexan(s[j:] + bytes([CR]), 1)
        if body:
            lines[n] = body
        else:
            lines.pop(n, None)
    out = bytearray()
    for n in sorted(lines):
        body = lines[n]
        out += bytes([len(body) + 4, n & 0xFF, n >> 8]) + body + bytes([CR])
    out += b'\x00\xff\xff'
    return bytes(out)


def keyword(tok):
    i = 0
    while i < len(KEYWDS) - 2:
        if KEYWDS[i] == tok and not printable(tok):
            j = i + 1
            w = bytearray()
            while j < len(KEYWDS) and printable(KEYWDS[j]):
                w.append(KEYWDS[j])
                j += 1
            return bytes(w).rstrip(b' ')
        i += 1
    return None


def detokenize(data):
    """Bytes de un programa -> texto (una linea por renglon)."""
    lines = []
    p = 0
    while p < len(data):
        ln = data[p]
        if ln == 0:
            break
        n = data[p + 1] | (data[p + 2] << 8)
        body = data[p + 3:p + ln - 1]
        p += ln
        out = bytearray(b'%d ' % n)
        quote = False
        raw = False
        k = 0
        while k < len(body):
            b = body[k]
            k += 1
            if raw or quote:
                out.append(b)
                if b == ord('"') and not raw:
                    quote = False
                continue
            if b == ord('"'):
                quote = True
                out.append(b)
            elif b == TLINO:
                b1, b2, b3 = body[k:k + 3]
                k += 3
                b1 = (b1 ^ 0x54) << 2
                lo = (b2 & 0x3F) | (b1 & 0xC0)
                hi = (b3 & 0x3F) | ((b1 << 2) & 0xC0)
                out += b'%d' % (lo | (hi << 8))
            elif b >= 0x80 or b < 0x20:
                t = b
                if TOKLO + OFFSET <= b <= TOKHI + OFFSET:
                    t = b - OFFSET
                w = keyword(t)
                out += w if w is not None else bytes([b])
                if b in (TREM, TDATA):
                    raw = True
            else:
                out.append(b)
        lines.append(bytes(out))
    return b'\n'.join(lines) + b'\n'


def main():
    if len(sys.argv) != 4 or sys.argv[1] not in ('tok', 'list'):
        print(__doc__)
        sys.exit(1)
    if sys.argv[1] == 'tok':
        text = open(sys.argv[2], encoding='utf-8').read().encode('latin-1')
        open(sys.argv[3], 'wb').write(tokenize(text))
    else:
        data = open(sys.argv[2], 'rb').read()
        open(sys.argv[3], 'w', encoding='utf-8').write(detokenize(data).decode('latin-1'))


if __name__ == '__main__':
    main()
