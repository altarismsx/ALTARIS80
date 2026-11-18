"""
Instalacion de ALTARIS 80, respaldo y restauracion de la memoria de la
MailStation. Lo usa altaris_pc.py (instalar, respaldo, restaurar).

Pasos de la instalacion:
  1. Se manda INSTALAR.BIN al Loader del firmware original.
  2. Se identifica la memoria de programa (tiene que ser una 29F080).
  3. Se copian a la PC la memoria de programa (1 MB) y la de datos (512 KB):
     es el respaldo, un archivo de 1,5 MB.
  4. Se borra y se graba ALTARIS 80, pagina por pagina, comprobando cada una.
  5. Se reinicia la MailStation.

Si algo se corta despues del paso 1, la MailStation sigue esperando ordenes
mientras no se apague: se puede volver a ejecutar el mismo comando.
"""
import os
import time

from altaris_pc import Error, barra

AQUI = os.path.dirname(os.path.abspath(__file__))
KIT = os.path.dirname(AQUI)
PAGINA = 16384
PAGINAS = 64            # memoria de programa: 1 MB
PAGINAS_DATOS = 32      # memoria de datos: 512 KB
TAM_PROGRAMA = PAGINAS * PAGINA
TAM_RESPALDO = (PAGINAS + PAGINAS_DATOS) * PAGINA
FABRICANTES = {0x01: "AMD", 0x04: "Fujitsu", 0x20: "ST", 0xC2: "Macronix",
               0x1F: "Atmel", 0xBF: "SST", 0x37: "AMIC"}


def suma16(datos):
    return sum(datos) & 0xFFFF


def pregunta(texto):
    r = input(texto + " ").strip().upper()
    return r in ("S", "SI", "SÍ")


def leer_archivo(ruta):
    try:
        return open(ruta, "rb").read()
    except OSError as e:
        raise Error("No pude leer %s: %s" % (ruta, e))


