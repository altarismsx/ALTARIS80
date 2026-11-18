;
; ALTARIS 80 - definiciones comunes
; Mapa de memoria, puertos y variables fijas del sistema.
;
; Memoria de la CPU:
;   0000-3FFF  pagina 0 de la flash de programa (nucleo)       fija
;   4000-7FFF  ranura A: BASIC (pagina 4) o bancos del sistema
;   8000-BFFF  ranura B: RAM pagina 1 (BASIC) o dispositivos
;   C000-FFFF  RAM pagina 0                                     fija
;
; RAM pagina 0 (fija):
;   8000-F4FF  programa BASIC, variables y pila (PAGE..HIMEM)
;   F500-F7FF  area de datos del interprete (modulo DATA)
;   F800-FFFF  variables del sistema
;
; Dispositivos de las ranuras (puertos 06h/08h)
DEVCF	EQU	0		;flash de programa
DEVRAM	EQU	1		;RAM
DEVLCDL	EQU	2		;pantalla, mitad izquierda
DEVDF	EQU	3		;flash de datos
DEVLCDR	EQU	4		;pantalla, mitad derecha
;
; Paginas de la flash de programa
PGCORE	EQU	0
PGBASIC	EQU	4
PGVDU	EQU	5
PGFS	EQU	6
PGBOOT	EQU	7
PGROMD	EQU	8		;comienzo del disco de aplicaciones
;
; Paginas de RAM
RPMAIN	EQU	1		;RAM del BASIC en 8000-BFFF
RPVDU	EQU	2		;pantalla virtual y estado del video
RPFS	EQU	3		;buffers del sistema de archivos
;
; Puertos
PKEYB	EQU	01H		;filas/columnas del teclado
PMISC2	EQU	02H		;LCD, LED, CAS, filas 8-9
PIRQ	EQU	03H		;mascara de interrupciones
PSLAPG	EQU	05H		;ranura A: pagina
PSLADV	EQU	06H		;ranura A: dispositivo
PSLBPG	EQU	07H		;ranura B: pagina
PSLBDV	EQU	08H		;ranura B: dispositivo
PMISC9	EQU	09H		;alimentacion, boton, control impresora
PDIR9	EQU	0AH
PDIR2	EQU	0BH
PSPEED	EQU	0DH		;velocidad CPU y frecuencia del timer
PRTC	EQU	10H		;reloj (10H-1CH)
PRTCD	EQU	1DH
PRTCE	EQU	1EH
PRTCF	EQU	1FH
PLPTST	EQU	21H		;estado del puerto paralelo
PMISC28	EQU	28H		;apagado
PDIR28	EQU	29H
PLPTDIR	EQU	2CH		;direccion de los datos del paralelo
PLPTDAT	EQU	2DH		;datos del paralelo
PIRQSP	EQU	2FH
;
; Valores iniciales (tomados del firmware original)
P2INIT	EQU	87H		;LCD encendido, modem apagado, filas 8-9 libres
SPEED	EQU	22H		;12 MHz, timer de 64 Hz
IRQON	EQU	02H		;solo el timer rapido
;
; Codigos de teclas
KESC	EQU	1BH
KDEL	EQU	7FH
KCOPY	EQU	87H		;Imprimir
KMENU	EQU	80H		;Menu
KF1	EQU	81H		;F1..F5 = 81H..85H
KLEFT	EQU	88H
KRIGHT	EQU	89H
KDOWN	EQU	8AH
KUP	EQU	8BH
KPGUP	EQU	8CH
KPGDN	EQU	8DH
KHOME	EQU	8EH
KEND	EQU	8FH
;
; ---------------- Variables fijas (F800-FFFF) ----------------
;
BOUNCE	EQU	0F800H		;buffer de intercambio, 256 bytes
CMDBUF	EQU	0F900H		;copia de comandos y nombres, 256 bytes
SCRAP	EQU	0FA00H		;bloques de parametros OSWORD, 64 bytes
;
; Estado de bancos y pila del sistema
SVSP	EQU	0FA40H		;pila del llamador
SVSLA	EQU	0FA42H		;ranura A guardada (pagina, dispositivo)
SVSLB	EQU	0FA44H		;ranura B guardada
INMOS	EQU	0FA46H		;1 = ejecutando en un banco
BNKADR	EQU	0FA47H		;direccion a llamar en el banco
BNKPG	EQU	0FA49H		;pagina del banco
RETA	EQU	0FA4AH		;registros de retorno
RETHL	EQU	0FA4BH
RETDE	EQU	0FA4DH
RETBC	EQU	0FA4FH
SHAD2	EQU	0FA51H		;sombra del puerto 02H
SHAD3	EQU	0FA52H		;sombra del puerto 03H
SHAD9	EQU	0FA53H		;sombra del puerto 09H
SHAD28	EQU	0FA54H		;sombra del puerto 28H
CURAPG	EQU	0FA56H		;ranura A actual: pagina
CURADV	EQU	0FA57H		;                 dispositivo
CURBPG	EQU	0FA58H		;ranura B actual: pagina
CURBDV	EQU	0FA59H		;                 dispositivo
BKHL	EQU	0FA5AH		;BANK: HL del llamador
BKAF	EQU	0FA5CH		;BANK: AF del llamador
BKIFF	EQU	0FA5EH		;reservado
;
; Teclado
KMAT	EQU	0FA60H		;estado actual de la matriz, 10 bytes
KPREV	EQU	0FA6AH		;estado anterior, 10 bytes
KBUF	EQU	0FA74H		;buffer circular de 32 teclas
KBHEAD	EQU	0FA94H
KBTAIL	EQU	0FA95H
KCAPS	EQU	0FA96H		;bloqueo de mayusculas
KLAST	EQU	0FA97H		;ultima tecla (codigo de matriz)
KRPT	EQU	0FA98H		;contador de repeticion
KCHR	EQU	0FA99H		;caracter que se repite
KSHIFT	EQU	0FA9AH		;estado de Shift/Fn (bit0 shift, bit1 fn)
PWRCNT	EQU	0FA9BH		;contador del boton de encendido
PWRARM	EQU	0FA9CH		;boton liberado desde el arranque
;
; Tiempo
TICKS	EQU	0FAA0H		;contador libre de interrupciones, 4 bytes
TIMECS	EQU	0FAA4H		;TIME en centesimas, 4 bytes
TACC	EQU	0FAA8H		;acumulador de fraccion
TPS	EQU	0FAA9H		;interrupciones por segundo (64 o 128)
LEDCNT	EQU	0FAAAH		;duracion del destello del LED
;
; Interprete y sistema operativo
FLAGS	EQU	0FAB0H		;bit7 ESC pendiente, bit6 ESC desactivado,
				;bit3 modo EDIT, bit4 sobreescribir,
				;bit1 SPOOL, bit0 EXEC
