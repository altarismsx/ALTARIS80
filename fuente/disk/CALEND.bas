# CALENDARIO - cualquier mes de cualquier año, con los feriados fijos
REM CALENDARIO - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 1:VDU 23,1,0;0;0;0;
DIM MES$(12),TT%(12),FD%(20),FM%(20),NOMF$(20),NF$(31),DIA$(6)
RESTORE {datos}
FOR I%=1 TO 12:READ MES$(I%):NEXT
FOR I%=1 TO 12:READ TT%(I%):NEXT
FOR I%=0 TO 6:READ DIA$(I%):NEXT
NFX%=0
REPEAT NFX%=NFX%+1:READ FD%(NFX%),FM%(NFX%),NOMF$(NFX%):UNTIL FD%(NFX%)=0
NFX%=NFX%-1
T$=TIME$
HD%=VAL(MID$(T$,5,2)):HA%=VAL(MID$(T$,12,4))
HM%=(INSTR("EneFebMarAbrMayJunJulAgoSepOctNovDic",MID$(T$,8,3))+2) DIV 3
MS%=HM%:A%=HA%
REPEAT
PROCmes
K%=GET
IF K%=136 THEN MS%=MS%-1:IF MS%<1 THEN MS%=12:A%=A%-1
IF K%=137 THEN MS%=MS%+1:IF MS%>12 THEN MS%=1:A%=A%+1
IF K%=139 THEN A%=A%+1
IF K%=138 THEN A%=A%-1
IF K%=72 OR K%=104 THEN MS%=HM%:A%=HA%
IF A%<1583 THEN A%=1583
IF A%>9999 THEN A%=9999
UNTIL FALSE
#
DEF PROCmes
LOCAL P%,N%,D%,C%,R%,T$,I%,L%
CLS
T$=MES$(MS%)+" "+STR$(A%)
PRINT TAB((40-LEN(T$)) DIV 2,0);T$;
RESTORE {semana}
FOR I%=0 TO 6:READ T$:PRINT TAB(3+I%*5,2);T$;:NEXT
PROCferiados
P%=(FNdow(1,MS%,A%)+6) MOD 7
N%=FNdias(MS%,A%)
FOR D%=1 TO N%
C%=(P%+D%-1) MOD 7:R%=3+(P%+D%-1) DIV 7
IF D%=HD% AND MS%=HM% AND A%=HA% THEN COLOUR 129:COLOUR 0
PRINT TAB(3+C%*5,R%);RIGHT$(" "+STR$(D%),2);
COLOUR 128:COLOUR 1
IF NF$(D%)<>"" THEN PRINT "*";
NEXT
PRINT TAB(0,9);STRING$(40,CHR$136);
L%=10
FOR D%=1 TO N%
IF NF$(D%)<>"" THEN PROClista(D%)
NEXT
IF L%=10 THEN PRINT TAB(0,10);" No hay feriados nacionales.";
T$="Hoy: "+DIA$(FNdow(HD%,HM%,HA%))+" "+STR$(HD%)+" de "+FNmin(MES$(HM%))
IF LEN(T$)<34 THEN T$=T$+" de "+STR$(HA%)
PRINT TAB(0,14);T$;
PRINT TAB(0,15);"Flechas: cambiar  H: hoy  Volver: salir";
ENDPROC
#
REM Marca los feriados del mes: los de fecha fija y los que dependen de Pascua
DEF PROCferiados
LOCAL I%,E%,B%,D%,N%
FOR I%=1 TO 31:NF$(I%)="":NEXT
FOR I%=1 TO NFX%:IF FM%(I%)=MS% THEN NF$(FD%(I%))=NOMF$(I%)
NEXT
E%=FNpascua(A%)
B%=FNdoy(1,MS%,A%)-1
FOR D%=1 TO FNdias(MS%,A%)
N%=B%+D%
IF N%=E%-48 OR N%=E%-47 THEN PROCagrega(D%,"Carnaval")
IF N%=E%-3 THEN PROCagrega(D%,"Jueves Santo (no laborable)")
IF N%=E%-2 THEN PROCagrega(D%,"Viernes Santo")
NEXT
ENDPROC
#
DEF PROCagrega(D%,T$)
IF NF$(D%)="" THEN NF$(D%)=T$ ELSE NF$(D%)=NF$(D%)+"|"+T$
ENDPROC
#
REM Escribe los feriados del día D% (separados por |), uno por línea
DEF PROClista(D%)
LOCAL T$,P%
T$=NF$(D%)
REPEAT
P%=INSTR(T$+"|","|")
IF L%<14 THEN PRINT TAB(0,L%);RIGHT$(" "+STR$(D%),2);" ";LEFT$(T$,P%-1);:L%=L%+1
T$=MID$(T$,P%+1)
UNTIL T$=""
ENDPROC
#
REM Día del año en que cae el domingo de Pascua (algoritmo de Gauss)
DEF FNpascua(Y%)
LOCAL A%,B%,C%,D%,E%,F%,G%,H%,I%,K%,L%,MS%,N%,P%
A%=Y% MOD 19:B%=Y% DIV 100:C%=Y% MOD 100
D%=B% DIV 4:E%=B% MOD 4:F%=(B%+8) DIV 25:G%=(B%-F%+1) DIV 3
H%=(19*A%+B%-D%-G%+15) MOD 30
I%=C% DIV 4:K%=C% MOD 4
L%=(32+2*E%+2*I%-H%-K%) MOD 7
MS%=(A%+11*H%+22*L%) DIV 451
N%=(H%+L%-7*MS%+114) DIV 31
P%=(H%+L%-7*MS%+114) MOD 31+1
=FNdoy(P%,N%,Y%)
#
DEF FNdoy(D%,MS%,Y%)
=TT%(MS%)+D%-(MS%>2 AND FNbis(Y%))
#
DEF FNbis(Y%)
=(Y% MOD 4=0 AND Y% MOD 100<>0) OR Y% MOD 400=0
#
DEF FNdias(MS%,Y%)
IF MS%=2 THEN =28-FNbis(Y%)
IF MS%=4 OR MS%=6 OR MS%=9 OR MS%=11 THEN =30
=31
#
REM Día de la semana: 0 = domingo
DEF FNdow(D%,MS%,Y%)
IF MS%<3 THEN Y%=Y%-1
=(Y%+Y% DIV 4-Y% DIV 100+Y% DIV 400+VAL(MID$("032503514624",MS%,1))+D%) MOD 7
#
DEF FNmin(T$)
=CHR$(ASC(T$) OR 32)+MID$(T$,2)
#
{error} IF ERR=17 THEN CHAIN "MENU"
MODE 0:VDU 23,1,1;0;0;0;:REPORT:PRINT " (línea ";ERL;")":END
#
{datos} DATA Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre
DATA 0,31,59,90,120,151,181,212,243,273,304,334
DATA domingo,lunes,martes,miércoles,jueves,viernes,sábado
REM Feriados nacionales (Argentina); los trasladables pueden pasar a un lunes
DATA 1,1,"Año Nuevo"
DATA 24,3,"Día de la Memoria"
DATA 2,4,"Día de los Caídos en Malvinas"
DATA 1,5,"Día del Trabajador"
DATA 25,5,"Revolución de Mayo"
DATA 17,6,"Güemes (trasladable)"
DATA 20,6,"Día de la Bandera"
DATA 9,7,"Día de la Independencia"
DATA 17,8,"San Martín (trasladable)"
DATA 12,10,"Diversidad Cultural (trasladable)"
DATA 20,11,"Soberanía Nacional (trasladable)"
DATA 8,12,"Inmaculada Concepción"
DATA 25,12,"Navidad"
DATA 0,0,""
{semana} DATA Lu,Ma,Mi,Ju,Vi,Sá,Do