class Instalador:
    def __init__(self, enlace):
        self.e = enlace
        self.version = 0

    def orden(self, letra, *args):
        self.e.mandar(letra.encode() + bytes(args))

    def respuesta(self, segundos=30):
        return self.e.recibir(1, espera_inicio=segundos)

    def ping(self):
        """None si el instalador de la MailStation contesta; si no, 'envio'
        (no tomo la orden) o 'respuesta' (la tomo pero no llega la respuesta)."""
        try:
            self.orden("P")
        except Error:
            return "envio"
        try:
            r = self.respuesta(10)
        except Error:
            return "respuesta"
        return None if r == b"K" else "respuesta"

    def cargar(self):
        print()
        print("En la MailStation: Aplicaciones, segunda pagina, elegi Loader y "
              "apreta Enter.")
        print("La pantalla NO cambia: sigue mostrando el icono de Loader. Asi esta bien.")
        print("Unico caso distinto: si la pantalla ya dice 'ALTARIS 80 - INSTALADOR'")
        print("(quedo de un intento anterior), no abras nada y escribi 2.")
        r = input("\nApreta Enter para seguir (o escribi 2 y Enter): ").strip()
        if r == "2":
            if self.ping():
                raise Error("La MailStation no contesto: el instalador no esta "
                            "cargado.\nApreta RESET atras de la MailStation, elegi "
                            "'No borrar', abri Loader y volve a empezar apretando "
                            "solo Enter.\nSi la pantalla si decia 'ALTARIS 80 - "
                            "INSTALADOR', hace la prueba de cables: PROBAR_CABLES.BAT.")
            return
        datos = leer_archivo(os.path.join(KIT, "INSTALAR.BIN"))
        print("Mandando el instalador:")
        self.e.cargar_loader(datos)
        time.sleep(1)
        falla = self.ping()
        if falla == "envio":
            raise Error("El instalador no arranco. Apreta RESET atras de la "
                        "MailStation, elegi 'No borrar', abri Loader y proba de "
                        "nuevo.")
        if falla:
            raise Error("El instalador llego a la MailStation, pero su respuesta no "
                        "llega a la PC.\nLa respuesta vuelve por los cables de los "
                        "pines 2, 3, 4, 6 y 10 del DB25\n(D2, D3, D4, D6 y D7 del "
                        "Arduino). Hace la prueba de cables: PROBAR_CABLES.BAT.\n"
                        "Antes: boton RESET atras de la MailStation, 'No borrar'.")

    def identificar(self):
        self.orden("I")
        r = self.e.recibir(6, espera_inicio=10)
        if r[:3] != b"ALT":
            raise Error("El instalador contesto algo raro (%r)." % r)
        fab, disp, self.version = r[3], r[4], r[5]
        nombre = FABRICANTES.get(fab, "fabricante %02X" % fab)
        print("Memoria de programa: %s, chip %02X." % (nombre, disp))
        if disp != 0xD5:
            raise Error("No conozco ese chip de memoria (se esperaba un 29F080, "
                        "codigo D5). No se cambio nada: apreta RESET en la "
                        "MailStation para volver al firmware original.")

    def volcar_pagina(self, p, letra="D"):
        for intento in range(3):
            self.orden(letra, p)
            datos = self.e.recibir(PAGINA, espera_inicio=10)
            s = self.e.recibir(2)
            if (s[0] | (s[1] << 8)) == suma16(datos):
                return datos
        raise Error("La pagina %d llego con errores tres veces. Revisa el cable." % p)

    def pedir_datos(self):
        if self.version < 2:
            raise Error("El instalador de la MailStation es viejo: no maneja la "
                        "memoria de datos. Usa INSTALAR.BIN de este kit.")

    def respaldo(self):
        self.pedir_datos()
        nombre = time.strftime("respaldo_mailstation_%Y%m%d_%H%M.bin")
        print("\nCopiando la memoria de la MailStation a la PC (%s)." % nombre)
        print("Tarda unos 3 minutos.")
        imagen = bytearray()
        t0 = time.time()
        total = PAGINAS + PAGINAS_DATOS
        for p in range(PAGINAS):
            imagen += self.volcar_pagina(p)
            barra(p + 1, total, "programa: pagina %d de %d " % (p + 1, PAGINAS))
        for p in range(PAGINAS_DATOS):
            imagen += self.volcar_pagina(p, "d")
            barra(PAGINAS + p + 1, total, "datos: pagina %d de %d   "
                  % (p + 1, PAGINAS_DATOS))
        print("\nListo en %d segundos." % (time.time() - t0))
        if imagen[:16] == b"\xff" * 16:
            raise Error("El respaldo salio vacio: algo anda mal. No se grabo nada.")
        open(nombre, "wb").write(imagen)
        print("Respaldo guardado en %s. Guardalo bien: sirve para volver al "
              "firmware original con 'restaurar'." % os.path.abspath(nombre))
        return bytes(imagen)

    def grabar(self, imagen, todas=False):
        """Graba la imagen (multiplo de 16 KB). Sin 'todas' se saltean las
        paginas que quedan en FF despues de borrar."""
        n = len(imagen) // PAGINA
        sectores = (n + 3) // 4
        trabajo = [(s, [p for p in range(4 * s, min(4 * s + 4, n))
                        if todas or imagen[p * PAGINA:(p + 1) * PAGINA] != b"\xff" * PAGINA])
                   for s in range(sectores)]
        total = sum(1 + len(ps) for s, ps in trabajo)
        hecho = 0
        t0 = time.time()
        for s, ps in trabajo:
            self.orden("E", s)
            r = self.respuesta(60)
            if r != b"K":
                raise Error("No se pudo borrar el sector %d (respuesta %r). NO "
                            "APAGUES la MailStation: volve a ejecutar el mismo "
                            "comando." % (s, r))
            hecho += 1
            barra(hecho, total, "sector %d       " % s)
            for p in ps:
                datos = imagen[p * PAGINA:(p + 1) * PAGINA]
                s16 = suma16(datos)
                for intento in range(5):
                    self.e.mandar(b"W" + bytes([p]) + datos + bytes([s16 & 0xFF, s16 >> 8]))
                    r = self.respuesta(60)
                    if r != b"N":
                        break
                if r != b"K":
                    raise Error("La pagina %d no quedo bien grabada (respuesta %r). "
                                "NO APAGUES la MailStation: volve a ejecutar el "
                                "mismo comando." % (p, r))
                hecho += 1
                barra(hecho, total, "pagina %d       " % p)
        print("\nGrabado en %d segundos." % (time.time() - t0))

    def grabar_datos(self, imagen):
        """Graba la memoria de datos (512 KB). La MailStation solo borra y
        graba los sectores que cambian."""
        self.pedir_datos()
        t0 = time.time()
        for p in range(PAGINAS_DATOS):
            datos = imagen[p * PAGINA:(p + 1) * PAGINA]
            s16 = suma16(datos)
            for intento in range(5):
                self.e.mandar(b"w" + bytes([p]) + datos + bytes([s16 & 0xFF, s16 >> 8]))
                r = self.respuesta(120)
                if r != b"N":
                    break
            if r != b"K":
                raise Error("La pagina de datos %d no quedo bien grabada (respuesta "
                            "%r). NO APAGUES la MailStation: volve a ejecutar el "
                            "mismo comando." % (p, r))
            barra(p + 1, PAGINAS_DATOS, "datos: pagina %d de %d" % (p + 1, PAGINAS_DATOS))
        print("\nMemoria de datos grabada en %d segundos." % (time.time() - t0))

    def reiniciar(self):
        self.orden("X")
        self.respuesta(10)


