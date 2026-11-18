# MENU - menu principal de ALTARIS 80
# (C) 2026 Altaris Software
# M% (variable residente) recuerda el ultimo programa elegido.
# La lista: los juegos, "-", las utilidades, "*" (hasta 11 por columna).
REM ALTARIS 80 - Menu principal
ON ERROR GOTO {errores}
MODE 0:VDU 23,1,0;0;0;0;
DIM N$(22),F$(22),D$(22)
RESTORE {lista}
NJ%=0:NT%=0
{leer} READ A$
IF A$="*" THEN GOTO {listo}
IF A$="-" THEN NJ%=NT%:GOTO {leer}
NT%=NT%+1:N$(NT%)=A$:READ F$(NT%),D$(NT%):GOTO {leer}
{listo} NU%=NT%-NJ%
IF M%<1 OR M%>NT% THEN M%=1
PROCmarco
msg$=""
{bucle} REPEAT
PROCitem(M%,TRUE):PROCdesc
REPEAT:PROCreloj:K%=INKEY(25):UNTIL K%>0
msg$=""
PROCitem(M%,FALSE)
IF K%=139 THEN M%=FNarriba(M%)
IF K%=138 THEN M%=FNabajo(M%)
IF K%=136 OR K%=137 THEN M%=FNcostado(M%)
UNTIL K%=13 OR K%=32
PROCitem(M%,TRUE)
msg$="Cargando "+N$(M%)+"...":PROCdesc
VDU 23,1,1;0;0;0;
CHAIN F$(M%)
END
#
DEF PROCmarco
LOCAL I%
CLS
VDU 31,0,0,138:PRINT STRING$(62,CHR$136);CHR$139;
VDU 31,3,0:PRINT " ALTARIS 80 · Menú principal ";
FOR I%=1 TO 14:VDU 31,0,I%,137,31,63,I%,137:NEXT
FOR I%=1 TO 12:VDU 31,31,I%,137:NEXT
VDU 31,31,0,144
VDU 31,0,13,142:PRINT STRING$(30,CHR$136);CHR$145;STRING$(31,CHR$136);CHR$143;
VDU 31,0,15,140:PRINT STRING$(62,CHR$136);CHR$141;
VDU 31,3,15:PRINT " Flechas: elegir · Enter: ejecutar · Volver: BASIC ";
VDU 31,3,1:PRINT "JUEGOS";
VDU 31,34,1:PRINT "UTILIDADES";
FOR I%=1 TO NT%:PROCitem(I%,FALSE):NEXT
ENDPROC
#
REM Moverse por las dos columnas (juegos 1..NJ%, utilidades NJ%+1..NT%)
DEF FNarriba(I%)
IF I%=1 THEN =NJ%
IF I%=NJ%+1 THEN =NT%
=I%-1
#
DEF FNabajo(I%)
IF I%=NJ% THEN =1
IF I%=NT% THEN =NJ%+1
=I%+1
#
DEF FNcostado(I%)
IF I%<=NJ% THEN =NJ%+FNmenor(I%,NU%)
=FNmenor(I%-NJ%,NJ%)
#
DEF FNmenor(A%,B%)
IF A%<B% THEN =A%
=B%
#
DEF PROCitem(I%,S%)
LOCAL X%,Y%
X%=2:Y%=1+I%
IF I%>NJ% THEN X%=33:Y%=1+I%-NJ%
VDU 31,X%,Y%
IF S% THEN COLOUR 129:COLOUR 0
PRINT " ";LEFT$(N$(I%)+STRING$(27," "),27);" ";
COLOUR 128:COLOUR 1
ENDPROC
#
DEF PROCdesc
LOCAL T$
T$=msg$:IF T$="" THEN T$=D$(M%)
VDU 31,2,14:PRINT LEFT$(T$+STRING$(60," "),60);
ENDPROC
#
DEF PROCreloj
VDU 31,55,0:PRINT " ";MID$(TIME$,17,5);" ";
ENDPROC
#
{errores} IF ERR=17 THEN MODE 0:VDU 23,1,1;0;0;0;:PRINT "BASIC listo. Tecla MENU: volver al menú.":END
IF ERR=214 OR ERR=190 THEN msg$="No se pudo cargar "+F$(M%)+": "+REPORT$:VDU 23,1,0;0;0;0;:GOTO {bucle}
MODE 0:VDU 23,1,1;0;0;0;:REPORT:PRINT " (línea ";ERL;")":END
#
{lista} DATA "Tateti 3D","TATETI3D","Ta-te-ti en un cubo de 3x3x3 contra la computadora"
DATA "Pulsenoid","PULSENOID","Rompé los ladrillos con la nave OVNI"
DATA "Che Fénix","CHEFENIX","Defendé la Tierra de los pájaros invasores"
DATA "Rocket Car","ROCKETCAR","Piloteá el auto cohete por la caverna"
DATA "Viborita","VIBORITA","La víbora come y crece: no choques"
DATA "Bloques","BLOQUES","Encajá las piezas que caen y completá líneas"
DATA "Buscaminas","BUSCAMIN","Encontrá todas las minas sin pisarlas"
DATA "Ahorcado","AHORCADO","Adiviná la palabra antes de que te ahorquen"
DATA "-"
DATA "Reloj","RELOJ","Hora y fecha en números grandes"
DATA "Calendario","CALEND","Calendario de cualquier mes y año"
DATA "Calculadora","CALC","Calculadora con memoria e historial"
DATA "Notas","NOTAS","Editor de textos: escribí y guardá tus notas"
DATA "Agenda","AGENDA","Nombres, teléfonos y direcciones"
DATA "Dibujo","DIBUJO","Dibujá con el cursor y guardá tus dibujos"
DATA "Gráficos","GRAFICO","Dibuja funciones matemáticas"
DATA "Demos","DEMOS","Demostraciones gráficas"
DATA "Ayuda","AYUDA","Guía del BASIC y de los comandos del sistema"
DATA "Archivos","ARCHIVOS","Ver, copiar, renombrar y borrar archivos"
DATA "*"
