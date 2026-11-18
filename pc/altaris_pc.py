#!/usr/bin/env python3
"""
ALTARIS PC - conexion entre la PC y la MailStation con ALTARIS 80
por el adaptador MS-LINK 2 (Arduino Uno o Nano). Altaris Software, 2026.

Uso (en Windows: py altaris_pc.py ...):

  py altaris_pc.py enviar  ARCHIVO [PUERTO]   manda un archivo a la MailStation
                                              (alla: *RECIBIR NOMBRE)
  py altaris_pc.py recibir NOMBRE  [PUERTO]   recibe un archivo de la MailStation
                                              (alla: *ENVIAR NOMBRE)
  py altaris_pc.py instalar        [PUERTO]   instala ALTARIS 80 (por el Loader),
                                              antes guarda un respaldo
  py altaris_pc.py directo         [PUERTO]   instala ALTARIS 80 sin respaldo
                                              (el firmware original se pierde)
  py altaris_pc.py respaldo        [PUERTO]   solo copia la memoria a la PC
  py altaris_pc.py restaurar ARCHIVO.bin [PUERTO]
                                              vuelve a grabar un respaldo
  py altaris_pc.py cargar  PROGRAMA.BIN [PUERTO]
                                              manda un programa al Loader
  py altaris_pc.py cables          [PUERTO]   prueba los cables, uno por uno

Los programas de BASIC (.bas) se escriben en la PC como texto, con o sin
numeros de linea: este programa los convierte al enviarlos, y al recibirlos
los vuelve a convertir en texto.

PUERTO es COM3, COM5, etc. Si no se indica, se busca solo.
Necesita Python 3 y pyserial:  py -m pip install pyserial
"""

import os
import re
import sys
import time

AQUI = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, AQUI)

try:
    import serial
    import serial.tools.list_ports
except ImportError:
    print("Falta pyserial. Instalalo con:  py -m pip install pyserial")
    sys.exit(1)

import bbcbasic

VELOCIDAD = 115200
BLOQUE = 32
# chips USB-serie habituales en placas Uno, Nano y clones
VID_CONOCIDOS = {0x2341, 0x2A03, 0x1A86, 0x0403, 0x10C4}


class Error(Exception):
    pass


# ----------------------------------------------------------------------
# Adaptador
# ----------------------------------------------------------------------

def buscar_puerto():
    puertos = list(serial.tools.list_ports.comports())
    candidatos = [p for p in puertos if p.vid in VID_CONOCIDOS]
    if len(candidatos) == 1:
        return candidatos[0].device
    if not puertos:
        raise Error("No encontre ningun puerto serie. Conecta el Arduino por USB.")
    lista = "\n".join("   %s  %s" % (p.device, p.description) for p in puertos)
    raise Error("No pude elegir el puerto solo. Puertos disponibles:\n%s\n"
                "Indicalo al final del comando, por ejemplo: COM5" % lista)


