# ARCHIVOS - ver, copiar, renombrar, borrar y ejecutar archivos de los discos
REM ARCHIVOS - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 0
*ESC OFF
MA%=160:MO%=600:VI%=13
DIM NM$(MA%),SZ%(MA%),DK%(MA%),PL%(MO%),B% 40
FOR I%=1 TO MA%:NM$(I%)=STRING$(16," "):NM$(I%)="":NEXT
T$=STRING$(255," "):N$=STRING$(63," "):M$=STRING$(63," "):R$=STRING$(31," ")
A$=STRING$(20," "):T$="":N$="":M$="":R$="":A$=""
VDU 23,1,0;0;0;0;
SE%=1:ARR%=1
PROCleer
PROClista
{bucle} REPEAT
PROCmarca(TRUE)
K%=GET
PROCmarca(FALSE)
PROCtecla(K%)
UNTIL FALSE
#
DEF PROCtecla(K%)
IF K%=139 AND SE%>1 THEN SE%=SE%-1:PROCvisible
IF K%=138 AND SE%<NA% THEN SE%=SE%+1:PROCvisible
IF K%=140 THEN SE%=SE%-VI%:IF SE%<1 THEN SE%=1
IF K%=141 THEN SE%=SE%+VI%:IF SE%>NA% THEN SE%=NA%
IF K%=140 OR K%=141 THEN PROCvisible
IF NA%=0 THEN IF K%=27 OR K%=128 THEN PROCsalir
IF NA%=0 THEN ENDPROC
IF K%=13 THEN PROCabrir(SE%)
IF K%=129 THEN PROCmirar(SE%)
IF K%=130 THEN PROCcopiar(SE%)
IF K%=131 THEN PROCrenombrar(SE%)
IF K%=132 THEN PROCborrar(SE%)
IF K%=133 THEN PROCenviar(SE%)
IF K%=27 OR K%=128 THEN PROCsalir
ENDPROC
#
REM ---------------- Lista de archivos ----------------
DEF PROCdir
A%=192:X%=B% MOD 256:Y%=B% DIV 256:CALL &FFF1
ENDPROC
#
DEF PROCleer
LOCAL I%,J%,U%
NA%=0:I%=0
REPEAT
!B%=I%:PROCdir
IF ?B%=0 AND NA%<MA% THEN NA%=NA%+1:NM$(NA%)=FNcampo(B%+2):SZ%(NA%)=B%!20 AND &FFFFFF:DK%(NA%)=B%?1
I%=I%+1
UNTIL ?B%=2
!B%=&FFFF:PROCdir
LI%=(B%!2 AND &FFFF) DIV 4:NU%=B%!4 AND &FFFF
U%=0:WHILE U%<NA% AND DK%(U%+1)=0:U%=U%+1:ENDWHILE
REM Ordena los archivos del usuario por nombre
I%=2
WHILE I%<=U%
J%=I%
WHILE J%>1 AND NM$(J%)<NM$(J%-1):PROCcambia(J%,J%-1):J%=J%-1:ENDWHILE
I%=I%+1
ENDWHILE
IF SE%>NA% THEN SE%=NA%
IF SE%<1 THEN SE%=1
ENDPROC
#
DEF PROCcambia(I%,J%)
LOCAL S%
A$=NM$(I%):NM$(I%)=NM$(J%):NM$(J%)=A$
S%=SZ%(I%):SZ%(I%)=SZ%(J%):SZ%(J%)=S%
S%=DK%(I%):DK%(I%)=DK%(J%):DK%(J%)=S%
ENDPROC
#
DEF FNcampo(A%)
R$=""
WHILE ?A%>32 AND LEN(R$)<16:R$=R$+CHR$?A%:A%=A%+1:ENDWHILE
=R$
#
DEF PROClista
CLS
PRINT TAB(0,0);"ARCHIVOS";TAB(16,0);"Tu disco: ";NU%;" archivo";
IF NU%<>1 THEN PRINT "s";
PRINT ", ";LI%;" KB libres";
PRINT TAB(0,1);" Nombre";TAB(19,1);"Tamaño";TAB(29,1);"Tipo";TAB(46,1);"Disco";
PROCayudita
IF NA%=0 THEN PRINT TAB(4,6);"No hay archivos.";:ENDPROC
PROCfilas
ENDPROC
#
DEF PROCayudita
PRINT TAB(0,15);"Enter Abrir F1 Ver F2 Copiar F3 Renombrar F4 Borrar F5 PC";
ENDPROC
#
DEF PROCvisible
IF SE%<ARR% THEN ARR%=SE%:PROCfilas
IF SE%>=ARR%+VI% THEN ARR%=SE%-VI%+1:PROCfilas
ENDPROC
#
DEF PROCfilas
LOCAL I%
FOR I%=ARR% TO ARR%+VI%-1:PROCfila(I%,FALSE):NEXT
ENDPROC
#
DEF PROCfila(I%,M%)
PRINT TAB(0,2+I%-ARR%);
IF I%>NA% THEN PRINT SPC(63);:ENDPROC
IF M% THEN COLOUR 129:COLOUR 0
PRINT " ";NM$(I%);SPC(17-LEN(NM$(I%)));RIGHT$("       "+STR$(SZ%(I%)),7);"   ";FNtiponom(NM$(I%));
PRINT TAB(46,2+I%-ARR%);
IF DK%(I%) THEN PRINT "aplicaciones    "; ELSE PRINT "tuyo            ";
COLOUR 128:COLOUR 1
ENDPROC
#
DEF PROCmarca(M%)
IF NA%>0 THEN PROCfila(SE%,M%)
ENDPROC
#
REM Tipo según el nombre (para la lista)
DEF FNtiponom(N$)
LOCAL E$
E$=MID$(N$,INSTR(N$+".",".")+1)
IF E$="" THEN ="Programa      "
IF E$="TXT" THEN ="Texto         "
IF E$="REC" THEN ="Récord        "
IF E$="DAT" THEN ="Datos         "
="Archivo       "
#
REM Tipo mirando el contenido: 1 programa BASIC, 2 texto, 3 otro
DEF FNtipo(N$)
LOCAL F%,L%,C%,I%,R%,E%
F%=OPENIN N$
IF F%=0 THEN =0
E%=EXT#F%
IF E%=0 THEN CLOSE#F%:=2
L%=BGET#F%
R%=3
IF L%=0 THEN R%=1
IF L%>=4 AND L%<E% THEN PTR#F%=L%-1:IF BGET#F%=13 THEN R%=1
IF R%=3 THEN R%=FNtexto(F%)
CLOSE#F%
=R%
#
REM Mira los primeros 64 bytes: si no hay códigos de control es un texto
DEF FNtexto(F%)
LOCAL I%,C%,R%
PTR#F%=0:R%=2
WHILE I%<64 AND NOT EOF#F%
C%=BGET#F%:I%=I%+1
IF C%<32 AND C%<>9 AND C%<>10 AND C%<>13 THEN R%=3
ENDWHILE
=R%
#
REM ---------------- Acciones ----------------
DEF PROCabrir(I%)
LOCAL T%
T%=FNtipo(NM$(I%))
IF T%=1 THEN PROCejecutar(I%):ENDPROC
IF T%=2 THEN PROCmirar(I%):ENDPROC
PROCaviso("No sé abrir este archivo (no es un programa ni un texto)")
ENDPROC
#
DEF PROCejecutar(I%)
*ESC ON
CLS:PRINT "Cargando ";NM$(I%);"..."
CHAIN NM$(I%)
ENDPROC
#
REM Visor de textos: flechas, Fn+flechas para pasar páginas
DEF PROCmirar(I%)
LOCAL F%,NL%,TL%,K%,R%,T%
T%=FNtipo(NM$(I%))
IF T%=1 THEN PROCaviso("Es un programa: Enter lo ejecuta (o LOAD y LIST desde el BASIC)"):ENDPROC
IF T%=3 THEN PROCaviso("No es un archivo de texto"):ENDPROC
CLS:PRINT TAB(0,15);"Leyendo ";NM$(I%);"...";
F%=OPENIN NM$(I%)
NL%=0
WHILE NOT EOF#F% AND NL%<MO%
NL%=NL%+1:PL%(NL%)=PTR#F%:T$=GET$#F%
ENDWHILE
TL%=1
REPEAT
PTR#F%=PL%(TL%)
FOR R%=0 TO 14
IF TL%+R%<=NL% THEN T$=GET$#F% ELSE T$=""
PRINT TAB(0,R%);LEFT$(T$,63);SPC(63-LEN(LEFT$(T$,63)));
NEXT
PRINT TAB(0,15);SPC(63);TAB(0,15);NM$(I%);"  ";TL%;"-";TL%+14;" de ";NL%;TAB(40,15);"Flechas · Volver: salir";
K%=GET
IF K%=138 AND TL%+15<=NL% THEN TL%=TL%+1
IF K%=139 AND TL%>1 THEN TL%=TL%-1
IF K%=141 OR K%=32 THEN TL%=TL%+15:IF TL%+15>NL% THEN TL%=NL%-14
IF K%=140 THEN TL%=TL%-15
IF TL%<1 THEN TL%=1
UNTIL K%=27 OR K%=128 OR K%=13
CLOSE#F%
PROClista
ENDPROC
#
DEF PROCcopiar(I%)
PROCpide("Copiar "+NM$(I%)+" con el nombre: ")
IF N$="" THEN ENDPROC
PROCmayus
OSCLI "COPIAR "+NM$(I%)+" "+N$
PROCrelistar(N$)
PROCaviso("Listo: copiado como "+N$)
ENDPROC
#
DEF PROCrenombrar(I%)
IF DK%(I%) THEN PROCaviso("Los archivos de aplicaciones no se pueden cambiar (copialo)"):ENDPROC
PROCpide("Nuevo nombre para "+NM$(I%)+": ")
IF N$="" THEN ENDPROC
PROCmayus
OSCLI "RENOMBRAR "+NM$(I%)+" "+N$
PROCrelistar(N$)
ENDPROC
#
DEF PROCborrar(I%)
LOCAL K%
IF DK%(I%) THEN PROCaviso("Los archivos de aplicaciones no se pueden borrar"):ENDPROC
K%=FNpregunta("¿Borrar "+NM$(I%)+"? No se puede deshacer. (S/N)")
IF K%<>83 THEN ENDPROC
OSCLI "BORRAR "+NM$(I%)
PROCrelistar("")
ENDPROC
#
REM Envía el archivo a la PC por el cable de la impresora (*ENVIAR)
DEF PROCenviar(I%)
LOCAL K%
K%=FNpregunta("¿Enviar "+NM$(I%)+" a la PC? Prepará el cable y la PC (S/N)")
IF K%<>83 THEN ENDPROC
*ESC ON
CLS:PRINT "Enviando ";NM$(I%);" (Volver cancela)..."
OSCLI "ENVIAR "+NM$(I%)
*ESC OFF
PROClista
PROCaviso("Enviado: "+NM$(I%))
ENDPROC
#
REM Vuelve a leer el disco y elige el archivo N$ si está
DEF PROCrelistar(N$)
LOCAL I%
PROCleer
FOR I%=1 TO NA%:IF NM$(I%)=N$ THEN SE%=I%
NEXT
IF SE%<ARR% OR SE%>=ARR%+VI% THEN ARR%=SE%
PROClista
ENDPROC
#
REM ---------------- Mensajes ----------------
DEF PROCaviso(M$)
LOCAL K%
PRINT TAB(0,15);SPC(63);TAB(0,15);LEFT$(M$,63);
K%=GET
PROCayudita
ENDPROC
#
DEF FNpregunta(M$)
LOCAL K%
PRINT TAB(0,15);SPC(63);TAB(0,15);LEFT$(M$,63);
K%=GET
IF K%>=97 AND K%<=122 THEN K%=K%-32
PROCayudita
=K%
#
DEF PROCpide(M$)
PRINT TAB(0,15);SPC(63);
VDU 28,0,15,63,15,12,23,1,1;0;0;0;
PRINT M$;
INPUT LINE "" N$
VDU 26,23,1,0;0;0;0;
WHILE LEFT$(N$,1)=" ":N$=MID$(N$,2):ENDWHILE
PROCayudita
ENDPROC
#
DEF PROCmayus
LOCAL I%,C%
FOR I%=1 TO LEN(N$)
C%=ASC(MID$(N$,I%,1))
IF C%>=97 AND C%<=122 THEN MID$(N$,I%,1)=CHR$(C%-32)
NEXT
ENDPROC
#
DEF PROCsalir
*ESC ON
CHAIN "MENU"
ENDPROC
#
{error} CLOSE#0:VDU 26,23,1,0;0;0;0;
*ESC OFF
IF ERR=17 THEN M$="Cancelado" ELSE M$=REPORT$
PROCleer:PROClista
PROCaviso(M$)
GOTO {bucle}
