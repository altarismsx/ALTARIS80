# BUSCAMINAS - encontra las minas sin pisarlas
REM BUSCAMINAS - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 1:VDU 23,1,0;0;0;0;
AN%=20:AL%=12
DIM M%(AN%+1,AL%+1),V%(AN%+1,AL%+1),PX%(500),PY%(500)
VDU 23,162,255,129,129,129,129,129,129,255
VDU 23,163,0,0,0,0,0,0,0,0
VDU 23,164,16,24,28,30,16,16,124,0
VDU 23,165,0,84,56,254,56,84,0,0
VDU 23,166,0,0,0,24,24,0,0,0
{inicio} PROCportada
{juego} PROCarmar
REPEAT
PROCcelda(CX%,CY%,TRUE)
K%=GET
PROCcelda(CX%,CY%,FALSE)
IF K%=136 AND CX%>1 THEN CX%=CX%-1
IF K%=137 AND CX%<AN% THEN CX%=CX%+1
IF K%=139 AND CY%>1 THEN CY%=CY%-1
IF K%=138 AND CY%<AL% THEN CY%=CY%+1
IF K%=13 OR K%=32 THEN PROCabrir(CX%,CY%)
IF K%=ASC("B") OR K%=ASC("b") OR K%=ASC("M") OR K%=ASC("m") THEN PROCbandera(CX%,CY%)
PROCtiempo
UNTIL ESTADO%<>0
PROCfin
IF FNotra THEN GOTO {juego}
CHAIN "MENU"
#
DEF PROCportada
LOCAL K$
CLS
PRINT TAB(10,2);"B U S C A M I N A S"
PRINT TAB(11,4);"Altaris Software ";CHR$169;" 2026"
PRINT TAB(3,6);"Abrí todas las casillas que no"
PRINT TAB(3,7);"tienen minas. El número dice cuántas"
PRINT TAB(3,8);"minas hay alrededor."
PRINT TAB(3,10);"Flechas: mover   Espacio: abrir"
PRINT TAB(3,11);"B: poner o sacar una bandera"
PRINT TAB(1,13);"Dificultad: 1 fácil 2 normal 3 difícil"
REPEAT K$=GET$:UNTIL INSTR("123",K$)
NM%=VAL(K$)*12+3
ENDPROC
#
DEF PROCarmar
LOCAL X%,Y%
CLS
FOR X%=0 TO AN%+1:FOR Y%=0 TO AL%+1:M%(X%,Y%)=0:V%(X%,Y%)=0:NEXT:NEXT
VDU 31,0,1,138:PRINT STRING$(AN%,CHR$136);CHR$139;
FOR Y%=2 TO AL%+1:VDU 31,0,Y%,137,31,AN%+1,Y%,137:NEXT
VDU 31,0,AL%+2,140:PRINT STRING$(AN%,CHR$136);CHR$141;
FOR Y%=1 TO AL%:PRINT TAB(1,Y%+1);STRING$(AN%,CHR$162);:NEXT
PRINT TAB(0,0);"BUSCAMINAS";
PRINT TAB(24,2);"MINAS";
PRINT TAB(24,3);NM%;
PRINT TAB(24,5);"BANDERAS";
PRINT TAB(24,8);"TIEMPO";
PRINT TAB(24,11);"B: bandera";
PRINT TAB(24,12);"Espacio:";
PRINT TAB(24,13);"  abrir";
CX%=AN% DIV 2:CY%=AL% DIV 2:ESTADO%=0:BA%=0:ABIERTAS%=0:PRIMERA%=TRUE:T0%=TIME
PROCbanderas
ENDPROC
#
DEF PROCbanderas
PRINT TAB(24,6);BA%;"  ";
ENDPROC
#
DEF PROCtiempo
IF PRIMERA% THEN ENDPROC
PRINT TAB(24,9);(TIME-T0%) DIV 100;" s  ";
ENDPROC
#
REM Pone las minas evitando la primera casilla y sus vecinas
DEF PROCminas(SX%,SY%)
LOCAL N%,X%,Y%
N%=0
REPEAT
X%=RND(AN%):Y%=RND(AL%)
IF M%(X%,Y%)=0 AND (ABS(X%-SX%)>1 OR ABS(Y%-SY%)>1) THEN M%(X%,Y%)=1:N%=N%+1
UNTIL N%=NM%
T0%=TIME
ENDPROC
#
DEF FNvecinas(X%,Y%)
=M%(X%-1,Y%-1)+M%(X%,Y%-1)+M%(X%+1,Y%-1)+M%(X%-1,Y%)+M%(X%+1,Y%)+M%(X%-1,Y%+1)+M%(X%,Y%+1)+M%(X%+1,Y%+1)
#
REM V%: 0 tapada, 1 abierta, 2 bandera
DEF PROCcelda(X%,Y%,S%)
LOCAL C%,N%
IF S% THEN COLOUR 129:COLOUR 0
IF V%(X%,Y%)=0 THEN C%=162
IF V%(X%,Y%)=2 THEN C%=164
IF V%(X%,Y%)=1 THEN N%=FNvecinas(X%,Y%):C%=48+N%+16*(N%=0)
IF V%(X%,Y%)=1 AND M%(X%,Y%)=1 THEN C%=165
VDU 31,X%,Y%+1,C%
COLOUR 128:COLOUR 1
ENDPROC
#
DEF PROCbandera(X%,Y%)
IF V%(X%,Y%)=1 THEN ENDPROC
IF V%(X%,Y%)=2 THEN V%(X%,Y%)=0:BA%=BA%-1 ELSE V%(X%,Y%)=2:BA%=BA%+1
PROCbanderas
ENDPROC
#
REM Abre una casilla; si no tiene minas alrededor abre las vecinas
DEF PROCabrir(X%,Y%)
LOCAL P%,A%,B%,I%,J%
IF V%(X%,Y%)<>0 THEN ENDPROC
IF PRIMERA% THEN PROCminas(X%,Y%):PRIMERA%=FALSE
IF M%(X%,Y%)=1 THEN V%(X%,Y%)=1:PROCcelda(X%,Y%,FALSE):ESTADO%=2:ENDPROC
P%=1:PX%(1)=X%:PY%(1)=Y%:V%(X%,Y%)=1
WHILE P%>0
A%=PX%(P%):B%=PY%(P%):P%=P%-1
ABIERTAS%=ABIERTAS%+1:PROCcelda(A%,B%,FALSE)
IF FNvecinas(A%,B%)=0 THEN PROCvecinas
ENDWHILE
IF ABIERTAS%=AN%*AL%-NM% THEN ESTADO%=1
ENDPROC
#
DEF PROCvecinas
FOR I%=A%-1 TO A%+1:FOR J%=B%-1 TO B%+1
IF I%>=1 AND I%<=AN% AND J%>=1 AND J%<=AL% THEN IF V%(I%,J%)=0 THEN V%(I%,J%)=1:P%=P%+1:PX%(P%)=I%:PY%(P%)=J%
NEXT:NEXT
ENDPROC
#
DEF PROCfin
LOCAL X%,Y%
FOR X%=1 TO AN%:FOR Y%=1 TO AL%
IF M%(X%,Y%)=1 AND V%(X%,Y%)<>2 THEN VDU 31,X%,Y%+1,165
NEXT:NEXT
IF ESTADO%=1 THEN PRINT TAB(24,15);"¡GANASTE!"; ELSE PRINT TAB(24,15);"¡BUM!";:SOUND 1,-15,20,20
WAIT 150
ENDPROC
#
DEF FNotra
LOCAL K$
PRINT TAB(0,15);"¿Otra? (S/N)";
REPEAT K$=GET$:UNTIL INSTR("SsNn",K$)
PRINT TAB(0,15);SPC(12);
=(K$="S" OR K$="s")
#
{error} IF ERR=17 THEN CHAIN "MENU"
MODE 0:VDU 23,1,1;0;0;0;:REPORT:PRINT " (línea ";ERL;")":END