class Enlace:
    def __init__(self, puerto):
        # Se abre con DTR y RTS apagados para no reiniciar el Arduino: mientras
        # se reinicia, sus salidas quedan sueltas y la MailStation podria
        # leer basura. Algunas veces igual se reinicia: entonces se espera.
        s = serial.Serial()
        s.port, s.baudrate, s.timeout = puerto, VELOCIDAD, 0.2
        s.dtr = False
        s.rts = False
        try:
            s.open()
        except serial.SerialException as e:
            raise Error("No pude abrir %s: %s" % (puerto, e))
        self.ser = s
        self.version = 0
        if self.probar(0.4):
            return
        time.sleep(2.5)
        for _ in range(3):
            if self.probar(1.5):
                return
        raise Error("El adaptador en %s no responde. Revisa que tenga cargado "
                    "MS_Link.ino." % puerto)

    def probar(self, segundos):
        self.ser.reset_input_buffer()
        self.ser.write(b"P")
        self.ser.timeout = segundos
        linea = self.ser.readline()
        self.ser.timeout = 0.2
        if b"MSLINK OK" not in linea:
            return False
        m = re.search(rb"MSLINK OK (\d+)", linea)
        self.version = int(m.group(1)) if m else 1
        return True

    def respuesta(self, segundos=8):
        fin = time.time() + segundos
        while time.time() < fin:
            r = self.ser.read(1)
            if r:
                return r
        return b""

    def leer_exacto(self, n, segundos=8):
        datos = b""
        fin = time.time() + segundos
        while len(datos) < n and time.time() < fin:
            datos += self.ser.read(n - len(datos))
        return datos

    def pedir_version2(self):
        # MS_Link 2 y 3 bajaban busy un instante al terminar de mandar: la
        # MailStation contestaba antes de tiempo y la respuesta se perdia
        if self.version < 4:
            raise Error("El Arduino tiene un MS_Link viejo (version %d). Hay que "
                        "cargarle MS_Link.ino de este kit (version 4)." % self.version)

    def mandar(self, datos, espera_inicio=0):
        """Manda bytes a la MailStation. Con espera_inicio > 0 reintenta el
        primer byte hasta que la MailStation lo tome (en segundos)."""
        self.pedir_version2()
        i = 0
        if espera_inicio:
            fin = time.time() + espera_inicio
            while True:
                self.ser.write(b"W\x01" + datos[0:1])
                r = self.respuesta(6)
                if r == b"K":
                    break
                if r not in (b"E", b"T") or time.time() > fin:
                    raise Error("La MailStation no responde.")
            i = 1
        while i < len(datos):
            bloque = datos[i:i + BLOQUE]
            self.ser.write(b"W" + bytes([len(bloque)]) + bloque)
            r = self.respuesta(8)
            if r != b"K":
                raise Error("Se corto la comunicacion con la MailStation "
                            "(respuesta %r)." % r)
            i += len(bloque)

    def recibir(self, n, espera_inicio=0):
        """Recibe n bytes. Con espera_inicio > 0 espera ese tiempo a que la
        MailStation empiece a mandar."""
        self.pedir_version2()
        datos = bytearray()
        fin = time.time() + espera_inicio
        while len(datos) < n:
            m = min(BLOQUE, n - len(datos))
            self.ser.write(b"R" + bytes([m]))
            r = self.respuesta(8)
            if r == b"T" and not datos and time.time() < fin:
                continue
            if r != b"K":
                raise Error("La MailStation no manda datos (respuesta %r)." % r)
            parte = self.leer_exacto(m)
            if len(parte) != m:
                raise Error("Se cortaron los datos de la MailStation.")
            datos += parte
        return bytes(datos)

    def cargar_loader(self, datos):
        """Manda un programa al Loader del firmware original."""
        largo = len(datos)
        self.ser.write(b"S" + bytes([largo & 0xFF, largo >> 8]))
        r = self.respuesta(8)
        if r != b"K":
            raise Error("La MailStation no responde. Apreta RESET atras, elegi "
                        "'No borrar', abri Loader y proba de nuevo.")
        enviados = 0
        while enviados < largo:
            bloque = datos[enviados:enviados + BLOQUE]
            self.ser.write(bloque)
            r = self.respuesta(8)
            if r != b"K":
                raise Error("Se corto el envio en el byte %d (respuesta %r)."
                            % (enviados, r))
            enviados += len(bloque)
            barra(enviados, largo)
        print()


