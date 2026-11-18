# DEMOS - demostraciones gráficas que se pasan solas
REM DEMOS - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 0
*ESC OFF
VDU 23,1,0;0;0;0;
DIM VX(8),VY(8),VZ(8),PX%(8),PY%(8),OX%(8),OY%(8),EA%(12),EB%(12),NOM$(8)
DIM SX(40),SY(40),SZ(40),QX%(40),QY%(40),BOX(4),BOY(4),BVX(4),BVY(4)
DIM CE%(140),PIL%(140)
RESTORE {datos}
FOR I%=1 TO 8:READ VX(I%),VY(I%),VZ(I%):NEXT
FOR I%=1 TO 12:READ EA%(I%),EB%(I%):NEXT
FOR I%=1 TO 8:READ NOM$(I%):NEXT
VDU 24,0;8;319;127;
SAL%=FALSE:D%=1
REPEAT
PROCtitulo
IF D%=1 THEN PROCcubo
IF D%=2 THEN PROClissajous
IF D%=3 THEN PROCestrellas
IF D%=4 THEN PROCpelotas
IF D%=5 THEN PROCmoire
IF D%=6 THEN PROClaberinto
IF D%=7 THEN PROCsierpinski
IF D%=8 THEN PROCreloj
D%=D% MOD 8+1
UNTIL SAL%
*ESC ON
CHAIN "MENU"
#
DEF PROCtitulo
CLG
PRINT TAB(0,15);SPC(63);TAB(0,15);"DEMO ";D%;"/8: ";NOM$(D%);TAB(37,15);"Espacio otra · Volver salir";
T0%=TIME:LIM%=1500
ENDPROC
#
REM Termina la demo: tecla, o pasaron 15 segundos
DEF FNfin
LOCAL K%
K%=INKEY(0)
IF K%=27 OR K%=128 THEN SAL%=TRUE
*FX 15
=SAL% OR K%=32 OR TIME>T0%+LIM%
#
REM ---------------- 1. Cubo 3D en alambre ----------------
DEF PROCcubo
LOCAL A,B,I%,X,Y,Z,C,S,P%
A=0:B=0:P%=FALSE
GCOL 3,1
REPEAT
A=A+0.07:B=B+0.045
FOR I%=1 TO 8
C=COS(A):S=SIN(A)
X=VX(I%)*C-VZ(I%)*S:Z=VX(I%)*S+VZ(I%)*C
C=COS(B):S=SIN(B)
Y=VY(I%)*C-Z*S:Z=VY(I%)*S+Z*C
PX%(I%)=160+X*120/(Z+4):PY%(I%)=68+Y*120/(Z+4)
NEXT
PROCaristas(P%)
FOR I%=1 TO 8:OX%(I%)=PX%(I%):OY%(I%)=PY%(I%):NEXT
P%=TRUE
UNTIL FNfin
GCOL 0,1
ENDPROC
#
REM Las 12 aristas: borra cada una en la posición anterior (si V%) y la
REM dibuja en la nueva enseguida, así casi no titila
DEF PROCaristas(V%)
LOCAL I%
FOR I%=1 TO 12
IF V% THEN MOVE OX%(EA%(I%)),OY%(EA%(I%)):DRAW OX%(EB%(I%)),OY%(EB%(I%))
MOVE PX%(EA%(I%)),PY%(EA%(I%)):DRAW PX%(EB%(I%)),PY%(EB%(I%))
NEXT
ENDPROC
#
REM ---------------- 2. Curvas de Lissajous ----------------
DEF PROClissajous
LOCAL A%,B%,T,F
GCOL 0,1
REPEAT
A%=RND(5):B%=RND(5):F=RND(1)*PI
CLG
MOVE 160+150*SIN(F),68
FOR T=0 TO 2*PI+0.05 STEP PI/90
DRAW 160+150*SIN(A%*T+F),68+56*SIN(B%*T)
NEXT
T=TIME:REPEAT UNTIL TIME>T+150 OR INKEY(-99) OR INKEY(-113)
UNTIL FNfin
ENDPROC
#
REM ---------------- 3. Viaje entre estrellas ----------------
DEF PROCestrellas
LOCAL I%,F
FOR I%=1 TO 40:PROCnueva(I%):SZ(I%)=RND(1)*8+1:QX%(I%)=-1:NEXT
GCOL 3,1
REPEAT
FOR I%=1 TO 40
IF QX%(I%)>=0 THEN PLOT 69,QX%(I%),QY%(I%)
SZ(I%)=SZ(I%)-0.25
IF SZ(I%)<0.3 THEN PROCnueva(I%)
F=60/SZ(I%):QX%(I%)=160+SX(I%)*F:QY%(I%)=68+SY(I%)*F
IF QX%(I%)<0 OR QX%(I%)>319 OR QY%(I%)<8 OR QY%(I%)>127 THEN PROCnueva(I%):QX%(I%)=-1 ELSE PLOT 69,QX%(I%),QY%(I%)
NEXT
UNTIL FNfin
GCOL 0,1
ENDPROC
#
DEF PROCnueva(I%)
SX(I%)=RND(1)*4-2:SY(I%)=RND(1)*2-1:SZ(I%)=8
ENDPROC
#
REM ---------------- 4. Pelotas que rebotan ----------------
DEF PROCpelotas
LOCAL I%
FOR I%=1 TO 4
BOX(I%)=20+RND(280):BOY(I%)=20+RND(90):BVX(I%)=(RND(5)+2)*SGN(RND(2)-1.5):BVY(I%)=(RND(4)+1)*SGN(RND(2)-1.5)
NEXT
GCOL 0,1
FOR I%=1 TO 4:CIRCLE FILL BOX(I%),BOY(I%),6:NEXT
REPEAT
FOR I%=1 TO 4
GCOL 0,0:CIRCLE FILL BOX(I%),BOY(I%),6:GCOL 0,1
BOX(I%)=BOX(I%)+BVX(I%):BOY(I%)=BOY(I%)+BVY(I%)
IF BOX(I%)<6 OR BOX(I%)>313 THEN BVX(I%)=-BVX(I%):BOX(I%)=BOX(I%)+BVX(I%):SOUND 1,-10,100+I%*20,1
IF BOY(I%)<14 OR BOY(I%)>121 THEN BVY(I%)=-BVY(I%):BOY(I%)=BOY(I%)+BVY(I%):SOUND 1,-10,120+I%*20,1
CIRCLE FILL BOX(I%),BOY(I%),6
NEXT
UNTIL FNfin
GCOL 0,1
ENDPROC
#
REM ---------------- 5. Muaré: líneas que se cruzan ----------------
DEF PROCmoire
LOCAL I%,K%
GCOL 3,1
I%=0
REPEAT
IF I%<=319 THEN MOVE 0,8:DRAW I%,127:MOVE 319,8:DRAW 319-I%,127
IF I%>319 AND I%<=438 THEN MOVE 0,8:DRAW 319,I%-311:MOVE 319,8:DRAW 0,I%-311
IF I%>438 THEN K%=TIME:REPEAT UNTIL TIME>K%+20 OR INKEY(-99)
I%=I%+3
UNTIL FNfin
GCOL 0,1
ENDPROC
#
REM ---------------- 6. Laberinto (se arma solo) ----------------
DEF PROClaberinto
LOCAL W%,H%,N%,C%,X%,Y%,V%,D%,P%,J%,R%
W%=19:H%=7
GCOL 0,1:RECTANGLE FILL 0,8,319,119
FOR C%=0 TO W%*H%-1:CE%(C%)=0:NEXT
P%=1:PIL%(1)=0:CE%(0)=1:PROCcelda(0)
GCOL 0,0
REPEAT
C%=PIL%(P%):X%=C% MOD W%:Y%=C% DIV W%
N%=0:D%=-1:R%=RND(4)
FOR J%=1 TO 4
V%=FNvecina(X%,Y%,(J%+R%) MOD 4)
IF V%>=0 AND N%=0 THEN N%=1:D%=V%
NEXT
IF N%=0 THEN P%=P%-1 ELSE CE%(D%)=1:PROCpasillo(C%,D%):P%=P%+1:PIL%(P%)=D%
UNTIL P%=0 OR FNfin
IF NOT SAL% THEN T0%=TIME:LIM%=400:REPEAT UNTIL FNfin
GCOL 0,1
ENDPROC
#
REM Vecina sin visitar en la dirección D% (0 der, 1 arr, 2 izq, 3 abj)
DEF FNvecina(X%,Y%,D%)
IF D%=0 THEN X%=X%+1
IF D%=1 THEN Y%=Y%+1
IF D%=2 THEN X%=X%-1
IF D%=3 THEN Y%=Y%-1
IF X%<0 OR X%>=W% OR Y%<0 OR Y%>=H% THEN =-1
IF CE%(Y%*W%+X%) THEN =-1
=Y%*W%+X%
#
DEF PROCcelda(C%)
GCOL 0,0
RECTANGLE FILL 8+(C% MOD W%)*16,16+(C% DIV W%)*16,7,7
ENDPROC
#
DEF PROCpasillo(A%,B%)
LOCAL X1%,Y1%,X2%,Y2%,T%
X1%=8+(A% MOD W%)*16:Y1%=16+(A% DIV W%)*16
X2%=8+(B% MOD W%)*16:Y2%=16+(B% DIV W%)*16
IF X2%<X1% THEN T%=X1%:X1%=X2%:X2%=T%
IF Y2%<Y1% THEN T%=Y1%:Y1%=Y2%:Y2%=T%
RECTANGLE FILL X1%,Y1%,X2%-X1%+7,Y2%-Y1%+7
ENDPROC
#
REM ---------------- 7. Triángulo de Sierpinski (juego del caos) ----------------
DEF PROCsierpinski
LOCAL X,Y,V%,I%
GCOL 0,1
X=160:Y=60
REPEAT
FOR I%=1 TO 40
V%=RND(3)
IF V%=1 THEN X=(X+160)/2:Y=(Y+124)/2
IF V%=2 THEN X=(X+10)/2:Y=(Y+10)/2
IF V%=3 THEN X=(X+310)/2:Y=(Y+10)/2
PLOT 69,X,Y
NEXT
UNTIL FNfin
ENDPROC
#
REM ---------------- 8. Reloj de agujas con la hora del sistema ----------------
DEF PROCreloj
LOCAL I%,A,H%,M%,S%,T$,U$
GCOL 0,1
CIRCLE 160,68,56:CIRCLE 160,68,57
FOR I%=0 TO 59
A=I%*PI/30
IF I% MOD 5=0 THEN MOVE 160+50*SIN(A),68+50*COS(A):DRAW 160+56*SIN(A),68+56*COS(A) ELSE PLOT 69,160+54*SIN(A),68+54*COS(A)
NEXT
U$=""
REPEAT
T$=MID$(TIME$,17,8)
IF T$<>U$ THEN PROCagujas(U$,0):PROCagujas(T$,1):U$=T$
UNTIL FNfin
ENDPROC
#
DEF PROCagujas(T$,C%)
LOCAL H,M,S
IF T$="" THEN ENDPROC
H=VAL(T$):M=VAL(MID$(T$,4)):S=VAL(MID$(T$,7))
GCOL 0,C%
PROCaguja((H MOD 12+M/60)*PI/6,28)
PROCaguja((M+S/60)*PI/30,42)
PROCaguja(S*PI/30,48)
GCOL 0,1:CIRCLE FILL 160,68,2
ENDPROC
#
DEF PROCaguja(A,L%)
MOVE 160,68:DRAW 160+L%*SIN(A),68+L%*COS(A)
ENDPROC
#
{error} OSCLI "ESC ON"
IF ERR=17 THEN CHAIN "MENU"
MODE 0:REPORT:PRINT " (línea ";ERL;")":END
#
{datos} DATA -1,-1,-1,1,-1,-1,1,1,-1,-1,1,-1,-1,-1,1,1,-1,1,1,1,1,-1,1,1
DATA 1,2,2,3,3,4,4,1,5,6,6,7,7,8,8,5,1,5,2,6,3,7,4,8
DATA Cubo 3D,Curvas de Lissajous,Viaje entre estrellas,Pelotas que rebotan
DATA Muaré,Laberinto,Triángulo de Sierpinski,Reloj de agujas
