# GRAFICO - dibuja funciones matemáticas y = f(x)
REM GRAFICOS - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 0
*ESC OFF
VDU 23,1,0;0;0;0;
DIM FU$(4),AY$(4)
FOR I%=1 TO 4:FU$(I%)=STRING$(60," "):FU$(I%)="":NEXT
F$=STRING$(63," "):N$=STRING$(63," "):M$=STRING$(63," "):F$="":N$="":M$=""
RESTORE {ayuda}
FOR I%=1 TO 4:READ AY$(I%):NEXT
NF%=1:FU$(1)="SIN(X)":XA=-10:XB=10:AU%=TRUE:YA=-1:YB=1
VDU 24,0;8;319;127;
PROCgraficar
{bucle} REPEAT
K%=GET
IF K%>=97 AND K%<=122 THEN K%=K%-32
IF K%=70 THEN PROCfuncion(TRUE)
IF K%=65 THEN PROCfuncion(FALSE)
IF K%=66 THEN NF%=0:PROCgraficar
IF K%=82 THEN PROCrango
IF K%=90 THEN PROCzoom(0.5)
IF K%=88 THEN PROCzoom(2)
IF K%=136 THEN PROCcorre(-0.25,0)
IF K%=137 THEN PROCcorre(0.25,0)
IF K%=139 THEN PROCcorre(0,0.25)
IF K%=138 THEN PROCcorre(0,-0.25)
IF K%=84 THEN PROCrastreo
IF K%=71 THEN PROCgrabar
IF K%=72 OR K%=63 THEN PROCayuda
IF K%=27 OR K%=128 THEN PROCsalir
UNTIL FALSE
#
REM Valor de la función F$ en X (1E38 si no se puede calcular)
DEF FNy(X)
ON ERROR LOCAL EE%=ERR:=1E38
=EVAL(F$)
#
DEF FNpx(X)
=(X-XA)/(XB-XA)*319
#
DEF FNpy(Y)
=8+(Y-YA)/(YB-YA)*119
#
REM ---------------- Dibujo ----------------
DEF PROCgraficar
LOCAL I%
CLG
IF AU% AND NF%>0 THEN PROCautomatico
PROCejes
FOR I%=1 TO NF%:PROCcurva(I%):NEXT
PROCestado
ENDPROC
#
REM Busca el rango de y mirando 64 puntos de cada función
DEF PROCautomatico
LOCAL I%,J%,X,Y,A,B,H%
A=1E30:B=-1E30
FOR I%=1 TO NF%
F$=FU$(I%)
FOR J%=0 TO 64
X=XA+(XB-XA)*J%/64:Y=FNy(X)
IF Y<1E37 THEN H%=TRUE:IF Y<A THEN A=Y
IF Y<1E37 AND Y>B THEN B=Y
NEXT
NEXT
IF NOT H% THEN A=-1:B=1
IF B-A<1E-6 THEN A=A-1:B=B+1
YA=A-(B-A)*0.08:YB=B+(B-A)*0.08
ENDPROC
#
REM Ejes con marcas cada "paso redondo"
DEF PROCejes
LOCAL P,V,X%,Y%,X0%,Y0%
GCOL 0,1
Y0%=-1:X0%=-1
IF YA<=0 AND YB>=0 THEN Y0%=FNpy(0):MOVE 0,Y0%:DRAW 319,Y0%
IF XA<=0 AND XB>=0 THEN X0%=FNpx(0):MOVE X0%,8:DRAW X0%,127
IF Y0%<0 THEN Y0%=8
IF X0%<0 THEN X0%=0
P=FNpaso(XB-XA):V=INT(XA/P)*P
WHILE V<=XB
X%=FNpx(V):MOVE X%,Y0%-2:DRAW X%,Y0%+2
V=V+P
ENDWHILE
P=FNpaso(YB-YA):V=INT(YA/P)*P
WHILE V<=YB
Y%=FNpy(V):MOVE X0%-2,Y%:DRAW X0%+2,Y%
V=V+P
ENDWHILE
ENDPROC
#
REM Un paso de 1, 2 o 5 por una potencia de 10 (unas 10 marcas)
DEF FNpaso(R)
LOCAL P
P=10^INT(LOG(R/10))
IF R/P>50 THEN =P*5
IF R/P>20 THEN =P*2
=P
#
REM Curva I%: 1 línea llena, 2 puntos, 3 rayas, 4 línea llena
DEF PROCcurva(I%)
LOCAL J%,X,Y,PX%,PY%,AN%,S%
F$=FU$(I%):AN%=FALSE:S%=0
GCOL 0,1
FOR J%=0 TO 319 STEP 2
X=XA+(XB-XA)*J%/319:Y=FNy(X)
IF Y>=1E37 OR Y>YB+(YB-YA)*4 OR Y<YA-(YB-YA)*4 THEN AN%=FALSE ELSE PROCtramo
NEXT
ENDPROC
#
DEF PROCtramo
PY%=FNpy(Y)
S%=S%+1
IF I%=2 THEN PLOT 69,J%,PY%:ENDPROC
IF AN% AND (I%<>3 OR (S% AND 2)=0) THEN DRAW J%,PY% ELSE MOVE J%,PY%
AN%=TRUE
ENDPROC
#
REM ---------------- Línea de estado ----------------
DEF PROCestado
PRINT TAB(0,15);SPC(63);TAB(0,15);
IF NF%=0 THEN PRINT "F: escribir una función"; ELSE PRINT "Y=";LEFT$(FU$(1),21);
IF NF%>1 THEN PRINT " +";NF%-1;
PRINT TAB(29,15);"x:";FNcorto(XA);"..";FNcorto(XB);
PRINT TAB(47,15);"H=ayuda";
ENDPROC
#
DEF FNcorto(V)
LOCAL T$
T$=STR$(SGN(V)*INT(ABS(V)*100+0.5)/100)
=LEFT$(T$,6)
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
REM ---------------- Funciones y rango ----------------
DEF PROCfuncion(NUEVA%)
LOCAL E%
IF NOT NUEVA% AND NF%>=4 THEN PROCaviso("Ya hay 4 funciones (B las borra)"):ENDPROC
PROCpide("Y = ")
IF N$="" THEN PROCestado:ENDPROC
PROCprepara
F$=N$:EE%=0
IF FNy(0.37)>=1E37 THEN E%=EE% ELSE E%=0
IF E%=16 OR E%=26 OR E%=27 OR E%=29 OR E%=6 OR E%=4 OR E%=31 OR E%=9 THEN PROCaviso("No entiendo la función: "+LEFT$(N$,30)):ENDPROC
IF NUEVA% THEN NF%=1 ELSE NF%=NF%+1
FU$(NF%)=LEFT$(N$,60)
PROCgraficar
ENDPROC
#
REM Mayúsculas y coma decimal en N$
DEF PROCprepara
LOCAL I%,C%
FOR I%=1 TO LEN(N$)
C%=ASC(MID$(N$,I%,1))
IF C%>=97 AND C%<=122 THEN MID$(N$,I%,1)=CHR$(C%-32)
IF C%=44 THEN MID$(N$,I%,1)="."
NEXT
ENDPROC
#
DEF PROCrango
LOCAL A,B
A=FNnumero("X desde: ",XA):B=FNnumero("X hasta: ",XB)
IF B<=A THEN PROCaviso("El final tiene que ser mayor que el comienzo"):ENDPROC
XA=A:XB=B
PROCpide("Y desde (Enter = automático): ")
IF N$="" THEN AU%=TRUE:PROCgraficar:ENDPROC
PROCprepara:A=VAL(N$)
B=FNnumero("Y hasta: ",YB)
IF B<=A THEN PROCaviso("El final tiene que ser mayor que el comienzo"):ENDPROC
YA=A:YB=B:AU%=FALSE
PROCgraficar
ENDPROC
#
DEF FNnumero(T$,V)
PROCpide(T$+"(Enter = "+FNcorto(V)+") ")
IF N$="" THEN =V
PROCprepara
=VAL(N$)
#
DEF PROCzoom(F)
LOCAL C,R
C=(XA+XB)/2:R=(XB-XA)*F/2:XA=C-R:XB=C+R
IF NOT AU% THEN C=(YA+YB)/2:R=(YB-YA)*F/2:YA=C-R:YB=C+R
PROCgraficar
ENDPROC
#
DEF PROCcorre(DX,DY)
LOCAL R
R=(XB-XA)*DX:XA=XA+R:XB=XB+R
IF DY<>0 THEN AU%=FALSE:R=(YB-YA)*DY:YA=YA+R:YB=YB+R
PROCgraficar
ENDPROC
#
REM Recorre la curva con las flechas mostrando x e y
DEF PROCrastreo
LOCAL T%,K%,X,Y,PY%,V%
IF NF%=0 THEN ENDPROC
T%=160:TF%=1
REPEAT
F$=FU$(TF%):X=XA+(XB-XA)*T%/319:Y=FNy(X)
V%=Y<1E37:IF V% THEN PY%=FNpy(Y):V%=PY%>=8 AND PY%<=127
IF V% THEN PROCmarca
PRINT TAB(0,15);SPC(63);TAB(0,15);"f";TF%;"  x=";FNcorto(X);
IF Y<1E37 THEN PRINT "  y=";LEFT$(STR$(Y),10); ELSE PRINT "  y=no existe";
PRINT TAB(42,15);"Flechas · T: listo";
K%=GET
IF V% THEN PROCmarca
IF K%=136 AND T%>0 THEN T%=T%-1
IF K%=137 AND T%<319 THEN T%=T%+1
IF K%=139 THEN TF%=TF% MOD NF%+1
IF K%=138 THEN TF%=(TF%+NF%-2) MOD NF%+1
UNTIL K%=27 OR K%=128 OR K%=84 OR K%=116 OR K%=13
PROCestado
ENDPROC
#
DEF PROCmarca
GCOL 3,1
MOVE T%-3,PY%:DRAW T%-1,PY%:MOVE T%+1,PY%:DRAW T%+3,PY%
MOVE T%,PY%-3:DRAW T%,PY%-1:MOVE T%,PY%+1:DRAW T%,PY%+3
GCOL 0,1
ENDPROC
#
DEF PROCgrabar
LOCAL F%
PROCpide("Grabar el gráfico como (Enter = cancelar): ")
IF N$="" THEN PROCestado:ENDPROC
PROCprepara
IF INSTR(N$,".")=0 THEN N$=N$+".PAN"
PRINT TAB(0,15);SPC(63);
OSCLI "FOTO "+N$
PROCaviso("Grabado: "+N$+" (se ve con *MOSTRAR o en Dibujo)")
ENDPROC
#
DEF PROCsalir
*ESC ON
CHAIN "MENU"
ENDPROC
#
REM ---------------- Mensajes en la última línea ----------------
DEF PROCaviso(M$)
LOCAL K%
PRINT TAB(0,15);SPC(63);TAB(0,15);LEFT$(M$,63);
K%=GET
PROCestado
ENDPROC
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
{error} CLOSE#0:VDU 26,23,1,0;0;0;0;
VDU 24,0;8;319;127;
*ESC OFF
IF ERR=17 THEN M$="Cancelado" ELSE M$=REPORT$
PROCaviso(M$)
GOTO {bucle}
#
{ayuda} DATA "F nueva función   A agregar otra (hasta 4)   B borrar todas"
DATA "R rango   Z acercar   X alejar   Flechas: mover el gráfico"
DATA "T recorrer la curva y ver los valores   G grabar la imagen"
DATA "Usá X: SIN COS TAN SQR LN LOG EXP ABS INT PI ^ (radianes)"
