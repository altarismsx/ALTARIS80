# DIBUJO - dibujá con el cursor; grabá y abrí tus dibujos (.PAN)
REM DIBUJO - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 0
*ESC OFF
VDU 23,1,0;0;0;0;
DIM LI$(42),B% 40,TN$(5),AY$(4)
FOR I%=1 TO 42:LI$(I%)=STRING$(16," "):LI$(I%)="":NEXT
N$=STRING$(63," "):M$=STRING$(63," "):R$=STRING$(31," "):NOM$=STRING$(20," ")
N$="":M$="":R$="":NOM$=""
RESTORE {datos}
FOR I%=0 TO 5:READ TN$(I%):NEXT
FOR I%=1 TO 4:READ AY$(I%):NEXT
CX%=160:CY%=68:PL%=FALSE:CO%=1:HE%=0:AN%=FALSE:FIN%=FALSE:CAMB%=FALSE:HC%=0
PROCportada
CLS
VDU 24,0;8;319;127;
CLG
PROCestado
{bucle} REPEAT
PROCmira
REPEAT
K%=INKEY(2)
MV%=INKEY(-26) OR INKEY(-122) OR INKEY(-58) OR INKEY(-42)
UNTIL K%>=0 OR MV%
PROCmira
IF MV% THEN PROCmover ELSE HC%=0
IF (K%>=0 AND K%<136) OR K%>139 THEN PROCtecla(K%)
*FX 15
UNTIL FALSE
#
DEF PROCportada
LOCAL I%,K%
CLS
PRINT TAB(24,1);"D I B U J O"
PRINT TAB(21,3);"Altaris Software ";CHR$169;" 2026"
FOR I%=1 TO 4:PRINT TAB(1,4+I%*2);AY$(I%);:NEXT
PRINT TAB(1,14);"H muestra la ayuda en la última línea mientras dibujás."
PRINT TAB(18,15);"Apretá una tecla para empezar";
K%=GET
ENDPROC
#
REM Cursor (cruz con el centro libre) y la figura en preparación, en modo XOR
DEF PROCmira
GCOL 3,1
IF AN% THEN PROCforma
MOVE CX%-4,CY%:DRAW CX%-2,CY%:MOVE CX%+2,CY%:DRAW CX%+4,CY%
MOVE CX%,CY%-4:DRAW CX%,CY%-2:MOVE CX%,CY%+2:DRAW CX%,CY%+4
ENDPROC
#
REM Figura desde el punto marcado (AX%,AY%) hasta el cursor
DEF PROCforma
LOCAL X%,Y%,W%,H%
IF HE%=1 THEN MOVE AX%,AY%:DRAW CX%,CY%:ENDPROC
IF HE%=3 THEN CIRCLE AX%,AY%,FNradio:ENDPROC
IF HE%=5 THEN IF FIN% THEN CIRCLE FILL AX%,AY%,FNradio:ENDPROC
IF HE%=5 THEN CIRCLE AX%,AY%,FNradio:ENDPROC
X%=AX%:W%=CX%-AX%:IF W%<0 THEN X%=CX%:W%=-W%
Y%=AY%:H%=CY%-AY%:IF H%<0 THEN Y%=CY%:H%=-H%
IF HE%=4 AND FIN% THEN RECTANGLE FILL X%,Y%,W%,H% ELSE RECTANGLE X%,Y%,W%,H%
ENDPROC
#
DEF FNradio
=INT(SQR((CX%-AX%)^2+(CY%-AY%)^2)+0.5)
#
REM Mueve el cursor; si se mantiene la flecha va cada vez más rápido
DEF PROCmover
LOCAL S%,OX%,OY%
HC%=HC%+1:S%=1
IF HC%>6 THEN S%=2
IF HC%>16 THEN S%=4
OX%=CX%:OY%=CY%
IF INKEY(-26) THEN CX%=CX%-S%
IF INKEY(-122) THEN CX%=CX%+S%
IF INKEY(-58) THEN CY%=CY%+S%
IF INKEY(-42) THEN CY%=CY%-S%
IF CX%<0 THEN CX%=0
IF CX%>319 THEN CX%=319
IF CY%<8 THEN CY%=8
IF CY%>127 THEN CY%=127
IF PL% THEN GCOL 0,CO%:MOVE OX%,OY%:DRAW CX%,CY%:CAMB%=TRUE
PROCcoord
ENDPROC
#
DEF PROCtecla(K%)
IF K%>=97 AND K%<=122 THEN K%=K%-32
IF K%=32 THEN PL%=NOT PL%:PROCestado:IF PL% THEN GCOL 0,CO%:PLOT 69,CX%,CY%:CAMB%=TRUE
IF K%=76 THEN PROCherr(1)
IF K%=82 THEN PROCherr(2)
IF K%=67 THEN PROCherr(3)
IF K%=70 THEN PROCherr(4)
IF K%=68 THEN PROCherr(5)
IF K%=13 AND AN% THEN PROCfinal
IF K%=66 THEN CO%=1-CO%:PROCestado
IF K%=84 THEN PROCtexto
IF K%=71 THEN PROCgrabar
IF K%=65 THEN PROCabrir
IF K%=78 THEN PROCnuevo
IF K%=72 OR K%=63 THEN PROCayuda
IF K%=27 OR K%=128 THEN PROCvolver
ENDPROC
#
REM Herramientas: la primera vez marca el punto, la segunda termina la figura
DEF PROCherr(H%)
IF AN% AND HE%=H% THEN PROCfinal:ENDPROC
IF NOT AN% THEN AX%=CX%:AY%=CY%
AN%=TRUE:HE%=H%
PROCestado
ENDPROC
#
DEF PROCfinal
GCOL 0,CO%:FIN%=TRUE
PROCforma
FIN%=FALSE:AN%=FALSE:HE%=0:CAMB%=TRUE
PROCestado
ENDPROC
#
DEF PROCvolver
IF AN% THEN AN%=FALSE:HE%=0:PROCestado:ENDPROC
PROCsalir
ENDPROC
#
REM ---------------- Línea de estado ----------------
DEF PROCestado
PRINT TAB(0,15);"Lápiz:";
IF PL% THEN PRINT "abajo "; ELSE PRINT "arriba";
PRINT "  Tinta:";
IF CO% THEN PRINT "negra "; ELSE PRINT "blanca";
PRINT "  ";TN$(HE%);SPC(11-LEN(TN$(HE%)));
PROCcoord
PRINT TAB(53,15);"H = ayuda ";
ENDPROC
#
DEF PROCcoord
PRINT TAB(40,15);"x:";RIGHT$("  "+STR$(CX%),3);" y:";RIGHT$("  "+STR$(CY%),3);" ";
ENDPROC
#
DEF PROCayuda
LOCAL I%,K%
I%=1
REPEAT
PRINT TAB(0,15);SPC(63);TAB(0,15);AY$(I%);
K%=GET
I%=I%+1
UNTIL I%>4 OR (K%<>72 AND K%<>104 AND K%<>32 AND K%<>13)
PROCestado
ENDPROC
#
REM ---------------- Texto, archivos ----------------
DEF PROCtexto
PROCpide("Texto para poner en el cursor (Enter = cancelar): ")
IF N$="" THEN PROCestado:ENDPROC
VDU 5:GCOL 0,CO%:MOVE CX%,CY%:PRINT N$;:VDU 4
CAMB%=TRUE
PROCestado
ENDPROC
#
DEF PROCgrabar
LOCAL F%,K%
IF NOM$="" THEN PROCpide("Nombre del dibujo (Enter = cancelar): ") ELSE PROCpide("Nombre (Enter = "+NOM$+"): "):IF N$="" THEN N$=NOM$
IF N$="" THEN PROCestado:ENDPROC
PROCmayus
IF INSTR(N$,".")=0 THEN N$=N$+".PAN"
IF LEN(N$)>16 THEN PROCaviso("El nombre es demasiado largo (máximo 16)"):ENDPROC
IF N$<>NOM$ THEN F%=OPENIN N$ ELSE F%=0
IF F%>0 THEN CLOSE#F%:K%=FNpregunta(N$+" ya existe. ¿Reemplazarlo? (S/N)"):IF K%<>83 THEN PROCestado:ENDPROC
PRINT TAB(0,15);SPC(63);
OSCLI "FOTO "+N$
NOM$=N$:CAMB%=FALSE
PROCaviso("Grabado: "+NOM$)
ENDPROC
#
DEF PROCabrir
LOCAL K%
IF CAMB% THEN K%=FNpregunta("Hay cambios sin grabar. ¿Abrir otro igual? (S/N)"):IF K%<>83 THEN PROCestado:ENDPROC
N$=FNelegir(".PAN")
IF N$="" AND NOT LS% THEN PROCestado:ENDPROC
CLS
IF N$<>"" THEN NOM$=N$
IF NOM$<>"" THEN OSCLI "MOSTRAR "+NOM$ ELSE CLG
CAMB%=FALSE:AN%=FALSE:HE%=0
PROCestado
ENDPROC
#
DEF PROCnuevo
LOCAL K%
IF CAMB% THEN K%=FNpregunta("Hay cambios sin grabar. ¿Borrar todo igual? (S/N)"):IF K%<>83 THEN PROCestado:ENDPROC
CLG:NOM$="":CAMB%=FALSE:AN%=FALSE:HE%=0
PROCestado
ENDPROC
#
DEF PROCsalir
LOCAL K%
IF CAMB% THEN K%=FNpregunta("Hay cambios sin grabar. ¿Salir igual? (S/N)") ELSE K%=83
IF K%<>83 THEN PROCestado:ENDPROC
*ESC ON
CHAIN "MENU"
ENDPROC
#
REM Lista los archivos con la extensión E$ de los dos discos y deja elegir uno
DEF FNelegir(E$)
LOCAL N%,I%,K%,S%,X%,Y%
N%=0:I%=0:LS%=FALSE
REPEAT
!B%=I%:A%=192:X%=B% MOD 256:Y%=B% DIV 256:CALL &FFF1
IF ?B%=0 AND N%<42 THEN N$=FNcampo(B%+2):IF RIGHT$(N$,4)=E$ THEN N%=N%+1:LI$(N%)=N$
I%=I%+1
UNTIL ?B%=2
IF N%=0 THEN PROCaviso("No hay dibujos grabados ("+E$+")"):=""
CLS:LS%=TRUE
PRINT TAB(0,0);"ABRIR: elegí un dibujo con las flechas y apretá Enter";
PRINT TAB(0,15);"Flechas: elegir   Enter: abrir   Volver: cancelar";
FOR I%=1 TO N%:PROCopcion(I%,FALSE):NEXT
S%=1
REPEAT
PROCopcion(S%,TRUE)
K%=GET
PROCopcion(S%,FALSE)
IF K%=136 AND S%>14 THEN S%=S%-14
IF K%=137 AND S%+14<=N% THEN S%=S%+14
IF K%=139 AND S%>1 THEN S%=S%-1
IF K%=138 AND S%<N% THEN S%=S%+1
UNTIL K%=13 OR K%=27
IF K%=27 THEN =""
=LI$(S%)
#
DEF PROCopcion(I%,M%)
IF M% THEN COLOUR 129:COLOUR 0
PRINT TAB(((I%-1) DIV 14)*21,1+(I%-1) MOD 14);" ";LI$(I%);SPC(17-LEN(LI$(I%)));
COLOUR 128:COLOUR 1
ENDPROC
#
DEF FNcampo(A%)
R$=""
WHILE ?A%>32 AND LEN(R$)<16:R$=R$+CHR$?A%:A%=A%+1:ENDWHILE
=R$
#
REM ---------------- Mensajes en la última línea ----------------
DEF PROCaviso(M$)
LOCAL K%
PRINT TAB(0,15);SPC(63);TAB(0,15);LEFT$(M$,50);"  (una tecla)";
K%=GET
PROCestado
ENDPROC
#
DEF FNpregunta(M$)
LOCAL K%
PRINT TAB(0,15);SPC(63);TAB(0,15);LEFT$(M$,63);
K%=GET
IF K%>=97 AND K%<=122 THEN K%=K%-32
=K%
#
DEF PROCpide(M$)
PRINT TAB(0,15);SPC(63);
VDU 28,0,15,63,15,12,23,1,1;0;0;0;
PRINT M$;
INPUT LINE "" N$
VDU 26,23,1,0;0;0;0;
VDU 24,0;8;319;127;
WHILE LEFT$(N$,1)=" ":N$=MID$(N$,2):ENDWHILE
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
{error} CLOSE#0:VDU 26,23,1,0;0;0;0;
VDU 24,0;8;319;127;
*ESC OFF
IF ERR=17 THEN M$="Cancelado" ELSE M$=REPORT$
PROCaviso(M$)
GOTO {bucle}
#
{datos} DATA Lápiz,Línea,Rectángulo,Círculo,Caja llena,Disco
DATA "Flechas: mover   Espacio: lápiz arriba/abajo   B: tinta"
DATA "L línea  R rectángulo  F caja llena  C círculo  D disco"
DATA "L R F C D marcan el inicio; Enter o la misma letra terminan"
DATA "T texto  G grabar  A abrir  N nuevo  Volver: salir o cancelar"
