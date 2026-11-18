# TATETI 3D - ta-te-ti en un cubo de 3x3x3 contra la computadora
# Version para ALTARIS 80 del juego de Altaris Software.
REM TATETI 3D - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 0:VDU 23,1,0;0;0;0;
DIM B%(26),TL%(48,2),CL%(26,13),CN%(26),NC%(48,2)
PROClineas
PV%=0:PC%=0:PE%=0:NV%=2:EMPIEZA%=1:XB%=60
PROCtitulo
{partida} PROCnueva
REPEAT
IF TURNO%=1 THEN PROCjugador ELSE PROCcpu
G%=FNganador
IF G%=0 AND LIBRES%=0 THEN G%=3
TURNO%=3-TURNO%
UNTIL G%>0
PROCfin(G%)
IF FNotra THEN EMPIEZA%=3-EMPIEZA%:GOTO {partida}
CHAIN "MENU"
#
DEF PROClineas
LOCAL D%,L%,R%,C%,DL%,DR%,DC%,N%
N%=0
RESTORE {dirs}
FOR D%=1 TO 13
READ DL%,DR%,DC%
FOR L%=0 TO 2:FOR R%=0 TO 2:FOR C%=0 TO 2
IF FNfuera(L%-DL%,R%-DR%,C%-DC%) AND NOT FNfuera(L%+2*DL%,R%+2*DR%,C%+2*DC%) THEN TL%(N%,0)=L%*9+R%*3+C%:TL%(N%,1)=TL%(N%,0)+DL%*9+DR%*3+DC%:TL%(N%,2)=TL%(N%,1)+DL%*9+DR%*3+DC%:N%=N%+1
NEXT:NEXT:NEXT
NEXT
NL%=N%
FOR L%=0 TO NL%-1:FOR C%=0 TO 2
D%=TL%(L%,C%):CL%(D%,CN%(D%))=L%:CN%(D%)=CN%(D%)+1
NEXT:NEXT
ENDPROC
#
DEF FNfuera(L%,R%,C%)=L%<0 OR L%>2 OR R%<0 OR R%>2 OR C%<0 OR C%>2
#
{dirs} DATA 0,0,1, 0,1,0, 0,1,1, 0,1,-1, 1,0,0, 1,0,1, 1,0,-1
DATA 1,1,0, 1,-1,0, 1,1,1, 1,1,-1, 1,-1,1, 1,-1,-1
#
DEF PROCtitulo
CLS
PRINT TAB(22,3);"T A T E T I   3 D"
PRINT TAB(21,5);"Altaris Software ";CHR$169;" 2026"
PRINT TAB(8,8);"Tres en l";CHR$237;"nea en un cubo de 3x3x3: horizontal, vertical,"
PRINT TAB(8,9);"en diagonal o atravesando los tres niveles."
PRINT TAB(8,11);"Dificultad: 1 = normal   2 = dif";CHR$237;"cil"
REPEAT K$=GET$:UNTIL K$="1" OR K$="2"
NV%=VAL(K$)+1
ENDPROC
#
DEF PROCnueva
LOCAL I%
FOR I%=0 TO 26:B%(I%)=0:NEXT
FOR I%=0 TO 48:NC%(I%,1)=0:NC%(I%,2)=0:NEXT
LIBRES%=27:TURNO%=EMPIEZA%:CUR%=4:G%=0
CLS:CLG
FOR I%=0 TO 2:PROCnivel(I%):NEXT
PRINT TAB(44,0);"TATETI 3D"
PRINT TAB(44,2);"Vos:    X"
PRINT TAB(44,3);"Equipo: O"
PROCmarcador
PRINT TAB(44,10);"Flechas: mover"
PRINT TAB(44,11);"Enter: marcar"
PRINT TAB(44,12);"Volver: salir"
ENDPROC
#
DEF PROCmarcador
PRINT TAB(44,5);"Ganadas:  ";PV%;"  "
PRINT TAB(44,6);"Perdidas: ";PC%;"  "
PRINT TAB(44,7);"Empates:  ";PE%;"  "
ENDPROC
#
DEF PROCnivel(L%)
LOCAL K%,YT%
YT%=121-L%*42
VDU 5:MOVE XB%-24,YT%-12:PRINT ;L%+1;:VDU 4
FOR K%=0 TO 3
MOVE XB%+6*(3-K%),YT%-10*K%:DRAW XB%+78+6*(3-K%),YT%-10*K%
MOVE XB%+18+26*K%,YT%:DRAW XB%+26*K%,YT%-30
NEXT
ENDPROC
#
DEF FNcx(P%)=XB%+26*(P% MOD 3)+13+6*(2.5-(P% DIV 3) MOD 3)
DEF FNcy(P%)=121-(P% DIV 9)*42-10*((P% DIV 3) MOD 3)-5
#
DEF PROCficha(P%)
LOCAL X%,Y%
X%=FNcx(P%):Y%=FNcy(P%)
GCOL 0,1
IF B%(P%)=1 THEN MOVE X%-6,Y%-3:DRAW X%+6,Y%+3:MOVE X%-6,Y%+3:DRAW X%+6,Y%-3
IF B%(P%)=2 THEN CIRCLE X%,Y%,4
ENDPROC
#
DEF PROCcursor(P%)
LOCAL X%,Y%
X%=FNcx(P%):Y%=FNcy(P%)
GCOL 3,1:RECTANGLE FILL X%-10,Y%-4,20,8:GCOL 0,1
ENDPROC
#
DEF PROCestado(T$)
PRINT TAB(44,14);LEFT$(T$+STRING$(20," "),20);
ENDPROC
#
DEF PROCjugador
LOCAL K%,L%,R%,C%
PROCestado("Tu turno")
REPEAT
PROCcursor(CUR%)
K%=GET
PROCcursor(CUR%)
L%=CUR% DIV 9:R%=(CUR% DIV 3) MOD 3:C%=CUR% MOD 3
IF K%=136 AND C%>0 THEN C%=C%-1
IF K%=137 AND C%<2 THEN C%=C%+1
IF K%=139 THEN R%=R%-1:IF R%<0 THEN R%=2:L%=L%-1:IF L%<0 THEN L%=0:R%=0
IF K%=138 THEN R%=R%+1:IF R%>2 THEN R%=0:L%=L%+1:IF L%>2 THEN L%=2:R%=2
CUR%=L%*9+R%*3+C%
UNTIL (K%=13 OR K%=32) AND B%(CUR%)=0
PROCponer(CUR%,1)
ENDPROC
#
DEF PROCponer(P%,J%)
LOCAL K%
B%(P%)=J%:LIBRES%=LIBRES%-1:PROCficha(P%)
FOR K%=0 TO CN%(P%)-1:NC%(CL%(P%,K%),J%)=NC%(CL%(P%,K%),J%)+1:NEXT
ENDPROC
#
DEF PROCcpu
LOCAL P%
PROCestado("Pensando...")
P%=FNbusca(2):IF P%<0 THEN P%=FNbusca(1)
IF P%<0 AND B%(13)=0 THEN P%=13
IF P%<0 AND NV%=3 THEN P%=FNhorquilla(2):IF P%<0 THEN P%=FNhorquilla(1)
IF P%<0 THEN P%=FNmejor
PROCponer(P%,2)
ENDPROC
#
REM Casilla que completa una linea de J% (o -1)
DEF FNbusca(J%)
LOCAL L%,P%
P%=-1
FOR L%=0 TO NL%-1
IF NC%(L%,J%)=2 AND NC%(L%,3-J%)=0 THEN P%=FNvacia(L%):L%=NL%
NEXT
=P%
#
DEF FNvacia(L%)
IF B%(TL%(L%,0))=0 THEN =TL%(L%,0)
IF B%(TL%(L%,1))=0 THEN =TL%(L%,1)
=TL%(L%,2)
#
REM Casilla que arma dos amenazas a la vez para J%
DEF FNhorquilla(J%)
LOCAL P%,K%,A%,R%,L%
R%=-1
FOR P%=0 TO 26
IF B%(P%)=0 THEN
A%=0
FOR K%=0 TO CN%(P%)-1
L%=CL%(P%,K%):IF NC%(L%,J%)=1 AND NC%(L%,3-J%)=0 THEN A%=A%+1
NEXT
IF A%>=2 THEN R%=P%:P%=26
ENDIF
NEXT
=R%
#
REM Puntaje de cada casilla libre; la mejor (con algo de azar)
DEF FNmejor
LOCAL P%,K%,L%,M%,O%,S%,MX%,R%
MX%=-1:R%=-1
FOR P%=0 TO 26
IF B%(P%)=0 THEN
S%=RND(3)
FOR K%=0 TO CN%(P%)-1
L%=CL%(P%,K%):M%=NC%(L%,2):O%=NC%(L%,1)
IF O%=0 THEN S%=S%+2+M%*4
IF M%=0 THEN S%=S%+1+O%*3
NEXT
IF S%>MX% THEN MX%=S%:R%=P%
ENDIF
NEXT
=R%
#
REM 0 = nadie, 1 = jugador, 2 = computadora
DEF FNganador
LOCAL L%,J%
J%=0
FOR L%=0 TO NL%-1
IF NC%(L%,1)=3 THEN J%=1:WL%=L%:L%=NL%
IF NC%(L%,2)=3 THEN J%=2:WL%=L%:L%=NL%
NEXT
=J%
#
DEF PROCfin(G%)
LOCAL I%,K%
IF G%=1 THEN PV%=PV%+1:PROCestado("¡Ganaste!")
IF G%=2 THEN PC%=PC%+1:PROCestado("Gana el equipo")
IF G%=3 THEN PE%=PE%+1:PROCestado("Empate")
PROCmarcador
IF G%<3 THEN FOR K%=1 TO 6:FOR I%=0 TO 2:PROCcursor(TL%(WL%,I%)):NEXT:WAIT 20:NEXT
ENDPROC
#
DEF FNotra
LOCAL K$
PRINT TAB(44,15);"¿Otra? (S/N)";
REPEAT K$=GET$:UNTIL INSTR("SsNn",K$)
PRINT TAB(44,15);SPC(12);
=(K$="S" OR K$="s")
#
{error} IF ERR=17 THEN CHAIN "MENU"
MODE 0:VDU 23,1,1;0;0;0;:REPORT:PRINT " (línea ";ERL;")":END