def barra(hecho, total, texto=""):
    n = 30 * hecho // max(total, 1)
    sys.stdout.write("\r  [%s%s] %3d%% %s" % ("#" * n, "." * (30 - n),
                                              100 * hecho // max(total, 1), texto))
    sys.stdout.flush()


# ----------------------------------------------------------------------
# Programas de BASIC
# ----------------------------------------------------------------------

def leer_texto(ruta):
    crudo = open(ruta, "rb").read()
    for cod in ("utf-8-sig", "cp1252"):
        try:
            return crudo.decode(cod)
        except UnicodeDecodeError:
            pass
    return crudo.decode("latin-1")


def numerar(texto):
    """Numera las lineas que no tienen numero (10, 20, ...) y resuelve las
    etiquetas {nombre}. Las lineas que empiezan con # se saltean."""
    out, labels, pending, num = [], {}, [], 0
    for raw in texto.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        s = raw.strip()
        if not s or s.startswith("#"):
            continue
        m = re.match(r"^\{(\w+)\}\s*(.*)$", s)
        if m:
            pending.append(m.group(1))
            s = m.group(2)
            if not s:
                continue
        m = re.match(r"^(\d+)\s*(.*)$", s)
        if m:
            n = int(m.group(1))
            if n <= num:
                raise Error("Numero de linea fuera de orden: %d" % n)
            num = n
            s = m.group(2)
        else:
            num += 10
        for lab in pending:
            labels[lab] = num
        pending = []
        out.append((num, s))

    def fix(code):
        partes = code.split('"')
        for i in range(0, len(partes), 2):
            def rep(m):
                if m.group(1) not in labels:
                    raise Error("Etiqueta desconocida {%s}" % m.group(1))
                return str(labels[m.group(1)])
            partes[i] = re.sub(r"\{(\w+)\}", rep, partes[i])
        return '"'.join(partes)
    return "\n".join("%d %s" % (n, fix(c)) for n, c in out) + "\n"


def es_programa(datos):
    """Verdadero si los bytes tienen la forma de un programa de BASIC."""
    p = 0
    while p < len(datos):
        ln = datos[p]
        if ln == 0:
            return p > 0 and datos[p:p + 3] in (b"\x00\xff\xff", b"\x00\xff", b"\x00")
        if ln < 4 or p + ln > len(datos) or datos[p + ln - 1] != 0x0D:
            return False
        p += ln
    return False


def preparar(ruta):
    """Devuelve (nombre para la MailStation, bytes a mandar, descripcion)."""
    base = os.path.basename(ruta)
    raiz, ext = os.path.splitext(base)
    ext = ext.lower()
    if ext == ".bas":
        texto = numerar(leer_texto(ruta))
        try:
            datos = bbcbasic.tokenize(texto.encode("latin-1", "replace"))
        except bbcbasic.BasicError as e:
            raise Error("Error en el programa: %s" % e)
        return raiz.upper(), datos, "programa de BASIC"
    if ext == ".txt":
        texto = leer_texto(ruta).replace("\r\n", "\n").replace("\r", "\n")
        if not texto.endswith("\n"):
            texto += "\n"
        return base.upper(), texto.encode("latin-1", "replace"), "texto"
    return base.upper(), open(ruta, "rb").read(), "archivo"


# ----------------------------------------------------------------------
# Comandos
# ----------------------------------------------------------------------

def suma16(datos):
    return sum(datos) & 0xFFFF


def cmd_enviar(enlace, ruta):
    nombre, datos, que = preparar(ruta)
    if len(nombre) > 16:
        raise Error("El nombre %s tiene mas de 16 letras." % nombre)
    print("Archivo: %s (%s, %d bytes)" % (nombre, que, len(datos)))
    print("En la MailStation escribi:  *RECIBIR %s" % nombre)
    print("Esperando a la MailStation (hasta 2 minutos)...")
    largo = len(datos)
    cab = b"A8" + bytes([largo & 0xFF, (largo >> 8) & 0xFF, largo >> 16])
    enlace.mandar(cab[:1], espera_inicio=120)
    enlace.mandar(cab[1:])
    enviados = 0
    while enviados < largo:
        parte = datos[enviados:enviados + 512]
        enlace.mandar(parte)
        enviados += len(parte)
        barra(enviados, largo)
    s = suma16(datos)
    enlace.mandar(bytes([s & 0xFF, s >> 8]))
    print("\nListo: %s esta en el disco de la MailStation." % nombre)


def cmd_recibir(enlace, nombre):
    print("En la MailStation escribi:  *ENVIAR %s" % nombre.upper())
    print("Esperando a la MailStation (hasta 2 minutos)...")
    cab = enlace.recibir(5, espera_inicio=120)
    if cab[:2] != b"A8":
        raise Error("La MailStation mando algo que no es un archivo.")
    largo = cab[2] | (cab[3] << 8) | (cab[4] << 16)
    datos = bytearray()
    while len(datos) < largo:
        datos += enlace.recibir(min(512, largo - len(datos)))
        barra(len(datos), largo)
    s = enlace.recibir(2)
    print()
    if (s[0] | (s[1] << 8)) != suma16(datos):
        raise Error("Los datos llegaron con errores. Proba de nuevo.")
    datos = bytes(datos)
    raiz, ext = os.path.splitext(nombre)
    if not ext and es_programa(datos):
        destino = raiz.upper() + ".bas"
        texto = bbcbasic.detokenize(datos).decode("latin-1")
        open(destino, "w", encoding="utf-8").write(texto)
        print("Listo: %s (programa de BASIC pasado a texto, %d bytes)."
              % (destino, len(datos)))
    elif ext.lower() == ".txt":
        texto = datos.decode("latin-1").replace("\r\n", "\n").replace("\r", "\n")
        open(nombre.upper(), "w", encoding="utf-8").write(texto)
        print("Listo: %s (texto)." % nombre.upper())
    else:
        open(nombre.upper(), "wb").write(datos)
        print("Listo: %s (%d bytes)." % (nombre.upper(), len(datos)))


# cada linea de la prueba: salida del Arduino -> MailStation -> entrada
# del Arduino (bit, pin DB25 de ida, pin Arduino, pin DB25 de vuelta, pin Arduino)
PARES = [(0, 15, "D11", 2, "D2"), (1, 13, "D10", 3, "D3"), (2, 12, "D9", 4, "D4"),
         (3, 10, "D7", 5, "D5"), (4, 11, "D8", 6, "D6")]
# el cable que no se prueba al mandar un programa al Loader
SOSPECHOSO = {0: (2, "D2"), 1: (3, "D3"), 2: (4, "D4"), 3: (10, "D7"), 4: (6, "D6")}


def cmd_cables(enlace):
    enlace.pedir_version2()
    datos = open(os.path.join(os.path.dirname(AQUI), "CABLES.BIN"), "rb").read()
    print()
    print("En la MailStation: Aplicaciones, segunda pagina, elegi Loader y apreta Enter.")
    print("La pantalla NO cambia: sigue mostrando el icono de Loader. Asi esta bien.")
    input("\nDespues apreta Enter aca...")
    print("Mandando la prueba:")
    enlace.cargar_loader(datos)
    print("En la MailStation tiene que aparecer 'ALTARIS 80 - PRUEBA DE CABLES'.")
    time.sleep(1.5)
    enlace.ser.reset_input_buffer()
    patrones = [0x00, 0x1F] + [1 << k for k in range(5)] + [0x1F ^ (1 << k) for k in range(5)]
    vuelta = []
    for v in patrones:
        enlace.ser.write(b"Q" + bytes([v]))
        r = enlace.respuesta(3)
        x = enlace.leer_exacto(1, 3)
        if r != b"K" or len(x) != 1:
            raise Error("El Arduino no contesto la prueba (respuesta %r)." % r)
        vuelta.append(x[0] & 0x1F)
    malos = []
    print("\nResultado (ida: Arduino -> MailStation, vuelta: MailStation -> Arduino):\n")
    for bit, pi, ai, pv, av in PARES:
        m = 1 << bit
        llega = [bool(x & m) for x in vuelta]
        manda = [bool(v & m) for v in patrones]
        if llega == manda:
            estado = "BIEN"
        else:
            malos.append(bit)
            if not any(llega):
                estado = "MAL (siempre vuelve 0)"
            elif all(llega):
                estado = "MAL (siempre vuelve 1)"
            else:
                otro = [p for b, p, a, q, c in PARES
                        if [bool(v & (1 << b)) for v in patrones] == llega]
                estado = ("MAL (cruzado: vuelve lo del pin %d)" % otro[0] if otro
                          else "MAL (falla a veces)")
        print("  ida pin %2d (%-3s) -> vuelta pin %d (%s):  %s" % (pi, ai, pv, av, estado))
    print()
    if not malos:
        print("Los 11 cables andan bien.")
    elif len(malos) == 5:
        print("No vuelve nada. Fijate que la MailStation diga 'ALTARIS 80 - PRUEBA DE "
              "CABLES'.\nSi lo dice, revisa los cables de vuelta: pines 2, 3, 4, 6 y 10 "
              "del DB25.")
    else:
        print("Los cables de los pines 5, 11, 12, 13, 15 y 25 andan: por ellos llego "
              "la prueba.")
        print("Revisa, de punta a punta:")
        for bit in malos:
            pin, ard = SOSPECHOSO[bit]
            print("  - el cable del pin %d del DB25 al pin %s del Arduino" % (pin, ard))
    if not malos:
        if prueba_comunicacion(enlace):
            print("\nCables y comunicacion andan bien.")
    print("\nPara salir de la prueba: boton RESET atras de la MailStation, 'No borrar'.")


def prueba_comunicacion(enlace):
    """Con CABLES.BIN andando: 256 bytes de ida y vuelta con el protocolo
    de 3 bits (las mismas rutinas que el instalador)."""
    print("\nPrueba de comunicacion (ida y vuelta, como el instalador):")
    for v in (0x15, 0x0A):          # la senal para que CABLES.BIN pase a esta prueba
        enlace.ser.write(b"Q" + bytes([v]))
        enlace.respuesta(3)
        enlace.leer_exacto(1, 3)
        time.sleep(0.15)
    time.sleep(0.3)
    errores = 0
    for i in range(256):
        b = (i * 167 + 13) & 0xFF   # los 256 valores, mezclados
        enlace.ser.write(b"W\x01" + bytes([b]))
        r = enlace.respuesta(5)
        if r != b"K":
            print("\n  MAL: la MailStation no tomo el byte %d de 256 (el Arduino "
                  "respondio %r)." % (i + 1, r))
            return False
        enlace.ser.write(b"R\x01")
        r = enlace.respuesta(5)
        if r != b"K":
            print("\n  MAL: la MailStation tomo el byte %d pero no lo devolvio (el "
                  "Arduino respondio %r)." % (i + 1, r))
            return False
        x = enlace.leer_exacto(1, 3)
        if x != bytes([b]):
            errores += 1
            if errores <= 5:
                print("\n  MAL: fue %02X y volvio %s." % (b, x.hex().upper() or "nada"))
        barra(i + 1, 256)
    print()
    if errores:
        print("  %d de 256 bytes volvieron mal." % errores)
        return False
    print("  BIEN: 256 bytes fueron y volvieron sin errores.")
    return True


def cmd_cargar(enlace, ruta):
    datos = open(ruta, "rb").read()
    if not 1 <= len(datos) <= 16384:
        raise Error("El programa tiene que medir entre 1 y 16384 bytes.")
    print("Abri Loader en la MailStation (Aplicaciones, segunda pagina)")
    input("y despues apreta Enter aca...")
    enlace.cargar_loader(datos)
    print("Listo.")


def main():
    args = sys.argv[1:]
    if not args or args[0] not in ("enviar", "recibir", "instalar", "directo",
                                   "respaldo", "restaurar", "cargar", "cables"):
        print(__doc__)
        sys.exit(1)
    orden = args[0]
    necesita = 1 if orden in ("enviar", "recibir", "restaurar", "cargar") else 0
    if len(args) < 1 + necesita:
        print(__doc__)
        sys.exit(1)
    dato = args[1] if necesita else None
    puerto = args[1 + necesita] if len(args) > 1 + necesita else None
    try:
        if orden in ("enviar", "cargar", "restaurar") and not os.path.isfile(dato):
            raise Error("No encuentro el archivo %s" % dato)
        puerto = puerto or buscar_puerto()
        enlace = Enlace(puerto)
        print("Adaptador listo en %s." % puerto)
        if orden == "enviar":
            cmd_enviar(enlace, dato)
        elif orden == "recibir":
            cmd_recibir(enlace, dato)
        elif orden == "cargar":
            cmd_cargar(enlace, dato)
        elif orden == "cables":
            cmd_cables(enlace)
        else:
            import instalador
            instalador.ejecutar(enlace, orden, dato)
    except Error as e:
        print("\n" + str(e))
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nCancelado.")
        sys.exit(1)


if __name__ == "__main__":
    # instalador.py hace "from altaris_pc import Error": que use este mismo
    # modulo y no una segunda copia (si no, sus errores no se atrapan)
    sys.modules["altaris_pc"] = sys.modules[__name__]
    main()