def imagen_altaris():
    datos = leer_archivo(os.path.join(KIT, "ALTARIS80.BIN"))
    if len(datos) % PAGINA or not datos:
        raise Error("ALTARIS80.BIN esta danado (largo %d)." % len(datos))
    return datos


def ejecutar(enlace, orden, archivo):
    enlace.pedir_version2()
    inst = Instalador(enlace)
    sin_respaldo = os.environ.get("ALTARIS_SIN_RESPALDO") == "1"   # solo pruebas
    if orden == "directo":          # instalar sin guardar el firmware original
        orden = "instalar"
        sin_respaldo = True
    datos = None
    if orden == "restaurar":
        imagen = leer_archivo(archivo)
        if len(imagen) == TAM_RESPALDO:
            imagen, datos = imagen[:TAM_PROGRAMA], imagen[TAM_PROGRAMA:]
        elif len(imagen) != TAM_PROGRAMA:
            raise Error("El respaldo tiene que medir 1,5 MB (%d bytes) o, si es "
                        "solo de la memoria de programa, 1 MB (%d bytes)."
                        % (TAM_RESPALDO, TAM_PROGRAMA))
    elif orden == "instalar":
        imagen = imagen_altaris()
    print("ANTES DE EMPEZAR: conecta la fuente de la MailStation (no uses solo "
          "las pilas).")
    inst.cargar()
    inst.identificar()
    if orden == "respaldo":
        inst.respaldo()
        print("\nReiniciando la MailStation.")
        inst.reiniciar()
        return
    if not sin_respaldo:
        inst.respaldo()
    print()
    if orden == "instalar" and sin_respaldo:
        print("Ahora se borra la memoria de programa y se graba ALTARIS 80.")
        print("NO se guarda respaldo de lo que tiene ahora (si es el firmware "
              "original, se pierde para siempre).")
        print("Tus archivos del disco interno no se tocan.")
    elif orden == "instalar":
        print("Ahora se borra el firmware original y se graba ALTARIS 80.")
    else:
        print("Ahora se borra la memoria de programa y se graba el respaldo%s."
              % (" (despues, la de datos)" if datos else ""))
    print("Desde este momento NO APAGUES NI DESCONECTES la MailStation.")
    if not pregunta("¿Seguir? (escribi SI)"):
        print("No se cambio nada. Reiniciando la MailStation.")
        inst.reiniciar()
        return
    inst.grabar(imagen, todas=(orden == "restaurar"))
    if datos:
        inst.grabar_datos(datos)
    print("Reiniciando la MailStation...")
    inst.reiniciar()
    if orden == "instalar":
        print("\nListo. ALTARIS 80 arranca solo. La primera vez prepara el "
              "disco interno.")
    else:
        print("\nListo. La MailStation tiene otra vez el firmware del respaldo.")
