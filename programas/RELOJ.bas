# RELOJ - hora y fecha en numeros grandes, cronometro y puesta en hora
REM RELOJ - (C) 2026 Altaris Software
ON ERROR GOTO {error}
MODE 0:VDU 23,1,0;0;0;0;
DIM SG%(9),XD%(5),PV%(5),DIA$(6),MES$(11)
RESTORE {datos}
FOR I%=0 TO 9:READ SG%(I%):NEXT
FOR I%=0 TO 5:READ XD%(I%):NEXT
FOR I%=0 TO 6:READ DIA$(I%):NEXT
FOR I%=0 TO 11:READ MES$(I%):NEXT
VISTA%=0:CORRE%=FALSE:ACUM%=0
PROCpantalla
REPEAT
IF VISTA%=0 THEN PROCreloj ELSE PROCcrono
K%=INKEY(4)
IF K%=67 OR K%=99 THEN VISTA%=1-VISTA%:PROCpantalla
IF VISTA%=0 AND (K%=80 OR K%=112) THEN PROCponer:PROCpantalla
IF VISTA%=1 AND K%=32 THEN PROCmarcha
IF VISTA%=1 AND (K%=82 OR K%=114) THEN CORRE%=FALSE:ACUM%=0
UNTIL FALSE
#
DEF PROCpantalla
LOCAL I%
CLS:CLG
FOR I%=0 TO 5:PV%(I%)=-1:NEXT
ULT$=""
GCOL 0,1
RECTANGLE FILL 109,58,6,6:RECTANGLE FILL 109,82,6,6
RECTANGLE FILL 203,58,6,6:RECTANGLE FILL 203,82,6,6
IF VISTA%=0 THEN PROCcentro(0,"R E L O J") ELSE PROCcentro(0,"C R O N Ó M E T R O")
IF VISTA%=0 THEN PROCcentro(15,"C: cronómetro    P: poner en hora    Volver: salir")
IF VISTA%=1 THEN PROCcentro(15,"Espacio: marcha/pausa   R: a cero   C: reloj   Volver: salir")
IF VISTA%=1 THEN PROCcentro(12,"minutos : segundos : centésimas")
ENDPROC
#
DEF PROCcentro(Y%,T$)
PRINT TAB((64-LEN(T$)) DIV 2,Y%);T$;
ENDPROC
#
DEF PROCreloj
LOCAL T$,D%,M%
T$=TIME$
IF T$=ULT$ THEN ENDPROC
PROCnumeros(VAL(MID$(T$,17,2)),VAL(MID$(T$,20,2)),VAL(MID$(T$,23,2)))
IF LEFT$(T$,16)<>LEFT$(ULT$,16) THEN PROCfecha(T$)
ULT$=T$
ENDPROC
#
DEF PROCfecha(T$)
LOCAL D%,M%,F$
D%=(INSTR("DomLunMarMérJueVieSáb",LEFT$(T$,3))-1) DIV 3
M%=(INSTR("EneFebMarAbrMayJunJulAgoSepOctNovDic",MID$(T$,8,3))-1) DIV 3
F$=STR$(VAL(MID$(T$,5,2)))+" de "+MES$(M%)+" de "+MID$(T$,12,4)
IF D%>=0 THEN F$=DIA$(D%)+" "+F$
PRINT TAB(0,12);SPC(64);
PROCcentro(12,F$)
ENDPROC
#
DEF PROCcrono
LOCAL E%
E%=ACUM%
IF CORRE% THEN E%=E%+TIME-T0%
PROCnumeros((E% DIV 6000) MOD 100,(E% DIV 100) MOD 60,E% MOD 100)
ENDPROC
#
DEF PROCmarcha
IF CORRE% THEN ACUM%=ACUM%+TIME-T0%:CORRE%=FALSE ELSE T0%=TIME:CORRE%=TRUE
ENDPROC
#
REM Muestra tres pares de cifras; solo redibuja las que cambiaron
DEF PROCnumeros(A%,B%,C%)
PROCcifra(0,A% DIV 10):PROCcifra(1,A% MOD 10)
PROCcifra(2,B% DIV 10):PROCcifra(3,B% MOD 10)
PROCcifra(4,C% DIV 10):PROCcifra(5,C% MOD 10)
ENDPROC
#
REM Cifra de siete segmentos: 32 x 64 puntos, trazo de 6
DEF PROCcifra(P%,N%)
LOCAL X%,S%
IF PV%(P%)=N% THEN ENDPROC
PV%(P%)=N%:X%=XD%(P%):S%=SG%(N%)
GCOL 0,0:RECTANGLE FILL X%,40,31,63
GCOL 0,1
IF S% AND 1 THEN RECTANGLE FILL X%+4,98,23,5
IF S% AND 2 THEN RECTANGLE FILL X%+26,73,5,28
IF S% AND 4 THEN RECTANGLE FILL X%+26,42,5,28
IF S% AND 8 THEN RECTANGLE FILL X%+4,40,23,5
IF S% AND 16 THEN RECTANGLE FILL X%,42,5,28
IF S% AND 32 THEN RECTANGLE FILL X%,73,5,28
IF S% AND 64 THEN RECTANGLE FILL X%+4,69,23,5
ENDPROC
#
DEF PROCponer
LOCAL H$,F$
CLS:CLG
VDU 23,1,1;0;0;0;
PRINT TAB(2,1);"PONER EN HORA"
PRINT TAB(2,3);"Hora actual:  ";MID$(TIME$,17,8)
PRINT TAB(2,4);"Fecha actual: ";MID$(TIME$,5,11)
PRINT TAB(2,6);"Nueva hora (hh:mm:ss) o Enter para no cambiarla"
PRINT TAB(2,7);"> ";:INPUT LINE "" H$
IF H$<>"" THEN PROCnhora(H$)
PRINT TAB(2,10);"Nueva fecha (dd/mm/aaaa) o Enter para no cambiarla"
PRINT TAB(2,11);"> ";:INPUT LINE "" F$
IF F$<>"" THEN PROCnfecha(F$)
VDU 23,1,0;0;0;0;
WAIT 150
ENDPROC
#
DEF PROCnhora(H$)
LOCAL H%,M%,S%,P%,Q%
H%=VAL(H$):P%=INSTR(H$,":")
IF P%=0 THEN PROCmal(8):ENDPROC
M%=VAL(MID$(H$,P%+1)):Q%=INSTR(H$,":",P%+1)
IF Q%>0 THEN S%=VAL(MID$(H$,Q%+1))
IF H%<0 OR H%>23 OR M%<0 OR M%>59 OR S%<0 OR S%>59 THEN PROCmal(8):ENDPROC
TIME$=FNdos(H%)+":"+FNdos(M%)+":"+FNdos(S%)
PRINT TAB(2,8);"Listo: la hora es ";MID$(TIME$,17,8)
ENDPROC
#
DEF PROCnfecha(F$)
LOCAL D%,M%,A%,P%,Q%
D%=VAL(F$):P%=FNsep(F$,1)
IF P%=0 THEN PROCmal(12):ENDPROC
M%=VAL(MID$(F$,P%+1)):Q%=FNsep(F$,P%+1)
IF Q%=0 THEN PROCmal(12):ENDPROC
A%=VAL(MID$(F$,Q%+1))
IF A%<100 THEN A%=A%+2000
IF M%<1 OR M%>12 OR A%<2000 OR A%>2079 THEN PROCmal(12):ENDPROC
IF D%<1 OR D%>FNdias(M%,A%) THEN PROCmal(12):ENDPROC
TIME$="Lun,"+FNdos(D%)+" "+MID$("EneFebMarAbrMayJunJulAgoSepOctNovDic",M%*3-2,3)+" "+STR$(A%)
PRINT TAB(2,12);"Listo: hoy es ";MID$(TIME$,1,15)
ENDPROC
#
REM Posición del primer separador (/ - .) desde P%
DEF FNsep(F$,P%)
LOCAL I%,R%
FOR I%=P% TO LEN(F$)
IF R%=0 AND INSTR("/-.",MID$(F$,I%,1))>0 THEN R%=I%
NEXT
=R%
#
DEF FNdias(M%,A%)
IF M%=2 THEN =28-((A% MOD 4=0 AND A% MOD 100<>0) OR A% MOD 400=0)
IF M%=4 OR M%=6 OR M%=9 OR M%=11 THEN =30
=31
#
DEF FNdos(N%)
=RIGHT$("0"+STR$(N%),2)
#
DEF PROCmal(Y%)
PRINT TAB(2,Y%);"No entendí el dato: no se cambió.";
ENDPROC
#
{error} IF ERR=17 THEN CHAIN "MENU"
MODE 0:VDU 23,1,1;0;0;0;:REPORT:PRINT " (línea ";ERL;")":END
#
REM Segmentos de cada cifra (a=1 b=2 c=4 d=8 e=16 f=32 g=64)
{datos} DATA 63,6,91,79,102,109,125,7,127,111
REM Posición horizontal de las seis cifras
DATA 30,68,124,162,218,256
DATA Domingo,Lunes,Martes,Miércoles,Jueves,Viernes,Sábado
DATA enero,febrero,marzo,abril,mayo,junio,julio,agosto,septiembre,octubre,noviembre,diciembre
