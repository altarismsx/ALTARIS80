#!/usr/bin/env python3
"""Genera src/errores.inc: los mensajes de error del BASIC en castellano.

Los mensajes van en orden de numero de error (0, 1, 2...), cada uno terminado
en 0. {FN}, {PROC}... son las palabras clave (se escriben con su token).
Las letras con acento se escriben como 01H + la letra en Latin-1, porque el
BASIC toma los bytes de 80H para arriba como palabras clave.
"""
import os
TOK = {'FN': 0xA4, 'PROC': 0xF2, 'DIM': 0xDE, 'FOR': 0xE3, 'TO': 0xB8,
       'GOSUB': 0xE4, 'ON': 0xEE, 'DATA': 0xDC, 'REPEAT': 0xF5, 'EXIT': 0x10,
       'WHILE': 0xC7, 'ENDCASE': 0xCB, 'OF': 0xCA, 'ENDIF': 0xCD,
       'NEXT': 0xED, 'RETURN': 0xF8}
MSG = [
    'Sin memoria',                          # 0
    'Fuera de rango',                       # 1
    '',                                     # 2
    'Etiqueta repetida',                    # 3
    'No entiendo',                          # 4
    'Falta ,',                              # 5
    'Tipo de dato equivocado',              # 6
    'Fuera de un {FN}',                     # 7
    '',                                     # 8
    'Falta "',                              # 9
    '{DIM} incorrecto',                     # 10
    'No hay lugar para el {DIM}',           # 11
    'Fuera de un {FN} o {PROC}',            # 12
    'Fuera de un {PROC}',                   # 13
    'Mal uso de una matriz',                # 14
    'Subíndice incorrecto',                 # 15
    'Error de sintaxis',                    # 16
    'Interrumpido',                         # 17
    'División por cero',                    # 18
    'Texto demasiado largo',                # 19
    'Número demasiado grande',              # 20
    'Raíz de un número negativo',           # 21
    'Logaritmo fuera de rango',             # 22
    'Se perdió precisión',                  # 23
    'Exponente fuera de rango',             # 24
    '',                                     # 25
    'No existe la variable',                # 26
    'Falta )',                              # 27
    'Número hex o binario incorrecto',      # 28
    'No existe ese {FN}/{PROC}',            # 29
    'Llamada incorrecta',                   # 30
    'Parámetros incorrectos',               # 31
    'Fuera de un ciclo {FOR}',              # 32
    'El {NEXT} no corresponde al {FOR}',    # 33
    'Variable de {FOR} incorrecta',         # 34
    '',                                     # 35
    'Falta {TO}',                           # 36
    '',                                     # 37
    '{RETURN} sin {GOSUB}',                 # 38
    '{ON} mal escrito',                     # 39
    '{ON} fuera de rango',                  # 40
    'No existe esa línea',                  # 41
    'No hay más {DATA}',                    # 42
    'Fuera de un ciclo {REPEAT}',           # 43
    '{EXIT} incorrecto',                    # 44
    'Falta #',                              # 45
    'Fuera de un ciclo {WHILE}',            # 46
    'Falta {ENDCASE}',                      # 47
    '{OF} no es lo último',                 # 48
    'Falta {ENDIF}',                        # 49
]


def encode(s):
    out = []
    i = 0
    while i < len(s):
        if s[i] == '{':
            j = s.index('}', i)
            out.append(TOK[s[i + 1:j]])
            i = j + 1
            continue
        c = ord(s[i].encode('latin-1'))
        if c >= 0x80:
            out += [1, c]
        else:
            out.append(c)
        i += 1
    return out + [0]


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    lines = ['; Generado por tools/mkerr.py: no editar a mano', 'ERRMSG:']
    for n, m in enumerate(MSG):
        b = encode(m)
        lines.append('\tDEFB\t' + ','.join('%03XH' % x for x in b) + '\t;%d %s' % (n, m.encode('ascii', 'replace').decode()))
    open(os.path.join(here, '..', 'src', 'errores.inc'), 'w').write('\n'.join(lines) + '\n')


if __name__ == '__main__':
    main()