INKEY	EQU	0FAB1H
EDPTR	EQU	0FAB2H
OPTVAL	EQU	0FAB4H
TRPCNT	EQU	0FAB5H
SPLCH	EQU	0FAB6H		;canal de SPOOL
EXECH	EQU	0FAB7H		;canal de EXEC
WARMSG	EQU	0FAB8H		;firma de arranque en caliente, 4 bytes
KBAR	EQU	0FABCH		;barra de teclas: 1 = activada
KBARON	EQU	0FABDH		;barra dibujada en pantalla
FKPTR	EQU	0FABEH		;puntero a texto de tecla de funcion en curso
FKLEN	EQU	0FAC0H		;caracteres restantes
CSRVIS	EQU	0FAC1H		;cursor visible al esperar tecla
VDUQ	EQU	0FAC2H		;reservado
BOOTFL	EQU	0FAC3H		;banderas de arranque
LPTMODE	EQU	0FAC4H		;reservado para transferencias
FSERRN	EQU	0FAC5H		;ultimo error del disco (0 = ninguno)
ERRBUF	EQU	0FFC0H		;texto del ultimo error del sistema, 32 bytes
CSRTCK	EQU	0FAC6H		;ultimo cambio del cursor
CSRST	EQU	0FAC7H		;cursor dibujado
LCROW	EQU	0FAC8H		;2 bytes: filas, primera fila (copia al LCD)
EXPRV	EQU	0FACAH		;ultimo caracter leido por EXEC
LASTLN	EQU	0FEC0H		;ultima linea escrita, 64 bytes
KEYSTR	EQU	0FF00H		;teclas de funcion: 6 x 32 bytes (largo + texto)
;
; Area de trabajo del disco (FB00-FBFF)
FSWORK	EQU	0FB00H
;
; Pila del sistema (crece hacia abajo desde MOSTOP)
MOSSTK	EQU	0FC00H
MOSTOP	EQU	0FE00H
;
; Variables de los modulos (FE00-FFDF)
DSKVAR	EQU	0FE00H		;sistema de archivos, 128 bytes
VDUVAR	EQU	0FE80H		;copia rapida del estado de video, 64 bytes
;
; Tabla de saltos estilo Acorn para codigo de usuario (FFE0-FFFF)
JOSRDCH	EQU	0FFE0H
JOSWRCH	EQU	0FFEEH
JOSWORD	EQU	0FFF1H
JOSBYTE	EQU	0FFF4H
JOSCLI	EQU	0FFF7H
;
; Limites de memoria del BASIC
BPAGE	EQU	08000H
BHIMEM	EQU	0F500H
BDATA	EQU	0F500H
;
; Entradas de los bancos (primeros bytes de cada banco)
; Banco de video (PGVDU)
V_INIT	EQU	4000H		;inicializar video
V_WRCH	EQU	4003H		;escribir caracter A
V_CSRON	EQU	4006H		;mostrar cursor
V_CSROFF EQU	4009H		;ocultar cursor
V_WORD	EQU	400CH		;OSWORD A, HL=bloque
V_BYTE	EQU	400FH		;OSBYTE A, L, H
V_KBAR	EQU	4012H		;dibujar barra de teclas (A=1) o quitarla
V_STATE	EQU	4015H		;leer estado (A=0 X, 1 Y, 2 modo, 3 ancho)
V_BOOT	EQU	4018H		;servicios para la pantalla de arranque
;
; Banco del sistema de archivos (PGFS)
F_INIT	EQU	4000H		;montar disco
F_OPEN	EQU	4003H		;abrir archivo
F_CLOSE	EQU	4006H		;cerrar archivo
F_BGET	EQU	4009H		;leer byte
F_BPUT	EQU	400CH		;escribir byte
F_STAT	EQU	400FH		;fin de archivo
F_EXT	EQU	4012H		;largo
F_PTR	EQU	4015H		;leer puntero
F_SPTR	EQU	4018H		;mover puntero
F_LOAD	EQU	401BH		;cargar archivo en memoria
F_SAVE	EQU	401EH		;grabar memoria en archivo
F_CMD	EQU	4021H		;comandos * del disco
F_KEYS	EQU	4024H		;textos de teclas de funcion
F_FREE	EQU	4027H		;espacio libre
;
; Codigos de error del disco (A con CY=1)
EFNF	EQU	1		;archivo no encontrado
EFULL	EQU	2		;disco lleno
EMANY	EQU	3		;demasiados archivos abiertos
ECHAN	EQU	4		;canal invalido
ERO	EQU	5		;solo lectura
ENAME	EQU	6		;nombre invalido
EEXIST	EQU	7		;ya existe
EDISK	EQU	8		;error de disco
EDIRF	EQU	9		;directorio lleno
EBIG	EQU	10		;demasiado grande
EOPEN	EQU	11		;archivo abierto
EEOF	EQU	12		;fin de archivo
EXFER	EQU	13		;error de transmision
ECANC	EQU	14		;cancelado
;
; Banco de arranque (PGBOOT)
B_START	EQU	4000H		;pantalla de arranque
